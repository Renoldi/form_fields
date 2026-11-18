import 'package:material_ui/material_ui.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utilities/safe_notify.dart';
import 'package:form_fields/src/providers/form_fields_change_notifier.dart';

class FormFieldsMyImageController extends FormFieldsChangeNotifier {
  FormFieldsMyImageController({List<MyImageResult>? initialImages})
      : _images = List<MyImageResult>.from(initialImages ?? const []);

  /// Preferred named constructor for prefilled images.
  FormFieldsMyImageController.fromImages(List<MyImageResult> images)
      : _images = List<MyImageResult>.from(images);

  /// Backward-compatible alias (optional).
  @Deprecated('Use FormFieldsMyImageController.fromImages instead')
  FormFieldsMyImageController.fromNetworkUrls(List<MyImageResult> images)
      : this.fromImages(images);

  /// Backward-compatible alias (optional).
  @Deprecated('Use FormFieldsMyImageController.fromImages instead')
  FormFieldsMyImageController.fromLinks(List<MyImageResult> images)
      : this.fromImages(images);

  List<MyImageResult> _images;

  List<MyImageResult> get images => List<MyImageResult>.unmodifiable(_images);

  set images(List<MyImageResult> value) {
    _images = List<MyImageResult>.from(value);
    safeNotify(() => notifyListeners());
  }

  /// Replaces all images.
  void setImages(List<MyImageResult> images) {
    _images = List<MyImageResult>.from(images);
    safeNotify(() => notifyListeners());
  }

  /// Backward-compatible alias (optional).
  @Deprecated('Use setImages instead')
  void setNetworkUrls(List<MyImageResult> images) => setImages(images);

  /// Backward-compatible alias (optional).
  @Deprecated('Use setImages instead')
  void setLinks(List<MyImageResult> images) => setImages(images);

  void addImage(MyImageResult image) {
    _images.add(image);
    safeNotify(() => notifyListeners());
  }

  void clear() {
    _images.clear();
    safeNotify(() => notifyListeners());
  }

  // ── Capture integration ──────────────────────────────────────────────────

  /// Registered by [FormFieldsLiveCameraCapture] when it mounts.
  final FormFieldsHandlerSlot<Future<MyImageResult?> Function()> _capture =
      FormFieldsHandlerSlot();
  final FormFieldsHandlerSlot<VoidCallback> _reset = FormFieldsHandlerSlot();

  /// @internal — called by [FormFieldsLiveCameraCapture].
  void registerCaptureHandler(
    Future<MyImageResult?> Function() onCapture,
    VoidCallback onReset,
  ) {
    _capture.register(onCapture);
    _reset.register(onReset);
  }

  /// @internal — called by [FormFieldsLiveCameraCapture] on dispose.
  void unregisterCaptureHandler() {
    _capture.unregister();
    _reset.unregister();
  }

  /// Programmatically trigger a capture from the linked
  /// [FormFieldsLiveCameraCapture] widget.
  ///
  /// Returns [MyImageResult] on success, or `null` if no widget is attached
  /// or the camera is not ready.
  Future<MyImageResult?> capture() =>
      _capture.handler?.call() ?? Future.value(null);

  /// Programmatically reset the linked [FormFieldsLiveCameraCapture] widget
  /// back to live-preview mode and clear captured images.
  void resetCapture() => _reset.handler?.call();

  // ── FormFieldsMyImage pick integration ───────────────────────────────────

  /// Registered by [FormFieldsMyImage] when it mounts with an external controller.
  final FormFieldsHandlerSlot<Future<void> Function(String? source)> _pickImage =
      FormFieldsHandlerSlot();

  /// @internal — called by [FormFieldsMyImage].
  void registerPickImageHandler(Future<void> Function(String? source) handler) {
    _pickImage.register(handler);
  }

  /// @internal — called by [FormFieldsMyImage] on dispose.
  void unregisterPickImageHandler() => _pickImage.unregister();

  /// Programmatically open the image picker on the linked [FormFieldsMyImage].
  ///
  /// [source] can be `'camera'`, `'gallery'`, or `null` to show the
  /// bottom-sheet chooser. Returns immediately if no widget is attached.
  Future<void> pickImage({String? source}) =>
      _pickImage.handler?.call(source) ?? Future.value();
}
