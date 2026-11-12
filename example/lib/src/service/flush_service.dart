import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'submission_retry_policy.dart';
export 'send_current_location.dart';
export 'send_random_event.dart';

// Lightweight, example-only flush service. Keep this file small,
// well-documented and easy to reuse in host apps.

final Logger _logger = Logger();

const String _kPendingTable = 'pending_submissions';
const String _kStatusPending = 'pending';
const String _kPayloadsDir = 'payloads';
const String _kRetryTable = 'pending_submission_retries';
const SubmissionRetryPolicy _kRetryPolicy = SubmissionRetryPolicy();

/// A row being sent is marked `sending:<epoch-ms>` so no other flush (in this
/// isolate or a WorkManager isolate) sends it at the same time.
const String _kClaimPrefix = 'sending:';
const Duration _kClaimTimeout = Duration(minutes: 5);

@pragma('vm:entry-point')
Future<void> workmanagerFlushPendingHandler() async {
  if (kDebugMode) {
    // ignore: avoid_print
    print('workmanagerFlushPendingHandler invoked in isolate');
  }
  await processPendingSubmissions();
}

@pragma('vm:entry-point')
Future<bool> workmanagerFlushBackgroundHandler(
  String task,
  Map<String, dynamic>? inputData,
) async {
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('workmanagerFlushBackgroundHandler invoked: $task');
    }
    await processPendingSubmissions();
    return true;
  } catch (e, st) {
    _logger.w('workmanagerFlushBackgroundHandler failed: $e\n$st');
    return false;
  }
}

/// Convenience wrapper used by UI/background entry points.
/// Returns true when processing completed without unhandled errors.
Future<bool> processPendingSubmissions({SubmitHandler? submitHandler}) async {
  final handler = submitHandler ?? defaultSubmitHandler;
  try {
    _logger.i('processPendingSubmissions: invoking flush');
    final ok = await flushPendingSubmissions(submitHandler: handler);
    _logger.i('processPendingSubmissions -> ${ok ? 'success' : 'failure'}');
    await _scheduleNextRetry(submitHandler);
    return ok;
  } catch (e, st) {
    _logger.w('processPendingSubmissions threw: $e\n$st');
    return false;
  }
}

/// In-app timer for the next backoff retry. Without workers nothing else
/// wakes the app up when a failed submission becomes due, so a flush that
/// leaves rows in backoff schedules itself for the earliest due time.
Timer? _retryTimer;

Future<void> _scheduleNextRetry(SubmitHandler? submitHandler) async {
  _retryTimer?.cancel();
  _retryTimer = null;
  try {
    final due = (await _nextAttemptById()).values;
    if (due.isEmpty) return;
    final earliest = due.reduce(math.min);
    final wait = earliest - DateTime.now().millisecondsSinceEpoch;
    final delay =
        Duration(milliseconds: math.max(0, wait)) + const Duration(seconds: 1);
    _logger.i('next retry in $delay');
    _retryTimer = Timer(
      delay,
      () => processPendingSubmissions(submitHandler: submitHandler),
    );
  } catch (e, st) {
    _logger.w('scheduling retry failed: $e\n$st');
  }
}

@pragma('vm:entry-point')
Future<bool> defaultSubmitHandler(Map<String, dynamic> payload, int? id) async {
  try {
    // Example default: map to Post model and call Post.add()
    // Host apps should inject their own handler for production.
    final post = Post.fromJson(payload);
    final res = await Post.add(post: post);
    return res != null;
  } catch (e, st) {
    _logger.w('defaultSubmitHandler threw for id=${id ?? '-'}: $e\n$st');
    return false;
  }
}

/// Simplified flush: attempts to acquire a single process-wide guard
/// and processes pending rows sequentially. This function is intentionally
/// small and deterministic so apps can reuse it or adapt easily.
Future<bool> flushPendingSubmissions({
  SubmitHandler? submitHandler,
  // legacy compatibility: accept but ignore polling semantics
  bool waitIfFlushing = false,
  Duration? waitTimeout,
  bool skipGuard = false,
  bool skipFlushStateGuard = false,
}) async {
  final skip =
      skipGuard ||
      skipFlushStateGuard ||
      WorkmanagerService.isInCountdownInvocation;
  _logger.i(
    'flushPendingSubmissions: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}',
  );
  final acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
  if (!skip && !acquiredHere) {
    _logger.i('flushPendingSubmissions: another flush in progress — skipping');
    return false;
  }

  try {
    await _withSchemaRetry(_releaseStaleClaims);
    final rows = await _withSchemaRetry(_fetchPendingRows);
    if (rows.isEmpty) {
      _logger.i('flushPendingSubmissions: no pending rows');
      return true;
    }

    final handler = submitHandler ?? defaultSubmitHandler;
    for (final row in rows) {
      try {
        final processed = await _processPendingRow(row, handler);
        if (processed) {
          _logger.i('flushed pending id=${row['id']}');
        }
      } catch (e, st) {
        _logger.w('error processing row id=${row['id']}: $e\n$st');
        await _recordFailure(row['id'] as int?, e);
        // continue processing remaining rows — best-effort
      }
    }

    return true;
  } catch (e, st) {
    _logger.w('flushPendingSubmissions threw: $e\n$st');
    return false;
  } finally {
    if (acquiredHere) WorkmanagerService.releaseFlushGuard();
  }
}

@pragma('vm:entry-point')
Future<bool> flushPendingSubmissionById(
  int id, {
  SubmitHandler? submitHandler,
  bool skipGuard = false,
}) async {
  final acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skipGuard);
  if (!skipGuard && !acquiredHere) return false;
  try {
    final rows = await DBService.instance.selectFrom(
      _kPendingTable,
      where: 'id = ? AND status = ?',
      whereArgs: [id, _kStatusPending],
    );
    if (rows.isEmpty) return false;
    if (!await _claimRow(id)) return false;

    try {
      final payload = await _decodePayload(rows.first['payload']);
      if (payload.isEmpty) {
        await _releaseRow(id);
        return false;
      }

      final handler = submitHandler ?? defaultSubmitHandler;
      final success = await _invokeHandler(handler, payload, id);
      if (!success) {
        await _releaseRow(id);
        await _recordFailure(id, 'submit returned false');
        return false;
      }

      await DBService.instance.delete(_kPendingTable, 'id = ?', [id]);
      await _clearRetry(id);
    } catch (_) {
      await _releaseRow(id);
      rethrow;
    }
    try {
      WorkmanagerService.instance.notifyPendingChanged();
    } catch (_) {}
    return true;
  } catch (e, st) {
    _logger.w('flushPendingSubmissionById threw: $e\n$st');
    return false;
  } finally {
    if (acquiredHere) WorkmanagerService.releaseFlushGuard();
  }
}

/// Runs [op]; if the pending table is missing (`no such table`), re-applies the
/// schema-only migration (`CREATE TABLE IF NOT EXISTS`, safe to repeat) and
/// retries once. Any other error is rethrown unchanged.
Future<T> _withSchemaRetry<T>(Future<T> Function() op) async {
  try {
    return await op();
  } catch (e) {
    if (!e.toString().contains('no such table')) rethrow;
    _logger.w('Pending schema missing, re-applying migrations: $e');
    await DBService.instance.runMigrationAsset('migrations/migration.sql');
    return op();
  }
}

Future<List<Map<String, dynamic>>> _fetchPendingRows() async {
  try {
    final rows = await DBService.instance.selectFrom(
      _kPendingTable,
      where: 'status = ?',
      whereArgs: [_kStatusPending],
      orderBy: 'created_at ASC',
    );
    final nextAttempt = await _nextAttemptById();
    final now = DateTime.now().millisecondsSinceEpoch;
    return rows.cast<Map<String, dynamic>>().where((row) {
      final next = nextAttempt[row['id']];
      return next == null || next <= now;
    }).toList();
  } catch (e, st) {
    _logger.w('Failed to fetch pending rows: $e\n$st');
    return <Map<String, dynamic>>[];
  }
}

Future<void> _ensureRetryTable() async {
  await DBService.instance.executeSqlInsUpDel(
    'CREATE TABLE IF NOT EXISTS $_kRetryTable ('
    'id INTEGER PRIMARY KEY, attempts INTEGER NOT NULL, '
    'next_attempt_at INTEGER NOT NULL, last_error TEXT)',
  );
}

/// id -> epoch millis of the next allowed attempt, for rows that have failed.
Future<Map<dynamic, int>> _nextAttemptById() async {
  await _ensureRetryTable();
  final rows = await DBService.instance.selectFrom(
    _kRetryTable,
    columns: ['id', 'next_attempt_at'],
  );
  return {for (final r in rows) r['id']: (r['next_attempt_at'] as num).toInt()};
}

/// Counts a failed attempt. Schedules the next try with exponential backoff,
/// or marks the submission as failed once the attempts are used up.
Future<void> _recordFailure(int? id, Object? error) async {
  if (id == null) return;
  await _ensureRetryTable();
  final existing = await DBService.instance.selectFrom(
    _kRetryTable,
    where: 'id = ?',
    whereArgs: [id],
  );
  final attempts =
      (existing.isEmpty ? 0 : (existing.first['attempts'] as num).toInt()) + 1;

  if (_kRetryPolicy.isExhausted(attempts)) {
    await DBService.instance.update(
      _kPendingTable,
      {'status': 'failed'},
      'id = ?',
      [id],
    );
    await _clearRetry(id);
    _logger.w('pending id=$id marked failed after $attempts attempts: $error');
    return;
  }

  final delay = _kRetryPolicy.delayAfter(attempts);
  await DBService.instance.insertOrUpdate(_kRetryTable, {
    'id': id,
    'attempts': attempts,
    'next_attempt_at': DateTime.now().add(delay).millisecondsSinceEpoch,
    'last_error': '$error',
  }, autoHandlePayload: false);
  _logger.i('pending id=$id attempt $attempts failed; retry in $delay');
}

Future<void> _clearRetry(int? id) async {
  if (id == null) return;
  await _ensureRetryTable();
  await DBService.instance.delete(_kRetryTable, 'id = ?', [id]);
}

/// Atomically marks a pending row as being sent. Returns false when another
/// flush already holds it, so the row is skipped instead of sent twice.
Future<bool> _claimRow(int id) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final changed = await DBService.instance.update(
    _kPendingTable,
    {'status': '$_kClaimPrefix$now'},
    'id = ? AND status = ?',
    [id, _kStatusPending],
  );
  return changed == 1;
}

/// Returns a row to `pending` after a failed or interrupted send.
Future<void> _releaseRow(int id) async {
  await DBService.instance.update(
    _kPendingTable,
    {'status': _kStatusPending},
    'id = ?',
    [id],
  );
}

/// Releases claims older than [_kClaimTimeout]: their flush was killed mid-send.
Future<void> _releaseStaleClaims() async {
  final claimed = await DBService.instance.selectFrom(
    _kPendingTable,
    columns: ['id', 'status'],
    where: 'status LIKE ?',
    whereArgs: ['$_kClaimPrefix%'],
  );
  final cutoff = DateTime.now().subtract(_kClaimTimeout).millisecondsSinceEpoch;
  for (final row in claimed) {
    final stamp =
        int.tryParse(
          (row['status'] as String).substring(_kClaimPrefix.length),
        ) ??
        0;
    if (stamp < cutoff) await _releaseRow(row['id'] as int);
  }
}

Future<bool> _processPendingRow(
  Map<String, dynamic> row,
  SubmitHandler handler,
) async {
  final id = row['id'] as int?;
  if (id == null || !await _claimRow(id)) return false;

  try {
    final payload = await _decodePayload(row['payload']);
    if (payload.isEmpty) {
      await _releaseRow(id);
      return false;
    }

    final success = await _invokeHandler(handler, payload, id);
    if (!success) {
      await _releaseRow(id);
      await _recordFailure(id, 'submit returned false');
      return false;
    }

    await DBService.instance.delete(_kPendingTable, 'id = ?', [id]);
    await _clearRetry(id);
  } catch (_) {
    await _releaseRow(id);
    rethrow;
  }

  try {
    WorkmanagerService.instance.notifyPendingChanged();
  } catch (_) {}
  return true;
}

Future<Map<String, dynamic>> _decodePayload(dynamic payloadRaw) async {
  if (payloadRaw is Map) return Map<String, dynamic>.from(payloadRaw);
  if (payloadRaw is! String) return {};

  final trimmed = payloadRaw.trim();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      final decoded = json.decode(payloadRaw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  try {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(path.join(docs.path, _kPayloadsDir, payloadRaw));
    if (!await file.exists()) return <String, dynamic>{};
    final content = await file.readAsString();
    final decoded = json.decode(content);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } catch (_) {
    return <String, dynamic>{};
  }
}

Future<bool> _invokeHandler(
  SubmitHandler handler,
  Map<String, dynamic> payload,
  int? id,
) async {
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('calling submitHandler for id=$id payload=$payload');
    }
    final result = await handler(payload, id);
    return result;
  } catch (e, st) {
    _logger.w('submitHandler threw for id=${id ?? '-'}: $e\n$st');
    return false;
  }
}
