# FormFieldsSignaturePad

Signature pad widget for capturing user signatures as images, with export to PNG and integration with MyimageResult for upload or further processing.

## Basic Usage

```dart
FormFieldsSignaturePad(
  height: 200,
  width: double.infinity,
  penColor: Colors.black,
  backgroundColor: Colors.white,
  penStrokeWidth: 3.0,
  onExported: (result) {
    // result is a MyimageResult? containing the PNG signature
  },
)
```

## Key Options

- `height`, `width`: Size of the signature area
- `penColor`, `backgroundColor`, `penStrokeWidth`: Drawing style
- `onExported`: Callback with exported signature as MyimageResult
- `exportBackgroundColor`: Optional override for PNG background

## Integration

- Uses the [signature](https://pub.dev/packages/signature) package for drawing.
- Exports signature as PNG and wraps it in a MyimageResult for easy upload or preview.

See [API.md](../../API.md) for full parameter details.
