library;

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
