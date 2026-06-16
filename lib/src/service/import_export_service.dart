import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

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
      await DBService.instance.importFromSqlFile(destPath);
      _log.info('Imported SQL from picked file $filePath');
      return destPath;
    } catch (e, st) {
      _log.warning('Failed to pick/import file: $e', e, st);
      return null;
    }
  }

  /// Import multiple migration JSON files from a local folder path.
  ///
  /// For each JSON file in [folderPath], this will:
  /// - determine the record type (asset, master_inspection_forms, master_inspections, pending_inspections)
  /// - write a payload JSON file into the app documents directory with a naming convention
  /// - insert a row into the corresponding table with `payload` set to the filename and `updated_at` timestamp
  ///
  /// Returns list of created payload file paths.
  Future<List<String>> importMigrationsFolder(String folderPath) async {
    final results = <String>[];
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) return results;

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));
      final docs = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(docs.path, 'migrations'));
      await targetDir.create(recursive: true);

      final now = DateTime.now().millisecondsSinceEpoch;

      for (final f in files) {
        try {
          final content = await f.readAsString();
          final dynamic jsonObj = json.decode(content);

          // Asset
          if (jsonObj is Map && jsonObj.containsKey('assetId')) {
            final id = jsonObj['assetId'].toString();
            final fname = 'asset_$id.json';
            final outPath = p.join(targetDir.path, fname);
            await File(outPath).writeAsString(content);
            await DBService.instance.insert(
                'asset',
                {
                  'assetId': id,
                  'payload': fname,
                  'updated_at': now,
                },
                autoHandlePayload: true);
            results.add(outPath);
            continue;
          }

          // master_inspection_forms: contains hseFormId and possibly a `payload` string
          if (jsonObj is Map && jsonObj.containsKey('hseFormId')) {
            final id = jsonObj['hseFormId'].toString();

            // If this file already contains a `payload` field that is stringified JSON,
            // prefer writing `master_inspection_forms_<id>.json` with that payload content.
            if (jsonObj.containsKey('payload') &&
                jsonObj['payload'] is String) {
              final payloadStr = jsonObj['payload'] as String;
              final fname = 'master_inspection_forms_$id.json';
              final outPath = p.join(targetDir.path, fname);
              await File(outPath).writeAsString(payloadStr);
              await DBService.instance.insert(
                  'master_inspection_forms',
                  {
                    'hseFormId': id,
                    'payload': fname,
                    'updated_at': now,
                  },
                  autoHandlePayload: true);
              results.add(outPath);
              // Also insert master_inspections record pointing to a separate file
              final masterFname = 'master_inspections_$id.json';
              final masterOut = p.join(targetDir.path, masterFname);
              await File(masterOut).writeAsString(content);
              await DBService.instance.insert(
                  'master_inspections',
                  {
                    'hseFormId': id,
                    'payload': masterFname,
                    'updated_at': now,
                    'formType': jsonObj['hseFormType'] ?? ''
                  },
                  autoHandlePayload: true);
              results.add(masterOut);
              continue;
            }

            // Default: write the JSON object as master_inspections entry
            final fname = 'master_inspections_$id.json';
            final outPath = p.join(targetDir.path, fname);
            await File(outPath).writeAsString(content);
            await DBService.instance.insert(
                'master_inspections',
                {
                  'hseFormId': id,
                  'payload': fname,
                  'updated_at': now,
                  'formType': jsonObj['hseFormType'] ?? ''
                },
                autoHandlePayload: true);
            results.add(outPath);
            continue;
          }

          // pending_inspections: fallback when file name contains 'pending' or object has no ids
          if (p.basename(f.path).toLowerCase().contains('pending') ||
              jsonObj is Map && jsonObj.containsKey('items')) {
            final fname = 'pending_${now}_${p.basename(f.path)}';
            final outPath = p.join(targetDir.path, fname);
            await File(outPath).writeAsString(content);
            await DBService.instance.insert(
                'pending_inspections',
                {
                  'payload': fname,
                  'status': 'NEW',
                  'created_at': now,
                },
                autoHandlePayload: true);
            results.add(outPath);
            continue;
          }

          // Unknown: write as a generic file and skip DB insert
          final fname = 'migration_${p.basename(f.path)}';
          final outPath = p.join(targetDir.path, fname);
          await File(outPath).writeAsString(content);
          results.add(outPath);
        } catch (e, st) {
          _log.warning('Failed to process ${f.path}: $e', e, st);
          continue;
        }
      }
    } catch (e, st) {
      _log.warning('Failed to import migrations from $folderPath: $e', e, st);
    }
    return results;
  }

  /// Let the user pick a folder and import JSON migration files from it.
  /// Returns list of created payload paths, or null if cancelled/failed.
  Future<List<String>?> pickFolderAndImport() async {
    try {
      final dirPath = await FilePicker.getDirectoryPath();
      if (dirPath == null) return null;
      final results = await importMigrationsFolder(dirPath);
      _log.info('Imported ${results.length} files from folder: $dirPath');
      return results;
    } catch (e, st) {
      _log.warning('Failed to pick/import folder: $e', e, st);
      return null;
    }
  }
}
