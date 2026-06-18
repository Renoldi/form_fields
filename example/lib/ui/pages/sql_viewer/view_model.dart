import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:form_fields/form_fields.dart';

class SqlViewerViewModel extends ChangeNotifier {
  final DBService _db = DBService.instance;

  List<String> tables = [];
  String? selectedTable;
  List<Map<String, dynamic>> rows = [];
  List<String> tablesBeforeUpgrade = [];
  List<String> tablesAfterUpgrade = [];
  String? lastUpgradeError;
  int? dbVersion;

  bool loading = false;

  Future<void> loadTables() async {
    loading = true;
    notifyListeners();
    try {
      // Use DBService helpers to read schema and PRAGMA.
      final masterRows = await _db.selectSqliteMaster();
      // Filter for tables and extract the name column.
      tables = masterRows
          .where((r) => (r['type']?.toString() ?? '') == 'table')
          .map((r) => r['name'].toString())
          .toList();

      try {
        dbVersion = await _db.selectDbVersion();
      } catch (_) {
        dbVersion = null;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Load only the `PRAGMA user_version` into `dbVersion`.
  Future<void> loadDbVersion() async {
    try {
      dbVersion = await _db.selectDbVersion();
    } catch (_) {
      dbVersion = null;
    }
    notifyListeners();
  }

  Future<void> loadRows(String table, {bool inlinePayloads = false}) async {
    loading = true;
    notifyListeners();
    try {
      selectedTable = table;
      final db = await _db.init();
      final results =
          await db.rawQuery('SELECT rowid, * FROM "$table" LIMIT 500');
      rows = results.map((r) => Map<String, dynamic>.from(r)).toList();

      // Post-process rows: if a column looks like a payload filename (ends
      // with .json) or has a registered handler, attempt to read and decode
      // the payload and inline it. Allow inlinePayloads toggle or fallback
      // to only first row when inlinePayloads == false.
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final shouldInline = inlinePayloads ? true : (i == 0);
        final keys = r.keys.toList();
        for (final k in keys) {
          final v = r[k];
          if (!shouldInline) continue;
          if (v is String) {
            final s = v.trim();
            try {
              // If there's a handler, or column naming suggests a payload,
              // or the stored value itself looks like a filename, attempt
              // to read the payload file.
              final fnRe =
                  RegExp(r'^[A-Za-z0-9._-]+\.json$', caseSensitive: false);
              final looksLikeFilename = fnRe.hasMatch(s);
              if (_db.hasColumnHandler(table, k) ||
                  _db.isColumnFileBacked(table, k) ||
                  looksLikeFilename) {
                final decoded = await _db.readPayloadJson(s);
                if (decoded != null) {
                  r[k] = decoded;
                  continue;
                }
              }
            } catch (_) {}

            // Fallback: if stored value itself is JSON text, decode it.
            try {
              if (s.startsWith('{') || s.startsWith('[')) {
                r[k] = json.decode(s);
              }
            } catch (_) {}
          }
        }
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRow(String table, int rowid) async {
    // final db = await _db.init();
    // await db.delete(table, where: 'rowid = ?', whereArgs: [rowid]);
    await _db.delete(table, 'rowid = ?', [rowid]);
    await loadRows(table);
  }

  /// Capture table list, change DB version (upgrade or downgrade), then
  /// capture the table list again. Stores before/after lists in
  /// `tablesBeforeUpgrade`/`tablesAfterUpgrade` and sets `lastUpgradeError`
  /// on failure.
  Future<void> changeDbVersionAndCaptureTables(int targetVersion,
      {List<String>? migrationAssetPaths}) async {
    loading = true;
    notifyListeners();
    lastUpgradeError = null;
    try {
      final db = await _db.init();
      final before = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
      tablesBeforeUpgrade = before.map((r) => r['name'].toString()).toList();

      try {
        await _db.migrateTo(
            targetVersion: targetVersion,
            migrationAssetPaths: migrationAssetPaths);
      } catch (e) {
        lastUpgradeError = e.toString();
      }

      // Ensure PRAGMA user_version is set to targetVersion in case the
      // migration flow did not update it automatically.
      try {
        await _db.setUserVersion(targetVersion);
      } catch (e) {
        lastUpgradeError = lastUpgradeError == null
            ? 'Failed to set user_version: $e'
            : '$lastUpgradeError\nFailed to set user_version: $e';
      }

      // Re-open DB (if needed) and read schema + PRAGMA from disk.
      final freshDb = await _db.init();
      final after = await freshDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
      tablesAfterUpgrade = after.map((r) => r['name'].toString()).toList();
      try {
        final pragma2 = await freshDb.rawQuery('PRAGMA user_version;');
        if (pragma2.isNotEmpty) {
          final first2 = pragma2.first.values.first;
          if (first2 is int) {
            dbVersion = first2;
          } else {
            dbVersion = int.tryParse(first2.toString()) ?? dbVersion;
          }
        }
      } catch (_) {}
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Backwards-compatible wrapper named `upgradeAndCaptureTables`.
  Future<void> upgradeAndCaptureTables(int targetVersion,
          {List<String>? migrationAssetPaths}) async =>
      await changeDbVersionAndCaptureTables(targetVersion,
          migrationAssetPaths: migrationAssetPaths);

  /// Explicit downgrade wrapper for clarity.
  Future<void> downgradeAndCaptureTables(int targetVersion,
          {List<String>? migrationAssetPaths}) async =>
      await changeDbVersionAndCaptureTables(targetVersion,
          migrationAssetPaths: migrationAssetPaths);

  /// Clear loaded tables/rows state without initializing the DB.
  void clearState() {
    tables = [];
    rows = [];
    selectedTable = null;
    tablesBeforeUpgrade = [];
    tablesAfterUpgrade = [];
    lastUpgradeError = null;
    notifyListeners();
  }

  /// Set PRAGMA user_version directly.
  Future<void> setUserVersion(int version) async {
    loading = true;
    notifyListeners();
    try {
      await _db.setUserVersion(version);
      // Read PRAGMA using DBService helper to keep behavior consistent.
      try {
        final v = await _db.selectDbVersion();
        dbVersion = v ?? version;
      } catch (_) {
        dbVersion = version;
      }
    } catch (e) {
      lastUpgradeError = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Convert a DB row to pretty JSON. If [includePayloads] is true,
  /// attempts to read any filename values ending with `.json` and inline
  /// their decoded payloads.
  Future<String> rowToPrettyJson(Map<String, dynamic> row,
      {bool includePayloads = false}) async {
    final copy = Map<String, dynamic>.from(row);
    if (includePayloads) {
      final keys = copy.keys.toList();
      for (final k in keys) {
        final v = copy[k];
        if (v is String) {
          final s = v.trim();
          if (s.endsWith('.json')) {
            try {
              final decoded = await _db.readPayloadJson(s);
              if (decoded != null) copy[k] = decoded;
            } catch (_) {
              // ignore - leave filename as-is
            }
          }
        }
      }
    }
    return const JsonEncoder.withIndent('  ').convert(copy);
  }
}
