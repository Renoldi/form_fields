import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'crypto_utils.dart';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'column_handler.dart';

final _phLog = Logger('PayloadHandler');

const String payloadDirName = 'payloads';

/// Read payload file content as string. Returns null if file does not exist.
Future<String?> readPayloadString(String filename) async {
  try {
    final documents = await getApplicationDocumentsDirectory();
    final file = File(p.join(documents.path, payloadDirName, filename));
    if (!await file.exists()) return null;
    return await file.readAsString();
  } catch (e) {
    _phLog.warning('Failed to read payload file $filename: $e');
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
    if (val is String && val.isNotEmpty) {
      try {
        final documents = await getApplicationDocumentsDirectory();
        final file = File(p.join(documents.path, payloadDirName, val));
        if (await file.exists()) await file.delete();
      } catch (e) {
        _phLog.warning('FileBackedColumnHandler:onDelete failed: $e');
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
          final safeName = p.basename(existing);
          final filenameRe = RegExp(r'^[A-Za-z0-9._-]+\$');
          if (!filenameRe.hasMatch(safeName)) {
            _phLog.warning('Rejected unsafe existing filename: $existing');
            throw Exception('unsafe_filename');
          }

          final documents = await getApplicationDocumentsDirectory();
          final dir = Directory(p.join(documents.path, payloadDirName));
          await dir.create(recursive: true);
          final filePath = p.join(dir.path, safeName);
          String content;
          if (payload is String) {
            final s = payload.trim();
            if (s.startsWith('{') || s.startsWith('[')) {
              try {
                json.decode(s);
                content = s;
              } catch (_) {
                content = json.encode(payload);
              }
            } else {
              content = json.encode(payload);
            }
          } else {
            content = json.encode(payload);
          }

          final tmpPath = p.join(
            dir.path,
            '$safeName.tmp.${Random.secure().nextInt(1 << 32).toRadixString(16)}',
          );
          final tmpFile = File(tmpPath);
          await tmpFile.writeAsString(content);
          final targetFile = File(filePath);
          try {
            if (await targetFile.exists()) {
              await targetFile.delete();
            }
            await tmpFile.rename(filePath);
          } catch (e) {
            try {
              await tmpFile.copy(filePath);
              await tmpFile.delete();
            } catch (e2) {
              _phLog.warning(
                'Failed to atomically overwrite $filePath: $e / $e2',
              );
              rethrow;
            }
          }
          _phLog.info('Overwrote payload file: $safeName');
          return safeName;
        } catch (e) {
          if (e.toString().contains('unsafe_filename')) {
          } else {
            _phLog.warning('FileBackedColumnHandler:overwrite failed: $e');
          }
        }
      }
    }

    if (value is String) {
      final strim = value.trim();
      if (!(strim.startsWith('{') || strim.startsWith('['))) {
        return value;
      }
    }
    try {
      final documents = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(documents.path, payloadDirName));
      await dir.create(recursive: true);
      String content;
      if (value is String) {
        final s = value.trim();
        if (s.startsWith('{') || s.startsWith('[')) {
          try {
            json.decode(s);
            content = s;
          } catch (_) {
            content = json.encode(value);
          }
        } else {
          content = json.encode(value);
        }
      } else {
        content = json.encode(value);
      }

      final hash = CryptoUtils.instance.bytesSha256(utf8.encode(content));
      final safePrefix = prefix; // caller should manage prefix semantics
      final name = '${safePrefix}_$hash.json';
      final filePath = p.join(dir.path, name);
      final file = File(filePath);

      if (await file.exists()) {
        if (overwriteOnDedupe) {
          try {
            final tmpPath2 = p.join(
              dir.path,
              '$name.tmp.${Random.secure().nextInt(1 << 32).toRadixString(16)}',
            );
            final tmpFile2 = File(tmpPath2);
            await tmpFile2.writeAsString(content);
            try {
              await file.delete();
              await tmpFile2.rename(filePath);
            } catch (e) {
              try {
                await tmpFile2.copy(filePath);
                await tmpFile2.delete();
              } catch (e2) {
                _phLog.warning(
                  'Failed to overwrite existing $filePath: $e / $e2',
                );
                rethrow;
              }
            }
            _phLog.info('Overwrote payload file (dedupe overwrite): $name');
            return name;
          } catch (e) {
            _phLog.warning('Failed to overwrite existing payload $name: $e');
            return name;
          }
        }
        _phLog.info('Payload dedupe: file already exists: $name');
        return name;
      }

      final tmpPath = p.join(
        dir.path,
        '$name.tmp.${Random.secure().nextInt(1 << 32).toRadixString(16)}',
      );
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsString(content);
      try {
        if (await file.exists()) {
          if (overwriteOnDedupe) {
            try {
              await file.delete();
              await tmpFile.rename(filePath);
              _phLog.info('Overwrote payload file (concurrent writer): $name');
              return name;
            } catch (e) {
              try {
                if (!await file.exists()) {
                  await tmpFile.copy(filePath);
                }
                await tmpFile.delete();
                _phLog.info('Wrote payload file after concurrent race: $name');
                return name;
              } catch (e2) {
                _phLog.warning(
                  'Failed to write payload file $filePath: $e / $e2',
                );
                rethrow;
              }
            }
          }
          _phLog.info('Concurrent writer created $name; discarding tmp file');
          await tmpFile.delete();
          return name;
        }
        await tmpFile.rename(filePath);
      } catch (e) {
        try {
          if (!await file.exists()) {
            await tmpFile.copy(filePath);
          }
          await tmpFile.delete();
        } catch (e2) {
          _phLog.warning('Failed to write payload file $filePath: $e / $e2');
          rethrow;
        }
      }
      _phLog.info('Wrote payload file: $name');
      return name;
    } catch (e) {
      _phLog.warning('FileBackedColumnHandler:onWrite failed: $e');
      rethrow;
    }
  }
}
