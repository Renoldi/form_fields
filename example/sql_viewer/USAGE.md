# SQL Viewer - Example snippets

This document contains ready-to-copy snippets that demonstrate `selectFrom` and `select` usage
with multiple WHERE clauses and payload inlining. These snippets are intended to be pasted into
an example Flutter app or into an existing `example/` screen.

## 1. Simple selectFrom (all columns)

```dart
final rows = await DBService.instance.selectFrom('asset');
print('found ${rows.length} rows');
```

## 2. Multiple WHERE (AND)

```dart
final rows = await DBService.instance.selectFrom(
  'asset',
  where: 'type = ? AND status = ?',
  whereArgs: ['image', 'active'],
);
```

## 3. Grouped conditions (AND/OR)

```dart
final rows = await DBService.instance.selectFrom(
  'asset',
  where: '(owner_id = ? AND status = ?) OR (shared = ?)',
  whereArgs: [ownerId, 'draft', 1],
);
```

## 4. IN list

```dart
final ids = [1,2,3];
final placeholders = List.filled(ids.length, '?').join(',');
final rows = await DBService.instance.selectFrom(
  'asset',
  where: 'id IN ($placeholders)',
  whereArgs: ids,
);
```

## 5. Raw SQL / JOIN example (use `select`)

```dart
final sql = '''
SELECT a.*, b.meta
FROM asset a
JOIN meta b ON a.id = b.asset_id
WHERE a.type = ?
''';
final rows = await DBService.instance.select(sql, params: ['image']);
```

## 6. Disable payload inlining

```dart
final rows = await DBService.instance.selectFrom(
  'asset',
  where: 'id = ?',
  whereArgs: [42],
  inlinePayloads: false,
);
```

## Notes

## 7. Insert / Update / Delete examples

```dart
// Insert (payload Map will be written to file by handler and filename stored)
final id = await DBService.instance.insert('asset', {
  'name': 'Photo A',
  'type': 'image',
  'payload': {'w': 800, 'h': 600},
});

// Upsert
final rowId = await DBService.instance.insertOrUpdate('asset', {
  'id': id,
  'name': 'Photo A (edited)',
  'payload': {'w': 1200, 'h': 900},
});

// Update
final updatedCount = await DBService.instance.update(
  'asset',
  {'status': 'archived'},
  'id = ?',
  [id],
);

// Delete (will trigger onDelete handlers to cleanup payload files)
final deleted = await DBService.instance.delete('asset', 'id = ?', [id]);
```

## 8. Utilities: raw exec, payload file helpers, export/import

```dart
// Raw SQL runner (INSERT/UPDATE/DELETE routing attempted)
await DBService.instance.executeSqlInsUpDel("DELETE FROM asset WHERE status = 'old'");

// Read payload contents
final text = await DBService.instance.readPayloadString('asset_payload_...json');
final jsonObj = await DBService.instance.readPayloadJson('asset_payload_...json');

// Export and import
await DBService.instance.exportToSqlFile('/tmp/form_fields_dump.sql', inlinePayloads: true);
await DBService.instance.importFromSqlFile('/tmp/form_fields_dump.sql', convertInlinePayloads: true);
```

## 9. Lifecycle / Migration

```dart
// Init or migrate during app startup
await DBService.instance.init(dbName: 'form_fields.db', dbVersion: 2);

// Reset DB file (optionally reinit)
await DBService.instance.resetDatabase(reinit: true);
```

- Paste these snippets into an async handler (e.g., button `onPressed`) inside a Flutter example.
- Ensure `DBService.instance.init()` has been called (e.g., app startup) before running queries.
