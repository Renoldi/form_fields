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

> **Tip:**
> - Use nullable types (`T?`) for optional fields or when you want to allow clearing the value.
> - Use non-nullable types (`T`) for required fields or when a value must always be present.
> - All FormFields widgets and properties are null-safe and work seamlessly with both approaches.

---
