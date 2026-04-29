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

| Parameter                     | Type                                      | Description                                    |
| ----------------------------- | ----------------------------------------- | ---------------------------------------------- |
| `height`, `width`             | `double`                                  | Size of the signature area                     |
| `penColor`, `backgroundColor` | `Color`                                   | Drawing style                                  |
| `penStrokeWidth`              | `double`                                  | Pen thickness                                  |
| `exportBackgroundColor`       | `Color?`                                  | PNG background override (`null` = transparent) |
| `onExported`                  | `void Function(MyimageResult?)`           | Legacy: signature only                         |
| `onExportedResult`            | `void Function(SignaturePadExportResult)` | Signature + optional live capture              |
| `onLiveCaptured`              | `void Function(MyimageResult)`            | Fired immediately after camera capture         |
| `showLiveCamera`              | `bool`                                    | Enable live front-camera preview               |
| `liveCameraHeight`            | `double`                                  | Camera preview height                          |
| `liveCameraController`        | `FormFieldsMyImageController?`            | External controller for captured image         |
| `layoutBuilder`               | `Widget Function(ctx, pad, camera)?`      | Fully custom layout                            |
| `liveCameraBuilder`           | `Widget Function(ctx, cam)?`              | Custom camera wrapper                          |

## SignaturePadExportResult

```dart
class SignaturePadExportResult {
  final MyimageResult signature;    // Always present
  final MyimageResult? liveCapture; // null if camera disabled or not captured
}
```

## Behavior Notes

- Live camera captures once on first draw start per signing session.
- Capture resets automatically when user taps Clear.
- `onExported` is still supported for backward compatibility.

## Integration

- Signature drawing: [`package:signature`](https://pub.dev/packages/signature)
- Camera: [`package:camera`](https://pub.dev/packages/camera)

See [API.md](../../API.md) for full parameter details.
See [FormFieldsLiveCameraCapture](form_fields_live_camera_capture.md) for standalone camera usage.
