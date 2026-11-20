import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:form_fields/src/service/crypto_utils.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _phLog = Logger('PayloadHandler');

const String payloadDirName = 'payloads';

/// Accepted payload file names: letters, digits, dot, underscore and hyphen.
final RegExp _safeFileNamePattern = RegExp(r'^[A-Za-z0-9._-]+$');

/// Returns [name] reduced to a plain file name inside the payload folder, or
/// null when it cannot be used safely. Stored names come from the database,
/// so anything with a path separator or a dot-segment is rejected.
String? _safePayloadName(String name) {
  final base = p.basename(name);
  if (base != name) return null;
  if (base == '.' || base == '..') return null;
  return _safeFileNamePattern.hasMatch(base) ? base : null;
}

Future<Directory> _payloadDir() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory(p.join(documents.path, payloadDirName));
}

/// Writes [content] to [target] through a temporary file in the same folder.
/// `rename` replaces the target atomically on POSIX platforms, so the old
/// content stays readable until the new content is fully written. Only
/// platforms where rename cannot overwrite fall back to copy.
Future<void> _writeAtomic(File target, String content) async {
  final rand = Random.secure().nextInt(1 << 32).toRadixString(16);
  final tmp = File('${target.path}.tmp.$rand');
  try {
    await tmp.writeAsString(content, flush: true);
    try {
      await tmp.rename(target.path);
    } on FileSystemException {
      await tmp.copy(target.path);
    }
  } finally {
    if (await tmp.exists()) {
      await tmp.delete();
    }
  }
}

/// Read payload file content as string. Returns null if the file does not
/// exist or the name is not a valid payload file name.
Future<String?> readPayloadString(String filename) async {
  final name = _safePayloadName(filename);
  if (name == null) {
    _phLog.warning('Rejected unsafe payload file name: $filename');
    return null;
  }
  try {
    final file = File(p.join((await _payloadDir()).path, name));
    if (!await file.exists()) return null;
    return await file.readAsString();
  } catch (e) {
    _phLog.warning('Failed to read payload file $name: $e');
    return null;
  }
}

/// Read and decode JSON payload file. Returns decoded object or null.
Future<dynamic> readPayloadJson(String filename) async {
  final s = await readPayloadString(filename);
  if (s == null) return null;
  try {
    return json.decode(s);
  } catch (e) {
    _phLog.warning('Failed to decode JSON in payload $filename: $e');
    return null;
  }
}

/// Default implementation that writes JSON payloads to disk and returns the
/// filename as the stored value. This is a standalone utility so payload
/// handling can be reused across services.
class FileBackedColumnHandler implements ColumnHandler {
  final String prefix;
  final bool overwriteOnDedupe;
  FileBackedColumnHandler({
    required this.prefix,
    this.overwriteOnDedupe = true,
  });

  @override
  Future<void> onDelete(
    String table,
    String column,
    Map<String, dynamic> row,
  ) async {
    final val = row[column];
    if (val is! String || val.isEmpty) return;
    final name = _safePayloadName(val);
    if (name == null) {
      _phLog.warning('Refused to delete unsafe payload name: $val');
      return;
    }
    try {
      final file = File(p.join((await _payloadDir()).path, name));
      if (await file.exists()) await file.delete();
    } catch (e) {
      _phLog.warning('FileBackedColumnHandler:onDelete failed: $e');
    }
  }

  @override
  Future<dynamic> onWrite(String table, String column, dynamic value) async {
    // A wrapper with an existing filename overwrites that payload file.
    if (value is Map &&
        value.containsKey('__existing_filename') &&
        value.containsKey('payload')) {
      final existing = value['__existing_filename'];
      if (existing is String && existing.isNotEmpty) {
        final name = _safePayloadName(existing);
        if (name == null) {
          _phLog.warning('Rejected unsafe existing filename: $existing');
        } else {
          try {
            final dir = await _payloadDir();
            await dir.create(recursive: true);
            final payload = value['payload'];
            final content = payload is String ? payload : json.encode(payload);
            await _writeAtomic(File(p.join(dir.path, name)), content);
            _phLog.info('Overwrote payload file: $name');
            return name;
          } catch (e) {
            _phLog.warning('FileBackedColumnHandler:overwrite failed: $e');
          }
        }
      }
    }

    // Plain strings that are not JSON documents are stored as-is.
    if (value is String) {
      final trimmed = value.trim();
      if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) {
        return value;
      }
    }

    try {
      final dir = await _payloadDir();
      await dir.create(recursive: true);
      final content = value is String ? value : json.encode(value);

      // The name is derived from the content, so identical content always maps
      // to the same file.
      final hash = CryptoUtils.instance.bytesSha256(utf8.encode(content));
      final name = '${prefix}_$hash.json';
      final file = File(p.join(dir.path, name));

      if (await file.exists()) {
        if (overwriteOnDedupe) {
          await _writeAtomic(file, content);
          _phLog.info('Overwrote payload file (dedupe overwrite): $name');
        } else {
          _phLog.info('Payload dedupe: file already exists: $name');
        }
        return name;
      }

      await _writeAtomic(file, content);
      _phLog.info('Wrote payload file: $name');
      return name;
    } catch (e) {
      _phLog.warning('FileBackedColumnHandler:onWrite failed: $e');
      rethrow;
    }
  }
}

/// ColumnHandler defines how to process a column's value on write and how to
/// cleanup when rows are deleted. Implementations live in separate helpers
/// (e.g. `payload_handler.dart`) to keep concerns separated.
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

/// Optional decoder used to resolve payload columns. Receives the raw
/// stored string, table and column and should return the decoded value
/// (or null if not applicable).
typedef PayloadDecoder =
    Future<dynamic> Function(String raw, String table, String column);

typedef RowMapper<T> = T Function(Map<String, dynamic> row);

/// A stored value that looks like a payload file name (`something.json`).
final RegExp _payloadFileNamePattern = RegExp(
  r'^[A-Za-z0-9._-]+\.json$',
  caseSensitive: false,
);

/// Small, dependency-free utilities around payload inlining and decoding.
/// This file intentionally doesn't refer to private DBService members so it
/// can be unit tested independently. Callers must provide the minimal
/// adapters (getHandler/isColumnFileBacked/readPayloadJson) to integrate
/// with their environment.
class PayloadUtils {
  /// Inline payloads for [rows] in-place.
  ///
  /// - [getHandler] should return a registered `ColumnHandler` for the
  ///   provided table/column or null.
  /// - [isColumnFileBacked] indicates whether the column name suggests a
  ///   file-backed payload when no explicit handler exists.
  /// - [readPayloadJson] should read a filename and return decoded JSON or
  ///   null if not found/decodable.
  static Future<void> inlinePayloadsForRows(
    String table,
    List<Map<String, dynamic>> rows, {
    bool inlinePayloads = true,
    PayloadDecoder? payloadDecoder,
    ColumnHandler? Function(String table, String column)? getHandler,
    bool Function(String table, String column)? isColumnFileBacked,
    Future<dynamic> Function(String filename)? readPayloadJson,
  }) async {
    if (!inlinePayloads || rows.isEmpty) return;

    // Ensure adapters are present; if missing, provide conservative defaults
    final getHandlerLocal = getHandler ?? ((key, value) => null);
    final isColumnFileBackedLocal =
        isColumnFileBacked ?? ((key, value) => false);
    final readPayloadJsonLocal = readPayloadJson ?? ((_) async => null);

    for (final r in rows) {
      for (final entry in List<MapEntry<String, dynamic>>.from(r.entries)) {
        final c = entry.key;
        final v = entry.value;
        if (v is! String) continue;

        final handler = getHandlerLocal(table, c);

        if (handler != null) {
          try {
            final decoded = payloadDecoder != null
                ? await payloadDecoder(v, table, c)
                : await readPayloadJsonLocal(v);
            if (decoded != null) {
              r[c] = decoded;
              continue;
            }
          } catch (_) {}
        } else {
          try {
            final s = v.trim();
            final looksLikeFilename = _payloadFileNamePattern.hasMatch(s);
            if (isColumnFileBackedLocal(table, c) || looksLikeFilename) {
              final decoded = payloadDecoder != null
                  ? await payloadDecoder(v, table, c)
                  : await readPayloadJsonLocal(v);
              if (decoded != null) {
                r[c] = decoded;
                continue;
              }
            }
          } catch (_) {}
        }

        try {
          final s = v.trim();
          if (s.startsWith('{') || s.startsWith('[')) {
            r[c] = json.decode(s);
          }
        } catch (_) {}
      }
    }
  }
}
