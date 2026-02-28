# FormFields

[![Pub Package](https://img.shields.io/pub/v/form_fields.svg)](https://pub.dev/packages/form_fields)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <b>Beautiful, powerful, and easy-to-use Flutter form fields for 2026</b><br>
  <i>All input types, all label positions, all the beauty and flexibility you need.</i>
</p>

---

## 🚀 2026 Highlights

- ✨ All label positions: <b>top, bottom, left, right, inBorder, none</b>
- ✨ Professional, beautiful UI out-of-the-box
- ✨ Modular, maintainable, and extensible codebase
- ✨ Full localization and multi-language support
- ✨ All field types: text, email, phone, password, date, time, dropdown, multi-select, radio, checkbox, and more
- ✨ Powerful validation, custom error messages, and built-in validators
- ✨ Provider-based state management for advanced use cases
- ✨ Type-safe generics for all widgets
- ✨ Easy migration from legacy form field packages

---

## Why Choose FormFields?

- **All label positions**: Place your label anywhere—top, bottom, left, right, inside the border, or hide it completely.
- **Beautiful by default**: Professional spacing, error handling, and Material design—no extra styling needed.
- **All field types**: Text, email, phone, password, date, time, dropdown, multi-select, radio, checkbox, and more.
- **Localization built-in**: US English and Indonesian included, easy to add more.
- **Type-safe and flexible**: Use your own model classes, not just strings.
- **Comprehensive docs and examples**: Everything you need to get started and go advanced.
- **Actively maintained for 2026 and beyond**.

---

## Quick Start

```dart
import 'package:form_fields/form_fields.dart';

FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  labelPosition: LabelPosition.top,
  isRequired: true,
  onChanged: (value) {
    print('Email: $value');
  },
)
```

---

## 🏁 Navigation

- [Widget Overview](#-widget-overview)
- [Installation](#-installation)
- [Quick Start](#quick-start)
- [Nullable and Non-Nullable Property Usage](#nullable-and-non-nullable-property-usage)
- [FormFields<T> Properties](#formfieldst-properties)
- [Enums: FormType, LabelPosition, BorderType](#formtype-enum)
- [Selection Widgets](#selection-widgets)
- [Built-in Validators](#built-in-validators)
- [String & Date Extensions](#string-extensions)
- [Custom Validators](#custom-validators)
- [Advanced Examples](#advanced-examples)
- [Custom Classes](#working-with-custom-classes)
- [Number Formatting](#number-formatting)
- [Custom Date Format & Range](#custom-date-format)
- [Custom Error Messages](#custom-error-messages)
- [Focus Navigation](#focus-navigation)
- [Form Validation Example](#form-validation-example)
- [Color Customization](#color-customization)
- [Locale Support](#locale-support)
- [Troubleshooting](#troubleshooting)
- [Localization & Multi-Language Support](#-localization--multi-language-support)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## 🆕 Nullable Type Support (2026)

FormFields and all selection widgets now offer **first-class support for nullable types**—making your forms more flexible, null-safe, and user-friendly than ever before.

### Why Nullable Types?
- **Optional fields**: Cleanly represent fields that are not required.
- **Clearable selections**: Allow users to reset or clear their choice.
- **Null safety**: Embrace Dart's null safety for robust, error-free code.

### How It Works
- Use `FormFields<T?>`, `FormFieldsDropdown<T?>`, `FormFieldsRadioButton<T?>`, etc.
- Pass `null` as the initial value or when clearing a field.
- All widgets handle `null` gracefully in the UI and validation.
- Built-in validators and error messages are null-aware.

### Examples

#### Optional Text Field
```dart
FormFields<String?>(
  label: 'Middle Name (optional)',
  formType: FormType.string,
  currrentValue: _middleName, // _middleName can be null
  onChanged: (value) => setState(() => _middleName = value),
)
```

#### Optional Dropdown
```dart
FormFieldsDropdown<String?>(
  label: 'Country (optional)',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // _country can be null
  onChanged: (value) => setState(() => _country = value),
)
```

#### Optional Radio Button
```dart
FormFieldsRadioButton<String?>(
  label: 'Gender (optional)',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // _gender can be null
  onChanged: (value) => setState(() => _gender = value),
)
```

#### Clearing a Field
```dart
// To clear a field, just set its value to null
setState(() => _country = null);
```

#### Custom Validation with Nullables
```dart
FormFields<String?>(
  label: 'Referral Code (optional)',
  validator: (value) {
    if (value != null && value.length < 6) {
      return 'Referral code must be at least 6 characters';
    }
    return null; // Accepts null as valid (optional field)
  },
  onChanged: (value) => setState(() => _referralCode = value),
)
```

> **Tip:** Use nullable types for any field that is not required, or whenever you want to let users clear their input or selection.

---

## Nullable and Non-Nullable Property Usage

All FormFields widgets and properties support both nullable and non-nullable types. This gives you full flexibility and null safety for every use case.

### How to Use Nullable and Non-Nullable Properties

#### 1. Text Field (String and String?)
```dart
// Non-nullable (required field)
FormFields<String>(
  label: 'First Name',
  isRequired: true,
  currrentValue: _firstName, // String, must not be null
  onChanged: (value) => setState(() => _firstName = value ?? ''),
)

// Nullable (optional field)
FormFields<String?>(
  label: 'Middle Name (optional)',
  currrentValue: _middleName, // String? (can be null)
  onChanged: (value) => setState(() => _middleName = value),
)
```

#### 2. Dropdown (T and T?)
```dart
// Non-nullable (must select)
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String, not null
  isRequired: true,
  onChanged: (value) => setState(() => _country = value ?? ''),
)

// Nullable (can clear selection)
FormFieldsDropdown<String?>(
  label: 'Country (optional)',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String? (can be null)
  onChanged: (value) => setState(() => _country = value),
)
```

#### 3. Radio Button (T and T?)
```dart
// Non-nullable
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String, not null
  isRequired: true,
  onChanged: (value) => setState(() => _gender = value ?? ''),
)

// Nullable
FormFieldsRadioButton<String?>(
  label: 'Gender (optional)',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String? (can be null)
  onChanged: (value) => setState(() => _gender = value),
)
```

#### 4. Checkbox (List<T> and List<T?>)
```dart
// Non-nullable list
FormFieldsCheckbox<String>(
  label: 'Hobbies',
  items: ['Reading', 'Music', 'Sports'],
  initialValue: _hobbies, // List<String>
  onChanged: (values) => setState(() => _hobbies = values),
)

// Nullable list (rare, but possible)
FormFieldsCheckbox<String?>(
  label: 'Optional Hobbies',
  items: ['Reading', 'Music', 'Sports'],
  initialValue: _optionalHobbies, // List<String?>
  onChanged: (values) => setState(() => _optionalHobbies = values),
)
```

#### 5. Numeric Fields (int, int?, double, double?)
```dart
// Non-nullable int
FormFields<int>(
  label: 'Age',
  currrentValue: _age, // int
  onChanged: (value) => setState(() => _age = value ?? 0),
)

// Nullable int
FormFields<int?>(
  label: 'Age (optional)',
  currrentValue: _age, // int?
  onChanged: (value) => setState(() => _age = value),
)

// Non-nullable double
FormFields<double>(
  label: 'Price',
  currrentValue: _price, // double
  onChanged: (value) => setState(() => _price = value ?? 0.0),
)

// Nullable double
FormFields<double?>(
  label: 'Price (optional)',
  currrentValue: _price, // double?
  onChanged: (value) => setState(() => _price = value),
)
```

#### 6. Date/Time Fields (DateTime, DateTime?, TimeOfDay, TimeOfDay?)
```dart
// Non-nullable DateTime
FormFields<DateTime>(
  label: 'Birth Date',
  currrentValue: _birthDate, // DateTime
  onChanged: (value) => setState(() => _birthDate = value!),
)

// Nullable DateTime
FormFields<DateTime?>(
  label: 'Anniversary (optional)',
  currrentValue: _anniversary, // DateTime?
  onChanged: (value) => setState(() => _anniversary = value),
)

// Non-nullable TimeOfDay
FormFields<TimeOfDay>(
  label: 'Meeting Time',
  currrentValue: _meetingTime, // TimeOfDay
  onChanged: (value) => setState(() => _meetingTime = value!),
)

// Nullable TimeOfDay
FormFields<TimeOfDay?>(
  label: 'Optional Meeting Time',
  currrentValue: _optionalMeetingTime, // TimeOfDay?
  onChanged: (value) => setState(() => _optionalMeetingTime = value),
)
```

#### 7. Custom Validation with Nullables
```dart
FormFields<String?>(
  label: 'Referral Code (optional)',
  validator: (value) {
    if (value != null && value.length < 6) {
      return 'Referral code must be at least 6 characters';
    }
    return null; // Accepts null as valid (optional field)
  },
  onChanged: (value) => setState(() => _referralCode = value),
)
```

---

### Date Range Picker: useDatePickerForRange

The `useDatePickerForRange` property lets you choose between a single dialog for picking a date range, or two separate dialogs for start and end dates. This gives you more control over the user experience.

#### Default (Single Dialog)
```dart
FormFields<DateTimeRange>(
  label: 'Trip Duration',
  currrentValue: _tripDates,
  onChanged: (value) => setState(() => _tripDates = value),
)
```
- Shows a single date range picker dialog (Material style).
- User selects both start and end dates in one step.

#### Separate Start/End Pickers
```dart
FormFields<DateTimeRange>(
  label: 'Trip Duration',
  useDatePickerForRange: true, // <-- Enable this
  currrentValue: _tripDates,
  onChanged: (value) => setState(() => _tripDates = value),
)
```
- Shows two dialogs: first for start date, then for end date.
- Useful for workflows where you want to guide the user step-by-step.

**Tip:**
- `useDatePickerForRange: false` (default) = single dialog (recommended for most apps)
- `useDatePickerForRange: true` = two dialogs (for custom UX or accessibility)

---

### Date Range Picker (Single and Multi-Selection)

You can use FormFields<DateTimeRange> for a single date range, or FormFields<List<DateTimeRange>> for multi-selection of date ranges.

#### Single Date Range
```dart
FormFields<DateTimeRange>(
  label: 'Trip Duration',
  currrentValue: _tripDates, // DateTimeRange
  onChanged: (value) => setState(() => _tripDates = value),
)
```
- Shows a date range picker dialog.
- Returns a DateTimeRange with start and end.
- Great for booking, rental periods, or any single range selection.

#### Multiple Date Ranges (Advanced)
```dart
FormFields<List<DateTimeRange>>(
  label: 'Multiple Booking Periods',
  currrentValue: _periods, // List<DateTimeRange>
  onChanged: (value) => setState(() => _periods = value ?? []),
)
```
- Allows selection of multiple date ranges (if your UI supports it).
- Returns a list of DateTimeRange objects.
- Useful for advanced scheduling, availability, or batch bookings.

**Tip:** For most use cases, a single DateTimeRange is sufficient. Use a list only if you need to support multiple, non-overlapping periods.

---

> **Tip:**
> - Use nullable types (`T?`) for optional fields or when you want to allow clearing the value.
> - Use non-nullable types (`T`) for required fields or when a value must always be present.
> - All FormFields widgets and properties are null-safe and work seamlessly with both approaches.

---

## FormFields<T> Properties (2026)

Below are all properties supported by the core `FormFields<T>` widget, with clear explanations and usage for both nullable and non-nullable types.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `onChanged` | `ValueChanged<T>` | **Required** | Callback when field value changes |
| `currrentValue` | `T` | **Required** | Current value (nullable or non-nullable) |
| `validator` | `FormFieldValidator<String>?` | `null` | Custom validator function |
| `isRequired` | `bool` | `false` | Whether field is required |
| `autovalidateMode` | `AutovalidateMode` | `onUserInteraction` | When to show validation errors |
| `minLengthPassword` | `int` | `6` | Minimum length for password field |
| `customPasswordValidator` | `FormFieldValidator<String>?` | `null` | Custom password validator |
| `minLengthPasswordErrorText` | `String?` | `null` | Error text for min password length |
| `formType` | `FormType` | `FormType.string` | Field type (text, email, phone, etc.) |
| `label` | `String` | **Required** | Field label text |
| `labelPosition` | `LabelPosition` | `LabelPosition.none` | Label position (top, bottom, left, right, inBorder, none) |
| `multiLine` | `int` | `0` | Number of lines for multiline input |
| `radius` | `double` | `10` | Border radius |
| `borderType` | `BorderType` | `BorderType.outlineInputBorder` | Border style |
| `borderColor` | `Color` | `Color(0xFFC7C7C7)` | Border color (normal) |
| `errorBorderColor` | `Color` | `Colors.red` | Border color (error) |
| `labelTextStyle` | `TextStyle?` | `null` | Custom label text style |
| `inputDecoration` | `InputDecoration?` | `null` | Custom input decoration |
| `prefix` | `Widget?` | `null` | Widget before input |
| `prefixIcon` | `Widget?` | `null` | Icon before input |
| `suffix` | `Widget?` | `null` | Widget after input |
| `suffixIcon` | `Widget?` | `null` | Icon after input |
| `focusNode` | `FocusNode?` | `null` | Focus node for this field |
| `nextFocusNode` | `FocusNode?` | `null` | Next focus node for navigation |
| `enterText` | `String` | `'Enter '` | Custom text prefix for input hints |
| `invalidIntegerText` | `String` | `'Enter valid integer for'` | Custom error for invalid integer |
| `invalidNumberText` | `String` | `'Enter valid number for'` | Custom error for invalid number |
| `stripSeparators` | `bool` | `true` | Format numbers with thousand separators |
| `customFormat` | `String?` | `null` | Custom date/time format |
| `pickerLocale` | `String?` | `'id_ID'` | Locale for date/time pickers |
| `firstDate` | `DateTime?` | `null` (100 years ago) | First selectable date for pickers |
| `lastDate` | `DateTime?` | `null` (today) | Last selectable date for pickers |
| `useDatePickerForRange` | `bool` | `false` | Use two dialogs for date range selection |
| `phoneCountryCodes` | `List<String>` | `['+62', ...]` | List of selectable country codes |
| `initialCountryCode` | `String?` | `null` | Initial country code for phone input |
| `formatPhone` | `bool` | `false` | Display phone with dashes in input field |

**Usage:**
- All properties work with both nullable and non-nullable types for `T`.
- See code examples above for how to use each property in practice.
- For advanced customization, combine these properties as needed.

---
