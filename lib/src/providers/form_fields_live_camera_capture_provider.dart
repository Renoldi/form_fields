import 'package:flutter/material.dart';
import 'package:form_fields/src/utilities/myimage_result.dart';

class FormFieldsLiveCameraCaptureProvider extends ChangeNotifier {
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  MyimageResult? _capturedResult;
  MyimageResult? get capturedResult => _capturedResult;

  void setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  void setCapturedResult(MyimageResult? result) {
    _capturedResult = result;
    notifyListeners();
  }

  void notifyCameraReady() {
    notifyListeners();
  }
}
