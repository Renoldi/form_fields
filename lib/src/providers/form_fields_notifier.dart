import 'package:flutter/material.dart';

/// Manages FormFields internal state including selected country code and locale changes
class FormFieldsNotifier extends ChangeNotifier {
  String _selectedCountryCode = '';

  String get selectedCountryCode => _selectedCountryCode;

  void setSelectedCountryCode(String code) {
    _selectedCountryCode = code;
    notifyListeners();
  }

  void rebuildOnLocaleChange() {
    notifyListeners();
  }

  void rebuildOnUpdate() {
    notifyListeners();
  }
}
