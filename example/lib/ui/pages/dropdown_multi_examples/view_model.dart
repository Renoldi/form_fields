import 'package:flutter/material.dart';

class DropdownMultiExamplesViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  List<String> multiDropdown1 = [];
  List<String> multiDropdown2 = [];
  List<String> multiDropdown3 = [];
  List<String> multiDropdown4 = [];
  List<String> multiDropdown5 = [];
  List<String> multiDropdown6 = [];

  void setMultiDropdown1(List<String> value) {
    multiDropdown1 = value;
    notifyListeners();
  }

  void setMultiDropdown2(List<String> value) {
    multiDropdown2 = value;
    notifyListeners();
  }

  void setMultiDropdown3(List<String> value) {
    multiDropdown3 = value;
    notifyListeners();
  }

  void setMultiDropdown4(List<String> value) {
    multiDropdown4 = value;
    notifyListeners();
  }

  void setMultiDropdown5(List<String> value) {
    multiDropdown5 = value;
    notifyListeners();
  }

  void setMultiDropdown6(List<String> value) {
    multiDropdown6 = value;
    notifyListeners();
  }
}
