import 'dart:ui';

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

/// Configuration describing a single worker/task that may be registered
/// with Workmanager. Hosts can provide multiple registrations to schedule
/// and manage several background workers from `initAll`.
class WorkerRegistration {
  const WorkerRegistration({
    this.taskName,
    this.frequency = const Duration(hours: 1),
    this.initialDelay = kWorkmanagerInitialDelayDefault,
    this.periodic = true,
    this.inputData,
    this.backgroundHandler,
    this.foregroundHandler,
    this.register = true,
  });

  final String? taskName;
  final Duration frequency;
  final Duration initialDelay;
  final bool periodic;
  final Map<String, dynamic>? inputData;
  final BackgroundTaskHandler? backgroundHandler;
  final Future<void> Function()? foregroundHandler;
  final bool register;
}

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

  /// Registers each provided [WorkerRegistration]. Returns the first
  /// non-null `BackgroundTaskHandler` encountered so the caller may
  /// register a package-level background handler. This helper centralizes
  /// logging and error handling for worker registration.
  static Future<BackgroundTaskHandler?> _registerWorkers(
      List<WorkerRegistration> regs) async {
    BackgroundTaskHandler? firstHandler;
    for (final reg in regs) {
      if (reg.backgroundHandler != null && firstHandler == null) {
        firstHandler = reg.backgroundHandler;
      }

      if (reg.foregroundHandler != null) {
        _safeSetForegroundFlushHandler(reg.foregroundHandler);
      }

      if (!reg.register) continue;

      try {
        // Merge reg.inputData and embed a callback handle for the
        // registration's own handler (if provided). This ensures that
        // each worker can resolve its specific top-level handler when
        // executed in a background isolate.
        Map<String, dynamic>? inputDataForReg;
        try {
          final base = reg.inputData != null
              ? Map<String, dynamic>.from(reg.inputData!)
              : <String, dynamic>{};
          if (reg.backgroundHandler != null) {
            try {
              final handle =
                  PluginUtilities.getCallbackHandle(reg.backgroundHandler!);
              if (kDebugMode) {
                // ignore: avoid_print
                print('getCallbackHandle for reg.handler -> $handle');
              }
              if (handle != null) {
                base['callback_handle'] = handle.toRawHandle();
              }
            } catch (_) {}
          }
          inputDataForReg = base.isEmpty ? null : base;
        } catch (_) {
          inputDataForReg = reg.inputData;
        }

        await WorkmanagerService.instance.start(
          taskName: reg.taskName,
          frequency: reg.frequency,
          periodic: reg.periodic,
          inputData: inputDataForReg,
          initialDelay: reg.initialDelay,
        );
        // Register per-task foreground handler so countdown triggers can
        // invoke task-specific foreground logic (e.g. `sendRandomForeground`).
        try {
          if (reg.taskName != null && reg.foregroundHandler != null) {
            WorkmanagerService.instance.setForegroundHandlerForTask(
                reg.taskName!, reg.foregroundHandler);
          }
        } catch (_) {}
        _log.fine('Registered worker: ${reg.taskName}');
      } catch (e, st) {
        _log.warning('Failed to register worker ${reg.taskName}: $e', e, st);
      }
    }

    return firstHandler;
  }

  static void _safeSetForegroundFlushHandler(Future<void> Function()? handler) {
    if (handler == null) return;
    try {
      // Only set the foreground flush handler if one hasn't been set yet.
      // This preserves the host-provided flush handler (typically the
      // `form_fields_flush` handler) and avoids later worker registrations
      // from overwriting it (which could cause countdown-triggered flushes
      // to call the wrong handler such as `sendRandomForeground`).
      if (WorkmanagerService.instance.foregroundFlushHandler == null) {
        WorkmanagerService.instance.foregroundFlushHandler = handler;
      } else {
        _log.fine('foregroundFlushHandler already set; skipping override');
      }
    } catch (e, st) {
      _log.warning('Failed to set foregroundFlushHandler: $e', e, st);
    }
  }

  /// Initialize Workmanager plugin and register provided handlers when
  /// appropriate. This is intentionally isolated so hosts may reuse parts.
  static Future<void> _initWorkmanagerIfNeeded({
    required bool enableWorkmanager,
    required void Function()? workmanagerCallbackDispatcher,
    required List<WorkerRegistration>? workerRegistrations,
    required bool registerPeriodic,
    required bool autoStartWorkmanager,
  }) async {
    if (!enableWorkmanager || kIsWeb) return;

    _log.info('Initializing WorkmanagerService');

    await WorkmanagerService.instance
        .initialize(callbackDispatcher: workmanagerCallbackDispatcher);

    // Register provided worker registrations via helper to keep logic small
    // and reusable. The helper returns the first provided background handler
    // (if any) so we can register it at the package level.
    if (workerRegistrations != null && workerRegistrations.isNotEmpty) {
      final BackgroundTaskHandler? firstHandler =
          await _registerWorkers(workerRegistrations);

      if (firstHandler != null) {
        try {
          WorkmanagerService.instance.setHandler(firstHandler);
          WorkmanagerService.setBackgroundTaskHandler(firstHandler);
        } catch (e, st) {
          _log.warning('Failed to set background task handler: $e', e, st);
        }
      }
      return;
    }

    // Fallback: no registrations provided. If `autoStartWorkmanager` is true
    // and `registerPeriodic` is set, start the default service without
    // scheduling tasks (legacy behavior removed; nothing to register).
    if (autoStartWorkmanager) {
      try {
        await WorkmanagerService.instance.start(
          taskName: null,
          frequency: const Duration(hours: 1),
          periodic: false,
          inputData: null,
          initialDelay: Duration.zero,
        );
      } catch (e, st) {
        _log.warning('Failed to auto-start WorkmanagerService: $e', e, st);
      }
    }
  }

  /// Initialize DB, logging, workmanager and any other services the package
  /// requires. Designed to be called from app `main()` so the host app
  /// doesn't need to initialize each service individually.
  static Future<void> initAll({
    String dbName = 'form_fields.db',
    bool enableWorkmanager = true,
    bool registerPeriodic = true,

    /// If true the initializer will call `WorkmanagerService.instance.start()`
    /// after initialization. Use this to opt-in to automatic scheduling from
    /// `initAll`.
    bool autoStartWorkmanager = false,

    /// Optional top-level callback dispatcher to register with `Workmanager()`
    /// in the host app. If provided and `enableWorkmanager` is true, `initAll`
    /// will call `Workmanager().initialize(workmanagerCallbackDispatcher)` so
    /// background isolates can reach the host's top-level dispatcher.
    void Function()? workmanagerCallbackDispatcher,

    /// New: multiple worker registrations to schedule and manage background
    /// tasks. Use `WorkerRegistration` to describe each worker.
    List<WorkerRegistration>? workerRegistrations,
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
    // Validate worker registrations
    if (workerRegistrations != null) {
      for (final reg in workerRegistrations) {
        if (reg.frequency <= Duration.zero) {
          throw ArgumentError.value(reg.frequency, 'workerRegistrations',
              'frequency must be > Duration.zero for ${reg.taskName}');
        }
      }
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

    // No host-provided flush handlers are registered automatically anymore.
    // Hosts should register any FlushApi handlers explicitly when needed.

    await _initWorkmanagerIfNeeded(
      enableWorkmanager: enableWorkmanager,
      workmanagerCallbackDispatcher: workmanagerCallbackDispatcher,
      workerRegistrations: workerRegistrations,
      registerPeriodic: registerPeriodic,
      autoStartWorkmanager: autoStartWorkmanager,
    );
    _log.info('FormFields initialized');
  }

  // NOTE: `FlushApi` registration is no longer performed automatically
  // by `initAll`. Hosts who want to expose flush handlers should call
  // `FlushApi.register(...)` themselves at app startup.

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
