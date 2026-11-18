import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/providers/form_fields_change_notifier.dart';

/// State of a [FormFieldsLiveCameraCapture]: the captured frame and the upload
/// progress (shared through [FormFieldsUploadProgressMixin]).
class FormFieldsLiveCameraCaptureProvider extends FormFieldsChangeNotifier
    with FormFieldsUploadProgressMixin {
  MyImageResult? _capturedResult;
  MyImageResult? get capturedResult => _capturedResult;

  void setCapturedResult(MyImageResult? result) {
    _capturedResult = result;
    notifySafely();
  }

  void notifyCameraReady() => notifySafely();
}
