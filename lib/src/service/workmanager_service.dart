import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'flush_api.dart';
import 'flush_state.dart';

/// Thin wrapper around the `workmanager` plugin that provides a small,
/// testable surface for the example app. Includes per-task scheduling
/// metadata and a `perTaskCountdownListenable` so the UI can show
/// countdowns for each registered worker.
class WorkmanagerService {
  WorkmanagerService._internal() {
    _attachLastLogListener();
  }

  static final WorkmanagerService _instance = WorkmanagerService._internal();
  factory WorkmanagerService() => _instance;
  static WorkmanagerService get instance => _instance;

  bool _suppressListener = false;
  bool _initialized = false;

  // Basic state exposed to the UI
  final ValueNotifier<String?> statusListenable = ValueNotifier(null);
  final ValueNotifier<String?> lastLogListenable = ValueNotifier(null);
  final ValueNotifier<int> registeredCountListenable = ValueNotifier(0);
  final ValueNotifier<int> pendingChangedListenable = ValueNotifier(0);
  final ValueNotifier<String?> countdownListenable = ValueNotifier(null);
  final ValueNotifier<Map<String, String?>> perTaskCountdownListenable =
      ValueNotifier(<String, String?>{});

  DateTime? lastRunAt;

  // Internal bookkeeping
  final List<String> _logs = <String>[];
  final Set<String> _registeredTasks = <String>{};
  final Map<String, DateTime?> _scheduledAtPerTask = <String, DateTime?>{};
  final Map<String, Duration?> _scheduledFrequencyPerTask =
      <String, Duration?>{};
  // Preserve the originally requested frequency (what host passed) so the
  // UI can opt to display requested intervals even if the platform adjusts
  // the effective scheduling interval (e.g. Android WorkManager min).
  final Map<String, Duration?> _scheduledRequestedFrequencyPerTask =
      <String, Duration?>{};

  Duration? configuredFrequency;
  Timer? _countdownTimer;

  StreamSubscription<dynamic>? _connectivitySub;

  /// Host-provided top-level background handler resolver (optional).
  static BackgroundTaskHandler? _backgroundHandler;

  /// Optional handler the host registers to perform a foreground flush.
  Future<void> Function()? foregroundFlushHandler;

  /// Per-task foreground flush handlers (registered by task name).
  final Map<String, Future<void> Function()> _perTaskForegroundHandlers = {};

  /// Register a foreground handler for a specific task name.
  void setForegroundHandlerForTask(
      String taskName, Future<void> Function()? handler) {
    try {
      if (handler == null) {
        _perTaskForegroundHandlers.remove(taskName);
      } else {
        _perTaskForegroundHandlers[taskName] = handler;
      }
    } catch (_) {}
  }

  static const String _defaultTaskName = 'form_fields_background_task';

  void _attachLastLogListener() {
    lastLogListenable.addListener(() {
      try {
        if (_suppressListener) return;
        final v = lastLogListenable.value;
        if (v != null) {
          _logs.add(v);
          if (_logs.length > 50) _logs.removeAt(0);
        }
      } catch (_) {}
    });
  }

  /// Helper for legacy example usage.
  static void setBackgroundTaskHandler(BackgroundTaskHandler handler) {
    _backgroundHandler = handler;
  }

  /// Initialize the workmanager plugin and connectivity listener.
  Future<void> initialize({void Function()? callbackDispatcher}) async {
    if (_initialized) return;
    try {
      await Workmanager().initialize(
          callbackDispatcher ?? WorkmanagerService._callbackDispatcher);
      _initialized = true;

      // Listen for connectivity changes and invoke foreground flush when online.
      try {
        _connectivitySub =
            Connectivity().onConnectivityChanged.listen((_) async {
          try {
            final current = await Connectivity().checkConnectivity();
            final curStr = current.toString().toLowerCase();
            final hasNetwork = !curStr.contains('none');
            if (hasNetwork) {
              _addLog('connectivity: $current -> attempting flush');
              try {
                await foregroundFlushHandler?.call();
              } catch (e) {
                _addLog('flush handler error: $e');
              }
            }
          } catch (_) {}
        });
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Workmanager initialize failed: $e');
      }
    }
  }

  void setHandler(BackgroundTaskHandler handler) {
    // kept for API compatibility; not used by this wrapper.
  }

  /// Start a worker. Records per-task metadata to support per-worker UI.
  Future<void> start({
    String? taskName,
    Duration? frequency,
    bool periodic = true,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
  }) async {
    await initialize();

    final name = taskName ?? _defaultTaskName;
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
        if (_backgroundHandler != null) {
          final handle = PluginUtilities.getCallbackHandle(_backgroundHandler!);
          if (kDebugMode) {
            // ignore: avoid_print
            print('getCallbackHandle for _backgroundHandler -> $handle');
          }
          // Only embed the global background handler if the caller did not
          // already provide a `callback_handle` (per-registration handlers
          // should take precedence).
          if (handle != null && data['callback_handle'] == null) {
            data['callback_handle'] = handle.toRawHandle();
            if (kDebugMode) {
              // ignore: avoid_print
              print(
                  'embedding callback_handle raw=${handle.toRawHandle()} into inputData');
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
        const Duration kAndroidMinPeriodic = Duration(minutes: 15);
        try {
          if (frequency != null && frequency < kAndroidMinPeriodic) {
            effectiveFreq = kAndroidMinPeriodic;
            _addLog(
                'effective_interval_adjusted: $name requested_s=${frequency.inSeconds} -> effective_s=${effectiveFreq.inSeconds}');
            try {
              // also print to console to aid debugging via logcat
              // ignore: avoid_print
              print(
                  'effective_interval_adjusted: $name requested_s=${frequency.inSeconds} -> effective_s=${effectiveFreq.inSeconds}');
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
              'registered_from_start: $name freq_s=$freqS initialDelay_s=${initialDelay?.inSeconds ?? 0} scheduledAt=$sat nextEst=$next');
          try {
            // Print to console so it's visible in adb logcat (helpful when
            // the UI dialog isn't easily copyable).
            // ignore: avoid_print
            print(
                'registered_from_start: $name freq_s=$freqS initialDelay_s=${initialDelay?.inSeconds ?? 0} scheduledAt=$sat nextEst=$next');
          } catch (_) {}
        } catch (_) {}
        _startCountdownTimer();
      } else {
        await Workmanager().registerOneOffTask(name, name, inputData: data);
        _scheduledAtPerTask[name] = DateTime.now();
        _scheduledFrequencyPerTask[name] = null;
        _addLog('task_registered (one-off): $name');
        // keep timer running for UI if other periodic tasks exist
        _startCountdownTimer();
      }

      _registeredTasks.add(name);
      registeredCountListenable.value = _registeredTasks.length;
      statusListenable.value =
          periodic ? 'registered_periodic' : 'registered_once';
      _addLog('registered ${periodic ? 'periodic' : 'one-off'}: $name');
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Workmanager register task failed: $e');
      }
      statusListenable.value = 'register_failed';
      _addLog('register_failed: $e');
    }
  }

  /// Run a one-off task immediately.
  Future<String?> runOnceNowDetailed({
    String? taskName,
    Map<String, dynamic>? inputData,
  }) async {
    final name =
        taskName ?? 'run_once_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final data = inputData != null
          ? Map<String, dynamic>.from(inputData)
          : <String, dynamic>{};
      try {
        if (_backgroundHandler != null) {
          final handle = PluginUtilities.getCallbackHandle(_backgroundHandler!);
          if (kDebugMode) {
            // ignore: avoid_print
            print('getCallbackHandle for runOnceNowDetailed -> $handle');
          }
          if (handle != null) data['callback_handle'] = handle.toRawHandle();
        }
      } catch (_) {}

      await Workmanager().registerOneOffTask(name, name, inputData: data);
      final now = DateTime.now();
      _registeredTasks.add(name);
      _scheduledAtPerTask[name] = now;
      _scheduledFrequencyPerTask[name] = null;
      registeredCountListenable.value = _registeredTasks.length;
      _addLog('registered one-off (run now): $name');
      _startCountdownTimer();
      return null;
    } catch (e) {
      _addLog('runOnceNowDetailed failed: $e');
      return e.toString();
    }
  }

  /// Stop specific task or all tasks.
  Future<void> stop({VoidCallback? onStop, String? taskName}) async {
    try {
      onStop?.call();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('onStop callback threw: $e');
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
          // ignore: avoid_print
          print('cancelAll failed: $e');
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
            // ignore: avoid_print
            print('cancelByUniqueName failed for $name: $e');
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

    try {
      await _connectivitySub?.cancel();
      _connectivitySub = null;
      foregroundFlushHandler = null;
      _addLog(
          'stopped: connectivity listener cancelled and flush handler cleared');
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('failed to cancel connectivity subscription: $e');
      }
    }
  }

  void _startCountdownTimer() {
    try {
      _countdownTimer?.cancel();
      countdownListenable.value = null;
      if (_registeredTasks.isEmpty) return;

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        try {
          final now = DateTime.now();
          Duration? minRem;
          final Map<String, String?> perMap = {};
          final List<String> toTrigger = [];

          for (final tName in _registeredTasks) {
            final at = _scheduledAtPerTask[tName];
            // Prefer displaying the requested frequency when the host
            // provided definitions (the user expects the UI to reflect
            // `workerRegistrations`). Fall back to the effective platform
            // frequency otherwise.
            Duration? fq;
            final requested = _scheduledRequestedFrequencyPerTask[tName];
            if (_providedWorkerDefinitions != null && requested != null) {
              fq = requested;
            } else {
              fq = _scheduledFrequencyPerTask[tName];
            }
            if (at == null || fq == null) {
              perMap[tName] = null;
              continue;
            }
            final next = at.add(fq);
            final rem = next.difference(now);
            if (rem.inMilliseconds <= 0) {
              toTrigger.add(tName);
              perMap[tName] = '00:00';
              minRem = const Duration(seconds: 0);
            } else {
              final h = rem.inHours;
              final m = rem.inMinutes.remainder(60);
              final s = rem.inSeconds.remainder(60);
              final display = h > 0
                  ? '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                  : '${m.toString()}:${s.toString().padLeft(2, '0')}';
              perMap[tName] = display;
              if (minRem == null || rem < minRem) minRem = rem;
            }
          }

          try {
            perTaskCountdownListenable.value = perMap;
          } catch (_) {}

          if (minRem == null) {
            try {
              countdownListenable.value = null;
            } catch (_) {}
          } else {
            final h = minRem.inHours;
            final m = minRem.inMinutes.remainder(60);
            final s = minRem.inSeconds.remainder(60);
            final display = h > 0
                ? '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                : '${m.toString()}:${s.toString().padLeft(2, '0')}';
            try {
              countdownListenable.value = display;
            } catch (_) {}
          }

          if (toTrigger.isNotEmpty) {
            try {
              lastLogListenable.value =
                  'countdown-trigger: calling flushPendingSubmissions()';
            } catch (_) {}

            // Prevent overlapping flush runs using FlushState guard.
            if (FlushState.isFlushing) {
              try {
                lastLogListenable.value =
                    'countdown-trigger: flush already in progress; skipping';
              } catch (_) {}
            } else {
              FlushState.isFlushing = true;
              var success = false;
              try {
                try {
                  lastLogListenable.value =
                      'countdown-trigger: toTrigger=${toTrigger.join(',')}';
                } catch (_) {}
                // Prefer per-task foreground handlers. Call each task's
                // handler if registered. If no per-task handlers were
                // invoked, fall back to the global `foregroundFlushHandler`
                // or to `FlushApi.flushPendingSubmissions()`.
                // Deduplicate handlers so a single function reference is only
                // invoked once even if it is registered for multiple tasks.
                final Set<Future<void> Function()> uniqueHandlers = {};
                for (final n in toTrigger) {
                  final h = _perTaskForegroundHandlers[n];
                  if (h != null) uniqueHandlers.add(h);
                }

                if (uniqueHandlers.isNotEmpty) {
                  try {
                    lastLogListenable.value =
                        'countdown-trigger: invoking ${uniqueHandlers.length} per-task handlers';
                  } catch (_) {}
                  for (final h in uniqueHandlers) {
                    try {
                      await h();
                      success = true;
                      try {
                        lastLogListenable.value = 'task-handler success';
                      } catch (_) {}
                    } catch (e, st) {
                      try {
                        lastLogListenable.value = 'task-handler threw: $e';
                      } catch (_) {}
                      try {
                        _addLog('task-handler threw: $e');
                      } catch (_) {}
                    }
                  }
                } else {
                  // No per-task handlers registered. Call the global
                  // foreground handler or fallback flush function once.
                  if (foregroundFlushHandler != null) {
                    try {
                      lastLogListenable.value =
                          'countdown-trigger: calling global foregroundFlushHandler';
                    } catch (_) {}
                    try {
                      await foregroundFlushHandler!();
                      success = true;
                      try {
                        lastLogListenable.value =
                            'foregroundFlushHandler success';
                      } catch (_) {}
                    } catch (e, st) {
                      try {
                        lastLogListenable.value =
                            'foregroundFlushHandler threw: $e';
                      } catch (_) {}
                    }
                  } else {
                    try {
                      lastLogListenable.value =
                          'countdown-trigger: calling FlushApi.flushPendingSubmissions';
                    } catch (_) {}
                    try {
                      success = await FlushApi.flushPendingSubmissions();
                      try {
                        lastLogListenable.value =
                            'FlushApi.flushPendingSubmissions -> ${success ? 'success' : 'failure'}';
                      } catch (_) {}
                    } catch (e, st) {
                      try {
                        lastLogListenable.value =
                            'FlushApi.flushPendingSubmissions threw: $e';
                      } catch (_) {}
                    }
                  }
                }
              } catch (e, st) {
                try {
                  lastLogListenable.value =
                      'countdown-triggered flush threw: $e\n$st';
                } catch (_) {}
              } finally {
                FlushState.isFlushing = false;
              }

              try {
                lastLogListenable.value =
                    'countdown-triggered flush: ${success ? 'success' : 'failure'}';
              } catch (_) {}

              try {
                final now2 = DateTime.now();
                for (final n in toTrigger) {
                  if (_scheduledFrequencyPerTask[n] != null) {
                    _scheduledAtPerTask[n] = now2;
                  }
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _stopCountdownTimer() {
    try {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    } catch (_) {}
    try {
      countdownListenable.value = null;
    } catch (_) {}
  }

  DateTime? get nextEstimatedRun {
    try {
      // return nearest non-null scheduled run across tasks
      DateTime? next;
      for (final t in _registeredTasks) {
        final at = _scheduledAtPerTask[t];
        final fq = _scheduledFrequencyPerTask[t];
        if (at != null && fq != null) {
          final candidate = at.add(fq);
          if (next == null || candidate.isBefore(next)) next = candidate;
        }
      }
      return next;
    } catch (_) {
      return null;
    }
  }

  void _addLog(String msg) {
    try {
      _logs.add(msg);
      if (_logs.length > 50) _logs.removeAt(0);
      _suppressListener = true;
      lastLogListenable.value = msg;
      _suppressListener = false;
    } catch (_) {}
  }

  void notifyPendingChanged() {
    try {
      pendingChangedListenable.value = pendingChangedListenable.value + 1;
    } catch (_) {}
  }

  List<String> get recentLogs => List.unmodifiable(_logs);

  List<String> get registeredTaskNames => List.unmodifiable(_registeredTasks);

  // Optional host-provided definitions (populated by FormFieldsInitializer
  // when the host passed `workerRegistrations` to `initAll`). If present
  // these are used by the example UI instead of the built-in demo defs.
  List<Map<String, dynamic>>? _providedWorkerDefinitions;

  /// Called by hosts (via `FormFieldsInitializer`) to expose the
  /// registration metadata used at startup. The example UI reads
  /// `providedWorkerDefinitions` so it doesn't hardcode demo values.
  void setProvidedWorkerDefinitions(List<Map<String, dynamic>> defs) {
    try {
      _providedWorkerDefinitions = List<Map<String, dynamic>>.from(defs);
      try {
        for (final d in _providedWorkerDefinitions!) {
          final name = d['name'];
          final freq = d['frequency'] is Duration
              ? (d['frequency'] as Duration).inSeconds
              : d['frequency']?.toString();
          _addLog('provided_def: $name freq_s=$freq');
          try {
            // Also print to console so adb logcat captures it.
            // ignore: avoid_print
            print('provided_def: $name freq_s=$freq');
          } catch (_) {}
        }
      } catch (_) {}
    } catch (_) {}
  }

  /// Return the host-provided definitions when available, otherwise fall
  /// back to the internal `demoWorkerDefinitions` used by the example.
  List<Map<String, dynamic>> get providedWorkerDefinitions =>
      _providedWorkerDefinitions ?? demoWorkerDefinitions;

  /// Return a snapshot of per-task metadata for debugging/inspection.
  Map<String, Map<String, dynamic>> get taskMetadata {
    final Map<String, Map<String, dynamic>> out = {};
    for (final t in _registeredTasks) {
      out[t] = {
        'scheduledAt': _scheduledAtPerTask[t]?.toIso8601String(),
        'requestedFrequencySeconds':
            _scheduledRequestedFrequencyPerTask[t]?.inSeconds,
        'effectiveFrequencySeconds': _scheduledFrequencyPerTask[t]?.inSeconds,
      };
    }
    return out;
  }

  /// Demo worker definitions used by the example UI to offer a
  /// "Start All" convenience. This intentionally contains only metadata
  /// (names, frequencies, initial delays) and does not reference any
  /// handler functions so it can live inside the service layer.
  static List<Map<String, dynamic>> get demoWorkerDefinitions {
    return [
      {
        'name': 'form_fields_flush',
        'frequency': const Duration(seconds: 20),
        'initialDelay': Duration.zero,
      },
      {
        'name': 'send_current_location',
        // Use minutes for realistic scheduling in the example.
        'frequency': const Duration(minutes: 70),
        'initialDelay': Duration.zero,
      },
      {
        'name': 'send_random_event',
        // Use minutes for realistic scheduling in the example.
        'frequency': const Duration(minutes: 70),
        'initialDelay': Duration.zero,
      },
    ];
  }

  bool get isInitialized => _initialized;

  void clearLogs() {
    try {
      _logs.clear();
      _suppressListener = true;
      lastLogListenable.value = null;
      _suppressListener = false;
    } catch (_) {}
  }

  // Background callback dispatcher used by Workmanager plugin.
  static void _callbackDispatcher() {
    WidgetsFlutterBinding.ensureInitialized();

    Workmanager().executeTask((task, inputData) async {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Workmanager executeTask: $task, inputData: $inputData');
      }

      try {
        if (inputData != null && inputData['callback_handle'] != null) {
          try {
            final raw = inputData['callback_handle'];
            final rawHandle = raw is int ? raw : int.parse(raw.toString());
            final cbHandle = CallbackHandle.fromRawHandle(rawHandle);
            if (kDebugMode) {
              // ignore: avoid_print
              print('Attempting to resolve callback handle: $rawHandle');
            }
            final cb = PluginUtilities.getCallbackFromHandle(cbHandle);
            if (kDebugMode) {
              // ignore: avoid_print
              print('Resolved callback: $cb');
            }
            if (cb is BackgroundTaskHandler) {
              final res = await cb(task, inputData as Map<String, dynamic>?);
              return Future.value(res);
            } else {
              if (kDebugMode) {
                // ignore: avoid_print
                print(
                    'Callback resolved but is not BackgroundTaskHandler: $cb');
              }
              // If we could not resolve a usable callback, bail out with
              // `false` so Workmanager does not treat the task as succeeded.
              return Future.value(false);
            }
          } catch (e) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('failed to resolve callback_handle: $e');
            }
          }
        }

        if (_backgroundHandler != null) {
          try {
            if (kDebugMode) {
              // ignore: avoid_print
              print(
                  'Using static _backgroundHandler fallback: $_backgroundHandler');
            }
            final res = await _backgroundHandler!(task, inputData);
            return Future.value(res);
          } catch (e) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('background handler threw: $e');
            }
            return Future.value(false);
          }
        }
      } catch (_) {}

      return Future.value(true);
    });
  }

  @pragma('vm:entry-point')
  void workmanagerCallbackDispatcher() =>
      WorkmanagerService._callbackDispatcher();
}
