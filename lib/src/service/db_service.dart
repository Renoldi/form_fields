import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'payload_handler.dart' as payload_handler;
import 'package:sqflite/sqflite.dart';

part 'db_service_parts/schema.dart';
part 'db_service_parts/payloads.dart';
part 'db_service_parts/sql_rewrite.dart';
part 'db_service_parts/api.dart';
part 'db_service_parts/transfer.dart';

final _log = Logger('DBService');

// Mutable default database name. `init(dbName: ...)` updates this when a
// non-empty value is provided so other APIs can fall back to it.
String _defaultDbName = 'form_fields.db';

String _effectiveDbName(String? dbName) {
  if (dbName == null || dbName.isEmpty) return _defaultDbName;
  return dbName;
}

class DBService {
  DBService._();

  static final DBService instance = DBService._();

  Database? _db;
  Completer<Database>? _initCompleter;

  // Column handlers registry: table -> column -> handler.
  final Map<String, Map<String, payload_handler.ColumnHandler>>
  _columnHandlers = {};
  // Cache of table -> column names, so PRAGMA table_info runs once per table.
  final Map<String, Set<String>> _tableColumnsCache = {};

  /// Register a handler for a specific `table` and `column`.
  /// Use table = '*' to register for all tables.
  void registerColumnHandler(
    String table,
    String column,
    payload_handler.ColumnHandler handler,
  ) {
    _columnHandlers.putIfAbsent(table, () => {})[column] = handler;
  }

  /// Unregister handler.
  void unregisterColumnHandler(String table, String column) {
    _columnHandlers[table]?.remove(column);
  }

  /// Public check whether a handler is registered for [table].[column].
  bool hasColumnHandler(String table, String column) {
    return _getHandler(table, column) != null;
  }

  /// Returns true when a column should be treated as file-backed even when
  /// no explicit payload_handler.ColumnHandler was registered (`payload` or `*_payload`).
  bool isColumnFileBacked(String table, String column) {
    if (_getHandler(table, column) != null) return true;
    return column == 'payload' || column.endsWith('_payload');
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
  }) => _init(
    dbName: dbName,
    migrationAssetPaths: migrationAssetPaths,
    dbVersion: dbVersion,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
    onDowngrade: onDowngrade,
    onOpen: onOpen,
  );

  Future<void> close() => _closeConnection();

  /// Delete the on-disk database file and optionally the `migrations` folder.
  /// This also closes any open connection and clears the cached instance.
  Future<void> deleteDatabaseFile({
    String? dbName,
    bool removeMigrationsDir = false,
    bool removePayloadsDir = false,
  }) => _deleteDatabaseFile(
    dbName: dbName,
    removeMigrationsDir: removeMigrationsDir,
    removePayloadsDir: removePayloadsDir,
  );

  /// Reset the database by deleting the file and optionally re-initializing
  /// it from bundled assets.
  Future<void> resetDatabase({
    String? dbName,
    bool removeMigrationsDir = false,
    bool removePayloadsDir = false,
    bool reinit = true,
  }) => _resetDatabase(
    dbName: dbName,
    removeMigrationsDir: removeMigrationsDir,
    removePayloadsDir: removePayloadsDir,
    reinit: reinit,
  );

  /// Set SQLite `user_version`. Uses the open connection when it points at
  /// the same file; otherwise opens a short-lived connection. The shared
  /// connection is never closed here.
  Future<void> setUserVersion(int version, {String? dbName}) =>
      _setUserVersion(version, dbName: dbName);

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
  }) => _migrateTo(
    dbName: dbName,
    targetVersion: targetVersion,
    migrationAssetPaths: migrationAssetPaths,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
    onDowngrade: onDowngrade,
    onOpen: onOpen,
  );

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
  }) => _selectFrom(
    table,
    distinct: distinct,
    columns: columns,
    where: where,
    whereArgs: whereArgs,
    groupBy: groupBy,
    having: having,
    orderBy: orderBy,
    limit: limit,
    offset: offset,
    inlinePayloads: inlinePayloads,
  );

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
  }) => _selectOneFrom(
    table,
    distinct: distinct,
    columns: columns,
    where: where,
    whereArgs: whereArgs,
    groupBy: groupBy,
    having: having,
    orderBy: orderBy,
    offset: offset,
    inlinePayloads: inlinePayloads,
  );

  /// Return rows from `sqlite_master`. When [includeInternal] is false
  /// (default), internal `sqlite_*` objects are excluded.
  Future<List<Map<String, dynamic>>> selectSqliteMaster({
    bool includeInternal = false,
  }) => _selectSqliteMaster(includeInternal: includeInternal);

  /// Read the database `user_version` and return it as an `int`.
  Future<int?> selectDbVersion() => _selectDbVersion();

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
  }) => _insert(table, values, autoHandlePayload: autoHandlePayload);

  /// Insert or update (upsert) a row into [table]. Uses SQLite conflict
  /// resolution to replace an existing row on a unique/primary key conflict.
  Future<int> insertOrUpdate(
    String table,
    Map<String, dynamic> values, {
    bool autoHandlePayload = true,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) => _insertOrUpdate(
    table,
    values,
    autoHandlePayload: autoHandlePayload,
    conflictAlgorithm: conflictAlgorithm,
  );

  Future<int> update(
    String table,
    Map<String, dynamic> values,
    String where,
    List<dynamic> whereArgs, {
    bool autoHandlePayload = true,
  }) => _update(
    table,
    values,
    where,
    whereArgs,
    autoHandlePayload: autoHandlePayload,
  );

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs, {
    bool autoCleanupOnDelete = true,
  }) => _delete(
    table,
    where,
    whereArgs,
    autoCleanupOnDelete: autoCleanupOnDelete,
  );

  /// Execute a SQL statement. Simple single-table `INSERT` / `UPDATE` /
  /// `DELETE` statements are routed through the typed helpers so column
  /// handlers and timestamps still apply; anything else runs as raw SQL.
  ///
  /// Returns:
  /// - for `INSERT`: the inserted row id
  /// - for `UPDATE` / `DELETE`: the number of affected rows
  /// - for other statements: 0
  Future<int> executeSqlInsUpDel(String sql) => _executeSqlInsUpDel(sql);

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
  }) => _exportToSqlFile(
    destPath,
    dbName: dbName,
    inlinePayloads: inlinePayloads,
  );

  Future<void> importFromSqlFile(
    String filePath, {
    bool convertInlinePayloads = true,
  }) => _importFromSqlFile(
    filePath,
    convertInlinePayloads: convertInlinePayloads,
  );

  /// Import sample/demo inserts packaged as an asset. Returns the temporary
  /// file path used for import on success, or null on failure.
  Future<String?> importSampleInserts({
    String assetPath = 'migrations/sample_inserts.sql',
    bool convertInlinePayloads = true,
  }) => _importSampleInserts(
    assetPath: assetPath,
    convertInlinePayloads: convertInlinePayloads,
  );

  /// Run a migration SQL asset. By default only schema statements (CREATE,
  /// ALTER, DROP, PRAGMA) are applied so sample data is not imported. Set
  /// [applyDml] to true to also run DML (INSERT/UPDATE/DELETE).
  Future<void> runMigrationAsset(String assetPath, {bool applyDml = false}) =>
      _runMigrationAsset(assetPath, applyDml: applyDml);

  Future<String> copyDatabaseFile(String destPath, {String? dbName}) async {
    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, _effectiveDbName(dbName)));
    final dest = File(destPath);
    await dest.create(recursive: true);
    await dbFile.copy(dest.path);
    _log.info('Copied DB file to ${dest.path}');
    return dest.path;
  }
}
