import 'package:flutter/material.dart';
import 'package:form_fields/src/utilities/myimage_result.dart';

class FormFieldsSignaturePadProvider extends ChangeNotifier {
  double? _uploadProgress;
  double? get uploadProgress => _uploadProgress;

  bool get isUploading => _uploadProgress != null;

  MyimageResult? _previewSignatureResult;
  MyimageResult? get previewSignatureResult => _previewSignatureResult;

  MyimageResult? _previewLiveCaptureResult;
  MyimageResult? get previewLiveCaptureResult => _previewLiveCaptureResult;

  void startUpload({double? initialProgress}) {
    _uploadProgress = initialProgress;
    notifyListeners();
  }

  void setUploadProgress(double progress) {
    _uploadProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  void completeUpload() {
    _uploadProgress = 1.0;
    notifyListeners();
  }

  void clearUpload() {
    _uploadProgress = null;
    notifyListeners();
  }

  void setPreviewResults({
    required MyimageResult? signature,
    required MyimageResult? liveCapture,
  }) {
    _previewSignatureResult = signature;
    _previewLiveCaptureResult = liveCapture;
    notifyListeners();
  }

  void clearPreviewResults() {
    _previewSignatureResult = null;
    _previewLiveCaptureResult = null;
    notifyListeners();
  }
}
