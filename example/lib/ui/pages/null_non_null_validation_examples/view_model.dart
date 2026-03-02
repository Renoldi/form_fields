import 'package:flutter/material.dart';

class NullNonNullValidationExamplesViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  String stringNonNullRequired = '';
  String stringNonNullOptional = '';
  String? stringNullRequired;
  String? stringNullOptional;

  int intNonNullRequired = 0;
  int intNonNullOptional = 0;
  int? intNullRequired;
  int? intNullOptional;

  double doubleNonNullRequired = 0.0;
  double doubleNonNullOptional = 0.0;
  double? doubleNullRequired;
  double? doubleNullOptional;

  String usernameCustom = '';
  String? emailCustom;
  int ageCustom = 0;

  void setStringNonNullRequired(String value) {
    stringNonNullRequired = value;
    notifyListeners();
  }

  void setStringNonNullOptional(String value) {
    stringNonNullOptional = value;
    notifyListeners();
  }

  void setStringNullRequired(String? value) {
    stringNullRequired = value;
    notifyListeners();
  }

  void setStringNullOptional(String? value) {
    stringNullOptional = value;
    notifyListeners();
  }

  void setIntNonNullRequired(int value) {
    intNonNullRequired = value;
    notifyListeners();
  }

  void setIntNonNullOptional(int value) {
    intNonNullOptional = value;
    notifyListeners();
  }

  void setIntNullRequired(int? value) {
    intNullRequired = value;
    notifyListeners();
  }

  void setIntNullOptional(int? value) {
    intNullOptional = value;
    notifyListeners();
  }

  void setDoubleNonNullRequired(double value) {
    doubleNonNullRequired = value;
    notifyListeners();
  }

  void setDoubleNonNullOptional(double value) {
    doubleNonNullOptional = value;
    notifyListeners();
  }

  void setDoubleNullRequired(double? value) {
    doubleNullRequired = value;
    notifyListeners();
  }

  void setDoubleNullOptional(double? value) {
    doubleNullOptional = value;
    notifyListeners();
  }

  void setUsernameCustom(String value) {
    usernameCustom = value;
    notifyListeners();
  }

  void setEmailCustom(String? value) {
    emailCustom = value;
    notifyListeners();
  }

  void setAgeCustom(int value) {
    ageCustom = value;
    notifyListeners();
  }
}
