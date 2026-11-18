part of '../db_service.dart';

/// A single SQL literal: NULL, 'text' (with '' escapes), "text", or a number.
final _sqlLiteralRe = RegExp(
  r'''^(?:(NULL)|'((?:[^']|'')*)'|"((?:[^"]|"")*)"|([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?))$''',
  caseSensitive: false,
);

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

extension _DBServiceSqlX on DBService {
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

  String _valueToSqlLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    if (value is Uint8List) {
      final hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return "X'$hex'";
    }
    final s = value.toString().replaceAll("'", "''");
    return "'$s'";
  }
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

/// `col = literal` as a typed pair, or null when the value is not a literal.
({String column, Object? value})? _equalityOf(String text) {
  final m = _equalityRe.firstMatch(text);
  if (m == null) return null;
  final literal = _literalOf(m.group(2)!);
  if (literal == null) return null;
  return (column: m.group(1)!, value: literal.value);
}

String _unquote(String s) => s.trim().replaceAll('"', '').replaceAll('`', '');

bool _isTransactionControl(String stmt) {
  final up = stmt.toUpperCase();
  return up == 'BEGIN' ||
      up.startsWith('BEGIN TRANSACTION') ||
      up == 'COMMIT' ||
      up.startsWith('COMMIT');
}

/// Splits a SQL script at `;` that ends a statement. A `;` inside a string
/// literal, a quoted identifier or a comment does not split, so text values
/// such as `'a; b'` survive. A `CREATE TRIGGER` keeps its body whole, since the
/// body's own `;` separators sit between `BEGIN` and `END`.
List<String> _splitSqlScript(String script) {
  final out = <String>[];
  var buf = StringBuffer();
  var quote = ''; // '', "'", '"' or '`' while inside a quoted run
  var inLineComment = false;
  var inBlockComment = false;

  for (var i = 0; i < script.length; i++) {
    final ch = script[i];
    final next = i + 1 < script.length ? script[i + 1] : '';

    if (inLineComment) {
      buf.write(ch);
      if (ch == '\n') inLineComment = false;
      continue;
    }
    if (inBlockComment) {
      buf.write(ch);
      if (ch == '*' && next == '/') {
        buf.write(next);
        i++;
        inBlockComment = false;
      }
      continue;
    }
    if (quote.isNotEmpty) {
      buf.write(ch);
      if (ch == quote) {
        if (next == quote) {
          // A doubled quote inside a literal is an escaped quote.
          buf.write(next);
          i++;
        } else {
          quote = '';
        }
      }
      continue;
    }

    if (ch == '-' && next == '-') {
      inLineComment = true;
      buf.write('--');
      i++;
      continue;
    }
    if (ch == '/' && next == '*') {
      inBlockComment = true;
      buf.write('/*');
      i++;
      continue;
    }
    if (ch == "'" || ch == '"' || ch == '`') {
      quote = ch;
      buf.write(ch);
      continue;
    }
    if (ch == ';') {
      final text = buf.toString();
      final inTriggerBody =
          _triggerStartRe.hasMatch(text) &&
          !_endsWithEndRe.hasMatch(text.trimRight());
      if (inTriggerBody) {
        buf.write(ch);
        continue;
      }
      out.add(text);
      buf = StringBuffer();
      continue;
    }
    buf.write(ch);
  }
  final rest = buf.toString();
  if (rest.trim().isNotEmpty) out.add(rest);
  return out;
}

/// Splits a SQL script into statements. Line comments and transaction-control
/// keywords are dropped; the caller runs the statements in its own transaction.
Iterable<String> _sqlStatements(String script) sync* {
  for (final raw in _splitSqlScript(script)) {
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
