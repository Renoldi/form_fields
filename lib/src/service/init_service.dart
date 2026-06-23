import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'db_service.dart';
import 'workmanager_service.dart';
// NOTE: dependency migrated from an OS-scheduled plugin to `flutter_foreground_task`.
// Runtime APIs and parameter names were renamed to reflect
// foreground-service semantics provided by `flutter_foreground_task`.
import 'flush_types.dart';

final _log = Logger('FormFieldsInitializer');

/// Default initial delay used for scheduling periodic background tasks.
/// Hosts can override this by passing an explicit `initialDelay` in
/// `WorkerRegistration` when calling `initAll` from the host app.
const Duration kBackgroundInitialDelayDefault = Duration(minutes: 15);

/// Configuration describing a single worker/task that may be registered
/// with the package's foreground-service scheduling. Hosts can provide
/// multiple registrations to schedule and manage several background
/// workers from `initAll`.
class WorkerRegistration {
  const WorkerRegistration({
    this.taskName,
    this.frequency = const Duration(hours: 1),
    this.initialDelay = kBackgroundInitialDelayDefault,
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
/// - Initialize foreground-service plumbing (optional)
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
      List<WorkerRegistration> regs,
      {bool triggerOnStart = false}) async {
    BackgroundTaskHandler? firstHandler;

    // Track seen handler+period combinations so we only register one
    // callback per period. Key format: <handlerId>|<freqSeconds>|<periodic>
    final Set<String> seenHandlerPeriod = <String>{};

    for (final reg in regs) {
      if (reg.backgroundHandler != null && firstHandler == null) {
        firstHandler = reg.backgroundHandler;
      }

      if (reg.foregroundHandler != null) {
        _safeSetForegroundFlushHandler(reg.foregroundHandler);
      }

      if (!reg.register) continue;

      // Build a dedupe key based on available callback handle or fallback
      // to runtime identity. Prefer background handler identity when
      // available, otherwise use foreground handler identity.
      String? handlerId;
      try {
        if (reg.backgroundHandler != null) {
          final handle =
              PluginUtilities.getCallbackHandle(reg.backgroundHandler!);
          if (handle != null) {
            handlerId = 'cb:${handle.toRawHandle()}';
          } else {
            handlerId = 'bg_hash:${reg.backgroundHandler.hashCode}';
          }
        } else if (reg.foregroundHandler != null) {
          // Foreground handlers are typically closures and not top-level
          // callbacks, so avoid calling PluginUtilities.getCallbackHandle
          // (incompatible type) and use a hash-based identity instead.
          handlerId = 'fg_hash:${reg.foregroundHandler.hashCode}';
        }
      } catch (_) {
        // If PluginUtilities throws, fall back to hash-based id
        if (handlerId == null) {
          if (reg.backgroundHandler != null) {
            handlerId = 'bg_hash:${reg.backgroundHandler.hashCode}';
          } else if (reg.foregroundHandler != null) {
            handlerId = 'fg_hash:${reg.foregroundHandler.hashCode}';
          }
        }
      }

      final key = handlerId == null
          ? null
          : '$handlerId|${reg.frequency.inSeconds}|${reg.periodic}';

      if (key != null && seenHandlerPeriod.contains(key)) {
        _log.fine(
            'Skipping duplicate worker registration for ${reg.taskName} (same handler+period)');
        continue;
      }

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

        await ForegroundTaskService.instance.start(
          taskName: reg.taskName,
          frequency: reg.frequency,
          periodic: reg.periodic,
          inputData: inputDataForReg,
          initialDelay: reg.initialDelay,
        );

        // Optionally trigger handlers immediately at startup so hosts can
        // run initial work (foreground/background) without waiting for the
        // scheduled interval to elapse. This is opt-in via
        // `triggerOnStart` passed from `initAll`.
        if (triggerOnStart) {
          try {
            if (reg.foregroundHandler != null) {
              await reg.foregroundHandler!();
              _log.fine(
                  'Invoked foregroundHandler for ${reg.taskName} on start');
            }
          } catch (e, st) {
            _log.warning(
                'foregroundHandler threw during start invocation: $e', e, st);
          }

          try {
            if (reg.backgroundHandler != null) {
              // Use a one-off run to trigger the background handler via the
              // foreground-task adapter. This will request a one-off run
              // that should execute the resolved background callback.
              await ForegroundTaskService.instance.runOnceNowDetailed(
                taskName: reg.taskName,
                inputData: inputDataForReg,
              );
              _log.fine(
                  'Requested runOnceNow for backgroundHandler ${reg.taskName}');
            }
          } catch (e, st) {
            _log.warning(
                'Failed to trigger backgroundHandler at start: $e', e, st);
          }
        }

        // Mark this handler+period as registered so subsequent identical
        // registrations are skipped. Use the key we computed earlier.
        if (key != null) seenHandlerPeriod.add(key);

        try {
          ForegroundTaskService.instance.lastLogListenable.value =
              'registered_from_init: ${reg.taskName} freq_s=${reg.frequency.inSeconds}';
        } catch (_) {}
        // Register per-task foreground handler so countdown triggers can
        // invoke task-specific foreground logic (e.g. `sendRandomForeground`).
        try {
          if (reg.taskName != null && reg.foregroundHandler != null) {
            ForegroundTaskService.instance.setForegroundHandlerForTask(
                reg.taskName!, reg.foregroundHandler);
          }
        } catch (_) {}
        try {
          if (reg.taskName != null && reg.backgroundHandler != null) {
            ForegroundTaskService.instance.setBackgroundHandlerForTask(
                reg.taskName!, reg.backgroundHandler);
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
      if (ForegroundTaskService.instance.foregroundFlushHandler == null) {
        ForegroundTaskService.instance.foregroundFlushHandler = handler;
      } else {
        _log.fine('foregroundFlushHandler already set; skipping override');
      }
    } catch (e, st) {
      _log.warning('Failed to set foregroundFlushHandler: $e', e, st);
    }
  }

  /// Initialize foreground-service plumbing and register provided handlers
  /// when appropriate. This is intentionally isolated so hosts may reuse
  /// parts.
  static Future<void> _initForegroundIfNeeded({
    required bool enableForegroundService,
    required void Function()? foregroundTaskCallbackDispatcher,
    required List<WorkerRegistration>? workerRegistrations,
    required bool registerPeriodic,
    required bool autoStartForegroundService,
    required bool triggerWorkerHandlersOnStart,
    required bool useConnectivity,
  }) async {
    if (!enableForegroundService || kIsWeb) return;

    _log.info('Initializing ForegroundTaskService (foreground-service)');

    await ForegroundTaskService.instance.initialize(
        callbackDispatcher: foregroundTaskCallbackDispatcher,
        useConnectivity: useConnectivity);

    // If host provided registration metadata, expose it to the
    // ForegroundTaskService so the example UI can read the host-provided
    // definitions (instead of the built-in demo definitions).
    if (workerRegistrations != null && workerRegistrations.isNotEmpty) {
      try {
        final defs = workerRegistrations.map((reg) {
          return {
            'name': reg.taskName ?? 'form_fields_background_task',
            'frequency': reg.frequency,
            'initialDelay': reg.initialDelay,
            'periodic': reg.periodic,
          };
        }).toList();
        ForegroundTaskService.instance.setProvidedWorkerDefinitions(defs);
      } catch (_) {}

      // Register provided worker registrations via helper to keep logic small
      // and reusable. The helper returns the first provided background handler
      // (if any) so we can register it at the package level.
      final BackgroundTaskHandler? firstHandler = await _registerWorkers(
          workerRegistrations,
          triggerOnStart: triggerWorkerHandlersOnStart);

      if (firstHandler != null) {
        try {
          ForegroundTaskService.instance.setHandler(firstHandler);
          ForegroundTaskService.setBackgroundTaskHandler(firstHandler);
        } catch (e, st) {
          _log.warning('Failed to set background task handler: $e', e, st);
        }
      }
      return;
    }

    // Fallback: no registrations provided. If `autoStartForegroundService`
    // is true and `registerPeriodic` is set, start the default service
    // without scheduling tasks (legacy behavior removed; nothing to
    // register).
    if (autoStartForegroundService) {
      try {
        await ForegroundTaskService.instance.start(
          taskName: null,
          frequency: const Duration(hours: 1),
          periodic: false,
          inputData: null,
          initialDelay: Duration.zero,
        );
      } catch (e, st) {
        _log.warning('Failed to auto-start ForegroundTaskService: $e', e, st);
      }
    }
  }

  /// Initialize DB, logging, foreground-service and any other services the package
  /// requires. Designed to be called from app `main()` so the host app
  /// doesn't need to initialize each service individually.
  static Future<void> initAll({
    String dbName = 'form_fields.db',
    bool enableForegroundService = true,
    bool registerPeriodic = true,

    /// If true the initializer will call `ForegroundTaskService.instance.start()`
    /// after initialization. Use this to opt-in to automatic scheduling from
    /// `initAll`.
    bool autoStartForegroundService = false,

    /// Optional top-level callback dispatcher to register with the package's
    /// foreground-task adapter in the host app. If provided and
    /// `enableForegroundService` is true, `initAll` will register this
    /// dispatcher so background isolates can reach the host's top-level
    /// dispatcher.
    void Function()? foregroundTaskCallbackDispatcher,

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

    /// If true, call each registration's foreground/background handlers
    /// immediately at startup (in addition to scheduling periodic runs).
    /// Default: true.
    bool triggerWorkerHandlersOnStart = true,

    /// Whether `ForegroundTaskService` should listen for connectivity changes
    /// and attempt foreground flushes when network returns. Defaults to
    /// `true`.
    bool useConnectivity = true,

    // Optional host-provided flush handlers that will be registered on
    // package startup so callers can invoke host-provided flush logic via
    // `FlushApi.flushPendingSubmissions` / `FlushApi.flushPendingSubmissionById`.
    FlushAllHandler? flushAll,
    FlushOneHandler? flushOne,
  }) async {
    // Setup logging
    Logger.root.level = logLevel;
    Logger.root.onRecord.listen((rec) {
      /// Strategy for background execution. Defaults to `foregroundService`.
      // BackgroundStrategy backgroundStrategy =
      //     BackgroundStrategy.foregroundService,
      if (kDebugMode) {
        print(rec.message);
      }
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

    await _initForegroundIfNeeded(
      enableForegroundService: enableForegroundService,
      foregroundTaskCallbackDispatcher: foregroundTaskCallbackDispatcher,
      workerRegistrations: workerRegistrations,
      registerPeriodic: registerPeriodic,
      autoStartForegroundService: autoStartForegroundService,
      triggerWorkerHandlersOnStart: triggerWorkerHandlersOnStart,
      useConnectivity: useConnectivity,
    );
    _log.info('FormFields initialized');
  }

  // NOTE: `FlushApi` registration is no longer performed automatically
  // by `initAll`. Hosts who want to expose flush handlers should call
  // `FlushApi.register(...)` themselves at app startup.

  /// Change the on-disk database version by triggering the DB migration
  /// flow. This will open/reconcile the DB and run upgrades/downgrades as
  /// needed. If `migrationAssetPaths` are provided they will be used to
  // backgroundStrategy: backgroundStrategy,
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
