/// State holders for the image-based fields: MyImage, SignaturePad and
/// LiveCameraCapture. They share the upload-progress mixin from
/// `form_fields_change_notifier.dart`.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/models/signature_pad_export_result.dart';
import 'package:form_fields/src/state/form_fields_change_notifier.dart';
import 'package:form_fields/src/utilities/debug_log.dart';

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
    notifySafely();
  }

  /// Replaces all images.
  void setImages(List<MyImageResult> images) {
    _images = List<MyImageResult>.from(images);
    notifySafely();
  }

  /// Backward-compatible alias (optional).
  @Deprecated('Use setImages instead')
  void setNetworkUrls(List<MyImageResult> images) => setImages(images);

  /// Backward-compatible alias (optional).
  @Deprecated('Use setImages instead')
  void setLinks(List<MyImageResult> images) => setImages(images);

  void addImage(MyImageResult image) {
    _images.add(image);
    notifySafely();
  }

  void clear() {
    _images.clear();
    notifySafely();
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
  final FormFieldsHandlerSlot<Future<void> Function(String? source)>
  _pickImage = FormFieldsHandlerSlot();

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

class FormFieldsMyImageProvider extends FormFieldsChangeNotifier {
  /// Debug-only logging. Release builds must not print file names and paths.
  static void _log(String message) {
    if (kDebugMode) debugLog(message);
  }

  List<MyImageResult> _images = [];
  List<MyImageResult> get images => _images;

  List<double> _uploadProgress = [];
  List<double> get uploadProgress => _uploadProgress;

  bool _loading = false;
  bool get loading => _loading;

  void setImages(List<MyImageResult> images) {
    _images = List<MyImageResult>.from(images);
    // Keep the progress of images that are still there. This runs on every
    // controller change, and resetting progress here made an upload in
    // progress jump back to zero.
    final previous = _uploadProgress;
    _uploadProgress = List<double>.generate(
      _images.length,
      (i) => i < previous.length ? previous[i] : 0.0,
    );
    _log('FormFieldsMyImageProvider.setImages -> ${_images.length} images');
    commit();
  }

  void addImage(MyImageResult image) {
    _images.add(image);
    _uploadProgress.add(0.0);
    final name = image.path.trim().isNotEmpty
        ? image.path.split(Platform.pathSeparator).last
        : (image.link.isNotEmpty ? image.link : '<no-path>');
    _log(
      'FormFieldsMyImageProvider.addImage -> added: $name (total=${_images.length})',
    );
    commit();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      if (index < _uploadProgress.length) _uploadProgress.removeAt(index);
      _log(
        'FormFieldsMyImageProvider.removeImage -> removed index $index (total=${_images.length})',
      );
      commit();
    }
  }

  void updateImage(int index, MyImageResult image) {
    if (index >= 0 && index < _images.length) {
      _images[index] = image;
      final name = image.path.trim().isNotEmpty
          ? image.path.split(Platform.pathSeparator).last
          : (image.link.isNotEmpty ? image.link : '<no-path>');
      _log(
        'FormFieldsMyImageProvider.updateImage -> index $index updated to: $name',
      );
      commit();
    }
  }

  void clearImages() {
    _images.clear();
    _uploadProgress = [];
    commit();
  }

  void setUploadProgress(int index, double progress) {
    while (_uploadProgress.length <= index) {
      _uploadProgress.add(0.0);
    }
    _uploadProgress[index] = progress;
    commit();
  }

  void resetUploadProgress(int index) {
    if (index >= 0 && index < _uploadProgress.length) {
      _uploadProgress[index] = 0.0;
      commit();
    }
  }

  void setLoading(bool value) {
    _loading = value;
    commit();
  }

  void commit() {
    try {
      final summary = _images
          .map(
            (i) => i.path.trim().isNotEmpty
                ? i.path.split(Platform.pathSeparator).last
                : (i.link.isNotEmpty ? i.link : '<no-path>'),
          )
          .join(', ');
      _log(
        'FormFieldsMyImageProvider.commit -> images=${_images.length}; summary=[$summary]',
      );
    } catch (_) {
      _log('FormFieldsMyImageProvider.commit -> images=${_images.length}');
    }
    notifySafely();
  }
}

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
///   MyImageResult.network('https://example.com/existing-signature.png'),
/// );
/// ```
class FormFieldsSignaturePadController extends FormFieldsChangeNotifier {
  FormFieldsSignaturePadController();

  /// Named constructor — pre-seeds with an existing signature result.
  ///
  /// When attached to [FormFieldsSignaturePad], the pad will immediately render
  /// this image in preview mode (same as if the user had just exported it).
  FormFieldsSignaturePadController.fromSignature(MyImageResult signature)
    : _exportResult = SignaturePadExportResult(
        signature: signature,
        liveCapture: MyImageResult(),
      );

  /// Named constructor — pre-seeds with a full [SignaturePadExportResult]
  /// (signature + optional live-capture).
  FormFieldsSignaturePadController.fromExportResult(
    SignaturePadExportResult result,
  ) : _exportResult = result;

  SignaturePadExportResult? _exportResult;

  /// The current export result held by this controller.
  ///
  /// `null` until the widget exports (or until a pre-seed value is provided).
  SignaturePadExportResult? get exportResult => _exportResult;

  /// Convenience getter for the signature part of [exportResult].
  MyImageResult? get signature => _exportResult?.signature;

  /// Convenience getter for the live-capture part of [exportResult].
  MyImageResult? get liveCapture => _exportResult?.liveCapture;

  /// Replace the current result programmatically.
  ///
  /// The attached widget will synchronize its preview state on the next frame.
  void setExportResult(SignaturePadExportResult result) {
    _exportResult = result;
    notifySafely();
  }

  /// Convenience helper — update only the signature, keeping live-capture.
  void setSignature(MyImageResult signature) {
    _exportResult = SignaturePadExportResult(
      signature: signature,
      liveCapture: _exportResult?.liveCapture ?? MyImageResult(),
    );
    notifySafely();
  }

  /// Clear signature and live-capture.
  ///
  /// The attached widget will switch back to drawing mode on the next frame.
  void clear() {
    _exportResult = null;
    notifySafely();
  }

  // ── Internal integration — called only by FormFieldsSignaturePad ──────────

  /// @internal — registered by [FormFieldsSignaturePad] on mount.
  final FormFieldsHandlerSlot<VoidCallback> _clear = FormFieldsHandlerSlot();

  void registerClearHandler(VoidCallback onClear) => _clear.register(onClear);

  void unregisterClearHandler() => _clear.unregister();

  /// @internal — called by the widget after export.
  void updateFromWidget(SignaturePadExportResult result) {
    _exportResult = result;
    notifySafely();
  }

  /// @internal — called by the widget after a clear action.
  void clearFromWidget() {
    _exportResult = null;
    notifySafely();
  }

  /// Programmatically clear the attached [FormFieldsSignaturePad] widget,
  /// resetting both the drawing pad and the camera capture.
  void clearWidget() => _clear.handler?.call();
}

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
