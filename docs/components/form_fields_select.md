# FormFieldsSelect

Generic selectable list field for strongly typed models with custom item text rendering.

## Basic Usage

```dart
FormFieldsSelect<Country>(
  label: 'Country',
  currentValue: selectedCountry,
  items: countries,
  itemBuilder: (country) => country.name,
  onChanged: (value) => selectedCountry = value,
)
```

## Key Options

- `items`, `currentValue`, `onChanged`
- `itemBuilder` or equivalent text builder
- `isRequired`, `validator`
- label and border customization

See [API.md](../../API.md) for complete API details.
