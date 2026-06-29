FCM Integration Steps (Android & iOS)

This guide walks through required platform setup to use Firebase Cloud Messaging (FCM) with the example app.

## Android

1. Add Firebase to your Android app:
   - In the Firebase Console, add an Android app for your project.
   - Use your Android package name (see `example/android/app/src/main/AndroidManifest.xml`).
   - Download `google-services.json` and place it under `example/android/app/`.

2. Add Google Services plugin:
   - In `example/android/build.gradle` add classpath:
     ```groovy
     dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
     }
     ```
   - In `example/android/app/build.gradle`, at the bottom add:
     ```groovy
     apply plugin: 'com.google.gms.google-services'
     ```

3. Ensure Firebase Messaging dependency is present (handled by `pubspec.yaml`).

4. Notification channel & icons:
   - Ensure you have an adaptive launcher icon (mipmap) and a small notification
     icon in `res/drawable` (e.g. `ic_stat_ic_notification`).
   - The example uses `@mipmap/ic_launcher` as the default notification icon.

5. Permissions: on Android 13+ request `POST_NOTIFICATIONS` at runtime. The
   example app requests notification permission via `permission_handler`.

## iOS / macOS

1. Register App in Firebase Console for iOS and download
   `GoogleService-Info.plist` into `example/ios/Runner/`.

2. Enable Push Notifications capability and Background Modes (Remote
   notifications) in `Runner` target > Signing & Capabilities.

3. In `ios/Podfile`, ensure platform is at least 11.0 or higher.

4. For APNs: upload your APNs key / certificates to Firebase so FCM can
   deliver messages to iOS devices.

5. App delegate setup: the `firebase_messaging` package's iOS
   integration requires configuring `UNUserNotificationCenter` delegate
   and requesting permissions. The example app requests notification
   permission via `permission_handler` and `FCMService` requests
   messaging permissions as well.

## Notes

for iOS notifications) and check logs for FCM token. Use the token to send
test messages from the Firebase Console or your server.
is registered with a top-level function like `fcmBackgroundHandler`.
For background message handling, register the background handler via the
`FCMService` helper:

```dart
// In your `main()` before `runApp()`
FCMService.registerBackgroundHandler(fcmBackgroundHandler);
```

Ensure `fcmBackgroundHandler` is a top-level function so it can be
invoked from background isolates.

- See `example/lib/main.dart` for how the example initializes and uses
  `FCMService`.

## Sending test messages

You can send test messages to a device token using either `curl` or the
provided Dart helper script.

1. Using curl (legacy server key):

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" -H "Content-Type: application/json" \
   -d '{"to":"<DEVICE_TOKEN>","notification":{"title":"Test","body":"Hello"}}' \
   https://fcm.googleapis.com/fcm/send
```

2. Using the provided Dart script:

Set the server key in the environment and run the script from the package root:

```bash
cd example
DART_SERVER_KEY="AAAA..." dart run example/tools/send_fcm_test.dart <DEVICE_TOKEN>
```

Note: Avoid committing server keys to source control. For production, use
Firebase Cloud Messaging HTTP v1 API with OAuth2 service accounts or use a
backend to send messages securely.

## HTTP v1 (recommended for production)

This method uses a Google service account JSON and OAuth2 to call the
FCM HTTP v1 endpoint. Example Node.js script included at
`example/tools/send_fcm_v1.js`.

Requirements:

- Node.js and npm
- A service account JSON with `firebase.messaging` scope (create in
  Google Cloud Console and grant the Firebase Admin role)

Install and run:

```bash
cd example
npm install google-auth-library axios
node example/tools/send_fcm_v1.js path/to/service-account.json <DEVICE_TOKEN>
```

The script exchanges the service account credentials for an access token
and securely calls the FCM HTTP v1 API.
