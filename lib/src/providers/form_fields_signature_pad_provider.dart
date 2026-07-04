import 'package:flutter/material.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utils/safe_notify.dart';

class FormFieldsSignaturePadProvider extends ChangeNotifier {
  double? _uploadProgress;
  double? get uploadProgress => _uploadProgress;

  bool get isUploading => _uploadProgress != null;

  MyImageResult? _previewSignatureResult;
  MyImageResult? get previewSignatureResult => _previewSignatureResult;

  MyImageResult? _previewLiveCaptureResult;
  MyImageResult? get previewLiveCaptureResult => _previewLiveCaptureResult;

  void startUpload({double? initialProgress}) {
    _uploadProgress = initialProgress;
    safeNotify(() => notifyListeners());
  }

  void setUploadProgress(double progress) {
    _uploadProgress = progress.clamp(0.0, 1.0);
    safeNotify(() => notifyListeners());
  }

  void completeUpload() {
    _uploadProgress = 1.0;
    safeNotify(() => notifyListeners());
  }

  void clearUpload() {
    _uploadProgress = null;
    safeNotify(() => notifyListeners());
  }

  void setPreviewResults({
    required MyImageResult? signature,
    required MyImageResult? liveCapture,
  }) {
    _previewSignatureResult = signature;
    _previewLiveCaptureResult = liveCapture;
    safeNotify(() => notifyListeners());
  }

  void clearPreviewResults() {
    _previewSignatureResult = null;
    _previewLiveCaptureResult = null;
    safeNotify(() => notifyListeners());
  }
}
