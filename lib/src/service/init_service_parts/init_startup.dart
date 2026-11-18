part of '../init_service.dart';

/// Internal owner of [FormFieldsInitializer] members moved out of the main file.
class _FormFieldsStartup {
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

    // Versioned assets run only when they are newer than the DB. Re-running an
    // older one (for example CREATE TABLE) fails and blocks the newer assets
    // from ever being recorded. Unversioned assets run on every start, as before.
    final current = maxVer > 0
        ? (await DBService.instance.selectDbVersion().catchError((_) => null) ??
              0)
        : 0;
    final toRun = [
      for (final asset in migrationAssetPaths)
        if ((parseMigrationVersion(asset) ?? 0) == 0 ||
            parseMigrationVersion(asset)! > current)
          asset,
    ];
    if (toRun.isEmpty) {
      _log.fine('DB already at version $current; migration assets skipped');
      return;
    }

    var failed = false;
    for (final asset in toRun) {
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
        // Only the steps that were just applied. Steps at or below [current]
        // were already in place, so their hooks must not run again.
        for (var v = current + 1; v <= maxVer; v++) {
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

  /// Runs [action] now, or after [FormFieldsInitializer._iosStartupDelay] when [defer] is true.
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
      unawaited(
        Future<void>.delayed(FormFieldsInitializer._iosStartupDelay, guarded),
      );
    } else {
      await guarded();
    }
  }
}
