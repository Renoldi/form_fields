# FormFields

Main flexible form widget that supports multiple input types (`FormType`) with validation, formatting, localization, and customizable decoration.

## Basic Usage

```dart
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  currrentValue: value,
  onChanged: (v) => value = v,
)
```

## Common Options

- `formType`: Selects input behavior (email, phone, password, date, etc).
- `isRequired`: Enables required-field validation.
- `validator`: Adds custom validation.
- `labelPosition`: Controls label placement.
- `borderType` and `radius`: Border appearance.
- `inputDecoration`: Additional InputDecoration control.

## Architecture Links

- [Architecture Diagram](../../ARCHITECTURE.md#architecture-diagram)
- [FormFields Validation Flow](../../ARCHITECTURE.md#formfields-validation-flow)

For full property details, see [API.md](../../API.md).
