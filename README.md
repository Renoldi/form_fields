# Form Fields Flutter Package

A reusable Flutter package for building form UIs with consistent behavior, validation, localization, Material 3-friendly components, and advanced OTP/verification field support.

## Quick Start

Add dependency:

```yaml
dependencies:
  form_fields: ^latest
```

Import package:

```dart
import 'package:form_fields/form_fields.dart';
```

Basic example:

```dart
FormFields<String>(
  label: 'Username',
  currentValue: '',
  onChanged: (value) {},
)
```

## OTP & Verification Field Highlights

- **OTP Field with Countdown & Resend:**
  - Built-in countdown timer with "resend" UI and callback.
  - Professional UX: validation above countdown, always visible timer ("00:00:00" format).
  - Flexible OTP digit count, alphanumeric support, and hidden/obscured mode.
  - Automatic resend button and callback (`onOtpCountdownReload`).
- **Customizable OTP Box Style:**
  - `otpBorderType`: Choose between `OtpBorderType.box` or `OtpBorderType.underline` for OTP digit boxes.
  - Full control over box width, spacing, text style, and InputDecoration.
- **Flexible Label Positioning:**
  - Place labels above, below, left, right, inline, or hidden using `labelPosition`.
- **Multi-Language & Localization:**
  - All validation and UI text is fully localized (English, Indonesian, and easy extension).
  - See [LOCALIZATION.md](LOCALIZATION.md) for details.

## Component Documentation

All public widgets, controllers, and utilities are accessible via a single import:

```dart
import 'package:form_fields/form_fields.dart';
```

Each component has its own documentation file for clarity and maintainability:

- [AppButton](docs/components/app_button.md)
- [AppButtonGroup](docs/components/app_button_group.md)
- [AppSegmentedButton](docs/components/app_segmented_button.md)
- [AppSplitButton](docs/components/app_split_button.md)
- [AppFabMenu](docs/components/app_fab_menu.md)
- [AppDialogService](docs/components/app_dialog_service.md)
- [AppModalBottomSheet](docs/components/app_modal_bottom_sheet.md)
- [Loading & Progress](docs/components/loading_progress.md)
- [FormFields](docs/components/form_fields.md)
- [FormFieldsAutocomplete](docs/components/form_fields_autocomplete.md)
- [FormFieldsDropdown](docs/components/form_fields_dropdown.md)
- [FormFieldsDropdownMulti](docs/components/form_fields_dropdown_multi.md)
- [FormFieldsRadioButton](docs/components/form_fields_radio_button.md)
- [FormFieldsCheckbox](docs/components/form_fields_checkbox.md)
- [FormFieldsSelect](docs/components/form_fields_select.md)
- [FormFieldsSignaturePad](docs/components/form_fields_signature_pad.md)
- [FormFieldsMyImage](docs/components/form_fields_my_image.md)
- [FormFieldsBarcodeScan](docs/components/form_fields_barcode_scan.md)

## Barcode/QR Code Scanner Field

**FormFieldsBarcodeScan** is a reusable barcode/QR code scanner form field widget for Flutter, using mobile_scanner. It provides a professional overlay border, seamless integration with forms, and a consistent API with other FormFields components.

### Example

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

See [FormFieldsBarcodeScan documentation](docs/components/form_fields_barcode_scan.md) for details and advanced usage.

See the [Documentation Index](docs/README.md) for a full list.

Architecture shortcuts:

- [Architecture Diagram](ARCHITECTURE.md#architecture-diagram)
- [FormFields Validation Flow](ARCHITECTURE.md#formfields-validation-flow)
- [AppButton Family Diagram](ARCHITECTURE.md#appbutton-family-diagram)

---

**Segmented button icon behavior note:**

- `ButtonSegment.icon` can be hardcoded per segment. See [AppSegmentedButton docs](docs/components/app_segmented_button.md) for best practices with `selectedIcon`.

AppButton generic callback note:

- `AppButton<T>` supports typed payload callbacks via `value` + `onPressedWithValue`. See [AppButton docs](docs/components/app_button.md).
- Includes examples for all `AppButtonType` with generic `T` in [AppButton docs](docs/components/app_button.md#all-button-types-with-generic-t).

### AppButton<T> Quick Example

```dart
class LoginAction {
  final String source;
  final bool rememberMe;

  const LoginAction({required this.source, required this.rememberMe});
}

AppButton<LoginAction>(
  text: 'Sign in',
  value: const LoginAction(source: 'email', rememberMe: true),
  onPressedWithValue: (payload) {
    if (payload == null) return;
    login(source: payload.source, rememberMe: payload.rememberMe);
  },
)
```

## Additional References

- [API Reference](API.md)
- [Usage Guide](USAGE.md)
- [Localization Guide](LOCALIZATION.md)
- [Quickstart](QUICKSTART.md)
- [Architecture](ARCHITECTURE.md)
- [Project Structure](PROJECT_STRUCTURE.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

## MyImage Widget (Image Picker & Uploader)

`MyImage` adalah widget untuk memilih, menampilkan, dan mengunggah gambar (atau dokumen) dengan dukungan multi-image, upload langsung, serta callback perubahan gambar. Mendukung integrasi dengan kamera, galeri, dan scanner dokumen.

### Fitur Utama

- Pilihan single/multi image
- Upload langsung ke server (opsional)
- Callback perubahan gambar dan penghapusan
- Kustomisasi builder untuk tampilan gambar dan tombol tambah/hapus
- Dukungan scanner dokumen (Cunning Document Scanner)
- Dukungan upload dengan token dan pesan sukses/gagal kustom

### Contoh Penggunaan Dasar

```dart
MyImage(
  label: 'Foto Profil',
  maxImages: 1,
  onImageChanged: (image) {
    // Handle image result
  },
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',
  isDirectUpload: true,
)
```

Lihat dokumentasi API untuk detail properti dan contoh lanjutan.

## Backend Validation Error Mapping (externalErrorText)

### Fitur Baru: Error Validasi Backend Langsung ke Form Field

Mulai versi 2026-04, semua field utama (FormFields, Dropdown, Checkbox, dsb) mendukung parameter `externalErrorText` untuk menampilkan error validasi dari backend secara langsung di bawah field.

### Cara Pakai (Contoh dengan AppDialogService.guard)

1. **Lempar error validasi dari backend:**
   ```dart
   throw ValidationException(
     'Validasi gagal',
     details: {
       'email': ['Email tidak valid'],
       'password': ['Password minimal 8 karakter']
     },
   );
   ```
2. **Tangkap dan mapping error di UI/ViewModel:**
   ```dart
   await AppDialogService(context).guard(
     task: () async {
       // ...proses
     },
     errorTitle: 'Error',
     mapError: AppDialogService.defaultErrorMapper,
     onValidationError: (errors) {
       // errors: Map<String, List<String>>
       vm.setFieldErrors(errors); // mapping ke state
     },
   );
   ```
3. **Tampilkan error di FormFields:**
   ```dart
   FormFields(
     label: 'Email',
     currentValue: vm.email,
     onChanged: vm.setEmail,
     externalErrorText: vm.fieldErrors['email']?.join(', '),
   )
   ```

### Catatan

- Pastikan ViewModel/state punya Map<String, List<String>> fieldErrors.
- Panggil notifyListeners/setState setelah update agar UI refresh.
- externalErrorText akan override error validator lokal jika diisi.

Lihat juga contoh implementasi di folder `example/` dan dokumentasi masing-masing field di `docs/components/`.

## Testing

This package uses a lightweight baseline test to keep feedback fast during development.

Run only the fast feedback tests:

```bash
flutter test test/feedback/app_dialog_service_fast_test.dart
```

Run all tests in the package:

```bash
flutter test
```

Tips for faster local iteration:

- Prefer unit tests for core logic and mapping behavior.
- Avoid heavy widget test flows unless UI interaction coverage is required.
- Use plain-name filtering for focused runs:

```bash
flutter test --plain-name "fast unit"
```

## License

This project is licensed under the [LICENSE](LICENSE).

## Catatan Versioning Android

- **versionName** biasanya mengikuti format MAJOR.MINOR.PATCH (misal: 2.5.13)
  - Angka pertama (MAJOR): perubahan besar/breaking changes
  - Angka kedua (MINOR): penambahan fitur kompatibel
  - Angka ketiga (PATCH): perbaikan bug/kecil
- **versionCode** adalah integer terpisah, wajib naik setiap rilis
- versionName hanya label untuk user, tidak mempengaruhi update logic Android
- Untuk membedakan dev, beta, atau prod pada versionName, tambahkan label di belakang angka versi.
  - Contoh:
    - 1.2.3-dev (versi development)
    - 1.2.3-beta (versi beta/testing)
    - 1.2.3 (versi production/stabil)
- Penamaan ini membantu user dan tim dev mengetahui status rilis aplikasi hanya dari versionName.
