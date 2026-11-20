part of '../map_controller.dart';

/// Registry of map controllers, notifiers, loading flags and marker-tap handlers
/// for [FormFieldsMapController]. Internal; the public API delegates here.
class _MapRegistry {
  // When performing large batch mutations (set/append raw markers), present
  // a blocking overlay automatically if the mutation size meets or exceeds
  // this threshold. Matches the example's batching size.
  static const int _autoBlockingThreshold = 512;

  static final Map<String, MapController> _controllers = {};
  // Registered notifiers per controller id. Widgets must register their
  // `FormFieldsMapNotifier` instance so the controller can perform
  // mutations on the notifier on behalf of external callers.
  static final Map<String, FormFieldsMapNotifier> _notifiers = {};
  // Reverse mapping from notifier instance to id to help callers (examples)
  // discover the registry id when they hold a notifier reference.
  static final Map<FormFieldsMapNotifier, String> _notifierToId = {};
  // Transient retry counts for _MapRawMarkerOps.appendRawMarkers when map camera isn't ready.
  static final Map<String, int> _appendRetryCounts = {};
  static const int _maxAppendRetries = 40;
  // Timers used to debounce clearing the blocking overlay so rapid
  // sequential batch appends don't cause the overlay to flicker.
  static final Map<String, Timer?> _blockingClearTimers = {};

  // Optional ValueNotifiers to represent loading state per controller id.
  static final Map<String, ValueNotifier<bool>> _loadingNotifiers = {};
  // Separate notifiers for full-screen (blocking) loading used for
  // data fetch operations where the UI should be modal and interaction
  // must be prevented.
  static final Map<String, ValueNotifier<bool>> _blockingLoadingNotifiers = {};
  // Optional global handlers for marker taps keyed by controller id. This
  // allows external marker widgets to invoke the map-level `onMarkerTap`
  // callback by calling `invokeOnMarkerTap` with the controller id.
  static final Map<String, ValueChanged<ShapeMeta>?> _onMarkerTapHandlers = {};
  // Timestamp of last invoke per controller id to suppress rapid duplicate
  static final Map<String, DateTime?> _lastInvokeAt = {};

  /// Register an external or pre-created [controller] under [id]. This
  /// allows consumers that provide their own `MapController` to expose it
  /// through the shared registry so other widgets or callers can access
  /// the same controller instance via the registry APIs.
  static void registerController(String id, MapController controller) {
    // Ensure a controller instance is only stored under a single id.
    // If the same controller was previously registered under a different
    // id, FormFieldsMapController.remove that old entry to avoid duplicate ids pointing to the
    // same controller (which can cause lookup mismatches).
    final toRemove = <String>[];
    for (final e in _controllers.entries) {
      if (identical(e.value, controller) && e.key != id) {
        toRemove.add(e.key);
      }
    }
    for (final k in toRemove) {
      // Migrate any per-id registrations from the old id to the new id
      // so callers that registered early (e.g., via getIdForController())
      // don't become disconnected when the widget later registers a
      // stable controller id.
      try {
        // Move notifier registration
        final oldNotifier = _notifiers.remove(k);
        if (oldNotifier != null && !_notifiers.containsKey(id)) {
          _notifiers[id] = oldNotifier;
          _notifierToId[oldNotifier] = id;
          try {
            oldNotifier.attachController(id);
          } catch (_) {}
        }
      } catch (_) {}
      try {
        if (_loadingNotifiers.containsKey(k) &&
            !_loadingNotifiers.containsKey(id)) {
          _loadingNotifiers[id] = _loadingNotifiers.remove(k)!;
        }
      } catch (_) {}
      try {
        if (_blockingLoadingNotifiers.containsKey(k) &&
            !_blockingLoadingNotifiers.containsKey(id)) {
          _blockingLoadingNotifiers[id] = _blockingLoadingNotifiers.remove(k)!;
        }
      } catch (_) {}
      try {
        if (_onMarkerTapHandlers.containsKey(k) &&
            !_onMarkerTapHandlers.containsKey(id)) {
          _onMarkerTapHandlers[id] = _onMarkerTapHandlers.remove(k)!;
        }
      } catch (_) {}
      try {
        if (_MapPlaybackOps._playbackHandlers.containsKey(k) &&
            !_MapPlaybackOps._playbackHandlers.containsKey(id)) {
          _MapPlaybackOps._playbackHandlers[id] = _MapPlaybackOps
              ._playbackHandlers
              .remove(k)!;
        }
      } catch (_) {}
      try {
        if (_MapPlaybackOps._playbackPlayingNotifiers.containsKey(k) &&
            !_MapPlaybackOps._playbackPlayingNotifiers.containsKey(id)) {
          _MapPlaybackOps._playbackPlayingNotifiers[id] = _MapPlaybackOps
              ._playbackPlayingNotifiers
              .remove(k)!;
        }
      } catch (_) {}
      _controllers.remove(k);
    }
    _controllers[id] = controller;
  }

  /// Convenience helper that registers a controller under the stable
  /// `ff_controller_<hash>` id and optionally registers a `FormFieldsMapNotifier`
  /// for the same id. This simplifies consumer code by ensuring both the
  /// controller and notifier are registered under the same stable id that
  /// `FormFieldsMap` widgets use.
  static String registerControllerAndNotifier(
    MapController controller,
    FormFieldsMapNotifier? notifier,
  ) {
    final id = 'ff_controller_${controller.hashCode}';
    registerController(id, controller);
    if (notifier != null) {
      registerNotifier(id, notifier);
    }
    return id;
  }

  /// Returns an existing controller for [id], or creates one if missing.
  static MapController getOrCreate(String id) {
    return _controllers.putIfAbsent(id, () => MapController());
  }

  /// Register a `FormFieldsMapNotifier` instance for the controller id.
  static void registerNotifier(String id, FormFieldsMapNotifier notifier) {
    final existing = _notifiers[id];
    if (identical(existing, notifier)) {
      // Already registered the same notifier under this id; avoid
      // re-attaching or logging repeatedly.
      return;
    }
    _notifiers[id] = notifier;
    _notifierToId[notifier] = id;
    try {
      notifier.attachController(id);
    } catch (_) {}
    try {
      debugLog(
        '[FormFieldsMapController] registerNotifier id=$id notifier=${notifier.hashCode}',
      );
    } catch (_) {}
  }

  /// Remove a previously registered notifier for [id]. Called on widget
  /// dispose to avoid leaks.
  static void removeNotifier(String id) {
    final n = _notifiers.remove(id);
    if (n != null) {
      _notifierToId.remove(n);
      try {
        n.attachController(null);
      } catch (_) {}
      try {
        debugLog(
          '[FormFieldsMapController] removeNotifier id=$id notifier=${n.hashCode}',
        );
      } catch (_) {}
    }
  }

  /// Helper to safely get a notifier for [id]. Returns null when not
  /// registered.
  static FormFieldsMapNotifier? _getNotifier(String id) {
    return _notifiers[id];
  }

  /// Public accessor for the registered `FormFieldsMapNotifier` for [id].
  /// Returns `null` when no notifier is registered. This is a thin
  /// wrapper around the internal `_getNotifier` helper to allow callers
  /// that need direct access to the notifier (e.g. widgets using
  /// `ChangeNotifierProvider.value`) to obtain it safely.
  static FormFieldsMapNotifier? getNotifier(String id) {
    return _getNotifier(id);
  }

  /// Return a copy of the notifier's `rawMarkers` list for [id], or an
  /// empty list when no notifier is registered. This is a safe read-only
  /// accessor for external callers.
  static List<dynamic> getRawMarkers(String id) {
    final n = _getNotifier(id);
    if (n == null) return const [];
    try {
      return List<dynamic>.from(n.rawMarkers);
    } catch (_) {
      return List<dynamic>.from(n.rawMarkers);
    }
  }

  /// Return the registry id associated with a `FormFieldsMapNotifier`. If
  /// the notifier is not yet registered, a new id is created and the
  /// notifier is registered under it. This is primarily a helper for
  /// examples and code that holds a notifier instance and needs the
  /// corresponding registry id used by the map widget.
  static String getIdForNotifier(FormFieldsMapNotifier notifier) {
    final existing = _notifierToId[notifier];
    if (existing != null) return existing;
    final id =
        'ff_notifier_${DateTime.now().microsecondsSinceEpoch}_${_notifiers.length}';
    registerNotifier(id, notifier);
    return id;
  }

  /// Return the registry id associated with [controller], creating a new
  /// registry entry if the controller is not yet known. This allows callers
  /// that hold a `MapController` instance to obtain a stable string id for
  /// use with other registry APIs.
  static String getIdForController(MapController controller) {
    for (final e in _controllers.entries) {
      if (identical(e.value, controller)) return e.key;
    }
    final id =
        'auto_${DateTime.now().microsecondsSinceEpoch}_${_controllers.length}';
    _controllers[id] = controller;
    try {
      debugLog(
        '[FormFieldsMapController] getIdForController created id=$id controller=${controller.hashCode}',
      );
    } catch (_) {}
    return id;
  }

  /// Returns a `ValueListenable<bool>` representing the loading state for
  /// the controller with [id]. The notifier is created on demand and shared
  /// so callers can observe or set loading state across widgets and viewmodels.
  static ValueListenable<bool> getLoadingListenable(String id) {
    return _loadingNotifiers.putIfAbsent(id, () => ValueNotifier<bool>(false));
  }

  /// Convenience setter to change the loading value for [id].
  static void setLoading(String id, bool value) {
    final notifier = _loadingNotifiers.putIfAbsent(
      id,
      () => ValueNotifier<bool>(false),
    );
    try {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.idle) {
        notifier.value = value;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            notifier.value = value;
          } catch (_) {}
        });
      }
    } catch (_) {
      try {
        notifier.value = value;
      } catch (_) {}
    }
  }

  /// Setter for blocking loading state for [id]. Use this when you need
  /// to present a full-screen blocking overlay (e.g., while fetching data).
  static void setBlockingLoading(String id, bool value) {
    final notifier = _blockingLoadingNotifiers.putIfAbsent(
      id,
      () => ValueNotifier<bool>(false),
    );
    try {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.idle) {
        notifier.value = value;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            notifier.value = value;
          } catch (_) {}
        });
      }
    } catch (_) {
      try {
        notifier.value = value;
      } catch (_) {}
    }
  }

  /// Returns a `ValueListenable<bool>` representing a blocking loading
  /// state for the controller with [id]. This is intended for long-running
  /// data loads where the map UI should be modal/blocked (full-screen
  /// overlay). Notifier is created on demand.
  static ValueListenable<bool> getBlockingLoadingListenable(String id) {
    return _blockingLoadingNotifiers.putIfAbsent(
      id,
      () => ValueNotifier<bool>(false),
    );
  }

  /// Register a handler to be invoked when a marker is tapped. The map
  /// widget will call this during init and update, and it will be removed
  /// when the widget disposes.
  static void registerOnMarkerTap(String id, ValueChanged<ShapeMeta>? handler) {
    _onMarkerTapHandlers[id] = handler;
    if (handler == null) {
      // allow explicit unregistering
    } else {
      // registering handler (silent)
    }
  }

  /// Invoke the registered `onMarkerTap` handler (if any) for [id]. This
  /// is safe to call from anywhere (e.g., marker widget tap callbacks).
  static void invokeOnMarkerTap(String id, ShapeMeta payload) {
    final handler = _onMarkerTapHandlers[id];
    if (handler == null) {
      return;
    }

    // suppress duplicate invocations within a short window
    final now = DateTime.now();
    final last = _lastInvokeAt[id];
    const window = Duration(milliseconds: 500);
    if (last != null && now.difference(last) <= window) {
      return;
    }

    _lastInvokeAt[id] = now;
    try {
      handler.call(payload);
    } catch (_) {
      // swallow errors from handlers to avoid affecting map internals
    }
  }

  /// Remove any registered onMarkerTap handler for [id].
  static void removeOnMarkerTap(String id) {
    _onMarkerTapHandlers.remove(id);
  }

  // Toggle to enable verbose batch logging. Default off for performance.
  static bool enableBatchLogging = false;
}
