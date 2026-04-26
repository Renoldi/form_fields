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

export 'src/fields/core/form_fields_signature_pad.dart'
    show FormFieldsSignaturePad;

// ...existing code...
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
export 'src/general/app_modal_bottom_sheet.dart' show showAppModalBottomSheet;
export 'src/general/responsive_menu_grid.dart' show ResponsiveMenuGrid;
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
        AppDialogLoadingContainer,
        AppLoadingVariant,
        AppProgressType;
export 'src/utilities/dialog_typedefs.dart'
    show AppDialogErrorMapper, AppDialogCancelRequested, AppDialogCancelled;

// -------------------
// Utilities & Enums
// -------------------
export 'src/utilities/enums.dart';
export 'src/buttons/app_button_enums.dart';

// -------------------
// MyImage Field & Utilities
// -------------------
export 'src/fields/core/form_fields_my_image.dart' show FormFieldsMyImage;
export 'src/controllers/form_fields_my_image_controller.dart'
    show FormFieldsMyImageController;
export 'src/providers/form_fields_my_image_provider.dart'
    show FormFieldsMyImageProvider;
export 'src/utilities/myimage_result.dart' show MyimageResult;
export 'src/service/dio_service.dart' show DioUtil;

export 'src/controllers/form_fields_controller.dart';
export 'src/utilities/validators.dart';
export 'src/utilities/extensions.dart';
export 'src/utilities/validation_exception.dart' show ValidationException;
export 'src/utilities/app_dialog_typedefs.dart';

// -------------------
// Export AppButtonThemeData secara publik agar bisa diimport dari package utama, bukan dari src.
// -------------------
export 'src/buttons/app_button_theme.dart' show AppButtonThemeData;

// -------------------
// Localization
// -------------------
export 'src/localization/form_fields_localizations.dart';
