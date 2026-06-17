import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('sequential upgrade v1 then v2 updates user_version', () async {
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

    await DBService.instance.deleteDatabaseFile(dbName: 'form_fields.db');

    // First apply v1 via version-less initAll
    await FormFieldsInitializer.initAll(
      dbName: 'form_fields.db',
      dbVersion: 0,
      migrationAssetPaths: ['migrations/v1.sql'],
      enableWorkmanager: false,
    );

    var db =
        await DBService.instance.init(dbName: 'form_fields.db', dbVersion: 1);
    var pragma = await db.rawQuery('PRAGMA user_version;');
    final pv1 = pragma.isNotEmpty ? pragma.first.values.first : null;
    // ignore: avoid_print
    print('After v1 PRAGMA: $pv1');
    expect(pv1, equals(1));

    // Now upgrade to v2 via DBService.init with dbVersion=2
    await DBService.instance.init(
        dbName: 'form_fields.db',
        dbVersion: 2,
        migrationAssetPaths: ['migrations/v1.sql', 'migrations/v2.sql']);
    db = await DBService.instance.init(dbName: 'form_fields.db', dbVersion: 2);
    pragma = await db.rawQuery('PRAGMA user_version;');
    final pv2 = pragma.isNotEmpty ? pragma.first.values.first : null;
    // ignore: avoid_print
    print('After v2 PRAGMA: $pv2');
    expect(pv2, equals(2));
  }, timeout: Timeout(Duration(minutes: 2)));
}
