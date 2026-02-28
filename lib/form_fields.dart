/// ---------------------------------------------------------------------------
/// FormFields Package
/// ---------------------------------------------------------------------------
/// A comprehensive, beautiful, and easy-to-use Flutter form field widget suite.
///
/// Features:
///   - All field types: text, dropdown, multi-select, radio, checkbox, etc.
///   - Full label position support: top, bottom, left, right, inBorder, none
///   - Professional UI, error handling, and localization
///   - Modular, maintainable, and extensible
///
/// ---------------------------------------------------------------------------
/// Quick Usage Example:
/// ---------------------------------------------------------------------------
/// import 'package:form_fields/form_fields.dart';
///
/// FormFields<String>(
///   label: 'Email',
///   formType: FormType.email,
///   labelPosition: LabelPosition.top,
///   onChanged: (value) { /* ... */ },
/// )
/// ---------------------------------------------------------------------------

library;

// -------------------
// Core FormFields API
// -------------------
export 'src/form_fields.dart' show FormFields;

// -------------------
// Field Widgets
// -------------------
export 'src/form_fields_select.dart' show FormFieldsSelect;
export 'src/form_fields_dropdown.dart' show FormFieldsDropdown;
export 'src/form_fields_dropdown_multi.dart' show FormFieldsDropdownMulti;
export 'src/form_fields_radio_button.dart' show FormFieldsRadioButton;
export 'src/form_fields_checkbox.dart' show FormFieldsCheckbox;

// -------------------
// Utilities & Enums
// -------------------
export 'src/utilities/enums.dart';
export 'src/utilities/controller.dart';
export 'src/utilities/validators.dart';
export 'src/utilities/extensions.dart';

// -------------------
// Localization
// -------------------
export 'src/localization/form_fields_localizations.dart';
