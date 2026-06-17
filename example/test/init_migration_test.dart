import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialize ffi implementation for sqflite in test environment.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('initAll with dbVersion 0 applies migrations and sets user_version',
      () async {
    // Provide a mock for path_provider so tests can locate a documents dir.
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

    // Ensure clean state
    await DBService.instance.deleteDatabaseFile(dbName: 'form_fields.db');

    // Initialize with dbVersion == 0 and migration asset present in example/pubspec
    await FormFieldsInitializer.initAll(
      dbName: 'form_fields.db',
      dbVersion: 0,
      migrationAssetPaths: ['migrations/v1.sql', 'migrations/v2.sql'],
      enableWorkmanager: false,
      onCreate: (db, v) async {
        // Print to test output for verification
        // ignore: avoid_print
        print('onCreate invoked with version: $v');
      },
    );

    // Re-open DB with dbVersion 2 to avoid automatic downgrade
    final db =
        await DBService.instance.init(dbName: 'form_fields.db', dbVersion: 2);

    final pragma = await db.rawQuery('PRAGMA user_version;');
    final pv = pragma.isNotEmpty ? pragma.first.values.first : null;
    // ignore: avoid_print
    print('PRAGMA user_version: $pv');

    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");
    // ignore: avoid_print
    print('Tables: $tables');

    expect(pv, equals(2));
    expect(tables, isNotEmpty);
  }, timeout: Timeout(Duration(minutes: 2)));
}
