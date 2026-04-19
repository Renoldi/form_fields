import 'package:flutter/material.dart';
import 'package:form_fields/src/utilities/myimage_result.dart';

class FormFieldsMyImageController extends ChangeNotifier {
  List<MyimageResult> _images = [];

  List<MyimageResult> get images => _images;

  set images(List<MyimageResult> value) {
    _images = value;
    notifyListeners();
  }

  void addImage(MyimageResult image) {
    _images.add(image);
    notifyListeners();
  }

  void clear() {
    _images.clear();
    notifyListeners();
  }
}
