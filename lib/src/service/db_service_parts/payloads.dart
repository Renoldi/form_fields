part of '../db_service.dart';

extension _DBServicePayloadsX on DBService {
  ColumnHandler? _getHandler(String table, String column) {
    final byTable = _columnHandlers[table]?[column];
    if (byTable != null) return byTable;
    return _columnHandlers['*']?[column];
  }

  /// Columns of [table] with a handler, including wildcard (`*`) handlers.
  Set<String> _handledColumnsFor(String table) {
    return {...?_columnHandlers[table]?.keys, ...?_columnHandlers['*']?.keys};
  }

  bool _looksLikeJsonString(dynamic v) {
    if (v is! String) return false;
    final s = v.trim();
    return s.startsWith('{') || s.startsWith('[');
  }

  bool _isPayloadCandidate(String col, Object? value) {
    return col == 'payload' ||
        col.endsWith('_payload') ||
        value is Map ||
        value is List ||
        _looksLikeJsonString(value);
  }

  /// Returns a copy of [values] with payload-like columns converted by their
  /// handlers, plus timestamps when the table supports them.
  Future<Map<String, dynamic>> _processPayloadColumns(
    Database db,
    String table,
    Map<String, dynamic> values, {
    bool setCreated = false,
    bool setUpdated = true,
  }) async {
    if (values.isEmpty) return values;
    final result = Map<String, dynamic>.from(values);
    for (final entry in values.entries) {
      final col = entry.key;
      if (!_isPayloadCandidate(col, entry.value)) continue;
      final handler =
          _getHandler(table, col) ??
          payload_handler.FileBackedColumnHandler(prefix: table);
      try {
        result[col] = await handler.onWrite(table, col, entry.value);
      } catch (e, st) {
        _log.warning('Handler onWrite failed for $table.$col: $e', e, st);
      }
    }
    // Timestamps apply to every write, not only writes with payload columns.
    await _ensureTimestamps(
      db,
      table,
      result,
      setCreated: setCreated,
      setUpdated: setUpdated,
    );
    return result;
  }

  /// Deletes the payload files of [rows] for [columns] that no row still
  /// refers to. Payload files are named by content, so one file can back
  /// several rows; deleting it for one row would break the others.
  Future<void> _releaseUnreferencedPayloads(
    DatabaseExecutor db,
    String table,
    List<Map<String, Object?>> rows,
    Set<String> columns,
  ) async {
    for (final row in rows) {
      for (final col in columns) {
        final value = row[col];
        if (value is! String || value.isEmpty) continue;
        final handler = _getHandler(table, col);
        if (handler == null) continue;
        try {
          if (await _isPayloadReferenced(db, value)) continue;
          await handler.onDelete(table, col, {col: value});
        } catch (e, st) {
          _log.warning('Releasing payload for $table.$col failed: $e', e, st);
        }
      }
    }
  }

  /// True when any file-backed column of any table still stores [fileName].
  Future<bool> _isPayloadReferenced(
    DatabaseExecutor db,
    String fileName,
  ) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    for (final t in tables) {
      final table = t['name'] as String;
      final info = await db.rawQuery('PRAGMA table_info("$table")');
      for (final c in info) {
        final column = c['name'] as String;
        if (!isColumnFileBacked(table, column)) continue;
        final hit = await db.rawQuery(
          'SELECT 1 FROM "$table" WHERE "$column" = ? LIMIT 1',
          [fileName],
        );
        if (hit.isNotEmpty) return true;
      }
    }
    return false;
  }

  /// The rows that share the primary key of [values]. Returns an empty list
  /// when the table has no primary key or [values] does not carry all of it.
  Future<List<Map<String, Object?>>> _rowsWithSamePrimaryKey(
    DatabaseExecutor db,
    String table,
    Map<String, dynamic> values,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info("$table")');
    final pk = info
        .where((c) => ((c['pk'] as num?) ?? 0) > 0)
        .map((c) => c['name'] as String)
        .toList();
    if (pk.isEmpty || pk.any((c) => !values.containsKey(c))) {
      return const [];
    }
    return db.query(
      table,
      where: pk.map((c) => '"$c" = ?').join(' AND '),
      whereArgs: [for (final c in pk) values[c]],
    );
  }

  /// Moves inline JSON text (`{...}` / `[...]`) out of table columns into
  /// payload files and stores the file name instead. Only rows that contain
  /// such text are read, and each table's updates share one transaction.
  Future<void> _convertInlineJsonPayloads(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );
    for (final t in tables) {
      final name = t['name'] as String?;
      if (name == null) continue;
      try {
        final info = await db.rawQuery('PRAGMA table_info("$name")');
        if (info.isEmpty) continue;
        final candidates = info
            .map((c) => c['name'] as String)
            .map((c) => 'TRIM("$c") LIKE \'{%\' OR TRIM("$c") LIKE \'[%\'')
            .join(' OR ');

        final rows = await db.rawQuery(
          'SELECT rowid AS __rowid__, * FROM "$name" WHERE $candidates',
        );
        if (rows.isEmpty) continue;

        await db.transaction((txn) async {
          for (final row in rows) {
            final updates = <String, Object?>{};
            for (final entry in row.entries) {
              final col = entry.key;
              final value = entry.value;
              if (col == '__rowid__' || value is! String) continue;
              final s = value.trim();
              if (!(s.startsWith('{') || s.startsWith('['))) continue;

              final Object? decoded;
              try {
                decoded = json.decode(s);
              } catch (_) {
                continue; // not valid JSON
              }
              final handler =
                  _getHandler(name, col) ??
                  payload_handler.FileBackedColumnHandler(prefix: name);
              try {
                updates[col] = await handler.onWrite(name, col, decoded);
              } catch (e) {
                _log.warning(
                  'Failed to write imported payload for $name.$col: $e',
                );
              }
            }
            if (updates.isNotEmpty) {
              await txn.update(
                name,
                updates,
                where: 'rowid = ?',
                whereArgs: [row['__rowid__']],
              );
            }
          }
        });
      } catch (e, st) {
        // e.g. WITHOUT ROWID tables have no rowid; skip just this table.
        _log.warning('Skipping payload conversion for $name: $e', e, st);
      }
    }
  }
}
