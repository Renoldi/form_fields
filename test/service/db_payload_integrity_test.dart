import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/db_service.dart';
import 'package:form_fields/src/service/payload_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/platform_mocks.dart';

void main() {
  final db = DBService.instance;
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = tempDir('db_integrity');
    mockDocumentsDirectory(dir);
    mockAssets(const {});
    await db.close();
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test(
    'deleting one row keeps the payload of another row with the same content',
    () async {
      await db.init(dbName: 'share.db');
      await db.executeSqlInsUpDel(
        'CREATE TABLE forms (id INTEGER PRIMARY KEY, data TEXT)',
      );
      db.registerColumnHandler(
        'forms',
        'data',
        FileBackedColumnHandler(prefix: 'forms'),
      );

      // Identical JSON content: both rows point at one shared payload file.
      const json = {'answer': 'yes', 'items': [1, 2, 3]};
      await db.insert('forms', {'id': 1, 'data': json});
      await db.insert('forms', {'id': 2, 'data': json});

      await db.delete('forms', 'id = ?', [1]);

      final survivor = await db.selectOneFrom(
        'forms',
        where: 'id = ?',
        whereArgs: [2],
      );
      expect(survivor, isNotNull);
      expect(survivor!['data'], json);
    },
  );

  test(
    'replacing a row payload removes the old payload file it no longer uses',
    () async {
      await db.init(dbName: 'orphan.db');
      await db.executeSqlInsUpDel(
        'CREATE TABLE forms (id INTEGER PRIMARY KEY, data TEXT)',
      );
      db.registerColumnHandler(
        'forms',
        'data',
        FileBackedColumnHandler(prefix: 'forms'),
      );
      await db.insert('forms', {
        'id': 1,
        'data': {'v': 1},
      });
      await db.update('forms', {
        'data': {'v': 2},
      }, 'id = ?', [1]);

      final payloadDir = Directory('${dir.path}/$payloadDirName');
      final files = payloadDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();
      // Only the file for the current value remains.
      expect(files, hasLength(1));
      final current = await db.selectOneFrom(
        'forms',
        where: 'id = ?',
        whereArgs: [1],
      );
      expect(current!['data'], {'v': 2});
    },
  );

  test('an export and import keeps text values that contain semicolons',
      () async {
    await db.init(dbName: 'semi.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)',
    );
    const body = 'first; second; third';
    await db.insert('notes', {'id': 1, 'body': body});

    final dump = File('${dir.path}/notes.sql');
    await db.exportToSqlFile(dump.path);
    await db.executeSqlInsUpDel('DELETE FROM notes');
    await db.importFromSqlFile(dump.path);

    final row = await db.selectOneFrom('notes', where: 'id = ?', whereArgs: [1]);
    expect(row, isNotNull, reason: 'the row was dropped on import');
    expect(row!['body'], body);
  });

  test('a migration with a trigger keeps the trigger body whole', () async {
    mockAssets(const {
      'migrations/trigger.sql': '''
-- the trigger body has its own semicolons
CREATE TABLE items (id INTEGER PRIMARY KEY);
CREATE TABLE audit (msg TEXT);
CREATE TRIGGER items_ai AFTER INSERT ON items
BEGIN
  INSERT INTO audit (msg) VALUES ('added; logged');
END;
''',
    });
    await db.init(dbName: 'trigger.db');
    await db.runMigrationAsset('migrations/trigger.sql');

    await db.executeSqlInsUpDel('INSERT INTO items (id) VALUES (1)');
    final audit = await db.selectFrom('audit');
    expect(audit.single['msg'], 'added; logged');
  });
}
