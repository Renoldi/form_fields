part of '../init_service.dart';

/// Internal owner of [FormFieldsInitializer] members moved out of the main file.
class _FormFieldsInitSteps {
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
    await FormFieldsInitializer._logSubscription?.cancel();
    FormFieldsInitializer._logSubscription = Logger.root.onRecord.listen((rec) {
      // Console output is for debug builds. Release builds print nothing from
      // here, so records with file paths or payload details stay out of the
      // device log. Host apps can still attach their own `Logger.root` listener.
      if (!kDebugMode) return;
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

    await _FormFieldsStartup._applyMigrationAssetsIfNeeded(
      db: db,
      dbVersion: dbVersion,
      migrationAssetPaths: migrationAssetPaths,
      invokeOnUpgradeWhenDbVersionZero: invokeOnUpgradeWhenDbVersionZero,
      onUpgrade: onUpgrade,
      onCreate: onCreate,
    );

    await _FormFieldsStartup._restorePendingUploads();

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

    await _FormFieldsWorkerRegistry._initWorkmanagerIfNeeded(
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
}
