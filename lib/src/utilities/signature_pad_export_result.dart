import 'package:form_fields/src/utilities/myimage_result.dart';

/// Result of a signature pad export, optionally including a live camera capture.
class SignaturePadExportResult {
  /// The exported signature image.
  final MyimageResult signature;

  /// The live camera capture taken at export time (null if live camera disabled
  /// or no photo was captured).
  final MyimageResult? liveCapture;

  const SignaturePadExportResult({
    required this.signature,
    this.liveCapture,
  });
}
