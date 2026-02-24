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
- Time picker (supports both `DateTime` and `TimeOfDay` types)
- DateTime picker
- DateRange picker
- Multiline text areas

✨ **Customization**
- Flexible label positioning (top, bottom, left, right, inline, hidden)
- Multiple border styles (outline, underline, none)
- Custom border radius
- Custom input decoration
- Custom validators
- Custom error messages and hint text
- Locale support for date/time pickers (string format: 'en_US', 'id_ID', etc.)
- Custom date/time formatting
- Date range customization (`firstDate`, `lastDate`) for date/datetime/daterange pickers
- Automatic number formatting with thousands separators (numeric types only)
- Numeric-only input validation for int/double fields

✨ **Developer Experience**
- Generic type support for type safety (`FormFields<String>`, `FormFields<int>`, `FormFields<DateTime>`, `FormFields<TimeOfDay>`, etc.)
- Built-in validators with custom message support
- Debounced input handling (500ms) for optimized performance
- Automatic value parsing for numeric types
- Focus node support for keyboard navigation
- Comprehensive error messages with customization options
- Provider-based state management
- Text input prefix customization (`enterText`, `invalidIntegerText`, `invalidNumberText`)
- TimeOfDay/DateTime conversion extension methods

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

// Time picker (DateTime)
FormFields<DateTime>(
  label: 'Time',
  formType: FormType.time,
  onChanged: (value) {
    setState(() => _time = value);
  },
)

// Time picker (TimeOfDay)
FormFields<TimeOfDay>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (value) {
    setState(() => _meetingTime = value);
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
| `stripSeparators` | `bool` | `true` | Format numbers with thousand separators (int/double only) |
| `pickerLocale` | `String?` | `'id_ID'` | Locale for date/time pickers |
| `enterText` | `String` | `'Enter '` | Custom text prefix for input hints |
| `invalidIntegerText` | `String` | `'Enter valid integer for'` | Custom error text for invalid integer |
| `invalidNumberText` | `String` | `'Enter valid number for'` | Custom error text for invalid number |
| `firstDate` | `DateTime?` | `null` (100 years ago) | First selectable date for date pickers |
| `lastDate` | `DateTime?` | `null` (today) | Last selectable date for date pickers |

## FormType Enum

- `FormType.string` - Text input
- `FormType.email` - Email input with validation
- `FormType.phone` - Phone input with validation
- `FormType.password` - Password input with visibility toggle
- `FormType.date` - Date picker (returns `DateTime`)
- `FormType.time` - Time picker (supports `DateTime` or `TimeOfDay`)
- `FormType.dateTime` - DateTime picker (returns `DateTime`)

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

## TimeOfDay/DateTime Extensions

Easily convert between TimeOfDay and DateTime:

```dart
// DateTime to TimeOfDay
DateTime dateTime = DateTime.now();
TimeOfDay? timeOfDay = dateTime.toTimeOfDay();

// TimeOfDay to DateTime (uses current date)
TimeOfDay time = TimeOfDay(hour: 14, minute: 30);
DateTime? dateTime = time.toDateTime();

// TimeOfDay to DateTime with specific date
DateTime specificDate = DateTime(2026, 12, 25);
DateTime? christmas2pm = time.toDateTimeWithDate(specificDate);
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

The `stripSeparators` parameter controls thousand separator formatting **for numeric types only** (`FormFields<int>` and `FormFields<double>`). It also restricts input to numbers only, preventing non-numeric characters.

```dart
// With thousand separators: 1,000,000
FormFields<int>(
  label: 'Amount',
  stripSeparators: true,  // Shows: 1,000,000 (default)
  onChanged: (value) {
    print(value);  // Value is clean: 1000000
  },
)

// Without thousand separators: 1000000
FormFields<int>(
  label: 'Amount',
  stripSeparators: false,  // Shows: 1000000 (no commas)
  onChanged: (value) {
    print(value);  // Value is: 1000000
  },
)

// For double/decimal numbers
FormFields<double>(
  label: 'Price',
  stripSeparators: true,  // Shows: 1,234.56
  onChanged: (value) {
    print(value);  // Value is: 1234.56
  },
)
```

**Note:** Both `true` and `false` restrict input to numeric characters only. The difference is only in the visual formatting (whether commas are displayed).

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

## Custom Date Range

```dart
// Future dates only (e.g., booking system)
FormFields<DateTime>(
  label: 'Appointment Date',
  formType: FormType.date,
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(Duration(days: 365)),
  onChanged: (value) {},
)

// Specific year only
FormFields<DateTime>(
  label: 'Event Date 2026',
  formType: FormType.date,
  firstDate: DateTime(2026, 1, 1),
  lastDate: DateTime(2026, 12, 31),
  onChanged: (value) {},
)

// DateTimeRange with custom range (e.g., vacation dates in next 2 years)
FormFields<DateTimeRange>(
  label: 'Vacation Dates',
  formType: FormType.date,
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(Duration(days: 730)),
  onChanged: (value) {
    print('Start: ${value.start}, End: ${value.end}');
  },
)

// DateTimeRange with historical range (e.g., project timeline 2020-2030)
FormFields<DateTimeRange>(
  label: 'Project Timeline',
  formType: FormType.date,
  firstDate: DateTime(2020, 1, 1),
  lastDate: DateTime(2030, 12, 31),
  onChanged: (value) {},
)
```

## Custom Error Messages

Customize validation messages and text hints:

```dart
FormFields<int>(
  label: 'Age',
  enterText: 'Please enter ',  // Changes hint text
  invalidIntegerText: 'Invalid number for',  // Changes error for invalid integers
  onChanged: (value) {
    setState(() => _age = value ?? 0);
  },
)

FormFields<double>(
  label: 'Price',
  invalidNumberText: 'Please provide a valid number for',  // Changes error for invalid numbers
  onChanged: (value) {
    setState(() => _price = value ?? 0.0);
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
  pickerLocale: 'en_US',  // Use locale string format
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
  formType: FormType.date,
  pickerLocale: 'en_US',
  onChanged: (value) => setState(() => _date = value),
)
```

### Numbers not formatting with thousand separators

The `stripSeparators` parameter only works with numeric types (`FormFields<int>` and `FormFields<double>`):

```dart
// ✅ Correct - shows thousand separators
FormFields<int>(
  label: 'Amount',
  stripSeparators: true,  // Shows: 1,000,000
  onChanged: (value) => setState(() => _amount = value ?? 0),
)

// ✅ Also correct - no thousand separators but still numeric-only input
FormFields<double>(
  label: 'Price',
  stripSeparators: false,  // Shows: 1234.56 (no commas)
  onChanged: (value) => setState(() => _price = value ?? 0.0),
)

// ❌ Wrong - stripSeparators has no effect on String types
FormFields<String>(
  label: 'Text',
  stripSeparators: true,  // Has no effect on String
  onChanged: (value) => setState(() => _text = value ?? ''),
)
```

**Note:** Both `stripSeparators: true` and `stripSeparators: false` restrict input to numeric characters only for int/double types. The only difference is whether thousand separators (commas) are displayed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please visit the [GitHub repository](https://github.com/enerren/form_fields/issues).
