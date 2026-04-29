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
  final FormFieldsMyImageController cameraController;

  /// Called each time [FormFieldsLiveCameraCaptureState.capture] succeeds.
  final void Function(MyimageResult captured)? onCaptured;

  const FormFieldsLiveCameraCapture({
    super.key,
    required this.height,
    required this.cameraController,
    this.onCaptured,
  });

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

  @override
  void initState() {
    super.initState();
    _cam.addListener(_onCameraReady);
    _cam.acquire();
  }

  void _onCameraReady() {
    if (mounted) setState(() {});
  }

  /// Capture current preview into a PNG file and return [MyimageResult].
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
      final result = await MyimageResult.fromFile(file);

      widget.cameraController.images = [result];
      widget.onCaptured?.call(result);
      if (mounted) setState(() => _capturedResult = result);
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Reset to live preview mode and clear the connected controller.
  void resetCapture() {
    widget.cameraController.clear();
    if (mounted) setState(() => _capturedResult = null);
  }

  @override
  void dispose() {
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
