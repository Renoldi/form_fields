import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:form_fields/model/fcm_models.dart';

/// Options to configure `FCMService` behavior on initialization.
class FCMOptions {
  /// When true, incoming foreground messages will trigger a local notification.
  final bool showLocalNotification;

  const FCMOptions({this.showLocalNotification = true});
}

/// Top-level background handler must be a top-level function. Register this
/// using `FCMService.registerBackgroundHandler(...)` from the app `main()` if
/// background handling is needed. This centralizes registration so example
/// and consumers do not call `FirebaseMessaging.onBackgroundMessage` directly.
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // Minimal default: no-op. Users can process background messages by
  // implementing their own background callback and/or calling into
  // platform-specific code here.
}

/// Professional, reusable FCM helper for common tasks: initialization,
/// handlers, topic subscription, token management, and optional local
/// notifications for foreground messages.
class FCMService {
  FCMService._internal();
  static final FCMService instance = FCMService._internal();
  factory FCMService() => instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  /// Initialize Firebase (if necessary), local notifications and message
  /// handlers. Provide optional callbacks for foreground/opened-app events.
  Future<void> initialize({
    FCMOptions options = const FCMOptions(),
    FCMMessageHandler? onMessage,
    FCMMessageHandler? onMessageOpenedApp,
  }) async {
    // Ensure Firebase is initialized (safe to call multiple times).
    try {
      await Firebase.initializeApp();
    } catch (_) {}

    await _initLocalNotifications();

    // Request permissions (iOS / macOS); Android returns granted by default.
    await _messaging.requestPermission();

    // Foreground messages
    _onMessageSub = FirebaseMessaging.onMessage.listen((msg) async {
      final model = FCMMessage.fromRemoteMessage(msg);
      if (options.showLocalNotification) {
        await _showLocalNotification(model);
      }
      if (onMessage != null) await onMessage(model);
    });

    // Tapped/opened messages
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      final model = FCMMessage.fromRemoteMessage(msg);
      if (onMessageOpenedApp != null) await onMessageOpenedApp(model);
    });

    // Handle case where app was opened from a terminated state via a message
    final initial = await _messaging.getInitialMessage();
    if (initial != null && onMessageOpenedApp != null) {
      await onMessageOpenedApp(FCMMessage.fromRemoteMessage(initial));
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final settings = InitializationSettings(android: android, iOS: ios);

    await _localNotificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) async {
          // Default tap behavior: nothing. Consumers can wire payloads to
          // navigation by listening to `onMessageOpenedApp` from Firebase.
        });
  }

  Future<void> _showLocalNotification(FCMMessage msg) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final androidDetails = AndroidNotificationDetails(
      'form_fields_fcm_channel',
      'FormFields FCM',
      channelDescription: 'Notifications for FormFields package',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotificationsPlugin.show(
      id: id,
      title: msg.title ?? '',
      body: msg.body ?? '',
      notificationDetails: details,
      payload: msg.data.isNotEmpty ? msg.data.toString() : null,
    );
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> deleteToken() => _messaging.deleteToken();

  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
  }

  /// Register a top-level background message handler in one central place.
  ///
  /// Example (call from `main()` before `runApp()`):
  /// `FCMService.registerBackgroundHandler(fcmBackgroundHandler);`
  static void registerBackgroundHandler(BackgroundMessageHandler handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  /// Register a token refresh listener centrally.
  /// Returns the created [StreamSubscription] so callers may cancel if desired.
  static StreamSubscription<String> registerOnTokenRefresh(
      FutureOr<void> Function(String token) handler) {
    return FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await handler(token);
      } catch (_) {}
    });
  }
}
