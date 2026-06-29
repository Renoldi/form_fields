# FCM (Firebase Cloud Messaging) — FormFields integration

This document shows how to integrate the `FCMService` helper included in
the `form_fields` package to handle push notifications in a reusable,
maintainable way.

## 1) Add dependencies

In your app `pubspec.yaml` make sure you include Firebase and local
notification packages (these are required by the package):

```yaml
dependencies:
  firebase_core: ^
  firebase_messaging: ^
  flutter_local_notifications: ^
  form_fields:
    path: ../ # or use package reference
```

Run:

```bash
flutter pub get
```

## 2) Android / iOS platform setup

Follow the official Firebase setup guides for Android and iOS to register
your app, add `google-services.json` / `GoogleService-Info.plist`, and
configure application IDs and entitlements. Also enable background
messaging capabilities on iOS as described in the Firebase docs.

## 3) Use the helper in `main()`

A minimal example is provided in the package at
`lib/src/service/fcm_example.dart`. Key steps:

- Initialize Firebase (`Firebase.initializeApp()`).
- Register a top-level background handler with
  `FCMService.registerBackgroundHandler(fcmBackgroundHandler)`.
- Call `await FCMService.instance.initialize(...)` and provide
  optional `onMessage` and `onMessageOpenedApp` callbacks.

Example (see `fcm_example.dart`):

```dart
import 'package:form_fields/form_fields.dart';

Future<void> main() async {
  await exampleMain();
}
```

## 4) Customization

- `FCMOptions(showLocalNotification: true)` controls whether incoming
  foreground messages generate a local notification via
  `flutter_local_notifications`.
- Provide `onMessage` to handle in-app foreground messages and
  `onMessageOpenedApp` to handle taps on notifications.

## 5) Notes

- The example shows token retrieval, subscribing to topics, and basic
  UI flows. For production, secure your server keys and implement
  server-side logic for sending messages.
