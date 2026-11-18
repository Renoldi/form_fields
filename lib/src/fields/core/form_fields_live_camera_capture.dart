import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/service/permission_gate.dart';
import 'package:form_fields/src/utilities/base64_image.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:form_fields/src/utilities/network_status.dart';
import 'package:form_fields/src/utilities/upload_request_helpers.dart';
import 'package:form_fields/src/utilities/debug_log.dart';
import 'package:form_fields/src/utilities/persisted_headers.dart';
import 'package:form_fields/src/utilities/url_origin.dart';
part 'form_fields_live_camera_capture_parts/live_camera_capture_widget.dart';

part 'form_fields_live_camera_capture_parts/controller_sync.dart';
part 'form_fields_live_camera_capture_parts/upload.dart';
part 'form_fields_live_camera_capture_parts/camera_placeholder.dart';
part 'form_fields_live_camera_capture_parts/captured_photo.dart';
part 'form_fields_live_camera_capture_parts/shared_camera_manager.dart';

class FormFieldsLiveCameraCaptureState
    extends State<FormFieldsLiveCameraCapture> {
  final _cam = SharedCameraManager.instance;

  // Screenshot-based capture avoids ImageCapture use case, reducing CameraX
  // surface-combination conflicts.
  final _previewKey = GlobalKey();

  late FormFieldsLiveCameraCaptureProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = FormFieldsLiveCameraCaptureProvider();
    _bindController(widget.cameraController);
    // Listen for SharedCameraManager state changes so pre-acquire can flip
    // the UI to the live preview once the controller is ready.
    _cam.addListener(_onCameraReady);
    // Immediately sync camera-ready state in case SharedCameraManager
    // already has an initialized controller (pre-acquired). This avoids
    // the preview staying on "Initializing..." when reopening the page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _onCameraReady();
      } catch (_) {}
    });
    if (widget.preAcquire) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final granted = await PermissionGate.ensureCameraPermission(context);
        if (!mounted) return;
        if (granted) {
          try {
            await _cam.acquire(widget.resolutionPreset);
          } catch (_) {}
        }
      });
    }

    // If camera permission is already granted (e.g., user opened page before
    // and accepted), attempt to acquire immediately so reopening the widget
    // doesn't remain stuck on "Initializing...".
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final status = await Permission.camera.status;
        if (status.isGranted && !_cam.isReady) {
          try {
            await _cam.acquire(widget.resolutionPreset);
          } catch (_) {}
        }
      } catch (_) {}
    });
  }

  bool _cameraInitDone = false;

  @override
  void didUpdateWidget(FormFieldsLiveCameraCapture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cameraController != oldWidget.cameraController) {
      _unbindController(oldWidget.cameraController);
      _bindController(widget.cameraController);
    }
  }

  @override
  void dispose() {
    _unbindController(widget.cameraController);
    _cam.removeListener(_onCameraReady);
    _cam.release();
    _provider.dispose();
    super.dispose();
  }

  /// Single entry point for rebuilds requested from the helper extensions in
  /// `*_parts/`. Keeps the protected `setState` call inside this class.
  void _applyStateChange(VoidCallback fn) => setState(fn);

  /// Capture current preview into a PNG file and return [MyImageResult].
  /// When [FormFieldsLiveCameraCapture.isDirectUpload] is `true`, the image is
  /// uploaded automatically and the returned result (and the connected
  /// controller) will already contain the server link/imageId.
  Future<MyImageResult?> capture() async {
    if (!_cam.isReady) return null;
    // Temp PNG written for this capture. It must outlive the upload attempt:
    // the upload reads it, and an offline-queued payload refers to its path.
    File? tempCapture;
    try {
      MyImageResult result;

      if (widget.hidePreview) {
        // Silent mode: use CameraController.takePicture() — no widget needed.
        final xfile = await _cam.controller!.takePicture();
        result = await MyImageResult.fromFile(
          File(xfile.path),
          quality: widget.quality,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        final boundary =
            _previewKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) return null;

        final image = await boundary.toImage(pixelRatio: 1.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return null;

        final bytes = byteData.buffer.asUint8List();
        final tempDir = Directory.systemTemp;
        final file = await File(
          '${tempDir.path}/live_capture_${DateTime.now().millisecondsSinceEpoch}.png',
        ).create();
        await file.writeAsBytes(bytes);
        tempCapture = file;
        result = await MyImageResult.fromFile(file, quality: widget.quality);
      }

      if (widget.isDirectUpload && mounted) {
        if (widget.showUploadLoading) {
          _provider.startUpload(initialProgress: 0.02);
        }
        final uploaded = await _uploadImageDio(
          result,
          showSuccessDialog: false,
        );
        if (mounted && widget.showUploadLoading) {
          if (uploaded != null && uploaded.status == MyImageStatus.uploaded) {
            _provider.completeUpload();
            await Future<void>.delayed(uploadCompletionTransitionDelay);
            if (mounted) {
              _provider.clearUpload();
            }
          } else {
            _provider.clearUpload();
          }
        }
        if (uploaded != null &&
            uploaded.status == MyImageStatus.uploaded &&
            widget.showUploadResultDialog &&
            mounted) {
          final l = FormFieldsLocalizations.of(context);
          final dialog = AppDialogService(context);
          await dialog.showSuccess(
            title: widget.uploadSuccessTitle ?? l.get('uploadSuccessTitle'),
            message:
                widget.uploadSuccessMessage ?? l.get('uploadSuccessMessage'),
          );
        }
        if (uploaded != null) {
          result = uploaded;
          // Only a confirmed upload lets the temp PNG go. A queued payload
          // still needs the file, so it is kept until the queue flushes.
          if (uploaded.status == MyImageStatus.uploaded) {
            await _deleteTempCapture(tempCapture);
          }
        } else {
          // Refused and not queued: show it as failed, not as a capture.
          result = result.copyWith(status: MyImageStatus.failed);
        }
      }

      widget.cameraController?.images = [result];
      widget.onCaptured?.call(result);
      if (mounted) _provider.setCapturedResult(result);
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Reset to live preview mode and clear the connected controller.
  void resetCapture() {
    widget.cameraController?.clear();
    if (mounted) _provider.setCapturedResult(null);
  }

  @override
  Widget build(BuildContext context) {
    // In silent/hidden mode the camera is initialised in the background but
    // nothing is rendered on screen.
    if (widget.hidePreview) return const SizedBox.shrink();

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<FormFieldsLiveCameraCaptureProvider>(
        builder: (context, provider, _) {
          final loadingTheme =
              Theme.of(context).extension<AppLoadingThemeData>() ??
              const AppLoadingThemeData.fallback();
          final progressTheme = Theme.of(context).progressIndicatorTheme;
          final progressColor =
              progressTheme.color ?? loadingTheme.indicatorColor;
          final progressTrackColor =
              progressTheme.linearTrackColor ?? loadingTheme.trackColor;
          final localizations = FormFieldsLocalizations.of(context);
          String? errorMessage;
          if (_cam.errorMessage == 'cameraNoCamerasFound') {
            errorMessage = localizations.get('cameraNoCamerasFound');
          } else if (_cam.errorMessage == 'cameraAvailableTimeout') {
            errorMessage = localizations.get('cameraAvailableTimeout');
          } else if (_cam.errorMessage == 'cameraInitializeTimeout') {
            errorMessage = localizations.get('cameraInitializeTimeout');
          } else {
            errorMessage = _cam.errorMessage;
          }

          if (errorMessage != null) {
            return _CameraPlaceholder(
              height: widget.height,
              icon: Icons.no_photography_outlined,
              message: errorMessage,
            );
          }
          if (!_cam.isReady) {
            return _CameraPlaceholder(
              height: widget.height,
              icon: Icons.camera_front,
              message: localizations.get('cameraInitializing'),
              showSpinner: true,
            );
          }

          final previewWidget = SizedBox(
            height: widget.height,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: provider.capturedResult == null ? 1.0 : 0.0,
                    child: RepaintBoundary(
                      key: _previewKey,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width:
                              _cam.controller!.value.previewSize?.height ?? 1,
                          height:
                              _cam.controller!.value.previewSize?.width ?? 1,
                          child: CameraPreview(_cam.controller!),
                        ),
                      ),
                    ),
                  ),
                  if (provider.capturedResult != null)
                    _CapturedPhoto(
                      result: provider.capturedResult!,
                      headers:
                          (widget.uploadToken != null &&
                              widget.uploadToken!.isNotEmpty &&
                              isSameOrigin(
                                provider.capturedResult!.link,
                                widget.uploadUrl,
                              ))
                          ? <String, String>{
                              HttpHeaders.authorizationHeader:
                                  widget.uploadToken!,
                            }
                          : null,
                    ),
                  // Upload loading overlay
                  if (provider.isUploading)
                    Positioned.fill(
                      child: Container(
                        color: loadingTheme.overlayColor,
                        child: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 170,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: .94),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: progressColor.withValues(alpha: .20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppProgressIndicator(
                                    type: AppProgressType.linear,
                                    value: provider.uploadProgress,
                                    minHeight: 6,
                                    color: progressColor,
                                    trackColor: progressTrackColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: provider.capturedResult == null
                        ? const SizedBox.shrink()
                        : Builder(
                            builder: (ctx) {
                              final st = provider.capturedResult!.status;
                              final icon = st == MyImageStatus.uploading
                                  ? Icons.cloud_upload
                                  : st == MyImageStatus.queued
                                  ? Icons.schedule
                                  : st == MyImageStatus.failed
                                  ? Icons.error_outline
                                  : Icons.check_circle;
                              final iconColor = st == MyImageStatus.failed
                                  ? Theme.of(context).colorScheme.error
                                  : resolveTextColor(ctx);
                              return Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).shadowColor.withValues(alpha: .18),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, size: 14, color: iconColor),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );

          // Only reveal the live preview widget after camera acquire() has
          // completed. This avoids showing the camera card while acquisition is
          // still in progress (spinner inside the preview). PermissionGate
          // still handles permission requests; onPermissionGranted we trigger
          // acquire and wait, then flip `_cameraInitDone` so the child becomes
          // the actual preview.
          final childToShow = _cameraInitDone
              ? previewWidget
              : _CameraPlaceholder(
                  height: widget.height,
                  icon: Icons.camera_front,
                  message: FormFieldsLocalizations.of(
                    context,
                  ).get('cameraInitializing'),
                  showSpinner: true,
                );

          return PermissionGate(
            onPermissionGranted: () async {
              try {
                await _cam.acquire(widget.resolutionPreset);
              } catch (_) {}
            },
            child: childToShow,
          );
        },
      ),
    );
  }
}
