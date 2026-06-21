import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:form_fields/form_fields.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';

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

// Background wrapper with Workmanager's expected signature. Returns true
// on success so Workmanager treats the task as completed.
@pragma('vm:entry-point')
Future<bool> workmanagerFlushBackgroundHandler(
    String task, Map<String, dynamic>? inputData) async {
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
          'workmanagerFlushBackgroundHandler invoked: $task input=$inputData');
    }
    await flushPendingSubmissions(submitHandler: defaultSubmitHandler);
    return true;
  } catch (e, st) {
    logger.w('workmanagerFlushBackgroundHandler failed: $e\n$st');
    return false;
  }
}

// Example worker: send current location
@pragma('vm:entry-point')
Future<bool> sendCurrentLocationBackgroundHandler(
    String task, Map<String, dynamic>? inputData) async {
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('sendCurrentLocationBackgroundHandler invoked: $task');
    }

    // Attempt to retrieve a real location when possible. Background
    // isolates may not be able to prompt for permissions, so this
    // function falls back to a deterministic mock when permission
    // is unavailable.
    double lat = 0.0;
    double lng = 0.0;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        // Can't request permission from background isolate; fall back
        // to inputData or mock.
        if (inputData != null && inputData['location'] is Map) {
          final loc = Map<String, dynamic>.from(inputData['location']);
          lat = (loc['lat'] is num) ? (loc['lat'] as num).toDouble() : 0.0;
          lng = (loc['lng'] is num) ? (loc['lng'] as num).toDouble() : 0.0;
        } else {
          final now = DateTime.now().millisecondsSinceEpoch;
          lat = 37.4219999 + (now % 100) / 10000.0;
          lng = -122.0840575 - (now % 100) / 10000.0;
        }
      } else {
        // Permission is granted — fetch current position.
        final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.best));
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (e) {
      // Any platform/plugin error falls back to mock/inputData.
      if (inputData != null && inputData['location'] is Map) {
        final loc = Map<String, dynamic>.from(inputData['location']);
        lat = (loc['lat'] is num) ? (loc['lat'] as num).toDouble() : 0.0;
        lng = (loc['lng'] is num) ? (loc['lng'] as num).toDouble() : 0.0;
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        lat = 37.4219999 + (now % 100) / 10000.0;
        lng = -122.0840575 - (now % 100) / 10000.0;
      }
    }

    final payload = {
      'type': 'location',
      'lat': lat,
      'lng': lng,
      'ts': DateTime.now().toIso8601String(),
    };

    await DBService.instance.insertOrUpdate('pending_submissions', {
      'payload': json.encode(payload),
      'status': _kStatusPending,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'worker: send_current_location queued';
      WorkmanagerService.instance.notifyPendingChanged();
    } catch (_) {}

    return true;
  } catch (e, st) {
    logger.w('sendCurrentLocationBackgroundHandler failed: $e\n$st');
    return false;
  }
}

// Foreground helper for UI-invoked immediate send
Future<void> sendCurrentLocationForeground() async {
  try {
    // Request permission from the foreground isolate when necessary.
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      logger.w('Location permission denied; cannot fetch location');
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best));
    await sendCurrentLocationBackgroundHandler('foreground', {
      'location': {'lat': pos.latitude, 'lng': pos.longitude}
    });
    // Attempt an immediate foreground flush to send any pending items.
    try {
      await FlushApi.flushPendingSubmissions(
          waitIfFlushing: true, waitTimeout: const Duration(seconds: 15));
    } catch (_) {}
    try {
      WorkmanagerService.instance.notifyPendingChanged();
    } catch (_) {}
  } catch (e, st) {
    logger.w('sendCurrentLocationForeground failed: $e\n$st');
  }
}

// Example worker: send random event
@pragma('vm:entry-point')
Future<bool> sendRandomBackgroundHandler(
    String task, Map<String, dynamic>? inputData) async {
  try {
    if (kDebugMode) {
      // ignore: avoid_print
      print('sendRandomBackgroundHandler invoked: $task');
    }

    final rnd = (DateTime.now().millisecondsSinceEpoch % 10000);
    final payload = {
      'type': 'random_event',
      'value': rnd,
      'ts': DateTime.now().toIso8601String(),
    };

    await DBService.instance.insertOrUpdate('pending_submissions', {
      'payload': json.encode(payload),
      'status': _kStatusPending,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'worker: send_random queued value=$rnd';
      WorkmanagerService.instance.notifyPendingChanged();
    } catch (_) {}

    return true;
  } catch (e, st) {
    logger.w('sendRandomBackgroundHandler failed: $e\n$st');
    return false;
  }
}

Future<void> sendRandomForeground() async {
  try {
    await sendRandomBackgroundHandler('foreground', null);
    // Try to flush pending items immediately after enqueueing.
    try {
      await FlushApi.flushPendingSubmissions(
          waitIfFlushing: true, waitTimeout: const Duration(seconds: 15));
    } catch (_) {}
    try {
      WorkmanagerService.instance.notifyPendingChanged();
    } catch (_) {}
  } catch (e, st) {
    logger.w('sendRandomForeground failed: $e\n$st');
  }
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
