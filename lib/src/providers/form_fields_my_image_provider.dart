import 'package:flutter/material.dart';
import 'package:form_fields/src/utilities/myimage_result.dart';

class FormFieldsMyImageProvider extends ChangeNotifier {
  List<MyImageResult> _images = [];
  List<MyImageResult> get images => _images;

  List<double> _uploadProgress = [];
  List<double> get uploadProgress => _uploadProgress;

  bool _loading = false;
  bool get loading => _loading;

  void setImages(List<MyImageResult> images) {
    _images = List<MyImageResult>.from(images);
    _uploadProgress = List<double>.filled(_images.length, 0.0).toList();
    commit();
  }

  void addImage(MyImageResult image) {
    _images.add(image);
    _uploadProgress.add(0.0);
    commit();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      _uploadProgress.removeAt(index);
      commit();
    }
  }

  void updateImage(int index, MyImageResult image) {
    if (index >= 0 && index < _images.length) {
      _images[index] = image;
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
    notifyListeners();
  }
}
