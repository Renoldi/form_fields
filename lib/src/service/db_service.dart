import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'payload_utils.dart';
import 'column_handler.dart';
import 'package:sqflite/sqflite.dart';

final _log = Logger('DBService');

const String _payloadDirName = 'payloads';

class DBService {
  DBService._() {
    // Register default file-backed handler for any `payload` column.
    // registerColumnHandler(
    //     '*', 'payload', FileBackedColumnHandler(prefix: 'payload'));
    // Register table-specific prefixes for common tables to produce nicer filenames.
    // registerColumnHandler(
    //     'asset', 'payload', FileBackedColumnHandler(prefix: 'asset'));
    // registerColumnHandler('master_inspection_forms', 'payload',
    //     FileBackedColumnHandler(prefix: 'master_inspection_forms'));
    // registerColumnHandler('master_inspections', 'payload',
    //     FileBackedColumnHandler(prefix: 'master_inspections'));
    // registerColumnHandler('pending_inspections', 'payload',
    //     FileBackedColumnHandler(prefix: 'pending_inspections'));
  }
  static final DBService instance = DBService._();

  // Per-call flags control automatic payload handling; global toggle removed.

  Database? _db;
  Completer<Database>? _initCompleter;

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

  /// Returns true when a column should be treated as file-backed even when
  /// no explicit ColumnHandler was registered. This covers common names
  /// like `payload` or columns ending with `_payload` to provide a sensible
  /// default without requiring manual registration.
  bool isColumnFileBacked(String table, String column) {
    if (_getHandler(table, column) != null) return true;
    if (column == 'payload' || column.endsWith('_payload')) return true;
    return false;
  }

  Future<Database> init(
      {String dbName = 'form_fields.db',
      List<String>? migrationAssetPaths,
      int dbVersion = 0,
      OnDatabaseConfigureFn? onConfigure,
      OnDatabaseCreateFn? onCreate,
      OnDatabaseVersionChangeFn? onUpgrade,
      OnDatabaseVersionChangeFn? onDowngrade,
      OnDatabaseOpenFn? onOpen}) async {
    // Ensure only one init runs at a time; concurrent callers await the same
    // initialization to avoid racing open/close operations on `_db`.
    if (_initCompleter != null) return await _initCompleter!.future;
    _initCompleter = Completer<Database>();

    try {
      // Build migration maps from provided assets. The maps contain "up"
      // migration assets keyed by target version and optional "down" assets
      // for downgrades if present in filenames (containing 'down' or
      // 'downgrade'). If no parseable version is found, assets are assigned
      // incremental versions starting at 1 in the provided order.
      final migrationAssets = <int, String>{};
      final downgradeAssets = <int, String>{};
      if (migrationAssetPaths != null && migrationAssetPaths.isNotEmpty) {
        int fallbackIndex = 1;
        for (final asset in migrationAssetPaths) {
          final basename = p.basename(asset);
          final verMatch = RegExp(r'v?(\d+)').firstMatch(basename);
          int ver;
          if (verMatch != null) {
            ver = int.parse(verMatch.group(1)!);
          } else {
            ver = fallbackIndex++;
          }
          final isDown = RegExp(r'down|downgrade', caseSensitive: false)
              .hasMatch(basename);
          if (isDown) {
            downgradeAssets[ver] = asset;
          } else {
            migrationAssets[ver] = asset;
          }
        }
      }

      Future<void> applyMigrationForVersion(Database db, int version,
          {bool applyDml = false}) async {
        final asset = migrationAssets[version];
        if (asset == null) {
          _log.info('No migration asset for version $version');
          return;
        }
        _log.info('Applying migration for version $version from $asset');
        try {
          final content = await rootBundle.loadString(asset);
          final statements = content.split(';');
          await db.transaction((txn) async {
            for (var stmt in statements) {
              stmt = stmt.trim();
              if (stmt.isEmpty) {
                continue;
              }
              if (stmt.toUpperCase().contains('CREATE TABLE')) {
                final createRe = RegExp(r'CREATE\s+TABLE[\s\S]*?\)\s*;?',
                    caseSensitive: false);
                final matches = createRe.allMatches(stmt);
                for (final m in matches) {
                  final createStmt = m.group(0)!.trim();
                  try {
                    _log.fine(
                        'Executing extracted CREATE stmt: ${createStmt.length > 200 ? "${createStmt.substring(0, 200)}..." : createStmt}');
                    await txn.execute(createStmt);
                  } catch (e, st) {
                    _log.warning(
                        'Failed to execute extracted CREATE stmt: $createStmt\n$e',
                        e,
                        st);
                  }
                }
                continue;
              }
              // Remove any leading single-line SQL comments so we can detect the
              // actual statement token (e.g. CREATE, PRAGMA). Comments like
              // "-- V1: ..." often precede CREATE and would otherwise prevent
              // schema detection when multiple statements are bundled together.
              final cleaned = stmt
                  .replaceAll(RegExp(r'^\s*--.*\r?\n', multiLine: true), '')
                  .trim();
              if (cleaned.isEmpty) continue;
              final up = cleaned.toUpperCase();
              if (up == 'BEGIN' ||
                  up.startsWith('BEGIN TRANSACTION') ||
                  up == 'COMMIT' ||
                  up.startsWith('COMMIT')) {
                continue;
              }
              if (!applyDml) {
                final upclean = cleaned.toUpperCase();
                if (!(upclean.contains('CREATE') ||
                    upclean.contains('PRAGMA') ||
                    upclean.contains('DROP') ||
                    upclean.contains('ALTER'))) {
                  _log.fine('Skipping non-schema statement in $asset: $stmt');
                  continue;
                }
              }
              try {
                _log.fine(
                    'Executing migration stmt: ${cleaned.length > 200 ? "${cleaned.substring(0, 200)}..." : cleaned}');
                await txn.execute(cleaned);
              } catch (e, st) {
                _log.warning(
                    'Failed to execute migration stmt: $cleaned\n$e', e, st);
              }
            }
          });
          _log.info('Applied migration asset for version $version');
        } catch (e, st) {
          _log.warning('Failed to apply migration asset $asset: $e', e, st);
          rethrow;
        }
      }

      Future<void> applyDowngradeForVersion(Database db, int version) async {
        final asset = downgradeAssets[version];
        if (asset == null) {
          _log.warning(
              'No downgrade asset found for version $version; skipping');
          return;
        }
        _log.info('Applying downgrade for version $version from $asset');
        try {
          final content = await rootBundle.loadString(asset);
          final statements = content.split(';');
          await db.transaction((txn) async {
            for (var stmt in statements) {
              stmt = stmt.trim();
              if (stmt.isEmpty) {
                continue;
              }
              final cleaned = stmt
                  .replaceAll(RegExp(r'^\s*--.*\r?\n', multiLine: true), '')
                  .trim();
              if (cleaned.isEmpty) continue;
              final up = cleaned.toUpperCase();
              if (up == 'BEGIN' ||
                  up.startsWith('BEGIN TRANSACTION') ||
                  up == 'COMMIT' ||
                  up.startsWith('COMMIT')) {
                continue;
              }
              try {
                _log.fine(
                    'Executing downgrade stmt: ${cleaned.length > 200 ? "${cleaned.substring(0, 200)}..." : cleaned}');
                await txn.execute(cleaned);
              } catch (e, st) {
                _log.warning(
                    'Failed to execute downgrade stmt: $cleaned\n$e', e, st);
              }
            }
          });
          _log.info('Applied downgrade asset for version $version');
        } catch (e, st) {
          _log.warning('Failed to apply downgrade asset $asset: $e', e, st);
          rethrow;
        }
      }

      if (_db != null) {
        try {
          final pragma = await _db!.rawQuery('PRAGMA user_version;');
          var curVersion = 0;
          if (pragma.isNotEmpty) {
            final first = pragma.first.values.first;
            if (first is int) {
              curVersion = first;
            } else {
              curVersion = int.tryParse(first.toString()) ?? 0;
            }
          }
          if (curVersion == dbVersion) return _db!;
          // If caller did not request a target version (dbVersion <= 0),
          // treat this as a no-op: do not attempt upgrades or downgrades.
          if (dbVersion <= 0) {
            _log.info(
                'No target dbVersion requested (dbVersion=$dbVersion); leaving open DB at $curVersion');
            return _db!;
          }
          if (dbVersion > curVersion) {
            _log.info(
                'Detected open DB version $curVersion, upgrading to $dbVersion');
            final versions = migrationAssets.keys.toList()..sort();
            for (final ver in versions) {
              if (ver > curVersion && ver <= dbVersion) {
                await applyMigrationForVersion(_db!, ver, applyDml: false);
              }
            }
            try {
              await _db!.execute('PRAGMA user_version = $dbVersion');
            } catch (_) {}
            try {
              if (onUpgrade != null) onUpgrade(_db!, curVersion, dbVersion);
            } catch (e, st) {
              _log.warning('onUpgrade callback threw: $e', e, st);
            }
            return _db!;
          }
          _log.info(
              'Detected open DB version $curVersion, downgrading to $dbVersion');
          final versionsDown = downgradeAssets.keys.toList()
            ..sort((a, b) => b - a);
          for (final ver in versionsDown) {
            if (ver <= curVersion && ver > dbVersion) {
              await applyDowngradeForVersion(_db!, ver);
            }
          }
          try {
            await _db!.execute('PRAGMA user_version = $dbVersion');
          } catch (_) {}
          try {
            if (onDowngrade != null) onDowngrade(_db!, curVersion, dbVersion);
          } catch (e, st) {
            _log.warning('onDowngrade callback threw: $e', e, st);
          }
          return _db!;
        } catch (e, st) {
          _log.warning('Failed to reconcile open DB version: $e', e, st);
          try {
            await _db!.close();
          } catch (_) {}
          _db = null;
        }
      }

      final documents = await getApplicationDocumentsDirectory();
      final path = p.join(documents.path, dbName);
      _log.info('Opening database at $path');

      _db = await openDatabase(
        path,
        version: dbVersion > 0 ? dbVersion : null,
        onConfigure: onConfigure,
        onCreate: dbVersion > 0
            ? (Database db, int v) async {
                _log.info('onCreate: creating DB up to version $v');
                try {
                  try {
                    final base =
                        await rootBundle.loadString('migrations/migration.sql');
                    if (base.trim().isNotEmpty) {
                      final statements = base.split(';');
                      final allowedRe = RegExp(r'^(CREATE|PRAGMA|DROP|ALTER)',
                          caseSensitive: false);
                      for (var stmt in statements) {
                        stmt = stmt.trim();
                        if (stmt.isEmpty) {
                          continue;
                        }
                        final up = stmt.toUpperCase();
                        if (up == 'BEGIN' ||
                            up.startsWith('BEGIN TRANSACTION') ||
                            up == 'COMMIT' ||
                            up.startsWith('COMMIT')) {
                          continue;
                        }
                        if (!allowedRe.hasMatch(stmt)) {
                          continue;
                        }
                        try {
                          await db.execute(stmt);
                        } catch (e) {
                          _log.warning('Failed to execute init statement: $e');
                        }
                      }
                      _log.info(
                          'Database initialized from migrations/migration.sql');
                    }
                  } catch (_) {}

                  final versions = migrationAssets.keys.toList()..sort();
                  for (final ver in versions) {
                    if (ver <= v) {
                      await applyMigrationForVersion(db, ver, applyDml: false);
                    }
                  }
                  try {
                    if (onCreate != null) onCreate(db, v);
                  } catch (e, st) {
                    _log.warning('onCreate callback threw: $e', e, st);
                  }
                } catch (e, st) {
                  _log.warning('Failed during onCreate migrations: $e', e, st);
                }
              }
            : null,
        onUpgrade: dbVersion > 0
            ? (Database db, int oldV, int newV) async {
                _log.info('onUpgrade: $oldV -> $newV');
                final versions = migrationAssets.keys.toList()..sort();
                for (final ver in versions) {
                  if (ver > oldV && ver <= newV) {
                    await applyMigrationForVersion(db, ver, applyDml: false);
                  }
                }
                try {
                  if (onUpgrade != null) onUpgrade(db, oldV, newV);
                } catch (e, st) {
                  _log.warning('onUpgrade callback threw: $e', e, st);
                }
              }
            : null,
        onDowngrade: dbVersion > 0
            ? (Database db, int oldV, int newV) async {
                _log.info('onDowngrade: $oldV -> $newV');
                final versions = downgradeAssets.keys.toList()
                  ..sort((a, b) => b - a);
                for (final ver in versions) {
                  if (ver <= oldV && ver > newV) {
                    await applyDowngradeForVersion(db, ver);
                  }
                }
                try {
                  if (onDowngrade != null) onDowngrade(db, oldV, newV);
                } catch (e, st) {
                  _log.warning('onDowngrade callback threw: $e', e, st);
                }
              }
            : null,
        onOpen: (db) async {
          try {
            if (onOpen != null) await onOpen(db);
          } catch (e, st) {
            _log.warning('onOpen callback threw: $e', e, st);
          }
        },
      );
      return _db!;
    } catch (e) {
      // Propagate error to any waiters
      if (!_initCompleter!.isCompleted) _initCompleter!.completeError(e);
      rethrow;
    } finally {
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete(_db!);
      }
      _initCompleter = null;
    }
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

  /// Set SQLite `user_version` PRAGMA. Ensures DB is open before setting.
  Future<void> setUserVersion(int version) async {
    // Open a transient connection to the DB file to set PRAGMA directly.
    try {
      final documents = await getApplicationDocumentsDirectory();
      final path = p.join(documents.path, 'form_fields.db');
      final transient = await openDatabase(path);
      try {
        await transient.execute('PRAGMA user_version = $version');
        _log.info('Set PRAGMA user_version = $version (transient)');
      } finally {
        try {
          await transient.close();
        } catch (_) {}
      }

      // Clear cached connection so future operations reopen a fresh one.
      try {
        await close();
      } catch (_) {}
      _db = null;
      return;
    } catch (e, st) {
      _log.warning('Failed to set PRAGMA user_version = $version: $e', e, st);
      rethrow;
    }
  }

  /// Migrate the open (or on-disk) database to [targetVersion]. This is a
  /// convenience wrapper around `init` that forwards migration assets and
  /// lifecycle callbacks. If the DB is already open it will attempt to
  /// reconcile the current version with [targetVersion] (running upgrades or
  /// downgrades as needed).
  Future<Database> migrateTo({
    String dbName = 'form_fields.db',
    required int targetVersion,
    List<String>? migrationAssetPaths,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
  }) async {
    return await init(
      dbName: dbName,
      migrationAssetPaths: migrationAssetPaths,
      dbVersion: targetVersion,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
      onOpen: onOpen,
    );
  }

  /// Convenience wrapper to migrate up to [targetVersion].
  Future<Database> upgradeTo(int targetVersion,
          {String dbName = 'form_fields.db',
          List<String>? migrationAssetPaths,
          OnDatabaseConfigureFn? onConfigure,
          OnDatabaseCreateFn? onCreate,
          OnDatabaseVersionChangeFn? onUpgrade,
          OnDatabaseOpenFn? onOpen}) async =>
      await migrateTo(
          dbName: dbName,
          targetVersion: targetVersion,
          migrationAssetPaths: migrationAssetPaths,
          onConfigure: onConfigure,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
          onOpen: onOpen);

  /// Convenience wrapper to migrate down to [targetVersion].
  Future<Database> downgradeTo(int targetVersion,
          {String dbName = 'form_fields.db',
          List<String>? migrationAssetPaths,
          OnDatabaseConfigureFn? onConfigure,
          OnDatabaseCreateFn? onCreate,
          OnDatabaseVersionChangeFn? onDowngrade,
          OnDatabaseOpenFn? onOpen}) async =>
      await migrateTo(
          dbName: dbName,
          targetVersion: targetVersion,
          migrationAssetPaths: migrationAssetPaths,
          onConfigure: onConfigure,
          onCreate: onCreate,
          onDowngrade: onDowngrade,
          onOpen: onOpen);

  /// Structured SELECT helper for a single table. This is a more
  /// professional/typed alternative to `select(sql, params: ...)` and
  /// leverages sqflite's `query` API. When [inlinePayloads] is true any
  /// columns with registered handlers will attempt to inline JSON payloads
  /// from payload files or decode inline JSON strings.
  Future<List<Map<String, dynamic>>> selectFrom(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset,
      bool inlinePayloads = true}) async {
    final db = _db ?? await init();
    try {
      final rows = (await db.query(table,
              distinct: distinct ?? false,
              columns: columns,
              where: where,
              whereArgs: whereArgs,
              groupBy: groupBy,
              having: having,
              orderBy: orderBy,
              limit: limit,
              offset: offset))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      await PayloadUtils.inlinePayloadsForRows(table, rows,
          inlinePayloads: inlinePayloads,
          payloadDecoder: null,
          getHandler: (t, c) => _getHandler(t, c),
          isColumnFileBacked: (t, c) => isColumnFileBacked(t, c),
          readPayloadJson: (fn) => readPayloadJson(fn));

      return rows;
    } catch (e, st) {
      _log.warning('selectFrom failed: $e', e, st);
      rethrow;
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
        var handler = _getHandler(table, col);
        final originalVal = values[col];

        // If no explicit handler was registered, apply a sensible fallback:
        // - treat columns named `payload` or ending with `_payload` as file-backed
        // - treat Map/List values or JSON-like strings as JSON payloads
        //   to be written to disk
        final looksLikeJsonString = originalVal is String &&
            (originalVal.trim().startsWith('{') ||
                originalVal.trim().startsWith('['));

        if (col == 'payload' ||
            col.endsWith('_payload') ||
            originalVal is Map ||
            originalVal is List ||
            looksLikeJsonString) {
          handler ??= FileBackedColumnHandler(prefix: table);
        } else {
          continue;
        }

        try {
          final newVal = await handler.onWrite(table, col, originalVal);
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

  /// Insert or update (upsert) a row into [table]. This mirrors `insert`
  /// payload handling behavior, but uses SQLite conflict resolution to
  /// replace an existing row when a unique/primary key conflict occurs.
  ///
  /// Returns the row id of the inserted row.
  Future<int> insertOrUpdate(String table, Map<String, dynamic> values,
      {bool autoHandlePayload = true,
      ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) async {
    final db = _db ?? await init();

    if (autoHandlePayload && values.isNotEmpty) {
      final keys = values.keys.toList();
      for (final col in keys) {
        var handler = _getHandler(table, col);
        final originalVal = values[col];

        final looksLikeJsonString = originalVal is String &&
            (originalVal.trim().startsWith('{') ||
                originalVal.trim().startsWith('['));

        if (col == 'payload' ||
            col.endsWith('_payload') ||
            originalVal is Map ||
            originalVal is List ||
            looksLikeJsonString) {
          handler ??= FileBackedColumnHandler(prefix: table);
        } else {
          continue;
        }

        try {
          final newVal = await handler.onWrite(table, col, originalVal);
          values = Map<String, dynamic>.from(values);
          values[col] = newVal;
          values['created_at'] =
              values['created_at'] ?? DateTime.now().millisecondsSinceEpoch;
        } catch (e, st) {
          _log.warning('Handler onWrite failed for $table.$col: $e', e, st);
        }
      }
    }

    return await db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
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
        var handler = _getHandler(table, col);
        final originalVal = values[col];

        final looksLikeJsonString = originalVal is String &&
            (originalVal.trim().startsWith('{') ||
                originalVal.trim().startsWith('['));

        if (col == 'payload' ||
            col.endsWith('_payload') ||
            originalVal is Map ||
            originalVal is List ||
            looksLikeJsonString) {
          handler ??= FileBackedColumnHandler(prefix: table);
        } else {
          continue;
        }

        try {
          final newVal = await handler.onWrite(table, col, originalVal);
          values = Map<String, dynamic>.from(values);
          values[col] = newVal;
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

  /// Execute a raw SQL statement (INSERT / UPDATE / DELETE / others).
  ///
  /// Returns:
  /// - for `INSERT`: the inserted row id (as returned by `rawInsert`)
  /// - for `UPDATE`/`DELETE`: the number of affected rows
  /// - for other statements: 0
  Future<int> executeSqlInsUpDel(String sql) async {
    final db = _db ?? await init();
    final stmt = sql.trim();
    try {
      final up = stmt.toUpperCase();
      if (up.startsWith('INSERT')) {
        // Try to parse a simple single-row INSERT statement and route it
        // through the high-level `insert` helper so ColumnHandlers run.
        try {
          // Find table name
          final tableRe = RegExp(
              r'INSERT\s+INTO\s+(?:["`])?([A-Za-z0-9_]+)(?:["`])?',
              caseSensitive: false);
          final tableMatch = tableRe.firstMatch(stmt);
          if (tableMatch == null) return await db.rawInsert(sql);
          final table = tableMatch.group(1)!;

          // Helper to find matching parenthesis starting at idx
          int findMatching(String s, int start) {
            var depth = 0;
            for (var i = start; i < s.length; i++) {
              final ch = s[i];
              if (ch == '(') depth++;
              if (ch == ')') {
                depth--;
                if (depth == 0) return i;
              }
            }
            return -1;
          }

          // Parse optional columns list after table name
          int pos = tableMatch.end;
          while (pos < stmt.length && stmt[pos].trim().isEmpty) {
            pos++;
          }
          List<String>? columns;
          if (pos < stmt.length && stmt[pos] == '(') {
            final end = findMatching(stmt, pos);
            if (end > pos) {
              final colsRaw = stmt.substring(pos + 1, end);
              columns = colsRaw
                  .split(',')
                  .map((s) => s.trim().replaceAll('"', '').replaceAll('`', ''))
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          }

          // Find VALUES keyword
          final valuesRe = RegExp(r"\bVALUES\b", caseSensitive: false);
          final valuesMatch = valuesRe.firstMatch(stmt);
          if (valuesMatch == null) return await db.rawInsert(sql);
          var vpos = valuesMatch.end;
          while (vpos < stmt.length && stmt[vpos].trim().isEmpty) {
            vpos++;
          }
          if (vpos >= stmt.length || stmt[vpos] != '(') {
            return await db.rawInsert(sql);
          }
          final vend = findMatching(stmt, vpos);
          if (vend < 0) return await db.rawInsert(sql);
          final valsRaw = stmt.substring(vpos + 1, vend);

          // Split values at top-level commas (respect quotes/parentheses)
          List<String> splitValues(String s) {
            final out = <String>[];
            var buf = StringBuffer();
            var inSingle = false;
            var inDouble = false;
            var depth = 0;
            for (var i = 0; i < s.length; i++) {
              final ch = s[i];
              if (ch == "'" && !inDouble) {
                // handle escaped '' inside single quotes
                final next = (i + 1 < s.length) ? s[i + 1] : null;
                if (inSingle && next == "'") {
                  buf.write("'");
                  i++; // skip escaped quote
                  continue;
                }
                inSingle = !inSingle;
                buf.write(ch);
                continue;
              }
              if (ch == '"' && !inSingle) {
                inDouble = !inDouble;
                buf.write(ch);
                continue;
              }
              if (!inSingle && !inDouble) {
                if (ch == '(') {
                  depth++;
                } else if (ch == ')') {
                  depth--;
                } else if (ch == ',' && depth == 0) {
                  out.add(buf.toString().trim());
                  buf = StringBuffer();
                  continue;
                }
              }
              buf.write(ch);
            }
            final last = buf.toString().trim();
            if (last.isNotEmpty) out.add(last);
            return out;
          }

          final vals = splitValues(valsRaw);
          // If columns are present but counts mismatch, fall back
          if (columns != null && columns.length != vals.length) {
            return await db.rawInsert(sql);
          }

          dynamic parseValueToken(String t) {
            final s = t.trim();
            if (s.startsWith("'") && s.endsWith("'")) {
              // unquote single-quoted SQL string and unescape doubled quotes
              final inner = s.substring(1, s.length - 1).replaceAll("''", "'");
              return inner;
            }
            // try int
            final intVal = int.tryParse(s);
            if (intVal != null) return intVal;
            // try double
            final dbl = double.tryParse(s);
            if (dbl != null) return dbl;
            // fallback to raw string
            return s;
          }

          final valuesMap = <String, dynamic>{};
          if (columns != null) {
            for (var i = 0; i < columns.length; i++) {
              valuesMap[columns[i]] = parseValueToken(vals[i]);
            }
            // call high-level insert to trigger handlers
            return await insert(table, valuesMap);
          } else {
            // No columns specified; cannot safely map to insert helper.
            return await db.rawInsert(sql);
          }
        } catch (e) {
          // Parsing failed; fall back to rawInsert
          return await db.rawInsert(sql);
        }
      } else if (up.startsWith('UPDATE')) {
        // Try to parse simple UPDATE ... SET ... WHERE col = literal
        try {
          final tableRe = RegExp(r'UPDATE\s+(?:["`])?([A-Za-z0-9_]+)(?:["`])?',
              caseSensitive: false);
          final tableMatch = tableRe.firstMatch(stmt);
          if (tableMatch == null) return await db.rawUpdate(sql);
          final table = tableMatch.group(1)!;

          // find SET and optional WHERE
          final setRe = RegExp(r'\bSET\b', caseSensitive: false);
          final setMatch = setRe.firstMatch(stmt);
          if (setMatch == null) return await db.rawUpdate(sql);
          final setStart = setMatch.end;
          final whereRe = RegExp(r'\bWHERE\b', caseSensitive: false);
          final whereMatch = whereRe.firstMatch(stmt);
          final setRaw = whereMatch != null
              ? stmt.substring(setStart, whereMatch.start)
              : stmt.substring(setStart);
          final whereRaw =
              whereMatch != null ? stmt.substring(whereMatch.end).trim() : null;

          // split assignments (respect quotes/parentheses)
          List<String> splitAssignments(String s) {
            final out = <String>[];
            var buf = StringBuffer();
            var inSingle = false;
            var inDouble = false;
            var depth = 0;
            for (var i = 0; i < s.length; i++) {
              final ch = s[i];
              if (ch == "'" && !inDouble) {
                final next = (i + 1 < s.length) ? s[i + 1] : null;
                if (inSingle && next == "'") {
                  buf.write("'");
                  i++;
                  continue;
                }
                inSingle = !inSingle;
                buf.write(ch);
                continue;
              }
              if (ch == '"' && !inSingle) {
                inDouble = !inDouble;
                buf.write(ch);
                continue;
              }
              if (!inSingle && !inDouble) {
                if (ch == '(') {
                  depth++;
                } else if (ch == ')') {
                  depth--;
                } else if (ch == ',' && depth == 0) {
                  out.add(buf.toString().trim());
                  buf = StringBuffer();
                  continue;
                }
              }
              buf.write(ch);
            }
            final last = buf.toString().trim();
            if (last.isNotEmpty) out.add(last);
            return out;
          }

          dynamic parseValueToken(String t) {
            final s = t.trim();
            if (s.startsWith("'") && s.endsWith("'")) {
              final inner = s.substring(1, s.length - 1).replaceAll("''", "'");
              return inner;
            }
            final intVal = int.tryParse(s);
            if (intVal != null) return intVal;
            final dbl = double.tryParse(s);
            if (dbl != null) return dbl;
            return s;
          }

          final assigns = splitAssignments(setRaw);
          final valuesMap = <String, dynamic>{};
          for (final a in assigns) {
            final idx = a.indexOf('=');
            if (idx <= 0) return await db.rawUpdate(sql);
            final col = a
                .substring(0, idx)
                .trim()
                .replaceAll('"', '')
                .replaceAll('`', '');
            final valToken = a.substring(idx + 1).trim();
            valuesMap[col] = parseValueToken(valToken);
          }

          if (whereRaw == null) {
            // No WHERE -> unsafe to map; fallback
            return await db.rawUpdate(sql);
          }

          // support simple equality WHERE: col = literal
          final eqRe = RegExp(r'^(?:["`]?([A-Za-z0-9_]+)["`]?)\s*=\s*(.+)\$',
              caseSensitive: false);
          final eqMatch = eqRe.firstMatch(whereRaw);
          if (eqMatch == null) return await db.rawUpdate(sql);
          final wcol = eqMatch.group(1)!;
          final wvalToken = eqMatch.group(2)!.trim();
          if (wvalToken == '?') return await db.rawUpdate(sql);
          final wval = parseValueToken(wvalToken);
          final whereClause = '$wcol = ?';
          return await update(table, valuesMap, whereClause, [wval]);
        } catch (e) {
          return await db.rawUpdate(sql);
        }
      } else if (up.startsWith('DELETE')) {
        // Try to parse DELETE FROM table WHERE col = literal
        try {
          final tableRe = RegExp(
              r'DELETE\s+FROM\s+(?:["`])?([A-Za-z0-9_]+)(?:["`])?',
              caseSensitive: false);
          final tableMatch = tableRe.firstMatch(stmt);
          if (tableMatch == null) return await db.rawDelete(sql);
          final table = tableMatch.group(1)!;
          final whereRe = RegExp(r'\bWHERE\b', caseSensitive: false);
          final whereMatch = whereRe.firstMatch(stmt);
          if (whereMatch == null) return await db.rawDelete(sql);
          final whereRaw = stmt.substring(whereMatch.end).trim();

          final eqRe = RegExp(r'^(?:["`]?([A-Za-z0-9_]+)["`]?)\s*=\s*(.+)\$',
              caseSensitive: false);
          final eqMatch = eqRe.firstMatch(whereRaw);
          if (eqMatch == null) return await db.rawDelete(sql);
          final wcol = eqMatch.group(1)!;
          final wvalToken = eqMatch.group(2)!.trim();
          if (wvalToken == '?') return await db.rawDelete(sql);

          dynamic parseValueToken(String t) {
            final s = t.trim();
            if (s.startsWith("'") && s.endsWith("'")) {
              final inner = s.substring(1, s.length - 1).replaceAll("''", "'");
              return inner;
            }
            final intVal = int.tryParse(s);
            if (intVal != null) return intVal;
            final dbl = double.tryParse(s);
            if (dbl != null) return dbl;
            return s;
          }

          final wval = parseValueToken(wvalToken);
          final whereClause = '$wcol = ?';
          return await delete(table, whereClause, [wval]);
        } catch (e) {
          return await db.rawDelete(sql);
        }
      } else {
        await db.execute(sql);
        return 0;
      }
    } catch (e, st) {
      _log.warning('Failed to execute SQL: $e', e, st);
      rethrow;
    }
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

  Future<void> exportToSqlFile(String destPath,
      {bool inlinePayloads = true}) async {
    final db = _db ?? await init();
    final sb = StringBuffer();

    final tables = await db.rawQuery(
        "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");

    for (final row in tables) {
      final name = row['name'] as String?;
      final createSql = row['sql'] as String?;
      if (name == null || createSql == null) {
        continue;
      }
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
          // No need to require pre-registered handlers here — we want to
          // convert inline JSON in any column during import. Proceed to
          // inspect all columns and use registered handlers when available,
          // otherwise fall back to `FileBackedColumnHandler`.

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

            // Inspect every column in the row; if the value looks like
            // inline JSON (string starting with '{' or '[') or is already
            // a Map/List, write it out via a handler (registered or fallback)
            for (final entry in r.entries) {
              final c = entry.key;
              if (c == 'rowid') continue;
              final val = entry.value;

              dynamic toWrite;
              if (val is String) {
                final s = val.trim();
                if (s.startsWith('{') || s.startsWith('[')) {
                  try {
                    toWrite = json.decode(s);
                  } catch (_) {
                    continue; // not valid JSON
                  }
                } else {
                  continue;
                }
              } else if (val is Map || val is List) {
                toWrite = val;
              } else {
                continue;
              }

              var handler = _getHandler(name, c);
              handler ??= FileBackedColumnHandler(prefix: name);

              try {
                final newVal = await handler.onWrite(name, c, toWrite);
                updates[c] = newVal;
              } catch (e) {
                _log.warning(
                    'Failed to write imported payload for $name.$c: $e');
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
          if (stmt.isEmpty) {
            continue;
          }
          // If the chunk contains CREATE TABLE blocks mixed with comments,
          // extract and execute each CREATE statement individually. This
          // handles bundled migration files where comments precede CREATEs
          // in the same semicolon-delimited chunk.
          if (!applyDml && stmt.toUpperCase().contains('CREATE TABLE')) {
            final createRe =
                RegExp(r'CREATE\s+TABLE[\s\S]*?\)\s*;?', caseSensitive: false);
            final matches = createRe.allMatches(stmt);
            for (final m in matches) {
              final createStmt = m.group(0)!.trim();
              try {
                _log.fine(
                    'Executing extracted CREATE stmt: ${createStmt.length > 200 ? "${createStmt.substring(0, 200)}..." : createStmt}');
                await txn.execute(createStmt);
              } catch (e, st) {
                _log.warning(
                    'Failed to execute extracted CREATE stmt: $createStmt\n$e',
                    e,
                    st);
              }
            }
            continue;
          }
          final up = stmt.toUpperCase();
          if (up == 'BEGIN' ||
              up.startsWith('BEGIN TRANSACTION') ||
              up == 'COMMIT' ||
              up.startsWith('COMMIT')) {
            continue;
          }
          // If DML not allowed, only run schema statements.
          if (!applyDml && !allowedRe.hasMatch(stmt)) {
            _log.fine(
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
