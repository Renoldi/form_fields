import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';

/// A persistent controller provider for `MapController` instances.
/// Controllers are keyed by an `id` so they are not recreated on widget rebuilds.
class FormFieldsMapController {
  static final Map<String, MapController> _controllers = {};
  // Registered notifiers per controller id. Widgets must register their
  // `FormFieldsMapNotifier` instance so the controller can perform
  // mutations on the notifier on behalf of external callers.
  static final Map<String, FormFieldsMapNotifier> _notifiers = {};
  // Reverse mapping from notifier instance to id to help callers (examples)
  // discover the registry id when they hold a notifier reference.
  static final Map<FormFieldsMapNotifier, String> _notifierToId = {};

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
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.rawMarkers = List<dynamic>.from(coords);
      try {
        debugPrint(
            '[FormFieldsMapController] setRawMarkers id=$id notifier=${n.hashCode} count=${n.rawMarkers.length}');
      } catch (_) {}
    } catch (_) {}
  }

  static void appendRawMarkers(String id, List<dynamic> coords) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.appendRawMarkers(List<dynamic>.from(coords));
      try {
        debugPrint(
            '[FormFieldsMapController] appendRawMarkers id=$id notifier=${n.hashCode} count=${n.rawMarkers.length}');
      } catch (_) {}
    } catch (_) {}
  }

  static void clearRawMarkers(String id) {
    final n = _getNotifier(id);
    if (n == null) return;
    try {
      n.clearRawMarkers();
    } catch (_) {}
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
    final n = _getNotifier(id);
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
    final n = _getNotifier(id);
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
    final n = _getNotifier(id);
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
    final n = _getNotifier(id);
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

  FormFieldsMapPlaybackHandler({
    required this.start,
    required this.pause,
    required this.restart,
    required this.setInterval,
    required this.setInterpolationSteps,
    required this.toggle,
  });
}

/// Convenience extension on `MapController` to allow calling registry APIs
/// directly from a `MapController` instance. This lets consumers simply do
/// `mapController.setBlockingLoading(true)` instead of resolving a string id.
extension FormFieldsMapControllerMapControllerExt on MapController {
  String registerWithNotifier(FormFieldsMapNotifier? notifier) {
    return FormFieldsMapController.registerControllerAndNotifier(
        this, notifier);
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

  void appendRawMarkers(List<dynamic> coords) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.appendRawMarkers(id, coords);
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
