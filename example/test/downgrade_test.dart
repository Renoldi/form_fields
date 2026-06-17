import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('upgrade to v2 then downgrade to v1 applies downgrade asset', () async {
    final tmp = await Directory.systemTemp.createTemp('form_fields_test');
    const channelName = 'plugins.flutter.io/path_provider';
    final channel = const MethodChannel(channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tmp.path;
      }
      return null;
    });

    // Ensure clean DB
    await DBService.instance.deleteDatabaseFile(dbName: 'form_fields.db');

    // Perform initial version-less install applying v1 and v2
    await FormFieldsInitializer.initAll(
      dbName: 'form_fields.db',
      dbVersion: 0,
      migrationAssetPaths: ['migrations/v1.sql', 'migrations/v2.sql'],
      enableWorkmanager: false,
    );

    // Confirm we are at v2
    var db =
        await DBService.instance.init(dbName: 'form_fields.db', dbVersion: 2);
    var pragma = await db.rawQuery('PRAGMA user_version;');
    final pv = pragma.isNotEmpty ? pragma.first.values.first : null;
    // ignore: avoid_print
    print('After upgrade PRAGMA: $pv');
    expect(pv, equals(2));

    // Now initialize with target dbVersion=1 and include downgrade asset
    await DBService.instance.init(
      dbName: 'form_fields.db',
      dbVersion: 1,
      migrationAssetPaths: [
        'migrations/v1.sql',
        'migrations/v2.sql',
        'migrations/v2_down.sql'
      ],
    );

    // Reopen to confirm
    db = await DBService.instance.init(dbName: 'form_fields.db', dbVersion: 1);
    pragma = await db.rawQuery('PRAGMA user_version;');
    final pv2 = pragma.isNotEmpty ? pragma.first.values.first : null;
    // ignore: avoid_print
    print('After downgrade PRAGMA: $pv2');
    expect(pv2, equals(1));

    // Check tables: v2 tables (with triple 'sss') should be gone; v1 tables remain
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");
    // ignore: avoid_print
    print('Tables after downgrade: $tables');

    final names = tables.map((r) => r['name']).toSet();
    expect(names.contains('pending_inspections_v1'), isTrue);
    expect(names.contains('pending_inspections_v2'), isFalse);
  }, timeout: Timeout(Duration(minutes: 2)));
}
