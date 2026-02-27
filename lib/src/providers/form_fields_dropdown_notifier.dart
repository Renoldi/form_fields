import 'package:flutter/material.dart';

/// Manages FormFieldsDropdown internal state for locale changes
class FormFieldsDropdownNotifier extends ChangeNotifier {
  void rebuildOnLocaleChange() {
    notifyListeners();
  }
}
