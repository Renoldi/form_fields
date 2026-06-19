import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:form_fields/form_fields.dart';
import '../../data/models/post.dart';

/// Example-only helper: Process pending submissions stored in the
/// `pending_submissions` table. Host app controls how each resolved
/// payload is submitted via [submitHandler].
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
          success = await submitHandler(payload, id);
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
  } catch (e) {
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'example.flushPendingSubmissions threw: $e';
    } catch (_) {}
    return false;
  } finally {
    // FlushState.isFlushing = false;
  }
}

/// Process a single pending submission by id. Returns true on success.
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
  } catch (e) {
    try {
      WorkmanagerService.instance.lastLogListenable.value =
          'flushPendingSubmissionById threw: $e';
    } catch (_) {}
    return false;
  } finally {
    // FlushState.isFlushing = false;
  }
}
