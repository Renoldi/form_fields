# form_fields

A professional Flutter package for building form UIs with consistent behavior, Material 3 design, localization, validation, image management, signature capture, and live camera integration.

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Components](#components)
- [FormFieldsSignaturePad](#formfieldssignaturepad)
- [FormFieldsLiveCameraCapture](#formfieldslivecameracapture)
- [FormFieldsMyImage](#formfieldsmyimage)
- [Controllers](#controllers)
- [Validation & External Errors](#validation--external-errors)
- [Localization](#localization)
- [Testing](#testing)
- [Additional References](#additional-references)

---

## Installation

```yaml
dependencies:
  form_fields:
    git:
      url: https://github.com/your-org/form_fields_package.git
```

```dart
import 'package:form_fields/form_fields.dart';
```

---

## Quick Start

```dart
FormFields<String>(
  label: 'Username',
  currentValue: '',
  onChanged: (value) {},
)
```

---

## Exporting and Importing Database

The package exposes helpers to export the on-disk SQLite database to a SQL
file and to import SQL files. These are useful for backups, debugging, or
transferring data between devices.

Usage examples:

- Export current/default DB to a file (inlines payload files as JSON by default):

```dart
await DBService.instance.init(dbName: 'form_fields.db');
await DBService.instance.exportToSqlFile('/path/to/out.sql');
```

- Export a different DB file without changing the initialized default:

```dart
await DBService.instance.exportToSqlFile('/path/to/other.sql', dbName: 'other.db');
```

- Control whether payload files are inlined (set `inlinePayloads: false` to keep filenames):

```dart
await DBService.instance.exportToSqlFile('/path/to/out.sql', inlinePayloads: false);
```

- Import an SQL file into the current DB (optionally convert inline JSON into payload files):

```dart
await DBService.instance.importFromSqlFile('/path/to/out.sql');
```

Notes:

- `init(dbName: ...)` sets the runtime default DB name used when other
  APIs are called without an explicit `dbName` (or passed `null`/empty).
- `exportToSqlFile` will open a transient connection when a different
  `dbName` is supplied and close it after exporting.

---

## Components

All components are accessible from a single import. Detailed docs are in [`docs/components/`](docs/components/).

| Component                                                                           | Description                             |
| ----------------------------------------------------------------------------------- | --------------------------------------- |
| [`FormFields`](docs/components/form_fields.md)                                      | Universal text/OTP/barcode form field   |
| [`FormFieldsAutocomplete`](docs/components/form_fields_autocomplete.md)             | Autocomplete field                      |
| [`FormFieldsDropdown`](docs/components/form_fields_dropdown.md)                     | Single-select dropdown                  |
| [`FormFieldsDropdownMulti`](docs/components/form_fields_dropdown_multi.md)          | Multi-select dropdown                   |
| [`FormFieldsRadioButton`](docs/components/form_fields_radio_button.md)              | Radio button group                      |
| [`FormFieldsCheckbox`](docs/components/form_fields_checkbox.md)                     | Checkbox field                          |
| [`FormFieldsSelect`](docs/components/form_fields_select.md)                         | Bottom-sheet select                     |
| [`FormFieldsSignaturePad`](docs/components/form_fields_signature_pad.md)            | Signature pad with optional live camera |
| [`FormFieldsMyImage`](docs/components/form_fields_my_image.md)                      | Image picker and uploader               |
| [`FormFieldsLiveCameraCapture`](docs/components/form_fields_live_camera_capture.md) | Standalone front-camera capture         |
| [`AppButton`](docs/components/app_button.md)                                        | Material 3 button with typed payload    |
| [`AppButtonGroup`](docs/components/app_button_group.md)                             | Button group                            |
| [`AppSegmentedButton`](docs/components/app_segmented_button.md)                     | Segmented button                        |
| [`AppSplitButton`](docs/components/app_split_button.md)                             | Split button                            |
| [`AppFabMenu`](docs/components/app_fab_menu.md)                                     | FAB speed-dial menu                     |
| [`AppDialogService`](docs/components/app_dialog_service.md)                         | Dialog, guard, and error mapping        |
| [`AppModalBottomSheet`](docs/components/app_modal_bottom_sheet.md)                  | Reusable bottom sheet                   |
| [`LoadingProgress`](docs/components/loading_progress.md)                            | Loading / progress indicators           |

---

## FormFieldsSignaturePad

A signature-drawing pad with optional live front-camera capture, in-pad preview, direct upload, controller-based prefill, and validation support.

### Basic Usage

```dart
FormFieldsSignaturePad(
  backgroundColor: Colors.white,
  onExported: (MyimageResult? result) {
    // result contains path, base64, link, imageId
  },
)
```

### With Export Preview

Replace the drawing area with the exported image after confirmation:

```dart
FormFieldsSignaturePad(
  showExportPreview: true,
  exportPreviewSource: SignaturePadPreviewSource.signature,
  onExported: (result) { },
)
```

### With Live Camera

Auto-captures a selfie on the first draw stroke. The signature and selfie are delivered together in `onExportedResult`:

```dart
FormFieldsSignaturePad(
  showLiveCamera: true,
  showExportPreview: true,
  exportPreviewSource: SignaturePadPreviewSource.both,
  onExportedResult: (SignaturePadExportResult result) {
    result.signature;    // MyimageResult — signature drawing
    result.liveCapture;  // MyimageResult? — auto-captured selfie
  },
)
```

### With Direct Upload

Auto-uploads signature (and selfie) after export. Callbacks receive server `link` and `imageId`:

```dart
FormFieldsSignaturePad(
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',   // optional
  showUploadLoading: true,
  showUploadResultDialog: true,
  showLiveCamera: true,
  showExportPreview: true,
  exportPreviewSource: SignaturePadPreviewSource.both,
  onExportedResult: (result) {
    result.signature.link;    // uploaded signature URL
    result.liveCapture?.link; // uploaded selfie URL
  },
)
```

Note on resiliency and queuing:

- The uploader includes short retry/backoff for transient DNS/connection errors. If a payload cannot be uploaded because of network issues or `401` auth failures, the library will produce a sanitized `DirectUploadPayload` (with `Authorization` removed) and queue it for retry. Use `onFailDirectUploadPayload` to persist payloads.
- New callback `onUploadQueued(DirectUploadPayload payload, bool authExpired)` is invoked when the library queues a payload; `authExpired == true` indicates the queueing was due to an authentication failure (401).

### Prefilled Signature (Controller)

Seed the pad with an existing signature on first render using `FormFieldsSignaturePadController`:

```dart
// Signature only
final ctrl = FormFieldsSignaturePadController.fromSignature(
  MyimageResult.network('https://example.com/existing-signature.png'),
);

// Signature + live capture
final ctrl = FormFieldsSignaturePadController.fromExportResult(
  SignaturePadExportResult(
    signature: MyimageResult.network('https://example.com/sig.png'),
    liveCapture: MyimageResult.network('https://example.com/selfie.jpg'),
  ),
);

FormFieldsSignaturePad(
  signaturePadController: ctrl,
  showLiveCamera: true,
  showExportPreview: true,
  exportPreviewSource: SignaturePadPreviewSource.both,
  onExportedResult: (result) { },
)
```

The pad starts directly in preview mode. When the user clears and re-signs, the controller is updated automatically. Use `ctrl.clearWidget()` to reset programmatically.

### Validation

```dart
FormFieldsSignaturePad(
  label: 'Customer Signature',
  labelPosition: LabelPosition.top,
  isRequired: true,
  autovalidateMode: AutovalidateMode.onUserInteraction,
  onExported: (result) { },
)
```

### Custom Layout

```dart
FormFieldsSignaturePad(
  showLiveCamera: true,
  layoutBuilder: (ctx, signaturePad, cameraWidget) {
    return Row(
      children: [
        Expanded(child: signaturePad),
        if (cameraWidget != null) ...[
          const SizedBox(width: 12),
          Expanded(child: cameraWidget),
        ],
      ],
    );
  },
)
```

### API Reference

| Parameter                | Type                                       | Default      | Description                                            |
| ------------------------ | ------------------------------------------ | ------------ | ------------------------------------------------------ |
| `height`                 | `double`                                   | `200`        | Signature pad height                                   |
| `width`                  | `double`                                   | `∞`          | Signature pad width                                    |
| `backgroundColor`        | `Color`                                    | `white`      | Pad background                                         |
| `penColor`               | `Color`                                    | `black`      | Pen color                                              |
| `penStrokeWidth`         | `double`                                   | `3.0`        | Pen thickness                                          |
| `exportBackgroundColor`  | `Color?`                                   | `null`       | Export PNG background (`null` = transparent)           |
| `onExported`             | `void Function(MyimageResult?)?`           | —            | Callback with signature only                           |
| `onExportedResult`       | `void Function(SignaturePadExportResult)?` | —            | Callback with signature + live capture                 |
| `onLiveCaptured`         | `void Function(MyimageResult)?`            | —            | Fired immediately after auto-capture                   |
| `showExportPreview`      | `bool`                                     | `false`      | Replace pad with exported image preview                |
| `exportPreviewSource`    | `SignaturePadPreviewSource`                | `.signature` | Which image to show in preview                         |
| `showLiveCamera`         | `bool`                                     | `false`      | Show front-camera live preview                         |
| `liveCameraHeight`       | `double`                                   | `200`        | Camera widget height                                   |
| `liveCameraController`   | `FormFieldsMyImageController?`             | —            | External controller for live capture                   |
| `signaturePadController` | `FormFieldsSignaturePadController?`        | —            | Controller for prefill and programmatic clear          |
| `layoutBuilder`          | `Widget Function(ctx, pad, camera?)?`      | —            | Fully custom layout                                    |
| `liveCameraBuilder`      | `Widget Function(ctx, camera)?`            | —            | Custom camera section wrapper                          |
| `isDirectUpload`         | `bool`                                     | `false`      | Auto-upload after export                               |
| `uploadUrl`              | `String?`                                  | —            | Upload endpoint (required when `isDirectUpload: true`) |
| `uploadToken`            | `String?`                                  | —            | Bearer token for `Authorization` header                |
| `showUploadResultDialog` | `bool`                                     | `false`      | Show success/error dialog                              |
| `showUploadLoading`      | `bool`                                     | `true`       | Loading overlay during upload                          |

# `uploadFileUrlKey` and `uploadImageIdKey` have been removed; the mapper now auto-detects common response keys.

| `label` | `String?` | — | Label text |
| `labelPosition` | `LabelPosition` | `.none` | Label placement |
| `isRequired` | `bool` | `false` | Signature is required for form validity |
| `validator` | `String? Function(bool)?` | — | Custom validator |
| `autovalidateMode` | `AutovalidateMode` | `.onUserInteraction` | When to validate |
| `externalErrorText` | `String?` | — | Backend error shown unconditionally |

---

## FormFieldsLiveCameraCapture

Standalone front-camera preview with capture and reset. Used internally by `FormFieldsSignaturePad`, but also available independently.

### Option A — GlobalKey

```dart
final cameraKey = GlobalKey<FormFieldsLiveCameraCaptureState>();

FormFieldsLiveCameraCapture(
  key: cameraKey,
  height: 200,
  onCaptured: (MyimageResult result) { },
)

// Capture
await cameraKey.currentState?.capture();

// Reset
cameraKey.currentState?.resetCapture();
```

### Option B — Controller

```dart
final controller = FormFieldsMyImageController();

FormFieldsLiveCameraCapture(
  height: 200,
  cameraController: controller,
  onCaptured: (result) { },
)

// Capture from anywhere
await controller.capture();

// Reset from anywhere
controller.resetCapture();
```

### Prefilled Image

Start in captured state with an existing image:

```dart
final controller = FormFieldsMyImageController.fromImages([
  MyimageResult.network('https://example.com/existing.jpg'),
]);

FormFieldsLiveCameraCapture(
  height: 200,
  cameraController: controller,
)
```

### Permissions

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to capture a photo during signing.</string>
```

---

## FormFieldsMyImage

Image picker and uploader with multi-image, direct upload, and document scanner support.

```dart
FormFieldsMyImage(
  label: 'Profile Photo',
  maxImages: 1,
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',
  onImageChanged: (MyimageResult image) { },
)
```

### Prefilled Images

```dart
final controller = FormFieldsMyImageController.fromImages([
  MyimageResult.network('https://example.com/image1.jpg'),
  MyimageResult.network('https://example.com/image2.jpg'),
]);

FormFieldsMyImage(
  controller: controller,
  onImageChanged: (image) { },
)
```

---

## Offline persistence & retry (examples)

The example app includes a simple offline-persistence + retry pattern for direct uploads. Key points:

- Persistence location: example uses files under the system temp directory:
  - `form_fields_offline_payloads_myimage.json` — persisted payloads from `FormFieldsMyImage` example pages
  - `form_fields_offline_payloads_signature_pad.json` — persisted payloads from `FormFieldsSignaturePad` example pages

- Payload shape and normalization:
  - Example code normalizes upload payloads into a canonical map with a nested `file` entry (`{ 'file': { 'path', 'base64', 'fileName' }, ... }`).
  - Each persisted payload includes an `uploadCorrelationId` so retry results can be matched back to UI controllers.
  - A `source` tag (`myimage` or `signature_pad`) is added so multiple example pages can share the same cache directory without showing mixed previews.

- Deduplication: persisted entries are deduplicated, preferring `uploadCorrelationId` equality, then falling back to `file.path` or `file.base64`.

- Retry behavior: the example's `Retry Uploads` button reads the persisted file, rebuilds upload-ready payloads (decoding `base64` to temp files when needed), calls the upload helper, and removes successful uploads from the persisted queue. Failed uploads remain for future retries.

- Clearing/migrating persisted data:
  - Remove old global file used by older examples (if present):
    ```bash
    adb shell run-as com.example.form_fields_example.debug rm /data/user/0/com.example.form_fields_example.debug/cache/form_fields_offline_payloads.json
    ```
  - New per-view files can be removed similarly, or you can rely on the example UI to retry and clear entries.

If you want me to update the documentation in `docs/components/` or add a migration script for legacy persisted files, tell me which option you prefer.

## Controllers

### FormFieldsSignaturePadController

Manages signature pad state externally and supports prefilled images.

```dart
// Empty — read result after export
final ctrl = FormFieldsSignaturePadController();

// Prefill — signature only
final ctrl = FormFieldsSignaturePadController.fromSignature(
  MyimageResult.network('https://example.com/sig.png'),
);

// Prefill — signature + live capture
final ctrl = FormFieldsSignaturePadController.fromExportResult(
  SignaturePadExportResult(
    signature: MyimageResult.network('https://example.com/sig.png'),
    liveCapture: MyimageResult.network('https://example.com/selfie.jpg'),
  ),
);
```

| Member                    | Description                                     |
| ------------------------- | ----------------------------------------------- |
| `exportResult`            | Current `SignaturePadExportResult?`             |
| `signature`               | Shortcut for `exportResult?.signature`          |
| `liveCapture`             | Shortcut for `exportResult?.liveCapture`        |
| `setExportResult(result)` | Update result programmatically                  |
| `setSignature(image)`     | Update only the signature image                 |
| `clear()`                 | Clear result (controller state only)            |
| `clearWidget()`           | Clear pad + camera (resets the attached widget) |

### FormFieldsMyImageController

Manages image list and programmatic camera/picker actions.

```dart
// Empty
final ctrl = FormFieldsMyImageController();

// Prefilled
final ctrl = FormFieldsMyImageController.fromImages([
  MyimageResult.network('https://example.com/photo.jpg'),
]);
```

| Member                | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `images`              | `List<MyimageResult>` (unmodifiable)                      |
| `setImages(images)`   | Replace all images                                        |
| `addImage(image)`     | Append one image                                          |
| `clear()`             | Clear all images                                          |
| `capture()`           | Trigger capture on attached `FormFieldsLiveCameraCapture` |
| `resetCapture()`      | Reset attached camera widget to live preview              |
| `pickImage({source})` | Open picker on attached `FormFieldsMyImage`               |

### MyimageResult

```dart
// From file
final result = await MyimageResult.fromFile(file);

// From network URL (prefill use case)
final result = MyimageResult.network('https://example.com/image.jpg');

// Manual
final result = MyimageResult(
  link: 'https://example.com/image.jpg',
  base64: 'data:image/png;base64,...',
  path: '/tmp/image.png',
  imageId: 'server-id-123',
);
```

---

## Validation & External Errors

**Database Usage (Debug vs Release)**

- **Overview:**: `DBService` menyediakan helper tingkat-tinggi untuk membuka, memigrasi, membaca, dan menulis database SQLite. Gunakan `DBService` agar lifecycle hooks dan `ColumnHandler` (mis. `FileBackedColumnHandler`) dijalankan otomatis saat `insert`, `update`, atau `delete`.
- **File locations:**: Database file default berada di lokasi yang dikembalikan oleh `getApplicationDocumentsDirectory()`.
  - Android (device/emulator): `/data/data/<package>/files/form_fields.db` (akses via `adb shell run-as <package> ...` untuk build debug). Contoh:

```bash
adb shell run-as com.example.form_fields_example.debug ls -l /data/data/com.example.form_fields_example.debug/files
adb shell run-as com.example.form_fields_example.debug cat /data/data/com.example.form_fields_example.debug/files/form_fields.db
```

- iOS Simulator / macOS: dokumen app di folder simulator; buka melalui Finder atau gunakan `sqlite3` di terminal ke path `Documents/form_fields.db`.

- **Debug vs Release differences:**: Pada build debug biasanya package id berakhiran `.debug` (example app). Path file dan izin ADB berbeda untuk release. Selain itu, debug builds menjalankan aplikasi dalam mode observability sehingga log console (print, logger) akan terlihat di IDE — gunakan ini untuk memverifikasi operasi DB dan handler.

- **Use `DBService` helpers (recommended):**: Untuk memastikan `ColumnHandler.onWrite` dan `onDelete` dieksekusi (contoh: penulisan/ penghapusan file JSON payload), jangan jalankan SQL mentah `rawInsert` / `rawUpdate` / `rawDelete` langsung. Gunakan API berikut:
  - `await DBService.instance.insert(table, values);` — akan menjalankan handler `onWrite` untuk kolom seperti `payload`.
  - `await DBService.instance.update(table, values, where, whereArgs);`
  - `await DBService.instance.delete(table, where, whereArgs);` — akan memanggil `onDelete` pada `ColumnHandler` sehingga file payload (.json) dihapus.
  - `await DBService.instance.executeSql(sql);` — mengeksekusi SQL mentah; catatan: `INSERT` via `executeSql` TIDAK akan memicu `onWrite`.

- **Contoh: insert yang memicu handler (gunakan `insert`):**

```dart
final values = {
  'assetId': '97502c88-9703-4712-a957-1d0985b3db65-3',
  'payload': '{"assetId":"97502c88...","assetName":"laptop-3"}',
  'updated_at': 1781586828002,
};
await DBService.instance.insert('asset', values);
```

- **Contoh: hapus baris dan pastikan file payload ikut terhapus:**

```dart
await DBService.instance.delete('asset', 'rowid = ?', [rowid]);
```

- **Mengeksekusi file SQL (sample inserts / migrations):**: contoh asset [example/migrations/sample_inserts.sql](example/migrations/sample_inserts.sql) bisa diimpor melalui UI (Import sample asset) atau dengan API `DBService.importFromSqlFile(path)`.

- **Melihat/membuka DB dari shell (Android debug):**

```bash
adb shell run-as com.example.form_fields_example.debug
cd files
sqlite3 form_fields.db
sqlite> .tables
sqlite> SELECT name FROM sqlite_master WHERE type='table';
```

- **Set PRAGMA user_version / migrasi:**: gunakan `DBService.setUserVersion(int)` untuk men-set PRAGMA langsung, atau `DBService.migrateTo(targetVersion, migrationAssetPaths: [...])` untuk menjalankan asset migration yang dikemas di `example/migrations/`.

- **Export / Import SQL:**: gunakan UI `Export to folder` atau `Import from file` pada viewer SQL di aplikasi contoh. Programatik gunakan `DBService.exportToSqlFile(destPath)` dan `DBService.importFromSqlFile(path)`.

- **Debugging tips:**
  - Jalankan app dengan `flutter run` atau dari IDE (debug) untuk melihat log.
  - Jika ingin memeriksa isi payload files, periksa folder payload yang dikelola oleh `FileBackedColumnHandler` (default ada di Documents/`payloads` atau sesuai `_payloadDirName` pada `DBService`).
  - Untuk masalah permission di device fisik Android release, gunakan export via UI dan copy file dari storage eksternal.

- **Keamanan & produksi:**: pastikan payload sensitif dienkripsi atau disimpan di lokasi yang sesuai sebelum rilis. Untuk produksi, paths dan package id berbeda — perintah `adb shell run-as` mungkin tidak bekerja tanpa akses, gunakan mekanisme export di aplikasi untuk mengambil salinan DB.

All fields support `externalErrorText` to display backend validation errors directly under the field:

```dart
FormFields(
  label: 'Email',
  currentValue: viewModel.email,
  onChanged: viewModel.setEmail,
  externalErrorText: viewModel.fieldErrors['email']?.join(', '),
)
```

Typical pattern with `AppDialogService.guard`:

```dart
await AppDialogService(context).guard(
  task: () async { /* API call */ },
  onValidationError: (errors) {
    // errors: Map<String, List<String>>
    viewModel.setFieldErrors(errors);
  },
);
```

---

## Localization

Supports English and Indonesian out of the box. All UI strings (validation, camera status, upload messages) are localized.

```dart
MaterialApp(
  localizationsDelegates: [
    FormFieldsLocalizationsDelegate(),
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('id'),
  ],
)
```

See [LOCALIZATION.md](LOCALIZATION.md) for extending or overriding strings.

---

## Testing

Run the fast feedback test suite:

```bash
flutter test test/feedback/app_dialog_service_fast_test.dart
```

Run all tests:

```bash
flutter test
```

Focused run by name:

```bash
flutter test --plain-name "fast unit"
```

---

## Additional References

---

**Database Migrations**

- **Overview:**: The package ships a small migration runner that applies SQL migration assets bundled with the app and manages SQLite `user_version` (`PRAGMA user_version`). It supports:
  - applying schema-only migrations from assets,
  - programmatic upgrade/downgrade via helpers,
  - a version-less initialization mode where the package applies bundled assets and then invokes lifecycle callbacks manually.

- **Files & naming:**: Place migration SQL files under your app `assets` (for example include `migrations/` in `pubspec.yaml`). Filenames should include a version token like `v1`, `v2` (e.g. `migrations/v1.sql`, `migrations/v2.sql`). Downgrade assets may include `down` or `downgrade` in the name (e.g. `migrations/v2_down.sql`). If a file does not contain a parseable version, it will be assigned an incremental fallback version based on order.

- **How initAll works:**: Use `FormFieldsInitializer.initAll(...)` to initialize package services. Key DB-related parameters:
  - **`migrationAssetPaths`**: list of asset paths (order not important if files contain `vN`).
  - **`dbVersion`**: numeric DB version passed to `sqflite` when opening. If > 0 the package passes lifecycle callbacks (`onCreate`, `onUpgrade`, `onDowngrade`) to `openDatabase` and `sqflite` will manage migrations.
  - **`dbVersion == 0` behavior**: when `dbVersion` is 0 the package opens the DB without a numeric version (sqflite will not call `onCreate`/`onUpgrade`). In this mode the initializer will:
    - apply the listed migration assets (schema-only by default),
    - set `PRAGMA user_version` to the highest version discovered among assets,
    - optionally invoke `onUpgrade` manually for each incremental step (1..maxVer) if `invokeOnUpgradeWhenDbVersionZero: true`,
    - then invoke `onCreate(db, maxVer)` if provided.

- **Configuring manual upgrade invocation:**: `initAll` includes parameter `invokeOnUpgradeWhenDbVersionZero` (default `true`). If set to `false`, the `onUpgrade` callback will not be invoked during the manual asset application flow for `dbVersion == 0`.

- **Programmatic migration helpers:**: The package exposes convenience methods:
  - `DBService.instance.migrateTo(targetVersion, ...)` — opens/reconciles DB and migrates to `targetVersion` (runs upgrades/downgrades as needed).
  - `DBService.instance.upgradeTo(targetVersion, ...)` — shim for `migrateTo` to run upgrades.
  - `DBService.instance.downgradeTo(targetVersion, ...)` — shim for downgrades.
  - `FormFieldsInitializer.changeDbVersion(targetVersion, ...)` — higher-level wrapper you can call from your app to trigger the migration flow.

- **Callback contract:**: Provide `onConfigure`, `onCreate`, `onUpgrade`, `onDowngrade`, `onOpen` exactly as you would for `openDatabase`. When using `dbVersion == 0` and `invokeOnUpgradeWhenDbVersionZero` is true, `onUpgrade` will be invoked manually in sequence: `onUpgrade(db, 0, 1)`, `onUpgrade(db, 1, 2)`, ..., `onUpgrade(db, maxVer-1, maxVer)`.

- **Schema vs DML:**: By default the runner executes schema-related statements (`CREATE`, `ALTER`, `DROP`, `PRAGMA`) only. DML statements (INSERT/UPDATE/DELETE) are skipped unless specifically allowed by using `applyDml=true` when calling the migration APIs inside your own code.

- **Example — version-less initialization (apply bundled migrations):**

```dart
await FormFieldsInitializer.initAll(
  dbName: 'form_fields.db',
  dbVersion: 0, // openDatabase without version
  migrationAssetPaths: [
    'migrations/v1.sql',
    'migrations/v2.sql',
  ],
  // optional lifecycle callbacks
  onCreate: (db, version) async { /* app-specific setup */ },
  onUpgrade: (db, oldV, newV) async { /* incremental upgrade work */ },
  invokeOnUpgradeWhenDbVersionZero: true,
);
```

- **Example — programmatic upgrade/downgrade at runtime:**

```dart
// Upgrade to version 3 using migration assets
await FormFieldsInitializer.changeDbVersion(3,
    migrationAssetPaths: ['migrations/v1.sql','migrations/v2.sql','migrations/v3.sql']);

// Downgrade to version 1 (requires downgrade assets e.g. v2_down.sql)
await FormFieldsInitializer.changeDbVersion(1,
    migrationAssetPaths: ['migrations/v1.sql','migrations/v2.sql','migrations/v2_down.sql']);
```

---

| Document                                     | Description                |
| -------------------------------------------- | -------------------------- |
| [API.md](API.md)                             | Full API reference         |
| [USAGE.md](USAGE.md)                         | Usage patterns and recipes |
| [LOCALIZATION.md](LOCALIZATION.md)           | Localization guide         |
| [QUICKSTART.md](QUICKSTART.md)               | Quickstart guide           |
| [ARCHITECTURE.md](ARCHITECTURE.md)           | Architecture overview      |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Project structure          |
| [CONTRIBUTING.md](CONTRIBUTING.md)           | Contribution guidelines    |
| [CHANGELOG.md](CHANGELOG.md)                 | Changelog                  |

---

## License

This project is licensed under the [MIT License](LICENSE).

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

## Signature Pad + Live Camera (New)

`FormFieldsSignaturePad` now supports integrated live front-camera preview and automatic capture, and the camera module can also be used as a standalone widget.

### What is New

- Integrated live camera in `FormFieldsSignaturePad`.
- Auto-capture on first draw start (one time per signing session).
- Auto-capture reset when user taps clear.
- New combined export model: `SignaturePadExportResult`.
- New standalone camera widget: `FormFieldsLiveCameraCapture`.
- `cameraController` is now **optional** — use a `GlobalKey` or a controller, or both.
- `FormFieldsMyImageController` now supports programmatic `capture()`, `resetCapture()`, and `pickImage()` without needing a `GlobalKey`.
- Full camera status labels now localized (EN/ID).

### `FormFieldsSignaturePad` New Capabilities

- `showLiveCamera`: enable live front-camera preview.
- `liveCameraHeight`: control camera preview height.
- `liveCameraController`: external `FormFieldsMyImageController` for reading captured image.
- `onLiveCaptured`: callback fired immediately after camera capture.
- `onExportedResult`: receive signature + optional live capture in one payload.
- `showExportPreview`: optionally replace signature pad area with exported preview.
- `exportPreviewSource`: choose preview source (`signature`, `liveCapture`, `both`).
- `layoutBuilder`: fully custom signature + camera layout.
- `liveCameraBuilder`: custom wrapper for camera section while keeping default layout.
- `isDirectUpload`: auto-upload signature (and live capture) after export.
- `uploadUrl`: endpoint to POST the image file.
- `uploadToken`: optional bearer token sent in `Authorization` header.
- `showUploadResultDialog`: show success/error dialog after upload.
- `showUploadLoading`: show loading overlay on the pad (and camera) during upload.
- Upload response keys: mapper auto-detects common keys for file URL and image ID; manual keys are no longer required.

### Signature + Live Camera Example

```dart
FormFieldsSignaturePad(
  showLiveCamera: true,
  showExportPreview: true,
  exportPreviewSource: SignaturePadPreviewSource.both,
  liveCameraController: liveCameraController,
  onLiveCaptured: (captured) {
    // Called right after first draw-start capture
  },
  onExportedResult: (result) {
    final MyimageResult signature = result.signature;
    final MyimageResult? liveCapture = result.liveCapture;
    // Handle both results together
  },
)
```

### Direct Upload Example

Auto-upload signature (and selfie) immediately after export. The `MyimageResult`
returned in callbacks will contain `link` and `imageId` from the server.

```dart
FormFieldsSignaturePad(
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',       // optional
  showUploadResultDialog: true,
  showUploadLoading: true,                // loading overlay while uploading
  showExportPreview: true,
  onExported: (result) {
    result.link;    // server URL
    result.imageId; // server ID
  },
)
```

With live camera — both signature and selfie are uploaded in one export action:

```dart
FormFieldsSignaturePad(
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  showUploadLoading: true,
  showLiveCamera: true,
  showExportPreview: true,
  exportPreviewSource: SignaturePadPreviewSource.both,
  onExportedResult: (result) {
    result.signature.link;    // uploaded signature URL
    result.liveCapture?.link; // uploaded selfie URL
  },
)
```

### Export Preview Modes (Optional)

Use these options when you want the exported result to be shown inside the
signature area and hide the export button until user clears.

```dart
FormFieldsSignaturePad(
  showLiveCamera: true,
  showExportPreview: true,
  // One of: signature | liveCapture | both
  exportPreviewSource: SignaturePadPreviewSource.signature,
)
```

### Show Export Result in Another Area

If you want the result at the end of a `Column` (or any external area), keep
`showExportPreview: false`, then render result from callback state.

```dart
SignaturePadExportResult? exported;

FormFieldsSignaturePad(
  showLiveCamera: true,
  showExportPreview: false,
  onExportedResult: (result) => setState(() => exported = result),
  layoutBuilder: (ctx, pad, camera) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pad,
        if (camera != null) ...[
          const SizedBox(height: 12),
          camera,
        ],
        if (exported != null) ...[
          const SizedBox(height: 12),
          Text('Rendered outside pad area'),
          // build your own preview widget here
        ],
      ],
    );
  },
)
```

### Standalone Live Camera Example

Use this when you need live camera capture without signature pad.

Two approaches are available — choose the one that fits your needs:

#### Option A — GlobalKey (no controller needed)

```dart
final cameraKey = GlobalKey<FormFieldsLiveCameraCaptureState>();

FormFieldsLiveCameraCapture(
  key: cameraKey,
  height: 200,
  onCaptured: (result) {
    // Called when capture() succeeds
  },
)

// Trigger capture
await cameraKey.currentState?.capture();

// Reset to live preview
cameraKey.currentState?.resetCapture();
```

#### Option B — Controller (no GlobalKey needed)

```dart
final cameraController = FormFieldsMyImageController();

FormFieldsLiveCameraCapture(
  height: 200,
  cameraController: cameraController,
  onCaptured: (result) { },
)

// Trigger capture from anywhere
final result = await cameraController.capture();

// Reset from anywhere
cameraController.resetCapture();
```

Both `cameraController` and `key` can be used together for maximum flexibility.

### Behavior Notes

- Camera source is front camera by default.
- No camera/gallery chooser dialog is shown.
- In signature flow, capture fires once on first draw start.
- Capture will fire again only after clear/reset.
- Existing `onExported` remains supported for backward compatibility.

### Localization Keys Added (EN/ID)

- `signatureClear`
- `signatureExport`
- `liveCaptureTitle`
- `liveCaptureAutoOnSign`
- `cameraInitializing`
- `cameraNoCamerasFound`
- `cameraReady`
- `cameraCaptured`
- `uploadSuccessTitle`
- `uploadSuccessMessage`
- `uploadFailedTitle`
- `uploadFailedMessage`
- `uploadErrorTitle`
- `uploadErrorMessage`

### Example App Updates

The `example` app now includes:

- Basic signature export.
- Signature + live camera auto-capture.
- Custom layout via `layoutBuilder`.
- Custom camera wrapper via `liveCameraBuilder`.
- Standalone live camera with capture/reset via `GlobalKey`.
- Standalone live camera with capture/reset via **controller** (no `GlobalKey`).
- **Direct upload** — signature auto-uploaded after export (Example 8).
- **Direct upload + live camera** — both signature and selfie uploaded (Example 9).

### Technical Notes

#### Camera Initialization

- Front camera is initialized lazily on first widget build.
- Uses shared singleton manager to avoid multi-instance conflicts.
- Only one `CameraController` is active at a time (ref-counted).

#### Capture Mechanism

- Capture uses `RepaintBoundary.toImage()` (screenshot-based).
- Avoids CameraX "No supported surface combination" errors.
- Captured image is saved as PNG to system temp directory.
- Result wrapped in `MyimageResult` (same as FormFieldsMyImage).

#### Permissions

- Requires `CAMERA` permission on Android/iOS.
- Add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  ```
- Add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Camera access needed to capture signature photo</string>
  ```
- Use `permission_handler` package to request at runtime (optional but recommended).

#### Dependencies

- Signature pad: `package:signature`
- Camera: `package:camera`
- Image processing: `package:flutter/rendering`

### API Reference (Summary)

#### FormFieldsSignaturePad

```dart
FormFieldsSignaturePad(
  // Signature pad appearance
  height: 200,
  width: double.infinity,
  backgroundColor: Colors.white,
  penColor: Colors.black,
  penStrokeWidth: 3.0,
  exportBackgroundColor: null, // null = transparent

  // Callbacks
  onExported: (MyimageResult?) { },      // Legacy: signature only
  onExportedResult: (SignaturePadExportResult) { },  // New: both signature + live capture
  onLiveCaptured: (MyimageResult) { },    // Called right after capture

  // Optional in-pad preview after export
  showExportPreview: false,
  exportPreviewSource: SignaturePadPreviewSource.signature,

  // Live camera
  showLiveCamera: false,
  liveCameraHeight: 200,
  liveCameraController: controller,       // Optional external controller
  layoutBuilder: (ctx, pad, camera) => ..., // Custom layout
  liveCameraBuilder: (ctx, cam) => ...,     // Custom camera wrapper

  // Direct upload
  isDirectUpload: false,
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',       // optional; sent as Authorization header
  showUploadResultDialog: false,          // show success/error dialog after upload
  showUploadLoading: true,                // loading overlay on pad + camera while uploading
  // Upload response keys are auto-detected by the mapper; no manual keys required.
  uploadSuccessTitle: null,              // null = use localized default
  uploadFailedTitle: null,
  uploadErrorTitle: null,
  uploadSuccessMessage: null,
  uploadFailedMessage: null,
  uploadErrorMessage: null,
)
```

#### SignaturePadPreviewSource

```dart
enum SignaturePadPreviewSource {
  signature,
  liveCapture,
  both,
}
```

#### SignaturePadExportResult

```dart
class SignaturePadExportResult {
  final MyimageResult signature;      // Always present (signature drawing)
  final MyimageResult? liveCapture;   // Optional (null if disabled or not captured)
}
```

#### FormFieldsLiveCameraCapture

```dart
FormFieldsLiveCameraCapture(
  key: GlobalKey<FormFieldsLiveCameraCaptureState>(), // optional
  height: 200,
  cameraController: FormFieldsMyImageController(),   // optional
  onCaptured: (MyimageResult) { },

  // Direct upload
  isDirectUpload: false,
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',   // optional
  showUploadResultDialog: false,
  showUploadLoading: true,            // loading overlay during upload
  // Upload response keys are auto-detected by the mapper; no manual keys required.
)
```

#### FormFieldsLiveCameraCaptureState

```dart
// Methods accessible via GlobalKey<FormFieldsLiveCameraCaptureState>()
Future<MyimageResult?> capture()    // Capture current frame
void resetCapture()                 // Clear capture, return to live preview
```

#### FormFieldsMyImageController — Camera & Picker Methods

```dart
// Capture current frame from the linked FormFieldsLiveCameraCapture
Future<MyimageResult?> capture()

// Reset the linked FormFieldsLiveCameraCapture to live preview
void resetCapture()

// Open image picker on the linked FormFieldsMyImage
// source: 'camera' | 'gallery' | null (shows bottom-sheet chooser)
Future<void> pickImage({String? source})
```

These methods are no-ops when no widget is currently linked to the controller.

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
- [FormFieldsLiveCameraCapture](docs/components/form_fields_live_camera_capture.md)

## Barcode/QR Code Scanner Field

**FormFieldsBarcodeScan** is a reusable barcode/QR code scanner form field widget for Flutter, using mobile_scanner. It provides a professional overlay border, seamless integration with forms, and a consistent API with other FormFields components.

### Example

```dart
FormFields<String>(
  label: 'Scan Barcode',
  formType: FormType.scanBarcode,
  labelPosition: LabelPosition.inBorder, // label inside border
  currentValue: viewModel.barcode,
  isRequired: true,
  onChanged: (value) {
    viewModel.setBarcode(value);
  },
)
```

### Example: Barcode Scan Field with No Label

```dart
FormFields<String>(
  label: 'Scan Barcode',
  formType: FormType.scanBarcode,
  labelPosition: LabelPosition.none, // no label at all
  currentValue: viewModel.barcode,
  isRequired: true,
  onChanged: (value) {
    viewModel.setBarcode(value);
  },
)
```

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
FormFieldsMyImage(
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
