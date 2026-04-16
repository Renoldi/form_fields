# FormFieldsAutocomplete

Async autocomplete widget with API querying, custom parsing, custom option rendering, and full localization support.

## Basic Usage

```dart
FormFieldsAutocomplete<String>(
  fieldLabel: 'City',
  apiUrl: 'https://api.example.com/cities',
  onItemSelected: (city) {},
)
```

## Key Options

- `apiUrl`, `apiToken`, `searchKey`, `tokenHeaderName`
- `parseResults`
- `itemSelectedBuilder`, `itemBuilder`
- `inputDecoration`, `labelPlacement`, `borderStyle`
- **Localization:** All UI and error text is localized (see [LOCALIZATION.md](../../LOCALIZATION.md)).

For complete parameters, see [API.md](../../API.md).
