/// Enums for FormFields package

/// Supported form field types
enum FormType {
  string,
  phone,
  password,
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
