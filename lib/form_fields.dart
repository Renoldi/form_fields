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
export 'src/utilities/signature_pad_export_result.dart'
    show SignaturePadExportResult;
export 'src/fields/core/form_fields_live_camera_capture.dart'
    show
        FormFieldsLiveCameraCapture,
        FormFieldsLiveCameraCaptureState,
        SharedCameraManager;

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
export 'src/fields/selection/form_fields_list_tile.dart'
    show FormFieldsListTile;
export 'src/fields/selection/form_fields_checkbox_list_tile.dart'
    show FormFieldsCheckboxListTile;
export 'src/fields/core/form_fields_rating.dart' show FormFieldsRating;
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
export 'src/theme/app_loading_theme.dart' show AppLoadingThemeData;
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
export 'src/theme/form_fields_my_image_theme.dart'
    show FormFieldsMyImageThemeData;
export 'src/controllers/form_fields_my_image_controller.dart'
    show FormFieldsMyImageController;
export 'src/controllers/form_fields_signature_pad_controller.dart'
    show FormFieldsSignaturePadController;
export 'src/providers/form_fields_my_image_provider.dart'
    show FormFieldsMyImageProvider;
export 'src/providers/form_fields_signature_pad_provider.dart'
    show FormFieldsSignaturePadProvider;
export 'src/providers/form_fields_live_camera_capture_provider.dart'
    show FormFieldsLiveCameraCaptureProvider;
export 'src/models/myimage_result.dart' show MyImageResult;
export 'src/models/direct_upload_payload.dart' show DirectUploadPayload;
export 'src/service/dio_service.dart' show DioUtil;
export 'src/service/http_exception.dart' show HttpException, ErrorType;
export 'src/service/upload_service.dart' show UploadService, UploadOutcome;
export 'src/utilities/upload_helper.dart' show UploadHelper;
export 'src/service/offline_upload_manager.dart' show OfflineUploadManager;

// Database, import/export, crypto, and background workmanager services
export 'src/service/db_service.dart' show DBService;
export 'src/service/import_export_service.dart' show ImportExportService;
export 'src/service/crypto_utils.dart' show CryptoUtils;
export 'src/service/workmanager_service.dart'
    show WorkmanagerService, workmanagerCallbackDispatcher;
export 'src/service/init_service.dart'
    show FormFieldsInitializer, WorkerRegistration;
// `FlushState` moved into `WorkmanagerService` as `isFlushing`.
export 'src/service/flush_types.dart'
    show SubmitHandler, FlushAllHandler, FlushOneHandler;

export 'src/controllers/form_fields_controller.dart';
export 'src/utilities/validators.dart';
export 'src/utilities/extensions.dart';
export 'src/utilities/upload_ui_constants.dart';
export 'src/utilities/upload_response_mapper.dart' show UploadResponseMapper;
export 'src/utilities/validation_exception.dart' show ValidationException;
export 'src/utilities/app_dialog_typedefs.dart';
export 'src/general/list_data.dart';

// -------------------
// Export AppButtonThemeData secara publik agar bisa diimport dari package utama, bukan dari src.
// -------------------
export 'src/theme/app_button_theme.dart' show AppButtonThemeData;

// Reusable Scaffold with SafeArea parent and configurable sides.
export 'src/widgets/safe_scaffold.dart' show SafeScaffold;
export 'src/widgets/custom_app_bar.dart' show CustomAppBar, PreferredAppBar;

// -------------------
// Localization
// -------------------
export 'src/localization/form_fields_localizations.dart';
// Map widget
export 'src/fields/map/form_fields_map.dart'
    show
        FormFieldsMap,
        FormFieldsMapPlaybackConfig,
        FormFieldsMapMapConfig,
        FormFieldsMapFindConfig,
        FormFieldsMapFeature;
export 'src/providers/form_fields_map_notifier.dart' show FormFieldsMapNotifier;
export 'src/controllers/map_controller.dart'
    show
        FormFieldsMapController,
        FormFieldsMapPlaybackHandler,
        FormFieldsMapControllerMapControllerExt;
export 'src/controllers/form_fields_map_api.dart' show FormFieldsMapApi;
export 'src/models/shape_meta.dart'
    show ShapeMeta, PointMeta, ShapeMetaOptions, ShapeTypes;
