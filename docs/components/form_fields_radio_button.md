# FormFieldsRadioButton

Single-choice radio field with flexible layout, validation, and styling.

## Basic Usage

```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  currentValue: selected,
  items: const ['Male', 'Female'],
  onChanged: (value) => selected = value,
)
```

## Key Options

- `items`, `currentValue`, `onChanged`
- `isRequired`, `validator`
- direction, spacing, and indicator alignment
- border and active color customization

See [API.md](../../API.md) for full parameter details.
