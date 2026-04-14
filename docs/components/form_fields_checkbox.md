# FormFieldsCheckbox

Checkbox group field supporting single/multiple selection with vertical or horizontal layouts.

## Basic Usage

```dart
FormFieldsCheckbox<String>(
  label: 'Hobbies',
  initialValue: selected,
  items: const ['Reading', 'Traveling', 'Music'],
  onChanged: (values) => selected = values,
)
```

## Key Options

- `items`, `initialValue`, `onChanged`
- `isRequired`, `validator`
- direction, side-by-side behavior, indicator alignment
- border, item padding, and active color customization

See [API.md](../../API.md) for complete parameter details.
