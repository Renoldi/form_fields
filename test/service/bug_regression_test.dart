import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/column_handler.dart';
import 'package:form_fields/src/service/db_service.dart';
import 'package:form_fields/src/service/init_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/platform_mocks.dart';

class _CountingWrites implements ColumnHandler {
  int writes = 0;

  @override
  Future<dynamic> onWrite(String table, String column, dynamic value) async {
    writes++;
    return value;
  }

  @override
  Future<void> onDelete(
    String table,
    String column,
    Map<String, dynamic> row,
  ) async {}
}

void main() {
  final db = DBService.instance;
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = tempDir('bugs');
    mockDocumentsDirectory(dir);
    mockAssets({
      'migrations/v1.sql': 'CREATE TABLE a (id INTEGER);',
      'migrations/v2.sql': 'CREATE TABLE b (id INTEGER);',
    });
    await db.close();
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('A: a failing typed INSERT is not replayed as raw SQL', () async {
    await db.init(dbName: 'a.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE p (id INTEGER PRIMARY KEY, payload TEXT)',
    );
    final h = _CountingWrites();
    db.registerColumnHandler('p', 'payload', h);
    try {
      await db.insert('p', {'id': 1, 'payload': 'x'});
      await expectLater(
        db.executeSqlInsUpDel("INSERT INTO p (id, payload) VALUES (1, 'y')"),
        throwsA(anything),
      );
      // One typed attempt for the duplicate, not a second replay.
      expect(h.writes, 2);
    } finally {
      db.unregisterColumnHandler('p', 'payload');
    }
  });

  test('B: compound WHERE in UPDATE applies to every matching row', () async {
    await db.init(dbName: 'b.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE kv (id INTEGER PRIMARY KEY, v TEXT)',
    );
    await db.executeSqlInsUpDel("INSERT INTO kv (id, v) VALUES (1, 'a')");
    await db.executeSqlInsUpDel("INSERT INTO kv (id, v) VALUES (2, 'a')");
    await db.executeSqlInsUpDel("UPDATE kv SET v = 'z' WHERE id = 1 OR id = 2");
    final rows = await db.selectFrom('kv');
    expect(rows.map((r) => r['v']), ['z', 'z']);
  });

  test('B2: compound WHERE in DELETE removes every matching row', () async {
    await db.init(dbName: 'b2.db');
    await db.executeSqlInsUpDel('CREATE TABLE d (id INTEGER PRIMARY KEY)');
    await db.executeSqlInsUpDel('INSERT INTO d (id) VALUES (1)');
    await db.executeSqlInsUpDel('INSERT INTO d (id) VALUES (2)');
    await db.executeSqlInsUpDel('DELETE FROM d WHERE id = 1 OR id = 2');
    expect(await db.selectFrom('d'), isEmpty);
  });

  test('C: SET with an expression is evaluated, not stored as text', () async {
    await db.init(dbName: 'c.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE c (id INTEGER PRIMARY KEY, n INTEGER)',
    );
    await db.executeSqlInsUpDel('INSERT INTO c (id, n) VALUES (1, 5)');
    await db.executeSqlInsUpDel('UPDATE c SET n = n + 1 WHERE id = 1');
    expect((await db.selectFrom('c')).single['n'], 6);
  });

  test('D: NULL literal is stored as NULL, not the text NULL', () async {
    await db.init(dbName: 'd.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE nn (id INTEGER PRIMARY KEY, v TEXT)',
    );
    await db.executeSqlInsUpDel('INSERT INTO nn (id, v) VALUES (1, NULL)');
    expect((await db.selectFrom('nn')).single['v'], isNull);
  });

  test(
    'E: DDL run through executeSqlInsUpDel refreshes timestamp columns',
    () async {
      await db.init(dbName: 'e.db');
      await db.executeSqlInsUpDel(
        'CREATE TABLE t (id INTEGER PRIMARY KEY, created_at INTEGER)',
      );
      await db.insert('t', {'id': 1}); // caches "has created_at"
      await db.executeSqlInsUpDel('DROP TABLE t');
      await db.executeSqlInsUpDel('CREATE TABLE t (id INTEGER PRIMARY KEY)');
      // Must not fail with "no column named created_at".
      await db.insert('t', {'id': 2});
      expect((await db.selectFrom('t')).single['id'], 2);
    },
  );

  test(
    'G: created_at/updated_at are set on writes without payload columns',
    () async {
      await db.init(dbName: 'g.db');
      await db.executeSqlInsUpDel(
        'CREATE TABLE ts (id INTEGER PRIMARY KEY, created_at INTEGER, updated_at INTEGER, v TEXT)',
      );
      await db.insert('ts', {'id': 1, 'v': 'a'});
      var row = (await db.selectFrom('ts')).single;
      // insert() is a create: it sets created_at only.
      expect(row['created_at'], isNotNull);
      expect(row['updated_at'], isNull);

      await db.update('ts', {'v': 'b'}, 'id = ?', [1]);
      row = (await db.selectFrom('ts')).single;
      expect(row['updated_at'], isNotNull);
    },
  );

  test('F: a migration that fails is retried on the next start', () async {
    // v2's asset is missing on the first start, so it fails to load.
    mockAssets({'migrations/v1.sql': 'CREATE TABLE a (id INTEGER);'});
    await FormFieldsInitializer.initAll(
      dbName: 'f.db',
      enableWorkmanager: false,
      migrationAssetPaths: const ['migrations/v1.sql', 'migrations/v2.sql'],
    );
    await db.close();
    // The asset appears; the next start must apply it.
    // A new process would load assets fresh; drop the cached failure.
    rootBundle.evict('migrations/v2.sql');
    mockAssets({
      'migrations/v1.sql': 'CREATE TABLE a (id INTEGER);',
      'migrations/v2.sql': 'CREATE TABLE b (id INTEGER);',
    });
    await FormFieldsInitializer.initAll(
      dbName: 'f.db',
      enableWorkmanager: false,
      migrationAssetPaths: const ['migrations/v1.sql', 'migrations/v2.sql'],
    );
    final names = (await db.selectSqliteMaster()).map((r) => r['name']);
    expect(names, contains('b'));
  });

  test('G: upgrading from v1 applies only v2 and records version 2', () async {
    // First start: only v1 exists, so the DB is recorded at version 1.
    await FormFieldsInitializer.initAll(
      dbName: 'g.db',
      enableWorkmanager: false,
      migrationAssetPaths: const ['migrations/v1.sql'],
    );
    await db.close();

    // Second start ships v2. Re-running v1 (CREATE TABLE a) would fail, so
    // the upgrade must skip it.
    await FormFieldsInitializer.initAll(
      dbName: 'g.db',
      enableWorkmanager: false,
      migrationAssetPaths: const ['migrations/v1.sql', 'migrations/v2.sql'],
    );

    expect(await db.selectDbVersion(), 2);
    final names = (await db.selectSqliteMaster()).map((r) => r['name']);
    expect(names, containsAll(['a', 'b']));
  });
}
