part of '../db_service.dart';

extension _DBServiceTransferX on DBService {
  Future<int> _executeSqlInsUpDel(String sql) async {
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

  Future<void> _exportToSqlFile(
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

  Future<void> _importFromSqlFile(
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
      for (final stmt in _splitSqlScript(content)) {
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

  Future<String?> _importSampleInserts({
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

  Future<void> _runMigrationAsset(
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
}
