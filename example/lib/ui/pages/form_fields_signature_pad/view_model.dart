import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class ViewModel extends ChangeNotifier {
  // ── Basic example ────────────────────────────────────────────────────────
  MyimageResult? signatureResult;

  void setSignature(MyimageResult? result) {
    signatureResult = result;
    notifyListeners();
  }

  // ── Live camera example ──────────────────────────────────────────────────
  /// External camera controller so the host page can read the captured photo.
  final FormFieldsMyImageController liveCameraController =
      FormFieldsMyImageController();
  final FormFieldsMyImageController standaloneCameraController =
      FormFieldsMyImageController();
  final FormFieldsMyImageController controllerCaptureController =
      FormFieldsMyImageController();

  MyimageResult? controllerCaptureResult;

  void setControllerCapture(MyimageResult? captured) {
    controllerCaptureResult = captured;
    notifyListeners();
  }

  SignaturePadExportResult? exportResult;
  MyimageResult? liveCaptureResult;
  MyimageResult? standaloneCaptureResult;

  void setExportResult(SignaturePadExportResult result) {
    exportResult = result;
    notifyListeners();
  }

  void setLiveCapture(MyimageResult captured) {
    liveCaptureResult = captured;
    notifyListeners();
  }

  void setStandaloneCapture(MyimageResult? captured) {
    standaloneCaptureResult = captured;
    notifyListeners();
  }

  @override
  void dispose() {
    liveCameraController.dispose();
    standaloneCameraController.dispose();
    controllerCaptureController.dispose();
    super.dispose();
  }
}
