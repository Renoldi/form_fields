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

Map<String, dynamic> _persisted(String corr) => {
  'uploadCorrelationId': corr,
  'file': {'path': '/stress/$corr.jpg'},
};

void main() {
  final mgr = OfflineUploadManager.instance;
  late Directory dir;
  late File file;

  setUp(() {
    mgr.resetForTesting();
    dir = Directory.systemTemp.createTempSync('pending_stress');
    file = File('${dir.path}/pending.json');
  });

  tearDown(() {
    mgr.resetForTesting();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('flood of unmatched successes stays capped at 100, keeps newest', () {
    final sw = Stopwatch()..start();
    for (var i = 0; i < 5000; i++) {
      mgr.notifyUploadSuccess(_persisted('f$i'), _resp('http://u/$i'));
    }
    sw.stop();

    expect(mgr.pendingCount, 100);
    // Newest entries survive: register a controller holding the last one.
    final c = FormFieldsMyImageController(
      initialImages: [MyImageResult(path: '/stress/f4999.jpg')],
    );
    mgr.registerController(c);
    expect(c.images.first.status, MyImageStatus.uploaded);
    expect(mgr.pendingCount, 99);
    mgr.unregisterController(c);
    c.dispose();
    expect(sw.elapsed, lessThan(const Duration(seconds: 10)));
  });

  test('retry storm on one correlation id never duplicates the entry', () {
    for (var i = 0; i < 10000; i++) {
      mgr.notifyUploadSuccess(_persisted('same'), _resp('http://u/$i'));
    }
    expect(mgr.pendingCount, 1);
  });

  test('many pending entries apply to a large controller in one pass', () {
    // Buffer cap is 100, so the largest batch that can be pending is 100.
    const n = 100;
    for (var i = 0; i < n; i++) {
      mgr.notifyUploadSuccess(_persisted('p$i'), _resp('http://u/$i'));
    }
    expect(mgr.pendingCount, n);

    final images = [
      for (var i = 0; i < 2000; i++)
        MyImageResult(path: i < n ? '/stress/p$i.jpg' : '/other/$i.jpg'),
    ];
    final c = FormFieldsMyImageController(initialImages: images);
    final sw = Stopwatch()..start();
    mgr.registerController(c);
    sw.stop();

    expect(mgr.pendingCount, 0);
    final uploaded = c.images
        .where((img) => img.status == MyImageStatus.uploaded)
        .length;
    expect(uploaded, n);
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    mgr.unregisterController(c);
    c.dispose();
  });

  test('setImages churn with pending entries neither loops nor leaks', () {
    mgr.notifyUploadSuccess(_persisted('churn'), _resp('http://u/c'));
    final c = FormFieldsMyImageController();
    mgr.registerController(c);
    // The first replacement applies the pending success (it is then removed).
    c.setImages([MyImageResult(path: '/stress/churn.jpg')]);
    expect(c.images.single.status, MyImageStatus.uploaded);
    expect(mgr.pendingCount, 0);
    // Later replacements must not loop or resurrect anything.
    for (var i = 0; i < 1000; i++) {
      c.setImages([MyImageResult(path: '/stress/churn.jpg')]);
    }
    expect(mgr.pendingCount, 0);
    mgr.unregisterController(c);
    c.dispose();
  });

  test('register and unregister cycles do not accumulate listeners', () {
    final c = FormFieldsMyImageController();
    for (var i = 0; i < 500; i++) {
      mgr.registerController(c);
      mgr.registerController(c); // idempotent: second call is a no-op
      mgr.unregisterController(c);
    }
    // After the last unregister, a change must not trigger any apply.
    mgr.notifyUploadSuccess(_persisted('after'), _resp('http://u/a'));
    c.setImages([MyImageResult(path: '/stress/after.jpg')]);
    expect(mgr.pendingCount, 1);
    c.dispose();
  });

  test('persisted file stays consistent with memory under churn', () async {
    await mgr.restorePending(file);
    for (var i = 0; i < 300; i++) {
      mgr.notifyUploadSuccess(_persisted('d$i'), _resp('http://u/$i'));
    }
    final expected = mgr.pendingCount;
    await mgr.pendingWritesFlushed;
    final list = jsonDecode(file.readAsStringSync()) as List;
    expect(list.length, expected);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });
}
