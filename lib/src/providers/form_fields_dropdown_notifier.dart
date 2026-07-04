import 'package:flutter/material.dart';
import 'package:form_fields/src/utils/safe_notify.dart';

/// Manages FormFieldsDropdown internal state for locale changes
class FormFieldsDropdownNotifier extends ChangeNotifier {
  void rebuildOnLocaleChange() {
    safeNotify(() => notifyListeners());
  }
}
