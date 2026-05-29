import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class ViewModel extends ChangeNotifier {
  // ── Basic example ────────────────────────────────────────────────────────
  final FormFieldsSignaturePadController basicSignatureController =
      FormFieldsSignaturePadController();
  MyImageResult? signatureResult;

  void setSignature(MyImageResult? result) {
    signatureResult = result;
    notifyListeners();
  }

  // ── Live camera example ──────────────────────────────────────────────────
  /// External camera controller so the host page can read the captured photo.
  final FormFieldsMyImageController liveCameraController =
      FormFieldsMyImageController();
  final FormFieldsMyImageController prefilledLiveCameraController =
      FormFieldsMyImageController.fromImages([
    MyImageResult(link: 'https://picsum.photos/seed/live-prefill/800/600'),
  ]);
  final FormFieldsMyImageController standaloneCameraController =
      FormFieldsMyImageController();
  final FormFieldsMyImageController controllerCaptureController =
      FormFieldsMyImageController();

  MyImageResult? controllerCaptureResult;

  void setControllerCapture(MyImageResult? captured) {
    controllerCaptureResult = captured;
    notifyListeners();
  }

  SignaturePadExportResult? exportResult;
  SignaturePadExportResult? prefilledExportResult;
  MyImageResult? liveCaptureResult;
  MyImageResult? standaloneCaptureResult;

  void setExportResult(SignaturePadExportResult result) {
    exportResult = result;
    notifyListeners();
  }

  void setPrefilledExportResult(SignaturePadExportResult result) {
    prefilledExportResult = result;
    notifyListeners();
  }

  void setLiveCapture(MyImageResult captured) {
    liveCaptureResult = captured;
    notifyListeners();
  }

  void setStandaloneCapture(MyImageResult? captured) {
    standaloneCaptureResult = captured;
    notifyListeners();
  }

  // ── Prefilled signature example ──────────────────────────────────────────
  final FormFieldsSignaturePadController prefilledSignatureController =
      FormFieldsSignaturePadController.fromSignature(
    MyImageResult.network(
        'https://picsum.photos/seed/signature-prefill/400/160'),
  );
  SignaturePadExportResult? prefilledSignatureExportResult;

  void setPrefilledSignatureExportResult(SignaturePadExportResult result) {
    prefilledSignatureExportResult = result;
    notifyListeners();
  }

  // ── Prefilled signature + live camera example ────────────────────────────
  final FormFieldsSignaturePadController prefilledBothController =
      FormFieldsSignaturePadController.fromExportResult(
    SignaturePadExportResult(
      signature:
          MyImageResult(link: 'https://picsum.photos/seed/sig-both/400/160'),
      liveCapture: MyImageResult.network(
          'https://picsum.photos/seed/prefill-both/800/600'),
    ),
  );
  SignaturePadExportResult? prefilledBothExportResult;

  void setPrefilledBothExportResult(SignaturePadExportResult result) {
    prefilledBothExportResult = result;
    notifyListeners();
  }

  // ── Direct upload examples ───────────────────────────────────────────────
  final FormFieldsSignaturePadController uploadedSignatureController =
      FormFieldsSignaturePadController();
  MyImageResult? uploadedSignatureResult;
  SignaturePadExportResult? uploadedExportResult;

  void setUploadedSignature(MyImageResult? result) {
    uploadedSignatureResult = result;
    notifyListeners();
  }

  void setUploadedExportResult(SignaturePadExportResult result) {
    uploadedExportResult = result;
    notifyListeners();
  }

  // ── Silent live capture example ──────────────────────────────────────────
  MyImageResult? silentCaptureResult;
  SignaturePadExportResult? silentExportResult;

  void setSilentCapture(MyImageResult captured) {
    silentCaptureResult = captured;
    notifyListeners();
  }

  void setSilentExportResult(SignaturePadExportResult result) {
    silentExportResult = result;
    notifyListeners();
  }

  // ── Hidden live camera (FormFieldsLiveCameraCapture hidePreview) ────────
  final FormFieldsMyImageController hiddenLiveCameraController =
      FormFieldsMyImageController();
  MyImageResult? hiddenCaptureResult;

  void setHiddenCapture(MyImageResult captured) {
    hiddenCaptureResult = captured;
    notifyListeners();
  }

  void clearHiddenCapture() {
    hiddenCaptureResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    basicSignatureController.dispose();
    liveCameraController.dispose();
    prefilledLiveCameraController.dispose();
    prefilledSignatureController.dispose();
    prefilledBothController.dispose();
    uploadedSignatureController.dispose();
    standaloneCameraController.dispose();
    controllerCaptureController.dispose();
    hiddenLiveCameraController.dispose();
    super.dispose();
  }
}
