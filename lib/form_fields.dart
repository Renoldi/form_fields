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
// ignore: unintended_html_in_doc_comment
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
export 'src/fields/core/form_fields.dart' show FormFields;
export 'src/fields/autocomplete/form_fields_autocomplete.dart'
    show FormFieldsAutocomplete;

// -------------------
// Field Widgets
// -------------------
export 'src/fields/selection/form_fields_select.dart' show FormFieldsSelect;
export 'src/fields/selection/form_fields_dropdown.dart' show FormFieldsDropdown;
export 'src/fields/selection/form_fields_dropdown_multi.dart'
    show FormFieldsDropdownMulti;
// Utilities
export 'src/utilities/app_modal_bottom_sheet.dart' show showAppModalBottomSheet;
export 'src/utilities/responsive_menu_grid.dart' show ResponsiveMenuGrid;
export 'src/fields/selection/form_fields_radio_button.dart'
    show FormFieldsRadioButton;
export 'src/fields/selection/form_fields_checkbox.dart' show FormFieldsCheckbox;
export 'src/buttons/app_button.dart' show AppButton;
export 'src/buttons/app_button_layout.dart' show AppButtonLayout;
export 'src/buttons/app_button_content.dart' show AppButtonContent;
export 'src/buttons/app_button_group.dart' show AppButtonGroup;
export 'src/buttons/app_segmented_button.dart' show AppSegmentedButton;
export 'src/buttons/app_split_button.dart'
    show AppSplitButton, AppSplitButtonItem;
export 'src/buttons/app_fab_menu.dart' show AppFabMenu, AppFabMenuItem;
export 'src/feedback/app_loading_indicator.dart' show AppLoadingIndicator;
export 'src/feedback/app_progress_indicator.dart' show AppProgressIndicator;
export 'src/feedback/app_dialog_service.dart' show AppDialogService;
export 'src/feedback/app_global_dialog_service.dart'
    show AppGlobalDialogService;

// Dialog enums and typedefs (now in utilities)
export 'src/utilities/enums.dart'
    show
        AppDialogType,
        AppDialogPosition,
        AppDialogLoadingVisual,
        AppDialogLoadingBackBehavior,
        AppLoadingVariant,
        AppProgressType;
export 'src/utilities/dialog_typedefs.dart'
    show AppDialogErrorMapper, AppDialogCancelRequested, AppDialogCancelled;

// -------------------
// Utilities & Enums
// -------------------
export 'src/utilities/enums.dart';
export 'src/buttons/app_button_enums.dart';

export 'src/utilities/controller.dart';
export 'src/utilities/validators.dart';
export 'src/utilities/extensions.dart';

// -------------------
// Localization
// -------------------
export 'src/localization/form_fields_localizations.dart';
