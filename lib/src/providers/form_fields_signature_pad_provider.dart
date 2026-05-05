import 'package:flutter/material.dart';
import 'package:form_fields/src/utilities/myimage_result.dart';

class FormFieldsSignaturePadProvider extends ChangeNotifier {
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  MyimageResult? _previewSignatureResult;
  MyimageResult? get previewSignatureResult => _previewSignatureResult;

  MyimageResult? _previewLiveCaptureResult;
  MyimageResult? get previewLiveCaptureResult => _previewLiveCaptureResult;

  void setUploading(bool value) {
    _isUploading = value;
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
