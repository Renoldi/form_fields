import 'package:flutter/material.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utils/safe_notify.dart';

class FormFieldsLiveCameraCaptureProvider extends ChangeNotifier {
  double? _uploadProgress;
  double? get uploadProgress => _uploadProgress;

  bool get isUploading => _uploadProgress != null;

  MyImageResult? _capturedResult;
  MyImageResult? get capturedResult => _capturedResult;

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

  void setCapturedResult(MyImageResult? result) {
    _capturedResult = result;
    safeNotify(() => notifyListeners());
  }

  void notifyCameraReady() {
    safeNotify(() => notifyListeners());
  }
}
