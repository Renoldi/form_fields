import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:form_fields/form_fields.dart';

/// Reusable front-camera live preview that can capture a frame into
/// [FormFieldsMyImageController].
class FormFieldsLiveCameraCapture extends StatefulWidget {
  final double height;

  /// Controller that will be updated with the latest captured image.
  /// Optional — only needed when you want to read captured images or trigger
  /// capture/reset programmatically without a [GlobalKey].
  final FormFieldsMyImageController? cameraController;

  /// Called each time [FormFieldsLiveCameraCaptureState.capture] succeeds.
  /// When [isDirectUpload] is enabled, the result passed here will already
  /// contain the server [MyimageResult.link] and [MyimageResult.imageId].
  final void Function(MyimageResult captured)? onCaptured;

  // ── Upload ─────────────────────────────────────────────────────────────────

  /// Upload otomatis saat capture selesai.
  /// Requires [uploadUrl] to be non-empty when `true`.
  final bool isDirectUpload;

  /// Upload endpoint URL (required when [isDirectUpload] is `true`).
  final String? uploadUrl;

  /// Bearer token sent as `Authorization` header during upload.
  final String? uploadToken;

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

  FormFieldsLiveCameraCapture({
    super.key,
    this.height = 100,
    this.cameraController,
    this.onCaptured,
    this.isDirectUpload = false,
    this.uploadUrl,
    this.uploadToken,
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
  final _cam = _SharedCameraManager.instance;

  // Screenshot-based capture avoids ImageCapture use case, reducing CameraX
  // surface-combination conflicts.
  final _previewKey = GlobalKey();

  /// Non-null after capture; displays frozen image until reset.
  MyimageResult? _capturedResult;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _cam.addListener(_onCameraReady);
    _cam.acquire();
    widget.cameraController?.registerCaptureHandler(capture, resetCapture);
  }

  @override
  void didUpdateWidget(FormFieldsLiveCameraCapture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cameraController != oldWidget.cameraController) {
      oldWidget.cameraController?.unregisterCaptureHandler();
      widget.cameraController?.registerCaptureHandler(capture, resetCapture);
    }
  }

  void _onCameraReady() {
    if (mounted) setState(() {});
  }

  /// Capture current preview into a PNG file and return [MyimageResult].
  /// When [FormFieldsLiveCameraCapture.isDirectUpload] is `true`, the image is
  /// uploaded automatically and the returned result (and the connected
  /// controller) will already contain the server link/imageId.
  Future<MyimageResult?> capture() async {
    if (!_cam.isReady) return null;
    try {
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
      MyimageResult result = await MyimageResult.fromFile(file);

      if (widget.isDirectUpload && mounted) {
        if (widget.showUploadLoading) setState(() => _isUploading = true);
        final uploaded = await _uploadImageDio(result);
        if (mounted && widget.showUploadLoading)
          setState(() => _isUploading = false);
        if (uploaded != null) result = uploaded;
      }

      widget.cameraController?.images = [result];
      widget.onCaptured?.call(result);
      if (mounted) setState(() => _capturedResult = result);
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Uploads [image] and returns the updated [MyimageResult] with server
  /// link/imageId. Returns `null` on failure.
  Future<MyimageResult?> _uploadImageDio(MyimageResult image) async {
    if (widget.uploadUrl == null) return null;
    final headers = <String, String>{};
    if (widget.uploadToken != null && widget.uploadToken!.isNotEmpty) {
      headers['Authorization'] = widget.uploadToken!;
    }
    final response = await DioUtil.uploadFile(
      url: widget.uploadUrl!,
      filePath: image.path,
      filename: File(image.path).path.split('/').last,
      headers: headers,
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
      if (response.statusCode == 200) {
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
        if (widget.showUploadResultDialog) {
          await dialog.showSuccess(
            title: uploadSuccessTitle,
            message: uploadSuccessMessage,
          );
        }
        return MyimageResult(
          link: uploadedLink ?? image.link,
          base64: image.base64,
          path: image.path,
          imageId: imageId ?? image.imageId,
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

  /// Reset to live preview mode and clear the connected controller.
  void resetCapture() {
    widget.cameraController?.clear();
    if (mounted) setState(() => _capturedResult = null);
  }

  @override
  void dispose() {
    widget.cameraController?.unregisterCaptureHandler();
    _cam.removeListener(_onCameraReady);
    _cam.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = FormFieldsLocalizations.of(context);
    final errorMessage = _cam.errorMessage == 'No cameras found'
        ? localizations.get('cameraNoCamerasFound')
        : _cam.errorMessage;

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

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: _capturedResult == null ? 1.0 : 0.0,
              child: RepaintBoundary(
                key: _previewKey,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cam.controller!.value.previewSize?.height ?? 1,
                    height: _cam.controller!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cam.controller!),
                  ),
                ),
              ),
            ),
            if (_capturedResult != null)
              _CapturedPhoto(result: _capturedResult!),
            // Upload loading overlay
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: .45),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: _capturedResult == null
                  ? _Badge(
                      icon: Icons.camera_front,
                      label: localizations.get('cameraReady'),
                      color: Colors.black54,
                    )
                  : _Badge(
                      icon: Icons.check_circle_outline,
                      label: localizations.get('cameraCaptured'),
                      color: Colors.green.shade700,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedCameraManager {
  _SharedCameraManager._();
  static final _SharedCameraManager instance = _SharedCameraManager._();

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

  Future<void> acquire() async {
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
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No cameras found';
        _initializing = false;
        _notify();
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();
      _controller = ctrl;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _initializing = false;
    _notify();
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
  final MyimageResult result;
  const _CapturedPhoto({required this.result});

  @override
  Widget build(BuildContext context) {
    return result.path.isNotEmpty
        ? Image.file(File(result.path),
            fit: BoxFit.cover, width: double.infinity)
        : Image.memory(
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
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
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
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator(color: Colors.white54)
            else
              Icon(icon, color: Colors.white54, size: 40),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
