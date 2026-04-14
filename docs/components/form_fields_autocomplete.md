# FormFieldsAutocomplete

Async autocomplete widget with API querying, custom parsing, and custom option rendering.

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

For complete parameters, see [API.md](../../API.md).
