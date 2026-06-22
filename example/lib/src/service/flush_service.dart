import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
export 'send_current_location.dart';
export 'send_random_event.dart';

// Lightweight, example-only flush service. Keep this file small,
// well-documented and easy to reuse in host apps.

final Logger _logger = Logger();

const String _kPendingTable = 'pending_submissions';
const String _kStatusPending = 'pending';
const String _kPayloadsDir = 'payloads';

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
    String task, Map<String, dynamic>? inputData) async {
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
    return ok;
  } catch (e, st) {
    _logger.w('processPendingSubmissions threw: $e\n$st');
    return false;
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
  final skip = skipGuard ||
      skipFlushStateGuard ||
      WorkmanagerService.isInCountdownInvocation;
  _logger.i(
      'flushPendingSubmissions: skip=$skip isFlushing=${WorkmanagerService.isFlushing} guardSetAt=${WorkmanagerService.flushGuardSetAt} inCountdown=${WorkmanagerService.isInCountdownInvocation}');
  final acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skip);
  if (!skip && !acquiredHere) {
    _logger.i('flushPendingSubmissions: another flush in progress — skipping');
    return false;
  }

  try {
    final rows = await _fetchPendingRows();
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
Future<bool> flushPendingSubmissionById(int id,
    {SubmitHandler? submitHandler, bool skipGuard = false}) async {
  final acquiredHere = WorkmanagerService.acquireFlushGuard(skip: skipGuard);
  if (!skipGuard && !acquiredHere) return false;
  try {
    final rows = await DBService.instance.selectFrom(_kPendingTable,
        where: 'id = ? AND status = ?', whereArgs: [id, _kStatusPending]);
    if (rows.isEmpty) return false;

    final row = rows.first;
    final payload = await _decodePayload(row['payload']);
    if (payload.isEmpty) return false;

    final handler = submitHandler ?? defaultSubmitHandler;
    final success = await _invokeHandler(handler, payload, id);
    if (!success) return false;

    await DBService.instance.delete(_kPendingTable, 'id = ?', [id]);
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

Future<List<Map<String, dynamic>>> _fetchPendingRows() async {
  try {
    final rows = await DBService.instance.selectFrom(
      _kPendingTable,
      where: 'status = ?',
      whereArgs: [_kStatusPending],
      orderBy: 'created_at ASC',
    );
    return rows.cast<Map<String, dynamic>>();
  } catch (e, st) {
    _logger.w('Failed to fetch pending rows: $e\n$st');
    return <Map<String, dynamic>>[];
  }
}

Future<bool> _processPendingRow(
  Map<String, dynamic> row,
  SubmitHandler handler,
) async {
  final id = row['id'] as int?;
  final payload = await _decodePayload(row['payload']);
  if (payload.isEmpty) return false;

  final success = await _invokeHandler(handler, payload, id);
  if (!success) return false;

  if (id != null) {
    await DBService.instance.delete(_kPendingTable, 'id = ?', [id]);
    try {
      WorkmanagerService.instance.notifyPendingChanged();
    } catch (_) {}
  }
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
