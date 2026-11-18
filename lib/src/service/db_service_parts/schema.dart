part of '../db_service.dart';

final _lineCommentRe = RegExp(r'^\s*--.*$', multiLine: true);

final _schemaStatementRe = RegExp(
  r'^(CREATE|PRAGMA|DROP|ALTER)\b',
  caseSensitive: false,
);

final _downgradeNameRe = RegExp(r'down|downgrade', caseSensitive: false);

final _migrationVersionRe = RegExp(r'v?(\d+)');

final _triggerStartRe = RegExp(
  r'^\s*CREATE\s+(TEMP\s+|TEMPORARY\s+)?TRIGGER\b',
  caseSensitive: false,
);

final _endsWithEndRe = RegExp(r'\bEND\s*$', caseSensitive: false);

extension _DBServiceSchemaX on DBService {
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

  Future<int> _readUserVersion(DatabaseExecutor db) async {
    final rows = await db.rawQuery('PRAGMA user_version;');
    if (rows.isEmpty) return 0;
    final first = rows.first.values.first;
    return first is int ? first : int.tryParse(first.toString()) ?? 0;
  }

  Future<void> _writeUserVersion(DatabaseExecutor db, int version) async {
    try {
      await db.execute('PRAGMA user_version = $version');
    } catch (e, st) {
      // Not fatal for the open, but a version that was not recorded means the
      // migrations run again on the next start. That must be visible in logs.
      _log.warning('Failed to record user_version $version: $e', e, st);
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
}

/// Extracts the schema version from a migration asset name such as `v2.sql`
/// or `migration_3.sql`. Returns null when the file name has no digits.
int? parseMigrationVersion(String assetPath) {
  final m = _migrationVersionRe.firstMatch(p.basename(assetPath));
  return m == null ? null : int.tryParse(m.group(1)!);
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
