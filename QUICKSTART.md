# FormFields Quick Start Guide

Get started with FormFields in 5 minutes!

## 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  form_fields: ^1.0.0
```

Run:
```bash
flutter pub get
```

## 2. Import

```dart
import 'package:form_fields/form_fields.dart';
```

## 3. Create Your First Field

```dart
FormFields<String>(
  label: 'Email Address',
  formType: FormType.email,
  onChanged: (value) {
    print('Email: $value');
  },
)
```

## 4. Common Examples

### Text Input
```dart
FormFields<String>(
  label: 'Full Name',
  onChanged: (value) {},
)
```

### Password Input
```dart
FormFields<String>(
  label: 'Password',
  formType: FormType.password,
  onChanged: (value) {},
)
```

### Phone Input
```dart
FormFields<String>(
  label: 'Phone',
  formType: FormType.phone,
  onChanged: (value) {},
)
```

### Number Input
```dart
FormFields<int>(
  label: 'Quantity',
  stripSeparators: true,
  onChanged: (value) {},
)
```

### Date Picker
```dart
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  onChanged: (value) {},
)
```

### Time Picker
```dart
// Using TimeOfDay (time-only)
FormFields<TimeOfDay>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (value) {},
)

// Using DateTime (full date-time)
FormFields<DateTime>(
  label: 'Appointment Time',
  formType: FormType.time,
  onChanged: (value) {},
)
```

## 5. Add Validation

```dart
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  isRequired: true,  // Enable validation
  onChanged: (value) {},
)
```

## 6. Customize Layout

```dart
FormFields<String>(
  label: 'Email',
  labelPosition: LabelPosition.top,  // Label on top
  borderType: BorderType.underlineInputBorder,  // Underline border
  radius: 12,  // Rounded corners
  onChanged: (value) {},
)
```

## 7. Form Submission

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      FormFields<String>(
        label: 'Email',
        isRequired: true,
        formType: FormType.email,
        onChanged: (value) {},
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Submit form
          }
        },
        child: const Text('Submit'),
      ),
    ],
  ),
)
```

## 8. Selection Widgets

### Dropdown (Single-Select)
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Germany'],
  initialValue: _selectedCountry,
  isRequired: true,
  onChanged: (value) {
    setState(() => _selectedCountry = value ?? '');
  },
)
```

### Multi-Select Dropdown
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German'],
  initialValues: _selectedLanguages,
  minSelections: 1,
  maxSelections: 3,
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
  direction: Axis.horizontal,
  onChanged: (value) {
    setState(() => _gender = value ?? '');
  },
)
```

### Checkbox
```dart
FormFieldsCheckbox<String>(
  label: 'Hobbies',
  items: ['Reading', 'Sports', 'Music', 'Travel'],
  initialValue: _hobbies,
  direction: Axis.vertical,
  onChanged: (values) {
    setState(() => _hobbies = values);
  },
)
```

## 9. Using Custom Classes

All selection widgets support generic types with custom classes:

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

// Use with dropdown
FormFieldsDropdown<Country>(
  label: 'Select Country',
  items: [
    Country('US', 'United States'),
    Country('CA', 'Canada'),
  ],
  itemLabelBuilder: (country) => country.name,
  onChanged: (value) {
    setState(() => _selectedCountry = value);
  },
)

// Use with multi-select
FormFieldsDropdownMulti<Country>(
  label: 'Countries Visited',
  items: countries,
  itemLabelBuilder: (country) => country.name,
  onChanged: (values) {
    setState(() => _countriesVisited = values);
  },
)
```

## 10. Converting Between TimeOfDay and DateTime

Use built-in extension methods for easy conversion:

```dart
// DateTime to TimeOfDay
DateTime dateTime = DateTime.now();
TimeOfDay? timeOfDay = dateTime.toTimeOfDay();

// TimeOfDay to DateTime
TimeOfDay time = TimeOfDay(hour: 14, minute: 30);
DateTime? dateTime = time.toDateTime();

// TimeOfDay to DateTime with specific date
DateTime eventDate = DateTime(2026, 12, 25);
DateTime? fullDateTime = time.toDateTimeWithDate(eventDate);
```

## Need Help?

- **Documentation**: See [README.md](README.md)
- **Usage Manual**: See [USAGE.md](USAGE.md)
- **Example App**: Check `example/lib/main.dart`
- **Issues**: https://github.com/enerren/form_fields/issues
