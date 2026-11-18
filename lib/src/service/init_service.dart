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
part 'init_service_parts/init_registration.dart';
part 'init_service_parts/init_startup.dart';
part 'init_service_parts/init_all.dart';

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

  /// Delay before startup handlers run on iOS, so platform APIs are not called
  /// before the app has finished launching.
  static const Duration _iosStartupDelay = Duration(seconds: 2);

  /// Initialize DB, logging, workmanager and any other services the package
  /// requires. Designed to be called from app `main()` so the host app
  /// doesn't need to initialize each service individually.
  static Future<void> initAll({
    String dbName = 'form_fields.db',
    bool enableWorkmanager = true,
    bool registerPeriodic = true,
    bool autoStartWorkmanager = false,
    void Function()? workmanagerCallbackDispatcher,
    List<WorkerRegistration>? workerRegistrations,
    Level logLevel = Level.INFO,
    List<String>? migrationAssetPaths,
    int dbVersion = 0,
    bool invokeOnUpgradeWhenDbVersionZero = true,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
    bool triggerWorkerHandlersOnStart = true,
    bool deferStartupHandlersOnIos = true,
    bool useConnectivity = true,
    FlushAllHandler? flushAll,
    FlushOneHandler? flushOne,
    Future<void> Function()? foregroundFlushHandler,
  }) => _FormFieldsInitSteps.initAll(
    dbName: dbName,
    enableWorkmanager: enableWorkmanager,
    registerPeriodic: registerPeriodic,
    autoStartWorkmanager: autoStartWorkmanager,
    workmanagerCallbackDispatcher: workmanagerCallbackDispatcher,
    workerRegistrations: workerRegistrations,
    logLevel: logLevel,
    migrationAssetPaths: migrationAssetPaths,
    dbVersion: dbVersion,
    invokeOnUpgradeWhenDbVersionZero: invokeOnUpgradeWhenDbVersionZero,
    onConfigure: onConfigure,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
    onDowngrade: onDowngrade,
    onOpen: onOpen,
    triggerWorkerHandlersOnStart: triggerWorkerHandlersOnStart,
    deferStartupHandlersOnIos: deferStartupHandlersOnIos,
    useConnectivity: useConnectivity,
    flushAll: flushAll,
    flushOne: flushOne,
    foregroundFlushHandler: foregroundFlushHandler,
  );

  // NOTE: `FlushApi` registration is no longer performed automatically
  // by `_FormFieldsInitSteps.initAll`. Hosts who want to expose flush handlers should call
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
