import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:form_fields/form_fields.dart';

/// Example-only helper: Process pending submissions stored in the
/// `pending_submissions` table. Host app controls how each resolved
/// payload is submitted via [submitHandler].
Future<bool> flushPendingSubmissions(
    {Future<bool> Function(Map<String, dynamic> payload, int? id)?
        submitHandler}) async {
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
  }
}
