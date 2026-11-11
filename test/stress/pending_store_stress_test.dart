import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/pending_upload_store.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('store_stress');
    file = File('${dir.path}/pending.json');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('200 overlapping writes: final state is the last snapshot', () async {
    final store = PendingUploadStore(file);
    final futures = <Future<void>>[];
    for (var i = 1; i <= 200; i++) {
      futures.add(
        store.write([
          for (var j = 0; j < i; j++) {'i': i, 'j': j},
        ]),
      );
    }
    await Future.wait(futures);

    final records = await PendingUploadStore(file).read();
    expect(records.length, 200);
    expect(records.every((r) => r['i'] == 200), isTrue);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('readers never observe a partially written file', () async {
    final store = PendingUploadStore(file);
    // Seed so the first read has a valid file.
    await store.write([
      {'seed': true},
    ]);

    final writes = <Future<void>>[];
    var completed = 0;
    for (var i = 1; i <= 100; i++) {
      writes.add(
        store.write([
          for (var j = 0; j < i * 20; j++) {'payload': 'x' * 200, 'j': j},
        ])..whenComplete(() => completed++),
      );
    }

    // Read while writes are in flight. A torn file would decode to nothing
    // (read() returns []), so every read must yield a non-empty list.
    final reader = PendingUploadStore(file);
    var reads = 0;
    while (completed < writes.length) {
      final r = await reader.read();
      expect(r, isNotEmpty);
      reads++;
      await Future<void>.delayed(Duration.zero);
    }
    await Future.wait(writes);
    expect(reads, greaterThan(0));
    final finalRecords = await reader.read();
    expect(finalRecords.length, 100 * 20);
  });

  test('large payload round-trips intact', () async {
    final big = List.generate(
      500,
      (i) => {'id': i, 'base64': 'A' * 4096, 'meta': 'row $i'},
    );
    final store = PendingUploadStore(file);
    await store.write(big);
    final back = await PendingUploadStore(file).read();
    expect(back.length, 500);
    expect(back[499]['meta'], 'row 499');
    expect(jsonDecode(file.readAsStringSync()), isA<List>());
  });

  test(
    'corrupt file in the middle of use is recovered by the next write',
    () async {
      final store = PendingUploadStore(file);
      file.writeAsStringSync('{broken');
      expect(await store.read(), isEmpty);
      await store.write([
        {'ok': 1},
      ]);
      expect((await store.read()).single['ok'], 1);
    },
  );
}
