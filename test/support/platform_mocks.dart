import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Points `getApplicationDocumentsDirectory()` at [dir] for the test.
void mockDocumentsDirectory(Directory dir) {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') return dir.path;
        return null;
      });
}

/// Serves `rootBundle` assets from [assets] (asset key -> file contents).
void mockAssets(Map<String, String> assets) {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        final content = assets[key];
        if (content == null) return null;
        final bytes = utf8.encode(content);
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      });
}

/// Creates a fresh temporary directory for one test.
Directory tempDir(String name) =>
    Directory.systemTemp.createTempSync('form_fields_$name');
