import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:form_fields_example/data/models/product.dart';
import 'package:form_fields/form_fields.dart';

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

  // ── Offline upload queue (example implementation) ────────────────
  int _offlineQueueCount = 0;

  int get offlineQueueCount => _offlineQueueCount;

  // Simple in-memory preview store for queued offline payloads.
  final List<OfflinePreview> _offlinePreviews = [];
  List<OfflinePreview> get offlinePreviews =>
      List.unmodifiable(_offlinePreviews);

  Future<void> handleDirectUploadPayload(
      Map<String, dynamic> payload, MyImageResult image, int index) async {
    try {
      final file = File(
          '${Directory.systemTemp.path}/form_fields_offline_payloads.json');
      List<dynamic> arr = [];
      if (await file.exists()) {
        final s = await file.readAsString();
        if (s.trim().isNotEmpty) {
          try {
            arr = jsonDecode(s);
          } catch (_) {
            arr = [];
          }
        }
      }
      arr.add(payload);
      await file.writeAsString(jsonEncode(arr));
      _offlineQueueCount = arr.length;

      // Also keep a lightweight preview (path/base64) in memory so the UI
      // can immediately show the image that couldn't be uploaded.
      try {
        final fileMap = (payload['file'] is Map)
            ? Map<String, dynamic>.from(payload['file'])
            : <String, dynamic>{};
        final pPath = (fileMap['path'] is String &&
                (fileMap['path'] as String).trim().isNotEmpty)
            ? fileMap['path'] as String
            : null;
        final pBase64 = (fileMap['base64'] is String &&
                (fileMap['base64'] as String).trim().isNotEmpty)
            ? fileMap['base64'] as String
            : null;
        _offlinePreviews.add(OfflinePreview(path: pPath, base64: pBase64));
      } catch (_) {
        // ignore
      }

      notifyListeners();
    } catch (e) {
      // Best-effort for example: log only
      // ignore: avoid_print
      print('Failed to enqueue offline payload: $e');
    }
  }
}

class OfflinePreview {
  final String? path;
  final String? base64;
  final DateTime createdAt;

  OfflinePreview({this.path, this.base64}) : createdAt = DateTime.now();
}
