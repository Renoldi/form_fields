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

## Need Help?

- **Documentation**: See [README.md](README.md)
- **Usage Manual**: See [USAGE.md](USAGE.md)
- **Example App**: Check `example/lib/main.dart`
- **Issues**: https://github.com/enerren/form_fields/issues
