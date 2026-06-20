import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'flush_api.dart';

/// Top-level helper to register a background handler from the host app.
/// Provided for backward compatibility with example usage.
void setBackgroundTaskHandler(BackgroundTaskHandler handler) =>
    WorkmanagerService.setBackgroundTaskHandler(handler);

/// A small, reusable wrapper around the `workmanager` plugin that exposes
/// a simple start/stop API and accepts `VoidCallback` handlers from
/// outside the plugin for foreground start/stop notifications.
///
/// Note: background tasks run in a separate isolate and cannot directly
/// call closures provided from the app's UI isolate. The provided
/// `onStart` / `onStop` callbacks are executed in the foreground when
/// `start()` / `stop()` are called.
class WorkmanagerService {
  WorkmanagerService._internal();
  bool _suppressListener = false;

  /// Estimated time the periodic task was scheduled at (host local time).
  /// Used by example UI to show an estimated countdown. This is only an
  /// approximation — platform schedulers may run tasks at slightly different
  /// times.
  DateTime? scheduledAt;

  /// The configured periodic frequency passed to `start()` when a periodic
  /// task was registered. Exposed for example UI to compute countdowns.
  Duration? scheduledFrequency;

  /// The host-configured/default frequency supplied when the service was
  /// initialized (via `FormFieldsInitializer.initAll`) or when `start()`
  /// was last called. This value is NOT cleared on `stop()` so UI can
  /// reuse the original configured frequency when re-starting.
  Duration? configuredFrequency;
  Timer? _countdownTimer;

  /// Notifier for UI countdown display (mm:ss). Null when no countdown.
  final ValueNotifier<String?> countdownListenable = ValueNotifier(null);

  // Initialize listener to capture direct writes to `lastLogListenable`.
  // Many places in the code set `lastLogListenable.value = '...'` directly;
  // this listener ensures those messages are recorded in `_logs`.
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

  static final WorkmanagerService _instance = WorkmanagerService._internal()
    .._attachLastLogListener();
  factory WorkmanagerService() => _instance;

  /// Backward-compatible accessor used throughout the package.
  static WorkmanagerService get instance => _instance;

  bool _initialized = false;
  StreamSubscription<dynamic>? _connectivitySub;

  static const String _defaultTaskName = 'form_fields_background_task';

  /// Public status notifier and last-run timestamp used by example UI.
  final ValueNotifier<String?> statusListenable = ValueNotifier(null);
  DateTime? lastRunAt;

  /// Last log message and registered task count for UI introspection.
  final ValueNotifier<String?> lastLogListenable = ValueNotifier(null);
  final ValueNotifier<int> registeredCountListenable = ValueNotifier(0);
  final List<String> _logs = <String>[];
  final Set<String> _registeredTasks = <String>{};

  /// Notifier incremented when pending submissions change (rows deleted/added).
  /// Example UI can listen to this to refresh pending lists without parsing logs.
  final ValueNotifier<int> pendingChangedListenable = ValueNotifier<int>(0);

  /// `setHandler` is kept for API compatibility but foreground handlers
  /// are not used by this service. Background handlers must be registered
  /// with `setBackgroundTaskHandler`.

  /// Background handler registered via top-level `setBackgroundTaskHandler`.
  static BackgroundTaskHandler? _backgroundHandler;

  /// Optional handler provided by the host app to flush pending submissions
  /// when network connectivity is available. This callback runs in the
  /// foreground isolate and should handle DB access and network calls.
  Future<void> Function()? flushPendingHandler;

  /// Initialize the underlying Workmanager plugin once.
  ///
  /// Note: the `isInDebugMode` flag is deprecated — debug behavior should
  /// be handled via native `WorkmanagerDebug` handlers configured on the
  /// platform side (see plugin docs). This method no longer accepts that
  /// parameter and will ignore any debug mode toggles.
  Future<void> initialize({void Function()? callbackDispatcher}) async {
    if (_initialized) return;
    try {
      await Workmanager().initialize(callbackDispatcher ?? _callbackDispatcher);
      _initialized = true;
      // Listen for connectivity changes in the foreground isolate and
      // invoke the host-provided flush handler when network becomes
      // available.
      try {
        _connectivitySub =
            Connectivity().onConnectivityChanged.listen((_) async {
          try {
            final current = await Connectivity().checkConnectivity();
            // Determine network availability via string representation
            final curStr = current.toString().toLowerCase();
            final hasNetwork = !curStr.contains('none');
            if (hasNetwork) {
              _addLog('connectivity: $current -> attempting flush');
              try {
                await flushPendingHandler?.call();
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

  /// Register a foreground handler callable from the UI isolate.
  void setHandler(BackgroundTaskHandler handler) {
    // No-op: foreground handlers are intentionally not invoked here.
  }

  /// Register a top-level background handler so it can be invoked from
  /// background isolates. This is provided as a top-level convenience
  /// to match the package example usage.
  static void setBackgroundTaskHandler(BackgroundTaskHandler handler) {
    _backgroundHandler = handler;
  }

  /// Start the worker. Backwards-compatible signature used by examples.
  Future<void> start({
    String? taskName,
    Duration? frequency,
    bool periodic = true,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
  }) async {
    await initialize();

    final name = taskName ?? _defaultTaskName;
    try {
      // Ensure callback handle is included so background isolates can
      // resolve the original top-level handler via PluginUtilities.
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
          if (handle != null) {
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
        // Record estimated scheduling details so the UI can display a
        // countdown. Also record the configured/default frequency so the
        // UI can re-use it after a stop() rather than falling back to a
        // hard-coded default.
        scheduledFrequency = frequency;
        if (frequency != null) configuredFrequency = frequency;
        scheduledAt = DateTime.now();
        // Start internal countdown updater so UI can display remaining time.
        _startCountdownTimer();
      } else {
        await Workmanager().registerOneOffTask(name, name, inputData: data);
        // For one-off tasks we record the schedule time but clear the
        // periodic frequency.
        scheduledAt = DateTime.now();
        scheduledFrequency = null;
        // Clear any countdown for one-off tasks.
        _stopCountdownTimer();
      }
      statusListenable.value =
          periodic ? 'registered_periodic' : 'registered_once';
      // Track registration for UI.
      _registeredTasks.add(name);
      registeredCountListenable.value = _registeredTasks.length;
      _addLog('registered ${periodic ? 'periodic' : 'one-off'}: $name');
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Workmanager register task failed: $e');
      }
      statusListenable.value = 'register_failed';
      statusListenable.value = 'register_failed';
      _addLog('register_failed: $e');
    }
  }

  /// Run a one-off task immediately and return an error string on failure,
  /// otherwise null on success.
  Future<String?> runOnceNowDetailed(
      {String? taskName, Map<String, dynamic>? inputData}) async {
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
      // Record one-off registration
      _registeredTasks.add(name);
      registeredCountListenable.value = _registeredTasks.length;
      _addLog('registered one-off (run now): $name');
      return null;
    } catch (e) {
      _addLog('runOnceNowDetailed failed: $e');
      return e.toString();
    }
  }

  /// Stop the service and cancel any registered tasks.
  Future<void> stop({VoidCallback? onStop, String? taskName}) async {
    // Call the provided foreground callback right away.
    try {
      onStop?.call();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('onStop callback threw: $e');
      }
    }

    // If a specific taskName is provided, cancel only that task.
    // Otherwise, cancel all tracked registered tasks so `stop()` acts
    // as a blanket shutdown when called without arguments.
    final namesToCancel = taskName != null
        ? <String>[taskName]
        : _registeredTasks.toList(growable: false);
    for (final name in namesToCancel) {
      try {
        await Workmanager().cancelByUniqueName(name);
        _registeredTasks.remove(name);
        _addLog('cancelled: $name');
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('cancelByUniqueName failed for $name: $e');
        }
        _addLog('cancel_failed: $name -> $e');
      }
    }

    // Ensure public count/status reflect current state.
    registeredCountListenable.value = _registeredTasks.length;
    if (_registeredTasks.isEmpty) {
      statusListenable.value = 'stopped';
    }
    // If no tasks remain, clear scheduling metadata.
    if (_registeredTasks.isEmpty) {
      scheduledAt = null;
      scheduledFrequency = null;
      _stopCountdownTimer();
    }
    // Cancel connectivity listener so auto-send stops when service is stopped.
    try {
      await _connectivitySub?.cancel();
      _connectivitySub = null;
      flushPendingHandler = null;
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
      if (scheduledFrequency == null) return;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        try {
          final freq = scheduledFrequency;
          if (freq == null) return;
          final scheduled = scheduledAt ?? DateTime.now();
          final next = scheduled.add(freq);
          final rem = next.difference(DateTime.now());

          if (rem.inMilliseconds <= 0) {
            try {
              lastLogListenable.value =
                  'next scheduled run now; triggering flush and resetting countdown';
            } catch (_) {}
            try {
              lastLogListenable.value =
                  'countdown-trigger: calling flushPendingSubmissions()';
            } catch (_) {}

            var success = false;
            try {
              if (flushPendingHandler != null) {
                await flushPendingHandler!();
                success = true;
              } else {
                success = await FlushApi.flushPendingSubmissions();
              }
            } catch (e, st) {
              try {
                lastLogListenable.value =
                    'countdown-triggered flush threw: $e\n$st';
              } catch (_) {}
            }

            try {
              lastLogListenable.value =
                  'countdown-triggered flush: ${success ? 'success' : 'failure'}';
            } catch (_) {}

            try {
              final err = await runOnceNowDetailed(taskName: 'dbg_countdown');
              try {
                lastLogListenable.value =
                    'scheduled one-off dbg_countdown -> ${err ?? 'ok'}';
              } catch (_) {}
            } catch (e, st) {
              try {
                lastLogListenable.value =
                    'failed scheduling dbg_countdown: $e\n$st';
              } catch (_) {}
            }

            scheduledAt = DateTime.now();
            try {
              countdownListenable.value = null;
            } catch (_) {}
            return;
          }

          final mm = rem.inMinutes.remainder(60).toString().padLeft(2, '0');
          final ss = rem.inSeconds.remainder(60).toString().padLeft(2, '0');
          try {
            countdownListenable.value = '$mm:$ss';
          } catch (_) {}
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

  /// Convenience: return an estimated next run time based on when the task
  /// was scheduled and the configured periodic frequency. Returns null when
  /// no estimate is available.
  DateTime? get nextEstimatedRun {
    try {
      if (scheduledAt == null || scheduledFrequency == null) return null;
      return scheduledAt!.add(scheduledFrequency!);
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

  /// Call this to notify listeners that pending items changed.
  void notifyPendingChanged() {
    try {
      pendingChangedListenable.value = pendingChangedListenable.value + 1;
    } catch (_) {}
  }

  /// Public accessor for recent logs (oldest -> newest).
  List<String> get recentLogs => List.unmodifiable(_logs);

  /// Clear recent logs and notify listeners.
  void clearLogs() {
    try {
      _logs.clear();
      _suppressListener = true;
      lastLogListenable.value = null;
      _suppressListener = false;
    } catch (_) {}
  }

  /// A lightweight helper to check whether Workmanager has been initialized.
  bool get isInitialized => _initialized;

  /// The callback dispatcher used by the `workmanager` plugin. This must be
  /// a top-level or static function reference as required by the plugin.
  static void _callbackDispatcher() {
    WidgetsFlutterBinding.ensureInitialized();

    Workmanager().executeTask((task, inputData) async {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Workmanager executeTask: $task, inputData: $inputData');
      }

      // Update last run timestamp and notify listeners in the UI isolate
      // via platform channels isn't possible here; we update a simple
      // timestamp variable for the isolate that invoked this code path.
      try {
        // First, attempt to find a callback handle provided in the task's
        // inputData. Hosts can schedule tasks with a `callback_handle`
        // entry (raw handle) so background isolates can resolve the
        // original top-level function via PluginUtilities.
        if (inputData != null && inputData['callback_handle'] != null) {
          try {
            final raw = inputData['callback_handle'];
            final rawHandle = raw is int ? raw : int.parse(raw.toString());
            final cbHandle = CallbackHandle.fromRawHandle(rawHandle);
            // Log resolution attempt
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
              final res = await cb(task, inputData);
              return Future.value(res);
            }
          } catch (e) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('failed to resolve callback_handle: $e');
            }
          }
        }

        // Fallback: attempt to use the static background handler if set
        // in this isolate (may be null in background isolates).
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
}
