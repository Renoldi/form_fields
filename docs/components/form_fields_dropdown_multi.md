# FormFieldsDropdownMulti

Multi-select dropdown field for selecting multiple values with validation and custom rendering.

## Basic Usage

```dart
FormFieldsDropdownMulti<String>(
  label: 'Skills',
  currentValue: selectedValues,
  items: const ['Dart', 'Flutter', 'Firebase'],
  onChanged: (values) => selectedValues = values,
)
```

## Key Options

- `items`, `currentValue`, `onChanged`
- `isRequired`, `validator`
- style and layout controls

See [API.md](../../API.md) for complete parameters.
