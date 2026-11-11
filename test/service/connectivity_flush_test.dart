import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/db_service.dart';
import 'package:form_fields/src/service/init_service.dart';
import 'package:form_fields/src/service/workmanager_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/platform_mocks.dart';

const _methodChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
const _eventChannelName = 'dev.fluttercommunity.plus/connectivity_status';
const _codec = StandardMethodCodec();

/// What `checkConnectivity()` reports; changed by each test.
List<String> _current = const ['wifi'];

void _emit(List<String> result) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        _eventChannelName,
        _codec.encodeSuccessEnvelope(result),
        null,
      );
}

void main() {
  late Directory dir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = tempDir('connectivity');
    mockDocumentsDirectory(dir);
    mockAssets(const {});
    _current = const ['wifi'];

    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    binding.setMockMethodCallHandler(_methodChannel, (call) async {
      if (call.method == 'check') return _current;
      return null;
    });
    // EventChannel listen/cancel arrive as method calls on the message channel.
    binding.setMockMessageHandler(_eventChannelName, (message) async {
      return _codec.encodeSuccessEnvelope(null);
    });
    await DBService.instance.close();
  });

  tearDown(() async {
    await WorkmanagerService.instance.stopConnectivityFlush();
    WorkmanagerService.instance.foregroundFlushHandler = null;
    await DBService.instance.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> start({
    bool useConnectivity = true,
    Future<void> Function()? flush,
  }) {
    return FormFieldsInitializer.initAll(
      dbName: 'conn_${DateTime.now().microsecondsSinceEpoch}.db',
      enableWorkmanager: false,
      useConnectivity: useConnectivity,
      foregroundFlushHandler: flush,
    );
  }

  test(
    'listens for connectivity even when enableWorkmanager is false',
    () async {
      await start();
      expect(WorkmanagerService.instance.isConnectivityFlushActive, isTrue);
    },
  );

  test('does not listen when useConnectivity is false', () async {
    await start(useConnectivity: false);
    expect(WorkmanagerService.instance.isConnectivityFlushActive, isFalse);
  });

  test('explicit foregroundFlushHandler is the one that runs', () async {
    var runs = 0;
    Future<void> flush() async => runs++;
    await start(flush: flush);
    expect(WorkmanagerService.instance.foregroundFlushHandler, same(flush));
  });

  test('network returning runs the flush exactly once per event', () async {
    var runs = 0;
    await start(flush: () async => runs++);

    _emit(const ['wifi']);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(runs, 1);
  });

  test('going offline does not run the flush', () async {
    var runs = 0;
    await start(flush: () async => runs++);

    _current = const ['none'];
    _emit(const ['none']);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(runs, 0);
  });

  test('returning to the foreground runs the flush when online', () async {
    var runs = 0;
    await start(flush: () async => runs++);
    _current = const ['wifi'];

    final binding = TestWidgetsFlutterBinding.instance;
    // Flutter returns from the background via `inactive` before `resumed`.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(runs, 1);
  });

  test('returning to the foreground while offline does not flush', () async {
    var runs = 0;
    await start(flush: () async => runs++);
    _current = const ['none'];

    final binding = TestWidgetsFlutterBinding.instance;
    // Flutter returns from the background via `inactive` before `resumed`.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(runs, 0, reason: 'offline resume must not spend retry attempts');
  });

  test('adding a pending row while online runs the flush', () async {
    var runs = 0;
    await start(flush: () async => runs++);
    _current = const ['wifi'];

    WorkmanagerService.instance.notifyPendingAdded();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(runs, 1);
  });

  test('adding a pending row while offline does not flush', () async {
    var runs = 0;
    await start(flush: () async => runs++);
    _current = const ['none'];

    WorkmanagerService.instance.notifyPendingAdded();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(runs, 0);
  });

  test('notifyPendingChanged alone never starts a flush', () async {
    var runs = 0;
    await start(flush: () async => runs++);
    _current = const ['wifi'];

    WorkmanagerService.instance.notifyPendingChanged();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(runs, 0, reason: 'post-send notifications must not loop');
  });

  test('starting twice keeps a single listener', () async {
    await start();
    WorkmanagerService.instance.startConnectivityFlush();
    expect(WorkmanagerService.instance.isConnectivityFlushActive, isTrue);
  });

  test('stopping one worker leaves the connectivity flush running', () async {
    var runs = 0;
    await start(flush: () async => runs++);

    await WorkmanagerService.instance.stop(taskName: 'form_fields_flush');

    expect(WorkmanagerService.instance.isConnectivityFlushActive, isTrue);
    expect(WorkmanagerService.instance.foregroundFlushHandler, isNotNull);
    _current = const ['wifi'];
    WorkmanagerService.instance.notifyPendingAdded();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(
      runs,
      1,
      reason: 'pending rows must still flush after a worker stop',
    );
  });

  test('stopConnectivityFlush turns the listener off', () async {
    await start();
    await WorkmanagerService.instance.stopConnectivityFlush();
    expect(WorkmanagerService.instance.isConnectivityFlushActive, isFalse);
  });
}
