part of '../form_fields_signature_pad.dart';

extension _FormFieldsSignaturePadControllersX on _FormFieldsSignaturePadState {
  void _initCameraController() {
    if (widget.liveCameraController != null) {
      _cameraController = widget.liveCameraController!;
      _ownsCamera = false;
    } else {
      _cameraController = FormFieldsMyImageController();
      _ownsCamera = true;
    }
    _cameraController.addListener(_onLiveCameraControllerChanged);
    _syncCaptureGuardFromController();
    // Register camera controller with OfflineUploadManager so offline
    // persisted upload retries can update the controller previews.
    try {
      OfflineUploadManager.instance.registerController(_cameraController);
    } catch (_) {}
  }

  void _disposeCameraControllerBinding() {
    _cameraController.removeListener(_onLiveCameraControllerChanged);
    // Unregister from OfflineUploadManager (best-effort)
    try {
      OfflineUploadManager.instance.unregisterController(_cameraController);
    } catch (_) {}
  }

  // ── SignaturePadController binding ────────────────────────────────────────

  void _bindSignaturePadController(
    FormFieldsSignaturePadController? controller,
  ) {
    controller?.registerClearHandler(_clearSignatureSession);
    controller?.addListener(_onSignaturePadControllerChanged);
  }

  void _unbindSignaturePadController(
    FormFieldsSignaturePadController? controller,
  ) {
    controller?.unregisterClearHandler();
    controller?.removeListener(_onSignaturePadControllerChanged);
  }

  void _onSignaturePadControllerChanged() {
    _syncPreviewFromSignaturePadController();
  }

  void _syncPreviewFromSignaturePadController() {
    if (!mounted) return;
    final ctrl = widget.signaturePadController;
    if (ctrl == null) return;
    final result = ctrl.exportResult;
    if (result != null) {
      _padProvider.setPreviewResults(
        signature: result.signature,
        liveCapture: result.liveCapture,
      );
      // Also sync live-capture controller so camera widget shows the prefilled image.
      _cameraController.images = [result.liveCapture];
    } else {
      _padProvider.clearPreviewResults();
    }
  }

  void _onLiveCameraControllerChanged() {
    _syncCaptureGuardFromController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSignature = _signatureController.isNotEmpty || _hasCaptured;
      _formFieldKey.currentState?.didChange(hasSignature);
      _formFieldKey.currentState?.validate();
    });
  }

  void _syncCaptureGuardFromController() {
    _hasCaptured = widget.showLiveCamera && _cameraController.images.isNotEmpty;
  }

  /// Gives back the shared camera reference, but only when one was acquired.
  /// Releasing without an acquire would drop a reference that another user of
  /// the shared camera still holds.
  void _releaseSilentCamera() {
    if (!_holdsSilentCamera) return;
    _holdsSilentCamera = false;
    SharedCameraManager.instance.release();
  }
}
