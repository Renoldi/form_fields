import 'package:form_fields/src/utilities/safe_notify.dart';
import 'package:form_fields/src/providers/form_fields_change_notifier.dart';

/// Manages FormFieldsDropdown internal state for locale changes
class FormFieldsDropdownNotifier extends FormFieldsChangeNotifier {
  void rebuildOnLocaleChange() {
    safeNotify(() => notifyListeners());
  }
}
