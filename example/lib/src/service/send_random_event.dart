import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:logger/logger.dart';
import 'package:form_fields/form_fields.dart';
import 'flush_service.dart';
import 'pending_submission_helper.dart';

final Logger _sendRandomLogger = Logger();

@pragma('vm:entry-point')
Future<bool> sendRandomBackgroundHandler(
  String task,
  Map<String, dynamic>? inputData,
) async {
  var acquiredHere = false;
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('sendRandomBackgroundHandler invoked: $task');
    }
    final skip = WorkmanagerService.isInCountdownInvocation;
    _sendRandomLogger.i(
      'sendRandomBackgroundHandler: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}',
    );
    acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
    if (!skip && !acquiredHere) {
      _sendRandomLogger.i(
        'sendRandomBackgroundHandler: another flush in progress — skipping',
      );
      return false;
    }

    _sendRandomLogger.i('Background handler invoked for $task');
    // Example: create and persist a random event payload for later flush.
    // final payload = {
    //   'type': 'random_event',
    //   'source': task,
    //   'value': DateTime.now().millisecondsSinceEpoch % 1000,
    //   'ts': DateTime.now().toIso8601String(),
    // };
    Post post = Post(
      userId: 1,
      title: 'Random Event',
      body:
          'Random event data: ${DateTime.now().millisecondsSinceEpoch % 1000}',
      tags: ['random', 'background'],
    );

    final id = await addPendingSubmission(post.toJson());
    if (id > 0) {
      _sendRandomLogger.i('Background inserted pending random id=$id');
    }
    // Release this handler's guard, then send what was just queued. Without
    // this, the row waits for the next run.
    if (acquiredHere) {
      WorkmanagerService.releaseFlushGuard();
      acquiredHere = false;
    }
    await processPendingSubmissions();
    return true;
  } catch (e, st) {
    _sendRandomLogger.w('Background handler failed: $e\n$st');
    return false;
  } finally {
    if (acquiredHere) WorkmanagerService.releaseFlushGuard();
  }
}

@pragma('vm:entry-point')
Future<void> sendRandomForeground() async {
  final skip = WorkmanagerService.isInCountdownInvocation;
  _sendRandomLogger.i(
    'sendRandomForeground: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}',
  );
  final acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
  if (!skip && !acquiredHere) {
    _sendRandomLogger.i(
      'sendRandomForeground: another flush in progress — skipping',
    );
    return;
  }

  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('sendRandomForeground invoked');
    }
    // _sendRandomLogger.i('Foreground handler invoked');
    // // Insert pending entry from foreground as well.
    // final payload = {
    //   'type': 'random_event',
    //   'source': 'foreground',
    //   'value': DateTime.now().millisecondsSinceEpoch % 1000,
    //   'ts': DateTime.now().toIso8601String(),
    // };

    Post post = Post(
      userId: 1,
      title: 'Random Event',
      body:
          'Random event data: ${DateTime.now().millisecondsSinceEpoch % 1000}',
      tags: ['random', 'background'],
    );

    final id = await addPendingSubmission(post.toJson());
    if (id > 0) {
      _sendRandomLogger.i('Foreground inserted pending random id=$id');
    }
  } catch (e, st) {
    _sendRandomLogger.w('Foreground handler threw: $e\n$st');
  } finally {
    if (acquiredHere) WorkmanagerService.releaseFlushGuard();
  }
}
