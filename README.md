# FormFields

A comprehensive and reusable Flutter form field widget package with support for multiple input types including text, email, phone, password, date, time, and more.

[![Pub Package](https://img.shields.io/pub/v/form_fields.svg)](https://pub.dev/packages/form_fields)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

✨ **Rich Field Types**
- Text fields with validation
- Email validation
- Phone number validation
- Password fields with visibility toggle
- Integer and decimal number input with automatic formatting
- Date picker
- Time picker
- DateTime picker
- DateRange picker
- Multiline text areas

✨ **Customization**
- Flexible label positioning (top, bottom, left, right, inline, hidden)
- Multiple border styles (outline, underline, none)
- Custom border radius
- Custom input decoration
- Custom validators
- Locale support for date/time pickers
- Custom date/time formatting
- Automatic number formatting with thousands separators

✨ **Developer Experience**
- Generic type support for type safety
- Built-in validators with custom message support
- Debounced input handling (500ms)
- Automatic value parsing for numeric types
- Focus node support for keyboard navigation
- Comprehensive error messages
- Provider-based state management

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  form_fields: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:form_fields/form_fields.dart';

FormFields<String>(
  label: 'Email Address',
  formType: FormType.email,
  labelPosition: LabelPosition.top,
  isRequired: true,
  onChanged: (value) {
    print('Email: $value');
  },
)
```

### String Field

```dart
FormFields<String>(
  label: 'Full Name',
  formType: FormType.string,
  onChanged: (value) {
    setState(() => _fullName = value ?? '');
  },
)
```

### Email Field

```dart
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  onChanged: (value) {
    setState(() => _email = value ?? '');
  },
)
```

### Phone Field

```dart
FormFields<String>(
  label: 'Phone Number',
  formType: FormType.phone,
  onChanged: (value) {
    setState(() => _phone = value ?? '');
  },
)
```

### Password Field

```dart
FormFields<String>(
  label: 'Password',
  formType: FormType.password,
  onChanged: (value) {
    setState(() => _password = value ?? '');
  },
)
```

### Numeric Fields

```dart
// Integer field
FormFields<int>(
  label: 'Quantity',
  stripSeparators: true,
  onChanged: (value) {
    setState(() => _quantity = value ?? 0);
  },
)

// Decimal field
FormFields<double>(
  label: 'Price',
  stripSeparators: true,
  onChanged: (value) {
    setState(() => _price = value ?? 0.0);
  },
)
```

### Date/Time Fields

```dart
// Date picker
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  onChanged: (value) {
    setState(() => _birthDate = value);
  },
)

// Time picker
FormFields<DateTime>(
  label: 'Time',
  formType: FormType.time,
  onChanged: (value) {
    setState(() => _time = value);
  },
)

// DateTime picker
FormFields<DateTime>(
  label: 'Event DateTime',
  formType: FormType.dateTime,
  onChanged: (value) {
    setState(() => _dateTime = value);
  },
)

// Date range picker
FormFields<DateTimeRange>(
  label: 'Trip Duration',
  onChanged: (value) {
    setState(() => _dateRange = value);
  },
)
```

### Multiline Text

```dart
FormFields<String>(
  label: 'Bio',
  formType: FormType.string,
  multiLine: 3,
  onChanged: (value) {
    setState(() => _bio = value ?? '');
  },
)
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `onChanged` | `ValueChanged<T>` | Required | Callback when field value changes |
| `label` | `String` | Required | Field label text |
| `formType` | `FormType` | `FormType.string` | Type of form field |
| `labelPosition` | `LabelPosition` | `LabelPosition.none` | Position of label relative to input |
| `isRequired` | `bool` | `false` | Enable validation |
| `validator` | `FormFieldValidator<String>?` | `null` | Custom validator function |
| `currrentValue` | `T?` | `null` | Initial/current field value |
| `focusNode` | `FocusNode?` | `null` | Focus node for this field |
| `nextFocusNode` | `FocusNode?` | `null` | Next focus node for navigation |
| `prefix` | `Widget?` | `null` | Widget before input |
| `prefixIcon` | `Widget?` | `null` | Icon before input |
| `suffix` | `Widget?` | `null` | Widget after input |
| `suffixIcon` | `Widget?` | `null` | Icon after input |
| `inputDecoration` | `InputDecoration?` | `null` | Custom input decoration |
| `radius` | `double` | `10` | Border radius |
| `borderType` | `BorderType` | `BorderType.outlineInputBorder` | Border style |
| `multiLine` | `int` | `0` | Number of lines (0 = single line) |
| `customFormat` | `String?` | `null` | Custom date/time format |
| `stripSeparators` | `bool` | `true` | Format large numbers with separators |
| `pickerLocale` | `Locale?` | `Locale('id', 'ID')` | Locale for date/time pickers |

## FormType Enum

- `FormType.string` - Text input
- `FormType.email` - Email input with validation
- `FormType.phone` - Phone input with validation
- `FormType.password` - Password input with visibility toggle
- `FormType.date` - Date picker
- `FormType.time` - Time picker
- `FormType.dateTime` - DateTime picker

## LabelPosition Enum

- `LabelPosition.top` - Label above input
- `LabelPosition.bottom` - Label below input
- `LabelPosition.left` - Label to the left of input
- `LabelPosition.right` - Label to the right of input
- `LabelPosition.inBorder` - Label inside input border (floating)
- `LabelPosition.none` - No label displayed

## BorderType Enum

- `BorderType.outlineInputBorder` - Material outlined border
- `BorderType.underlineInputBorder` - Material underline border
- `BorderType.none` - No border

## Built-in Validators

Use `FormFieldValidators` class for common validation patterns:

```dart
import 'package:form_fields/form_fields.dart';

// Required field
FormFieldValidators.required('Field Name')

// Email validation
FormFieldValidators.email('Email')

// Phone validation
FormFieldValidators.phone('Phone')

// Password validation
FormFieldValidators.password('Password')

// Numeric validation
FormFieldValidators.number('Amount')

// Minimum length
FormFieldValidators.minLength('Username', 3)

// Maximum length
FormFieldValidators.maxLength('Code', 8)

// Range validation
FormFieldValidators.range('Age', 18, 100)

// Pattern matching
FormFieldValidators.pattern('Username', r'^[a-zA-Z0-9_]+$')

// Field matching (confirmation)
FormFieldValidators.match('Password Confirm', passwordValue)

// Compose multiple validators
FormFieldValidators.compose([
  FormFieldValidators.required('Field'),
  FormFieldValidators.minLength('Field', 3),
])
```

## String Extensions

The package provides useful string validation extensions:

```dart
final email = 'test@example.com';
email.isValidEmail  // true

final phone = '081234567890';
phone.isValidPhone  // true

final password = 'secure123';
password.isValidPassword  // true (length > 5)

final text = '  ';
text.isWhiteSpace  // true

final num = '12345';
num.isValidNumber  // true
```

## Custom Validators

```dart
FormFields<String>(
  label: 'Username',
  isRequired: true,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  },
  onChanged: (value) {
    setState(() => _username = value ?? '');
  },
)
```

## Number Formatting

By default, numbers display with thousands separators:

```dart
// Shows: 1,000,000
FormFields<int>(
  label: 'Amount',
  stripSeparators: true,  // Enable formatting
  onChanged: (value) {
    print(value);  // Access clean value: 1000000
  },
)

// Disable formatting
FormFields<int>(
  label: 'Amount',
  stripSeparators: false,
  onChanged: (value) {
    print(value);
  },
)
```

## Custom Date Format

```dart
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  customFormat: 'dd/MM/yyyy',  // Format output
  onChanged: (value) {
    print(value);
  },
)
```

## Focus Navigation

```dart
final _nameFocus = FocusNode();
final _emailFocus = FocusNode();

FormFields<String>(
  label: 'Name',
  focusNode: _nameFocus,
  nextFocusNode: _emailFocus,
  onChanged: (value) => setState(() => _name = value ?? ''),
)

FormFields<String>(
  label: 'Email',
  focusNode: _emailFocus,
  onChanged: (value) => setState(() => _email = value ?? ''),
)
```

## Form Validation Example

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      FormFields<String>(
        label: 'Email',
        formType: FormType.email,
        isRequired: true,
        onChanged: (value) => setState(() => _email = value ?? ''),
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            print('Form is valid');
          }
        },
        child: const Text('Submit'),
      ),
    ],
  ),
)
```

## Color Customization

The package provides predefined colors via `ColorUtil`:

```dart
import 'package:form_fields/form_fields.dart';

// Access predefined colors
Color primary = ColorUtil.primaryColor;
Color error = ColorUtil.redColor;
Color success = ColorUtil.color329E36;
```

## Locale Support

```dart
FormFields<DateTime>(
  label: 'Date',
  formType: FormType.date,
  pickerLocale: const Locale('en', 'US'),
  onChanged: (value) => setState(() => _date = value),
)
```

## Complete Example

See the [example](https://github.com/enerren/form_fields/tree/main/example) folder for a complete working application demonstrating all features.

## Migration from Jotun App

If you're migrating from the Jotun app:

```dart
// Old import
import 'package:jotun/component/form/form_fields.dart';

// New import
import 'package:form_fields/form_fields.dart';

// All APIs remain the same, just update the import
```

## Troubleshooting

### Phone field not validating correctly

Ensure the phone number follows the format: `+0` followed by 11 digits.

```dart
// Valid formats:
// 081234567890
// +081234567890
```

### Date picker showing wrong language

Set the `pickerLocale` parameter:

```dart
FormFields<DateTime>(
  label: 'Date',
  pickerLocale: const Locale('en', 'US'),
  onChanged: (value) => setState(() => _date = value),
)
```

### Numbers not formatting

Enable `stripSeparators`:

```dart
FormFields<int>(
  label: 'Amount',
  stripSeparators: true,  // Must be true for formatting
  onChanged: (value) => setState(() => _amount = value ?? 0),
)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please visit the [GitHub repository](https://github.com/enerren/form_fields/issues).
