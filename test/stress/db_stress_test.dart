import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/column_handler.dart';
import 'package:form_fields/src/service/db_service.dart';
import 'package:form_fields/src/service/init_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/platform_mocks.dart';

class _CountingHandler implements ColumnHandler {
  int deletes = 0;

  @override
  Future<dynamic> onWrite(String table, String column, dynamic value) async =>
      value;

  @override
  Future<void> onDelete(
    String table,
    String column,
    Map<String, dynamic> row,
  ) async {
    deletes++;
  }
}

void main() {
  final db = DBService.instance;
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = tempDir('db_stress');
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

  test('20 concurrent init() calls share one connection', () async {
    final opened = await Future.wait(
      List.generate(20, (_) => db.init(dbName: 'conc.db')),
    );
    final first = opened.first;
    expect(opened.every((d) => identical(d, first)), isTrue);
    expect(first.isOpen, isTrue);
  });

  test('1000 concurrent inserts all land', () async {
    await db.init(dbName: 'ins.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)',
    );
    await Future.wait([
      for (var i = 0; i < 1000; i++) db.insert('t', {'id': i, 'v': 'row $i'}),
    ]);
    final count = (await db.selectFrom('t')).length;
    expect(count, 1000);
  });

  test(
    '500 SQL INSERT statements route through typed insert and persist',
    () async {
      await db.init(dbName: 'sqlins.db');
      await db.executeSqlInsUpDel(
        'CREATE TABLE s (id INTEGER PRIMARY KEY, v TEXT)',
      );
      for (var i = 0; i < 500; i++) {
        await db.executeSqlInsUpDel("INSERT INTO s (id, v) VALUES ($i, 'x$i')");
      }
      expect((await db.selectFrom('s')).length, 500);
    },
  );

  test('bulk import of 5000 rows with 500 inline JSON values', () async {
    await db.init(dbName: 'bulk.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE bulk (id INTEGER PRIMARY KEY, body TEXT)',
    );

    final buf = StringBuffer();
    for (var i = 0; i < 5000; i++) {
      final body = i % 10 == 0 ? '{"n":$i}' : 'plain $i';
      buf.writeln("INSERT INTO bulk (id, body) VALUES ($i, '$body');");
    }
    final dump = File('${dir.path}/bulk.sql')
      ..writeAsStringSync(buf.toString());

    final sw = Stopwatch()..start();
    await db.importFromSqlFile(dump.path);
    sw.stop();

    final rows = await db.selectFrom('bulk', inlinePayloads: false);
    expect(rows.length, 5000);
    final stillJson = rows.where((r) => (r['body'] as String).startsWith('{'));
    expect(stillJson, isEmpty, reason: 'every inline JSON must be moved out');
    expect(sw.elapsed, lessThan(const Duration(seconds: 60)));
  });

  test('deleting 2000 rows invokes the handler for each row', () async {
    await db.init(dbName: 'del.db');
    await db.executeSqlInsUpDel(
      'CREATE TABLE ev (id INTEGER PRIMARY KEY, payload TEXT)',
    );
    final handler = _CountingHandler();
    db.registerColumnHandler('ev', 'payload', handler);
    try {
      for (var i = 0; i < 2000; i++) {
        await db.insert('ev', {
          'id': i,
          'payload': 'p$i',
        }, autoHandlePayload: false);
      }
      final removed = await db.delete('ev', '1 = 1', const []);
      expect(removed, 2000);
      expect(handler.deletes, 2000);
    } finally {
      db.unregisterColumnHandler('ev', 'payload');
    }
  });

  test('delete without handlers skips the lookup and still deletes', () async {
    await db.init(dbName: 'nohandler.db');
    await db.executeSqlInsUpDel('CREATE TABLE q (id INTEGER)');
    for (var i = 0; i < 300; i++) {
      await db.insert('q', {'id': i}, autoHandlePayload: false);
    }
    expect(await db.delete('q', 'id < ?', [150]), 150);
    expect((await db.selectFrom('q')).length, 150);
  });

  test('60 close/init cycles keep the stored version intact', () async {
    await db.init(
      dbName: 'cycle.db',
      dbVersion: 2,
      migrationAssetPaths: const ['migrations/v1.sql', 'migrations/v2.sql'],
    );
    for (var i = 0; i < 60; i++) {
      await db.close();
      await db.init(
        dbName: 'cycle.db',
        dbVersion: 2,
        migrationAssetPaths: const ['migrations/v1.sql', 'migrations/v2.sql'],
      );
      expect(await db.selectDbVersion(), 2);
    }
  });

  test(
    'setUserVersion interleaved with writes never closes the connection',
    () async {
      final conn = await db.init(dbName: 'interleave.db');
      await db.executeSqlInsUpDel('CREATE TABLE z (id INTEGER)');
      for (var i = 0; i < 200; i++) {
        await db.setUserVersion(i);
        await db.insert('z', {'id': i}, autoHandlePayload: false);
      }
      expect(identical(await db.init(dbName: 'interleave.db'), conn), isTrue);
      expect(await db.selectDbVersion(), 199);
      expect((await db.selectFrom('z')).length, 200);
    },
  );

  test('20 restarts through initAll run the migrations exactly once', () async {
    final upgrades = <String>[];
    Future<void> onUpgrade(Database d, int o, int n) async {
      upgrades.add('$o->$n');
    }

    for (var i = 0; i < 20; i++) {
      await FormFieldsInitializer.initAll(
        dbName: 'restart.db',
        enableWorkmanager: false,
        migrationAssetPaths: const ['migrations/v1.sql', 'migrations/v2.sql'],
        onUpgrade: onUpgrade,
      );
      await db.close();
    }
    expect(upgrades, ['0->1', '1->2']);
  });
}
