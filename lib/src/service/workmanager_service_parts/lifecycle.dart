part of '../workmanager_service.dart';

extension _WorkmanagerLifecycleX on WorkmanagerService {
  Future<void> _initialize({
    void Function()? callbackDispatcher,
    bool useConnectivity = true,
  }) async {
    if (_initialized) return;
    try {
      final cb = callbackDispatcher ?? workmanagerCallbackDispatcher;
      if (kDebugMode) {
        _log.fine(
          'Workmanager initialize: callbackDispatcher is ${'provided'}',
        );
      }
      await Workmanager().initialize(cb);
      _initialized = true;

      // Optionally run the foreground flush when connectivity returns.
      // Hosts can disable this with `initialize(..., useConnectivity: false)`.
      if (useConnectivity) startConnectivityFlush();
    } catch (e, st) {
      // Always recorded, release builds included. Without this, a failed
      // background setup looks like it was never requested.
      _log.warning('Workmanager initialize failed: $e', e, st);
      _addLog('initialize_failed: $e');
    }
  }

  Future<void> _start({
    String? taskName,
    Duration? frequency,
    bool periodic = true,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    await initialize();

    final name = taskName ?? WorkmanagerService._defaultTaskName;
    // Prevent duplicate registrations for the same unique name. If the
    // task was already registered we skip re-registering to avoid the
    // handler being invoked multiple times for a single scheduled run.
    if (_registeredTasks.contains(name)) {
      _addLog('already_registered: $name');
      return;
    }
    try {
      final data = inputData != null
          ? Map<String, dynamic>.from(inputData)
          : <String, dynamic>{};
      try {
        if (WorkmanagerService._backgroundHandler != null) {
          final handle = PluginUtilities.getCallbackHandle(
            WorkmanagerService._backgroundHandler!,
          );
          if (kDebugMode) {
            _log.fine(
              'getCallbackHandle for WorkmanagerService._backgroundHandler -> $handle',
            );
          }
          // Only embed the global background handler if the caller did not
          // already provide a `callback_handle` (per-registration handlers
          // should take precedence).
          if (handle != null && data['callback_handle'] == null) {
            data['callback_handle'] = handle.toRawHandle();
            if (kDebugMode) {
              _log.fine(
                'embedding callback_handle raw=${handle.toRawHandle()} into inputData',
              );
            }
          }
        }
      } catch (_) {}

      if (periodic) {
        await Workmanager().registerPeriodicTask(
          name,
          name,
          frequency: frequency,
          inputData: data,
          initialDelay: initialDelay,
          foregroundServiceConfig: foregroundServiceConfig,
        );
        // record metadata
        if (frequency != null) configuredFrequency = frequency;
        _scheduledAtPerTask[name] = DateTime.now();
        // Store requested frequency separately so UI can display it if the
        // host provided registrations. We'll compute an effective frequency
        // next (platform may enforce a minimum).
        _scheduledRequestedFrequencyPerTask[name] = frequency;
        // WorkManager on Android enforces a minimum periodic interval
        // (typically 15 minutes). Use the effective interval for UI
        // countdowns so the app reflects what the platform will schedule.
        Duration? effectiveFreq = frequency;
        try {
          if (frequency != null && frequency < kAndroidMinPeriodicInterval) {
            effectiveFreq = kAndroidMinPeriodicInterval;
            _addLog(
              'effective_interval_adjusted: $name requested_s=${frequency.inSeconds} -> effective_s=${effectiveFreq.inSeconds}',
            );
            try {
              // also print to console to aid debugging via logcat
              _log.fine(
                'effective_interval_adjusted: $name requested_s=${frequency.inSeconds} -> effective_s=${effectiveFreq.inSeconds}',
              );
            } catch (_) {}
          }
        } catch (_) {}
        _scheduledFrequencyPerTask[name] = effectiveFreq;
        _addLog('task_registered: $name freq=${frequency?.inSeconds ?? 0}s');
        try {
          final sat = _scheduledAtPerTask[name]?.toIso8601String();
          final freqS = _scheduledFrequencyPerTask[name]?.inSeconds;
          final next = _scheduledAtPerTask[name]
              ?.add(_scheduledFrequencyPerTask[name] ?? Duration.zero)
              .toIso8601String();
          _addLog(
            'registered_from_start: $name freq_s=$freqS initialDelay_s=${initialDelay?.inSeconds ?? 0} scheduledAt=$sat nextEst=$next',
          );
          try {
            // Print to console so it's visible in adb logcat (helpful when
            // the UI dialog isn't easily copyable).
            _log.fine(
              'registered_from_start: $name freq_s=$freqS initialDelay_s=${initialDelay?.inSeconds ?? 0} scheduledAt=$sat nextEst=$next',
            );
          } catch (_) {}
        } catch (_) {}
        _startCountdownTimer();
      } else {
        await Workmanager().registerOneOffTask(
          name,
          name,
          inputData: data,
          foregroundServiceConfig: foregroundServiceConfig,
        );
        _scheduledAtPerTask[name] = DateTime.now();
        _scheduledFrequencyPerTask[name] = null;
        _addLog('task_registered (one-off): $name');
        // keep timer running for UI if other periodic tasks exist
        _startCountdownTimer();
      }

      _registeredTasks.add(name);
      registeredCountListenable.value = _registeredTasks.length;
      statusListenable.value = periodic
          ? 'registered_periodic'
          : 'registered_once';
      _addLog('registered ${periodic ? 'periodic' : 'one-off'}: $name');
    } catch (e) {
      if (kDebugMode) {
        _log.fine('Workmanager register task failed: $e');
      }
      statusListenable.value = 'register_failed';
      _addLog('register_failed: $e');
    }
  }

  Future<String?> _runOnceNowDetailed({
    String? taskName,
    Map<String, dynamic>? inputData,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    final name =
        taskName ?? 'run_once_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final data = inputData != null
          ? Map<String, dynamic>.from(inputData)
          : <String, dynamic>{};
      try {
        if (WorkmanagerService._backgroundHandler != null) {
          final handle = PluginUtilities.getCallbackHandle(
            WorkmanagerService._backgroundHandler!,
          );
          if (kDebugMode) {
            _log.fine('getCallbackHandle for runOnceNowDetailed -> $handle');
          }
          if (handle != null) data['callback_handle'] = handle.toRawHandle();
        }
      } catch (_) {}

      await Workmanager().registerOneOffTask(
        name,
        name,
        inputData: data,
        foregroundServiceConfig: foregroundServiceConfig,
      );
      // A one-off run has no schedule and no name to wait for later. Keeping
      // it in `_registeredTasks` would only grow the registered list and the
      // countdown loop with every call, so it is not tracked there.
      _addLog('registered one-off (run now): $name');
      return null;
    } catch (e) {
      _addLog('runOnceNowDetailed failed: $e');
      return e.toString();
    }
  }

  Future<void> _stop({VoidCallback? onStop, String? taskName}) async {
    try {
      onStop?.call();
    } catch (e) {
      if (kDebugMode) {
        _log.fine('onStop callback threw: $e');
      }
    }

    if (taskName == null) {
      // Stop all: attempt to cancel all scheduled work via Workmanager's
      // dedicated API, then clear internal registration state so the UI
      // reflects that no tasks remain registered.
      try {
        await Workmanager().cancelAll();
        _addLog('cancelAll invoked');
      } catch (e) {
        if (kDebugMode) {
          _log.fine('cancelAll failed: $e');
        }
        _addLog('cancelAll_failed: $e');
      }

      // Clear our internal bookkeeping regardless of platform cancel
      // success so the app state reflects the user's intent to stop all.
      for (final name in _registeredTasks.toList(growable: false)) {
        _scheduledAtPerTask.remove(name);
        _scheduledFrequencyPerTask.remove(name);
        _addLog('cleared registration: $name');
      }
      _registeredTasks.clear();
    } else {
      final namesToCancel = <String>[taskName];
      for (final name in namesToCancel) {
        try {
          await Workmanager().cancelByUniqueName(name);
          _registeredTasks.remove(name);
          _scheduledAtPerTask.remove(name);
          _scheduledFrequencyPerTask.remove(name);
          _addLog('cancelled: $name');
        } catch (e) {
          if (kDebugMode) {
            _log.fine('cancelByUniqueName failed for $name: $e');
          }
          _addLog('cancel_failed: $name -> $e');
        }
      }
    }

    registeredCountListenable.value = _registeredTasks.length;
    if (_registeredTasks.isEmpty) {
      statusListenable.value = 'stopped';
      _scheduledAtPerTask.clear();
      _scheduledFrequencyPerTask.clear();
      _stopCountdownTimer();
    }

    // The connectivity and lifecycle flush is a separate feature from the
    // workers. It stays active here, so pending rows still go out when the
    // network returns. Use [stopConnectivityFlush] to turn it off.
  }

  /// Adds the background callback handle to [data], so a one-off run uses the
  /// same background handler as the periodic workers.
  Map<String, dynamic> _withCallbackHandle(Map<String, dynamic> data) {
    try {
      final handler = WorkmanagerService._backgroundHandler;
      if (handler != null) {
        final handle = PluginUtilities.getCallbackHandle(handler);
        if (handle != null) data['callback_handle'] = handle.toRawHandle();
      }
    } catch (_) {}
    return data;
  }

  /// Schedules a one-off background run after [delay]. The run is handled by
  /// the background path, so it still happens when the app is in background.
  /// A new call with the same [uniqueName] replaces the pending run.
  Future<void> _scheduleOneOff({
    required String uniqueName,
    Duration delay = Duration.zero,
    Map<String, dynamic>? inputData,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    final data = _withCallbackHandle(
      inputData != null
          ? Map<String, dynamic>.from(inputData)
          : <String, dynamic>{},
    );
    try {
      await Workmanager().registerOneOffTask(
        uniqueName,
        uniqueName,
        inputData: data,
        initialDelay: delay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        foregroundServiceConfig: foregroundServiceConfig,
      );
      _addLog('scheduled one-off: $uniqueName in ${delay.inSeconds}s');
    } catch (e) {
      _addLog('schedule one-off failed: $uniqueName -> $e');
    }
  }

  /// Cancels a one-off run scheduled with [_scheduleOneOff].
  Future<void> _cancelOneOff(String uniqueName) async {
    try {
      await Workmanager().cancelByUniqueName(uniqueName);
      _addLog('cancelled one-off: $uniqueName');
    } catch (e) {
      _addLog('cancel one-off failed: $uniqueName -> $e');
    }
  }
}
