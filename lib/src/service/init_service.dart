import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_service.dart';
import 'offline_upload_manager.dart';
import 'workmanager_service.dart';
import 'package:workmanager/workmanager.dart';
import 'flush_types.dart';

/// File (inside the app documents directory) that keeps upload successes which
/// are still waiting for their image to appear.
const String kPendingUploadsFileName = 'form_fields_pending_uploads.json';

final _log = Logger('FormFieldsInitializer');

// Strip common ANSI escape sequences (colors/etc.) so logs printed in
// environments that don't support ANSI (or where escapes are visible)
// remain readable.
final _ansiEscape = RegExp(r'\x1B\[[0-9;]*[A-Za-z]');

String _stripAnsi(String? input) {
  if (input == null) return '';
  return input.replaceAll(_ansiEscape, '');
}

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

  static StreamSubscription<LogRecord>? _logSubscription;

  /// Loads upload successes that were still pending when the app last closed,
  /// so they can be applied once their images reappear. Failures are logged;
  /// they must not block startup.
  static Future<void> _restorePendingUploads() async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      await OfflineUploadManager.instance.restorePending(
        File(p.join(documents.path, kPendingUploadsFileName)),
      );
    } catch (e, st) {
      _log.warning('Failed to restore pending uploads: $e', e, st);
    }
  }

  /// Apply migration assets when the DB is opened without a numeric version.
  /// Receives the already-opened [db] instance to invoke host callbacks.
  static Future<void> _applyMigrationAssetsIfNeeded({
    required Database db,
    required int dbVersion,
    required List<String>? migrationAssetPaths,
    required bool invokeOnUpgradeWhenDbVersionZero,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseCreateFn? onCreate,
  }) async {
    if (dbVersion != 0 ||
        migrationAssetPaths == null ||
        migrationAssetPaths.isEmpty) {
      return;
    }

    // Highest version declared by the assets (0 when they are unversioned).
    final maxVer = migrationAssetPaths
        .map(parseMigrationVersion)
        .whereType<int>()
        .fold<int>(0, (a, b) => b > a ? b : a);

    // Versioned assets are applied once: skip them when the DB is already
    // at (or beyond) the highest declared version. Unversioned assets keep
    // running on every start, as before.
    if (maxVer > 0) {
      final current =
          await DBService.instance.selectDbVersion().catchError((_) => null) ??
          0;
      if (current >= maxVer) {
        _log.fine('DB already at version $current; migration assets skipped');
        return;
      }
    }

    var failed = false;
    for (final asset in migrationAssetPaths) {
      try {
        _log.info('Applying migration asset via initAll: $asset');
        await DBService.instance.runMigrationAsset(asset);
      } catch (e, st) {
        failed = true;
        _log.warning('Failed to apply migration asset $asset: $e', e, st);
      }
    }

    // Recording the version after a failure would skip the failed asset on
    // every later start. Leave the version unchanged so the next start retries.
    if (failed) {
      _log.warning(
        'Migration incomplete; user_version not recorded, will retry on next start',
      );
      return;
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
          'onUpgrade callback threw during manual invocation: $e',
          e,
          st,
        );
      }
    }

    if (onCreate != null) {
      try {
        await onCreate(db, maxVer);
      } catch (e, st) {
        _log.warning(
          'onCreate callback threw during manual invocation: $e',
          e,
          st,
        );
      }
    }
  }

  /// Delay before startup handlers run on iOS, so platform APIs are not called
  /// before the app has finished launching.
  static const Duration _iosStartupDelay = Duration(seconds: 2);

  /// Registers each provided [WorkerRegistration]. Returns the first
  /// non-null `BackgroundTaskHandler` so the caller can register a
  /// package-level background handler. A failing registration is logged and
  /// does not stop the remaining ones.
  static Future<BackgroundTaskHandler?> _registerWorkers(
    List<WorkerRegistration> regs, {
    bool triggerOnStart = false,
    bool deferStartupHandlersOnIos = true,
  }) async {
    BackgroundTaskHandler? firstHandler;
    // One registration per handler + period. Key: <handlerKey>|<freq>|<periodic>
    final seen = <String>{};
    final deferOnIos =
        deferStartupHandlersOnIos &&
        defaultTargetPlatform == TargetPlatform.iOS;

    for (final reg in regs) {
      firstHandler ??= reg.backgroundHandler;
      if (reg.foregroundHandler != null) {
        _safeSetForegroundFlushHandler(reg.foregroundHandler);
      }
      if (!reg.register) continue;
      if (reg.periodic &&
          defaultTargetPlatform == TargetPlatform.android &&
          reg.frequency < kAndroidMinPeriodicInterval) {
        _log.warning(
          'Worker ${reg.taskName} requests ${reg.frequency.inSeconds}s, but '
          'Android runs periodic work at most every '
          '${kAndroidMinPeriodicInterval.inMinutes} minutes. '
          'Use a frequency of at least ${kAndroidMinPeriodicInterval.inMinutes} minutes.',
        );
      }

      final handlerKey = _registrationKey(reg);
      final dedupeKey = handlerKey == null
          ? null
          : '$handlerKey|${reg.frequency.inSeconds}|${reg.periodic}';
      if (dedupeKey != null && seen.contains(dedupeKey)) {
        // A skipped worker never runs, so this must be visible in the logs.
        _log.warning(
          'Worker ${reg.taskName} not registered: its handler and period '
          'match an earlier registration (inputData of this worker is ignored)',
        );
        continue;
      }

      try {
        final inputData = _inputDataFor(reg);
        await WorkmanagerService.instance.start(
          taskName: reg.taskName,
          frequency: reg.frequency,
          periodic: reg.periodic,
          inputData: inputData,
          initialDelay: reg.initialDelay,
        );

        if (triggerOnStart) {
          await _triggerAtStartup(reg, inputData, defer: deferOnIos);
        }
        if (dedupeKey != null) seen.add(dedupeKey);
        _registerTaskHandlers(reg);
        _log.fine('Registered worker: ${reg.taskName}');
      } catch (e, st) {
        _log.warning('Failed to register worker ${reg.taskName}: $e', e, st);
      }
    }

    return firstHandler;
  }

  /// Identity of a registration's handler, used for de-duplication. Prefers
  /// the background handler's callback handle (stable across isolates), then
  /// falls back to object identity. Returns null when there is no handler.
  static String? _registrationKey(WorkerRegistration reg) {
    final bg = reg.backgroundHandler;
    if (bg != null) {
      final handle = _callbackHandleOf(bg);
      return handle != null ? 'cb:$handle' : 'bg_hash:${bg.hashCode}';
    }
    final fg = reg.foregroundHandler;
    // Foreground handlers are usually closures, which have no callback handle.
    return fg != null ? 'fg_hash:${fg.hashCode}' : null;
  }

  /// Raw callback handle for a top-level or static [fn], or null when the
  /// function has none (for example, a closure).
  static int? _callbackHandleOf(Function fn) {
    try {
      return PluginUtilities.getCallbackHandle(fn)?.toRawHandle();
    } catch (_) {
      return null;
    }
  }

  /// Input data for a worker, with the background handler's callback handle
  /// embedded so the background isolate can resolve it. Null when empty.
  static Map<String, dynamic>? _inputDataFor(WorkerRegistration reg) {
    final data = <String, dynamic>{...?reg.inputData};
    final bg = reg.backgroundHandler;
    if (bg != null) {
      final handle = _callbackHandleOf(bg);
      if (handle != null) data['callback_handle'] = handle;
    }
    return data.isEmpty ? null : data;
  }

  /// Runs the registration's handlers once at startup. Opt-in via
  /// `triggerWorkerHandlersOnStart`.
  static Future<void> _triggerAtStartup(
    WorkerRegistration reg,
    Map<String, dynamic>? inputData, {
    required bool defer,
  }) async {
    final fg = reg.foregroundHandler;
    if (fg != null) {
      await _invokeAtStartup(
        label: 'foregroundHandler for ${reg.taskName}',
        defer: defer,
        action: fg,
      );
    }
    if (reg.backgroundHandler != null) {
      await _invokeAtStartup(
        label: 'runOnceNow for ${reg.taskName}',
        defer: defer,
        action: () async {
          await WorkmanagerService.instance.runOnceNowDetailed(
            taskName: reg.taskName,
            inputData: inputData,
          );
        },
      );
    }
  }

  /// Runs [action] now, or after [_iosStartupDelay] when [defer] is true.
  /// Failures are logged and never thrown to the caller.
  static Future<void> _invokeAtStartup({
    required String label,
    required bool defer,
    required Future<void> Function() action,
  }) async {
    Future<void> guarded() async {
      try {
        await action();
        _log.fine('Invoked $label on start');
      } catch (e, st) {
        _log.warning('$label threw during start invocation: $e', e, st);
      }
    }

    if (defer) {
      _log.fine('Deferring $label on iOS');
      unawaited(Future<void>.delayed(_iosStartupDelay, guarded));
    } else {
      await guarded();
    }
  }

  /// Registers the per-task foreground/background handlers so countdown
  /// triggers can run task-specific logic (e.g. `sendRandomForeground`).
  static void _registerTaskHandlers(WorkerRegistration reg) {
    final service = WorkmanagerService.instance;
    service.lastLogListenable.value =
        'registered_from_init: ${reg.taskName} freq_s=${reg.frequency.inSeconds}';
    final name = reg.taskName;
    if (name == null) return;
    if (reg.foregroundHandler != null) {
      service.setForegroundHandlerForTask(name, reg.foregroundHandler);
    }
    if (reg.backgroundHandler != null) {
      service.setBackgroundHandlerForTask(name, reg.backgroundHandler);
    }
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
    required bool triggerWorkerHandlersOnStart,
    required bool useConnectivity,
    required bool deferStartupHandlersOnIos,
  }) async {
    // Registrations are only honored when Workmanager actually runs. Warn
    // instead of silently ignoring them.
    if (workerRegistrations != null && workerRegistrations.isNotEmpty) {
      if (!enableWorkmanager) {
        _log.warning(
          'workerRegistrations (${workerRegistrations.length}) ignored: '
          'enableWorkmanager is false',
        );
      } else if (kIsWeb) {
        _log.warning(
          'workerRegistrations ignored: Workmanager is not '
          'supported on web',
        );
      }
    }
    if (!enableWorkmanager || kIsWeb) return;

    _log.info('Initializing WorkmanagerService');

    await WorkmanagerService.instance.initialize(
      callbackDispatcher: workmanagerCallbackDispatcher,
      useConnectivity: useConnectivity,
    );

    // If host provided registration metadata, expose it to the
    // WorkmanagerService so the example UI can read the host-provided
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
        WorkmanagerService.instance.setProvidedWorkerDefinitions(defs);
      } catch (_) {}

      // Register provided worker registrations via helper to keep logic small
      // and reusable. The helper returns the first provided background handler
      // (if any) so we can register it at the package level.
      final BackgroundTaskHandler? firstHandler = await _registerWorkers(
        workerRegistrations,
        triggerOnStart: triggerWorkerHandlersOnStart,
        deferStartupHandlersOnIos: deferStartupHandlersOnIos,
      );

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

    /// If true, call each registration's foreground/background handlers
    /// immediately at startup (in addition to scheduling periodic runs).
    /// Default: true.
    bool triggerWorkerHandlersOnStart = true,

    /// If true, `initAll` will defer invoking startup handlers on iOS by a
    /// short delay to avoid calling platform APIs before the app is fully
    /// initialized. Hosts may set this to `false` to preserve legacy
    /// immediate behavior (not recommended on iOS).
    bool deferStartupHandlersOnIos = true,

    /// Whether `WorkmanagerService` should listen for connectivity changes
    /// and attempt foreground flushes when network returns. Defaults to
    /// `true`.
    bool useConnectivity = true,
    // Optional host-provided flush handlers that will be registered on
    // package startup so callers can invoke host-provided flush logic via
    // `FlushApi.flushPendingSubmissions` / `FlushApi.flushPendingSubmissionById`.
    FlushAllHandler? flushAll,
    FlushOneHandler? flushOne,

    /// Runs when the device comes back online while the app is running. Works
    /// without Workmanager. When set, it takes precedence over the foreground
    /// handler of any `WorkerRegistration`.
    Future<void> Function()? foregroundFlushHandler,
  }) async {
    // Setup logging. Cancel the previous listener so repeated calls (hot
    // restart, tests) do not print every record more than once.
    Logger.root.level = logLevel;
    await _logSubscription?.cancel();
    _logSubscription = Logger.root.onRecord.listen((rec) {
      final raw =
          '${rec.level.name}: ${rec.time.toIso8601String()} '
          '${rec.loggerName} - ${rec.message}';
      final msg = _stripAnsi(raw);
      // ignore: avoid_print
      print(msg);
      if (rec.error != null) {
        // ignore: avoid_print
        print(_stripAnsi(rec.error.toString()));
      }
      if (rec.stackTrace != null) {
        // ignore: avoid_print
        print(_stripAnsi(rec.stackTrace.toString()));
      }
    });

    // Validate inputs to catch common misconfiguration early.
    // Validate worker registrations
    if (workerRegistrations != null) {
      for (final reg in workerRegistrations) {
        if (reg.frequency <= Duration.zero) {
          throw ArgumentError.value(
            reg.frequency,
            'workerRegistrations',
            'frequency must be > Duration.zero for ${reg.taskName}',
          );
        }
      }
    }

    if (dbVersion == 0 && onDowngrade != null) {
      _log.warning(
        'onDowngrade provided but will be ignored when dbVersion == 0',
      );
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

    await _restorePendingUploads();

    // Connectivity-triggered flush does not depend on Workmanager: it only
    // needs the running app. Start it here so `enableWorkmanager: false` still
    // flushes when the network returns.
    if (foregroundFlushHandler != null) {
      WorkmanagerService.instance.foregroundFlushHandler =
          foregroundFlushHandler;
    }
    if (useConnectivity) {
      WorkmanagerService.instance.startConnectivityFlush();
    }

    // No host-provided flush handlers are registered automatically anymore.
    // Hosts should register any FlushApi handlers explicitly when needed.

    await _initWorkmanagerIfNeeded(
      enableWorkmanager: enableWorkmanager,
      workmanagerCallbackDispatcher: workmanagerCallbackDispatcher,
      workerRegistrations: workerRegistrations,
      registerPeriodic: registerPeriodic,
      autoStartWorkmanager: autoStartWorkmanager,
      triggerWorkerHandlersOnStart: triggerWorkerHandlersOnStart,
      deferStartupHandlersOnIos: deferStartupHandlersOnIos,
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
  /// locate migration assets.
  static Future<Database> changeDbVersion(
    int targetVersion, {
    String dbName = 'form_fields.db',
    List<String>? migrationAssetPaths,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
  }) async {
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
