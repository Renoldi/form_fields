# FormFieldsDropdown

Single-select dropdown field with customizable labels, validation, and style.

## Basic Usage

```dart
FormFieldsDropdown<String>(
  label: 'Country',
  currentValue: selected,
  items: const ['ID', 'US', 'JP'],
  onChanged: (value) => selected = value,
)
```

## Key Options

- `items`, `currentValue`, `onChanged`
- `isRequired`, `validator`
- `labelPosition`, `borderType`
- item and border styling parameters

See [API.md](../../API.md) for full details.
