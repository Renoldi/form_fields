import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'payload_utils.dart';
import 'column_handler.dart';
import 'payload_handler.dart' as payload_handler;
import 'package:sqflite/sqflite.dart';

final _log = Logger('DBService');

// Mutable default database name. `init(dbName: ...)` updates this when a
// non-empty value is provided so other APIs can fall back to it.
String _defaultDbName = 'form_fields.db';

String _effectiveDbName(String? dbName) {
  if (dbName == null || dbName.isEmpty) return _defaultDbName;
  return dbName;
}

final _lineCommentRe = RegExp(r'^\s*--.*$', multiLine: true);
final _schemaStatementRe = RegExp(
  r'^(CREATE|PRAGMA|DROP|ALTER)\b',
  caseSensitive: false,
);
final _downgradeNameRe = RegExp(r'down|downgrade', caseSensitive: false);
final _migrationVersionRe = RegExp(r'v?(\d+)');

/// Extracts the schema version from a migration asset name such as `v2.sql`
/// or `migration_3.sql`. Returns null when the file name has no digits.
int? parseMigrationVersion(String assetPath) {
  final m = _migrationVersionRe.firstMatch(p.basename(assetPath));
  return m == null ? null : int.tryParse(m.group(1)!);
}

bool _isTransactionControl(String stmt) {
  final up = stmt.toUpperCase();
  return up == 'BEGIN' ||
      up.startsWith('BEGIN TRANSACTION') ||
      up == 'COMMIT' ||
      up.startsWith('COMMIT');
}

/// Splits a SQL script into statements. Line comments and transaction-control
/// keywords are dropped; the caller runs the statements in its own transaction.
Iterable<String> _sqlStatements(String script) sync* {
  for (final raw in script.split(';')) {
    final cleaned = raw.replaceAll(_lineCommentRe, '').trim();
    if (cleaned.isEmpty || _isTransactionControl(cleaned)) continue;
    yield cleaned;
  }
}

/// Executes every statement of [script] on [executor]. A failing statement is
/// logged and skipped so one bad statement does not abort the whole script.
/// With [schemaOnly] only CREATE / PRAGMA / DROP / ALTER statements run.
Future<void> _executeScript(
  DatabaseExecutor executor,
  String script, {
  required String source,
  bool schemaOnly = false,
}) async {
  for (final stmt in _sqlStatements(script)) {
    if (schemaOnly && !_schemaStatementRe.hasMatch(stmt)) {
      _log.fine('Skipping non-schema statement in $source');
      continue;
    }
    try {
      await executor.execute(stmt);
    } catch (e, st) {
      _log.warning(
        'Failed to execute statement from $source: $stmt\n$e',
        e,
        st,
      );
    }
  }
}

/// Migration assets indexed by version. `up` holds forward migrations and
/// `down` holds assets whose name contains `down` / `downgrade`.
class _MigrationAssets {
  _MigrationAssets._(this.up, this.down);

  factory _MigrationAssets.index(List<String>? paths) {
    final up = <int, String>{};
    final down = <int, String>{};
    var fallbackIndex = 1;
    for (final asset in paths ?? const <String>[]) {
      // Assets without a parseable version get incremental versions in the
      // order they were provided.
      final ver = parseMigrationVersion(asset) ?? fallbackIndex++;
      (_downgradeNameRe.hasMatch(p.basename(asset)) ? down : up)[ver] = asset;
    }
    return _MigrationAssets._(up, down);
  }

  final Map<int, String> up;
  final Map<int, String> down;

  List<int> get upVersions => up.keys.toList()..sort();
  List<int> get downVersionsDesc => down.keys.toList()..sort((a, b) => b - a);
}

/// Splits [s] on commas that are outside quotes and parentheses.
List<String> _splitTopLevel(String s) {
  final out = <String>[];
  var buf = StringBuffer();
  var inSingle = false;
  var inDouble = false;
  var depth = 0;
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (ch == "'" && !inDouble) {
      // An doubled quote inside a single-quoted literal is an escaped quote.
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

/// A single SQL literal: NULL, 'text' (with '' escapes), "text", or a number.
final _sqlLiteralRe = RegExp(
  r'''^(?:(NULL)|'((?:[^']|'')*)'|"((?:[^"]|"")*)"|([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?))$''',
  caseSensitive: false,
);

/// Parses [token] as exactly one literal. Returns null for anything else
/// (expressions, function calls, parameters, several values), so callers can
/// fall back to running the statement as raw SQL.
({Object? value})? _literalOf(String token) {
  final m = _sqlLiteralRe.firstMatch(token.trim());
  if (m == null) return null;
  if (m.group(1) != null) return (value: null);
  if (m.group(2) != null) return (value: m.group(2)!.replaceAll("''", "'"));
  if (m.group(3) != null) return (value: m.group(3)!.replaceAll('""', '"'));
  final number = m.group(4)!;
  return (value: int.tryParse(number) ?? double.parse(number));
}

const _identifier = r'[A-Za-z_][A-Za-z0-9_]*';

/// Statement shapes the typed rewrite accepts. Anchored, so the table name
/// must directly follow the keyword (`UPDATE OR REPLACE` does not match).
final _insertRe = RegExp(
  '^INSERT\\s+INTO\\s+["`]?($_identifier)["`]?\\s*\\(([^)]*)\\)\\s*VALUES\\s*\\((.*)\\)\\s*;?\\s*\$',
  caseSensitive: false,
  dotAll: true,
);
final _updateRe = RegExp(
  '^UPDATE\\s+["`]?($_identifier)["`]?\\s+SET\\s+(.*?)\\s+WHERE\\s+(.*?)\\s*;?\\s*\$',
  caseSensitive: false,
  dotAll: true,
);
final _deleteRe = RegExp(
  '^DELETE\\s+FROM\\s+["`]?($_identifier)["`]?\\s+WHERE\\s+(.*?)\\s*;?\\s*\$',
  caseSensitive: false,
  dotAll: true,
);

/// `column = literal`, with an optionally quoted column name.
final _equalityRe = RegExp(
  '^\\s*["`]?($_identifier)["`]?\\s*=\\s*(.+?)\\s*\$',
  dotAll: true,
);

/// `col = literal` as a typed pair, or null when the value is not a literal.
({String column, Object? value})? _equalityOf(String text) {
  final m = _equalityRe.firstMatch(text);
  if (m == null) return null;
  final literal = _literalOf(m.group(2)!);
  if (literal == null) return null;
  return (column: m.group(1)!, value: literal.value);
}

String _unquote(String s) => s.trim().replaceAll('"', '').replaceAll('`', '');

class DBService {
  DBService._();

  static final DBService instance = DBService._();

  Database? _db;
  Completer<Database>? _initCompleter;

  // Column handlers registry: table -> column -> handler.
  final Map<String, Map<String, ColumnHandler>> _columnHandlers = {};
  // Cache of table -> column names, so PRAGMA table_info runs once per table.
  final Map<String, Set<String>> _tableColumnsCache = {};

  /// Returns the open connection, opening it first when necessary.
  Future<Database> get _database async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    return init();
  }

  void _invalidateSchemaCache() => _tableColumnsCache.clear();

  /// Returns true when the given [table] has a column named [column].
  Future<bool> _tableHasColumn(Database db, String table, String column) async {
    var cols = _tableColumnsCache[table];
    if (cols == null) {
      try {
        final info = await db.rawQuery('PRAGMA table_info($table);');
        cols = info
            .map((r) => r['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();
        _tableColumnsCache[table] = cols;
      } catch (_) {
        return false;
      }
    }
    return cols.contains(column);
  }

  /// Sets `created_at` / `updated_at` in [values] when the table has those
  /// columns. Failures are ignored: timestamps are best-effort.
  Future<void> _ensureTimestamps(
    Database db,
    String table,
    Map<String, dynamic> values, {
    bool setCreated = false,
    bool setUpdated = true,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (setCreated && await _tableHasColumn(db, table, 'created_at')) {
        values['created_at'] = values['created_at'] ?? now;
      }
      if (setUpdated && await _tableHasColumn(db, table, 'updated_at')) {
        values['updated_at'] = values['updated_at'] ?? now;
      }
    } catch (_) {
      // ignore PRAGMA failures
    }
  }

  /// Register a handler for a specific `table` and `column`.
  /// Use table = '*' to register for all tables.
  void registerColumnHandler(
    String table,
    String column,
    ColumnHandler handler,
  ) {
    _columnHandlers.putIfAbsent(table, () => {})[column] = handler;
  }

  /// Unregister handler.
  void unregisterColumnHandler(String table, String column) {
    _columnHandlers[table]?.remove(column);
  }

  ColumnHandler? _getHandler(String table, String column) {
    final byTable = _columnHandlers[table]?[column];
    if (byTable != null) return byTable;
    return _columnHandlers['*']?[column];
  }

  /// Columns of [table] with a handler, including wildcard (`*`) handlers.
  Set<String> _handledColumnsFor(String table) {
    return {...?_columnHandlers[table]?.keys, ...?_columnHandlers['*']?.keys};
  }

  /// Public check whether a handler is registered for [table].[column].
  bool hasColumnHandler(String table, String column) {
    return _getHandler(table, column) != null;
  }

  /// Returns true when a column should be treated as file-backed even when
  /// no explicit ColumnHandler was registered (`payload` or `*_payload`).
  bool isColumnFileBacked(String table, String column) {
    if (_getHandler(table, column) != null) return true;
    return column == 'payload' || column.endsWith('_payload');
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

  Future<int> _readUserVersion(DatabaseExecutor db) async {
    final rows = await db.rawQuery('PRAGMA user_version;');
    if (rows.isEmpty) return 0;
    final first = rows.first.values.first;
    return first is int ? first : int.tryParse(first.toString()) ?? 0;
  }

  Future<void> _writeUserVersion(DatabaseExecutor db, int version) async {
    try {
      await db.execute('PRAGMA user_version = $version');
    } catch (_) {
      // Best-effort: a failed version write must not abort the open.
    }
  }

  /// Runs the schema statements of one migration asset in a transaction.
  /// With [schemaOnly] false, DML statements run too (used for downgrades).
  Future<void> _runAssetInTransaction(
    Database db,
    String asset, {
    required bool schemaOnly,
  }) async {
    try {
      final content = await rootBundle.loadString(asset);
      await db.transaction(
        (txn) =>
            _executeScript(txn, content, source: asset, schemaOnly: schemaOnly),
      );
      _invalidateSchemaCache();
    } catch (e, st) {
      _log.warning('Failed to apply migration asset $asset: $e', e, st);
      rethrow;
    }
  }

  Future<void> _applyUpMigration(
    Database db,
    _MigrationAssets assets,
    int version,
  ) async {
    final asset = assets.up[version];
    if (asset == null) {
      _log.info('No migration asset for version $version');
      return;
    }
    _log.info('Applying migration for version $version from $asset');
    await _runAssetInTransaction(db, asset, schemaOnly: true);
    _log.info('Applied migration asset for version $version');
  }

  Future<void> _applyDownMigration(
    Database db,
    _MigrationAssets assets,
    int version,
  ) async {
    final asset = assets.down[version];
    if (asset == null) {
      _log.warning('No downgrade asset found for version $version; skipping');
      return;
    }
    _log.info('Applying downgrade for version $version from $asset');
    await _runAssetInTransaction(db, asset, schemaOnly: false);
    _log.info('Applied downgrade asset for version $version');
  }

  /// Applies every up migration with `from < version <= to`, in order.
  Future<void> _applyUpgrades(
    Database db,
    _MigrationAssets assets, {
    required int from,
    required int to,
  }) async {
    for (final ver in assets.upVersions) {
      if (ver > from && ver <= to) {
        await _applyUpMigration(db, assets, ver);
      }
    }
  }

  /// Applies every down migration with `to < version <= from`, newest first.
  Future<void> _applyDowngrades(
    Database db,
    _MigrationAssets assets, {
    required int from,
    required int to,
  }) async {
    for (final ver in assets.downVersionsDesc) {
      if (ver <= from && ver > to) {
        await _applyDownMigration(db, assets, ver);
      }
    }
  }

  /// Runs a host callback and logs (instead of throwing) when it fails.
  Future<void> _safeCallback(
    String name,
    Future<void> Function() callback,
  ) async {
    try {
      await callback();
    } catch (e, st) {
      _log.warning('$name callback threw: $e', e, st);
    }
  }

  Future<void> _closeConnection() async {
    final db = _db;
    _db = null;
    // Cached column lists belong to the file that was open.
    _invalidateSchemaCache();
    if (db == null) return;
    try {
      await db.close();
    } catch (_) {}
  }

  /// Initializes (or migrates) the database and makes it the shared
  /// connection. Concurrent callers share one in-flight initialization.
  Future<Database> init({
    String? dbName,
    List<String>? migrationAssetPaths,
    int dbVersion = 0,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
  }) async {
    final inFlight = _initCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<Database>()..future.ignore();
    _initCompleter = completer;
    try {
      final db = await _openOrReconcile(
        dbName: dbName,
        migrationAssetPaths: migrationAssetPaths,
        dbVersion: dbVersion,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen,
      );
      completer.complete(db);
      return db;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  Future<Database> _openOrReconcile({
    String? dbName,
    List<String>? migrationAssetPaths,
    required int dbVersion,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
  }) async {
    final effectiveDb = _effectiveDbName(dbName);
    // A different file was requested: close the current connection so the
    // requested file is opened instead of silently reusing the old one.
    if (_db != null && effectiveDb != _defaultDbName) {
      await _closeConnection();
    }
    _defaultDbName = effectiveDb;

    final assets = _MigrationAssets.index(migrationAssetPaths);

    final open = _db;
    if (open != null && open.isOpen) {
      if (dbVersion <= 0) return open;
      final reconciled = await _reconcileOpenDb(
        open,
        assets,
        dbVersion,
        onUpgrade,
        onDowngrade,
      );
      if (reconciled != null) return reconciled;
    }

    final documents = await getApplicationDocumentsDirectory();
    final path = p.join(documents.path, effectiveDb);
    _log.info('Opening database at $path');

    final versioned = dbVersion > 0;
    final db = await openDatabase(
      path,
      version: versioned ? dbVersion : null,
      onConfigure: onConfigure,
      onCreate: versioned
          ? (db, v) => _onCreate(db, v, assets, onCreate)
          : null,
      onUpgrade: versioned
          ? (db, oldV, newV) => _onUpgrade(db, oldV, newV, assets, onUpgrade)
          : null,
      onDowngrade: versioned
          ? (db, oldV, newV) =>
                _onDowngrade(db, oldV, newV, assets, onDowngrade)
          : null,
      onOpen: (db) => _safeCallback('onOpen', () async {
        await onOpen?.call(db);
      }),
    );
    _db = db;
    _invalidateSchemaCache();
    return db;
  }

  /// Brings an already-open connection to [dbVersion]. Returns null when the
  /// reconciliation failed; the connection is then closed and reopened.
  Future<Database?> _reconcileOpenDb(
    Database db,
    _MigrationAssets assets,
    int dbVersion,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
  ) async {
    try {
      final curVersion = await _readUserVersion(db);
      if (curVersion == dbVersion) return db;

      if (dbVersion > curVersion) {
        _log.info(
          'Detected open DB version $curVersion, upgrading to $dbVersion',
        );
        await _applyUpgrades(db, assets, from: curVersion, to: dbVersion);
        await _writeUserVersion(db, dbVersion);
        await _safeCallback('onUpgrade', () async {
          await onUpgrade?.call(db, curVersion, dbVersion);
        });
        return db;
      }

      _log.info(
        'Detected open DB version $curVersion, downgrading to $dbVersion',
      );
      await _applyDowngrades(db, assets, from: curVersion, to: dbVersion);
      await _writeUserVersion(db, dbVersion);
      await _safeCallback('onDowngrade', () async {
        await onDowngrade?.call(db, curVersion, dbVersion);
      });
      return db;
    } catch (e, st) {
      _log.warning('Failed to reconcile open DB version: $e', e, st);
      await _closeConnection();
      return null;
    }
  }

  Future<void> _onCreate(
    Database db,
    int version,
    _MigrationAssets assets,
    OnDatabaseCreateFn? hook,
  ) async {
    _log.info('onCreate: creating DB up to version $version');
    try {
      await _runBaseSchema(db);
      for (final ver in assets.upVersions) {
        if (ver <= version) await _applyUpMigration(db, assets, ver);
      }
      await _safeCallback('onCreate', () async {
        await hook?.call(db, version);
      });
    } catch (e, st) {
      _log.warning('Failed during onCreate migrations: $e', e, st);
    }
  }

  Future<void> _onUpgrade(
    Database db,
    int oldV,
    int newV,
    _MigrationAssets assets,
    OnDatabaseVersionChangeFn? hook,
  ) async {
    _log.info('onUpgrade: $oldV -> $newV');
    await _applyUpgrades(db, assets, from: oldV, to: newV);
    await _safeCallback('onUpgrade', () async {
      await hook?.call(db, oldV, newV);
    });
  }

  Future<void> _onDowngrade(
    Database db,
    int oldV,
    int newV,
    _MigrationAssets assets,
    OnDatabaseVersionChangeFn? hook,
  ) async {
    _log.info('onDowngrade: $oldV -> $newV');
    await _applyDowngrades(db, assets, from: oldV, to: newV);
    await _safeCallback('onDowngrade', () async {
      await hook?.call(db, oldV, newV);
    });
  }

  /// Creates the base schema from `migrations/migration.sql` when bundled.
  Future<void> _runBaseSchema(Database db) async {
    try {
      final base = await rootBundle.loadString('migrations/migration.sql');
      if (base.trim().isEmpty) return;
      await _executeScript(
        db,
        base,
        source: 'migrations/migration.sql',
        schemaOnly: true,
      );
      _log.info('Database initialized from migrations/migration.sql');
    } catch (_) {
      // The base schema is optional.
    }
  }

  Future<void> close() => _closeConnection();

  /// Delete the on-disk database file and optionally the `migrations` folder.
  /// This also closes any open connection and clears the cached instance.
  Future<void> deleteDatabaseFile({
    String? dbName,
    bool removeMigrationsDir = false,
    bool removePayloadsDir = false,
  }) async {
    await close();
    try {
      final documents = await getApplicationDocumentsDirectory();
      final effective = _effectiveDbName(dbName);
      final dbPath = p.join(documents.path, effective);
      try {
        await deleteDatabase(dbPath);
      } catch (_) {
        // fall back to manual deletion below
      }
      for (final suffix in const ['', '-wal', '-shm', '-journal']) {
        final file = File('$dbPath$suffix');
        if (await file.exists()) await file.delete();
      }
      if (removeMigrationsDir) {
        final dir = Directory(p.join(documents.path, 'migrations'));
        if (await dir.exists()) await dir.delete(recursive: true);
      }
      if (removePayloadsDir) {
        final dir = Directory(
          p.join(documents.path, payload_handler.payloadDirName),
        );
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    } catch (e, st) {
      _log.warning('Failed to delete DB file: $e', e, st);
    }
  }

  /// Reset the database by deleting the file and optionally re-initializing
  /// it from bundled assets.
  Future<void> resetDatabase({
    String? dbName,
    bool removeMigrationsDir = false,
    bool removePayloadsDir = false,
    bool reinit = true,
  }) async {
    await deleteDatabaseFile(
      dbName: dbName,
      removeMigrationsDir: removeMigrationsDir,
      removePayloadsDir: removePayloadsDir,
    );
    if (reinit) {
      await init(dbName: dbName);
    }
  }

  /// Set SQLite `user_version`. Uses the open connection when it points at
  /// the same file; otherwise opens a short-lived connection. The shared
  /// connection is never closed here.
  Future<void> setUserVersion(int version, {String? dbName}) async {
    final effective = _effectiveDbName(dbName);
    try {
      final open = _db;
      if (open != null && open.isOpen && effective == _defaultDbName) {
        await open.execute('PRAGMA user_version = $version');
      } else {
        final documents = await getApplicationDocumentsDirectory();
        final transient = await openDatabase(p.join(documents.path, effective));
        try {
          await transient.execute('PRAGMA user_version = $version');
        } finally {
          try {
            await transient.close();
          } catch (_) {}
        }
      }
      _log.info('Set PRAGMA user_version = $version');
    } catch (e, st) {
      _log.warning('Failed to set PRAGMA user_version = $version: $e', e, st);
      rethrow;
    }
  }

  /// Migrate the open (or on-disk) database to [targetVersion]. Convenience
  /// wrapper around `init` that forwards migration assets and callbacks.
  Future<Database> migrateTo({
    String? dbName,
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
  Future<Database> upgradeTo(
    int targetVersion, {
    String? dbName,
    List<String>? migrationAssetPaths,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseOpenFn? onOpen,
  }) async => await migrateTo(
    dbName: dbName,
    targetVersion: targetVersion,
    migrationAssetPaths: migrationAssetPaths,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
    onOpen: onOpen,
  );

  /// Convenience wrapper to migrate down to [targetVersion].
  Future<Database> downgradeTo(
    int targetVersion, {
    String? dbName,
    List<String>? migrationAssetPaths,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
  }) async => await migrateTo(
    dbName: dbName,
    targetVersion: targetVersion,
    migrationAssetPaths: migrationAssetPaths,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onDowngrade: onDowngrade,
    onOpen: onOpen,
  );

  /// Structured SELECT helper for a single table. When [inlinePayloads] is
  /// true, columns with handlers inline their JSON payloads.
  Future<List<Map<String, dynamic>>> selectFrom(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    bool inlinePayloads = true,
  }) async {
    final db = await _database;
    try {
      final rows = (await db.query(
        table,
        distinct: distinct ?? false,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      )).map((e) => Map<String, dynamic>.from(e)).toList();

      await PayloadUtils.inlinePayloadsForRows(
        table,
        rows,
        inlinePayloads: inlinePayloads,
        payloadDecoder: null,
        getHandler: (t, c) => _getHandler(t, c),
        isColumnFileBacked: (t, c) => isColumnFileBacked(t, c),
        readPayloadJson: (fn) => readPayloadJson(fn),
      );

      return rows;
    } catch (e, st) {
      _log.warning('selectFrom failed: $e', e, st);
      rethrow;
    }
  }

  /// Select a single row from [table] using the same options as `selectFrom`.
  /// Returns `null` when no row matches.
  Future<Map<String, dynamic>?> selectOneFrom(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? offset,
    bool inlinePayloads = true,
  }) async {
    final rows = await selectFrom(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: 1,
      offset: offset,
      inlinePayloads: inlinePayloads,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Return rows from `sqlite_master`. When [includeInternal] is false
  /// (default), internal `sqlite_*` objects are excluded.
  Future<List<Map<String, dynamic>>> selectSqliteMaster({
    bool includeInternal = false,
  }) async {
    final db = await _database;
    try {
      final q = includeInternal
          ? "SELECT * FROM sqlite_master"
          : "SELECT * FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY name";
      return (await db.rawQuery(
        q,
      )).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e, st) {
      _log.warning('selectSqliteMaster failed: $e', e, st);
      rethrow;
    }
  }

  /// Read the database `user_version` and return it as an `int`.
  Future<int?> selectDbVersion() async {
    final db = await _database;
    try {
      final pragma = await db.rawQuery('PRAGMA user_version;');
      if (pragma.isEmpty) return null;
      final first = pragma.first.values.first;
      return first is int ? first : int.tryParse(first.toString());
    } catch (e, st) {
      _log.warning('selectDbVersion failed: $e', e, st);
      rethrow;
    }
  }

  /// Return the full filesystem path to the database file stored in the
  /// application's documents directory.
  Future<String> getDbPath({String? dbName}) async {
    final documents = await getApplicationDocumentsDirectory();
    return p.join(documents.path, _effectiveDbName(dbName));
  }

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    bool autoHandlePayload = true,
  }) async {
    final db = await _database;
    final prepared = autoHandlePayload
        ? await _processPayloadColumns(
            db,
            table,
            values,
            setCreated: true,
            setUpdated: false,
          )
        : values;
    return await db.insert(table, prepared);
  }

  /// Insert or update (upsert) a row into [table]. Uses SQLite conflict
  /// resolution to replace an existing row on a unique/primary key conflict.
  Future<int> insertOrUpdate(
    String table,
    Map<String, dynamic> values, {
    bool autoHandlePayload = true,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    final db = await _database;
    final prepared = autoHandlePayload
        ? await _processPayloadColumns(
            db,
            table,
            values,
            setCreated: true,
            setUpdated: true,
          )
        : values;
    return await db.insert(
      table,
      prepared,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values,
    String where,
    List<dynamic> whereArgs, {
    bool autoHandlePayload = true,
  }) async {
    final db = await _database;
    final prepared = autoHandlePayload
        ? await _processPayloadColumns(
            db,
            table,
            values,
            setCreated: false,
            setUpdated: true,
          )
        : values;
    return await db.update(table, prepared, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs, {
    bool autoCleanupOnDelete = true,
  }) async {
    final db = await _database;
    // Only look up the rows when a handler could clean something up.
    final handled = autoCleanupOnDelete
        ? _handledColumnsFor(table)
        : const <String>{};
    if (handled.isNotEmpty) {
      await _runDeleteHandlers(db, table, where, whereArgs, handled);
    }
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> _runDeleteHandlers(
    Database db,
    String table,
    String where,
    List<dynamic> whereArgs,
    Set<String> handled,
  ) async {
    try {
      final rows = await db.query(table, where: where, whereArgs: whereArgs);
      for (final row in rows) {
        for (final col in handled) {
          if (!row.containsKey(col)) continue;
          final handler = _getHandler(table, col);
          if (handler == null) continue;
          try {
            await handler.onDelete(table, col, row);
          } catch (e, st) {
            _log.warning('Handler onDelete failed for $table.$col: $e', e, st);
          }
        }
      }
    } catch (e) {
      _log.warning('Failed to cleanup column handlers before delete: $e');
    }
  }

  /// Execute a SQL statement. Simple single-table `INSERT` / `UPDATE` /
  /// `DELETE` statements are routed through the typed helpers so column
  /// handlers and timestamps still apply; anything else runs as raw SQL.
  ///
  /// Returns:
  /// - for `INSERT`: the inserted row id
  /// - for `UPDATE` / `DELETE`: the number of affected rows
  /// - for other statements: 0
  Future<int> executeSqlInsUpDel(String sql) async {
    final db = await _database;
    final stmt = sql.trim();
    try {
      final up = stmt.toUpperCase();
      // A null result means "not a simple literal statement": run it raw.
      // Errors from the typed path propagate and are never replayed.
      if (up.startsWith('INSERT')) {
        return await _rewriteInsert(db, stmt) ?? await db.rawInsert(sql);
      } else if (up.startsWith('UPDATE')) {
        return await _rewriteUpdate(db, stmt) ?? await db.rawUpdate(sql);
      } else if (up.startsWith('DELETE')) {
        return await _rewriteDelete(stmt) ?? await db.rawDelete(sql);
      } else {
        await db.execute(sql);
        _invalidateSchemaCache(); // DDL can change the column layout
        return 0;
      }
    } catch (e, st) {
      _log.warning('Failed to execute SQL: $e', e, st);
      rethrow;
    }
  }

  /// Routes `INSERT INTO t (cols) VALUES (literals)` through [insert]. Returns
  /// null when the statement is not a plain literal insert.
  Future<int?> _rewriteInsert(Database db, String stmt) async {
    final m = _insertRe.firstMatch(stmt);
    if (m == null) return null;
    final table = m.group(1)!;
    final columns = m.group(2)!.split(',').map(_unquote).toList();
    final values = _splitTopLevel(m.group(3)!);
    if (columns.length != values.length || columns.any((c) => c.isEmpty)) {
      return null;
    }
    final row = <String, dynamic>{};
    for (var i = 0; i < columns.length; i++) {
      final literal = _literalOf(values[i]);
      if (literal == null) return null;
      row[columns[i]] = literal.value;
    }
    await _ensureTimestamps(db, table, row, setCreated: true, setUpdated: true);
    return insert(table, row);
  }

  /// Routes `UPDATE t SET col = literal[, ...] WHERE col = literal` through
  /// [update]. Returns null for anything else (expressions, compound WHERE,
  /// no WHERE clause).
  Future<int?> _rewriteUpdate(Database db, String stmt) async {
    final m = _updateRe.firstMatch(stmt);
    if (m == null) return null;
    final table = m.group(1)!;
    final values = <String, dynamic>{};
    for (final assignment in _splitTopLevel(m.group(2)!)) {
      final a = _equalityOf(assignment);
      if (a == null) return null;
      values[a.column] = a.value;
    }
    if (values.isEmpty) return null;
    final where = _equalityOf(m.group(3)!);
    if (where == null) return null;
    await _ensureTimestamps(
      db,
      table,
      values,
      setCreated: false,
      setUpdated: true,
    );
    return update(table, values, '${where.column} = ?', [where.value]);
  }

  /// Routes `DELETE FROM t WHERE col = literal` through [delete]. Returns null
  /// for anything else.
  Future<int?> _rewriteDelete(String stmt) async {
    final m = _deleteRe.firstMatch(stmt);
    if (m == null) return null;
    final where = _equalityOf(m.group(2)!);
    if (where == null) return null;
    return delete(m.group(1)!, '${where.column} = ?', [where.value]);
  }

  /// Read payload file content as string. Returns null if file does not exist.
  Future<String?> readPayloadString(String filename) async {
    return await payload_handler.readPayloadString(filename);
  }

  /// Read and decode JSON payload file. Returns decoded object or null.
  Future<dynamic> readPayloadJson(String filename) async {
    return await payload_handler.readPayloadJson(filename);
  }

  Future<void> exportToSqlFile(
    String destPath, {
    String? dbName,
    bool inlinePayloads = true,
  }) async {
    final effective = _effectiveDbName(dbName);

    Database db;
    var transient = false;
    if (_db == null || effective != _defaultDbName) {
      // Open a transient connection to the requested DB file.
      transient = true;
      final documents = await getApplicationDocumentsDirectory();
      db = await openDatabase(p.join(documents.path, effective));
    } else {
      db = _db!;
    }

    try {
      final sb = StringBuffer();

      final tables = await db.rawQuery(
        "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      );

      for (final row in tables) {
        final name = row['name'] as String?;
        final createSql = row['sql'] as String?;
        if (name == null || createSql == null) continue;
        sb.writeln('$createSql;');

        if (inlinePayloads) {
          final rows = await db.rawQuery('SELECT rowid, * FROM "$name"');
          for (final r in rows) {
            final outRow = Map<String, dynamic>.from(r)..remove('rowid');
            final cols = outRow.keys.toList();
            final vals = <String>[];
            for (final c in cols) {
              final v = outRow[c];
              if (_getHandler(name, c) != null && v is String) {
                // Columns with handlers hold a payload file name: inline it.
                final payload = await readPayloadString(v);
                if (payload != null) {
                  vals.add(_valueToSqlLiteral(payload));
                  continue;
                }
              }
              vals.add(_valueToSqlLiteral(v));
            }
            final columns = cols.map((c) => '"$c"').join(', ');
            sb.writeln(
              'INSERT INTO "$name" ($columns) VALUES (${vals.join(', ')});',
            );
          }
        } else {
          final rows = await db.query(name);
          for (final r in rows) {
            final columns = r.keys.map((c) => '"$c"').join(', ');
            final values = r.values
                .map((v) => _valueToSqlLiteral(v))
                .join(', ');
            sb.writeln('INSERT INTO "$name" ($columns) VALUES ($values);');
          }
        }
        sb.writeln();
      }

      final file = File(destPath);
      await file.create(recursive: true);
      await file.writeAsString(sb.toString());
      _log.info('Exported SQL to $destPath');
    } finally {
      if (transient) {
        try {
          await db.close();
        } catch (_) {}
      }
    }
  }

  Future<void> importFromSqlFile(
    String filePath, {
    bool convertInlinePayloads = true,
  }) async {
    final db = await _database;
    final content = await File(filePath).readAsString();
    final insertRe = RegExp(
      r'^\s*INSERT\s+INTO\s+(?:["`])?([A-Za-z0-9_]+)(?:["`])?',
      caseSensitive: false,
    );

    await db.transaction((txn) async {
      // Table existence is checked once per table, not once per statement.
      final existing = <String, bool>{};
      for (final stmt in content.split(';')) {
        final trimmed = stmt.trim();
        if (trimmed.isEmpty) continue;
        try {
          final m = insertRe.firstMatch(trimmed);
          if (m != null) {
            final tableName = m.group(1)!;
            final known = existing[tableName] ??= (await txn.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
              [tableName],
            )).isNotEmpty;
            if (!known) {
              _log.info('Skipping INSERT into missing table `$tableName`.');
              continue;
            }
          }
          await txn.execute(trimmed);
        } catch (e) {
          _log.warning('Failed to execute statement: $trimmed\n$e');
        }
      }
    });

    if (convertInlinePayloads) {
      try {
        await _convertInlineJsonPayloads(db);
      } catch (e, st) {
        _log.warning('Post-processing imported payloads failed: $e', e, st);
      }
    }

    _invalidateSchemaCache();
    _log.info('Imported SQL from $filePath');
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

  /// Import sample/demo inserts packaged as an asset. Returns the temporary
  /// file path used for import on success, or null on failure.
  Future<String?> importSampleInserts({
    String assetPath = 'migrations/sample_inserts.sql',
    bool convertInlinePayloads = true,
  }) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      if (content.trim().isEmpty) return null;
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = p.join(
        tmpDir.path,
        'sample_inserts_${DateTime.now().millisecondsSinceEpoch}.sql',
      );
      final f = File(tmpPath);
      await f.create(recursive: true);
      await f.writeAsString(content);
      await importFromSqlFile(
        tmpPath,
        convertInlinePayloads: convertInlinePayloads,
      );
      _log.info('Imported sample inserts from $assetPath');
      return tmpPath;
    } catch (e, st) {
      _log.warning(
        'Failed to import sample inserts asset $assetPath: $e',
        e,
        st,
      );
      return null;
    }
  }

  /// Run a migration SQL asset. By default only schema statements (CREATE,
  /// ALTER, DROP, PRAGMA) are applied so sample data is not imported. Set
  /// [applyDml] to true to also run DML (INSERT/UPDATE/DELETE).
  Future<void> runMigrationAsset(
    String assetPath, {
    bool applyDml = false,
  }) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      if (content.trim().isEmpty) {
        _log.info('Migration asset $assetPath is empty');
        return;
      }
      final db = await _database;
      await db.transaction(
        (txn) => _executeScript(
          txn,
          content,
          source: assetPath,
          schemaOnly: !applyDml,
        ),
      );
      _invalidateSchemaCache();
      _log.info('Applied migration asset: $assetPath (applyDml=$applyDml)');
    } catch (e, st) {
      _log.warning('Failed to apply migration asset $assetPath: $e', e, st);
      rethrow;
    }
  }

  Future<String> copyDatabaseFile(String destPath, {String? dbName}) async {
    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, _effectiveDbName(dbName)));
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
