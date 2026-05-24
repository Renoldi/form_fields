import 'package:flutter/material.dart';
import 'package:form_fields/src/utilities/myimage_result.dart';
import 'package:form_fields/src/utilities/signature_pad_export_result.dart';

/// Controller for [FormFieldsSignaturePad].
///
/// Allows reading the exported signature (and optional live-capture) from
/// outside the widget, and optionally pre-seeding the pad with an existing
/// signature on first render.
///
/// ### Basic usage
/// ```dart
/// final controller = FormFieldsSignaturePadController();
///
/// FormFieldsSignaturePad(
///   signaturePadController: controller,
///   onExportedResult: (_) {},
/// )
///
/// // Read result later:
/// final sig = controller.signature;
/// ```
///
/// ### Pre-seeding with an existing signature
/// ```dart
/// final controller = FormFieldsSignaturePadController.fromSignature(
///   MyimageResult.network('https://example.com/existing-signature.png'),
/// );
/// ```
class FormFieldsSignaturePadController extends ChangeNotifier {
  FormFieldsSignaturePadController();

  /// Named constructor — pre-seeds with an existing signature result.
  ///
  /// When attached to [FormFieldsSignaturePad], the pad will immediately render
  /// this image in preview mode (same as if the user had just exported it).
  FormFieldsSignaturePadController.fromSignature(MyimageResult signature)
      : _exportResult = SignaturePadExportResult(
          signature: signature,
          liveCapture: MyimageResult(),
        );

  /// Named constructor — pre-seeds with a full [SignaturePadExportResult]
  /// (signature + optional live-capture).
  FormFieldsSignaturePadController.fromExportResult(
      SignaturePadExportResult result)
      : _exportResult = result;

  SignaturePadExportResult? _exportResult;

  /// The current export result held by this controller.
  ///
  /// `null` until the widget exports (or until a pre-seed value is provided).
  SignaturePadExportResult? get exportResult => _exportResult;

  /// Convenience getter for the signature part of [exportResult].
  MyimageResult? get signature => _exportResult?.signature;

  /// Convenience getter for the live-capture part of [exportResult].
  MyimageResult? get liveCapture => _exportResult?.liveCapture;

  /// Replace the current result programmatically.
  ///
  /// The attached widget will synchronize its preview state on the next frame.
  void setExportResult(SignaturePadExportResult result) {
    _exportResult = result;
    notifyListeners();
  }

  /// Convenience helper — update only the signature, keeping live-capture.
  void setSignature(MyimageResult signature) {
    _exportResult = SignaturePadExportResult(
      signature: signature,
      liveCapture: _exportResult?.liveCapture ?? MyimageResult(),
    );
    notifyListeners();
  }

  /// Clear signature and live-capture.
  ///
  /// The attached widget will switch back to drawing mode on the next frame.
  void clear() {
    _exportResult = null;
    notifyListeners();
  }

  // ── Internal integration — called only by FormFieldsSignaturePad ──────────

  /// @internal — registered by [FormFieldsSignaturePad] on mount.
  VoidCallback? _clearHandler;

  // ignore: use_setters_to_change_properties
  void registerClearHandler(VoidCallback onClear) {
    _clearHandler = onClear;
  }

  void unregisterClearHandler() => _clearHandler = null;

  /// @internal — called by the widget after export.
  void updateFromWidget(SignaturePadExportResult result) {
    _exportResult = result;
    notifyListeners();
  }

  /// @internal — called by the widget after a clear action.
  void clearFromWidget() {
    _exportResult = null;
    notifyListeners();
  }

  /// Programmatically clear the attached [FormFieldsSignaturePad] widget,
  /// resetting both the drawing pad and the camera capture.
  void clearWidget() => _clearHandler?.call();
}
