import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'db_service.dart';

final _log = Logger('ImportExportService');

class ImportExportService {
  ImportExportService._();
  static final ImportExportService instance = ImportExportService._();

  /// Export the database to the app's documents directory and return the path.
  Future<String> exportToDocuments() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'form_fields_export_${DateTime.now().toIso8601String()}.sql';
    final dest = p.join(dir.path, fileName);
    await DBService.instance.exportToSqlFile(dest);
    _log.info('Exported DB to $dest');
    return dest;
  }

  /// Export the DB to the provided destination file path.
  Future<String> exportToPath(String destPath) async {
    await DBService.instance.exportToSqlFile(destPath);
    _log.info('Exported DB to $destPath');
    return destPath;
  }

  /// Let the user pick a folder and export the SQL file there. Returns the
  /// destination path on success, or null if cancelled.
  Future<String?> pickFolderAndExport() async {
    try {
      final dirPath = await FilePicker.getDirectoryPath();
      if (dirPath == null) return null;
      final fileName =
          'form_fields_export_${DateTime.now().toIso8601String()}.sql';
      final dest = p.join(dirPath, fileName);
      await exportToPath(dest);
      return dest;
    } catch (e, st) {
      _log.warning('Failed to pick folder and export: $e', e, st);
      return null;
    }
  }

  /// Import a SQL file bundled as an asset (e.g. assets/imports/mydata.sql).
  /// Returns the temporary file path used for import, or null on failure.
  Future<String?> importFromAsset(String assetPath) async {
    try {
      final data = await rootBundle.loadString(assetPath);
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = p.join(
          tmpDir.path, 'import_${DateTime.now().millisecondsSinceEpoch}.sql');
      final f = File(tmpPath);
      await f.writeAsString(data);
      // Ensure core schema exists before importing DML from the asset.
      try {
        await DBService.instance
            .runMigrationAsset('migrations/migration.sql', applyDml: true);
      } catch (e) {
        _log.warning('Failed to ensure migrations before asset import: $e');
      }
      await DBService.instance.importFromSqlFile(tmpPath);
      _log.info('Imported SQL from asset $assetPath');
      return tmpPath;
    } catch (e, st) {
      _log.warning('Failed to import asset $assetPath: $e', e, st);
      return null;
    }
  }

  /// Let the user pick a `.sql` file from device storage and import it.
  /// Returns the imported file path on success, or null on failure/cancel.
  Future<String?> pickFileAndImport() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sql', 'txt'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final filePath = result.files.single.path;
      if (filePath == null) return null;
      // Copy to temp to ensure read permissions and consistent path
      final tmpDir = await getTemporaryDirectory();
      final destPath = p.join(
          tmpDir.path, 'import_${DateTime.now().millisecondsSinceEpoch}.sql');
      final src = File(filePath);
      await src.copy(destPath);
      // Ensure core schema exists before importing user-provided SQL.
      try {
        await DBService.instance
            .runMigrationAsset('migrations/migration.sql', applyDml: true);
      } catch (e) {
        _log.warning('Failed to ensure migrations before file import: $e');
      }
      await DBService.instance.importFromSqlFile(destPath);
      _log.info('Imported SQL from picked file $filePath');
      return destPath;
    } catch (e, st) {
      _log.warning('Failed to pick/import file: $e', e, st);
      return null;
    }
  }
}
