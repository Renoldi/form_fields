import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  RemoteMessage? _initialRemoteMessage;
  FCMMessageHandler? _onMessageOpenedAppHandler;

  /// Initialize Firebase (if necessary), local notifications and message
  /// handlers. Provide optional callbacks for foreground/opened-app events.
  Future<void> initialize({
    FCMOptions options = const FCMOptions(),
    FCMMessageHandler? onMessage,
    FCMMessageHandler? onMessageOpenedApp,
    FutureOr<void> Function(String token)? onToken,
    FutureOr<void> Function(String token)? onTokenRefresh,
    BackgroundMessageHandler? backgroundHandler,
  }) async {
    // Register top-level background handler if provided. This centralizes
    // background registration so consumers may pass their top-level handler
    // into `initialize(...)` instead of calling a separate static API.
    try {
      await Firebase.initializeApp();
    } catch (_) {}

    if (backgroundHandler != null) {
      try {
        FirebaseMessaging.onBackgroundMessage(backgroundHandler);
      } catch (_) {}
    }

    // Initialize messaging instance after Firebase initialized.
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (_) {
      _messaging = null;
    }

    // Store handler so local notification taps can invoke it.
    _onMessageOpenedAppHandler = onMessageOpenedApp;
    await _initLocalNotifications();

    // Request permissions (iOS / macOS); Android returns granted by default.
    try {
      await _messaging?.requestPermission();
    } catch (_) {}

    // Foreground messages
    _onMessageSub = FirebaseMessaging.onMessage.listen((msg) async {
      final model = FCMMessage.fromRemoteMessage(msg);
      if (options.showLocalNotification) {
        await _showLocalNotification(model);
      }
      if (onMessage != null) await onMessage(model);
    });

    // Tapped/opened messages
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((
      msg,
    ) async {
      final model = FCMMessage.fromRemoteMessage(msg);
      if (onMessageOpenedApp != null) await onMessageOpenedApp(model);
    });

    // Handle case where app was opened from a terminated state via a message.
    // Store the initial message so the app can consume it once UI is ready.
    final initial = await (_messaging?.getInitialMessage());
    if (initial != null) {
      _initialRemoteMessage = initial;
      try {
        debugPrint(
          'FCMService: initial message received. title=${initial.notification?.title} data=${initial.data}',
        );
      } catch (_) {}
    }

    // Retrieve FCM token and notify caller if provided
    try {
      if (onToken != null) {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          try {
            await onToken(token);
          } catch (_) {}
        }
      }

      // Register token refresh listener if caller provided handler
      if (onTokenRefresh != null) {
        _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
          newToken,
        ) async {
          try {
            await onTokenRefresh(newToken);
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final settings = InitializationSettings(android: android, iOS: ios);

    await _localNotificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        // When the user taps a local notification, log payload and try to
        // invoke the `onMessageOpenedApp` handler (if any) with the parsed payload.
        try {
          final payload = response.payload;
          debugPrint('FCMService: local notification tapped. payload=$payload');
          if (payload != null && payload.isNotEmpty) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              jsonDecode(payload) as Map<String, dynamic>,
            );
            debugPrint('FCMService: parsed local notification data=$data');
            final fcm = FCMMessage.fromData(data);
            if (_onMessageOpenedAppHandler != null) {
              try {
                await _onMessageOpenedAppHandler!(fcm);
                debugPrint('FCMService: invoked onMessageOpenedApp handler');
              } catch (e, st) {
                debugPrint('FCMService: handler threw: $e\n$st');
              }
            } else {
              debugPrint(
                'FCMService: no onMessageOpenedApp handler registered',
              );
            }
          }
        } catch (e, st) {
          debugPrint(
            'FCMService: failed parsing notification payload: $e\n$st',
          );
        }
      },
    );
    // Create Android notification channel for richer presentation
    try {
      final androidChannel = AndroidNotificationChannel(
        'form_fields_fcm_channel',
        'FormFields FCM',
        description: 'Notifications for FormFields package',
        importance: Importance.high,
      );
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      debugPrint('FCMService: failed creating Android channel: $e');
    }

    // Clean up old temporary files used for notification images
    try {
      await _cleanupOldTempFiles();
    } catch (e) {
      debugPrint('FCMService: cleanup temp files failed: $e');
    }
  }

  Future<void> _cleanupOldTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      if (!await dir.exists()) return;
      final now = DateTime.now();
      await for (final f in dir.list()) {
        try {
          if (f is File) {
            final name = f.uri.pathSegments.isNotEmpty
                ? f.uri.pathSegments.last
                : '';
            if (name.startsWith('fcm_image_')) {
              final stat = await f.stat();
              if (now.difference(stat.modified) > const Duration(days: 1)) {
                try {
                  await f.delete();
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('FCMService: _cleanupOldTempFiles error: $e');
    }
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
    // Try to include an image if provided in payload (data.image|image_url|imageUrl).
    String? imageUrl;
    try {
      imageUrl =
          msg.data['image']?.toString() ??
          msg.data['image_url']?.toString() ??
          msg.data['imageUrl']?.toString();
    } catch (_) {
      imageUrl = null;
    }

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails();

    NotificationDetails details;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        // Download image to temporary directory
        final uri = Uri.parse(imageUrl);
        final filename = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'fcm_image_$id';
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(uri);
        // Provide a user-agent to avoid some servers blocking default clients
        try {
          request.headers.set(
            'User-Agent',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0 Safari/537.36',
          );
        } catch (_) {}
        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        if (response.statusCode == 200) {
          try {
            final contentType =
                response.headers.contentType?.mimeType ?? 'unknown';
            debugPrint(
              'FCMService: downloaded image content-type=$contentType',
            );
          } catch (_) {}
          final bytes = await consolidateHttpClientResponseBytes(response);
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          // Determine whether sender requested only a small image.
          final smallOnlyRaw = msg.data['small_image_only']?.toString();
          final smallOnly = smallOnlyRaw == '1' || smallOnlyRaw == 'true';

          // Android: create largeIcon; optionally use BigPicture style
          final largeIcon = FilePathAndroidBitmap(filePath);
          AndroidNotificationDetails androidWithImage;
          if (smallOnly) {
            androidWithImage = AndroidNotificationDetails(
              'form_fields_fcm_channel',
              'FormFields FCM',
              channelDescription: 'Notifications for FormFields package',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              largeIcon: largeIcon,
            );
          } else {
            final bigPicture = FilePathAndroidBitmap(filePath);
            androidWithImage = AndroidNotificationDetails(
              'form_fields_fcm_channel',
              'FormFields FCM',
              channelDescription: 'Notifications for FormFields package',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              largeIcon: largeIcon,
              styleInformation: BigPictureStyleInformation(
                bigPicture,
                largeIcon: largeIcon,
                contentTitle: msg.title ?? '',
                summaryText: msg.body ?? '',
              ),
            );
          }

          // iOS: attachment
          final DarwinNotificationAttachment attachment =
              DarwinNotificationAttachment(filePath);
          iosDetails = DarwinNotificationDetails(attachments: [attachment]);

          details = NotificationDetails(
            android: androidWithImage,
            iOS: iosDetails,
          );
        } else {
          details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );
        }
      } catch (e) {
        debugPrint('FCMService: failed to download image for notification: $e');
        details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      }
    } else {
      details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    }

    // Ensure payload contains something useful. If the remote message didn't
    // include a data payload, merge in the notification title/body so taps
    // still receive meaningful information.
    final Map<String, dynamic> payloadMap = <String, dynamic>{};
    if (msg.data.isNotEmpty) {
      payloadMap.addAll(msg.data);
    }
    if (payloadMap.isEmpty) {
      if (msg.title != null) payloadMap['title'] = msg.title;
      if (msg.body != null) payloadMap['body'] = msg.body;
    }

    await _localNotificationsPlugin.show(
      id: id,
      title: msg.title ?? '',
      body: msg.body ?? '',
      notificationDetails: details,
      payload: payloadMap.isNotEmpty ? jsonEncode(payloadMap) : null,
    );
  }

  Future<String?> getToken() async {
    try {
      if (_messaging != null) return await _messaging!.getToken();
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      if (_messaging != null) return await _messaging!.deleteToken();
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      if (_messaging != null) return await _messaging!.subscribeToTopic(topic);
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {}
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (_messaging != null) {
        return await _messaging!.unsubscribeFromTopic(topic);
      }
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _initialRemoteMessage = null;
  }

  /// Returns the initial message that opened the app (if any) and clears it
  /// so it won't be delivered twice. Useful for performing navigation after
  /// the widgets and routing are ready.
  Future<FCMMessage?> consumeInitialMessage() async {
    final m = _initialRemoteMessage;
    _initialRemoteMessage = null;
    if (m == null) return null;
    try {
      debugPrint('FCMService: initial message consumed. data=${m.data}');
    } catch (_) {}
    return FCMMessage.fromRemoteMessage(m);
  }

  // Background handler registration moved to `initialize(...)`.

  /// Register a token refresh listener centrally.
  /// Returns the created [StreamSubscription] so callers may cancel if desired.
  static StreamSubscription<String> registerOnTokenRefresh(
    FutureOr<void> Function(String token) handler,
  ) {
    return FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await handler(token);
      } catch (_) {}
    });
  }
}
