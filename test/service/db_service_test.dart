import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/db_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/platform_mocks.dart';

const _assets = <String, String>{
  'migrations/v1.sql': 'CREATE TABLE a (id INTEGER);',
  'migrations/v2.sql': 'CREATE TABLE b (id INTEGER);',
  'migrations/v3.sql': 'CREATE TABLE c (id INTEGER);',
  'migrations/v3_down.sql': 'DROP TABLE c;',
};

Future<List<Object?>> _tableNames(DBService db) async =>
    (await db.selectSqliteMaster()).map((r) => r['name']).toList();

void main() {
  final db = DBService.instance;
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = tempDir('db');
    mockDocumentsDirectory(dir);
    mockAssets(_assets);
    await db.close();
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('insert and select round-trip', () async {
    await db.init(dbName: 'rt.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT)',
    );
    await db.insert('items', {'id': 1, 'name': 'a'});
    final rows = await db.selectFrom('items');
    expect(rows.single['name'], 'a');
  });

  test('setUserVersion keeps the shared connection open', () async {
    final first = await db.init(dbName: 'v.db');
    await db.setUserVersion(7);
    final second = await db.init(dbName: 'v.db');
    expect(identical(first, second), isTrue);
    expect(second.isOpen, isTrue);
    expect(await db.selectDbVersion(), 7);
  });

  test('versioned migrations apply on create and on upgrade', () async {
    await db.init(
      dbName: 'm.db',
      dbVersion: 2,
      migrationAssetPaths: const [
        'migrations/v1.sql',
        'migrations/v2.sql',
        'migrations/v3.sql',
      ],
    );
    expect(await _tableNames(db), containsAll(['a', 'b']));
    expect(await _tableNames(db), isNot(contains('c')));

    await db.close();
    await db.init(
      dbName: 'm.db',
      dbVersion: 3,
      migrationAssetPaths: const [
        'migrations/v1.sql',
        'migrations/v2.sql',
        'migrations/v3.sql',
      ],
    );
    expect(await _tableNames(db), contains('c'));
    expect(await db.selectDbVersion(), 3);
  });

  test('downgrade runs the matching down asset', () async {
    const assets = [
      'migrations/v1.sql',
      'migrations/v2.sql',
      'migrations/v3.sql',
      'migrations/v3_down.sql',
    ];
    await db.init(dbName: 'd.db', dbVersion: 3, migrationAssetPaths: assets);
    await db.close();
    await db.init(dbName: 'd.db', dbVersion: 2, migrationAssetPaths: assets);
    expect(await _tableNames(db), isNot(contains('c')));
    expect(await db.selectDbVersion(), 2);
  });

  test('inline JSON in imported SQL is moved out of the row', () async {
    await db.init(dbName: 'imp.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)',
    );
    final dump = File('${dir.path}/dump.sql')
      ..writeAsStringSync(
        "INSERT INTO notes (id, body) VALUES (1, '{\"a\":1}');",
      );

    await db.importFromSqlFile(dump.path);

    final row = (await db.selectFrom('notes', inlinePayloads: false)).single;
    expect(row['body'], isNot(startsWith('{')));
  });

  test(
    'UPDATE and DELETE statements apply through the typed helpers',
    () async {
      await db.init(dbName: 'crud.db');
      await db.executeSqlInsUpDel(
        'CREATE TABLE kv (id INTEGER PRIMARY KEY, v TEXT)',
      );
      await db.executeSqlInsUpDel("INSERT INTO kv (id, v) VALUES (1, 'x')");

      await db.executeSqlInsUpDel("UPDATE kv SET v = 'y' WHERE id = 1");
      expect((await db.selectFrom('kv')).single['v'], 'y');

      final deleted = await db.executeSqlInsUpDel(
        'DELETE FROM kv WHERE id = 1',
      );
      expect(deleted, 1);
      expect(await db.selectFrom('kv'), isEmpty);
    },
  );

  test('database reopens on demand after close()', () async {
    await db.init(dbName: 're.db');
    await db.executeSqlInsUpDel('CREATE TABLE t (id INTEGER)');
    await db.close();
    await db.insert('t', {'id': 5});
    expect((await db.selectFrom('t')).single['id'], 5);
  });
}
