import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'db_service.dart';
import 'workmanager_service.dart';
import 'package:workmanager/workmanager.dart';

final _log = Logger('FormFieldsInitializer');

/// Default initial delay used for scheduling periodic Workmanager tasks.
/// Hosts can override this by passing `workmanagerInitialDelay` to `initAll`.
const Duration kWorkmanagerInitialDelayDefault = Duration(minutes: 15);

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

    /// If true the initializer will call `WorkmanagerService.instance.start()`
    /// after initialization. Use this to opt-in to automatic scheduling from
    /// `initAll`. If `registerPeriodic` is true this parameter is ignored
    /// because it preserves the previous behavior.
    bool autoStartWorkmanager = false,

    /// Optional task name for the registered workmanager task. If omitted
    /// the service default is used.
    String? workmanagerTaskName,

    /// Frequency used when starting a periodic task.
    Duration workmanagerFrequency = const Duration(hours: 1),

    /// Optional initial delay before the first run of a periodic task.
    /// Passed through to `WorkmanagerService.start` as `initialDelay`.
    /// Defaults to 15 minutes to match typical background scheduling minimums.
    Duration workmanagerInitialDelay = kWorkmanagerInitialDelayDefault,

    /// Whether the auto-start should register a periodic task (true) or
    /// simply mark the service as started without scheduling (false).
    bool workmanagerPeriodic = true,

    /// Optional input data passed to the background task when scheduled.
    Map<String, dynamic>? workmanagerInputData,

    /// Optional foreground flush handler that will be invoked when
    /// network connectivity is restored. This handler runs in the
    /// foreground isolate and should perform DB/network work. If
    /// provided `initAll` will register it on `WorkmanagerService`.
    Future<void> Function()? workmanagerFlushPendingHandler,

    /// Optional handler to register for background tasks.
    ///
    /// Usage notes:
    /// - The handler should be a top-level function (not a closure or
    ///   instance method) so background isolates can locate and invoke it.
    /// - When provided, `initAll` will register it for foreground usage
    ///   via `WorkmanagerService.instance.setHandler(...)` and will also
    ///   attempt to register it as the package-level background handler
    ///   so scheduling code can include a callback handle that background
    ///   isolates can resolve.
    /// - If the host app initializes `Workmanager()` itself (for example
    ///   to install a custom dispatcher), pass `enableWorkmanager: false`
    ///   to `initAll` to avoid double-initialization.
    ///
    /// See also: `WorkmanagerService.setBackgroundTaskHandler` and
    /// `PluginUtilities.getCallbackHandle` for inter-isolate callback
    /// resolution.
    BackgroundTaskHandler? workmanagerHandler,
    Level logLevel = Level.INFO,
    List<String>? migrationAssetPaths,
    int dbVersion = 0,

    /// When `dbVersion == 0` and migration assets are applied, whether to
    /// invoke `onUpgrade` manually for each incremental version step (1..maxVer).
    /// Defaults to true to preserve existing behavior.
    bool invokeOnUpgradeWhenDbVersionZero = true,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
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

    // Note: when `dbVersion == 0` openDatabase is called without a numeric
    // version so sqflite cannot invoke `onCreate`/`onUpgrade`/`onDowngrade`.
    // We'll still accept `onCreate` and invoke it manually after applying
    // provided `migrationAssetPaths` so hosts can supply a migration asset
    // list while using a version-less DB. `onDowngrade` remains not
    // applicable in this mode; `onUpgrade` can be invoked manually to
    // simulate incremental upgrades starting from version 0.
    if (dbVersion == 0 && onDowngrade != null) {
      _log.warning(
          'onDowngrade provided but will be ignored when dbVersion == 0');
    }

    final db = await DBService.instance.init(
      dbName: dbName,
      migrationAssetPaths: migrationAssetPaths,
      dbVersion: dbVersion,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
      onOpen: onOpen,
    );

    // When `dbVersion` is 0 we open the database without a numeric version
    // (sqflite will not invoke onCreate/onUpgrade). For that usage pattern
    // allow the host to provide migration assets via `migrationAssetPaths`.
    // Apply them now as schema-only migrations so the DB is prepared.
    if (dbVersion == 0 &&
        migrationAssetPaths != null &&
        migrationAssetPaths.isNotEmpty) {
      int maxVer = 0;
      for (final asset in migrationAssetPaths) {
        try {
          _log.info('Applying migration asset via initAll: $asset');
          await DBService.instance.runMigrationAsset(asset);
          final basename = p.basename(asset);
          final m = RegExp(r'v?(\d+)').firstMatch(basename);
          if (m != null) {
            final v = int.tryParse(m.group(1) ?? '0') ?? 0;
            if (v > maxVer) maxVer = v;
          }
        } catch (e, st) {
          _log.warning('Failed to apply migration asset $asset: $e', e, st);
        }
      }
      if (maxVer > 0) {
        try {
          await DBService.instance.setUserVersion(maxVer);
        } catch (e, st) {
          _log.warning('Failed to set user_version to $maxVer: $e', e, st);
        }
      }

      // If the host provided an `onUpgrade` callback, invoke it sequentially
      // to simulate incremental upgrades starting from DB version 0 up to
      // the computed `maxVer`. This mirrors how sqflite would call
      // `onUpgrade` for each step when opening with a numeric version.
      if (invokeOnUpgradeWhenDbVersionZero && onUpgrade != null && maxVer > 0) {
        try {
          for (var v = 1; v <= maxVer; v++) {
            await onUpgrade(db, v - 1, v);
          }
        } catch (e, st) {
          _log.warning(
              'onUpgrade callback threw during manual invocation: $e', e, st);
        }
      }

      // Manually invoke onCreate if the caller provided one. Pass the
      // computed max version (or 0) so the host knows what was applied.
      if (onCreate != null) {
        try {
          await onCreate(db, maxVer);
        } catch (e, st) {
          _log.warning(
              'onCreate callback threw during manual invocation: $e', e, st);
        }
      }
    }

    if (enableWorkmanager && !kIsWeb) {
      _log.info('Initializing WorkmanagerService');
      await WorkmanagerService.instance.initialize();

      // If the host provided a handler, register it for foreground usage.
      // Note: background isolates require a top-level handler via
      // `setBackgroundTaskHandler(...)`.
      if (workmanagerHandler != null) {
        // Register handler for foreground usage (backwards-compatible).
        WorkmanagerService.instance.setHandler(workmanagerHandler);
        // Also register as the top-level background handler so the
        // provided top-level function is available to background isolates.
        // The handler must be a top-level function from the host app.
        try {
          WorkmanagerService.setBackgroundTaskHandler(workmanagerHandler);
        } catch (e, st) {
          _log.warning('Failed to set background task handler: $e', e, st);
        }
      }

      // If the host provided a foreground flush handler, register it so
      // the service can invoke it on connectivity changes.
      if (workmanagerFlushPendingHandler != null) {
        try {
          WorkmanagerService.instance.flushPendingHandler =
              workmanagerFlushPendingHandler;
        } catch (e, st) {
          _log.warning('Failed to set flushPendingHandler: $e', e, st);
        }
      }

      // Backwards-compatible behavior: if registerPeriodic was requested
      // preserve the previous convenience. Otherwise respect autoStartWorkmanager.
      if (registerPeriodic) {
        await WorkmanagerService.instance.start(
            taskName: workmanagerTaskName,
            frequency: workmanagerFrequency,
            periodic: true,
            inputData: workmanagerInputData,
            initialDelay: workmanagerInitialDelay);
      } else if (autoStartWorkmanager) {
        await WorkmanagerService.instance.start(
            taskName: workmanagerTaskName,
            frequency: workmanagerFrequency,
            periodic: workmanagerPeriodic,
            inputData: workmanagerInputData,
            initialDelay: workmanagerInitialDelay);
      }
    }

    _log.info('FormFields initialized');
  }

  /// Change the on-disk database version by triggering the DB migration
  /// flow. This will open/reconcile the DB and run upgrades/downgrades as
  /// needed. If `migrationAssetPaths` are provided they will be used to
  /// locate migration assets.
  static Future<Database> changeDbVersion(int targetVersion,
      {String dbName = 'form_fields.db',
      List<String>? migrationAssetPaths,
      OnDatabaseConfigureFn? onConfigure,
      OnDatabaseCreateFn? onCreate,
      OnDatabaseVersionChangeFn? onUpgrade,
      OnDatabaseVersionChangeFn? onDowngrade,
      OnDatabaseOpenFn? onOpen}) async {
    return await DBService.instance.migrateTo(
      dbName: dbName,
      targetVersion: targetVersion,
      migrationAssetPaths: migrationAssetPaths,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
      onOpen: onOpen,
    );
  }
}
