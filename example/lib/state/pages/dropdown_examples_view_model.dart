import 'package:flutter/material.dart';

class DropdownExamplesViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  String? dropdown1;
  String? dropdown2;
  String? dropdown3;
  String? dropdown4;
  String? dropdown5;
  String? dropdown6;
  String? dropdown7;
  String? dropdown8;
  String? dropdown9;
  String? dropdown10;

  final List<String> countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'China',
    'Brazil',
    'India',
    'Italy',
    'Spain',
    'Mexico',
    'Russia',
    'South Korea',
    'Argentina',
    'Netherlands',
    'Sweden',
    'Switzerland',
    'Belgium',
    'Poland',
    'Norway',
    'Austria',
    'Denmark',
    'Finland',
    'Ireland',
    'Portugal',
    'Greece',
    'New Zealand',
    'Singapore',
  ];

  final List<String> colors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Purple',
    'Orange',
  ];

  final List<String> sizes = ['Small', 'Medium', 'Large', 'Extra Large'];

  void setDropdown1(String? value) {
    dropdown1 = value;
    notifyListeners();
  }

  void setDropdown2(String? value) {
    dropdown2 = value;
    notifyListeners();
  }

  void setDropdown3(String? value) {
    dropdown3 = value;
    notifyListeners();
  }

  void setDropdown4(String? value) {
    dropdown4 = value;
    notifyListeners();
  }

  void setDropdown5(String? value) {
    dropdown5 = value;
    notifyListeners();
  }

  void setDropdown6(String? value) {
    dropdown6 = value;
    notifyListeners();
  }

  void setDropdown7(String? value) {
    dropdown7 = value;
    notifyListeners();
  }

  void setDropdown8(String? value) {
    dropdown8 = value;
    notifyListeners();
  }

  void setDropdown9(String? value) {
    dropdown9 = value;
    notifyListeners();
  }

  void setDropdown10(String? value) {
    dropdown10 = value;
    notifyListeners();
  }
}
