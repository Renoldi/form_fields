import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'db_service.dart';
import 'workmanager_service.dart';
import 'package:workmanager/workmanager.dart';
import 'flush_api.dart';

final _log = Logger('FormFieldsInitializer');

/// Default initial delay used for scheduling periodic Workmanager tasks.
/// Hosts can override this by passing `workmanagerInitialDelay` to `initAll`.
const Duration kWorkmanagerInitialDelayDefault = Duration(minutes: 15);

/// Single initializer to bootstrap package services from host app.
///
/// Responsibilities:
/// - Initialize DB (apply optional migrations)
/// - Initialize Workmanager (optional)
/// - Register package-level Flush handlers
class FormFieldsInitializer {
  FormFieldsInitializer._();

  /// Apply migration assets when the DB is opened without a numeric version.
  /// Receives the already-opened [db] instance to invoke host callbacks.
  static Future<void> _applyMigrationAssetsIfNeeded(
      {required Database db,
      required int dbVersion,
      required List<String>? migrationAssetPaths,
      required bool invokeOnUpgradeWhenDbVersionZero,
      OnDatabaseVersionChangeFn? onUpgrade,
      OnDatabaseCreateFn? onCreate}) async {
    if (dbVersion != 0 ||
        migrationAssetPaths == null ||
        migrationAssetPaths.isEmpty) {
      return;
    }

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

    if (onCreate != null) {
      try {
        await onCreate(db, maxVer);
      } catch (e, st) {
        _log.warning(
            'onCreate callback threw during manual invocation: $e', e, st);
      }
    }
  }

  /// Initialize Workmanager plugin and register provided handlers when
  /// appropriate. This is intentionally isolated so hosts may reuse parts.
  static Future<void> _initWorkmanagerIfNeeded({
    required bool enableWorkmanager,
    required void Function()? workmanagerCallbackDispatcher,
    required BackgroundTaskHandler? workmanagerHandler,
    required Future<void> Function()? workmanagerFlushPendingHandler,
    required bool registerPeriodic,
    required bool autoStartWorkmanager,
    required Duration workmanagerFrequency,
    required Duration workmanagerInitialDelay,
    required bool workmanagerPeriodic,
    required Map<String, dynamic>? workmanagerInputData,
    String? workmanagerTaskName,
  }) async {
    if (!enableWorkmanager || kIsWeb) return;

    _log.info('Initializing WorkmanagerService');

    if (workmanagerCallbackDispatcher != null) {
      try {
        await Workmanager().initialize(workmanagerCallbackDispatcher);
      } catch (e, st) {
        _log.warning(
            'Failed to initialize Workmanager with callback dispatcher: $e',
            e,
            st);
      }
    }

    await WorkmanagerService.instance.initialize();

    if (workmanagerHandler != null) {
      WorkmanagerService.instance.setHandler(workmanagerHandler);
      try {
        WorkmanagerService.setBackgroundTaskHandler(workmanagerHandler);
      } catch (e, st) {
        _log.warning('Failed to set background task handler: $e', e, st);
      }
    }

    if (workmanagerFlushPendingHandler != null) {
      try {
        WorkmanagerService.instance.flushPendingHandler =
            workmanagerFlushPendingHandler;
      } catch (e, st) {
        _log.warning('Failed to set flushPendingHandler: $e', e, st);
      }
    }

    if (registerPeriodic) {
      await WorkmanagerService.instance.start(
        taskName: workmanagerTaskName,
        frequency: workmanagerFrequency,
        periodic: true,
        inputData: workmanagerInputData,
        initialDelay: workmanagerInitialDelay,
      );
    } else if (autoStartWorkmanager) {
      await WorkmanagerService.instance.start(
        taskName: workmanagerTaskName,
        frequency: workmanagerFrequency,
        periodic: workmanagerPeriodic,
        inputData: workmanagerInputData,
        initialDelay: workmanagerInitialDelay,
      );
    }
  }

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
    BackgroundTaskHandler? workmanagerHandler,

    /// Optional top-level callback dispatcher to register with `Workmanager()`
    /// in the host app. If provided and `enableWorkmanager` is true, `initAll`
    /// will call `Workmanager().initialize(workmanagerCallbackDispatcher)` so
    /// background isolates can reach the host's top-level dispatcher.
    void Function()? workmanagerCallbackDispatcher,
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
    // Optional host-provided flush handlers that will be registered on
    // package startup so callers can invoke host-provided flush logic via
    // `FlushApi.flushPendingSubmissions` / `FlushApi.flushPendingSubmissionById`.
    FlushAllHandler? flushAll,
    FlushOneHandler? flushOne,
  }) async {
    // Setup logging
    Logger.root.level = logLevel;
    Logger.root.onRecord.listen((rec) {
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

    // Validate inputs to catch common misconfiguration early.
    if (workmanagerFrequency <= Duration.zero) {
      throw ArgumentError.value(workmanagerFrequency, 'workmanagerFrequency',
          'must be > Duration.zero');
    }

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

    await _applyMigrationAssetsIfNeeded(
      db: db,
      dbVersion: dbVersion,
      migrationAssetPaths: migrationAssetPaths,
      invokeOnUpgradeWhenDbVersionZero: invokeOnUpgradeWhenDbVersionZero,
      onUpgrade: onUpgrade,
      onCreate: onCreate,
    );

    await _initWorkmanagerIfNeeded(
      enableWorkmanager: enableWorkmanager,
      workmanagerCallbackDispatcher: workmanagerCallbackDispatcher,
      workmanagerHandler: workmanagerHandler,
      workmanagerFlushPendingHandler: workmanagerFlushPendingHandler,
      registerPeriodic: registerPeriodic,
      autoStartWorkmanager: autoStartWorkmanager,
      workmanagerFrequency: workmanagerFrequency,
      workmanagerInitialDelay: workmanagerInitialDelay,
      workmanagerPeriodic: workmanagerPeriodic,
      workmanagerInputData: workmanagerInputData,
      workmanagerTaskName: workmanagerTaskName,
    );

    // Register optional host-provided Flush handlers so the package-level
    // FlushApi can call back into the host/example app. This preserves the
    // previous behavior where hosts registered implementations themselves.
    try {
      FlushApi.register(flushAll: flushAll, flushOne: flushOne);
    } catch (e, st) {
      _log.warning('Failed to register FlushApi handlers: $e', e, st);
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
