# form_fields_fcm

Optional Firebase Cloud Messaging helpers for the `form_fields` package.

This package isolates FCM and local-notification integration so consumers
who don't use FCM don't need to download Firebase dependencies.

## Install

Development (local path):

1. In your app `pubspec.yaml`:

```yaml
dependencies:
  form_fields: ^1.1.0
  form_fields_fcm:
    path: ../form_fields_fcm
```

2. Run:

```bash
flutter pub get
```

Published (pub.dev or git):

```yaml
dependencies:
  form_fields: ^1.1.0
  form_fields_fcm: ^1.0.0 # replace with published version
```

## Usage

Import the package and initialize as needed (example in `main()`):

```dart
import 'package:form_fields_fcm/form_fields_fcm.dart';

await FCMService.instance.initialize(
  backgroundHandler: fcmBackgroundHandler,
  options: const FCMOptions(showLocalNotification: true),
);
```

Use `FCMService.instance.getToken()`, `subscribeToTopic()`, etc.

## Notes for maintainers

- This package contains Firebase dependencies (`firebase_core`,
  `firebase_messaging`, `flutter_local_notifications`). Keep it separate
  to avoid forcing those deps on consumers of the core `form_fields` package.
- During development the root repository uses a local `path:` dependency.
  Before publishing `form_fields_fcm`:
  - Remove the `path:` usage from consuming package examples.
  - Ensure `version` is bumped in `form_fields_fcm/pubspec.yaml`.

## License

Same license as the parent repository. See the repository `LICENSE`.
