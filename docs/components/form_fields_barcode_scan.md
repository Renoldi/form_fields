# FormFieldsBarcodeScan

A reusable barcode/QR code scanner form field for Flutter, built with mobile_scanner and designed to match the FormFields API and style.

## Features

- Launches a camera overlay for barcode/QR scanning
- Professional overlay border for scan area
- Returns scanned value to the form field
- Supports validation, label positioning, and custom decoration
- Integrates with Provider, GoRouter, and modular architecture

## Example Usage

```dart
FormFieldsBarcodeScan(
  label: 'Scan Barcode',
  currentValue: viewModel.barcode,
  isRequired: true,
  onChanged: (value) {
    viewModel.setBarcode(value);
  },
)
```

## Overlay & UX

- Overlay border is always centered, non-blocking, and styled for best scan UX
- Uses IgnorePointer so scan area is not blocked
- Cancel button to close scanner

## Integration

- Example page: `example/lib/ui/pages/form_fields_barcode_scan/`
- Route: `AppRoute.barcodeScan`
- Menu: Barcode Scan

## Requirements

- Add `mobile_scanner` to your pubspec.yaml

```yaml
dependencies:
  mobile_scanner: any
```

## See Also

- [mobile_scanner](https://pub.dev/packages/mobile_scanner)
- [FormFields](form_fields.md)
