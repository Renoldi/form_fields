import 'package:form_fields/src/utilities/safe_notify.dart';
import 'package:form_fields/src/providers/form_fields_change_notifier.dart';

/// Manages FormFields internal state including selected country code and locale changes
class FormFieldsNotifier extends FormFieldsChangeNotifier {
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
