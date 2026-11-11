import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/src/service/flush_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('flush_claim');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => call.method == 'getApplicationDocumentsDirectory'
              ? dir.path
              : null,
        );
    await DBService.instance.close();
    await DBService.instance.init(
      dbName: 'claim_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await DBService.instance.executeSqlInsUpDel(
      'CREATE TABLE IF NOT EXISTS pending_submissions ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, payload TEXT NOT NULL, '
      'status TEXT NOT NULL, created_at INTEGER NOT NULL)',
    );
  });

  tearDown(() async {
    await DBService.instance.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> addPending(String title) =>
      DBService.instance.insert('pending_submissions', {
        'payload': '{"id":null,"title":"$title","body":"b","userId":1}',
        'status': 'pending',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

  test(
    'a row is sent once when two flushes overlap (countdown path)',
    () async {
      await addPending('ONCE');
      final sent = <int?>[];
      Future<bool> submit(Map<String, dynamic> payload, int? id) async {
        sent.add(id);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return true;
      }

      // skipGuard mirrors the countdown path, which bypasses the flush guard.
      await Future.wait([
        flushPendingSubmissions(submitHandler: submit, skipGuard: true),
        flushPendingSubmissions(submitHandler: submit, skipGuard: true),
      ]);

      expect(
        sent,
        hasLength(1),
        reason: 'duplicate send = duplicate server post',
      );
    },
  );

  test('a claim left behind by a killed flush is released and sent', () async {
    await DBService.instance.insert('pending_submissions', {
      'payload': '{"id":null,"title":"STALE","body":"b","userId":1}',
      'status': 'sending:0', // claimed at the epoch, long past the timeout
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    final sent = <int?>[];
    Future<bool> submit(Map<String, dynamic> payload, int? id) async {
      sent.add(id);
      return true;
    }

    await flushPendingSubmissions(submitHandler: submit, skipGuard: true);

    expect(sent, hasLength(1));
  });

  test('a row claimed by another flush is not sent again', () async {
    await addPending('CLAIMED');
    final sent = <int?>[];
    Future<bool> submit(Map<String, dynamic> payload, int? id) async {
      sent.add(id);
      return true;
    }

    // First flush sends and removes the row; a later flush must find nothing.
    await flushPendingSubmissions(submitHandler: submit, skipGuard: true);
    await flushPendingSubmissions(submitHandler: submit, skipGuard: true);

    expect(sent, hasLength(1));
  });
}
