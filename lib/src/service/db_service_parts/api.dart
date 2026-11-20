part of '../db_service.dart';

extension _DBServiceCrudX on DBService {
  Future<List<Map<String, dynamic>>> _selectFrom(
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

      await payload_handler.PayloadUtils.inlinePayloadsForRows(
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

  Future<Map<String, dynamic>?> _selectOneFrom(
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

  Future<List<Map<String, dynamic>>> _selectSqliteMaster({
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

  Future<int?> _selectDbVersion() async {
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

  Future<int> _insert(
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

  Future<int> _insertOrUpdate(
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
    final handled = autoHandlePayload
        ? _handledColumnsFor(table).where(values.containsKey).toSet()
        : const <String>{};
    // A replaced row takes its payload files with it: release them when no
    // other row still refers to them.
    if (handled.isEmpty || conflictAlgorithm != ConflictAlgorithm.replace) {
      return await db.insert(
        table,
        prepared,
        conflictAlgorithm: conflictAlgorithm,
      );
    }
    return await db.transaction((txn) async {
      final replaced = await _rowsWithSamePrimaryKey(txn, table, values);
      final id = await txn.insert(
        table,
        prepared,
        conflictAlgorithm: conflictAlgorithm,
      );
      await _releaseUnreferencedPayloads(txn, table, replaced, handled);
      return id;
    });
  }

  Future<int> _update(
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
    // Payload files that the updated rows stop using are released, unless
    // another row still refers to them.
    final handled = autoHandlePayload
        ? _handledColumnsFor(table).where(values.containsKey).toSet()
        : const <String>{};
    if (handled.isEmpty) {
      return await db.update(
        table,
        prepared,
        where: where,
        whereArgs: whereArgs,
      );
    }
    return await db.transaction((txn) async {
      final before = await txn.query(table, where: where, whereArgs: whereArgs);
      final count = await txn.update(
        table,
        prepared,
        where: where,
        whereArgs: whereArgs,
      );
      await _releaseUnreferencedPayloads(txn, table, before, handled);
      return count;
    });
  }

  Future<int> _delete(
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
    if (handled.isEmpty) {
      return await db.delete(table, where: where, whereArgs: whereArgs);
    }
    return await db.transaction((txn) async {
      final doomed = await txn.query(table, where: where, whereArgs: whereArgs);
      final count = await txn.delete(table, where: where, whereArgs: whereArgs);
      await _releaseUnreferencedPayloads(txn, table, doomed, handled);
      return count;
    });
  }
}

extension _DBServiceLifecycleX on DBService {
  Future<Database> _init({
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

  Future<void> _deleteDatabaseFile({
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

  Future<void> _resetDatabase({
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

  Future<void> _setUserVersion(int version, {String? dbName}) async {
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

  Future<Database> _migrateTo({
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
}
