import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utilities/enums.dart';

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

/// Variant of `SignaturePadExportResult` where each field may be null to
/// indicate the item did not fail (null = no error) or was not queued.
class SignaturePadExportNullableResult {
  final MyImageResult? signature;
  final MyImageResult? liveCapture;

  const SignaturePadExportNullableResult({this.signature, this.liveCapture});

  /// Create from an existing `SignaturePadExportResult` and null out fields
  /// that match `successStatus` (default: `MyImageStatus.uploaded`).
  factory SignaturePadExportNullableResult.fromExportResult(
    SignaturePadExportResult result, {
    MyImageStatus successStatus = MyImageStatus.uploaded,
  }) {
    final sig = result.signature.status == successStatus
        ? null
        : result.signature;
    final live = result.liveCapture.status == successStatus
        ? null
        : result.liveCapture;
    return SignaturePadExportNullableResult(signature: sig, liveCapture: live);
  }

  /// Create from raw parts directly.
  factory SignaturePadExportNullableResult.fromParts({
    MyImageResult? signature,
    MyImageResult? liveCapture,
  }) {
    return SignaturePadExportNullableResult(
      signature: signature,
      liveCapture: liveCapture,
    );
  }

  /// True when at least one side represents a failure/queued item.
  bool get hasAny => signature != null || liveCapture != null;
}
