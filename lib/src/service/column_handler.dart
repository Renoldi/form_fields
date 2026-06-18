import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'crypto_utils.dart';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _chLog = Logger('ColumnHandler');

const String _payloadDirName = 'payloads';

/// ColumnHandler defines how to process a column's value on write and how to
/// cleanup when rows are deleted.
abstract class ColumnHandler {
  /// Called before insert/update. Should return the value to be stored
  /// in the database (e.g., a filename) and may perform side-effects like
  /// writing files.
  Future<dynamic> onWrite(String table, String column, dynamic value);

  /// Called before the row is deleted. [row] contains the full row values as
  /// returned from the DB query. Implementations should cleanup any side
  /// effects (e.g., delete files).
  Future<void> onDelete(String table, String column, Map<String, dynamic> row);
}

/// Default implementation that writes JSON payloads to disk and returns the
/// filename as the stored value.
class FileBackedColumnHandler implements ColumnHandler {
  final String prefix;
  final bool overwriteOnDedupe;
  FileBackedColumnHandler(
      {required this.prefix, this.overwriteOnDedupe = true});

  @override
  Future<void> onDelete(
      String table, String column, Map<String, dynamic> row) async {
    final val = row[column];
    if (val is String && val.isNotEmpty) {
      try {
        final documents = await getApplicationDocumentsDirectory();
        final file = File(p.join(documents.path, _payloadDirName, val));
        if (await file.exists()) await file.delete();
      } catch (e) {
        _chLog.warning('FileBackedColumnHandler:onDelete failed: $e');
      }
    }
  }

  @override
  Future<dynamic> onWrite(String table, String column, dynamic value) async {
    // If caller passed an existing filename wrapper, overwrite the file.
    if (value is Map &&
        value.containsKey('__existing_filename') &&
        value.containsKey('payload')) {
      final existing = value['__existing_filename'];
      final payload = value['payload'];
      if (existing is String && existing.isNotEmpty) {
        try {
          // Normalize to basename to avoid path traversal and ensure files
          // are written inside the payloads directory only.
          final safeName = p.basename(existing);
          // Restrict allowed characters in filenames to a conservative set.
          final filenameRe = RegExp(r'^[A-Za-z0-9._-]+$');
          if (!filenameRe.hasMatch(safeName)) {
            _chLog.warning('Rejected unsafe existing filename: $existing');
            // fallthrough to creating a new deterministic file
            throw Exception('unsafe_filename');
          }

          final documents = await getApplicationDocumentsDirectory();
          final dir = Directory(p.join(documents.path, _payloadDirName));
          await dir.create(recursive: true);
          final filePath = p.join(dir.path, safeName);
          final content = payload is String ? payload : json.encode(payload);

          // Atomic write: write to a temp file then rename into place.
          final tmpPath = p.join(dir.path,
              '$safeName.tmp.${Random.secure().nextInt(1 << 32).toRadixString(16)}');
          final tmpFile = File(tmpPath);
          await tmpFile.writeAsString(content);
          final targetFile = File(filePath);
          try {
            if (await targetFile.exists()) {
              // Replace atomically: remove target then rename temp.
              await targetFile.delete();
            }
            await tmpFile.rename(filePath);
          } catch (e) {
            // Best-effort fallback: try overwriting directly.
            try {
              await tmpFile.copy(filePath);
              await tmpFile.delete();
            } catch (e2) {
              _chLog.warning(
                  'Failed to atomically overwrite $filePath: $e / $e2');
              rethrow;
            }
          }
          _chLog.info('Overwrote payload file: $safeName');
          return safeName;
        } catch (e) {
          if (e.toString().contains('unsafe_filename')) {
            // continue to deterministic creation below
          } else {
            _chLog.warning('FileBackedColumnHandler:overwrite failed: $e');
          }
          // fallthrough to create new file
        }
      }
    }

    // If the caller passed a plain string, decide whether it's an
    // existing filename or a JSON payload string. Preserve existing
    // filenames (conservative filename charset); treat JSON-like strings
    // (starting with '{' or '[') as payloads to be written to disk.
    if (value is String) {
      final strim = value.trim();
      if (!(strim.startsWith('{') || strim.startsWith('['))) {
        return value;
      }
      // fallthrough: treat JSON string as payload content
    }
    try {
      final documents = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(documents.path, _payloadDirName));
      await dir.create(recursive: true);
      final content = value is String ? value : json.encode(value);

      // Use SHA-256 of the content to produce a deterministic filename and
      // avoid creating duplicate files for identical payloads. Avoid
      // repeating the table name when `prefix` already contains it
      // (some callers pass a prefix that includes the table name).
      final hash = CryptoUtils.instance.bytesSha256(utf8.encode(content));
      final safePrefix = (prefix == table || prefix.contains(table))
          ? prefix
          : '${prefix}_$table';
      final name = '${safePrefix}_$hash.json';
      final filePath = p.join(dir.path, name);
      final file = File(filePath);

      if (await file.exists()) {
        if (overwriteOnDedupe) {
          try {
            // Overwrite existing deterministic file atomically.
            final tmpPath2 = p.join(dir.path,
                '$name.tmp.${Random.secure().nextInt(1 << 32).toRadixString(16)}');
            final tmpFile2 = File(tmpPath2);
            await tmpFile2.writeAsString(content);
            try {
              // replace target
              await file.delete();
              await tmpFile2.rename(filePath);
            } catch (e) {
              try {
                await tmpFile2.copy(filePath);
                await tmpFile2.delete();
              } catch (e2) {
                _chLog.warning(
                    'Failed to overwrite existing $filePath: $e / $e2');
                rethrow;
              }
            }
            _chLog.info('Overwrote payload file (dedupe overwrite): $name');
            return name;
          } catch (e) {
            _chLog.warning('Failed to overwrite existing payload $name: $e');
            // fall back to returning existing file name
            return name;
          }
        }
        _chLog.info('Payload dedupe: file already exists: $name');
        return name;
      }

      // Atomic write: write to temp then rename to final name. If another
      // writer created the file in the meantime, prefer the existing file.
      final tmpPath = p.join(dir.path,
          '$name.tmp.${Random.secure().nextInt(1 << 32).toRadixString(16)}');
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsString(content);
      try {
        // If target was created by a concurrent writer, either overwrite it
        // (when enabled) or prefer the existing file and discard tmp.
        if (await file.exists()) {
          if (overwriteOnDedupe) {
            try {
              await file.delete();
              await tmpFile.rename(filePath);
              _chLog.info('Overwrote payload file (concurrent writer): $name');
              return name;
            } catch (e) {
              try {
                if (!await file.exists()) {
                  await tmpFile.copy(filePath);
                }
                await tmpFile.delete();
                _chLog.info('Wrote payload file after concurrent race: $name');
                return name;
              } catch (e2) {
                _chLog.warning(
                    'Failed to write payload file $filePath: $e / $e2');
                rethrow;
              }
            }
          }
          _chLog.info('Concurrent writer created $name; discarding tmp file');
          await tmpFile.delete();
          return name;
        }
        await tmpFile.rename(filePath);
      } catch (e) {
        // Best-effort fallback: try to copy and delete temp.
        try {
          if (!await file.exists()) {
            await tmpFile.copy(filePath);
          }
          await tmpFile.delete();
        } catch (e2) {
          _chLog.warning('Failed to write payload file $filePath: $e / $e2');
          rethrow;
        }
      }
      _chLog.info('Wrote payload file: $name');
      return name;
    } catch (e) {
      _chLog.warning('FileBackedColumnHandler:onWrite failed: $e');
      rethrow;
    }
  }
}
