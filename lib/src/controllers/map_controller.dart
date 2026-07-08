import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';

/// A persistent controller provider for `MapController` instances.
/// Controllers are keyed by an `id` so they are not recreated on widget rebuilds.
class FormFieldsMapController {
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
  // Transient retry counts for appendRawMarkers when map camera isn't ready.
  static final Map<String, int> _appendRetryCounts = {};
  static const int _maxAppendRetries = 40;
  // Timers used to debounce clearing the blocking overlay so rapid
  // sequential batch appends don't cause the overlay to flicker.
  static final Map<String, Timer?> _blockingClearTimers = {};

  /// Register an external or pre-created [controller] under [id]. This
  /// allows consumers that provide their own `MapController` to expose it
  /// through the shared registry so other widgets or callers can access
  /// the same controller instance via the registry APIs.
  static void registerController(String id, MapController controller) {
    // Ensure a controller instance is only stored under a single id.
    // If the same controller was previously registered under a different
    // id, remove that old entry to avoid duplicate ids pointing to the
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
        if (_playbackHandlers.containsKey(k) &&
            !_playbackHandlers.containsKey(id)) {
          _playbackHandlers[id] = _playbackHandlers.remove(k)!;
        }
      } catch (_) {}
      try {
        if (_playbackPlayingNotifiers.containsKey(k) &&
            !_playbackPlayingNotifiers.containsKey(id)) {
          _playbackPlayingNotifiers[id] = _playbackPlayingNotifiers.remove(k)!;
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
      MapController controller, FormFieldsMapNotifier? notifier) {
    final id = 'ff_controller_${controller.hashCode}';
    registerController(id, controller);
    if (notifier != null) {
      registerNotifier(id, notifier);
    }
    return id;
  }

  // Optional ValueNotifiers to represent loading state per controller id.
  static final Map<String, ValueNotifier<bool>> _loadingNotifiers = {};
  // Separate notifiers for full-screen (blocking) loading used for
  // data fetch operations where the UI should be modal and interaction
  // must be prevented.
  static final Map<String, ValueNotifier<bool>> _blockingLoadingNotifiers = {};
  // Toggle to enable verbose batch logging. Default off for performance.
  static bool enableBatchLogging = false;
  // Optional global handlers for marker taps keyed by controller id. This
  // allows external marker widgets to invoke the map-level `onMarkerTap`
  // callback by calling `invokeOnMarkerTap` with the controller id.
  static final Map<String, ValueChanged<ShapeMeta>?> _onMarkerTapHandlers = {};
  // Timestamp of last invoke per controller id to suppress rapid duplicate
  static final Map<String, DateTime?> _lastInvokeAt = {};

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
      debugPrint(
          '[FormFieldsMapController] registerNotifier id=$id notifier=${notifier.hashCode}');
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
        debugPrint(
            '[FormFieldsMapController] removeNotifier id=$id notifier=${n.hashCode}');
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
      debugPrint(
          '[FormFieldsMapController] getIdForController created id=$id controller=${controller.hashCode}');
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
    final notifier =
        _loadingNotifiers.putIfAbsent(id, () => ValueNotifier<bool>(false));
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
        id, () => ValueNotifier<bool>(false));
  }

  /// Setter for blocking loading state for [id]. Use this when you need
  /// to present a full-screen blocking overlay (e.g., while fetching data).
  static void setBlockingLoading(String id, bool value) {
    final notifier = _blockingLoadingNotifiers.putIfAbsent(
        id, () => ValueNotifier<bool>(false));
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

  // --- Notifier mutation helpers ---
  /// Replace the notifier's `rawMarkers` list for [id]. No-op when no
  /// notifier is registered for [id].
  static void setRawMarkers(String id, List<dynamic> coords) {
    var n = _getNotifier(id);
    // Ensure a notifier exists so controller-only callers don't silently
    // fail to update raw markers (playback relies on this).
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return;
    try {
      final shouldBlock = coords.length >= _autoBlockingThreshold;
      if (shouldBlock) {
        try {
          setBlockingLoading(id, true);
        } catch (_) {}
      }

      // Rebuild rawMarkers and derived layer maps so `flutter_map` layers
      // (polygons/polylines/circles/markers) stay in sync with `rawMarkers`.
      try {
        // Clear existing rawMarkers and concrete layer maps first.
        n.clearRawMarkers();
        try {
          n.clearPolygons();
        } catch (_) {}
        try {
          n.clearPolylines();
        } catch (_) {}
        try {
          n.clearCircles();
        } catch (_) {}
        try {
          n.clearMarkers();
        } catch (_) {}
      } catch (_) {}

      // Use notifier.appendRawMarkers which will append the provided coords
      // and auto-register ShapeMeta entries into the concrete layer maps.
      try {
        n.appendRawMarkers(List<dynamic>.from(coords));
      } catch (_) {
        // Fallback: if appendRawMarkers fails, ensure rawMarkers is set so
        // the painter still sees the updated titles/positions.
        try {
          n.rawMarkers = List<dynamic>.from(coords);
        } catch (_) {}
      }

      if (shouldBlock) {
        try {
          setBlockingLoading(id, false);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<bool> appendRawMarkers(String id, List<dynamic> coords,
      {bool createMarkerWidgets = true}) async {
    var n = _getNotifier(id);
    // Ensure a notifier exists so UI widgets can observe updates even when
    // callers only hold a `MapController` reference.
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return false;

    // If the map/controller isn't ready yet (camera center unavailable),
    // schedule a short retry instead of mutating immediately. This fixes
    // the issue where markers are appended before the map has initialized
    // and thus are not displayed until the user interacts with the map.
    final center = getCenter(id);
    if (center == null) {
      final attempts = (_appendRetryCounts[id] ?? 0) + 1;
      if (attempts > _maxAppendRetries) {
        try {
          if (enableBatchLogging) {
            debugPrint(
                '[FormFieldsMapController] appendRawMarkers id=$id aborted after $attempts attempts (map not ready)');
          }
        } catch (_) {}
        _appendRetryCounts.remove(id);
        return false;
      }
      _appendRetryCounts[id] = attempts;
      await Future.delayed(const Duration(milliseconds: 100));
      return await appendRawMarkers(id, coords);
    }

    // Reset retry count on success path.
    _appendRetryCounts.remove(id);

    // Detect whether this is the first append for this controller so we
    // can initialize playback UI state if a playback handler was
    // registered. Capture current emptiness now (before mutation).
    final bool wasRawMarkersEmptyBeforeAppend = (n.rawMarkers.isEmpty);

    // Decide whether this append should present the full-screen blocking
    // overlay. We only do this for larger batches to avoid blocking UI
    // for tiny updates.
    final shouldBlock = coords.length >= _autoBlockingThreshold;

    try {
      if (shouldBlock) {
        // Cancel any pending clear timers (another batch is ongoing)
        try {
          _blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          setBlockingLoading(id, true);
        } catch (_) {}
        // Give one frame for the overlay to render.
        try {
          await Future.delayed(Duration.zero);
        } catch (_) {}
      }

      n.appendRawMarkers(coords, createMarkerWidgets: createMarkerWidgets);
      // If this was the first append (no markers previously) and a
      // playback handler is registered for this controller id, reset
      // the playback playing notifier so built-in controls show a
      // predictable initial state (not playing).
      try {
        if (wasRawMarkersEmptyBeforeAppend &&
            coords.isNotEmpty &&
            _playbackHandlers.containsKey(id) &&
            getPlaybackAutoStart(id)) {
          // Auto-start playback when the first raw markers are appended
          // and playback support is enabled for this controller. Use the
          // public helper so any registered handler is invoked to start
          // the playback flow (which will also set up timers and markers).
          try {
            setPlaybackPlaying(id, true);
          } catch (_) {}
          try {
            startPolylinePlayback(id, null);
          } catch (_) {}
        }
      } catch (_) {}
      try {
        if (enableBatchLogging) {
          debugPrint(
              '[FormFieldsMapController] appendRawMarkers id=$id notifier=${n.hashCode} appended=${coords.length} total=${n.rawMarkers.length}');
        }
      } catch (_) {}
      return true;
    } finally {
      if (shouldBlock) {
        // Debounce clearing the overlay so closely spaced batches don't
        // cause flicker. If another batch arrives it will cancel this
        // timer and keep the overlay visible.
        try {
          _blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _blockingClearTimers[id] =
              Timer(const Duration(milliseconds: 200), () {
            try {
              setBlockingLoading(id, false);
            } catch (_) {}
            _blockingClearTimers.remove(id);
          });
        } catch (_) {}
      }
    }
  }

  static void clearRawMarkers(String id) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.clearRawMarkers();
    } catch (_) {}
  }

  /// Update a single raw marker by `markerId` for the controller `id`.
  ///
  /// This performs a targeted update without replacing the entire
  /// `rawMarkers` list. It removes any existing derived layer entries
  /// for the marker id (polygon/polyline/circle/marker), replaces the
  /// raw marker, and then re-appends the new entry so derived maps are
  /// re-registered. Returns `true` when an update occurred.
  static bool updateRawMarker(String id, String markerId, dynamic entry) {
    final n = _getNotifier(id);
    if (n == null) return false;
    try {
      // Remove any concrete layer entries with this id so the new
      // entry can re-register cleanly.
      try {
        n.removePolygon(markerId);
      } catch (_) {}
      try {
        n.removePolyline(markerId);
      } catch (_) {}
      try {
        n.removeCircle(markerId);
      } catch (_) {}
      try {
        n.removeMarker(markerId);
      } catch (_) {}

      // Remove raw marker (if present)
      try {
        n.removeRawMarker(markerId);
      } catch (_) {}

      // Append the replacement entry (ShapeMeta or Map) so it is
      // registered into rawMarkers and any derived maps.
      try {
        n.appendRawMarkers([entry]);
      } catch (_) {
        try {
          // Fallback: directly set rawMarkers to include the entry.
          final combined = List<dynamic>.from(n.rawMarkers)..add(entry);
          n.rawMarkers = combined;
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Efficiently apply many coordinate-only updates for [id]. Each update
  /// should be a Map with `id` and `pointMetas` (serializable List of maps)
  /// or `lat`/`lon` for single-point markers. Returns true when applied.
  static bool batchUpdateCoordinates(
      String id, List<Map<String, dynamic>> updates,
      {bool createMarkerWidgets = true, bool useInPlaceMutation = true}) {
    var n = _getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return false;

    final shouldBlock = updates.length >= _autoBlockingThreshold;
    try {
      if (shouldBlock) {
        try {
          _blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          setBlockingLoading(id, true);
        } catch (_) {}
        try {
          // give frame for overlay
          Future.delayed(Duration.zero);
        } catch (_) {}
      }

      try {
        n.batchUpdateCoordinates(updates,
            createMarkerWidgets: createMarkerWidgets,
            useInPlaceMutation: useInPlaceMutation);
      } catch (_) {
        // Fallback: apply per-item via updateRawMarkerCoordinates or upsert
        for (final u in updates) {
          try {
            final idv = (u['id'] as String?) ?? '';
            if (idv.isEmpty) continue;
            if (u['pointMetas'] is List) {
              final pms = (u['pointMetas'] as List)
                  .map((pm) => PointMeta(
                      lat: (pm['lat'] as num).toDouble(),
                      lon: (pm['lon'] as num).toDouble()))
                  .toList(growable: false);
              n.upsertCoordinates(idv, pms,
                  createMarkerWidgets: createMarkerWidgets);
            } else if (u.containsKey('lat') && u.containsKey('lon')) {
              // convert to single-point ShapeMeta and upsert
              final p = PointMeta(
                  lat: (u['lat'] as num).toDouble(),
                  lon: (u['lon'] as num).toDouble());
              n.upsertCoordinates(idv, [p],
                  createMarkerWidgets: createMarkerWidgets);
            }
          } catch (_) {}
        }
      }

      return true;
    } finally {
      if (shouldBlock) {
        try {
          _blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _blockingClearTimers[id] =
              Timer(const Duration(milliseconds: 200), () {
            try {
              setBlockingLoading(id, false);
            } catch (_) {}
            _blockingClearTimers.remove(id);
          });
        } catch (_) {}
      }
    }
  }

  /// High-level helper: accept a list of `ShapeMeta` and perform inserts
  /// or updates automatically. Consumers can call this with full
  /// `ShapeMeta` objects and the controller will decide whether to append
  /// new entries or patch existing ones (using `batchUpdateCoordinates`).
  /// Returns true when the operation was attempted.
  static Future<bool> processShapeMetaList(String id, List<ShapeMeta> shapes,
      {bool createMarkerWidgets = true, bool useInPlaceMutation = true}) async {
    if (shapes.isEmpty) return true;

    // Snapshot existing ids for this controller so we can partition
    // incoming shapes into updates vs appends.
    final existing = getRawMarkers(id);
    final existingIds = <String>{};
    for (final e in existing) {
      try {
        if (e is ShapeMeta && e.id != null) existingIds.add(e.id!);
        if (e is Map && e['id'] is String) existingIds.add(e['id'] as String);
      } catch (_) {}
    }

    final toAppend = <dynamic>[];
    final updates = <Map<String, dynamic>>[];

    for (final s in shapes) {
      try {
        final sid = s.id;
        if (sid != null && existingIds.contains(sid)) {
          // Prepare update payload: include full pointMetas when present
          final map = <String, dynamic>{'id': sid};
          if (s.pointMetas != null) {
            map['pointMetas'] =
                s.pointMetas!.map((pm) => pm.toMap()).toList(growable: false);
          }
          updates.add(map);
        } else {
          // New entry: append ShapeMeta directly so notifier will register
          toAppend.add(s);
        }
      } catch (_) {}
    }

    // Apply updates in a single batch if any
    try {
      if (updates.isNotEmpty) {
        // Use static batchUpdateCoordinates which will forward to
        // the notifier and respect useInPlaceMutation flag.
        batchUpdateCoordinates(id, updates,
            createMarkerWidgets: createMarkerWidgets,
            useInPlaceMutation: useInPlaceMutation);
      }
    } catch (_) {}

    // Append new entries if any
    if (toAppend.isNotEmpty) {
      try {
        await appendRawMarkers(id, List<dynamic>.from(toAppend),
            createMarkerWidgets: createMarkerWidgets);
      } catch (_) {
        try {
          // Fallback: setRawMarkers to include appended entries
          final merged = List<dynamic>.from(getRawMarkers(id))
            ..addAll(toAppend);
          setRawMarkers(id, merged);
        } catch (_) {}
      }
    }

    return true;
  }

  /// Efficiently apply many raw-marker updates for [id] in a single batch.
  /// Returns true when the notifier exists and the operation was applied.
  static Future<bool> batchUpdateRawMarkers(String id, List<dynamic> updates,
      {bool createMarkerWidgets = true}) async {
    var n = _getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return false;

    // Decide whether to show blocking overlay for large batches.
    final shouldBlock = updates.length >= _autoBlockingThreshold;
    try {
      if (shouldBlock) {
        try {
          _blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          setBlockingLoading(id, true);
        } catch (_) {}
        try {
          await Future.delayed(Duration.zero);
        } catch (_) {}
      }

      // Delegate to notifier batch implementation which rebuilds caches
      // once and schedules a debounced notify.
      try {
        n.batchUpdateRawMarkers(updates,
            createMarkerWidgets: createMarkerWidgets);
      } catch (_) {
        try {
          // Fallback: apply per-item updateRawMarker
          for (final u in updates) {
            String? idv;
            if (u is ShapeMeta) idv = u.id;
            if (u is Map) idv = (u['id'] as String?);
            if (idv != null) {
              updateRawMarker(id, idv, u);
            } else {
              await appendRawMarkers(id, [u],
                  createMarkerWidgets: createMarkerWidgets);
            }
          }
        } catch (_) {}
      }

      try {
        if (enableBatchLogging) {
          debugPrint(
              '[FormFieldsMapController] batchUpdateRawMarkers id=$id updates=${updates.length} total=${n.rawMarkers.length}');
        }
      } catch (_) {}
      return true;
    } finally {
      if (shouldBlock) {
        try {
          _blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _blockingClearTimers[id] =
              Timer(const Duration(milliseconds: 200), () {
            try {
              setBlockingLoading(id, false);
            } catch (_) {}
            _blockingClearTimers.remove(id);
          });
        } catch (_) {}
      }
    }
  }

  /// Upsert a single raw marker: update if an entry with [markerId] exists,
  /// otherwise insert it. Returns true when the notifier exists and the
  /// operation was applied.
  static Future<bool> upsertRawMarker(String id, String markerId, dynamic entry,
      {bool createMarkerWidgets = true}) async {
    // Ensure the entry carries the id so batch logic treats it as a
    // replacement when possible.
    try {
      if (entry is ShapeMeta) {
        entry.id = markerId;
      } else if (entry is Map) {
        entry['id'] = markerId;
      }
    } catch (_) {}
    return await batchUpdateRawMarkers(id, [entry],
        createMarkerWidgets: createMarkerWidgets);
  }

  /// Update only coordinates of an existing raw marker or append if missing.
  /// This fast-path delegates to the notifier to avoid full derived-map
  /// rebuilds and returns true when applied.
  static bool updateRawMarkerCoordinates(
      String id, String markerId, List<PointMeta> newPointMetas,
      {bool createMarkerWidgets = true}) {
    final n = _getNotifier(id);
    if (n == null) return false;
    try {
      n.upsertCoordinates(markerId, newPointMetas,
          createMarkerWidgets: createMarkerWidgets);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool removeRawMarker(String id, String markerId) {
    final n = _getNotifier(id);
    if (n == null) return false;
    try {
      return n.removeRawMarker(markerId);
    } catch (_) {
      return false;
    }
  }

  // Polygons
  static String? addPolygon(String id, Polygon p) {
    var n = _getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return null;
    try {
      return n.addPolygon(p);
    } catch (_) {
      return null;
    }
  }

  static void addOrUpdatePolygon(String id, String pid, Polygon p) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.addOrUpdatePolygon(pid, p);
    } catch (_) {}
  }

  static bool removePolygon(String id, String pid) {
    final n = _getNotifier(id);
    if (n == null) return false;
    try {
      return n.removePolygon(pid);
    } catch (_) {
      return false;
    }
  }

  static void clearPolygons(String id) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.clearPolygons();
    } catch (_) {}
  }

  // Polylines
  static String? addPolyline(String id, Polyline l) {
    var n = _getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return null;
    try {
      return n.addPolyline(l);
    } catch (_) {
      return null;
    }
  }

  static void addOrUpdatePolyline(String id, String lid, Polyline l) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.addOrUpdatePolyline(lid, l);
    } catch (_) {}
  }

  static bool removePolyline(String id, String lid) {
    final n = _getNotifier(id);
    if (n == null) return false;
    try {
      return n.removePolyline(lid);
    } catch (_) {
      return false;
    }
  }

  static void clearPolylines(String id) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.clearPolylines();
    } catch (_) {}
  }

  // Circles
  static String? addCircle(String id, CircleMarker c) {
    var n = _getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return null;
    try {
      return n.addCircle(c);
    } catch (_) {
      return null;
    }
  }

  static void addOrUpdateCircle(String id, String cid, CircleMarker c) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.addOrUpdateCircle(cid, c);
    } catch (_) {}
  }

  static bool removeCircle(String id, String cid) {
    final n = _getNotifier(id);
    if (n == null) return false;
    try {
      return n.removeCircle(cid);
    } catch (_) {
      return false;
    }
  }

  static void clearCircles(String id) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.clearCircles();
    } catch (_) {}
  }

  // Markers
  static String? addMarker(String id, Marker m) {
    var n = _getNotifier(id);
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return null;
    try {
      return n.addMarker(m);
    } catch (_) {
      return null;
    }
  }

  static void addOrUpdateMarker(String id, String mid, Marker m) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.addOrUpdateMarker(mid, m);
    } catch (_) {}
  }

  static bool removeMarker(String id, String mid) {
    final n = _getNotifier(id);
    if (n == null) return false;
    try {
      return n.removeMarker(mid);
    } catch (_) {
      return false;
    }
  }

  static void clearMarkers(String id) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.clearMarkers();
    } catch (_) {}
  }

  /// Returns the current map center for the controller with [id], or `null`
  /// if the controller isn't available or the camera info is not yet
  /// initialized. This uses `mapController.camera.center` when possible.
  static LatLng? getCenter(String id) {
    final controller = _controllers[id];
    if (controller == null) return null;
    try {
      return controller.camera.center;
    } catch (_) {
      return null;
    }
  }

  /// Optionally remove a controller (e.g., on dispose of a long-lived form)
  static void remove(String id) {
    _controllers.remove(id);
  }

  // Playback handler registry for polyline playback control.
  static final Map<String, FormFieldsMapPlaybackHandler?> _playbackHandlers =
      {};

  // Per-controller flag whether appending markers should auto-start
  // playback. Widgets set this when they register their playback handler
  // according to their configuration (e.g. FormFieldsMapPlaybackConfig).
  static final Map<String, bool> _playbackAutoStart = {};

  // Whether consumers should receive center updates during internal
  // playback-driven camera moves. Defaults to `false` (suppress updates
  // while playback is active). Callers may set this per-controller id to
  // opt into receiving updates during playback.
  static final Map<String, bool> _notifyCenterDuringPlayback = {};

  /// Configure whether `onCenterChanged` callbacks should be invoked while
  /// internal playback is active for controller [id]. Defaults to `false`.
  static void setNotifyCenterDuringPlayback(String id, bool value) {
    _notifyCenterDuringPlayback[id] = value;
  }

  /// Returns whether center updates are allowed during internal playback for
  /// [id]. Defaults to `false` when not configured.
  static bool getNotifyCenterDuringPlayback(String id) {
    return _notifyCenterDuringPlayback.putIfAbsent(id, () => false);
  }

  // Playback playing notifiers so external UI can reflect authoritative
  // playback state. Created on demand per controller id.
  static final Map<String, ValueNotifier<bool>> _playbackPlayingNotifiers = {};

  /// Returns a `ValueListenable<bool>` that emits `true` while playback is
  /// active for controller [id]. The notifier is created on demand.
  static ValueListenable<bool> getPlaybackPlayingListenable(String id) {
    return _playbackPlayingNotifiers.putIfAbsent(
        id, () => ValueNotifier<bool>(false));
  }

  /// Set the authoritative playback playing state for [id]. This will
  /// create the notifier if necessary and update its value.
  static void setPlaybackPlaying(String id, bool value) {
    _playbackPlayingNotifiers
        .putIfAbsent(id, () => ValueNotifier<bool>(false))
        .value = value;
  }

  /// Register a playback handler for a given controller id. Pass `null`
  /// to unregister.
  static void registerPlaybackHandler(
      String id, FormFieldsMapPlaybackHandler? handler) {
    if (handler == null) {
      _playbackHandlers.remove(id);
    } else {
      _playbackHandlers[id] = handler;
    }
  }

  /// Control whether appendRawMarkers should auto-start playback for [id].
  /// When set to `true`, the first non-empty append will call the
  /// registered playback handler. Defaults to `false` when not set.
  static void setPlaybackAutoStart(String id, bool value) {
    if (value) {
      _playbackAutoStart[id] = true;
    } else {
      _playbackAutoStart.remove(id);
    }
  }

  static bool getPlaybackAutoStart(String id) {
    return _playbackAutoStart.putIfAbsent(id, () => false);
  }

  /// Unregister a playback handler for [id].
  static void unregisterPlaybackHandler(String id) {
    _playbackHandlers.remove(id);
  }

  /// Control helpers that forward to a registered playback handler (if any).
  static void startPolylinePlayback(String id, String? polylineId) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.start(polylineId);
    } catch (_) {}
  }

  static void pausePolylinePlayback(String id) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.pause();
    } catch (_) {}
  }

  static void restartPolylinePlayback(String id) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.restart();
    } catch (_) {}
  }

  static void setPolylinePlaybackInterval(String id, Duration interval) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.setInterval(interval);
    } catch (_) {}
  }

  /// Set the number of interpolation steps used by the playback handler
  /// for [id]. This forwards to the registered handler if present.
  static void setPolylinePlaybackInterpolationSteps(String id, int steps) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.setInterpolationSteps(steps);
    } catch (_) {}
  }

  /// Toggle playback (start/resume or pause) for the given controller id.
  static void togglePolylinePlayback(String id, String? polylineId) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.toggle(polylineId);
    } catch (_) {}
  }

  /// Advance playback by one step (forward). Forwards to registered handler.
  static void stepPolylineForward(String id, String? polylineId) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.stepForward(polylineId);
    } catch (_) {}
  }

  /// Move playback one step backward. Forwards to registered handler.
  static void stepPolylineBackward(String id, String? polylineId) {
    final h = _playbackHandlers[id];
    if (h == null) return;
    try {
      h.stepBackward(polylineId);
    } catch (_) {}
  }
}

/// A small value-object used to bridge playback control commands from
/// external callers (via `FormFieldsMapController`) into a concrete
/// `FormFieldsMapState` implementation.
class FormFieldsMapPlaybackHandler {
  final void Function(String? polylineId) start;
  final VoidCallback pause;
  final VoidCallback restart;
  final void Function(Duration) setInterval;
  final void Function(int) setInterpolationSteps;
  final void Function(String? polylineId) toggle;
  final void Function(String? polylineId) stepForward;
  final void Function(String? polylineId) stepBackward;

  FormFieldsMapPlaybackHandler({
    required this.start,
    required this.pause,
    required this.restart,
    required this.setInterval,
    required this.setInterpolationSteps,
    required this.toggle,
    required this.stepForward,
    required this.stepBackward,
  });
}

/// Convenience extension on `MapController` to allow calling registry APIs
/// directly from a `MapController` instance. This lets consumers simply do
/// `mapController.setBlockingLoading(true)` instead of resolving a string id.
extension FormFieldsMapControllerMapControllerExt on MapController {
  String registerWithNotifier([FormFieldsMapNotifier? notifier]) {
    final id =
        FormFieldsMapController.registerControllerAndNotifier(this, null);
    if (notifier == null) {
      // Create and register a fresh notifier for this controller id.
      final n = FormFieldsMapNotifier();
      FormFieldsMapController.registerNotifier(id, n);
    } else {
      FormFieldsMapController.registerNotifier(id, notifier);
    }
    return id;
  }

  void setBlockingLoading(bool value) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setBlockingLoading(id, value);
  }

  void setLoading(bool value) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setLoading(id, value);
  }

  void setRawMarkers(List<dynamic> coords) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setRawMarkers(id, coords);
  }

  Future<bool> appendRawMarkers(List<dynamic> coords) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.appendRawMarkers(id, coords);
  }

  Future<bool> batchUpdateRawMarkers(List<dynamic> updates) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.batchUpdateRawMarkers(id, updates);
  }

  Future<bool> batchUpdateCoordinates(List<Map<String, dynamic>> updates,
      {bool createMarkerWidgets = true, bool useInPlaceMutation = true}) async {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.batchUpdateCoordinates(id, updates,
        createMarkerWidgets: createMarkerWidgets,
        useInPlaceMutation: useInPlaceMutation);
  }

  Future<bool> processShapeMetaList(List<ShapeMeta> shapes,
      {bool createMarkerWidgets = true, bool useInPlaceMutation = true}) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.processShapeMetaList(id, shapes,
        createMarkerWidgets: createMarkerWidgets,
        useInPlaceMutation: useInPlaceMutation);
  }

  Future<bool> upsertRawMarker(String markerId, dynamic entry) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.upsertRawMarker(id, markerId, entry);
  }

  bool updateRawMarkerCoordinates(
      String markerId, List<PointMeta> newPointMetas) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.updateRawMarkerCoordinates(
        id, markerId, newPointMetas);
  }

  void clearRawMarkers() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearRawMarkers(id);
  }

  String? addPolyline(Polyline l) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addPolyline(id, l);
  }

  String? addMarker(Marker m) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addMarker(id, m);
  }

  void clearPolylines() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearPolylines(id);
  }

  void clearPolygons() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearPolygons(id);
  }

  void clearCircles() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearCircles(id);
  }

  void startPolylinePlayback(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.startPolylinePlayback(id, polylineId);
  }

  void pausePolylinePlayback() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.pausePolylinePlayback(id);
  }

  void restartPolylinePlayback() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.restartPolylinePlayback(id);
  }

  void togglePolylinePlayback(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.togglePolylinePlayback(id, polylineId);
  }

  void setPolylinePlaybackInterval(Duration interval) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setPolylinePlaybackInterval(id, interval);
  }

  void setPolylinePlaybackInterpolationSteps(int steps) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setPolylinePlaybackInterpolationSteps(id, steps);
  }

  ValueListenable<bool> getPlaybackPlayingListenable() {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.getPlaybackPlayingListenable(id);
  }

  void setPlaybackPlaying(bool value) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setPlaybackPlaying(id, value);
  }

  void stepPolylineForward(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.stepPolylineForward(id, polylineId);
  }

  void stepPolylineBackward(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.stepPolylineBackward(id, polylineId);
  }

  /// Smoothly animate the map camera from current center to [target].
  /// This helper performs a simple per-frame interpolation and calls
  /// `move` repeatedly. It is intentionally conservative and will
  /// catch errors thrown by the underlying controller.
  Future<void> animateCameraTo(LatLng target, double targetZoom,
      {Duration duration = const Duration(milliseconds: 400),
      Curve curve = Curves.easeInOut}) async {
    LatLng start;
    try {
      start = camera.center;
    } catch (_) {
      // Fallback to a safe origin at equator if camera unavailable.
      start = LatLng(0, 0);
    }

    double startZoom;
    try {
      startZoom = camera.zoom;
    } catch (_) {
      startZoom = 12.0;
    }

    final int steps = (duration.inMilliseconds / 16).clamp(1, 60).toInt();
    final int stepMs = (duration.inMilliseconds / steps).round();
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final et = curve.transform(t);
      final lat = start.latitude + (target.latitude - start.latitude) * et;
      final lon = start.longitude + (target.longitude - start.longitude) * et;
      final zoom = startZoom + (targetZoom - startZoom) * et;
      try {
        move(LatLng(lat, lon), zoom);
      } catch (_) {}
      await Future.delayed(Duration(milliseconds: stepMs));
    }
  }

  List<dynamic> getRawMarkers() {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.getRawMarkers(id);
  }

  String? addPolygon(Polygon p) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addPolygon(id, p);
  }

  String? addCircle(CircleMarker c) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addCircle(id, c);
  }

  void removeNotifier() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.removeNotifier(id);
  }
}
