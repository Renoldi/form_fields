# Database: Debug vs Release (Concise)

This short guide explains how to work with the package's SQLite database for both debug and release builds, and which APIs to use so file-backed payload handlers run correctly.

## Key ideas

- Use `DBService` APIs (recommended) so `ColumnHandler` lifecycle runs:
  - `DBService.instance.insert(table, values)` — runs `onWrite` handlers (eg. write payload JSON to file).
  - `DBService.instance.update(table, values, where, whereArgs)`
  - `DBService.instance.delete(table, where, whereArgs)` — runs `onDelete`, cleaning associated payload files.
  - `DBService.instance.executeSql(sql)` — executes raw SQL. Note: `INSERT`/`UPDATE` via raw SQL will NOT run handlers.

## File locations

- Default DB filename: `form_fields.db` in the app's documents directory (`getApplicationDocumentsDirectory()`).
- Android (debug / emulator):

```bash
adb shell run-as com.example.form_fields_example.debug ls -l /data/data/com.example.form_fields_example.debug/files
adb shell run-as com.example.form_fields_example.debug cp files/form_fields.db /sdcard/ && adb pull /sdcard/form_fields.db
```

- iOS Simulator / macOS: open the Simulator app, inspect the app container and find `Documents/form_fields.db`.

## Common tasks

- Insert (with handlers):

```dart
final values = {
  'assetId': 'id-123',
  'payload': '{"assetId":"id-123","name":"item"}',
  'updated_at': DateTime.now().millisecondsSinceEpoch,
};
await DBService.instance.insert('asset', values);
```

- Delete (ensures payload file removed by handler):

```dart
await DBService.instance.delete('asset', 'rowid = ?', [rowid]);
```

- Execute raw SQL (no handlers):

```dart
await DBService.instance.executeSql("INSERT INTO \"asset\" (...) VALUES (...);");
```

- Import sample SQL file (programmatic):

```dart
await DBService.instance.importFromSqlFile('/path/to/sample_inserts.sql');
```

## Schema / migration

- To run packaged migrations: `DBService.migrateTo(targetVersion, migrationAssetPaths: [...])`.
- To set PRAGMA directly: `DBService.setUserVersion(version)`.

## Debugging tips

- Run the example app in debug from your IDE to see logs from `DBService` and handlers.
- Use the example app UI: SQL Viewer supports `Import sample asset`, `Import from file`, `Export to folder`, and `Run SQL`.
- Check payload files (JSON) in the app documents payload folder (managed by `FileBackedColumnHandler`).

## Release considerations

- On release builds the package id and storage paths differ; `adb shell run-as` often won't work on production apps. Provide an export button in-app to retrieve DB for analysis.
- Protect sensitive payloads (encrypt or avoid storing PII in plaintext files) before shipping to production.

---

For more detailed examples see the example app SQL viewer and `example/migrations/sample_inserts.sql`.
