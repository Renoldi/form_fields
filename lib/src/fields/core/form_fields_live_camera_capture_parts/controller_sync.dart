part of '../form_fields_live_camera_capture.dart';

extension _FormFieldsLiveCameraCaptureSyncX
    on FormFieldsLiveCameraCaptureState {
  void _bindController(FormFieldsMyImageController? controller) {
    controller?.registerCaptureHandler(capture, resetCapture);
    controller?.addListener(_onExternalControllerChanged);
    _syncCapturedFromController();
    // Register controller with OfflineUploadManager so persisted retry
    // uploads can update the controller's images automatically.
    if (controller != null) {
      OfflineUploadManager.instance.registerController(controller);
    }
  }

  void _unbindController(FormFieldsMyImageController? controller) {
    controller?.unregisterCaptureHandler();
    controller?.removeListener(_onExternalControllerChanged);
    // Unregister from OfflineUploadManager (best-effort).
    if (controller != null) {
      OfflineUploadManager.instance.unregisterController(controller);
    }
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
      _applyStateChange(() {
        _cameraInitDone = ready;
      });
    }
  }

  Future<void> _deleteTempCapture(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
