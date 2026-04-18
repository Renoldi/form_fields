import 'package:flutter/material.dart';
import 'package:form_fields_example/data/models/product.dart';

class FormFieldsExamplesViewModel extends ChangeNotifier {
  String autocompleteCustomQueryParamResult = '';
  String autocompleteTokenResult = '';
  String autocompleteCustomResultProcessorResult = '';
  String autocompleteCustomDecorationResult = '';
  String autocompleteSuffixIconResult = '';
  String autocompleteRemoveSuffixIconResult = '';
  String autocompleteOutlineBorderResult = '';
  String autocompleteUnderlineBorderResult = '';
  String autocompleteNoBorderResult = '';

  void updateAutocompleteCustomQueryParamResult(String? value) {
    autocompleteCustomQueryParamResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteTokenResult(String? value) {
    autocompleteTokenResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteCustomResultProcessorResult(String? value) {
    autocompleteCustomResultProcessorResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteCustomDecorationResult(String? value) {
    autocompleteCustomDecorationResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteSuffixIconResult(String? value) {
    autocompleteSuffixIconResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteRemoveSuffixIconResult(String? value) {
    autocompleteRemoveSuffixIconResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteOutlineBorderResult(String? value) {
    autocompleteOutlineBorderResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteUnderlineBorderResult(String? value) {
    autocompleteUnderlineBorderResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteNoBorderResult(String? value) {
    autocompleteNoBorderResult = value ?? '';
    notifyListeners();
  }

  String autocompleteLabelBottomResult = '';
  String autocompleteLabelLeftResult = '';
  String autocompleteLabelRightResult = '';

  void updateAutocompleteLabelBottomResult(String? value) {
    autocompleteLabelBottomResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteLabelLeftResult(String? value) {
    autocompleteLabelLeftResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteLabelRightResult(String? value) {
    autocompleteLabelRightResult = value ?? '';
    notifyListeners();
  }

  String autocompleteResult = '';
  String autocompleteOutlineResult = '';
  String autocompleteUnderlineResult = '';
  String autocompleteNoneResult = '';

  void updateAutocompleteResult(String? value) {
    autocompleteResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteOutlineResult(String? value) {
    autocompleteOutlineResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteUnderlineResult(String? value) {
    autocompleteUnderlineResult = value ?? '';
    notifyListeners();
  }

  void updateAutocompleteNoneResult(String? value) {
    autocompleteNoneResult = value ?? '';
    notifyListeners();
  }

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
  String verificationCode = '';
  String verificationCodeNoOtp = '';
  String verificationCodeHiddenOtp = '';
  String verificationCodeHiddenSingle = '';
  String verificationCodeStyled = '';
  String otp4Code = '';

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
  // For Product autocomplete demo
  Product? selectedProduct;

  void updateSelectedProduct(Product? value) {
    selectedProduct = value;
    notifyListeners();
  }

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

  void updateVerificationCode(String value) {
    verificationCode = value;
    notifyListeners();
  }

  void updateVerificationCodeNoOtp(String value) {
    verificationCodeNoOtp = value;
    notifyListeners();
  }

  void updateVerificationCodeHiddenOtp(String value) {
    verificationCodeHiddenOtp = value;
    notifyListeners();
  }

  void updateVerificationCodeHiddenSingle(String value) {
    verificationCodeHiddenSingle = value;
    notifyListeners();
  }

  void updateVerificationCodeStyled(String value) {
    verificationCodeStyled = value;
    notifyListeners();
  }

  void updateOtp4Code(String value) {
    otp4Code = value;
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
