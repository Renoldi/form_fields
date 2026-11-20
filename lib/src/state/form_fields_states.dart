/// State holders for the core FormFields widget: the field controller and
/// the notifier that rebuilds it on country or locale changes.
library;

import 'package:form_fields/form_fields.dart';
import 'package:material_ui/material_ui.dart';

/// Controller for managing FormFields state
class FormFieldsController extends FormFieldsChangeNotifier {
  /// Notify listeners of changes
  void commit() {
    notifySafely();
  }

  /// Form value storage
  String _form = "";
  String get form => _form;
  set form(String form) {
    _form = form;
    commit();
  }

  void vForm(String form) {
    _form = form;
    commit();
  }

  /// Password obscurity state
  bool _obscure = true;
  bool get obscure => _obscure;
  set obscure(bool obscure) {
    _obscure = obscure;
    commit();
  }

  void vObscure(bool obscure) {
    _obscure = obscure;
    commit();
  }

  /// Text editing controller
  TextEditingController controller = TextEditingController();
  String get getController => controller.text;
  set setController(String value) {
    controller.text = value;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    commit();
  }

  /// Set controller text without notifying listeners (for initialization)
  void setControllerSilent(String value) {
    controller.text = value;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  /// Form type
  FormType? formType;

  /// Field label
  String label = "";

  /// Label display state
  bool isLabel = false;

  /// 100 years duration (used for date picker)
  Duration d100YEARS = const Duration(days: 365 * 100);

  /// Validity state
  bool _isValid = true;
  bool get isValid => _isValid;
  set isValid(bool isValid) {
    _isValid = isValid;
    commit();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Manages FormFields internal state including selected country code and locale changes
class FormFieldsNotifier extends FormFieldsChangeNotifier {
  String _selectedCountryCode = '';

  String get selectedCountryCode => _selectedCountryCode;

  void setSelectedCountryCode(String code) {
    _selectedCountryCode = code;
    notifySafely();
  }

  void rebuildOnLocaleChange() {
    notifySafely();
  }

  void rebuildOnUpdate() {
    notifySafely();
  }
}
