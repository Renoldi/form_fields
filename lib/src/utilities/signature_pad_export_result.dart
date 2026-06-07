import 'package:form_fields/src/models/myimage_result.dart';

/// Result of a signature pad export, optionally including a live camera capture.
class SignaturePadExportResult {
  /// The exported signature image.
  final MyImageResult signature;

  /// The live camera capture taken at export time (null if live camera disabled
  /// or no photo was captured).
  /// This is required and always present when exporting.
  final MyImageResult liveCapture;

  const SignaturePadExportResult({
    required this.signature,
    required this.liveCapture,
  });
}
