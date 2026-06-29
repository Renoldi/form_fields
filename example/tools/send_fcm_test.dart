// Simple Dart script to send a test FCM message to a device token.
// Usage:
//   DART_SERVER_KEY="AAAA..." dart run example/tools/send_fcm_test.dart <DEVICE_TOKEN>

import 'dart:convert';
import 'dart:io';

Future<int> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: DART_SERVER_KEY="<FCM_SERVER_KEY>" dart run example/tools/send_fcm_test.dart <device_token>');
    return 2;
  }

  final token = args[0];
  final serverKey = Platform.environment['DART_SERVER_KEY'];
  if (serverKey == null || serverKey.isEmpty) {
    stderr.writeln('Error: DART_SERVER_KEY environment variable is not set.');
    return 2;
  }

  final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
  final body = jsonEncode({
    'to': token,
    'notification': {
      'title': 'Test Notification',
      'body': 'This is a test message from example/tools/send_fcm_test.dart'
    },
    'data': {'source': 'example_send_script'}
  });

  final req = await HttpClient().postUrl(uri);
  req.headers.set('Content-Type', 'application/json');
  req.headers.set('Authorization', 'key=$serverKey');
  req.write(body);

  final resp = await req.close();
  final respBody = await resp.transform(utf8.decoder).join();
  stdout.writeln('Status: ${resp.statusCode}');
  stdout.writeln(respBody);
  return resp.statusCode == 200 ? 0 : 1;
}
