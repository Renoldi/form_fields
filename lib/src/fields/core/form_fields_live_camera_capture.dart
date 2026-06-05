import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import '../../utilities/theme_helpers.dart';
import '../../service/permission_gate.dart';

/// Reusable front-camera live preview that can capture a frame into
/// [FormFieldsMyImageController].
class FormFieldsLiveCameraCapture extends StatefulWidget {
  final double height;

  /// Resolution preset used when creating the camera controller.
  /// Lower presets initialize faster but have lower preview/capture quality.
  final ResolutionPreset resolutionPreset;

  /// Controller that will be updated with the latest captured image.
  /// Optional — only needed when you want to read captured images or trigger
  /// capture/reset programmatically without a [GlobalKey].
  final FormFieldsMyImageController? cameraController;

  /// Called each time [FormFieldsLiveCameraCaptureState.capture] succeeds.
  /// When [isDirectUpload] is enabled, the result passed here will already
  /// contain the server [MyImageResult.link] and [MyImageResult.imageId].
  final void Function(MyImageResult captured)? onCaptured;

  // ── Upload ─────────────────────────────────────────────────────────────────

  /// Upload otomatis saat capture selesai.
  /// Requires [uploadUrl] to be non-empty when `true`.
  final bool isDirectUpload;

  /// Upload endpoint URL (required when [isDirectUpload] is `true`).
  final String? uploadUrl;

  /// Bearer token sent as `Authorization` header during upload.
  final String? uploadToken;

  /// Called when `isDirectUpload == true` but the device has no internet.
  /// Receives a list of payload Maps (each containing URL, headers, fields
  /// and file data) so the caller can store and send them later when online.
  final void Function(List<Map<String, dynamic>> payloads)?
      onDirectUploadPayload;

  /// Show a result dialog after upload completes (success or failure).
  final bool showUploadResultDialog;

  /// Show a loading overlay on the camera preview while uploading.
  /// Defaults to `true`.
  final bool showUploadLoading;

  // Customizable upload messages
  final String? uploadSuccessTitle;
  final String? uploadFailedTitle;
  final String? uploadErrorTitle;
  final String? uploadSuccessMessage;
  final String? uploadFailedMessage;
  final String? uploadErrorMessage;

  /// JSON key for the uploaded file URL in the response body.
  final String uploadFileUrlKey;

  /// JSON key for the image/file ID in the response body.
  final String uploadImageIdKey;

  /// When `true`, the camera preview is hidden (renders as a zero-size widget)
  /// but the camera is still initialised in the background, allowing
  /// [FormFieldsLiveCameraCaptureState.capture] to fire silently.
  ///
  /// In silent mode [capture] uses [CameraController.takePicture] instead of
  /// the screenshot path, so no rendered widget is required.
  final bool hidePreview;

  /// When `true`, attempt to acquire the camera as soon as the widget is
  /// mounted (after the first frame) so the preview is ready faster.
  /// Permission will be requested if needed.
  final bool preAcquire;

  FormFieldsLiveCameraCapture({
    super.key,
    this.height = 100,
    this.resolutionPreset = ResolutionPreset.low,
    this.cameraController,
    this.onCaptured,
    this.isDirectUpload = false,
    this.uploadUrl,
    this.uploadToken,
    this.onDirectUploadPayload,
    this.showUploadResultDialog = false,
    this.showUploadLoading = true,
    this.uploadSuccessTitle,
    this.uploadFailedTitle,
    this.uploadErrorTitle,
    this.uploadSuccessMessage,
    this.uploadFailedMessage,
    this.uploadErrorMessage,
    this.uploadFileUrlKey = 'fileUrl',
    this.uploadImageIdKey = 'imageId',
    this.hidePreview = false,
    this.preAcquire = false,
  }) : assert(
          isDirectUpload == false ||
              (uploadUrl != null && uploadUrl.isNotEmpty),
          'For direct upload, uploadUrl must be provided and non-empty.',
        );

  @override
  State<FormFieldsLiveCameraCapture> createState() =>
      FormFieldsLiveCameraCaptureState();
}

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

  Future<bool> _hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _bindController(FormFieldsMyImageController? controller) {
    controller?.registerCaptureHandler(capture, resetCapture);
    controller?.addListener(_onExternalControllerChanged);
    _syncCapturedFromController();
  }

  void _unbindController(FormFieldsMyImageController? controller) {
    controller?.unregisterCaptureHandler();
    controller?.removeListener(_onExternalControllerChanged);
  }

  void _onExternalControllerChanged() {
    _syncCapturedFromController();
  }

  void _syncCapturedFromController() {
    final controller = widget.cameraController;
    if (controller == null) return;
    final images = controller.images;
    _provider.setCapturedResult(images.isNotEmpty ? images.first : null);
  }

  void _onCameraReady() {
    if (!mounted) return;
    _provider.notifyCameraReady();
    final ready = _cam.isReady;
    if (_cameraInitDone != ready) {
      setState(() {
        _cameraInitDone = ready;
      });
    }
  }

  /// Capture current preview into a PNG file and return [MyImageResult].
  /// When [FormFieldsLiveCameraCapture.isDirectUpload] is `true`, the image is
  /// uploaded automatically and the returned result (and the connected
  /// controller) will already contain the server link/imageId.
  Future<MyImageResult?> capture() async {
    if (!_cam.isReady) return null;
    try {
      MyImageResult result;

      if (widget.hidePreview) {
        // Silent mode: use CameraController.takePicture() — no widget needed.
        final xfile = await _cam.controller!.takePicture();
        result = await MyImageResult.fromFile(File(xfile.path));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        final boundary = _previewKey.currentContext?.findRenderObject()
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
        result = await MyImageResult.fromFile(file);
      }

      if (widget.isDirectUpload && mounted) {
        if (widget.showUploadLoading) {
          _provider.startUpload(initialProgress: 0.02);
        }
        final uploaded =
            await _uploadImageDio(result, showSuccessDialog: false);
        if (mounted && widget.showUploadLoading) {
          if (uploaded != null) {
            _provider.completeUpload();
            await Future<void>.delayed(uploadCompletionTransitionDelay);
            if (mounted) {
              _provider.clearUpload();
            }
          } else {
            _provider.clearUpload();
          }
        }
        if (uploaded != null && widget.showUploadResultDialog && mounted) {
          final l = FormFieldsLocalizations.of(context);
          final dialog = AppDialogService(context);
          await dialog.showSuccess(
            title: widget.uploadSuccessTitle ?? l.get('uploadSuccessTitle'),
            message:
                widget.uploadSuccessMessage ?? l.get('uploadSuccessMessage'),
          );
        }
        if (uploaded != null) result = uploaded;
      }

      widget.cameraController?.images = [result];
      widget.onCaptured?.call(result);
      if (mounted) _provider.setCapturedResult(result);
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Uploads [image] and returns the updated [MyImageResult] with server
  /// link/imageId. Returns `null` on failure.
  Future<MyImageResult?> _uploadImageDio(
    MyImageResult image, {
    bool showSuccessDialog = true,
  }) async {
    if (widget.uploadUrl == null) return null;
    final headers = <String, String>{};
    if (widget.uploadToken != null && widget.uploadToken!.isNotEmpty) {
      headers['Authorization'] = widget.uploadToken!;
    }

    // Prepare payload for offline enqueueing
    final fileName = image.path.trim().isNotEmpty
        ? image.path.split(Platform.pathSeparator).last
        : (image.link.isNotEmpty ? image.link.split('/').last : 'image');
    final imgDesc = (image.description).trim();
    final effDesc = imgDesc.isNotEmpty ? imgDesc : null;
    final extraFields = <MapEntry<String, String>>[];
    if (effDesc != null && effDesc.isNotEmpty) {
      extraFields.add(MapEntry('description', effDesc));
    }
    final payload = <String, dynamic>{
      'url': widget.uploadUrl,
      'headers': headers,
      'fields': Map<String, String>.fromEntries(extraFields),
      'file': {
        'fileName': fileName,
        'base64': image.base64,
        'path': image.path,
      },
      'uploadFileUrlKey': widget.uploadFileUrlKey,
      'uploadImageIdKey': widget.uploadImageIdKey,
      'description': effDesc,
      'index': 0,
    };

    final hasNet = await _hasNetwork();
    if (!hasNet) {
      if (mounted && widget.showUploadLoading) {
        _provider.setUploadProgress(0.0);
      }
      widget.onDirectUploadPayload?.call([payload]);
      return null;
    }

    final response = await DioUtil.uploadFile(
      url: widget.uploadUrl!,
      filePath: image.path,
      filename: File(image.path).path.split('/').last,
      headers: headers,
      onProgress: (progress) {
        if (mounted && widget.showUploadLoading) {
          _provider.setUploadProgress(progress);
        }
      },
      fields: extraFields.isNotEmpty ? extraFields : null,
    );
    if (!mounted) return null;
    final l = FormFieldsLocalizations.of(context);
    final dialog = AppDialogService(context);
    final uploadSuccessTitle =
        widget.uploadSuccessTitle ?? l.get('uploadSuccessTitle');
    final uploadFailedTitle =
        widget.uploadFailedTitle ?? l.get('uploadFailedTitle');
    final uploadErrorTitle =
        widget.uploadErrorTitle ?? l.get('uploadErrorTitle');
    final uploadSuccessMessage =
        widget.uploadSuccessMessage ?? l.get('uploadSuccessMessage');
    final uploadFailedMessage =
        widget.uploadFailedMessage ?? l.get('uploadFailedMessage');
    final uploadErrorMessage =
        widget.uploadErrorMessage ?? l.get('uploadErrorMessage');
    if (response == null) {
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadFailedTitle,
          message: uploadErrorMessage,
          dialogType: AppDialogType.network,
        );
      }
      return null;
    }
    try {
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        String? uploadedLink;
        String? imageId;
        final data = response.data;
        if (data is String) {
          final redirectRegex = RegExp(
            r"redirect_link\s*=\s*'([^']+)'",
            multiLine: true,
          );
          final match = redirectRegex.firstMatch(data);
          uploadedLink = match != null ? match.group(1) : data;
        } else if (data is Map) {
          uploadedLink = data[widget.uploadFileUrlKey]?.toString();
          imageId = data[widget.uploadImageIdKey]?.toString();
        }
        final uploadedDescription = _extractDescription(data);
        if (showSuccessDialog && widget.showUploadResultDialog) {
          await dialog.showSuccess(
            title: uploadSuccessTitle,
            message: uploadSuccessMessage,
          );
        }
        return MyImageResult(
          link: uploadedLink ?? image.link,
          base64: image.base64,
          // Keep local capture path to avoid extra GET right after upload.
          path: image.path,
          imageId: imageId ?? image.imageId,
          description: uploadedDescription ?? image.description,
        );
      } else {
        if (widget.showUploadResultDialog) {
          await dialog.showError(
            title: uploadFailedTitle,
            message: '$uploadFailedMessage ${response.statusMessage ?? ''}',
            dialogType: AppDialogType.server,
          );
        }
      }
    } catch (e) {
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadErrorTitle,
          message: '$uploadErrorMessage $e',
          dialogType: AppDialogType.server,
        );
      }
    }
    return null;
  }

  String? _extractDescription(dynamic data) {
    if (data == null) return null;

    final exact = _extractNestedValue(data, 'description');
    if ((exact ?? '').isNotEmpty) return exact;

    const fallbackKeys = [
      'description',
      'desc',
      'note',
      'caption',
      'alt',
      'title'
    ];
    for (final key in fallbackKeys) {
      final val = _extractNestedValue(data, key);
      if ((val ?? '').isNotEmpty) return val;
    }
    return null;
  }

  String? _extractNestedValue(dynamic data, String key) {
    if (data is Map) {
      for (final entry in data.entries) {
        if (entry.key.toString() == key) {
          return entry.value?.toString();
        }
        final nested = _extractNestedValue(entry.value, key);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    if (data is List) {
      for (final item in data) {
        final nested = _extractNestedValue(item, key);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    return null;
  }

  /// Reset to live preview mode and clear the connected controller.
  void resetCapture() {
    widget.cameraController?.clear();
    if (mounted) _provider.setCapturedResult(null);
  }

  @override
  void dispose() {
    _unbindController(widget.cameraController);
    _cam.removeListener(_onCameraReady);
    _cam.release();
    _provider.dispose();
    super.dispose();
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
                    _CapturedPhoto(result: provider.capturedResult!),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: .94),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: progressColor.withValues(alpha: .20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .shadowColor
                                        .withValues(alpha: 0.25),
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
                    bottom: 8,
                    right: 8,
                    child: provider.capturedResult == null
                        ? _Badge(
                            icon: Icons.camera_front,
                            label: localizations.get('cameraReady'),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          )
                        : _Badge(
                            icon: Icons.check_circle_outline,
                            label: localizations.get('cameraCaptured'),
                            color: resolveActiveColor(context, null),
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
                  message: FormFieldsLocalizations.of(context)
                      .get('cameraInitializing'),
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

class SharedCameraManager {
  SharedCameraManager._();
  static final SharedCameraManager instance = SharedCameraManager._();

  CameraController? _controller;
  int _refCount = 0;
  bool _initializing = false;
  String? _errorMessage;

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _notify() {
    for (final l in List<VoidCallback>.of(_listeners)) {
      l();
    }
  }

  Future<void> acquire(
      [ResolutionPreset preset = ResolutionPreset.medium]) async {
    _refCount++;
    if (_controller != null && _controller!.value.isInitialized) return;
    if (_initializing) {
      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _initializing;
      });
      return;
    }
    _initializing = true;
    _errorMessage = null;
    try {
      debugPrint('[SharedCameraManager] acquiring cameras...');
      // Give the camera init a reasonable timeout to avoid indefinite spinner.
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw Exception('availableCameras() timeout');
        },
      );
      if (cameras.isEmpty) {
        _errorMessage = 'cameraNoCamerasFound';
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      debugPrint(
          '[SharedCameraManager] initializing controller for ${front.name}');
      final ctrl = CameraController(
        front,
        preset,
        enableAudio: false,
      );
      await ctrl.initialize().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw Exception('CameraController.initialize() timeout');
        },
      );
      _controller = ctrl;
      debugPrint('[SharedCameraManager] camera initialized');
    } catch (e, st) {
      final msg = e.toString();
      if (msg.contains('availableCameras() timeout')) {
        _errorMessage = 'cameraAvailableTimeout';
      } else if (msg.contains('CameraController.initialize() timeout')) {
        _errorMessage = 'cameraInitializeTimeout';
      } else {
        _errorMessage = msg;
      }
      debugPrint('[SharedCameraManager] acquire failed: $e\n$st');
    } finally {
      _initializing = false;
      _notify();
    }
  }

  void release() {
    _refCount = (_refCount - 1).clamp(0, double.maxFinite.toInt());
    if (_refCount == 0) {
      _controller?.dispose();
      _controller = null;
      _errorMessage = null;
    }
  }

  CameraController? get controller => _controller;
  String? get errorMessage => _errorMessage;
  bool get isReady => _controller != null && _controller!.value.isInitialized;
}

class _CapturedPhoto extends StatelessWidget {
  final MyImageResult result;
  const _CapturedPhoto({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.path.isNotEmpty) {
      return Image.file(File(result.path),
          fit: BoxFit.cover, width: double.infinity);
    }
    if (result.link.isNotEmpty) {
      return Image.network(
        result.link,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(Icons.broken_image_outlined,
              size: 32, color: resolveTextColor(context, muted: true)),
        ),
      );
    }
    return Image.memory(
      Uri.parse(result.base64).data!.contentAsBytes(),
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  final double height;
  final IconData icon;
  final String message;
  final bool showSpinner;

  const _CameraPlaceholder({
    required this.height,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              CircularProgressIndicator(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.54))
            else
              Icon(icon,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.54),
                  size: 40),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.54),
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
