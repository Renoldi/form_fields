# FormFieldsSignaturePad

Signature pad widget for capturing user signatures as images, with export to PNG and integration with MyimageResult for upload or further processing. Supports integrated live front-camera preview that auto-captures the moment the user starts signing.

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

## With Live Camera

Auto-captures a selfie the moment the user starts drawing the signature.

```dart
final liveCameraController = FormFieldsMyImageController();

FormFieldsSignaturePad(
  showLiveCamera: true,
  liveCameraController: liveCameraController,
  onLiveCaptured: (captured) {
    // Called right after the first draw-start capture
  },
  onExportedResult: (result) {
    final MyimageResult signature = result.signature;
    final MyimageResult? liveCapture = result.liveCapture;
  },
)
```

## Export Preview Modes (Optional)

Show exported result directly inside the signature area and hide export button
until user taps Clear.

```dart
FormFieldsSignaturePad(
  showLiveCamera: true,
  showExportPreview: true,
  exportPreviewSource: SignaturePadPreviewSource.both,
)
```

Available values:

- `SignaturePadPreviewSource.signature`
- `SignaturePadPreviewSource.liveCapture`
- `SignaturePadPreviewSource.both`

## Render Result Outside the Pad Area

Use callback state + your own layout if you want result preview at the end of a
`Column` (or any other place).

```dart
SignaturePadExportResult? exported;

FormFieldsSignaturePad(
  showLiveCamera: true,
  showExportPreview: false,
  onExportedResult: (result) => setState(() => exported = result),
  layoutBuilder: (ctx, pad, camera) => Column(
    children: [
      pad,
      if (camera != null) camera,
      if (exported != null) Text('Render result here'),
    ],
  ),
)
```

## Custom Layout (signature + camera side-by-side)

```dart
FormFieldsSignaturePad(
  showLiveCamera: true,
  layoutBuilder: (ctx, pad, camera) => Row(
    children: [
      Expanded(child: pad),
      if (camera != null) SizedBox(width: 140, child: camera),
    ],
  ),
  onExportedResult: (_) {},
)
```

## Custom Camera Wrapper

```dart
FormFieldsSignaturePad(
  showLiveCamera: true,
  liveCameraBuilder: (ctx, cam) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.deepPurple, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(8),
    child: cam,
  ),
  onExportedResult: (_) {},
)
```

## Key Options

| Parameter                     | Type                                      | Description                                                      |
| ----------------------------- | ----------------------------------------- | ---------------------------------------------------------------- |
| `height`, `width`             | `double`                                  | Size of the signature area                                       |
| `penColor`, `backgroundColor` | `Color`                                   | Drawing style                                                    |
| `penStrokeWidth`              | `double`                                  | Pen thickness                                                    |
| `exportBackgroundColor`       | `Color?`                                  | PNG background override (`null` = transparent)                   |
| `onExported`                  | `void Function(MyimageResult?)`           | Legacy: signature only                                           |
| `onExportedResult`            | `void Function(SignaturePadExportResult)` | Signature + optional live capture                                |
| `onLiveCaptured`              | `void Function(MyimageResult)`            | Fired immediately after camera capture                           |
| `showExportPreview`           | `bool`                                    | Show exported preview in pad area                                |
| `exportPreviewSource`         | `SignaturePadPreviewSource`               | Preview source: signature/liveCapture/both                       |
| `showLiveCamera`              | `bool`                                    | Enable live front-camera preview                                 |
| `liveCameraHeight`            | `double`                                  | Camera preview height                                            |
| `liveCameraController`        | `FormFieldsMyImageController?`            | External controller for captured image                           |
| `layoutBuilder`               | `Widget Function(ctx, pad, camera)?`      | Fully custom layout                                              |
| `liveCameraBuilder`           | `Widget Function(ctx, cam)?`              | Custom camera wrapper                                            |
| `isDirectUpload`              | `bool`                                    | Auto-upload after export (default `false`)                       |
| `uploadUrl`                   | `String?`                                 | Upload endpoint (required when `isDirectUpload: true`)           |
| `uploadToken`                 | `String?`                                 | Bearer token for `Authorization` header                          |
| `showUploadResultDialog`      | `bool`                                    | Show success/error dialog after upload                           |
| `showUploadLoading`           | `bool`                                    | Loading overlay on pad + camera while uploading (default `true`) |
| `uploadFileUrlKey`            | `String`                                  | JSON key for server file URL (default `'url'`)                   |
| `uploadImageIdKey`            | `String`                                  | JSON key for server image ID (default `'id'`)                    |
| `uploadSuccessTitle`          | `String?`                                 | Custom dialog title on success (`null` = localized default)      |
| `uploadFailedTitle`           | `String?`                                 | Custom dialog title on failure                                   |
| `uploadErrorTitle`            | `String?`                                 | Custom dialog title on error                                     |
| `uploadSuccessMessage`        | `String?`                                 | Custom dialog message on success                                 |
| `uploadFailedMessage`         | `String?`                                 | Custom dialog message on failure                                 |
| `uploadErrorMessage`          | `String?`                                 | Custom dialog message on error                                   |

## SignaturePadExportResult

```dart
class SignaturePadExportResult {
  final MyimageResult signature;    // Always present
  final MyimageResult? liveCapture; // null if camera disabled or not captured
}
```

## Direct Upload

Auto-upload the exported signature (and selfie, if live camera is enabled)
immediately after the user taps Export.

```dart
FormFieldsSignaturePad(
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token', // optional
  showUploadResultDialog: true,
  showUploadLoading: true,          // loading overlay on pad + camera
  onExported: (result) {
    result.link;    // server URL after upload
    result.imageId; // server image ID
  },
)
```

With live camera:

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

- When `isDirectUpload: true`, `uploadUrl` must be non-empty (enforced by assertion).
- The loading overlay disables the Clear and Export buttons while uploading.
- Upload message dialogs use localized defaults when custom titles/messages are `null`.

## Behavior Notes

- Live camera captures once on first draw start per signing session.
- Capture resets automatically when user taps Clear.
- `onExported` is still supported for backward compatibility.

## Integration

- Signature drawing: [`package:signature`](https://pub.dev/packages/signature)
- Camera: [`package:camera`](https://pub.dev/packages/camera)

See [API.md](../../API.md) for full parameter details.
See [FormFieldsLiveCameraCapture](form_fields_live_camera_capture.md) for standalone camera usage.
