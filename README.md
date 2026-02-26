# FormFields

A comprehensive and reusable Flutter form field widget package with support for multiple input types including text, email, phone, password, date, time, dropdowns, radio buttons, checkboxes, and more.

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
- **Dropdown selection (single-select)**
- **Multi-select dropdown with chips**
- **Radio buttons (single selection)**
- **Checkboxes (multi-selection)**

✨ **Customization**
- Flexible label positioning (top, bottom, left, right, inline, hidden)
- Multiple border styles (outline, underline, none)
- Custom border radius
- Custom input decoration
- Custom validators
- Custom error messages and hint text
- **🌍 Multi-language support (US English default, Indonesian included)**
- Locale support for date/time pickers (string format: 'en_US', 'id_ID', etc.)
- Custom date/time formatting
- Date range customization (`firstDate`, `lastDate`) for date/datetime/daterange pickers
- Automatic number formatting with thousands separators (numeric types only)
- Numeric-only input validation for int/double fields
- **Filter/search functionality for dropdowns**
- **Custom filter hint text**

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

## Widget Overview

| Widget | Purpose | Value Type | Use Case |
|--------|---------|------------|----------|
| `FormFields<T>` | General text/date/time input | String, int, double, DateTime, TimeOfDay, DateTimeRange | Text input, numbers, dates, times |
| `FormFieldsDropdown<T>` | Single-select dropdown | Any type T | Selecting one item from a list |
| `FormFieldsDropdownMulti<T>` | Multi-select dropdown | List\<T\> | Selecting multiple items with chip display |
| `FormFieldsRadioButton<T>` | Radio button group | Any type T | Single selection from visible options |
| `FormFieldsCheckbox<T>` | Checkbox group | List\<T\> | Multi-selection from visible options |
| `FormFieldsSelect<T>` | Generic selector | T or List\<T\> | Delegating to specific widget based on FormType |

### Choosing the Right Widget

**For Single Selection:**
- **Dropdown** - Best for 5+ options, saves space
- **Radio Button** - Best for 2-5 options, shows all choices

**For Multiple Selection:**
- **Dropdown Multi** - Best for 5+ options, shows selected as chips
- **Checkbox** - Best for 2-10 options, shows all choices immediately

**For Text/Numbers/Dates:**
- **FormFields\<T\>** - Use with appropriate FormType

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

### Dropdown (Single-Select)

```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Australia'],
  initialValue: _selectedCountry,
  isRequired: true,
  onChanged: (value) {
    setState(() => _selectedCountry = value ?? '');
  },
)
```

### Dropdown Multi-Select

```dart
FormFieldsDropdownMulti<String>(
  label: 'Select Programming Languages',
  items: ['Dart', 'Java', 'Kotlin', 'Swift', 'JavaScript'],
  initialValues: _selectedLanguages,
  isRequired: true,
  minSelections: 1,
  maxSelections: 3,
  chipBackgroundColor: Colors.blue.shade100,
  onChanged: (values) {
    setState(() => _selectedLanguages = values);
  },
)
```

### Radio Button

```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender,
  isRequired: true,
  direction: Axis.horizontal,
  onChanged: (value) {
    setState(() => _gender = value ?? '');
  },
)
```

### Checkbox

```dart
FormFieldsCheckbox<String>(
  label: 'Select Hobbies',
  items: ['Reading', 'Sports', 'Music', 'Travel'],
  initialValue: _hobbies,
  isRequired: true,
  direction: Axis.vertical,
  onChanged: (values) {
    setState(() => _hobbies = values);
  },
)
```

## FormFields\<T\> Properties

The following properties apply to the `FormFields<T>` widget. For selection widgets (Dropdown, Radio, Checkbox), see the [Selection Widgets](#selection-widgets) section.

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
- `FormType.dateTimeRange` - Date range picker (returns `DateTimeRange`)
- `FormType.dropdown` - Single-select dropdown
- `FormType.dropdownMulti` - Multi-select dropdown with chips
- `FormType.radioButton` - Radio button selection
- `FormType.checkbox` - Checkbox selection

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

## Selection Widgets

### FormFieldsDropdown

Single-select dropdown with Material design.

```dart
FormFieldsDropdown<String>(
  label: 'Select Country',
  items: ['USA', 'Canada', 'UK', 'Germany', 'France'],
  initialValue: _country,
  isRequired: true,
  hintText: 'Choose a country',
  borderColor: Colors.grey,
  focusedBorderColor: Colors.blue,
  onChanged: (value) {
    setState(() => _country = value ?? '');
  },
)
```

**API Parameters:**
- `label` - Field label
- `items` - List of items to choose from
- `initialValue` - Currently selected value
- `itemLabelBuilder` - Custom function to build item labels
- `isRequired` - Whether selection is required
- `hintText` - Placeholder text
- `decoration` - Custom InputDecoration
- `labelPosition` - Label positioning
- `borderType` - Border style
- `radius` - Border radius
- `borderColor`, `focusedBorderColor`, `errorBorderColor` - Border colors
- `enabled` - Enable/disable the field

### FormFieldsDropdownMulti

Multi-select dropdown with chip display and dialog selection.

```dart
FormFieldsDropdownMulti<String>(
  label: 'Select Skills',
  items: ['Flutter', 'Firebase', 'REST API', 'GraphQL', 'UI/UX'],
  initialValues: _skills,
  isRequired: true,
  minSelections: 2,
  maxSelections: 5,
  chipBackgroundColor: Colors.blue.shade100,
  chipTextColor: Colors.blue.shade900,
  chipDeleteIconColor: Colors.blue.shade700,
  showItemCount: true,
  onChanged: (values) {
    setState(() => _skills = values);
  },
)
```

**API Parameters:**
- `label` - Field label
- `items` - List of items to choose from
- `initialValues` - List of currently selected values
- `itemLabelBuilder` - Custom function to build item labels
- `isRequired` - Whether selection is required
- `minSelections` - Minimum number of items to select
- `maxSelections` - Maximum number of items to select
- `hintText` - Placeholder text
- `showItemCount` - Show "X of Y selected" text
- `chipBackgroundColor` - Background color of chips
- `chipTextColor` - Text color of chips
- `chipDeleteIconColor` - Color of delete icon on chips
- `labelPosition` - Label positioning
- `borderType` - Border style
- `radius` - Border radius
- `borderColor`, `focusedBorderColor`, `errorBorderColor` - Border colors

### FormFieldsRadioButton

Single-selection radio button group.

```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: _gender,
  isRequired: true,
  direction: Axis.horizontal,
  activeColor: Colors.blue,
  itemPadding: EdgeInsets.symmetric(vertical: 8),
  onChanged: (value) {
    setState(() => _gender = value ?? '');
  },
)
```

**API Parameters:**
- `label` - Field label
- `items` - List of items to choose from
- `initialValue` - Currently selected value
- `itemLabelBuilder` - Custom function to build item labels
- `itemBuilder` - Custom widget builder for each item
- `isRequired` - Whether selection is required
- `direction` - Layout direction (Axis.horizontal or Axis.vertical)
- `activeColor` - Color of selected radio button
- `itemPadding` - Padding for each item
- `radius` - Border radius for container
- `borderColor`, `errorBorderColor` - Border colors

### FormFieldsCheckbox

Multi-selection checkbox group.

```dart
FormFieldsCheckbox<String>(
  label: 'Select Interests',
  items: ['Gaming', 'Music', 'Sports', 'Reading', 'Travel'],
  initialValue: _interests,
  isRequired: true,
  direction: Axis.vertical,
  activeColor: Colors.green,
  itemPadding: EdgeInsets.symmetric(vertical: 6),
  onChanged: (values) {
    setState(() => _interests = values);
  },
)
```

**API Parameters:**
- `label` - Field label
- `items` - List of items to choose from
- `initialValue` - List of currently selected values
- `itemLabelBuilder` - Custom function to build item labels
- `itemBuilder` - Custom widget builder for each item
- `isRequired` - Whether at least one selection is required
- `direction` - Layout direction (Axis.horizontal or Axis.vertical)
- `activeColor` - Color of checked checkboxes
- `itemPadding` - Padding for each item
- `radius` - Border radius for container
- `borderColor`, `errorBorderColor` - Border colors

### FormFieldsSelect

Generic wrapper that delegates to specific widgets based on `FormType`.

```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country,
  onChanged: (value) {
    setState(() => _country = value ?? '');
  },
)

// For multi-select
FormFieldsSelect<String>(
  formType: FormType.dropdownMulti,
  label: 'Languages',
  items: ['Dart', 'Java', 'Kotlin'],
  initialValues: _languages,
  onMultiChanged: (values) {
    setState(() => _languages = values);
  },
)
```

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

## Advanced Examples

### Dropdown with Custom Item Labels

```dart
class Country {
  final String code;
  final String name;
  
  Country(this.code, this.name);
}

final countries = [
  Country('US', 'United States'),
  Country('CA', 'Canada'),
  Country('GB', 'United Kingdom'),
];

FormFieldsDropdown<Country>(
  label: 'Country',
  items: countries,
  initialValue: _selectedCountry,
  itemLabelBuilder: (country) => country.name,
  onChanged: (value) {
    setState(() => _selectedCountry = value);
  },
)
```

### Multi-Select with Validation

```dart
FormFieldsDropdownMulti<String>(
  label: 'Required Skills',
  items: ['Flutter', 'Dart', 'Firebase', 'REST API', 'GraphQL'],
  initialValues: _skills,
  isRequired: true,
  minSelections: 2,
  maxSelections: 4,
  validator: (values) {
    if (values == null || values.isEmpty) {
      return 'Please select at least one skill';
    }
    if (!values.contains('Flutter') && !values.contains('Dart')) {
      return 'You must select Flutter or Dart';
    }
    return null;
  },
  onChanged: (values) {
    setState(() => _skills = values);
  },
)
```

### Radio Button with Custom Styling

```dart
FormFieldsRadioButton<String>(
  label: 'Subscription Plan',
  items: ['Free', 'Pro', 'Enterprise'],
  initialValue: _plan,
  isRequired: true,
  direction: Axis.horizontal,
  activeColor: Colors.purple,
  borderColor: Colors.grey.shade300,
  errorBorderColor: Colors.red,
  radius: 12,
  itemPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  onChanged: (value) {
    setState(() => _plan = value ?? 'Free');
  },
)
```

### Checkbox with Custom Item Builder

```dart
FormFieldsCheckbox<String>(
  label: 'Features',
  items: ['Push Notifications', 'Dark Mode', 'Offline Support', 'Analytics'],
  initialValue: _features,
  direction: Axis.vertical,
  activeColor: Colors.teal,
  itemBuilder: (item, selected) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? Colors.teal.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.teal : Colors.black87,
        ),
      ),
    );
  },
  onChanged: (values) {
    setState(() => _features = values);
  },
)
```

### Using FormFieldsSelect for Flexibility

```dart
// Single select
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Payment Method',
  items: ['Credit Card', 'PayPal', 'Bank Transfer'],
  initialValue: _paymentMethod,
  onChanged: (value) {
    setState(() => _paymentMethod = value ?? '');
  },
)

// Multi select
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Notification Preferences',
  items: ['Email', 'SMS', 'Push'],
  initialValues: _notifications,
  onMultiChanged: (values) {
    setState(() => _notifications = values);
  },
)
```

## Working with Custom Classes

All selection widgets support generic types with custom model classes for type-safe selection handling.

### Defining a Custom Model

Create a model class with proper equality operators:

```dart
class Country {
  final String code;
  final String name;
  final String flag;

  Country(this.code, this.name, this.flag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}
```

### Dropdown with Custom Class

```dart
final countries = [
  Country('US', 'United States', '🇺🇸'),
  Country('CA', 'Canada', '🇨🇦'),
  Country('GB', 'United Kingdom', '🇬🇧'),
  Country('DE', 'Germany', '🇩🇪'),
];

Country? _selectedCountry;

FormFieldsDropdown<Country>(
  label: 'Select Country',
  items: countries,
  initialValue: _selectedCountry,
  itemLabelBuilder: (country) => '${country.flag} ${country.name}',
  onChanged: (value) {
    setState(() => _selectedCountry = value);
    // Access full object properties
    if (value != null) {
      print('Code: ${value.code}, Name: ${value.name}');
    }
  },
)
```

### Multi-Select Dropdown with Custom Class

```dart
class Skill {
  final String id;
  final String name;
  final String category;

  Skill(this.id, this.name, this.category);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Skill && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

final skills = [
  Skill('flutter', 'Flutter', 'Mobile'),
  Skill('firebase', 'Firebase', 'Backend'),
  Skill('rest', 'REST API', 'Backend'),
];

List<Skill> _selectedSkills = [];

FormFieldsDropdownMulti<Skill>(
  label: 'Select Your Skills',
  items: skills,
  initialValues: _selectedSkills,
  itemLabelBuilder: (skill) => '${skill.name} (${skill.category})',
  minSelections: 1,
  maxSelections: 3,
  onChanged: (values) {
    setState(() => _selectedSkills = values);
    // Full type safety
    for (var skill in values) {
      print('${skill.name} - ${skill.category}');
    }
  },
)
```

### Radio Button with Custom Class

```dart
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;

  SubscriptionPlan(this.id, this.name, this.price);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

SubscriptionPlan? _selectedPlan;

FormFieldsRadioButton<SubscriptionPlan>(
  label: 'Choose Your Plan',
  items: [
    SubscriptionPlan('free', 'Free', 0),
    SubscriptionPlan('pro', 'Pro', 9.99),
    SubscriptionPlan('enterprise', 'Enterprise', 29.99),
  ],
  initialValue: _selectedPlan,
  itemLabelBuilder: (plan) => '${plan.name} - \$${plan.price}/mo',
  onChanged: (value) {
    setState(() => _selectedPlan = value);
  },
)
```

### Checkbox with Custom Class

```dart
class Interest {
  final String id;
  final String name;
  final Color color;

  Interest(this.id, this.name, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interest && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

List<Interest> _selectedInterests = [];

FormFieldsCheckbox<Interest>(
  label: 'Select Your Interests',
  items: [
    Interest('gaming', 'Gaming', Colors.purple),
    Interest('music', 'Music', Colors.pink),
    Interest('sports', 'Sports', Colors.orange),
  ],
  initialValue: _selectedInterests,
  itemLabelBuilder: (interest) => interest.name,
  onChanged: (values) {
    setState(() => _selectedInterests = values);
  },
)
```

### Custom Item Builder

For advanced UI customization, use `itemBuilder`:

```dart
FormFieldsRadioButton<SubscriptionPlan>(
  label: 'Choose Your Plan',
  items: plans,
  itemBuilder: (plan, selected) {
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
      child: Row(
        children: [
          Radio<SubscriptionPlan>(
            value: plan,
            groupValue: _selectedPlan,
            onChanged: (value) {
              setState(() => _selectedPlan = value);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('\$${plan.price}/month'),
              ],
            ),
          ),
        ],
      ),
    );
  },
  onChanged: (value) {
    setState(() => _selectedPlan = value);
  },
)
```

### Why Use Custom Classes?

1. **Type Safety** - Compile-time type checking
2. **Full Object Access** - Access all properties, not just strings
3. **Structured Data** - Maintain complex relationships
4. **API Integration** - Direct mapping to API models
5. **Code Clarity** - Self-documenting with meaningful types

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

The example app includes dedicated pages for:
- **FormFields Examples** - Text, email, phone, password, date, time fields
- **Dropdown Examples** - Single-select dropdowns with various configurations
- **Multi-Select Dropdown Examples** - Multi-select dropdowns with chips and validation
- **Radio Button Examples** - Radio button groups with different layouts
- **Checkbox Examples** - Checkbox groups with custom styling

Run the example app:
```bash
cd example
flutter run
```

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

### Dropdown: "There should be exactly one item" error

This error occurs when the `initialValue` is not in the `items` list or is an empty string. The widget now automatically handles this by setting invalid values to `null`.

```dart
// ✅ Correct - initialValue exists in items
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: 'USA',  // This value exists in items
  onChanged: (value) => setState(() => _country = value ?? ''),
)

// ✅ Also correct - empty string is automatically converted to null
String _country = '';  // Will be treated as null
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: _country,  // Empty string is safe
  onChanged: (value) => setState(() => _country = value ?? ''),
)
```

### Multi-Select Dropdown: Chips not showing

Ensure you're using a `List<T>` for `initialValues`, not a single value:

```dart
// ✅ Correct
List<String> _selectedItems = [];
FormFieldsDropdownMulti<String>(
  initialValues: _selectedItems,
  // ...
)

// ❌ Wrong
String _selectedItem = '';  // Should be List<String>
```

### Radio Button: No selection showing

Make sure the `initialValue` type matches the `items` type and exists in the list:

```dart
// ✅ Correct
FormFieldsRadioButton<String>(
  items: ['Option 1', 'Option 2'],
  initialValue: 'Option 1',  // Exists in items
  // ...
)

// ❌ Wrong - value doesn't exist in items
FormFieldsRadioButton<String>(
  items: ['Option 1', 'Option 2'],
  initialValue: 'Option 3',  // Not in items list
  // ...
)
```

### Checkbox: Getting List<List<T>> instead of List<T>

Ensure your state variable is `List<T>` not a nested list:

```dart
// ✅ Correct
List<String> _hobbies = [];
FormFieldsCheckbox<String>(
  items: ['Reading', 'Sports', 'Music'],
  initialValue: _hobbies,
  onChanged: (values) => setState(() => _hobbies = values),
)

// ❌ Wrong
List<List<String>> _hobbies = [];  // Don't use nested lists
```

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

## 🌍 Localization & Multi-Language Support

The FormFields package provides comprehensive multi-language support for all validation messages, error text, and UI elements. **US English is the default language**, with additional languages available.

### Supported Languages

| Language | Code | Status | Maintained By |
|----------|------|--------|---|
| 🇺🇸 English (US) | `en_US` | ✅ Default | Package Author |
| 🇮🇩 Indonesian | `id_ID` | ✅ Included | Package Author |

### Quick Setup

#### 1. Basic Usage (Default English)

Works out of the box without any configuration:

```dart
import 'package:form_fields/form_fields.dart';

FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  isRequired: true,
  onChanged: (value) => setState(() => _email = value),
  currrentValue: _email,
)
// Error message automatically shows in English: "Email is required"
```

#### 2. Enable Multi-Language Support in Your App

Add the localization delegate to your `MaterialApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormFields Example',
      locale: const Locale('id', 'ID'),  // Set to Indonesian
      localizationsDelegates: const [
        FormFieldsLocalizationsDelegate(),  // Add this delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: FormFieldsLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}
```

#### 3. Localized Validation Messages

Validation messages automatically appear in the selected language:

```dart
// English (en_US)
FormFields<String>(
  label: 'Username',
  isRequired: true,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';  // Error in English
    }
    return null;
  },
  onChanged: (value) => setState(() => _username = value),
  currrentValue: _username,
)

// Same code with locale: const Locale('id', 'ID')
// Will show: "Nama pengguna wajib diisi"  (Error in Indonesian)
```

#### 4. Built-in Localized Validators

Use the built-in validators which automatically support localization:

```dart
final l10n = FormFieldsLocalizations.of(context);

FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  isRequired: true,
  validator: FormFieldValidators.email(_email, l10n).call,
  onChanged: (value) => setState(() => _email = value),
  currrentValue: _email,
)
```

#### 5. Access Localized Strings Programmatically

```dart
final l10n = FormFieldsLocalizations.of(context);

// Simple getters
String cancelText = l10n.cancel;  // "CANCEL" (en) or "BATAL" (id)
String okText = l10n.ok;  // "OK" (en/id)
String doneText = l10n.done;  // "DONE" (en) or "SELESAI" (id)

// With parameters
String requiredMsg = l10n.enter('Email');  
// "Enter Email" (en) or "Masukkan Email" (id)

String minLengthMsg = l10n.getWithValue('passwordMinLength', 8);
// "Password must be at least 8 characters" (en)
// or "Kata sandi harus minimal 8 karakter" (id)

// Complex replacements
String rangeMsg = l10n.getWithParams('betweenValue', {
  'label': 'Age',
  'min': 18,
  'max': 65,
});
// "Age must be between 18 and 65" (en)
// or "Umur harus antara 18 dan 65" (id)
```

### Automatically Localized Elements

All of these automatically adapt to the selected language:

✅ **Validation Messages**
- Required field errors: `"{label} is required"` / `"{label} wajib diisi"`
- Type validation: `"Enter valid email address"` / `"Masukkan alamat email yang valid"`
- Length validation: `"{label} is too short"` / `"{label} terlalu pendek"`

✅ **Form Elements**
- Dropdown hints: `"Search..."` / `"Cari..."`
- Button text: `"OK"`, `"CANCEL"`, `"DONE"`, `"SUBMIT"`
- Field-specific errors for phone, password, numbers, dates

✅ **Password Validation**
- Minimum length: `"Password must be at least {value} characters"`
- Requirement messages: `"Must contain uppercase letter"`, `"Must contain a number"`

### Available Localization Keys

The package includes 50+ localization keys covering:

| Category | Keys | Example |
|----------|------|---------|
| **Common Actions** | cancel, ok, done, submit, validate | "CANCEL", "BATAL" |
| **Validation** | required, invalid, enter, enterValid | "required", "wajib diisi" |
| **Field Types** | fieldTypeEmail, fieldTypePhone, etc. | "email", "email" |
| **Errors** | tooShort, tooLong, minimumValue, maximumValue | "too short", "terlalu pendek" |
| **Password** | passwordMinLength, passwordNeedsNumber | "must be at least 8 characters" |
| **Selection** | selectAtLeast, selectAtMost, selectExactly | "Select at least 1 item" |
| **UI** | searchHint, typeHere, clearAll | "Search...", "Cari..." |

See [localization/languages/en_us.dart](lib/src/localization/languages/en_us.dart) for full list.

### Custom Language Switching at Runtime

```dart
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', 'US');

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: const [
        FormFieldsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: FormFieldsLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}

// In your page, change language like:
MyApp.of(context).setLocale(const Locale('id', 'ID'));
```

### Adding New Languages

Want to add support for your language? Follow these steps:

#### Step 1: Create Language File

Create a new file in `lib/src/localization/languages/` named `{lang}_{country}.dart`:

Example: `lib/src/localization/languages/es_es.dart`

```dart
/// Spanish language strings
final Map<String, String> esESStrings = {
  // Common actions
  'cancel': 'CANCELAR',
  'ok': 'OK',
  'done': 'LISTO',
  'submit': 'ENVIAR',
  'validate': 'VALIDAR',

  // Validation
  'required': '{label} es requerido',
  'enterPrefix': 'Ingrese ',
  'enter': 'Ingrese {label}',
  'enterValid': 'Ingrese un {type} válido para {label}',

  // Email & Phone
  'enterValidEmail': 'Ingrese una dirección de correo válida',
  'enterValidPhone': 'Ingrese un número de teléfono válido',

  // Numbers
  'enterValidInteger': 'Ingrese un número entero válido para {label}',
  'enterValidNumber': 'Ingrese un número válido para {label}',

  // Password
  'passwordRequired': 'La contraseña es requerida',
  'passwordMinLength': 'La contraseña debe tener al menos {value} caracteres',
  'passwordNeedsUppercase': 'Debe contener letra mayúscula',
  'passwordNeedsNumber': 'Debe contener un número',

  // Add all other keys from en_us.dart translated to Spanish...
  // See lib/src/localization/languages/en_us.dart for complete list
};
```

#### Step 2: Register Language in Delegate

Edit `lib/src/localization/form_fields_localizations.dart`:

```dart
import 'languages/es_es.dart';  // Add import

class FormFieldsLocalizations {
  // ... existing code ...

  /// Map of supported languages
  static final Map<String, Map<String, String>> _supportedLanguages = {
    'en_US': enUSStrings,
    'id_ID': idIDStrings,
    'es_ES': esESStrings,  // Add this line
  };
}
```

#### Step 3: Use in Your App

```dart
MaterialApp(
  locale: const Locale('es', 'ES'),  // Use Spanish
  localizationsDelegates: const [
    FormFieldsLocalizationsDelegate(),
    // ...
  ],
  supportedLocales: FormFieldsLocalizations.supportedLocales,
)
```

### Translation Template

Use this template for consistent translations:

```dart
final Map<String, String> {lang}_{country}Strings = {
  // === COMMON ACTIONS ===
  'cancel': '...',
  'ok': '...',
  'done': '...',
  'submit': '...',

  // === VALIDATION - REQUIRED & GENERAL ===
  'required': '{label} ...',
  'enterPrefix': '...',
  'enter': '...',

  // === EMAIL VALIDATION ===
  'enterValidEmail': '...',

  // === PHONE VALIDATION ===
  'enterValidPhone': '...',

  // === PASSWORD VALIDATION ===
  'passwordMinLength': '... {value} ...',
  'passwordNeedsUppercase': '...',

  // === FIELD TYPES ===
  'fieldTypeEmail': '...',
  'fieldTypePhone': '...',

  // Continue with all keys from en_us.dart...
};
```

### Troubleshooting Localization

**Q: Validation messages still show in English**

A: Make sure you've added `FormFieldsLocalizationsDelegate()` to `localizationsDelegates`:

```dart
MaterialApp(
  localizationsDelegates: const [
    FormFieldsLocalizationsDelegate(),  // Must be first
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
)
```

**Q: How do I know which locale code to use?**

A: Use standard locale codes: `Locale('en', 'US')`, `Locale('id', 'ID')`, etc.

Check [CLDR Language Coverage](https://cldr.unicode.org/) for language and country codes.

**Q: Can I mix languages in one app?**

A: Yes! Each build context gets the locale from the Material App's `locale` setting. Change it dynamically to switch languages across your entire app.

**📖 Full Documentation:** [LOCALIZATION.md](LOCALIZATION.md)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please visit the [GitHub repository](https://github.com/enerren/form_fields/issues).
