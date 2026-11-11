import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/workmanager_service.dart';
import 'package:workmanager/workmanager.dart';

/// Records one-off registrations instead of calling the native plugin.
class _FakeWorkmanager extends WorkmanagerPlatform {
  final List<String> oneOff = [];

  @override
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async {}

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

void main() {
  late _FakeWorkmanager fake;

  setUpAll(() {
    // `Workmanager()` installs the native platform on first construction and
    // would overwrite a fake set earlier, so construct it before faking.
    Workmanager();
  });

  setUp(() {
    fake = _FakeWorkmanager();
    WorkmanagerPlatform.instance = fake;
  });

  test('one-off runs are not kept in the registered task list', () async {
    final service = WorkmanagerService.instance;
    final before = service.registeredTaskNames.length;

    for (var i = 0; i < 3; i++) {
      await service.runOnceNowDetailed(taskName: 'one_off_$i');
    }

    expect(fake.oneOff, hasLength(3), reason: 'each run is still scheduled');
    expect(
      service.registeredTaskNames.length,
      before,
      reason: 'the list does not grow with every one-off run',
    );
  });

  test('the flush guard cannot be taken over while it is held', () {
    expect(WorkmanagerService.acquireFlushGuard(), isTrue);
    try {
      // Another flush must be refused, however long the first one runs.
      expect(WorkmanagerService.acquireFlushGuard(), isFalse);
    } finally {
      WorkmanagerService.releaseFlushGuard();
    }
    expect(WorkmanagerService.acquireFlushGuard(), isTrue);
    WorkmanagerService.releaseFlushGuard();
  });
}
