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
  String? pickerLocale = 'id_ID',
  String enterText = 'Enter ',
  String invalidIntegerText = 'Enter valid integer for',
  String invalidNumberText = 'Enter valid number for',
  DateTime? firstDate,
  DateTime? lastDate,
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
| `pickerLocale` | `String?` | `'id_ID'` | Picker locale |
| `enterText` | `String` | `'Enter '` | Custom input hint prefix |
| `invalidIntegerText` | `String` | `'Enter valid integer for'` | Error for invalid integer |
| `invalidNumberText` | `String` | `'Enter valid number for'` | Error for invalid number |
| `firstDate` | `DateTime?` | `null` | First selectable date (default: 100 years ago) |
| `lastDate` | `DateTime?` | `null` | Last selectable date (default: today) |

## Enums

### FormType

```dart
enum FormType {
  string,      // Basic text input
  email,       // Email with validation
  phone,       // Phone with validation
  password,    // Password with toggle
  date,        // Date picker (returns DateTime)
  time,        // Time picker (supports DateTime or TimeOfDay)
  dateTime,    // DateTime picker (returns DateTime)
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

### Conversion Methods

```dart
DateTime? dateTime = DateTime.now();

// Convert to TimeOfDay
TimeOfDay? timeOfDay = dateTime.toTimeOfDay();
// Returns: TimeOfDay(hour: dateTime.hour, minute: dateTime.minute)
```

## TimeOfDay Extensions

### Conversion Methods

```dart
TimeOfDay? time = TimeOfDay(hour: 14, minute: 30);

// Convert to DateTime (uses current date)
DateTime? dateTime = time.toDateTime();

// Convert to DateTime with specific date
DateTime specificDate = DateTime(2026, 12, 25);
DateTime? christmas2pm = time.toDateTimeWithDate(specificDate);
```

**Example Usage:**

```dart
// Get TimeOfDay from FormFields
FormFields<TimeOfDay>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (TimeOfDay? value) {
    if (value != null) {
      // Convert to DateTime for API submission
      DateTime meetingDateTime = value.toDateTime()!;
      
      // Or with specific date
      DateTime eventDate = DateTime(2026, 3, 15);
      DateTime fullDateTime = value.toDateTimeWithDate(eventDate)!;
    }
  },
)
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

## Type Support

### Supported Generic Types

FormFields supports the following generic types:

- `FormFields<String>` - Text input, email, phone, password
- `FormFields<int>` - Integer number input with optional formatting
- `FormFields<double>` - Decimal number input with optional formatting
- `FormFields<DateTime>` - Date, time, or datetime pickers
- `FormFields<TimeOfDay>` - Time picker (time-only values)
- `FormFields<DateTimeRange>` - Date range picker

### TimeOfDay vs DateTime for Time Pickers

#### Using TimeOfDay
```dart
FormFields<TimeOfDay>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (TimeOfDay? value) {
    if (value != null) {
      print('Hour: ${value.hour}, Minute: ${value.minute}');
      String formatted = value.format(context);
    }
  },
)
```

**Use TimeOfDay when:**
- You only need time (hour and minute)
- You want a lightweight time representation
- You don't need date context

#### Using DateTime for Time
```dart
FormFields<DateTime>(
  label: 'Appointment Time',
  formType: FormType.time,
  onChanged: (DateTime? value) {
    if (value != null) {
      String formatted = DateFormat.jm().format(value);
    }
  },
)
```

**Use DateTime when:**
- You need full date-time context
- You're working with APIs that expect DateTime
- You need date arithmetic capabilities

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

## FormFieldsRadioButton<T>

Radio button group widget for single selection from multiple options.

### Constructor

```dart
FormFieldsRadioButton<T>({
  required String label,
  List<T>? items,                                    // Simple list of options
  Map<String, List<T>>? sections,                   // Grouped options by section
  required ValueChanged<T?> onChanged,
  String Function(T item)? itemLabelBuilder,
  Widget Function(T item, bool selected)? itemBuilder,
  T? initialValue,
  bool isRequired = false,
  Axis direction = Axis.vertical,
  double radius = 10,
  Color borderColor = const Color(0xFFC7C7C7),
  Color errorBorderColor = Colors.red,
  Color activeColor = Colors.blue,
  EdgeInsets itemPadding = const EdgeInsets.symmetric(vertical: 8),
  double sectionSpacing = 12,
  Color? itemBorderColor,                           // Optional border for items
  double itemBorderWidth = 1.0,                    // Width of item borders
  double itemBorderRadius = 8,                     // Radius of item borders
  double textRightPadding = 0,                     // Right padding for text
  Color? selectedItemBackgroundColor,              // Background color for selected item
  Color? selectedItemTextColor,                    // Text color for selected item
  Color? hoverBackgroundColor,                     // Background color on hover
  bool itemShadow = false,                         // Show shadow on selected item
  LabelPosition labelPosition = LabelPosition.top, // Label position (top, bottom, left, right, inBorder, none)
  double containerPadding = 12,                    // Padding inside radio container
  double containerGap = 8,                         // Gap betweenlabel and container
  double itemMarginTop = 4,                        // Top margin for each item
  double itemMarginBottom = 4,                     // Bottom margin for each item
  FormFieldValidator<T>? validator,
})
```

### Properties

#### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `label` | `String` | Label text for the radio group |
| `onChanged` | `ValueChanged<T?>` | Callback when selection changes |

#### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `items` | `List<T>?` | `null` | Simple list of options (OR use `sections`) |
| `sections` | `Map<String, List<T>>?` | `null` | Grouped options by section name |
| `initialValue` | `T?` | `null` | Initial selected value |
| `isRequired` | `bool` | `false` | Enable validation |
| `direction` | `Axis` | `Axis.vertical` | Layout direction (only for simple `items`) |
| `borderColor` | `Color` | `Color(0xFFC7C7C7)` | Border color |
| `errorBorderColor` | `Color` | `Colors.red` | Border color when error |
| `activeColor` | `Color` | `Colors.blue` | Active radio button color |
| `radius` | `double` | `10` | Border radius |
| `itemPadding` | `EdgeInsets` | `symmetric(vertical: 8)` | Padding per item |
| `sectionSpacing` | `double` | `12` | Spacing between sections |
| `itemBorderColor` | `Color?` | `null` | Border color for each item (if null, no border) |
| `itemBorderWidth` | `double` | `1.0` | Width of item borders |
| `itemBorderRadius` | `double` | `8` | Border radius for corner rounding |
| `textRightPadding` | `double` | `0` | Right padding of text within item |
| `itemTextMarginRight` | `double` | `0` | Right margin for text (spacing after text) |
| `selectedItemBackgroundColor` | `Color?` | `null` | Background color for selected item |
| `selectedItemTextColor` | `Color?` | `null` | Text color for selected item |
| `hoverBackgroundColor` | `Color?` | `null` | Background color on hover |
| `itemShadow` | `bool` | `false` | Show shadow effect on selected item |
| `labelPosition` | `LabelPosition` | `top` | Label position (top, bottom, left, right, inBorder, none) |
| `containerPadding` | `double` | `12` | Padding inside the radio container |
| `containerGap` | `double` | `8` | Gap between label and container |
| `itemMarginTop` | `double` | `4` | Top margin for each item |
| `itemMarginBottom` | `double` | `4` | Bottom margin for each item |
| `itemLabelBuilder` | `String Function(T)?` | `null` | Custom text for each item |
| `itemBuilder` | `Widget Function(T, bool)?` | `null` | Custom widget for each item |
| `validator` | `FormFieldValidator<T>?` | `null` | Custom validation |

### Usage Examples

#### Basic Usage (Simple Items, Vertical)

```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: const ['Male', 'Female', 'Other'],
  initialValue: 'Male',
  isRequired: true,
  direction: Axis.vertical,
  activeColor: Colors.blue,
  onChanged: (value) {
    setState(() => selectedGender = value ?? '');
  },
)
```

#### Horizontal Layout

```dart
FormFieldsRadioButton<String>(
  label: 'Marital Status',
  items: const ['Single', 'Married', 'Divorced'],
  isRequired: true,
  direction: Axis.horizontal,  // Items displayed in a row
  onChanged: (value) {
    setState(() => maritalStatus = value ?? '');
  },
)
```

#### Sectioned with Horizontal Items

```dart
FormFieldsRadioButton<String>(
  label: 'Subscription Plan',
  sections: {
    'Cloud Services': ['Starter', 'Professional', 'Enterprise'],
    'Support Level': ['Basic', 'Premium', '24/7'],
    'Duration': ['Monthly', 'Quarterly', 'Yearly'],
  },
  isRequired: true,
  sectionSpacing: 16,
  activeColor: Colors.green,
  onChanged: (value) {
    setState(() => selectedPlan = value ?? '');
  },
)
```

**Output Format:**
```
Cloud Services
[ Starter ] [ Professional ] [ Enterprise ]

Support Level
[ Basic ] [ Premium ] [ 24/7 ]

Duration
[ Monthly ] [ Quarterly ] [ Yearly ]
```

#### Beautiful Styling with Selection Highlights

```dart
FormFieldsRadioButton<String>(
  label: 'Delivery Option',
  items: const ['Pickup', 'Standard Delivery', 'Express Delivery'],
  isRequired: true,
  activeColor: Colors.orange.shade600,
  selectedItemBackgroundColor: Colors.orange.shade50,    // Selected item background
  selectedItemTextColor: Colors.orange.shade900,         // Selected item text color
  hoverBackgroundColor: Colors.orange.shade100,          // Hover background
  itemBorderColor: Colors.orange.shade300,
  itemBorderWidth: 1.5,
  itemBorderRadius: 10,
  itemShadow: true,                                       // Show shadow on selected
  itemPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
  onChanged: (value) {
    setState(() => selectedDelivery = value ?? '');
  },
)
```

**Features:**
- ✅ Beautiful background highlight when item is selected
- ✅ Text color changes to emphasize selection
- ✅ Smooth hover effects with color change
- ✅ Optional shadow effect on selected item
- ✅ Better spacing and visual hierarchy

#### Sectioned with Item Borders

```dart
FormFieldsRadioButton<String>(
  label: 'Theme Preferences',
  sections: {
    'Theme': ['Light', 'Dark', 'Auto'],
    'Notifications': ['All', 'Important', 'None'],
  },
  isRequired: true,
  borderColor: Colors.grey,
  activeColor: Colors.teal,
  itemBorderColor: Colors.teal.shade300,  // Add border to each item
  itemBorderWidth: 1.5,
  itemBorderRadius: 6,
  textRightPadding: 8,                     // Add right padding to text
  sectionSpacing: 16,
  onChanged: (value) {
    setState(() => preference = value ?? '');
  },
)
```

**Output Format:**
```
Theme
[Light] [Dark] [Auto]

Notifications
[All] [Important] [None]
```
(With teal borders around each item and right-padded text)

#### Custom Item Labels

```dart
FormFieldsRadioButton<int>(
  label: 'Rating',
  items: const [1, 2, 3, 4, 5],
  itemLabelBuilder: (value) => '⭐' * value,
  isRequired: true,
  direction: Axis.horizontal,
  onChanged: (value) {
    setState(() => rating = value ?? 0);
  },
)
```

#### Custom Item Widgets

```dart
FormFieldsRadioButton<PaymentMethod>(
  label: 'Payment Method',
  items: [
    PaymentMethod(id: 1, name: 'Credit Card', icon: Icons.credit_card),
    PaymentMethod(id: 2, name: 'PayPal', icon: Icons.paypal),
    PaymentMethod(id: 3, name: 'Apple Pay', icon: Icons.apple),
  ],
  itemBuilder: (item, selected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? Colors.blue : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(item.icon, color: selected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(item.name),
        ],
      ),
    );
  },
  onChanged: (value) {
    setState(() => paymentMethod = value);
  },
)
```

#### With Validation

```dart
FormFieldsRadioButton<String>(
  label: 'Accept Terms',
  items: const ['I Agree', 'I Disagree'],
  isRequired: true,
  validator: (value) {
    if (value == 'I Disagree') {
      return 'You must agree to terms to proceed';
    }
    return null;
  },
  onChanged: (value) {
    setState(() => termsAccepted = value ?? '');
  },
)
```

### Comparison: Items vs Sections

| Feature | `items` | `sections` |
|---------|---------|-----------|
| Layout | Single group, linear | Multiple groups, organized |
| Use Case | 2-5 options | 6+ options or logical grouping |
| Direction | `vertical` or `horizontal` | Always horizontal per section |
| Example | Gender, Marital Status | Plans with features, settings groups |

### Notes

- **Either `items` or `sections` must be provided**, not both
- When using `sections`, items within each section are always displayed horizontally
- When using `items` with `direction: Axis.horizontal`, takes advantage of Wrap widget for responsive layout
- Validation automatically shows error message with red border
- All items must be of the same generic type `<T>`

## FormFieldsCheckbox<T>

Checkbox group widget for multi-selection from multiple options.

### Constructor

```dart
FormFieldsCheckbox<T>({
  required String label,
  required List<T> items,
  required ValueChanged<List<T>> onChanged,
  List<T>? initialValue,
  bool isRequired = false,
  Axis direction = Axis.vertical,
  double radius = 10,
  Color borderColor = const Color(0xFFC7C7C7),
  Color errorBorderColor = Colors.red,
  Color activeColor = Colors.blue,
  EdgeInsets itemPadding = const EdgeInsets.symmetric(vertical: 6),
  double itemMarginTop = 4,
  double itemMarginBottom = 4,
  double itemMarginHorizontal = 0,
  Color? itemBorderColor,                           // Optional border for items
  double itemBorderWidth = 1.0,                    // Width of item borders
  double itemBorderRadius = 8,                     // Radius of item borders
  String Function(T item)? itemLabelBuilder,
  Widget Function(T item, bool selected)? itemBuilder,
  FormFieldValidator<List<T>>? validator,
})
```

### Properties

#### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `label` | `String` | Label text for the checkbox group |
| `items` | `List<T>` | List of options |
| `onChanged` | `ValueChanged<List<T>>` | Callback when selection changes |

#### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `initialValue` | `List<T>?` | `null` | Initial selected values |
| `isRequired` | `bool` | `false` | Enable validation |
| `direction` | `Axis` | `Axis.vertical` | Layout direction |
| `radius` | `double` | `10` | Border radius |
| `borderColor` | `Color` | `Color(0xFFC7C7C7)` | Border color |
| `errorBorderColor` | `Color` | `Colors.red` | Border color when error |
| `activeColor` | `Color` | `Colors.blue` | Active checkbox color |
| `itemPadding` | `EdgeInsets` | `symmetric(vertical: 6)` | Padding per item |
| `itemMarginTop` | `double` | `4` | Top margin for each item |
| `itemMarginBottom` | `double` | `4` | Bottom margin for each item |
| `itemMarginHorizontal` | `double` | `0` | Left/right margin for each item |
| `itemBorderColor` | `Color?` | `null` | Border color for each item (if null, no border) |
| `itemBorderWidth` | `double` | `1.0` | Width of item borders |
| `itemBorderRadius` | `double` | `8` | Border radius for each item |
| `itemLabelBuilder` | `String Function(T)?` | `null` | Custom text for each item |
| `itemBuilder` | `Widget Function(T, bool)?` | `null` | Custom widget for each item |
| `validator` | `FormFieldValidator<List<T>>?` | `null` | Custom validation |

### Usage Example

```dart
FormFieldsCheckbox<String>(
  label: 'Interests',
  items: const ['Sports', 'Music', 'Reading'],
  initialValue: const ['Music'],
  isRequired: true,
  itemBorderColor: Colors.grey,
  itemBorderWidth: 1.0,
  itemBorderRadius: 8,
  onChanged: (value) {
    setState(() => interests = value);
  },
)
```
