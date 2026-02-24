# API Reference - FormFields Package

## Core Widget: FormFields<T>

The main widget for creating form fields.

### Constructor

```dart
FormFields<T>({
  required ValueChanged<T> onChanged,
  required String label,
  FormFieldValidator<String>? validator,
  T? currrentValue,
  FocusNode? nextFocusNode,
  FocusNode? focusNode,
  Widget? prefix,
  Widget? prefixIcon,
  Widget? suffix,
  Widget? suffixIcon,
  InputDecoration? inputDecoration,
  FormType formType = FormType.string,
  LabelPosition labelPosition = LabelPosition.none,
  bool isRequired = false,
  double radius = 10,
  BorderType borderType = BorderType.outlineInputBorder,
  int multiLine = 0,
  String? customFormat,
  bool stripSeparators = true,
  Locale? pickerLocale = const Locale('id', 'ID'),
})
```

### Properties

#### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `onChanged` | `ValueChanged<T>` | Callback when field value changes |
| `label` | `String` | Label text for the field |

#### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `formType` | `FormType` | `FormType.string` | Type of form field |
| `labelPosition` | `LabelPosition` | `LabelPosition.none` | Position of label |
| `isRequired` | `bool` | `false` | Enable validation |
| `validator` | `FormFieldValidator<String>?` | `null` | Custom validator |
| `currrentValue` | `T?` | `null` | Initial value |
| `focusNode` | `FocusNode?` | `null` | Focus control |
| `nextFocusNode` | `FocusNode?` | `null` | Next field focus |
| `prefix` | `Widget?` | `null` | Widget before input |
| `prefixIcon` | `Widget?` | `null` | Icon before input |
| `suffix` | `Widget?` | `null` | Widget after input |
| `suffixIcon` | `Widget?` | `null` | Icon after input |
| `inputDecoration` | `InputDecoration?` | `null` | Custom decoration |
| `radius` | `double` | `10` | Border radius |
| `borderType` | `BorderType` | `outlineInputBorder` | Border style |
| `multiLine` | `int` | `0` | Lines for text area |
| `customFormat` | `String?` | `null` | Custom date format |
| `stripSeparators` | `bool` | `true` | Format numbers |
| `pickerLocale` | `Locale?` | `Locale('id', 'ID')` | Picker locale |

## Enums

### FormType

```dart
enum FormType {
  string,      // Basic text input
  email,       // Email with validation
  phone,       // Phone with validation
  password,    // Password with toggle
  date,        // Date picker
  time,        // Time picker
  dateTime,    // DateTime picker
}
```

### LabelPosition

```dart
enum LabelPosition {
  top,        // Label above input
  bottom,     // Label below input
  left,       // Label to the left
  right,      // Label to the right
  inBorder,   // Floating label in border
  none,       // No label
}
```

### BorderType

```dart
enum BorderType {
  outlineInputBorder,      // Outlined border
  underlineInputBorder,    // Underline border
  none,                    // No border
}
```

## Validators: FormFieldValidators

### Static Methods

#### required(label, {customMessage})
Validates that field is not empty.

```dart
FormFieldValidators.required('Email')
```

#### email(label, {customMessage})
Validates email format.

```dart
FormFieldValidators.email('Email')
```

#### phone(label, {customMessage})
Validates phone format (Indonesian: 0 + 11 digits).

```dart
FormFieldValidators.phone('Phone')
```

#### password(label, {customMessage})
Validates password (minimum 6 characters).

```dart
FormFieldValidators.password('Password')
```

#### number(label, {customMessage})
Validates numeric input.

```dart
FormFieldValidators.number('Amount')
```

#### minLength(label, minLength, {customMessage})
Validates minimum string length.

```dart
FormFieldValidators.minLength('Username', 3)
```

#### maxLength(label, maxLength, {customMessage})
Validates maximum string length.

```dart
FormFieldValidators.maxLength('Code', 8)
```

#### range(label, min, max, {customMessage})
Validates number is within range.

```dart
FormFieldValidators.range('Age', 18, 100)
```

#### pattern(label, pattern, {customMessage})
Validates against regex pattern.

```dart
FormFieldValidators.pattern('Username', r'^[a-zA-Z0-9_]+$')
```

#### match(label, matchValue, {customMessage})
Validates field matches another value.

```dart
FormFieldValidators.match('Password Confirm', passwordValue)
```

#### compose(validators)
Combines multiple validators.

```dart
FormFieldValidators.compose([
  FormFieldValidators.required('Field'),
  FormFieldValidators.minLength('Field', 3),
])
```

## String Extensions

### Validation Properties

```dart
String email = 'test@example.com';

email.isValidEmail          // true
email.isValidPhone          // false
email.isValidPassword       // true (length > 5)
email.isValidNumber         // false
email.isWhiteSpace          // false
email.isValidVerification   // true (length >= 1)
```

### Manipulation Methods

```dart
String phone = '081234567890';

phone.hidePhone     // '*'.repeat(7) + '7890'
phone.is0Phone      // '081234567890' (or adds 0)
phone.toTitleCase   // Title case conversion
```

## DateTime Extensions

### Comparison Methods

```dart
DateTime? date = DateTime.now();

date.isBefore(other)           // Compare dates
date.isAfter(other)            // Compare dates
date.isAtSameMomentAs(other)   // Exact comparison
```

### Formatting Methods

```dart
DateTime? date = DateTime.now();

date.toStrings()                           // Default format
date.toStrings(format: Formats.date)       // Date only
date.toStrings(format: Formats.time)       // Time only
date.toStrings(format: Formats.dateTime)   // DateTime
date.toStrings(stringFormat: 'dd/MM/yyyy') // Custom format
```

## Controller: FormFieldsController

Internal state management controller.

### Properties

```dart
TextEditingController controller          // Internal text controller
bool obscure                              // Password visibility state
String form                               // Form value
FormType formType                         // Field type
String label                              // Field label
bool isLabel                              // Label display state
bool isValid                              // Validation state
Duration d100YEARS                        // 100-year duration
```

### Methods

```dart
void commit()                             // Notify listeners
void dispose()                            // Cleanup resources
```

## ColorUtil

Predefined colors for UI customization.

```dart
ColorUtil.primaryColor          // #1F1B62
ColorUtil.redColor              // Colors.red
ColorUtil.whiteColor            // Colors.white
ColorUtil.colorC7C7C7           // #C7C7C7
// ... many more colors available
```

## Formats Enum (for DateTime)

```dart
enum Formats {
  date,           // Date only
  time,           // Time only
  dateTime,       // Date and time
  dayDate,        // Day + date
  dayDateTime,    // Day + datetime
  month,          // Month only
  string,         // Custom string
}
```

## Complete Example

```dart
import 'package:form_fields/form_fields.dart';
import 'package:flutter/material.dart';

class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          FormFields<String>(
            label: 'Email',
            formType: FormType.email,
            labelPosition: LabelPosition.top,
            isRequired: true,
            onChanged: (value) {
              setState(() => _email = value ?? '');
            },
          ),
          FormFields<String>(
            label: 'Password',
            formType: FormType.password,
            labelPosition: LabelPosition.top,
            isRequired: true,
            onChanged: (value) {
              setState(() => _password = value ?? '');
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                print('Email: $_email, Password: $_password');
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

## Related Resources

- [README](README.md) - Full package documentation
- [USAGE](USAGE.md) - Detailed usage manual
- [QUICKSTART](QUICKSTART.md) - Quick start guide
- [Example App](example/lib/main.dart) - Complete example application
