import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

part 'workmanager_service_parts/countdown.dart';
part 'workmanager_service_parts/logging.dart';
part 'workmanager_service_parts/lifecycle.dart';
part 'workmanager_service_parts/registration.dart';
part 'workmanager_service_parts/connectivity.dart';

final _log = Logger('WorkmanagerService');

// Flush state relocated into WorkmanagerService as `isFlushing`.

/// Thin wrapper around the `workmanager` plugin that provides a small,
/// testable surface for the example app. Includes per-task scheduling
/// metadata and a `perTaskCountdownListenable` so the UI can show
/// countdowns for each registered worker.
/// Shortest periodic interval Android WorkManager honours. Shorter requests
/// are silently raised to this value by the OS.
const Duration kAndroidMinPeriodicInterval = Duration(minutes: 15);

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
  AppLifecycleListener? _lifecycleListener;

  /// Host-provided top-level background handler resolver (optional).
  static BackgroundTaskHandler? _backgroundHandler;

  /// Shared flush guard moved here so callers can check `WorkmanagerService.isFlushing`.
  static bool isFlushing = false;

  /// Timestamp when the shared flush guard was acquired. Used to detect
  /// and recover from stale guards that may be left set if an isolate
  /// crashed while holding the guard.
  static DateTime? _flushGuardSetAt;
  static bool _inCountdownInvocation = false;

  /// Whether the countdown code is currently invoking registered handlers.
  static bool get isInCountdownInvocation => _inCountdownInvocation;

  /// Public accessor for debugging: when the flush guard was set (or null).
  static DateTime? get flushGuardSetAt => _flushGuardSetAt;

  /// Try to acquire the shared flush guard.
  /// Returns `true` when this caller successfully acquired the guard
  /// (the caller must call `releaseFlushGuard()` when finished).
  /// If `skip` is true the guard is not acquired and the function returns
  /// `false` to indicate the caller did not set the guard (caller should
  /// treat `skip` as bypassing the guard semantics).
  static bool acquireFlushGuard({bool skip = false}) {
    if (skip) return false;
    if (isFlushing) {
      // The guard is never taken over while it is held. Every caller releases
      // it in `finally`, and a crashed isolate takes its statics with it. A
      // flush that is still running after a long time (slow network, many
      // rows) is a live flush, and a second one would upload the same rows
      // again. A long hold is only reported.
      try {
        final setAt = _flushGuardSetAt;
        if (setAt != null) {
          final age = DateTime.now().difference(setAt);
          if (age > const Duration(minutes: 5)) {
            _log.warning(
              'acquireFlushGuard: flush has held the guard for ${age.inMinutes}m',
            );
          }
        }
      } catch (_) {}
      return false;
    }
    isFlushing = true;
    _flushGuardSetAt = DateTime.now();
    return true;
  }

  /// Release the shared flush guard. Safe to call even if the guard is not set.
  static void releaseFlushGuard() {
    isFlushing = false;
    _flushGuardSetAt = null;
  }

  /// Optional handler the host registers to perform a foreground flush.
  Future<void> Function()? foregroundFlushHandler;

  /// Per-task foreground flush handlers (registered by task name).
  final Map<String, Future<void> Function()> _perTaskForegroundHandlers = {};

  /// Per-task background handlers (registered by task name).
  final Map<String, BackgroundTaskHandler> _perTaskBackgroundHandlers = {};

  /// Register a foreground handler for a specific task name.
  void setForegroundHandlerForTask(
    String taskName,
    Future<void> Function()? handler,
  ) {
    try {
      if (handler == null) {
        _perTaskForegroundHandlers.remove(taskName);
      } else {
        _perTaskForegroundHandlers[taskName] = handler;
      }
    } catch (_) {}
  }

  /// Register a top-level background handler for a specific task name.
  /// This allows the service to embed the handler's callback handle when
  /// scheduling work for that task (so background isolates can resolve
  /// the correct entrypoint).
  void setBackgroundHandlerForTask(
    String taskName,
    BackgroundTaskHandler? handler,
  ) {
    try {
      if (handler == null) {
        _perTaskBackgroundHandlers.remove(taskName);
      } else {
        _perTaskBackgroundHandlers[taskName] = handler;
      }
    } catch (_) {}
  }

  /// Convenience: schedule all provided worker definitions.
  /// For each provided definition this will call `start(...)` and,
  /// if `triggerNow` is true, attempt to invoke a foreground handler
  /// or request a one-off background run to trigger the registered
  /// background handler.
  Future<void> startAll({bool triggerNow = true}) =>
      _startAll(triggerNow: triggerNow);

  /// Start a single worker by its registered name using the provided
  /// worker definitions. If the worker definition isn't found this will
  /// no-op and log a message. If `triggerNow` is true the method will
  /// attempt to invoke a foreground handler (if registered) or request
  /// a one-off background run to trigger the background handler.
  Future<void> startWorkerByName(String name, {bool triggerNow = true}) =>
      _startWorkerByName(name, triggerNow: triggerNow);

  /// Ensure the countdown timer is running if any tasks are registered.
  void ensureCountdownActive() {
    try {
      if (_registeredTasks.isNotEmpty) _startCountdownTimer();
    } catch (_) {}
  }

  /// Stop a single worker by its unique name. This calls into the
  /// existing `stop(...)` API with `taskName` set so the same cancellation
  /// logic and bookkeeping is used.
  Future<void> stopWorkerByName(String name) => _stopWorkerByName(name);

  /// Return the countdown display string for a specific task name.
  /// Matches the display format used by the internal countdown timer
  /// (`perTaskCountdownListenable`). Returns `null` when no countdown
  /// is available for the given task (not scheduled or missing metadata).
  String? getCountdownForTask(String name) => _getCountdownForTask(name);

  static const String _defaultTaskName = 'form_fields_background_task';

  /// Helper for legacy example usage.
  static void setBackgroundTaskHandler(BackgroundTaskHandler handler) {
    _backgroundHandler = handler;
  }

  /// Initialize the workmanager plugin and optionally the connectivity listener.
  Future<void> initialize({
    void Function()? callbackDispatcher,
    bool useConnectivity = true,
  }) => _initialize(
    callbackDispatcher: callbackDispatcher,
    useConnectivity: useConnectivity,
  );

  /// Stops the connectivity listener started by [startConnectivityFlush].
  Future<void> stopConnectivityFlush() async {
    final sub = _connectivitySub;
    _connectivitySub = null;
    await sub?.cancel();
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }

  /// Whether the connectivity listener is running. Tests only.
  @visibleForTesting
  bool get isConnectivityFlushActive => _connectivitySub != null;

  /// Runs [foregroundFlushHandler] when the device has a network connection
  /// again, and when the app returns to the foreground. Only the running app
  /// can react, so this does not replace background workers for when the app
  /// is closed. Safe to call repeatedly; it starts listening once.
  void startConnectivityFlush() => _startConnectivityFlush();

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
  }) => _start(
    taskName: taskName,
    frequency: frequency,
    periodic: periodic,
    inputData: inputData,
    initialDelay: initialDelay,
  );

  /// Schedules a one-off background run that starts after [delay]. Unlike an
  /// in-app timer, it still runs while the app is in the background. Calling
  /// it again with the same [uniqueName] replaces the pending run.
  Future<void> scheduleOneOff({
    required String uniqueName,
    Duration delay = Duration.zero,
    Map<String, dynamic>? inputData,
  }) => _scheduleOneOff(
    uniqueName: uniqueName,
    delay: delay,
    inputData: inputData,
  );

  /// Cancels a run scheduled with [scheduleOneOff].
  Future<void> cancelOneOff(String uniqueName) => _cancelOneOff(uniqueName);

  /// Run a one-off task immediately.
  Future<String?> runOnceNowDetailed({
    String? taskName,
    Map<String, dynamic>? inputData,
  }) => _runOnceNowDetailed(taskName: taskName, inputData: inputData);

  /// Stop a specific task, or all tasks when [taskName] is null.
  ///
  /// This cancels only scheduled workers. The connectivity flush and
  /// [foregroundFlushHandler] are left running (see [stopConnectivityFlush]).
  Future<void> stop({VoidCallback? onStop, String? taskName}) =>
      _stop(onStop: onStop, taskName: taskName);

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

  void notifyPendingChanged() {
    try {
      pendingChangedListenable.value = pendingChangedListenable.value + 1;
    } catch (_) {}
  }

  /// When true (the default), [notifyPendingAdded] also runs the foreground
  /// flush right away if the device is online. Set it to false when pending
  /// rows must stay local until a worker run or an explicit send.
  bool flushOnPendingAdded = true;

  /// Call after inserting a new pending submission. Notifies listeners and,
  /// when [flushOnPendingAdded] is true and the device is online, runs the
  /// foreground flush right away.
  ///
  /// Do not use this after a successful send: it would start another flush.
  /// Use [notifyPendingChanged] for that.
  void notifyPendingAdded() {
    notifyPendingChanged();
    if (flushOnPendingAdded) unawaited(_flushIfOnline('pending added'));
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
  void setProvidedWorkerDefinitions(List<Map<String, dynamic>> defs) =>
      _setProvidedWorkerDefinitions(defs);

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
    // WidgetsFlutterBinding.ensureInitialized();

    Workmanager().executeTask((task, inputData) async {
      if (kDebugMode) {
        print('Workmanager executeTask: $task, inputData: $inputData');
      }

      try {
        if (inputData != null && inputData['callback_handle'] != null) {
          // Resolving the handle may fail. Running the handler may fail too.
          // Only a failed resolution falls through to the global handler. A
          // handler that ran and threw reports failure. Falling through would
          // run the same work a second time.
          BackgroundTaskHandler? handler;
          try {
            final raw = inputData['callback_handle'];
            final rawHandle = raw is int ? raw : int.parse(raw.toString());
            final cbHandle = CallbackHandle.fromRawHandle(rawHandle);
            if (kDebugMode) {
              print('Attempting to resolve callback handle: $rawHandle');
            }
            final cb = PluginUtilities.getCallbackFromHandle(cbHandle);
            if (kDebugMode) {
              print('Resolved callback: $cb');
            }
            if (cb is BackgroundTaskHandler) {
              handler = cb;
            } else {
              if (kDebugMode) {
                print(
                  'Callback resolved but is not BackgroundTaskHandler: $cb',
                );
              }
              // A usable callback was not found, so the task is not done.
              return false;
            }
          } catch (e) {
            if (kDebugMode) {
              print('failed to resolve callback_handle: $e');
            }
          }
          if (handler != null) {
            try {
              final res = await handler(task, inputData);
              return res;
            } catch (e) {
              if (kDebugMode) {
                print('per-task background handler threw: $e');
              }
              return false;
            }
          }
        }

        if (_backgroundHandler != null) {
          try {
            if (kDebugMode) {
              print(
                'Using static _backgroundHandler fallback: $_backgroundHandler',
              );
            }
            final res = await _backgroundHandler!(task, inputData);
            return await Future.value(res);
          } catch (e) {
            if (kDebugMode) {
              print('background handler threw: $e');
            }
            return await Future.value(false);
          }
        }
      } catch (_) {}

      // No handler could run. Report failure instead of success, so the task
      // is not recorded as done when no work was performed.
      if (kDebugMode) {
        print(
          'Workmanager executeTask: no handler for $task; reporting failure',
        );
      }
      return Future.value(false);
    });
  }
}

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() =>
    WorkmanagerService._callbackDispatcher();
