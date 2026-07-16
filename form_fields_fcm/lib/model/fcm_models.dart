import 'package:firebase_messaging/firebase_messaging.dart';

class FCMMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final RemoteMessage? raw;

  FCMMessage({this.title, this.body, required this.data, this.raw});

  factory FCMMessage.fromRemoteMessage(RemoteMessage message) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    if (data.isEmpty) {
      if (message.notification?.title != null) {
        data['title'] = message.notification!.title;
      }
      if (message.notification?.body != null) {
        data['body'] = message.notification!.body;
      }
    }
    return FCMMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: data,
      raw: message,
    );
  }

  factory FCMMessage.fromData(Map<String, dynamic> data) {
    return FCMMessage(
      title: data['title']?.toString(),
      body: data['body']?.toString(),
      data: data,
      raw: null,
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
