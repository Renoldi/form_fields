import 'package:flutter/material.dart';
import 'package:form_fields/src/models/myimage_result.dart';

class FormFieldsMyImageController extends ChangeNotifier {
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
    notifyListeners();
  }

  /// Replaces all images.
  void setImages(List<MyImageResult> images) {
    _images = List<MyImageResult>.from(images);
    notifyListeners();
  }

  /// Backward-compatible alias (optional).
  @Deprecated('Use setImages instead')
  void setNetworkUrls(List<MyImageResult> images) => setImages(images);

  /// Backward-compatible alias (optional).
  @Deprecated('Use setImages instead')
  void setLinks(List<MyImageResult> images) => setImages(images);

  void addImage(MyImageResult image) {
    _images.add(image);
    notifyListeners();
  }

  void clear() {
    _images.clear();
    notifyListeners();
  }

  // ── Capture integration ──────────────────────────────────────────────────

  /// Registered by [FormFieldsLiveCameraCapture] when it mounts.
  Future<MyImageResult?> Function()? _captureHandler;
  VoidCallback? _resetHandler;

  /// @internal — called by [FormFieldsLiveCameraCapture].
  // ignore: use_setters_to_change_properties
  void registerCaptureHandler(
    Future<MyImageResult?> Function() onCapture,
    VoidCallback onReset,
  ) {
    _captureHandler = onCapture;
    _resetHandler = onReset;
  }

  /// @internal — called by [FormFieldsLiveCameraCapture] on dispose.
  void unregisterCaptureHandler() {
    _captureHandler = null;
    _resetHandler = null;
  }

  /// Programmatically trigger a capture from the linked
  /// [FormFieldsLiveCameraCapture] widget.
  ///
  /// Returns [MyImageResult] on success, or `null` if no widget is attached
  /// or the camera is not ready.
  Future<MyImageResult?> capture() =>
      _captureHandler?.call() ?? Future.value(null);

  /// Programmatically reset the linked [FormFieldsLiveCameraCapture] widget
  /// back to live-preview mode and clear captured images.
  void resetCapture() => _resetHandler?.call();

  // ── FormFieldsMyImage pick integration ───────────────────────────────────

  /// Registered by [FormFieldsMyImage] when it mounts with an external controller.
  Future<void> Function(String? source)? _pickImageHandler;

  /// @internal — called by [FormFieldsMyImage].
  // ignore: use_setters_to_change_properties
  void registerPickImageHandler(Future<void> Function(String? source) handler) {
    _pickImageHandler = handler;
  }

  /// @internal — called by [FormFieldsMyImage] on dispose.
  void unregisterPickImageHandler() {
    _pickImageHandler = null;
  }

  /// Programmatically open the image picker on the linked [FormFieldsMyImage].
  ///
  /// [source] can be `'camera'`, `'gallery'`, or `null` to show the
  /// bottom-sheet chooser. Returns immediately if no widget is attached.
  Future<void> pickImage({String? source}) =>
      _pickImageHandler?.call(source) ?? Future.value();
}
