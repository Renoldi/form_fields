part of '../form_fields_signature_pad.dart';

extension _FormFieldsSignaturePadDrawingX on _FormFieldsSignaturePadState {
  String? _validateSignature(bool? hasSignature) {
    if (widget.externalErrorText != null) return widget.externalErrorText;
    if (widget.validator != null) {
      return widget.validator!(hasSignature ?? false);
    }
    if (widget.isRequired && (hasSignature != true)) {
      final l = _localizations;
      if (l == null) return '';
      final raw = widget.label;
      return (raw != null && raw.isNotEmpty)
          ? l.getWithLabel('signatureRequired', raw.toTitleCases)
          : l.get('signatureRequiredDefault');
    }
    return null;
  }

  // ── Auto-capture on draw start ─────────────────────────────────────────────

  void _onSignatureChanged() {
    _formFieldKey.currentState?.didChange(_signatureController.isNotEmpty);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formFieldKey.currentState?.validate();
    });

    // Schedule auto-export when the user pauses drawing.
    if (widget.autoExportOnFinish) {
      _autoExportTimer?.cancel();
      if (_signatureController.isNotEmpty) {
        _autoExportTimer = Timer(_autoExportDebounce, () {
          if (!mounted) return;
          if (_signatureController.isNotEmpty) {
            _triggerAutoExport();
          }
        });
      }
    }
  }

  Future<void> _triggerAutoExport() async {
    if (_autoExportInProgress) return;
    _autoExportInProgress = true;
    try {
      // Do not auto-export while upload is in progress.
      if (_padProvider.isUploading) return;
      await _exportSignature();
    } finally {
      _autoExportInProgress = false;
    }
  }

  Future<void> _onDrawStart() async {
    if (!widget.showLiveCamera && !widget.silentLiveCapture) return;
    if (_hasCaptured) return; // already captured this session
    _hasCaptured = true;

    // Silent capture: use CameraController.takePicture() directly.
    if (widget.silentLiveCapture && !widget.showLiveCamera) {
      final ctrl = SharedCameraManager.instance.controller;
      if (ctrl == null || !ctrl.value.isInitialized) {
        _hasCaptured = false;
        return;
      }
      try {
        final xfile = await ctrl.takePicture();
        final result = await MyImageResult.fromFile(
          File(xfile.path),
          quality: widget.quality,
        );
        // The widget may have been removed while the photo was being taken.
        if (!mounted) return;
        _cameraController.images = [result];
        widget.onLiveCaptured?.call(result);
      } catch (_) {
        _hasCaptured = false;
      }
      return;
    }

    // Visible camera: screenshot-based capture via FormFieldsLiveCameraCapture.
    final result = await _liveCameraKey.currentState?.capture();
    if (result == null) {
      // Allow retry if capture failed during draw start.
      _hasCaptured = false;
    }
  }

  void _clearSignatureSession() {
    _signatureController.clear();
    // Reset capture flag so the next draw triggers a fresh photo.
    _hasCaptured = false;
    if (widget.showLiveCamera) {
      _liveCameraKey.currentState?.resetCapture();
    }
    _cameraController.clear();
    if (_padProvider.previewSignatureResult != null ||
        _padProvider.previewLiveCaptureResult != null) {
      _padProvider.clearPreviewResults();
    }
    widget.signaturePadController?.clearFromWidget();
  }
}
