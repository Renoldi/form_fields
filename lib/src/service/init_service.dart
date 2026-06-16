import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'db_service.dart';
import 'workmanager_service.dart';

final _log = Logger('FormFieldsInitializer');

/// Single initializer to bootstrap package services from host app.
class FormFieldsInitializer {
  FormFieldsInitializer._();

  /// Initialize DB, logging, workmanager and any other services the package
  /// requires. Designed to be called from app `main()` so the host app
  /// doesn't need to initialize each service individually.
  static Future<void> initAll({
    String dbName = 'form_fields.db',
    bool enableWorkmanager = true,
    bool registerPeriodic = false,
    Level logLevel = Level.INFO,
    List<String>? migrationAssetPaths,
  }) async {
    // Setup logging
    Logger.root.level = logLevel;
    Logger.root.onRecord.listen((rec) {
      // Simple console logging for example apps; host apps can configure
      // their own logging handlers if desired.
      final msg = '${rec.level.name}: ${rec.time.toIso8601String()} '
          '${rec.loggerName} - ${rec.message}';
      // ignore: avoid_print
      print(msg);
      if (rec.error != null) {
        // ignore: avoid_print
        print(rec.error);
      }
      if (rec.stackTrace != null) {
        // ignore: avoid_print
        print(rec.stackTrace);
      }
    });

    _log.info('Initializing DBService');
    await DBService.instance
        .init(dbName: dbName, migrationAssetPaths: migrationAssetPaths);

    if (enableWorkmanager && !kIsWeb) {
      _log.info('Initializing WorkmanagerService');
      await WorkmanagerService.instance.initialize();
      if (registerPeriodic) {
        await WorkmanagerService.instance.registerPeriodic();
      }
    }

    _log.info('FormFields initialized');
  }
}
