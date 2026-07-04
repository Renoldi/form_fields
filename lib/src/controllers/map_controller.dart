import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';

/// A persistent controller provider for `MapController` instances.
/// Controllers are keyed by an `id` so they are not recreated on widget rebuilds.
class FormFieldsMapController {
  static final Map<String, MapController> _controllers = {};

  // Optional ValueNotifiers to represent loading state per controller id.
  static final Map<String, ValueNotifier<bool>> _loadingNotifiers = {};
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

  /// Returns a `ValueListenable<bool>` representing the loading state for
  /// the controller with [id]. The notifier is created on demand and shared
  /// so callers can observe or set loading state across widgets and viewmodels.
  static ValueListenable<bool> getLoadingListenable(String id) {
    return _loadingNotifiers.putIfAbsent(id, () => ValueNotifier<bool>(false));
  }

  /// Convenience setter to change the loading value for [id].
  static void setLoading(String id, bool value) {
    _loadingNotifiers.putIfAbsent(id, () => ValueNotifier<bool>(false)).value =
        value;
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
