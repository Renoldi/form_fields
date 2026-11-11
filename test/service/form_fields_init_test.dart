import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/db_service.dart';
import 'package:form_fields/src/service/init_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/platform_mocks.dart';

void main() {
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = tempDir('init');
    mockDocumentsDirectory(dir);
    mockAssets({
      'migrations/v1.sql': 'CREATE TABLE a (id INTEGER);',
      'migrations/v2.sql': 'CREATE TABLE b (id INTEGER);',
    });
    await DBService.instance.close();
  });

  tearDown(() async {
    await DBService.instance.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('versioned migration assets run once; later starts skip them', () async {
    final upgrades = <String>[];
    Future<void> onUpgrade(Database db, int oldV, int newV) async {
      upgrades.add('$oldV->$newV');
    }

    Future<void> start() => FormFieldsInitializer.initAll(
      dbName: 'init.db',
      enableWorkmanager: false,
      migrationAssetPaths: const ['migrations/v1.sql', 'migrations/v2.sql'],
      onUpgrade: onUpgrade,
    );

    await start();
    expect(upgrades, ['0->1', '1->2']);
    expect(await DBService.instance.selectDbVersion(), 2);

    await DBService.instance.close();
    await start();
    expect(upgrades, ['0->1', '1->2'], reason: 'second start must not re-run');
  });
}
