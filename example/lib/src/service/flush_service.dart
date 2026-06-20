import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:form_fields/form_fields.dart';
import '../../data/models/post.dart';
import '../../main.dart';

// Top-level default submit handler: safe to call from background isolates
@pragma('vm:entry-point')
Future<bool> defaultSubmitHandler(Map<String, dynamic> payload, int? id) async {
  try {
    final post = Post.fromJson(payload);
    final res = await Post.add(post: post);
    return res != null;
  } catch (e, st) {
    logger.w('flush submitHandler threw for id=${id ?? '-'}: $e\n$st');
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'flush handler threw for id=${id ?? '-'}: $e';
    } catch (_) {}
    return false;
  }
}

// Optional registry for selecting handlers by key (registry values must be top-level)
final Map<String, Future<bool> Function(Map<String, dynamic> payload, int? id)>
    submitHandlerRegistry = {
  'default': defaultSubmitHandler,
};

Future<bool> Function(Map<String, dynamic> payload, int? id)
    getSubmitHandlerByKey(String? key) {
  return submitHandlerRegistry[key ?? 'default'] ?? defaultSubmitHandler;
}

// Top-level helper used by Workmanager's callback dispatcher
@pragma('vm:entry-point')
Future<void> workmanagerFlushPendingHandler() async {
  if (kDebugMode) {
    // ignore: avoid_print
    print('workmanagerFlushPendingHandler invoked in isolate');
  }
  // In background isolate we must NOT rely on FlushApi.register (that's
  // registered in the UI isolate). Call the concrete implementation that
  // reads DB rows and invokes the submit handler directly.
  await flushPendingSubmissions(submitHandler: defaultSubmitHandler);
}

// Top-level background task handler matching Workmanager's signature.
// This is registered as the background handler so WorkmanagerService can
// obtain a callback handle and include it with scheduled tasks. The
// background isolate will resolve this handler and invoke it directly.
@pragma('vm:entry-point')
Future<bool> backgroundTaskHandler(
    String task, Map<String, dynamic>? inputData) async {
  try {
    // Directly call the implementation that accesses DB in this isolate.
    await flushPendingSubmissions(submitHandler: defaultSubmitHandler);
    return true;
  } catch (e) {
    return false;
  }
}

@pragma('vm:entry-point')
Future<bool> processPendingSubmissions({SubmitHandler? submitHandler}) async {
  // Use injected handler if provided, otherwise use top-level default.
  final handler = submitHandler ?? defaultSubmitHandler;

  try {
    logger.i('Invoking flushPendingSubmissions');
    final result =
        await FlushApi.flushPendingSubmissions(submitHandler: handler);

    final statusMsg = result ? 'success' : 'failure';
    logger.i('processPendingSubmissions -> $statusMsg');
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'processPendingSubmissions -> $statusMsg';
    } catch (_) {}

    return result;
  } catch (e, st) {
    logger.w('processPendingSubmissions threw: $e\n$st');
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'processPendingSubmissions threw: $e';
    } catch (_) {}
    return false;
  }
}

/// Example-only helper: Process pending submissions stored in the
/// `pending_submissions` table. Host app controls how each resolved
/// payload is submitted via [submitHandler].
@pragma('vm:entry-point')
Future<bool> flushPendingSubmissions(
    {Future<bool> Function(Map<String, dynamic> payload, int? id)?
        submitHandler}) async {
  // Prevent concurrent flushes from running in parallel (foreground + background).
  // If a flush is already in progress, return false to indicate no-op.
  // if (FlushState.isFlushing) return false;
  // FlushState.isFlushing = true;
  try {
    final rows = await DBService.instance.selectFrom('pending_submissions',
        where: "status = ?", whereArgs: ['pending'], orderBy: 'created_at ASC');
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'example.flushPendingSubmissions invoked: rows=${rows.length}';
    } catch (_) {}

    for (final row in rows) {
      final id = row['id'] as int?;
      final payloadRaw = row['payload'];
      Map<String, dynamic> payload = {};

      if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      } else if (payloadRaw is String) {
        final trimmed = payloadRaw.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          try {
            payload = json.decode(payloadRaw) as Map<String, dynamic>;
          } catch (_) {
            payload = {};
          }
        } else {
          try {
            final docs = await getApplicationDocumentsDirectory();
            final file = File(path.join(docs.path, 'payloads', payloadRaw));
            if (await file.exists()) {
              final content = await file.readAsString();
              payload = json.decode(content) as Map<String, dynamic>;
            } else {
              payload = {};
            }
          } catch (_) {
            payload = {};
          }
        }
      }

      if (payload.isEmpty) continue;

      var success = false;
      if (submitHandler != null) {
        try {
          if (kDebugMode) {
            // ignore: avoid_print
            print('calling submitHandler for id=$id payload=$payload');
          }
          success = await submitHandler(payload, id);
          if (kDebugMode) {
            // ignore: avoid_print
            print('submitHandler result for id=$id -> $success');
          }
        } catch (_) {
          success = false;
        }
      }

      if (success && id != null) {
        await DBService.instance.delete('pending_submissions', 'id = ?', [id]);
        try {
          WorkmanagerService.instance.notifyPendingChanged();
        } catch (_) {}
        try {
          WorkmanagerService.instance.lastLogListenable.value =
              'example.flushed pending id=$id';
        } catch (_) {}
      }
    }

    return true;
  } catch (e, st) {
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'example.flushPendingSubmissions threw: $e\n$st';
    } catch (_) {}
    return false;
  } finally {
    // FlushState.isFlushing = false;
  }
}

/// Process a single pending submission by id. Returns true on success.
@pragma('vm:entry-point')
Future<bool> flushPendingSubmissionById(int id,
    {Future<bool> Function(Map<String, dynamic> payload, int? id)?
        submitHandler}) async {
  // Prevent concurrent flushes from running in parallel.
  // if (FlushState.isFlushing) return false;
  // FlushState.isFlushing = true;
  try {
    final rows = await DBService.instance.selectFrom('pending_submissions',
        where: 'id = ? AND status = ?', whereArgs: [id, 'pending']);
    if (rows.isEmpty) {
      try {
        WorkmanagerService.instance.lastLogListenable.value =
            'flushPendingSubmissionById: no pending row for id=$id';
      } catch (_) {}
      return false;
    }

    final row = rows.first;
    final payloadRaw = row['payload'];
    Map<String, dynamic> payload = {};

    if (payloadRaw is Map) {
      payload = Map<String, dynamic>.from(payloadRaw);
    } else if (payloadRaw is String) {
      final trimmed = payloadRaw.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          payload = json.decode(payloadRaw) as Map<String, dynamic>;
        } catch (_) {
          payload = {};
        }
      }
    }

    if (payload.isEmpty) return false;

    var success = false;
    if (submitHandler != null) {
      try {
        success = await submitHandler(payload, id);
      } catch (_) {
        success = false;
      }
    } else {
      try {
        final post = Post.fromJson(payload);
        final res = await Post.add(post: post);
        success = res != null;
      } catch (_) {
        success = false;
      }
    }

    if (success) {
      await DBService.instance.delete('pending_submissions', 'id = ?', [id]);
      try {
        WorkmanagerService.instance.notifyPendingChanged();
      } catch (_) {}
      try {
        WorkmanagerService.instance.lastLogListenable.value =
            'example.flushed pending id=$id';
      } catch (_) {}
      return true;
    }

    return false;
  } catch (e, st) {
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'flushPendingSubmissionById threw: $e\n$st';
    } catch (_) {}
    return false;
  } finally {
    // FlushState.isFlushing = false;
  }
}
