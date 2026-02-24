/// State management controller for FormFields
import 'package:flutter/material.dart';
import 'enums.dart';

/// Controller for managing FormFields state
class FormFieldsController extends ChangeNotifier {
  /// Notify listeners of changes
  void commit() {
    notifyListeners();
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
  FormType _formType = FormType.string;
  FormType get formType => _formType;
  set formType(FormType formType) {
    _formType = formType;
  }

  /// Field label
  String _label = "";
  String get label => _label;
  set label(String label) {
    _label = label;
  }

  /// Label display state
  bool _isLabel = false;
  bool get isLabel => _isLabel;
  set isLabel(bool isLabel) {
    _isLabel = isLabel;
  }

  /// 100 years duration (used for date picker)
  Duration _d100YEARS = const Duration(days: 365 * 100);
  Duration get d100YEARS => _d100YEARS;
  set d100YEARS(Duration d100YEARS) {
    _d100YEARS = d100YEARS;
  }

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
