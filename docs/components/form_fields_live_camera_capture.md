# FormFieldsLiveCameraCapture

Standalone live front-camera preview widget that can capture a frame into a `MyimageResult`. Can be used independently or embedded inside `FormFieldsSignaturePad` via `showLiveCamera: true`.

## Basic Usage (GlobalKey)

Use a `GlobalKey` when you want to trigger capture/reset from a button in the same widget tree.

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

## Basic Usage (Controller)

Use a `FormFieldsMyImageController` when you want to trigger capture/reset from outside the widget tree (e.g. a ViewModel).

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

Both `key` and `cameraController` can be used together.

## Key Options

- `height`: Height of the camera preview area.
- `cameraController` _(optional)_: External controller for reading captured images and triggering capture/reset programmatically.
- `onCaptured`: Callback fired each time `capture()` succeeds with a `MyimageResult`.

## FormFieldsLiveCameraCaptureState Methods

Accessible via `GlobalKey<FormFieldsLiveCameraCaptureState>`:

| Method                             | Description                              |
| ---------------------------------- | ---------------------------------------- |
| `Future<MyimageResult?> capture()` | Capture current camera frame as PNG      |
| `void resetCapture()`              | Clear capture and return to live preview |

## FormFieldsMyImageController Methods (Camera)

| Method                             | Description                          |
| ---------------------------------- | ------------------------------------ |
| `Future<MyimageResult?> capture()` | Trigger capture on the linked widget |
| `void resetCapture()`              | Trigger reset on the linked widget   |

These are no-ops when no widget is linked.

## Technical Notes

- Uses `RepaintBoundary.toImage()` (screenshot-based capture).
- Avoids CameraX "No supported surface combination" errors.
- Captured image is saved as PNG to system temp directory.
- Front camera is used by default.
- Camera is lazily initialized and ref-counted via a shared singleton.

## Permissions

Android — add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

iOS — add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access needed to capture photo</string>
```

See [API.md](../../API.md) for full parameter details.
