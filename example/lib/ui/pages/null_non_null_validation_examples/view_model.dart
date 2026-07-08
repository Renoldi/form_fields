import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {
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
  // Selection widget state
  List<String> checkboxSelected = [];
  List<String> dropdownMultiSelected = [];
  String? dropdownSelected;
  String? radioSelected;
  // Read-only demo state
  List<String> checkboxReadOnlySelected = [];
  List<String> dropdownMultiReadOnlySelected = [];
  String? dropdownReadOnlySelected;
  String? radioReadOnlySelected;
  // Date/time and OTP examples
  DateTime? dateRequired;
  DateTime? dateTimeRequired;
  DateTimeRange? rangeRequired;
  String verificationOtp = '';

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

  void setCheckboxSelected(List<String> values) {
    checkboxSelected = values;
    notifyListeners();
  }

  void setCheckboxReadOnlySelected(List<String> values) {
    checkboxReadOnlySelected = values;
    notifyListeners();
  }

  void setDropdownMultiSelected(List<String> values) {
    dropdownMultiSelected = values;
    notifyListeners();
  }

  void setDropdownMultiReadOnlySelected(List<String> values) {
    dropdownMultiReadOnlySelected = values;
    notifyListeners();
  }

  void setDropdownSelected(String? value) {
    dropdownSelected = value;
    notifyListeners();
  }

  void setDropdownReadOnlySelected(String? value) {
    dropdownReadOnlySelected = value;
    notifyListeners();
  }

  void setRadioSelected(String? value) {
    radioSelected = value;
    notifyListeners();
  }

  void setRadioReadOnlySelected(String? value) {
    radioReadOnlySelected = value;
    notifyListeners();
  }

  void setDateRequired(DateTime? value) {
    dateRequired = value;
    notifyListeners();
  }

  void setDateTimeRequired(DateTime? value) {
    dateTimeRequired = value;
    notifyListeners();
  }

  void setRangeRequired(DateTimeRange? value) {
    rangeRequired = value;
    notifyListeners();
  }

  void setVerificationOtp(String value) {
    verificationOtp = value;
    notifyListeners();
  }
}
