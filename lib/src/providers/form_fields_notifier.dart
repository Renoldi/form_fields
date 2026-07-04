import 'package:flutter/material.dart';
import 'package:form_fields/src/utils/safe_notify.dart';

/// Manages FormFields internal state including selected country code and locale changes
class FormFieldsNotifier extends ChangeNotifier {
  String _selectedCountryCode = '';

  String get selectedCountryCode => _selectedCountryCode;

  void setSelectedCountryCode(String code) {
    _selectedCountryCode = code;
    safeNotify(() => notifyListeners());
  }

  void rebuildOnLocaleChange() {
    safeNotify(() => notifyListeners());
  }

  void rebuildOnUpdate() {
    safeNotify(() => notifyListeners());
  }
}
