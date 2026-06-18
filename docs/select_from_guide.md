## DBService usage reference — select, CRUD, utilities, payloads, lifecycle

This document is a consolidated, professional reference showing how to use
the key functions provided by `DBService` in `lib/src/service/db_service.dart`.
It includes function signatures, behavior notes, and copy-paste examples suitable
for the `example/` app.

Contents

- Overview
- `selectFrom` (structured SELECT)
- `select` (raw SQL)
- CRUD: `insert`, `insertOrUpdate`, `update`, `delete`
- Utilities: `executeSqlInsUpDel`, `queryAll`
- Payload helpers: `readPayloadString`, `readPayloadJson`, `exportToSqlFile`, `importFromSqlFile`
- Lifecycle & migrations
- Advanced patterns & best practices
- Complete examples

## Overview

`DBService` is a small, opinionated helper over `sqflite` that:

- Provides a structured `selectFrom` wrapper for single-table queries.
- Preserves and automates file-backed payload handling via `ColumnHandler`.
- Attempts to route simple SQL mutations through higher-level helpers so
  handlers run consistently (`executeSqlInsUpDel`).

Where possible, prefer `selectFrom` (safe parameterized queries) and use
`select` for complex multi-table queries.

## selectFrom (structured SELECT)

Signature (updated):

```
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
  }
)
```

Description:

- Convenience wrapper around `sqflite`'s `db.query` for a single table.
- When `inlinePayloads` is `true`, columns with registered `ColumnHandler`
  will attempt to read JSON payload files and return decoded objects instead
  of raw filenames.

Examples

- Select all columns:

```
final rows = await DBService.instance.selectFrom('asset');
```

- Multiple WHERE (AND):

```
final rows = await DBService.instance.selectFrom(
  'asset',
  where: 'type = ? AND status = ?',
  whereArgs: ['image', 'active'],
);
```

- Grouped conditions (AND/OR):

```
final rows = await DBService.instance.selectFrom(
  'asset',
  where: '(owner_id = ? AND status = ?) OR (shared = ?)',
  whereArgs: [ownerId, 'draft', 1],
);
```

- IN list (dynamic placeholders):

```
final ids = [1,2,3];
final placeholders = List.filled(ids.length, '?').join(',');
final rows = await DBService.instance.selectFrom(
  'asset',
  where: 'id IN ($placeholders)',
  whereArgs: ids,
);
```

Notes

- `columns == null` selects all columns (equivalent to `SELECT *`).
- `whereArgs` is typed as `List<Object?>?` to match `sqflite`'s parameter typing —
  this allows passing `null` values when needed (e.g. for `IS NULL` logic).
- The order of `whereArgs` must match the order of `?` placeholders.
- Use `inlinePayloads: false` to keep filename strings instead of decoding payloads.

New example: distinct + groupBy + having

```
final rows = await DBService.instance.selectFrom(
  'asset',
  distinct: true,
  columns: ['type', 'COUNT(*) as cnt'],
  groupBy: 'type',
  having: 'cnt > 5',
  orderBy: 'cnt DESC',
);
```

## select (raw SQL)

Signature:

```
Future<List<Map<String, dynamic>>> select(String sql,
    {List<dynamic>? params, bool isRaw = false, bool inlinePayloads = true})
```

Description:

- Execute arbitrary SELECT SQL (joins, subqueries, aggregates). Use `params`
  for parameterized arguments.
- `select` will attempt to infer a single table name from `FROM` to enable
  payload inlining; this heuristic may be ambiguous for complex queries.

Example (JOIN):

```
final sql = '''
SELECT a.*, b.meta
FROM asset a
JOIN meta b ON a.id = b.asset_id
WHERE a.type = ?
''';
final rows = await DBService.instance.select(sql, params: ['image']);
```

## CRUD helpers

insert

````
Signature:

```
Future<int> insert(String table, Map<String, dynamic> values,
    {bool autoHandlePayload = true})
```

Behavior:

- Runs registered per-column `onWrite` handlers (or fallback `FileBackedColumnHandler`)
  when `autoHandlePayload` is true. This writes file-backed JSON payloads to disk
  and stores the filename in the DB.

Example:

```
final id = await DBService.instance.insert('asset', {
  'name': 'Site photo',
  'type': 'image',
  'payload': {'width': 1024, 'height': 768},
});
```

insertOrUpdate (upsert)
````

Signature:

```
Future<int> insertOrUpdate(String table, Map<String, dynamic> values,
    {bool autoHandlePayload = true,
     ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace})
```

Example:

```
final id = await DBService.instance.insertOrUpdate('asset', {
  'id': 42,
  'name': 'Updated name',
  'payload': {'foo': 'bar'},
});
```

update

````
Signature:

```
Future<int> update(String table, Map<String, dynamic> values, String where,
    List<dynamic> whereArgs, {bool autoHandlePayload = true})
```

Example:

```
final count = await DBService.instance.update(
  'asset',
  {'status': 'archived'},
  'id = ?',
  [42],
);
```

delete
````

Signature:

```
Future<int> delete(String table, String where, List<dynamic> whereArgs,
    {bool autoCleanupOnDelete = true})
```

Behavior:

- When `autoCleanupOnDelete` is true, the service queries matching rows and
  invokes registered `onDelete` handlers so file-backed payloads can be removed.

Example:

```
final deleted = await DBService.instance.delete('asset', 'status = ?', ['archived']);
```

## Utilities

executeSqlInsUpDel

````
Signature:

```
Future<int> executeSqlInsUpDel(String sql, {bool isRaw = false})
```

Description:

- Executes raw SQL. If `isRaw` is false, the method attempts to parse simple
  INSERT/UPDATE/DELETE statements and route them through `insert`/`update`/`delete`
  so column handlers run. Returns affected rows or inserted id where applicable.

Example:

```
final res = await DBService.instance.executeSqlInsUpDel(
  "UPDATE asset SET status = 'active' WHERE id = 7"
);
```

queryAll
~~~~~~~

```
Future<List<Map<String, dynamic>>> queryAll(String table)
```

Shorthand for `db.query(table)`.

Payload helpers and import/export
--------------------------------
readPayloadString / readPayloadJson

```
Future<String?> readPayloadString(String filename)
Future<dynamic> readPayloadJson(String filename)
```

exportToSqlFile / importFromSqlFile

- `exportToSqlFile(destPath, inlinePayloads: true)` — writes CREATE and INSERT
  statements to `destPath`. When `inlinePayloads` is true, payload file contents
  will be embedded into INSERTs instead of filenames.
- `importFromSqlFile(filePath, convertInlinePayloads: true)` — executes statements
  in the SQL file and optionally converts inline JSON strings into payload files
  and updates rows to store filenames.

Lifecycle & migrations
----------------------
- `init(...)` — open DB, apply migrations from assets when provided.
- `migrateTo/upgradeTo/downgradeTo` — convenience wrappers for migrating.
- `resetDatabase`, `deleteDatabaseFile`, `setUserVersion` — maintenance helpers.

Advanced patterns & best practices
---------------------------------

- Use `where` + `whereArgs` placeholders to prevent SQL injection and ensure
  correct type-binding by `sqflite`.
- For dynamic `IN (...)` lists, programmatically build `?` placeholders equal to
  the list length and pass the list as `whereArgs`.
- Prefer `selectFrom` for single-table CRUD reads; use `select` for joins and
  aggregates where `db.query` is not sufficient.
- For batch writes/updates/deletes that must be atomic, wrap operations in a
  `db.transaction` (use `DBService.instance._db` after `init()` or expose a
  wrapper if needed).
- When working with payload-handling columns, be mindful of `inlinePayloads`:
  if you intend to transfer DB dumps between devices, exporting with
  `inlinePayloads: true` produces self-contained SQL files that import cleanly.

Complete examples
-----------------

1) Full read with grouping, ordering, limit:

```
final rows = await DBService.instance.selectFrom(
  'asset',
  columns: ['id','name','payload','created_at'],
  where: '(owner_id = ? AND status = ?) OR (shared = ?)',
  whereArgs: [ownerId, 'draft', 1],
  orderBy: 'created_at DESC',
  limit: 50,
);
```

2) Full CRUD sequence (insert -> update -> delete) showing payload handling:

```
final id = await DBService.instance.insert('asset', {
  'name': 'Site photo',
  'type': 'image',
  'payload': {'w': 1024, 'h': 768},
});

await DBService.instance.update('asset', {'name': 'Site photo v2'}, 'id = ?', [id]);

await DBService.instance.delete('asset', 'id = ?', [id]);
```

3) Exporting DB with inlined payloads:

```
await DBService.instance.exportToSqlFile('/tmp/form_fields_export.sql', inlinePayloads: true);
```

4) Import and convert inline payloads into files:

```
await DBService.instance.importFromSqlFile('/tmp/form_fields_export.sql', convertInlinePayloads: true);
```

If you'd like, I can:

- Add `///` documentation comments to `lib/src/service/db_service.dart` matching
  the sections above so IDE tooltips expose this guidance, or
- Create a small runnable example screen in `example/` that demonstrates these
  flows interactively.

````
