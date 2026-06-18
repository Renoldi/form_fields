import 'dart:convert';

import 'column_handler.dart';

/// Optional decoder used to resolve payload columns. Receives the raw
/// stored string, table and column and should return the decoded value
/// (or null if not applicable).
typedef PayloadDecoder = Future<dynamic> Function(
    String raw, String table, String column);

typedef RowMapper<T> = T Function(Map<String, dynamic> row);

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
    final getHandlerLocal = getHandler ?? ((_, __) => null);
    final isColumnFileBackedLocal = isColumnFileBacked ?? ((_, __) => false);
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
            final fnRe =
                RegExp(r'^[A-Za-z0-9._-]+\.json$', caseSensitive: false);
            final looksLikeFilename = fnRe.hasMatch(s);
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
