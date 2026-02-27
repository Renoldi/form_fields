import 'package:flutter/material.dart';

class CheckboxExamplesViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  List<String> checkbox1 = [];
  List<String> checkbox2 = [];
  List<String> checkbox3 = [];
  List<String> checkbox4 = [];
  List<String> checkbox5 = [];
  List<String> checkbox6 = [];
  List<String> checkbox7 = [];
  List<String> checkbox8 = [];

  void setCheckbox1(List<String> value) {
    checkbox1 = value;
    notifyListeners();
  }

  void setCheckbox2(List<String> value) {
    checkbox2 = value;
    notifyListeners();
  }

  void setCheckbox3(List<String> value) {
    checkbox3 = value;
    notifyListeners();
  }

  void setCheckbox4(List<String> value) {
    checkbox4 = value;
    notifyListeners();
  }

  void setCheckbox5(List<String> value) {
    checkbox5 = value;
    notifyListeners();
  }

  void setCheckbox6(List<String> value) {
    checkbox6 = value;
    notifyListeners();
  }

  void setCheckbox7(List<String> value) {
    checkbox7 = value;
    notifyListeners();
  }

  void setCheckbox8(List<String> value) {
    checkbox8 = value;
    notifyListeners();
  }
}
