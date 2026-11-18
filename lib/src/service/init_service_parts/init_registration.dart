part of '../init_service.dart';

/// Internal owner of [FormFieldsInitializer] members moved out of the main file.
class _FormFieldsWorkerRegistry {
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
          await _FormFieldsStartup._triggerAtStartup(
            reg,
            inputData,
            defer: deferOnIos,
          );
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
}
