import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utils/safe_notify.dart';
import 'package:form_fields/src/utils/debug_log.dart';

class FormFieldsMyImageProvider extends ChangeNotifier {
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
    _log(
        'FormFieldsMyImageProvider.setImages -> ${_images.length} images');
    commit();
  }

  void addImage(MyImageResult image) {
    _images.add(image);
    _uploadProgress.add(0.0);
    final name = image.path.trim().isNotEmpty
        ? image.path.split(Platform.pathSeparator).last
        : (image.link.isNotEmpty ? image.link : '<no-path>');
    _log(
        'FormFieldsMyImageProvider.addImage -> added: $name (total=${_images.length})');
    commit();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      if (index < _uploadProgress.length) _uploadProgress.removeAt(index);
      _log(
          'FormFieldsMyImageProvider.removeImage -> removed index $index (total=${_images.length})');
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
          'FormFieldsMyImageProvider.updateImage -> index $index updated to: $name');
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
          .map((i) => i.path.trim().isNotEmpty
              ? i.path.split(Platform.pathSeparator).last
              : (i.link.isNotEmpty ? i.link : '<no-path>'))
          .join(', ');
      _log(
          'FormFieldsMyImageProvider.commit -> images=${_images.length}; summary=[$summary]');
    } catch (_) {
      _log(
          'FormFieldsMyImageProvider.commit -> images=${_images.length}');
    }
    safeNotify(() => notifyListeners());
  }
}
