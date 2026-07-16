// Copied from original package to provide standalone FCM helpers.
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:form_fields_fcm/model/fcm_models.dart';

class FCMOptions {
  final bool showLocalNotification;
  const FCMOptions({this.showLocalNotification = true});
}

Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

typedef BackgroundMessageHandler = Future<void> Function(RemoteMessage message);

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

  Future<void> initialize({
    FCMOptions options = const FCMOptions(),
    FCMMessageHandler? onMessage,
    FCMMessageHandler? onMessageOpenedApp,
    FutureOr<void> Function(String token)? onToken,
    FutureOr<void> Function(String token)? onTokenRefresh,
    BackgroundMessageHandler? backgroundHandler,
  }) async {
    try {
      await Firebase.initializeApp();
    } catch (_) {}

    if (backgroundHandler != null) {
      try {
        FirebaseMessaging.onBackgroundMessage(backgroundHandler);
      } catch (_) {}
    }

    try {
      _messaging = FirebaseMessaging.instance;
    } catch (_) {
      _messaging = null;
    }

    _onMessageOpenedAppHandler = onMessageOpenedApp;
    await _initLocalNotifications();

    try {
      await _messaging?.requestPermission();
    } catch (_) {}

    _onMessageSub = FirebaseMessaging.onMessage.listen((msg) async {
      final model = FCMMessage.fromRemoteMessage(msg);
      if (options.showLocalNotification) {
        await _showLocalNotification(model);
      }
      if (onMessage != null) await onMessage(model);
    });

    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((
      msg,
    ) async {
      final model = FCMMessage.fromRemoteMessage(msg);
      if (onMessageOpenedApp != null) await onMessageOpenedApp(model);
    });

    final initial = await (_messaging?.getInitialMessage());
    if (initial != null) {
      _initialRemoteMessage = initial;
    }

    try {
      if (onToken != null) {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          try {
            await onToken(token);
          } catch (_) {}
        }
      }

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
        try {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              jsonDecode(payload) as Map<String, dynamic>,
            );
            final fcm = FCMMessage.fromData(data);
            if (_onMessageOpenedAppHandler != null) {
              try {
                await _onMessageOpenedAppHandler!(fcm);
              } catch (_) {}
            }
          }
        } catch (_) {}
      },
    );
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
    } catch (_) {}
  }

  // Removed unused helper: _cleanupOldTempFiles

  Future<void> _showLocalNotification(FCMMessage msg) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final androidDetails = AndroidNotificationDetails(
      'form_fields_fcm_channel',
      'FormFields FCM',
      channelDescription: 'Notifications for FormFields package',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
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
        final uri = Uri.parse(imageUrl);
        final filename = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'fcm_image_$id';
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(uri);
        try {
          request.headers.set('User-Agent', 'FormFields/FCM');
        } catch (_) {}
        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          final largeIcon = FilePathAndroidBitmap(filePath);
          final bigPicture = FilePathAndroidBitmap(filePath);
          final androidWithImage = AndroidNotificationDetails(
            'form_fields_fcm_channel',
            'FormFields FCM',
            channelDescription: 'Notifications for FormFields package',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            largeIcon: largeIcon,
            styleInformation: BigPictureStyleInformation(
              bigPicture,
              largeIcon: largeIcon,
            ),
          );

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
      } catch (_) {
        details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      }
    } else {
      details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    }

    final Map<String, dynamic> payloadMap = <String, dynamic>{};
    if (msg.data.isNotEmpty) payloadMap.addAll(msg.data);
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

  Future<FCMMessage?> consumeInitialMessage() async {
    final m = _initialRemoteMessage;
    _initialRemoteMessage = null;
    if (m == null) return null;
    return FCMMessage.fromRemoteMessage(m);
  }

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
