import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/pending_upload_store.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pending_store');
    file = File('${dir.path}/pending.json');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('missing file reads as empty', () async {
    expect(await PendingUploadStore(file).read(), isEmpty);
  });

  test('round-trips records through the file', () async {
    final store = PendingUploadStore(file);
    await store.write([
      {'uploadCorrelationId': 'a', 'link': 'http://x/1'},
      {'uploadCorrelationId': 'b'},
    ]);
    final records = await PendingUploadStore(file).read();
    expect(records.map((r) => r['uploadCorrelationId']), ['a', 'b']);
    expect(file.existsSync(), isTrue);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('corrupt file is discarded instead of throwing', () async {
    file.writeAsStringSync('{not json');
    expect(await PendingUploadStore(file).read(), isEmpty);
  });

  test('last queued write wins', () async {
    final store = PendingUploadStore(file);
    final first = store.write([
      {'n': 1},
    ]);
    final second = store.write([
      {'n': 2},
    ]);
    await Future.wait([first, second]);
    expect((await store.read()).single['n'], 2);
  });
}
