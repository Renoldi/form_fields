library;

/// Visual variants for [AppLoadingIndicator].
enum AppLoadingVariant {
  spinner,
  pulse,
  dots,
}

/// Supported progress presentations for [AppProgressIndicator].
enum AppProgressType {
  linear,
  circular,
}
// Dialog-related enums (moved from feedback/app_dialog_service_types.dart)

/// Types of dialogs for AppDialogService
enum AppDialogType {
  validation,
  network,
  authentication,
  server,
}

/// Dialog position on the screen
enum AppDialogPosition {
  top,
  center,
  bottom,
}

/// Container style for loading dialog (card/nonCard)
enum AppDialogLoadingContainer {
  card,
  nonCard,
}

/// Visual style for loading dialogs
enum AppDialogLoadingVisual {
  indicator,
  progress,
}

/// Back button behavior for loading dialogs
enum AppDialogLoadingBackBehavior {
  block,
  allow,
  confirmCancel,
}

/// Jenis border untuk OTP
enum OtpBorderType {
  box,
  underline,
}

/// Enums for FormFields package

/// Supported form field types
enum FormType {
  string,
  phone,
  password,
  verification,
  email,
  date,
  time,
  dateTime,
  dateTimeRange,
  timeOfDay,
  dropdown,
  dropdownMulti,
  radioButton,
  checkbox,
}

/// Label positions relative to the input field
enum LabelPosition { top, bottom, left, right, inBorder, none }

/// Border styles for input fields
enum BorderType { outlineInputBorder, underlineInputBorder, none }

/// Vertical alignment for selection indicator and item content row
enum IndicatorVerticalAlignment { top, center, bottom }
