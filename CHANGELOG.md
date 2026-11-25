# Changelog

All notable changes to the FormFields package will be documented in this file.

## [Unreleased]

### Added

- OTP/verification field with countdown timer, resend UI, and flexible label positioning
- `OtpBorderType` (box/underline) for OTP digit boxes
- Multi-language/localization for all OTP/verification UI and validation
- Professional UX: validation above countdown, always visible timer, InputDecoration for OTP boxes
- MyImage widget: image picker/uploader dengan upload langsung, multi-image, scanner dokumen, dan callback perubahan gambar

- Upload resiliency: `DioUtil.uploadFile` adds short retry/backoff for transient DNS/connection errors and returns diagnostic responses on persistent failures.
- `UploadService.uploadDirectPayload` returns a sanitized `DirectUploadPayload` when uploads are queued due to auth expiry (401) or network failures; new callback `onUploadQueued(DirectUploadPayload payload, bool authExpired)` notifies callers when a payload is queued (authExpired=true means 401).

### Changed

- **Dampak untuk pemakai package (SignaturePad dan LiveCameraCapture):** aturan pelaporan payload antrean sekarang satu untuk semua field.
  - `onUploadQueued` dan `onFailDirectUploadPayload` pada `FormFieldsSignaturePad` dipanggil saat upload diantrekan, bukan saat export selesai. Akibatnya callback ini terpanggil sebelum `onExported`.
  - Setiap payload antrean dilaporkan tepat sekali. Sebelumnya payload dari error server dan 401 pada SignaturePad dilaporkan dua kali, sekali saat upload dan sekali lagi saat export.
  - Payload dari `FormFieldsLiveCameraCapture` yang tertanam di SignaturePad diteruskan satu per satu. Tidak lagi digabung menjadi satu daftar saat export. Pemakai yang mengandalkan daftar gabungan perlu menyesuaikan.
  - `FormFieldsLiveCameraCapture` saat offline sekarang juga memanggil `onUploadQueued`. Sebelumnya hanya `onFailDirectUploadPayload`.
  - `FormFieldsLiveCameraCapture` saat 401 yang diantrekan sekarang menampilkan dialog gagal, sama seperti SignaturePad.
  - `FormFieldsLiveCameraCapture` saat error server yang bisa di-retry sekarang mengembalikan gambar berstatus `queued`, bukan `null`.
  - `onFailDirectUploadList` tidak berubah. Tetap berisi ringkasan hasil export.
  - Tidak ada perubahan pada nama atau signature callback publik. Pemakai tidak perlu mengubah kode pemanggilan, tetapi perlu memastikan logika mereka tidak bergantung pada urutan atau jumlah pemanggilan lama.

### Fixed

- `ResponsiveMenuGrid` rows are now `height` (item height) plus `verticalSpacing` apart. Before, the row height followed the column width, so rows were taller than the items wherever a column was wider than an item. A 5-item grid at 411 px had rows 128 px apart instead of 108 px, with extra empty space below each row.
  - **Dampak untuk pemakai package:** rows in grids with wide columns are shorter. A 3-column grid with 100 px items at phone width now has rows 108 px apart (was 118 px). Column layout and horizontal spacing are unchanged. No public parameter changed.
- `ResponsiveMenuGrid` no longer spreads its spacing across columns that stay empty. With 5 items at 800 px and 1200 px the gap is now 25 px (it was about 17 px and 10 px), and the items stay in one row.
  - **Dampak untuk pemakai package:** a grid with fewer items than columns that fit now uses only as many columns as there are items, and is sized to that content. Two items at 380 px are 25 px apart (was 35 px), and a single item or a 2-item grid is 100 px tall (was 110 px). Items remain left-aligned when `alignLeft` is true. No public parameter changed.
- Queued upload payloads no longer keep an `Authorization` header in any letter case. The previous check was case-sensitive, so a token passed as `Authorization` was written to the offline queue.
- `UploadHelper.uploadPersistedPayload` accepts `uploadTokenRefresher`. Retries from the offline queue now send a fresh token instead of going out without credentials. Stored headers that still hold an old token have it removed.
- `distanceToSegmentMeters` measures segments that cross the antimeridian the short way.
- `isNumeric` rejects `NaN` and infinite values.
- `isValidPhone` ignores surrounding whitespace, as `isValidEmail` already does.

### Documentation

- Moved the root-level guides (`API`, `USAGE`, `QUICKSTART`, `LOCALIZATION`, `ARCHITECTURE`, `PROJECT_STRUCTURE`, `CROSS_PLATFORM_SETUP`, `API_KEYS_SECURITY`) into `docs/guides/`. Links are updated.
- Updated all markdown docs for OTP/verification field, resend UI, OtpBorderType, and localization
- Synced API docs with feedback exports (`AppDialogService`, `AppGlobalDialogService`, `AppLoadingIndicator`, `AppProgressIndicator`)
- Added usage guide section for feedback/dialog patterns and loading visual options
- Updated architecture and project-structure docs for `lib/src/feedback`, including `app_dialog_service_types.dart` and `app_global_dialog_service.dart`
- Refreshed example app README to include button and dialog/loading demonstration coverage
- Added documentation for MyImage widget (README, API, USAGE)

## [1.0.0] - 2026-02-24

### Added

- Initial release of FormFields package
- Core `FormFields<T>` widget with generic type support
- Multiple form field types:
  - Text (FormType.string)
  - Email (FormType.email)
  - Phone (FormType.phone)
  - Password (FormType.password)
  - Date (FormType.date)
  - Time (FormType.time) - supports both DateTime and TimeOfDay types
  - DateTime (FormType.dateTime)
  - Integer and Double numeric fields
  - Date range picker
  - Multiline text areas

- Label positioning options:
  - Top (LabelPosition.top)
  - Bottom (LabelPosition.bottom)
  - Left (LabelPosition.left)
  - Right (LabelPosition.right)
  - Inline/Floating (LabelPosition.inBorder)
  - Hidden (LabelPosition.none)

- Border style options:
  - Outline (BorderType.outlineInputBorder)
  - Underline (BorderType.underlineInputBorder)
  - None (BorderType.none)

- Built-in validators:
  - Required field validation
  - Email format validation
  - Phone format validation
  - Password strength validation
  - Numeric validation
  - Min/max length validation
  - Range validation
  - Pattern matching validation
  - Field matching/confirmation validation
  - Composable validator support

- String extensions:
  - Email validation (isValidEmail)
  - Phone validation (isValidPhone)
  - Password validation (isValidPassword)
  - Whitespace checking (isWhiteSpace)
  - Numeric validation (isValidNumber)

- DateTime extensions:
  - Date comparison helpers
  - Flexible date formatting
  - TimeOfDay conversion (toTimeOfDay)

- TimeOfDay extensions:
  - DateTime conversion (toDateTime)
  - DateTime conversion with specific date (toDateTimeWithDate)

- State management:
  - FormFieldsController for field state
  - Provider-based reactive updates
  - Debounced input handling (500ms)

- Customization features:
  - Custom validators
  - Custom input decoration
  - Custom date/time formats
  - Prefix and suffix widgets
  - Custom border radius
  - Focus node support for keyboard navigation
  - Locale support for date/time pickers (string format: 'en_US', 'id_ID', etc.)
  - Custom error messages (enterText, invalidIntegerText, invalidNumberText)
  - Custom date range (firstDate, lastDate) for date pickers

- Number formatting:
  - Automatic thousands separator formatting
  - Configurable with stripSeparators parameter
  - Support for both integer and decimal numbers

- User experience featuret
  - DateTimeRange support
  - TimeOfDay support for time-only valuespe selection
  - Validation feedback
  - Clear/reset button for fields
  - Multiline text suppor
  - TimeOfDay support for time-only valuest
  - DateTimeRange support

- Documentation:
  - Comprehensive README
  - Detailed usage manual
  - Complete example application
  - API documentation

### Features

- **Type Safety**: Generic type system for compile-time type checking
- **Flexible Validation**: Built-in and custom validator support
- **Beautiful UI**: Material Design inspired with full customization
- **Developer Friendly**: Clear API and excellent documentation
- **Production Ready**: Tested and reliable for use in production apps

### Package Dependencies

- flutter: >=3.0.0
- provider: ^6.0.0
- intl: ^0.19.0

### Known Limitations

- Phone validation supports Indonesian format primarily
- Date pickers limited to past dates by default
- Locale support depends on intl package

---

## Upcoming Features (Future Releases)

- [ ] More locale support for phone validation
- [ ] Multi-select fields
- [ ] Autocomplete/suggestion fields
- [ ] Search/filtering fields
- [ ] Custom keyboard support
- [ ] Tablet layout optimization
- [ ] Accessibility improvements
