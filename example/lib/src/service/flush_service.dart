import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:form_fields/form_fields.dart';
import 'package:logger/logger.dart';

// Local logger for example service helpers (avoid circular import with main)
final logger = Logger();

const String _kPendingTable = 'pending_submissions';
const String _kStatusPending = 'pending';
const String _kPayloadsDir = 'payloads';

// Background dispatch entry-point used by Workmanager. Keep it top-level
// and entry-point-safe so background isolates can resolve the callback.
@pragma('vm:entry-point')
Future<void> workmanagerFlushPendingHandler() async {
  if (kDebugMode) {
    // ignore: avoid_print
    print('workmanagerFlushPendingHandler invoked in isolate');
  }
  await flushPendingSubmissions(submitHandler: defaultSubmitHandler);
}

// Top-level background helper that can be invoked from the UI isolate
// or from background isolates via a callback handle.
@pragma('vm:entry-point')
Future<bool> processPendingSubmissions({SubmitHandler? submitHandler}) async {
  final handler = submitHandler ?? defaultSubmitHandler;

  try {
    logger.i('Invoking flushPendingSubmissions');
    final result =
        await FlushApi.flushPendingSubmissions(submitHandler: handler);

    final statusMsg = result ? 'success' : 'failure';
    logger.i('processPendingSubmissions -> $statusMsg');
    _setLastLog('processPendingSubmissions -> $statusMsg');

    return result;
  } catch (e, st) {
    logger.w('processPendingSubmissions threw: $e\n$st');
    _setLastLog('processPendingSubmissions threw: $e');
    return false;
  }
}

// Top-level default submit handler: safe to call from background isolates
@pragma('vm:entry-point')
Future<bool> defaultSubmitHandler(Map<String, dynamic> payload, int? id) async {
  try {
    final post = Post.fromJson(payload);
    final res = await Post.add(post: post);
    return res != null;
  } catch (e, st) {
    logger.w('flush submitHandler threw for id=${id ?? '-'}: $e\n$st');
    _setLastLog('flush handler threw for id=${id ?? '-'}: $e');
    return false;
  }
}

// Optional registry for selecting handlers by key (registry values must be top-level)
final Map<String, SubmitHandler> submitHandlerRegistry = {
  'default': defaultSubmitHandler,
};

SubmitHandler getSubmitHandlerByKey(String? key) {
  return submitHandlerRegistry[key ?? 'default'] ?? defaultSubmitHandler;
}

// Helper: decode stored payload (may be Map, JSON string or a filename).
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

void _setLastLog(String msg) {
  try {
    WorkmanagerService.instance.lastLogListenable.value = msg;
  } catch (_) {}
}

// Helper: invoke a SubmitHandler with logging and error-safety.
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
    if (kDebugMode) {
      // ignore: avoid_print
      print('submitHandler result for id=$id -> $result');
    }
    return result;
  } catch (e, st) {
    logger.w('submitHandler threw for id=${id ?? '-'}: $e\n$st');
    return false;
  }
}

/// Example-only helper: Process pending submissions stored in the
/// `pending_submissions` table. Host app controls how each resolved
/// payload is submitted via [submitHandler].
@pragma('vm:entry-point')
Future<bool> flushPendingSubmissions({
  SubmitHandler? submitHandler,
  bool skipFlushStateGuard = false,
}) async {
  if (!skipFlushStateGuard) {
    if (FlushState.isFlushing) return false;
    FlushState.isFlushing = true;
  }

  try {
    final rows = await _fetchPendingRows();
    _setLastLog('example.flushPendingSubmissions invoked: rows=${rows.length}');

    final handler = submitHandler ?? defaultSubmitHandler;
    for (final row in rows) {
      final processed = await _processPendingRow(row, handler);
      if (processed) _setLastLog('example.flushed pending id=${row['id']}');
    }

    return true;
  } catch (e, st) {
    _setLastLog('example.flushPendingSubmissions threw: $e\n$st');
    logger.w('flushPendingSubmissions threw: $e\n$st');
    return false;
  } finally {
    if (!skipFlushStateGuard) FlushState.isFlushing = false;
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
    logger.w('Failed to fetch pending rows: $e\n$st');
    return <Map<String, dynamic>>[];
  }
}

Future<bool> _processPendingRow(
  Map<String, dynamic> row,
  SubmitHandler handler,
) async {
  final id = row['id'] as int?;
  try {
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
  } catch (e, st) {
    logger.w('Failed processing pending row id=$id: $e\n$st');
    return false;
  }
}

/// Process a single pending submission by id. Returns true on success.
@pragma('vm:entry-point')
Future<bool> flushPendingSubmissionById(int id,
    {SubmitHandler? submitHandler, bool skipFlushStateGuard = false}) async {
  // Prevent concurrent flushes from running in parallel.
  var acquiredHere = false;
  if (!skipFlushStateGuard) {
    if (FlushState.isFlushing) return false;
    FlushState.isFlushing = true;
    acquiredHere = true;
  }
  try {
    final rows = await DBService.instance.selectFrom('pending_submissions',
        where: 'id = ? AND status = ?', whereArgs: [id, 'pending']);
    if (rows.isEmpty) {
      _setLastLog('flushPendingSubmissionById: no pending row for id=$id');
      return false;
    }

    final row = rows.first;
    final payload = await _decodePayload(row['payload']);
    if (payload.isEmpty) return false;

    final handler = submitHandler ?? defaultSubmitHandler;
    final success = await _invokeHandler(handler, payload, id);

    if (success) {
      await DBService.instance.delete('pending_submissions', 'id = ?', [id]);
      try {
        WorkmanagerService.instance.notifyPendingChanged();
      } catch (_) {}
      _setLastLog('example.flushed pending id=$id');
      return true;
    }

    return false;
  } catch (e, st) {
    _setLastLog('flushPendingSubmissionById threw: $e\n$st');
    return false;
  } finally {
    if (acquiredHere) FlushState.isFlushing = false;
  }
}
