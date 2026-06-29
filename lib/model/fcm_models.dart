import 'package:firebase_messaging/firebase_messaging.dart';

/// Lightweight, package-local models for FCM messages and notifications.
class FCMMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final RemoteMessage raw;

  FCMMessage({this.title, this.body, required this.data, required this.raw});

  factory FCMMessage.fromRemoteMessage(RemoteMessage message) {
    return FCMMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      raw: message,
    );
  }
}

class FCMNotification {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  FCMNotification({this.title, this.body, this.data = const {}});
}

typedef FCMMessageHandler = Future<void> Function(FCMMessage message);
