import 'package:flutter/material.dart';

class RadioButtonExamplesViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  String radio1 = '';
  String radio2 = '';
  String radio3 = '';
  String radio4 = '';
  String radio5 = '';
  String radio6 = '';
  String radio7 = '';
  String radio8 = '';

  void setRadio1(String value) {
    radio1 = value;
    notifyListeners();
  }

  void setRadio2(String value) {
    radio2 = value;
    notifyListeners();
  }

  void setRadio3(String value) {
    radio3 = value;
    notifyListeners();
  }

  void setRadio4(String value) {
    radio4 = value;
    notifyListeners();
  }

  void setRadio5(String value) {
    radio5 = value;
    notifyListeners();
  }

  void setRadio6(String value) {
    radio6 = value;
    notifyListeners();
  }

  void setRadio7(String value) {
    radio7 = value;
    notifyListeners();
  }

  void setRadio8(String value) {
    radio8 = value;
    notifyListeners();
  }
}
