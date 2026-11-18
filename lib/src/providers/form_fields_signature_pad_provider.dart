import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/providers/form_fields_change_notifier.dart';

/// State of a [FormFieldsSignaturePad]: the preview images and the upload
/// progress (shared through [FormFieldsUploadProgressMixin]).
class FormFieldsSignaturePadProvider extends FormFieldsChangeNotifier
    with FormFieldsUploadProgressMixin {
  MyImageResult? _previewSignatureResult;
  MyImageResult? get previewSignatureResult => _previewSignatureResult;

  MyImageResult? _previewLiveCaptureResult;
  MyImageResult? get previewLiveCaptureResult => _previewLiveCaptureResult;

  void setPreviewResults({
    required MyImageResult? signature,
    required MyImageResult? liveCapture,
  }) {
    _previewSignatureResult = signature;
    _previewLiveCaptureResult = liveCapture;
    notifySafely();
  }

  void clearPreviewResults() {
    _previewSignatureResult = null;
    _previewLiveCaptureResult = null;
    notifySafely();
  }
}
