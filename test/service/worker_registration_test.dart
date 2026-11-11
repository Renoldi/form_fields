import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/db_service.dart';
import 'package:form_fields/src/service/init_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';

import '../support/platform_mocks.dart';

/// Records Workmanager calls instead of talking to the native plugin.
class _FakeWorkmanager extends WorkmanagerPlatform {
  final List<String> periodic = [];
  final List<String> oneOff = [];
  final Set<String> failOn = {};

  @override
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async {}

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    if (failOn.contains(uniqueName)) throw StateError('platform refused');
    periodic.add(uniqueName);
  }

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    ForegroundServiceConfig? foregroundServiceConfig,
    bool expedited = false,
  }) async {
    oneOff.add(uniqueName);
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {}
}

Future<bool> _bg(String taskName, Map<String, dynamic>? inputData) async =>
    true;

Future<bool> _bgTwo(String taskName, Map<String, dynamic>? inputData) async =>
    true;

void main() {
  late _FakeWorkmanager fake;
  late Directory dir;

  setUpAll(() {
    // `Workmanager()` installs the native platform on first construction and
    // would overwrite a fake set earlier, so construct it before faking.
    Workmanager();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    fake = _FakeWorkmanager();
    WorkmanagerPlatform.instance = fake;
    dir = tempDir('workers');
    mockDocumentsDirectory(dir);
    mockAssets(const {});
  });

  tearDown(() async {
    await DBService.instance.close();
    debugDefaultTargetPlatformOverride = null;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> start(
    List<WorkerRegistration> regs, {
    bool trigger = false,
    bool deferIos = false,
  }) {
    return FormFieldsInitializer.initAll(
      dbName: 'workers_${DateTime.now().microsecondsSinceEpoch}.db',
      enableWorkmanager: true,
      useConnectivity: false,
      workerRegistrations: regs,
      triggerWorkerHandlersOnStart: trigger,
      deferStartupHandlersOnIos: deferIos,
    );
  }

  test('each registration is scheduled under its task name', () async {
    await start([
      WorkerRegistration(taskName: 'wr_one', backgroundHandler: _bg),
      WorkerRegistration(taskName: 'wr_two', backgroundHandler: _bgTwo),
    ]);
    expect(fake.periodic, containsAll(['wr_one', 'wr_two']));
  });

  test('same handler and period is scheduled only once', () async {
    Future<void> fg() async {}
    await start([
      WorkerRegistration(taskName: 'wr_dup_a', foregroundHandler: fg),
      WorkerRegistration(taskName: 'wr_dup_b', foregroundHandler: fg),
    ]);
    expect(fake.periodic.where((n) => n.startsWith('wr_dup_')).toList(), [
      'wr_dup_a',
    ]);
  });

  test('register: false is skipped', () async {
    await start([
      WorkerRegistration(
        taskName: 'wr_off',
        backgroundHandler: _bg,
        register: false,
      ),
      WorkerRegistration(taskName: 'wr_on', backgroundHandler: _bgTwo),
    ]);
    // Control: 'wr_on' proves the fake records registrations at all.
    expect(fake.periodic, contains('wr_on'));
    expect(fake.periodic, isNot(contains('wr_off')));
  });

  test('a refused registration does not stop the others', () async {
    fake.failOn.add('wr_bad');
    await start([
      WorkerRegistration(taskName: 'wr_bad', backgroundHandler: _bg),
      WorkerRegistration(taskName: 'wr_good', backgroundHandler: _bgTwo),
    ]);
    expect(fake.periodic, contains('wr_good'));
    expect(fake.periodic, isNot(contains('wr_bad')));
  });

  test(
    'startup trigger runs foreground once and schedules a one-off run',
    () async {
      var foregroundRuns = 0;
      Future<void> fg() async => foregroundRuns++;
      await start([
        WorkerRegistration(
          taskName: 'wr_trig',
          backgroundHandler: _bg,
          foregroundHandler: fg,
        ),
      ], trigger: true);
      expect(foregroundRuns, 1);
      expect(fake.oneOff, contains('wr_trig'));
    },
  );

  test('a periodic interval below 15 minutes on Android is logged', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final records = <LogRecord>[];
    final sub = Logger.root.onRecord.listen(records.add);
    try {
      await start([
        WorkerRegistration(
          taskName: 'wr_short',
          frequency: const Duration(seconds: 30),
          backgroundHandler: _bg,
        ),
      ]);
    } finally {
      await sub.cancel();
    }
    expect(
      records.where(
        (r) => r.level == Level.WARNING && r.message.contains('wr_short'),
      ),
      isNotEmpty,
    );
  });

  test('iOS defers startup handlers by about two seconds', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var foregroundRuns = 0;
    Future<void> fg() async => foregroundRuns++;
    await start(
      [WorkerRegistration(taskName: 'wr_ios', foregroundHandler: fg)],
      trigger: true,
      deferIos: true,
    );
    expect(foregroundRuns, 0, reason: 'must not run before the delay');
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(foregroundRuns, 1);
  });
}
