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

- [Widget Overview](#why-choose-formfields)
- [Installation](#-installation)
- [Quick Start](#quick-start)
- [Nullable Type Support](#-nullable-type-support-2026)
- [Nullable and Non-Nullable Property Usage](#nullable-and-non-nullable-property-usage)
- [Date Range Picker](#date-range-picker-usedatepickerforrange)
- [FormFields<T> Properties](#formfieldst-properties-2026)
- [Enums: FormType, LabelPosition, BorderType](#enums-formtype-labelposition-bordertype)
- [FormFieldsCheckbox (null & non-null)](#1-formfieldscheckbox)
- [FormFieldsDropdownMulti (null & non-null)](#2-formfieldsdropdownmulti)
- [FormFieldsDropdown (null & non-null)](#3-formfieldsdropdown)
- [FormFieldsRadioButton (null & non-null)](#4-formfieldsradiobutton)
- [FormFieldsSelect (null & non-null)](#5-formfieldsselect)
- [Selection Widgets Overview](#selection-widgets-null-and-non-null-usage)
- [Built-in Validators](#built-in-validators)
- [String & Date Extensions](#string--date-extensions)
- [Custom Validators](#custom-validators)
- [Advanced Examples](#advanced-examples)
- [Custom Classes](#custom-class-usage-with-selection-widgets)
- [Number Formatting](#number-formatting)
- [Custom Date Format & Range](#custom-date-format--range)
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

## Selection Widgets: Null and Non-Null Usage

<!-- 1-formfieldscheckbox -->
### 1. FormFieldsCheckbox

#### Non-nullable
```dart
FormFieldsCheckbox<String>(
  label: 'Hobbies',
  items: ['Reading', 'Music', 'Sports'],
  initialValue: _hobbies, // List<String>
  onChanged: (values) => setState(() => _hobbies = values),
)
```
#### Nullable
```dart
FormFieldsCheckbox<String?>(
  label: 'Optional Hobbies',
  items: ['Reading', 'Music', 'Sports'],
  initialValue: _optionalHobbies, // List<String?>
  onChanged: (values) => setState(() => _optionalHobbies = values),
)
```

<!-- 2-formfieldsdropdownmulti -->
### 2. FormFieldsDropdownMulti

#### Non-nullable
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _languages, // List<String>
  onChanged: (values) => setState(() => _languages = values),
)
```
#### Nullable
```dart
FormFieldsDropdownMulti<String?>(
  label: 'Optional Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _optionalLanguages, // List<String?>
  onChanged: (values) => setState(() => _optionalLanguages = values),
)
```

<!-- 3-formfieldsdropdown -->
### 3. FormFieldsDropdown

#### Non-nullable
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String
  onChanged: (value) => setState(() => _country = value ?? ''),
)
```
#### Nullable
```dart
FormFieldsDropdown<String?>(
  label: 'Country (optional)',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String?
  onChanged: (value) => setState(() => _country = value),
)
```

<!-- 4-formfieldsradiobutton -->
### 4. FormFieldsRadioButton

#### Non-nullable
```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String
  onChanged: (value) => setState(() => _gender = value ?? ''),
)
```
#### Nullable
```dart
FormFieldsRadioButton<String?>(
  label: 'Gender (optional)',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String?
  onChanged: (value) => setState(() => _gender = value),
)
```

<!-- 5-formfieldsselect -->
### 5. FormFieldsSelect

#### Non-nullable (Dropdown)
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String
  onChanged: (value) => setState(() => _country = value ?? ''),
)
```
#### Nullable (Dropdown)
```dart
FormFieldsSelect<String?>(
  formType: FormType.dropdown,
  label: 'Country (optional)',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String?
  onChanged: (value) => setState(() => _country = value),
)
```
#### Non-nullable (Multi-Select)
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdownMulti,
  label: 'Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _languages, // List<String>
  onMultiChanged: (values) => setState(() => _languages = values),
)
```
#### Nullable (Multi-Select)
```dart
FormFieldsSelect<String?>(
  formType: FormType.dropdownMulti,
  label: 'Optional Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _optionalLanguages, // List<String?>
  onMultiChanged: (values) => setState(() => _optionalLanguages = values),
)
```

---

> **Tip:** All selection widgets support both nullable and non-nullable types for maximum flexibility and null safety.

---

## Full Property Usage Examples for Selection Widgets

Below are practical examples showing how to use all major properties for each selection widget, with both nullable and non-nullable types.

### 1. FormFieldsCheckbox
```dart
FormFieldsCheckbox<String>(
  label: 'Hobbies',
  items: ['Reading', 'Music', 'Sports'],
  initialValue: _hobbies, // List<String>
  isRequired: true,
  direction: Axis.vertical,
  itemLabelBuilder: (item) => item.toUpperCase(),
  itemBuilder: (item, selected) => Text(item),
  activeColor: Colors.blue,
  itemPadding: EdgeInsets.symmetric(vertical: 8),
  borderColor: Colors.grey,
  errorBorderColor: Colors.red,
  radius: 8,
  onChanged: (values) => setState(() => _hobbies = values),
)

FormFieldsCheckbox<String?>(
  label: 'Optional Hobbies',
  items: ['Reading', 'Music', 'Sports'],
  initialValue: _optionalHobbies, // List<String?>
  isRequired: false,
  direction: Axis.horizontal,
  onChanged: (values) => setState(() => _optionalHobbies = values),
)
```

### 2. FormFieldsDropdownMulti
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _languages, // List<String>
  isRequired: true,
  minSelections: 1,
  maxSelections: 3,
  chipBackgroundColor: Colors.green.shade100,
  chipTextColor: Colors.green.shade900,
  chipDeleteIconColor: Colors.green.shade700,
  showItemCount: true,
  itemLabelBuilder: (item) => item,
  onChanged: (values) => setState(() => _languages = values),
)

FormFieldsDropdownMulti<String?>(
  label: 'Optional Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _optionalLanguages, // List<String?>
  isRequired: false,
  onChanged: (values) => setState(() => _optionalLanguages = values),
)
```

### 3. FormFieldsDropdown
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String
  isRequired: true,
  hintText: 'Select a country',
  borderColor: Colors.grey,
  focusedBorderColor: Colors.blue,
  errorBorderColor: Colors.red,
  radius: 10,
  labelPosition: LabelPosition.top,
  borderType: BorderType.outlineInputBorder,
  enabled: true,
  itemLabelBuilder: (item) => item,
  onChanged: (value) => setState(() => _country = value ?? ''),
)

FormFieldsDropdown<String?>(
  label: 'Country (optional)',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String?
  isRequired: false,
  onChanged: (value) => setState(() => _country = value),
)
```

### 4. FormFieldsRadioButton
```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String
  isRequired: true,
  direction: Axis.horizontal,
  activeColor: Colors.purple,
  itemPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  borderColor: Colors.grey.shade300,
  errorBorderColor: Colors.red,
  radius: 12,
  itemLabelBuilder: (item) => item,
  itemBuilder: (item, selected) => Text(item),
  onChanged: (value) => setState(() => _gender = value ?? ''),
)

FormFieldsRadioButton<String?>(
  label: 'Gender (optional)',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String?
  isRequired: false,
  onChanged: (value) => setState(() => _gender = value),
)
```

### 5. FormFieldsSelect
```dart
// Dropdown (non-nullable)
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String
  isRequired: true,
  onChanged: (value) => setState(() => _country = value ?? ''),
)

// Dropdown (nullable)
FormFieldsSelect<String?>(
  formType: FormType.dropdown,
  label: 'Country (optional)',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country, // String?
  isRequired: false,
  onChanged: (value) => setState(() => _country = value),
)

// Multi-select (non-nullable)
FormFieldsSelect<String>(
  formType: FormType.dropdownMulti,
  label: 'Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _languages, // List<String>
  isRequired: true,
  onMultiChanged: (values) => setState(() => _languages = values),
)

// Multi-select (nullable)
FormFieldsSelect<String?>(
  formType: FormType.dropdownMulti,
  label: 'Optional Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _optionalLanguages, // List<String?>
  isRequired: false,
  onMultiChanged: (values) => setState(() => _optionalLanguages = values),
)
```

---

> **Tip:** All properties can be combined as needed. Use nullable types for optional fields and non-nullable for required fields. All selection widgets are fully null-safe.

---

## Custom Class Usage with Selection Widgets

All selection widgets support custom model classes for type-safe, rich data selection. Below are examples for each widget, showing both nullable and non-nullable usage.

### 1. FormFieldsCheckbox with Custom Class
```dart
class Hobby {
  final String id;
  final String name;
  const Hobby(this.id, this.name);
  @override
  bool operator ==(Object other) => other is Hobby && id == other.id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => name;
}

final hobbies = [Hobby('r', 'Reading'), Hobby('m', 'Music'), Hobby('s', 'Sports')];
List<Hobby> _selectedHobbies = [];

FormFieldsCheckbox<Hobby>(
  label: 'Hobbies',
  items: hobbies,
  initialValue: _selectedHobbies,
  itemLabelBuilder: (h) => h.name,
  onChanged: (values) => setState(() => _selectedHobbies = values),
)
```
#### Nullable
```dart
List<Hobby?> _optionalHobbies = [];
FormFieldsCheckbox<Hobby?>(
  label: 'Optional Hobbies',
  items: hobbies,
  initialValue: _optionalHobbies,
  onChanged: (values) => setState(() => _optionalHobbies = values),
)
```

### 2. FormFieldsDropdownMulti with Custom Class
```dart
class Language {
  final String code;
  final String name;
  const Language(this.code, this.name);
  @override
  bool operator ==(Object other) => other is Language && code == other.code;
  @override
  int get hashCode => code.hashCode;
  @override
  String toString() => name;
}

final languages = [Language('dart', 'Dart'), Language('java', 'Java'), Language('kt', 'Kotlin')];
List<Language> _selectedLanguages = [];

FormFieldsDropdownMulti<Language>(
  label: 'Languages',
  items: languages,
  initialValues: _selectedLanguages,
  itemLabelBuilder: (l) => l.name,
  onChanged: (values) => setState(() => _selectedLanguages = values),
)
```
#### Nullable
```dart
List<Language?> _optionalLanguages = [];
FormFieldsDropdownMulti<Language?>(
  label: 'Optional Languages',
  items: languages,
  initialValues: _optionalLanguages,
  onChanged: (values) => setState(() => _optionalLanguages = values),
)
```

### 3. FormFieldsDropdown with Custom Class
```dart
class Country {
  final String code;
  final String name;
  const Country(this.code, this.name);
  @override
  bool operator ==(Object other) => other is Country && code == other.code;
  @override
  int get hashCode => code.hashCode;
  @override
  String toString() => name;
}

final countries = [Country('US', 'USA'), Country('CA', 'Canada'), Country('UK', 'UK')];
Country? _country;

FormFieldsDropdown<Country>(
  label: 'Country',
  items: countries,
  initialValue: _country,
  itemLabelBuilder: (c) => c.name,
  onChanged: (value) => setState(() => _country = value),
)
```
#### Nullable
```dart
FormFieldsDropdown<Country?>(
  label: 'Country (optional)',
  items: countries,
  initialValue: _country,
  onChanged: (value) => setState(() => _country = value),
)
```

### 4. FormFieldsRadioButton with Custom Class
```dart
class Gender {
  final String id;
  final String label;
  const Gender(this.id, this.label);
  @override
  bool operator ==(Object other) => other is Gender && id == other.id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => label;
}

final genders = [Gender('m', 'Male'), Gender('f', 'Female'), Gender('o', 'Other')];
Gender? _gender;

FormFieldsRadioButton<Gender>(
  label: 'Gender',
  items: genders,
  initialValue: _gender,
  itemLabelBuilder: (g) => g.label,
  onChanged: (value) => setState(() => _gender = value),
)
```
#### Nullable
```dart
FormFieldsRadioButton<Gender?>(
  label: 'Gender (optional)',
  items: genders,
  initialValue: _gender,
  onChanged: (value) => setState(() => _gender = value),
)
```

### 5. FormFieldsSelect with Custom Class
```dart
// Dropdown
FormFieldsSelect<Country>(
  formType: FormType.dropdown,
  label: 'Country',
  items: countries,
  initialValue: _country,
  onChanged: (value) => setState(() => _country = value),
)
// Multi-select
FormFieldsSelect<Language>(
  formType: FormType.dropdownMulti,
  label: 'Languages',
  items: languages,
  initialValues: _selectedLanguages,
  onMultiChanged: (values) => setState(() => _selectedLanguages = values),
)
```
#### Nullable
```dart
FormFieldsSelect<Country?>(
  formType: FormType.dropdown,
  label: 'Country (optional)',
  items: countries,
  initialValue: _country,
  onChanged: (value) => setState(() => _country = value),
)
FormFieldsSelect<Language?>(
  formType: FormType.dropdownMulti,
  label: 'Optional Languages',
  items: languages,
  initialValues: _optionalLanguages,
  onMultiChanged: (values) => setState(() => _optionalLanguages = values),
)
```

---

> **Tip:** Always implement `==` and `hashCode` for your custom classes to ensure correct selection and comparison.

---
