import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/controllers/form_fields_my_image_controller.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/service/offline_upload_manager.dart';
import 'package:form_fields/src/utilities/enums.dart';

Response<dynamic> _resp(String link) => Response(
  requestOptions: RequestOptions(path: '/upload'),
  data: {'fileUrl': link},
);

/// Polls until [condition] holds, so asynchronous file writes can settle.
Future<void> _eventually(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  final mgr = OfflineUploadManager.instance;
  late Directory dir;
  late File file;

  setUp(() {
    mgr.resetForTesting();
    dir = Directory.systemTemp.createTempSync('offline_mgr');
    file = File('${dir.path}/pending.json');
  });

  tearDown(() {
    mgr.resetForTesting();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('unmatched success is buffered once per correlation id', () {
    final persisted = {
      'uploadCorrelationId': 'c1',
      'file': {'path': '/tmp/a.jpg'},
    };
    mgr.notifyUploadSuccess(persisted, _resp('http://u/1'));
    mgr.notifyUploadSuccess(persisted, _resp('http://u/2'));
    expect(mgr.pendingCount, 1);
  });

  test('registering a matching controller applies and drains pending', () {
    mgr.notifyUploadSuccess({
      'uploadCorrelationId': 'c1',
      'file': {'path': '/tmp/a.jpg'},
    }, _resp('http://u/2'));
    final c = FormFieldsMyImageController(
      initialImages: [MyImageResult(path: '/tmp/a.jpg')],
    );
    mgr.registerController(c);
    expect(mgr.pendingCount, 0);
    expect(c.images.first.status, MyImageStatus.uploaded);
    expect(c.images.first.link, 'http://u/2');
    mgr.unregisterController(c);
    c.dispose();
  });

  test('controller change re-entrancy does not loop', () {
    mgr.notifyUploadSuccess({
      'uploadCorrelationId': 'c9',
      'file': {'fileName': 'z.jpg'},
    }, _resp('http://u/9'));
    final c = FormFieldsMyImageController();
    mgr.registerController(c);
    c.setImages([MyImageResult(path: '/x/z.jpg')]);
    expect(mgr.pendingCount, 0);
    expect(c.images.first.status, MyImageStatus.uploaded);
    mgr.unregisterController(c);
    c.dispose();
  });

  test('pending entries are persisted and survive a restart', () async {
    await mgr.restorePending(file);
    mgr.notifyUploadSuccess({
      'uploadCorrelationId': 'c5',
      'file': {'path': '/tmp/b.jpg'},
    }, _resp('http://u/5'));
    await _eventually(() {
      if (!file.existsSync()) return false;
      final list = jsonDecode(file.readAsStringSync()) as List;
      return list.length == 1;
    });

    // Simulate a restart: clear memory, then restore from the file.
    mgr.resetForTesting();
    expect(mgr.pendingCount, 0);
    await mgr.restorePending(file);
    expect(mgr.pendingCount, 1);

    // Once the image shows up, the restored entry is applied and removed.
    final c = FormFieldsMyImageController(
      initialImages: [MyImageResult(path: '/tmp/b.jpg')],
    );
    mgr.registerController(c);
    expect(c.images.first.link, 'http://u/5');
    await _eventually(
      () => (jsonDecode(file.readAsStringSync()) as List).isEmpty,
    );
    mgr.unregisterController(c);
    c.dispose();
  });

  test('malformed stored records are skipped on restore', () async {
    file.writeAsStringSync(
      jsonEncode([
        {'persisted': 'not a map', 'createdAt': 'x'},
        {
          'persisted': {'uploadCorrelationId': 'ok'},
          'createdAt': DateTime.now().toIso8601String(),
        },
      ]),
    );
    await mgr.restorePending(file);
    expect(mgr.pendingCount, 1);
  });
}
