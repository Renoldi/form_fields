import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('PendingUploadStore');

/// Durable storage for pending upload records, kept as one JSON file.
///
/// Writes are queued so they never overlap, and each write goes to a temporary
/// file that is then renamed over the target. A crash mid-write therefore
/// leaves the previous file intact.
class PendingUploadStore {
  PendingUploadStore(this.file);

  final File file;

  /// Tail of the write queue. Always completes without error.
  Future<void> _writes = Future<void>.value();

  /// Completes once every write queued so far has finished. Used by
  /// [OfflineUploadManager.pendingWritesFlushed] and by tests.
  Future<void> get flushed => _writes;

  /// Returns the stored records. A missing or unreadable file yields an empty
  /// list, so a corrupt file never blocks startup.
  Future<List<Map<String, dynamic>>> read() async {
    try {
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (e, st) {
      _log.warning('Discarding unreadable pending upload file', e, st);
      return const [];
    }
  }

  /// Replaces the stored records with [records]. The snapshot is taken
  /// immediately, so later changes to the caller's list are not written.
  Future<void> write(List<Map<String, dynamic>> records) {
    final json = jsonEncode(records);
    _writes = _writes.then((_) => _replace(json)).catchError((
      Object e,
      StackTrace st,
    ) {
      _log.warning('Failed to persist pending uploads', e, st);
    });
    return _writes;
  }

  Future<void> _replace(String json) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }
}
