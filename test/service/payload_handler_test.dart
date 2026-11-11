import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/payload_handler.dart';
import 'package:path/path.dart' as p;

import '../support/platform_mocks.dart';

void main() {
  late Directory docs;
  late Directory payloadDir;
  late FileBackedColumnHandler handler;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('payload_handler_test');
    payloadDir = Directory(p.join(docs.path, payloadDirName))
      ..createSync(recursive: true);
    mockDocumentsDirectory(docs);
    handler = FileBackedColumnHandler(prefix: 'form');
  });

  tearDown(() {
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  test('stores a JSON value and returns a content-addressed name', () async {
    final name = await handler.onWrite('t', 'c', {'a': 1}) as String;

    expect(name, startsWith('form_'));
    expect(name, endsWith('.json'));
    expect(File(p.join(payloadDir.path, name)).readAsStringSync(), '{"a":1}');
    expect(await readPayloadJson(name), {'a': 1});
  });

  test('writing identical content returns the same name', () async {
    final first = await handler.onWrite('t', 'c', {'a': 1});
    final second = await handler.onWrite('t', 'c', {'a': 1});

    expect(second, first);
  });

  test(
    'existing-filename wrapper overwrites the stored payload in place',
    () async {
      final name = await handler.onWrite('t', 'c', {'v': 1}) as String;

      final returned = await handler.onWrite('t', 'c', {
        '__existing_filename': name,
        'payload': {'v': 2},
      });

      expect(returned, name);
      expect(await readPayloadJson(name), {'v': 2});
      // No temporary files are left behind.
      expect(
        payloadDir.listSync().where((f) => f.path.contains('.tmp.')),
        isEmpty,
      );
    },
  );

  test('plain non-JSON strings are stored as-is, not as files', () async {
    final value = await handler.onWrite('t', 'c', 'hello');

    expect(value, 'hello');
    expect(payloadDir.listSync(), isEmpty);
  });

  test(
    'readPayloadString rejects names that leave the payload folder',
    () async {
      final outside = File(p.join(docs.path, 'secret.txt'))
        ..writeAsStringSync('top secret');

      expect(await readPayloadString('../secret.txt'), isNull);
      expect(await readPayloadString(outside.path), isNull);
      expect(await readPayloadString('..'), isNull);
    },
  );

  test('onDelete never removes a file outside the payload folder', () async {
    final outside = File(p.join(docs.path, 'keep.txt'))
      ..writeAsStringSync('keep me');

    await handler.onDelete('t', 'c', {'c': '../keep.txt'});

    expect(outside.existsSync(), isTrue);
  });

  test('onDelete removes a stored payload file', () async {
    final name = await handler.onWrite('t', 'c', {'a': 1}) as String;
    final file = File(p.join(payloadDir.path, name));
    expect(file.existsSync(), isTrue);

    await handler.onDelete('t', 'c', {'c': name});

    expect(file.existsSync(), isFalse);
  });
}
