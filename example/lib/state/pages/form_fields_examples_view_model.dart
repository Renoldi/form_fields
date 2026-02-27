import 'package:flutter/material.dart';

class FormFieldsExamplesViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final focusNode1 = FocusNode();
  final focusNode2 = FocusNode();

  String string1 = '';
  String? string2;
  String stringCustom = '';
  String email = '';
  String phone = '';
  String phoneWithCountryCode = '';
  String phoneFormatted = '';
  String password = '';

  int int1 = 0;
  int? int2;

  double double1 = 0.0;
  double? double2;

  DateTime date1 = DateTime.now();
  DateTime? date2;

  TimeOfDay time1 = TimeOfDay.now();
  TimeOfDay? time2;

  DateTimeRange range1 =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  DateTimeRange? range2;

  void updateString1(String value) {
    string1 = value;
    notifyListeners();
  }

  void updateString2(String? value) {
    string2 = value;
    notifyListeners();
  }

  void updateStringCustom(String value) {
    stringCustom = value;
    notifyListeners();
  }

  void updateEmail(String value) {
    email = value;
    notifyListeners();
  }

  void updatePhone(String value) {
    phone = value;
    notifyListeners();
  }

  void updatePhoneWithCountryCode(String value) {
    phoneWithCountryCode = value;
    notifyListeners();
  }

  void updatePhoneFormatted(String value) {
    phoneFormatted = value;
    notifyListeners();
  }

  void updatePassword(String value) {
    password = value;
    notifyListeners();
  }

  void updateInt1(int value) {
    int1 = value;
    notifyListeners();
  }

  void updateInt2(int? value) {
    int2 = value;
    notifyListeners();
  }

  void updateDouble1(double value) {
    double1 = value;
    notifyListeners();
  }

  void updateDouble2(double? value) {
    double2 = value;
    notifyListeners();
  }

  void updateDate1(DateTime value) {
    date1 = value;
    notifyListeners();
  }

  void updateDate2(DateTime? value) {
    date2 = value;
    notifyListeners();
  }

  void updateTime1(TimeOfDay value) {
    time1 = value;
    notifyListeners();
  }

  void updateTime2(TimeOfDay? value) {
    time2 = value;
    notifyListeners();
  }

  void updateRange1(DateTimeRange value) {
    range1 = value;
    notifyListeners();
  }

  void updateRange2(DateTimeRange? value) {
    range2 = value;
    notifyListeners();
  }

  @override
  void dispose() {
    focusNode1.dispose();
    focusNode2.dispose();
    super.dispose();
  }
}
