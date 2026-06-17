import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:convert' show utf8;

import 'crypto_utils.dart';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

final _log = Logger('DBService');

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

  FileBackedColumnHandler({required this.prefix});

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
        _log.warning('FileBackedColumnHandler:onDelete failed: $e');
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
            _log.warning('Rejected unsafe existing filename: $existing');
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
              _log.warning(
                  'Failed to atomically overwrite $filePath: $e / $e2');
              rethrow;
            }
          }
          _log.info('Overwrote payload file: $safeName');
          return safeName;
        } catch (e) {
          if (e.toString().contains('unsafe_filename')) {
            // continue to deterministic creation below
          } else {
            _log.warning('FileBackedColumnHandler:overwrite failed: $e');
          }
          // fallthrough to create new file
        }
      }
    }

    if (value is String) return value;
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, _payloadDirName));
    await dir.create(recursive: true);
    final content = value is String ? value : json.encode(value);

    // Use SHA-256 of the content to produce a deterministic filename and
    // avoid creating duplicate files for identical payloads.
    final hash = CryptoUtils.instance.bytesSha256(utf8.encode(content));
    final name = '${prefix}_${table}_$hash.json';
    final filePath = p.join(dir.path, name);
    final file = File(filePath);

    if (await file.exists()) {
      _log.info('Payload dedupe: file already exists: $name');
      return name;
    }

    // Atomic write: write to temp then rename to final name. If another
    // writer created the file in the meantime, prefer the existing file.
    final tmpPath = p.join(dir.path,
        '$name.tmp.${Random.secure().nextInt(1 << 32).toRadixString(16)}');
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsString(content);
    try {
      // If target was created by a concurrent writer, prefer it and remove tmp.
      if (await file.exists()) {
        _log.info('Concurrent writer created $name; discarding tmp file');
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
        _log.warning('Failed to write payload file $filePath: $e / $e2');
        rethrow;
      }
    }
    _log.info('Wrote payload file: $name');
    return name;
  }
}

class DBService {
  DBService._() {
    // Register default file-backed handler for any `payload` column.
    registerColumnHandler(
        '*', 'payload', FileBackedColumnHandler(prefix: 'payload'));
    // Register table-specific prefixes for common tables to produce nicer filenames.
    registerColumnHandler(
        'asset', 'payload', FileBackedColumnHandler(prefix: 'asset'));
    registerColumnHandler('master_inspection_forms', 'payload',
        FileBackedColumnHandler(prefix: 'master_inspection_forms'));
    registerColumnHandler('master_inspections', 'payload',
        FileBackedColumnHandler(prefix: 'master_inspections'));
    registerColumnHandler('pending_inspections', 'payload',
        FileBackedColumnHandler(prefix: 'pending_inspections'));
  }
  static final DBService instance = DBService._();

  // Per-call flags control automatic payload handling; global toggle removed.

  Database? _db;

  // Column handlers registry: table -> column -> handler.
  final Map<String, Map<String, ColumnHandler>> _columnHandlers = {};

  /// Register a handler for a specific `table` and `column`.
  /// Use table = '*' to register for all tables.
  void registerColumnHandler(
      String table, String column, ColumnHandler handler) {
    final map = _columnHandlers.putIfAbsent(table, () => {});
    map[column] = handler;
  }

  /// Unregister handler.
  void unregisterColumnHandler(String table, String column) {
    _columnHandlers[table]?.remove(column);
  }

  ColumnHandler? _getHandler(String table, String column) {
    // Exact table match
    final byTable = _columnHandlers[table];
    if (byTable != null && byTable.containsKey(column)) return byTable[column];
    // Wildcard table
    final wildcard = _columnHandlers['*'];
    if (wildcard != null && wildcard.containsKey(column)) {
      return wildcard[column];
    }
    return null;
  }

  /// Public check whether a handler is registered for [table].[column].
  bool hasColumnHandler(String table, String column) {
    return _getHandler(table, column) != null;
  }

  Future<Database> init(
      {String dbName = 'form_fields.db',
      List<String>? migrationAssetPaths}) async {
    if (_db != null) return _db!;
    final documents = await getApplicationDocumentsDirectory();
    final path = p.join(documents.path, dbName);
    _log.info('Opening database at $path');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      try {
        // Initialize DB from bundled migration SQL (assets/migrations/migration.sql)
        final sql = await rootBundle.loadString('migrations/migration.sql');
        final statements = sql.split(';');
        // Execute only schema-related statements from the bundled migration SQL.
        // Some migration assets may include sample data (INSERTs) which should
        // not be applied automatically during DB creation. Allow only CREATE,
        // PRAGMA, and DROP statements here and skip DML (INSERT/UPDATE/DELETE).
        final allowedRe =
            RegExp(r'^(CREATE|PRAGMA|DROP|ALTER)\b', caseSensitive: false);
        for (var stmt in statements) {
          stmt = stmt.trim();
          if (stmt.isEmpty) continue;
          final up = stmt.toUpperCase();
          // Skip transaction markers if present in the bundled SQL.
          if (up == 'BEGIN' ||
              up.startsWith('BEGIN TRANSACTION') ||
              up == 'COMMIT' ||
              up.startsWith('COMMIT')) {
            continue;
          }
          // Only run allowed schema statements during init.
          if (!allowedRe.hasMatch(stmt)) {
            _log.info(
                'Skipping non-schema statement in migration.sql: ${stmt.substring(0, min(80, stmt.length)).replaceAll('\n', ' ')}');
            continue;
          }
          try {
            await db.execute(stmt);
          } catch (e) {
            _log.warning('Failed to execute init statement: $stmt\n$e');
          }
        }
        _log.info('Database initialized from migrations/migration.sql');

        // If additional migration assets were provided, execute their schema
        // statements directly against the `db` instance. Do NOT call
        // `importFromSqlFile` here because that helper may call `init()` and
        // cause recursive initialization while we're still in `onCreate`.
        if (migrationAssetPaths != null && migrationAssetPaths.isNotEmpty) {
          for (final assetPath in migrationAssetPaths) {
            if (assetPath.trim().isEmpty) continue;
            try {
              _log.info('Loading migration asset: $assetPath');
              final content = await rootBundle.loadString(assetPath);
              final statements = content.split(';');
              for (var stmt in statements) {
                stmt = stmt.trim();
                if (stmt.isEmpty) continue;
                final up = stmt.toUpperCase();
                if (up == 'BEGIN' ||
                    up.startsWith('BEGIN TRANSACTION') ||
                    up == 'COMMIT' ||
                    up.startsWith('COMMIT')) {
                  continue;
                }
                // Only apply schema statements during initialization.
                if (!allowedRe.hasMatch(stmt)) {
                  _log.info(
                      'Skipping non-schema statement in $assetPath: ${stmt.substring(0, min(80, stmt.length)).replaceAll('\n', ' ')}');
                  continue;
                }
                try {
                  await db.execute(stmt);
                } catch (e) {
                  _log.warning(
                      'Failed to execute migration asset statement from $assetPath: $stmt\n$e');
                }
              }
              _log.info('Imported migration asset: $assetPath');
            } catch (e, st) {
              _log.warning(
                  'Failed to import migration asset [$assetPath]: $e\n$st');
            }
          }
        }

        // Note: sample/demo inserts are no longer run automatically here.
        // If example/demo data is desired, call a dedicated helper to import
        // `migrations/sample_inserts.sql` so the host can control when it runs.
      } catch (e, st) {
        _log.warning(
            'Failed to initialize DB from asset migration.sql: $e', e, st);
      }
    });
    return _db!;
  }

  Future<void> close() async => await _db?.close();

  /// Delete the on-disk database file and optionally the `migrations` folder.
  /// This will also close any open DB connection and clear the cached instance.
  Future<void> deleteDatabaseFile(
      {String dbName = 'form_fields.db',
      bool removeMigrationsDir = false,
      bool removePayloadsDir = false}) async {
    try {
      await close();
    } catch (_) {}
    _db = null;
    try {
      final documents = await getApplicationDocumentsDirectory();
      final dbPath = p.join(documents.path, dbName);
      // Prefer using sqflite's deleteDatabase to properly remove any internal
      // state before deleting files.
      try {
        await deleteDatabase(dbPath);
      } catch (e) {
        // ignore - fallback to manual deletion below
      }
      final dbFile = File(dbPath);
      if (await dbFile.exists()) await dbFile.delete();
      // Also remove SQLite companion files that may hold WAL/SHM journal data.
      final wal = File(p.join(documents.path, '$dbName-wal'));
      final shm = File(p.join(documents.path, '$dbName-shm'));
      final journal = File(p.join(documents.path, '$dbName-journal'));
      if (await wal.exists()) await wal.delete();
      if (await shm.exists()) await shm.delete();
      if (await journal.exists()) await journal.delete();
      if (removeMigrationsDir) {
        final dir = Directory(p.join(documents.path, 'migrations'));
        if (await dir.exists()) await dir.delete(recursive: true);
      }
      if (removePayloadsDir) {
        final dir = Directory(p.join(documents.path, _payloadDirName));
        if (await dir.exists()) await dir.delete(recursive: true);
      }
      _log.info('Deleted database file: ${p.join(dbName)}');
    } catch (e, st) {
      _log.warning('Failed to delete DB file: $e', e, st);
    }
  }

  /// Reset the database by deleting the file and optionally re-initializing
  /// it from bundled assets. Returns once the DB is recreated if `reinit`
  /// is true.

  Future<void> resetDatabase(
      {String dbName = 'form_fields.db',
      bool removeMigrationsDir = false,
      bool removePayloadsDir = false,
      bool reinit = true}) async {
    await deleteDatabaseFile(
        dbName: dbName,
        removeMigrationsDir: removeMigrationsDir,
        removePayloadsDir: removePayloadsDir);
    if (reinit) {
      await init(dbName: dbName);
    }
  }

  Future<int> insert(String table, Map<String, dynamic> values,
      {bool autoHandlePayload = true}) async {
    final db = _db ?? await init();

    // If per-call handlers are enabled, run registered `onWrite` handlers for each
    // column present in `values`.
    if (autoHandlePayload && values.isNotEmpty) {
      final keys = values.keys.toList();
      for (final col in keys) {
        final handler = _getHandler(table, col);
        if (handler == null) continue;
        try {
          final newVal = await handler.onWrite(table, col, values[col]);
          values = Map<String, dynamic>.from(values);
          values[col] = newVal;
          // provide created_at convenience if present
          values['created_at'] =
              values['created_at'] ?? DateTime.now().millisecondsSinceEpoch;
        } catch (e, st) {
          _log.warning('Handler onWrite failed for $table.$col: $e', e, st);
        }
      }
    }

    return await db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values, String where,
      List<dynamic> whereArgs,
      {bool autoHandlePayload = true}) async {
    final db = _db ?? await init();

    // Table-agnostic handling: if `payload` is Map/List, write file and replace
    // payload with filename before updating. Honor the per-call `autoHandlePayload` flag.
    if (autoHandlePayload && values.isNotEmpty) {
      final keys = values.keys.toList();
      for (final col in keys) {
        final handler = _getHandler(table, col);
        if (handler == null) continue;
        try {
          final newVal = await handler.onWrite(table, col, values[col]);
          values = Map<String, dynamic>.from(values);
          values[col] = newVal;
          values['created_at'] =
              values['created_at'] ?? DateTime.now().millisecondsSinceEpoch;
        } catch (e, st) {
          _log.warning('Handler onWrite failed for $table.$col: $e', e, st);
        }
      }
    }

    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs,
      {bool autoCleanupOnDelete = true}) async {
    final db = _db ?? await init();

    // Only perform cleanup if caller requested it via `autoCleanupOnDelete`.
    if (autoCleanupOnDelete) {
      try {
        final rows = await db.query(table, where: where, whereArgs: whereArgs);
        if (rows.isNotEmpty) {
          // Determine columns that have handlers for this table (including wildcard)
          final cols = <String>{};
          final byTable = _columnHandlers[table];
          if (byTable != null) cols.addAll(byTable.keys);
          final wildcard = _columnHandlers['*'];
          if (wildcard != null) cols.addAll(wildcard.keys);

          for (final r in rows) {
            for (final col in cols) {
              if (!r.containsKey(col)) continue;
              final handler = _getHandler(table, col);
              if (handler == null) continue;
              try {
                await handler.onDelete(table, col, r);
              } catch (e, st) {
                _log.warning(
                    'Handler onDelete failed for $table.$col: $e', e, st);
              }
            }
          }
        }
      } catch (e) {
        _log.warning('Failed to cleanup column handlers before delete: $e');
      }
    }

    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Read payload file content as string. Returns null if file does not exist.
  Future<String?> readPayloadString(String filename) async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final file = File(p.join(documents.path, _payloadDirName, filename));
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      _log.warning('Failed to read payload file $filename: $e');
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
      _log.warning('Failed to decode JSON in payload $filename: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = _db ?? await init();
    return await db.query(table);
  }

  Future<void> exportToSqlFile(String destPath,
      {bool inlinePayloads = true}) async {
    final db = _db ?? await init();
    final sb = StringBuffer();

    final tables = await db.rawQuery(
        "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");

    for (final row in tables) {
      final name = row['name'] as String?;
      final createSql = row['sql'] as String?;
      if (name == null || createSql == null) continue;
      sb.writeln('$createSql;');

      if (inlinePayloads) {
        final rows = await db.rawQuery('SELECT rowid, * FROM "$name"');
        for (final r in rows) {
          // For columns that have handlers (eg. payload), inline file content
          final outRow = Map<String, dynamic>.from(r);
          // remove rowid from columns list when generating INSERT
          outRow.remove('rowid');

          final cols = outRow.keys.toList();
          final vals = <String>[];
          for (final c in cols) {
            final handler = _getHandler(name, c);
            final v = outRow[c];
            if (handler != null && v is String) {
              // If this looks like a filename in our migrations dir, read it
              final payload = await readPayloadString(v);
              if (payload != null) {
                vals.add(_valueToSqlLiteral(payload));
                continue;
              }
            }
            vals.add(_valueToSqlLiteral(v));
          }
          final columns = cols.map((c) => '"$c"').join(', ');
          final values = vals.join(', ');
          sb.writeln('INSERT INTO "$name" ($columns) VALUES ($values);');
        }
      } else {
        final rows = await db.query(name);
        for (final r in rows) {
          final columns = r.keys.map((c) => '"$c"').join(', ');
          final values = r.values.map((v) => _valueToSqlLiteral(v)).join(', ');
          sb.writeln('INSERT INTO "$name" ($columns) VALUES ($values);');
        }
      }
      sb.writeln();
    }

    final file = File(destPath);
    await file.create(recursive: true);
    await file.writeAsString(sb.toString());
    _log.info('Exported SQL to $destPath');
  }

  Future<void> importFromSqlFile(String filePath,
      {bool convertInlinePayloads = true}) async {
    final db = _db ?? await init();
    final content = await File(filePath).readAsString();
    final statements = content.split(';');
    await db.transaction((txn) async {
      final insertRe = RegExp(
          r'^\s*INSERT\s+INTO\s+(?:["`])?([A-Za-z0-9_]+)(?:["`])?',
          caseSensitive: false);
      for (var stmt in statements) {
        stmt = stmt.trim();
        if (stmt.isEmpty) continue;
        try {
          // If this is an INSERT, ensure the target table exists before executing
          final m = insertRe.firstMatch(stmt);
          if (m != null) {
            final tableName = m.group(1);
            if (tableName != null) {
              final exists = await txn.rawQuery(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
                  [tableName]);
              if (exists.isEmpty) {
                _log.info('Skipping INSERT into missing table `$tableName`.');
                continue;
              }
            }
          }
          await txn.execute(stmt);
        } catch (e) {
          _log.warning('Failed to execute statement: $stmt\n$e');
        }
      }
    });
    // Optionally post-process imported rows: for any table columns that have
    // registered handlers and contain inline JSON (string starting with '{' or
    // '['), write the JSON to a payload file and update the DB row to store
    // the filename instead.
    if (convertInlinePayloads) {
      try {
        final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");
        for (final t in tables) {
          final name = t['name'] as String?;
          if (name == null) continue;
          // determine handler columns for this table
          final cols = <String>{};
          final byTable = _columnHandlers[name];
          if (byTable != null) cols.addAll(byTable.keys);
          final wildcard = _columnHandlers['*'];
          if (wildcard != null) cols.addAll(wildcard.keys);
          if (cols.isEmpty) continue;

          // select rowid and columns
          final rows = await db.rawQuery('SELECT rowid, * FROM "$name"');

          // Determine best identifier to update rows: prefer a declared
          // PRIMARY KEY column (if any), otherwise fall back to rowid.
          String pkName = 'rowid';
          try {
            final pragma = await db.rawQuery('PRAGMA table_info("$name")');
            for (final col in pragma) {
              final pk = col['pk'];
              if (pk is int && pk > 0) {
                final n = col['name'] as String?;
                if (n != null && n.isNotEmpty) {
                  pkName = n;
                  break;
                }
              }
            }
          } catch (_) {}

          for (final r in rows) {
            final idValue = r.containsKey(pkName) ? r[pkName] : r['rowid'];
            if (idValue == null) continue;
            final updates = <String, dynamic>{};
            for (final c in cols) {
              if (!r.containsKey(c)) continue;
              final val = r[c];
              if (val is String) {
                final s = val.trim();
                if (s.startsWith('{') || s.startsWith('[')) {
                  try {
                    final decoded = json.decode(s);
                    final handler = _getHandler(name, c);
                    if (handler != null) {
                      final newVal = await handler.onWrite(name, c, decoded);
                      updates[c] = newVal;
                    }
                  } catch (e) {
                    // not valid JSON, skip
                  }
                } else {
                  _log.warning('Failed to update statement:');
                }
              }
            }
            if (updates.isNotEmpty) {
              final whereClause =
                  pkName == 'rowid' ? 'rowid = ?' : '"$pkName" = ?';
              await db.update(name, updates,
                  where: whereClause, whereArgs: [idValue]);
            }
          }
        }
      } catch (e, st) {
        _log.warning('Post-processing imported payloads failed: $e', e, st);
      }
    }

    _log.info('Imported SQL from $filePath');
  }

  /// Import sample/demo inserts packaged as an asset. Returns the temporary
  /// file path used for import on success, or null on failure.
  Future<String?> importSampleInserts(
      {String assetPath = 'migrations/sample_inserts.sql',
      bool convertInlinePayloads = true}) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      if (content.trim().isEmpty) return null;
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = p.join(tmpDir.path,
          'sample_inserts_${DateTime.now().millisecondsSinceEpoch}.sql');
      final f = File(tmpPath);
      await f.create(recursive: true);
      await f.writeAsString(content);
      await importFromSqlFile(tmpPath,
          convertInlinePayloads: convertInlinePayloads);
      _log.info('Imported sample inserts from $assetPath');
      return tmpPath;
    } catch (e, st) {
      _log.warning(
          'Failed to import sample inserts asset $assetPath: $e', e, st);
      return null;
    }
  }

  /// Run a migration SQL asset. By default only schema statements (CREATE,
  /// ALTER, DROP, PRAGMA) are applied to avoid importing sample data. Set
  /// [applyDml] to true to also execute DML statements (INSERT/UPDATE/DELETE)
  /// from the asset.
  Future<void> runMigrationAsset(String assetPath,
      {bool applyDml = false}) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      if (content.trim().isEmpty) {
        _log.info('Migration asset $assetPath is empty');
        return;
      }

      final db = _db ?? await init();
      final statements = content.split(';');
      final allowedRe =
          RegExp(r'^(CREATE|PRAGMA|DROP|ALTER)\b', caseSensitive: false);

      await db.transaction((txn) async {
        for (var stmt in statements) {
          stmt = stmt.trim();
          if (stmt.isEmpty) continue;
          final up = stmt.toUpperCase();
          if (up == 'BEGIN' ||
              up.startsWith('BEGIN TRANSACTION') ||
              up == 'COMMIT' ||
              up.startsWith('COMMIT')) {
            continue;
          }
          // If DML not allowed, only run schema statements.
          if (!applyDml && !allowedRe.hasMatch(stmt)) {
            _log.info(
                'Skipping non-schema statement in $assetPath: ${stmt.length > 80 ? stmt.substring(0, 80) : stmt}');
            continue;
          }
          try {
            await txn.execute(stmt);
          } catch (e, st) {
            _log.warning(
                'Failed to execute migration statement from $assetPath: $stmt\n$e',
                e,
                st);
          }
        }
      });
      _log.info('Applied migration asset: $assetPath (applyDml=$applyDml)');
    } catch (e, st) {
      _log.warning('Failed to apply migration asset $assetPath: $e', e, st);
      rethrow;
    }
  }

  Future<String> copyDatabaseFile(String destPath) async {
    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, 'form_fields.db'));
    final dest = File(destPath);
    await dest.create(recursive: true);
    await dbFile.copy(dest.path);
    _log.info('Copied DB file to ${dest.path}');
    return dest.path;
  }

  String _valueToSqlLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    final s = value.toString().replaceAll("'", "''");
    return "'$s'";
  }
}
