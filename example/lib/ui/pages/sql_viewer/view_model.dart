import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:form_fields/form_fields.dart';

class SqlViewerViewModel extends ChangeNotifier {
  final DBService _db = DBService.instance;

  List<String> tables = [];
  String? selectedTable;
  List<Map<String, dynamic>> rows = [];

  bool loading = false;

  Future<void> loadTables() async {
    loading = true;
    notifyListeners();
    try {
      final db = await _db.init();
      final results = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
      tables = results.map((r) => r['name'].toString()).toList();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadRows(String table) async {
    loading = true;
    notifyListeners();
    try {
      selectedTable = table;
      final db = await _db.init();
      final results =
          await db.rawQuery('SELECT rowid, * FROM "$table" LIMIT 500');
      rows = results.map((r) => Map<String, dynamic>.from(r)).toList();

      // Post-process rows: if a column looks like a payload filename (ends
      // with .json), attempt to read and decode the payload and inline it.
      for (final r in rows) {
        final keys = r.keys.toList();
        for (final k in keys) {
          final v = r[k];
          // Only attempt to inline payloads for columns that have a
          // registered handler (eg. `payload`). Leave other string values
          // untouched.
          if (!_db.hasColumnHandler(table, k)) continue;
          if (v is String) {
            final s = v.trim();
            if (s.endsWith('.json')) {
              try {
                final decoded = await _db.readPayloadJson(s);
                if (decoded != null) r[k] = decoded;
              } catch (_) {
                // ignore - leave filename as-is
              }
            }
          }
        }
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRow(String table, int rowid) async {
    final db = await _db.init();
    await db.delete(table, where: 'rowid = ?', whereArgs: [rowid]);
    await loadRows(table);
  }

  /// Clear loaded tables/rows state without initializing the DB.
  void clearState() {
    tables = [];
    rows = [];
    selectedTable = null;
    notifyListeners();
  }

  String rowToPrettyJson(Map<String, dynamic> row) {
    final copy = Map<String, dynamic>.from(row);
    return const JsonEncoder.withIndent('  ').convert(copy);
  }
}
