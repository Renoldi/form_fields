# User Manual - FormFields Package

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Basic Concepts](#basic-concepts)
4. [Field Types Guide](#field-types-guide)
5. [Customization Options](#customization-options)
6. [Validation](#validation)
7. [State Management](#state-management)
8. [Advanced Usage](#advanced-usage)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## Introduction

FormFields is a powerful and flexible Flutter form field widget package that simplifies form creation and validation. It provides out-of-the-box support for various input types including text, email, phone, password, and date/time pickers.

### Key Benefits

- **Easy Integration**: Drop-in replacement with minimal setup
- **Type Safety**: Generic type support for compile-time type checking
- **Rich Validation**: Built-in validators with custom message support
- **Beautiful UI**: Material Design inspired layouts with full customization
- **Developer Friendly**: Clear API and comprehensive documentation

## Installation

### Step 1: Add Dependency

Edit your `pubspec.yaml`:

```yaml
dependencies:
  form_fields: ^1.0.0
```

### Step 2: Get Packages

```bash
flutter pub get
```

or

```bash
flutter packages get
```

### Step 3: Import Package

```dart
import 'package:form_fields/form_fields.dart';
```

## Basic Concepts

### 1. Generic Type System

FormFields uses Dart generics to ensure type safety:

```dart
// String field
FormFields<String>(
  label: 'Name',
  onChanged: (String? value) {
    // value is typed as String
  },
)

// Integer field
FormFields<int>(
  label: 'Quantity',
  onChanged: (int? value) {
    // value is typed as int
  },
)

// DateTime field
FormFields<DateTime>(
  label: 'Birth Date',
  onChanged: (DateTime? value) {
    // value is typed as DateTime
  },
)
```

### 2. Value Handling

The `onChanged` callback fires when the user completes input with a 500ms debounce:

```dart
FormFields<String>(
  label: 'Search',
  onChanged: (value) {
    // Called after user stops typing for 500ms
    print('User entered: $value');
  },
)
```

### 3. State Management

FormFields uses Provider for internal state management. Your parent widget must be wrapped with `MultiProvider` if needed:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyProvider()),
  ],
  child: MyApp(),
)
```

## Field Types Guide

### Text Field

Basic text input for names, usernames, etc.

```dart
FormFields<String>(
  label: 'Username',
  formType: FormType.string,
  labelPosition: LabelPosition.top,
  onChanged: (value) {
    setState(() => _username = value ?? '');
  },
)
```

**Features:**
- Single line input
- Text keyboard
- Optional validation

### Email Field

Email address input with validation.

```dart
FormFields<String>(
  label: 'Email Address',
  formType: FormType.email,
  isRequired: true,
  onChanged: (value) {
    setState(() => _email = value ?? '');
  },
)
```

**Validation:**
- Checks for `@` symbol
- Validates domain format
- Shows error for invalid email

### Phone Field

Phone number input with Indonesian format validation.

```dart
FormFields<String>(
  label: 'Mobile Phone',
  formType: FormType.phone,
  isRequired: true,
  onChanged: (value) {
    setState(() => _phone = value ?? '');
  },
)
```

**Format:**
- Expected format: `0` followed by 11 digits: `081234567890`
- Also accepts: `+081234567890`

### Password Field

Secure password input with visibility toggle.

```dart
FormFields<String>(
  label: 'Password',
  formType: FormType.password,
  isRequired: true,
  onChanged: (value) {
    setState(() => _password = value ?? '');
  },
)
```

**Features:**
- Hides text by default
- Visibility toggle button
- Minimum 6 characters validation

### Integer Field

Numeric input for whole numbers.

```dart
FormFields<int>(
  label: 'Quantity',
  formType: FormType.string,  // Use string type for input
  stripSeparators: true,  // Format with commas: 1,000
  onChanged: (value) {
    setState(() => _quantity = value ?? 0);
  },
)
```

**Features:**
- Automatic formatting with thousands separators
- Validates integer format
- Returns clean integer value

### Decimal Field

Numeric input for floating-point numbers.

```dart
FormFields<double>(
  label: 'Price',
  stripSeparators: true,
  onChanged: (value) {
    setState(() => _price = value ?? 0.0);
  },
)
```

**Features:**
- Decimal point input
- Thousands separator formatting
- Returns clean double value

### Date Picker

Calendar date selection.

```dart
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  onChanged: (value) {
    setState(() => _birthDate = value);
  },
)
```

**Features:**
- Shows calendar picker
- Customizable date format (default: `MMM d, yyyy`)
- Limits to past dates by default

### Time Picker

Clock time selection with support for both `DateTime` and `TimeOfDay` types.

#### Using DateTime Type

```dart
FormFields<DateTime>(
  label: 'Start Time',
  formType: FormType.time,
  onChanged: (value) {
    setState(() => _startTime = value);
  },
)
```

**Features:**
- Shows time picker dialog
- Returns DateTime with current date and selected time
- Customizable time format (default: `h:mm a`)

#### Using TimeOfDay Type

```dart
FormFields<TimeOfDay>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (value) {
    setState(() => _meetingTime = value);
  },
)
```

**Features:**
- Shows time picker dialog
- Returns TimeOfDay object directly
- More lightweight than DateTime for time-only values
- Customizable format via `customFormat`

### DateTime Picker

Combined date and time selection.

```dart
FormFields<DateTime>(
  label: 'Event DateTime',
  formType: FormType.dateTime,
  onChanged: (value) {
    setState(() => _eventDateTime = value);
  },
)
```

**Features:**
- Shows date picker followed by time picker
- Customizable format (default: `MMM d, yyyy h:mm a`)
- Returns complete DateTime

### Date Range Picker

Select start and end dates.

```dart
FormFields<DateTimeRange>(
  label: 'Trip Duration',
  onChanged: (value) {
    setState(() => _tripDates = value);
  },
)
```

**Features:**
- Shows date range picker
- Returns DateTimeRange with start and end
- Great for booking, rental periods

### Multiline Text

Multi-paragraph text input.

```dart
FormFields<String>(
  label: 'Bio',
  multiLine: 3,  // 3 lines visible
  stripSeparators: false,
  onChanged: (value) {
    setState(() => _bio = value ?? '');
  },
)
```

**Features:**
- Configurable line count
- Text area style input
- Supports newlines

## Customization Options

### Label Positioning

Control where the label appears relative to the input:

```dart
// Top of input (default for most)
FormFields<String>(
  label: 'Email',
  labelPosition: LabelPosition.top,
  onChanged: (value) {},
)

// Bottom of input
FormFields<String>(
  label: 'Email',
  labelPosition: LabelPosition.bottom,
  onChanged: (value) {},
)

// Left side of input
FormFields<String>(
  label: 'Email',
  labelPosition: LabelPosition.left,
  onChanged: (value) {},
)

// Right side of input
FormFields<String>(
  label: 'Email',
  labelPosition: LabelPosition.right,
  onChanged: (value) {},
)

// Inside border (floating label)
FormFields<String>(
  label: 'Email',
  labelPosition: LabelPosition.inBorder,
  onChanged: (value) {},
)

// No label display
FormFields<String>(
  label: 'Email',
  labelPosition: LabelPosition.none,
  onChanged: (value) {},
)
```

### Border Styles

Choose from different border styles:

```dart
// Outlined border (default)
FormFields<String>(
  label: 'Email',
  borderType: BorderType.outlineInputBorder,
  radius: 12,
  onChanged: (value) {},
)

// Underline border
FormFields<String>(
  label: 'Email',
  borderType: BorderType.underlineInputBorder,
  onChanged: (value) {},
)

// No border
FormFields<String>(
  label: 'Email',
  borderType: BorderType.none,
  onChanged: (value) {},
)
```

### Border Radius

Customize corner roundness:

```dart
FormFields<String>(
  label: 'Email',
  radius: 16,  // Sharp to very rounded
  onChanged: (value) {},
)
```

### Prefix and Suffix

Add widgets before or after input:

```dart
FormFields<String>(
  label: 'Price',
  prefixIcon: Icon(Icons.attach_money),
  suffixIcon: Icon(Icons.clear),
  onChanged: (value) {},
)

// Or use widgets
FormFields<String>(
  label: 'Weight',
  suffix: Text('kg'),
  onChanged: (value) {},
)
```

### Custom Input Decoration

Override default styling:

```dart
FormFields<String>(
  label: 'Email',
  inputDecoration: InputDecoration(
    hintText: 'user@example.com',
    helperText: 'Enter your email address',
    filled: true,
    fillColor: Colors.grey.shade100,
  ),
  onChanged: (value) {},
)
```

### Keyboard Navigation

Set focus nodes for keyboard navigation:

```dart
final _nameFocus = FocusNode();
final _emailFocus = FocusNode();

FormFields<String>(
  label: 'Name',
  focusNode: _nameFocus,
  nextFocusNode: _emailFocus,  // Tab to email field
  onChanged: (value) {},
)

FormFields<String>(
  label: 'Email',
  focusNode: _emailFocus,
  onChanged: (value) {},
)
```

### Locale Support

Set language/region for date/time pickers:

```dart
FormFields<DateTime>(
  label: 'Date',
  formType: FormType.date,
  pickerLocale: 'id_ID',  // Indonesian
  onChanged: (value) {},
)

FormFields<DateTime>(
  label: 'Date',
  formType: FormType.date,
  pickerLocale: 'en_US',  // English (US)
  onChanged: (value) {},
)
```

### Custom Date/Time Format

```dart
FormFields<DateTime>(
  label: 'Date',
  formType: FormType.date,
  customFormat: 'dd/MM/yyyy',
  onChanged: (value) {},
)

FormFields<DateTime>(
  label: 'Time',
  formType: FormType.time,
  customFormat: 'HH:mm',
  onChanged: (value) {},
)
```

### Custom Date Range

Control the selectable date range for date pickers:

```dart
// Future dates only (e.g., appointment booking)
FormFields<DateTime>(
  label: 'Appointment Date',
  formType: FormType.date,
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(Duration(days: 365)),
  onChanged: (value) {},
)

// Past dates only (default: last 100 years to today)
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  firstDate: DateTime(1924, 1, 1),
  lastDate: DateTime.now(),
  onChanged: (value) {},
)

// Specific date range
FormFields<DateTime>(
  label: 'Event Date',
  formType: FormType.date,
  firstDate: DateTime(2026, 1, 1),
  lastDate: DateTime(2026, 12, 31),
  onChanged: (value) {},
)

// DateRange with custom limits
FormFields<DateTimeRange>(
  label: 'Vacation Period',
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(Duration(days: 730)), // 2 years ahead
  onChanged: (value) {},
)

// DateTime picker with date range
FormFields<DateTime>(
  label: 'Meeting DateTime',
  formType: FormType.dateTime,
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(Duration(days: 90)),
  onChanged: (value) {},
)
```

**Default Behavior:**
- `firstDate`: If not specified, defaults to 100 years ago
- `lastDate`: If not specified, defaults to today
- `initialDate`: Automatically adjusted to be within the valid range

### Custom Error Messages and Hint Text

Customize validation messages and hint text for numeric fields:

```dart
FormFields<int>(
  label: 'Age',
  enterText: 'Please enter ',  // Changes hint text prefix
  invalidIntegerText: 'Invalid number for',  // Custom error for invalid integers
  onChanged: (value) {
    setState(() => _age = value ?? 0);
  },
)

FormFields<double>(
  label: 'Price',
  invalidNumberText: 'Please provide a valid number for',  // Custom error for invalid numbers
  onChanged: (value) {
    setState(() => _price = value ?? 0.0);
  },
)
```

## Validation

### Enable Validation

```dart
FormFields<String>(
  label: 'Email',
  isRequired: true,  // Enable validation
  onChanged: (value) {},
)
```

### Built-in Validators

```dart
// Required field (not empty)
FormFieldValidators.required('Username')

// Email format
FormFieldValidators.email('Email')

// Phone format
FormFieldValidators.phone('Phone')

// Password length >= 6
FormFieldValidators.password('Password')

// Numeric format
FormFieldValidators.number('Amount')

// Minimum length
FormFieldValidators.minLength('Username', 3)

// Maximum length
FormFieldValidators.maxLength('Code', 8)

// Range (for numbers)
FormFieldValidators.range('Age', 18, 100)

// Pattern matching
FormFieldValidators.pattern('Username', r'^[a-zA-Z0-9_]+$')

// Field matching
FormFieldValidators.match('Password', password)

// Compose multiple
FormFieldValidators.compose([
  FormFieldValidators.required('Field'),
  FormFieldValidators.minLength('Field', 3),
])
```

### Custom Validators

```dart
FormFields<String>(
  label: 'Username',
  isRequired: true,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (value.length < 3) {
      return 'Min 3 chars';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only alphanumeric and _';
    }
    return null;
  },
  onChanged: (value) {},
)
```

### Custom Error Messages

```dart
FormFields<String>(
  label: 'Email',
  isRequired: true,
  validator: FormFieldValidators.email(
    'Email',
    customMessage: 'Please enter a valid email address',
  ),
  onChanged: (value) {},
)
```

## State Management

### Using setState

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => MyFormState();
}

class MyFormState extends State<MyForm> {
  String _email = '';

  @override
  Widget build(BuildContext context) {
    return FormFields<String>(
      label: 'Email',
      onChanged: (value) {
        setState(() => _email = value ?? '');
      },
    );
  }
}
```

### Using Provider

```dart
final _emailNotifier = ValueNotifier<String>('');

ValueListenableBuilder<String>(
  valueListenable: _emailNotifier,
  builder: (context, email, _) {
    return FormFields<String>(
      label: 'Email',
      currrentValue: email,
      onChanged: (value) {
        _emailNotifier.value = value ?? '';
      },
    );
  },
)
```

## Advanced Usage

### Working with TimeOfDay vs DateTime for Time Pickers

The `FormType.time` picker supports both `DateTime` and `TimeOfDay` generic types. Choose based on your use case:

#### When to Use TimeOfDay

Use `FormFields<TimeOfDay>` when you only need the time component:

```dart
TimeOfDay? _meetingTime;

FormFields<TimeOfDay>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (value) {
    setState(() => _meetingTime = value);
  },
  currrentValue: _meetingTime,
)

// Access time components
if (_meetingTime != null) {
  int hour = _meetingTime.hour;      // 0-23
  int minute = _meetingTime.minute;  // 0-59
  String formatted = _meetingTime.format(context); // 12-hour format with AM/PM
}
```

**Benefits:**
- Lightweight - only stores hour and minute
- Native Flutter type for time-only values
- Easy integration with Material time pickers
- Clear intent that only time matters

#### When to Use DateTime for Time

Use `FormFields<DateTime>` when you need a full date-time value:

```dart
DateTime? _appointmentTime;

FormFields<DateTime>(
  label: 'Appointment Time',
  formType: FormType.time,
  onChanged: (value) {
    setState(() => _appointmentTime = value);
  },
  currrentValue: _appointmentTime,
)

// Access as DateTime
if (_appointmentTime != null) {
  int hour = _appointmentTime.hour;
  int minute = _appointmentTime.minute;
  // Date components use current date
  String formatted = DateFormat.jm().format(_appointmentTime);
}
```

**Benefits:**
- Includes full date context (uses current date)
- Direct compatibility with APIs expecting DateTime
- Built-in formatting via DateFormat
- Easier date arithmetic if needed later

#### Converting Between Types

The package provides convenient extension methods for converting between TimeOfDay and DateTime:

```dart
// DateTime to TimeOfDay (using extension)
DateTime dateTime = DateTime.now();
TimeOfDay? timeOfDay = dateTime.toTimeOfDay();

// TimeOfDay to DateTime (using current date - extension)
TimeOfDay time = TimeOfDay(hour: 14, minute: 30);
DateTime? dateTime = time.toDateTime();

// TimeOfDay to DateTime with specific date (extension)
DateTime specificDate = DateTime(2026, 12, 25);
DateTime? christmas2pm = time.toDateTimeWithDate(specificDate);
```

**Manual Conversion (if needed):**

```dart
// TimeOfDay to DateTime (manual)
TimeOfDay timeOfDay = TimeOfDay(hour: 14, minute: 30);
DateTime dateTime = DateTime(
  DateTime.now().year,
  DateTime.now().month,
  DateTime.now().day,
  timeOfDay.hour,
  timeOfDay.minute,
);

// DateTime to TimeOfDay (manual)
DateTime dateTime = DateTime.now();
TimeOfDay timeOfDay = TimeOfDay(
  hour: dateTime.hour,
  minute: dateTime.minute,
);
```

### Form Validation

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
            // Form is valid
            submitForm();
          }
        },
        child: Text('Submit'),
      ),
    ],
  ),
)
```

### Conditional Fields

```dart
Column(
  children: [
    FormFields<String>(
      label: 'Country',
      onChanged: (value) => setState(() => _country = value),
    ),
    if (_country == 'Indonesia')
      FormFields<String>(
        label: 'Province',
        onChanged: (value) => setState(() => _province = value),
      ),
  ],
)
```

### Dynamic Field Count

```dart
List<int> _phoneCount = [0];

Column(
  children: [
    ...List.generate(_phoneCount.length, (index) {
      return FormFields<String>(
        label: 'Phone ${index + 1}',
        formType: FormType.phone,
        onChanged: (value) {
          setState(() => _phones[index] = value ?? '');
        },
      );
    }),
    ElevatedButton(
      onPressed: () {
        setState(() => _phoneCount.add(_phoneCount.length));
      },
      child: Text('Add Phone'),
    ),
  ],
)
```


## Selection Widgets: Dropdown, Multi-Select, Radio, Checkbox

All selection widgets support both simple and custom class types, as well as nullable and non-nullable usage for full null safety.

### Dropdown (Single-Select)
```dart
// Non-nullable
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Germany'],
  initialValue: _selectedCountry, // String
  isRequired: true,
  onChanged: (value) => setState(() => _selectedCountry = value ?? ''),
)

// Nullable
FormFieldsDropdown<String?>(
  label: 'Country (optional)',
  items: ['USA', 'Canada', 'UK', 'Germany'],
  initialValue: _selectedCountry, // String?
  onChanged: (value) => setState(() => _selectedCountry = value),
)
```

### Multi-Select Dropdown
```dart
// Non-nullable
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German'],
  initialValues: _selectedLanguages, // List<String>
  minSelections: 1,
  maxSelections: 3,
  onChanged: (values) => setState(() => _selectedLanguages = values),
)

// Nullable
FormFieldsDropdownMulti<String?>(
  label: 'Languages (optional)',
  items: ['English', 'Spanish', 'French', 'German'],
  initialValues: _selectedLanguages, // List<String?>
  onChanged: (values) => setState(() => _selectedLanguages = values),
)
```

### Radio Button
```dart
// Non-nullable
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String
  direction: Axis.horizontal,
  onChanged: (value) => setState(() => _gender = value ?? ''),
)

// Nullable
FormFieldsRadioButton<String?>(
  label: 'Gender (optional)',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender, // String?
  onChanged: (value) => setState(() => _gender = value),
)
```

### Checkbox
```dart
// Non-nullable
FormFieldsCheckbox<String>(
  label: 'Hobbies',
  items: ['Reading', 'Sports', 'Music', 'Travel'],
  initialValue: _hobbies, // List<String>
  direction: Axis.vertical,
  onChanged: (values) => setState(() => _hobbies = values),
)

// Nullable
FormFieldsCheckbox<String?>(
  label: 'Optional Hobbies',
  items: ['Reading', 'Sports', 'Music', 'Travel'],
  initialValue: _optionalHobbies, // List<String?>
  direction: Axis.vertical,
  onChanged: (values) => setState(() => _optionalHobbies = values),
)
```

### Using Custom Classes

All selection widgets support custom class types for advanced use cases:

```dart
// Define your model
class Country {
  final String code;
  final String name;
  Country(this.code, this.name);
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Country && code == other.code;
  @override
  int get hashCode => code.hashCode;
}

// Dropdown with custom class
FormFieldsDropdown<Country>(
  label: 'Select Country',
  items: [
    Country('US', 'United States'),
    Country('CA', 'Canada'),
  ],
  itemLabelBuilder: (country) => country.name,
  onChanged: (value) => setState(() => _selectedCountry = value),
)

// Multi-select with custom class
FormFieldsDropdownMulti<Country>(
  label: 'Countries Visited',
  items: countries, // List<Country>
  itemLabelBuilder: (country) => country.name,
  onChanged: (values) => setState(() => _countriesVisited = values),
)

// Radio button with custom class
FormFieldsRadioButton<Country>(
  label: 'Country',
  items: countries, // List<Country>
  itemLabelBuilder: (country) => country.name,
  onChanged: (value) => setState(() => _selectedCountry = value),
)

// Checkbox with custom class
FormFieldsCheckbox<Country>(
  label: 'Favorite Countries',
  items: countries, // List<Country>
  itemLabelBuilder: (country) => country.name,
  onChanged: (values) => setState(() => _favoriteCountries = values),
)
```

### Custom Item Builder for Advanced UI

Use `itemBuilder` for complete UI customization:

```dart
FormFieldsRadioButton<Country>(
  label: 'Choose Country',
  items: countries,
  itemBuilder: (country, selected) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade50 : Colors.white,
        border: Border.all(
          color: selected ? Colors.blue : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        country.name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  },
  onChanged: (value) => setState(() => _selectedCountry = value),
)
```

### Benefits and Best Practices for Custom Classes

1. **Type Safety**: Compile-time checking of object types
2. **Full Object Access**: Access all properties, not just display strings
3. **Structured Data**: Maintain complex relationships between fields
4. **Code Clarity**: Self-documenting code with meaningful types
5. **Validation**: Validate based on object properties
6. **API Integration**: Direct mapping to API models

**Best Practices:**
- Always implement `==` and `hashCode` for your model
- Use `final` fields for immutability
- Provide a meaningful `toString()` for debugging
- Use `itemLabelBuilder` for display customization


#### Benefits of Custom Classes

1. **Type Safety**: Compile-time checking of object types
2. **Full Object Access**: Access all properties, not just display strings
3. **Structured Data**: Maintain complex relationships between fields
4. **Code Clarity**: Self-documenting code with meaningful types
5. **Validation**: Validate based on object properties
6. **API Integration**: Direct mapping to API models

#### Best Practices for Custom Classes

1. **Always implement `==` operator**: Required for selection comparison
2. **Always implement `hashCode`**: Required for Set/Map operations
3. **Keep models immutable**: Use `final` fields
4. **Provide meaningful `toString()`**: Helpful for debugging
5. **Use `itemLabelBuilder`**: Customize display without changing model

## Best Practices

### 1. Always Provide onChange Handler

```dart
FormFields<String>(
  label: 'Email',
  onChanged: (value) {
    // Required - handle value changes
  },
)
```

### 2. Use Appropriate FormType

```dart
// GOOD
FormFields<String>(
  label: 'Email',
  formType: FormType.email,  // Specific type
  onChanged: (value) {},
)

// AVOID
FormFields<String>(
  label: 'Email',
  formType: FormType.string,  // Loss of validation
  onChanged: (value) {},
)
```

### 3. Validate for Required Fields

```dart
FormFields<String>(
  label: 'Name',
  isRequired: true,  // Enable validation
  onChanged: (value) {},
)
```

### 4. Use Appropriate Generic Types

```dart
// GOOD - Correct types
FormFields<String>(label: 'Name', onChanged: (v) {})
FormFields<int>(label: 'Count', onChanged: (v) {})
FormFields<DateTime>(label: 'Date', onChanged: (v) {})

// AVOID - Wrong types
FormFields<int>(label: 'Name', onChanged: (v) {})  // String name as int
```


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

### 6. Clear Error States

Reset form validation when needed:

```dart
final _formKey = GlobalKey<FormState>();

void clearForm() {
  _formKey.currentState?.reset();
}
```

## Troubleshooting

### Problem: Phone validation failing

**Solution:** Ensure phone format matches expected pattern.

```dart
// Valid: 081234567890 (0 + 11 digits)
// Valid: +081234567890
// Invalid: 1234567890 (missing leading 0)
// Invalid: 0812345678 (only 10 digits)
```

### Problem: Numbers not formatting

**Solution:** Enable `stripSeparators` for number display.

```dart
FormFields<int>(
  label: 'Amount',
  stripSeparators: true,  // Must enable
  onChanged: (value) {},
)
```

### Problem: Date picker in wrong language

**Solution:** Set correct `pickerLocale`.

```dart
FormFields<DateTime>(
  label: 'Date',
  pickerLocale: 'en_US',  // English
  onChanged: (value) {},
)
```

### Problem: Can't close keyboard after time picker

**Solution:** This is expected behavior. Use `FocusNode` to manage focus:

```dart
final _focus = Focus Node();

FormFields<DateTime>(
  label: 'Time',
  formType: FormType.time,
  focusNode: _focus,
  onChanged: (value) {
    _focus.unfocus();  // Close keyboard
  },
)
```

### Problem: Initial value not showing

**Solution:** Use `currrentValue` parameter.

```dart
FormFields<String>(
  label: 'Email',
  currrentValue: _email,  // Provide initial value
  onChanged: (value) => setState(() => _email = value ?? ''),
)
```

### Problem: Form not validating

**Solution:** Ensure `isRequired: true` is set and field is in a Form widget.

```dart
Form(
  key: _formKey,
  child: FormFields<String>(
    label: 'Email',
    isRequired: true,  // Required for validation
    onChanged: (value) {},
  ),
)
```

## Additional Resources

- **GitHub**: https://github.com/enerren/form_fields
- **Issues**: https://github.com/enerren/form_fields/issues
- **Example App**: Check the example folder for complete working application

## Support & Feedback

Please submit issues, feature requests, or feedback through GitHub Issues.
