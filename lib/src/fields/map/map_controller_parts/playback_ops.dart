part of '../map_controller.dart';

/// Internal implementation for [FormFieldsMapController]; the public API delegates here.
class _MapPlaybackOps {
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

  // Playback playing notifiers so external UI can reflect authoritative
  // playback state. Created on demand per controller id.
  static final Map<String, ValueNotifier<bool>> _playbackPlayingNotifiers = {};

  static final Map<String, bool> _requestedPlaying = {};

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

  /// Returns a `ValueListenable<bool>` that emits `true` while playback is
  /// active for controller [id]. The notifier is created on demand.
  static ValueListenable<bool> getPlaybackPlayingListenable(String id) {
    return _playbackPlayingNotifiers.putIfAbsent(
      id,
      () => ValueNotifier<bool>(false),
    );
  }

  /// Set the authoritative playback playing state for [id]. This will
  /// create the notifier if necessary and update its value.
  static void setPlaybackPlaying(String id, bool value) {
    final notifier = _playbackPlayingNotifiers.putIfAbsent(
      id,
      () => ValueNotifier<bool>(false),
    );
    // Playback can start from inside a build (for example when markers are
    // appended while the map is building). Notifying listeners right then
    // would mark widgets dirty during build, so the write is deferred. The
    // deferred write uses the latest requested value, so a later direct write
    // is not overwritten when the deferred one runs.
    _requestedPlaying[id] = value;
    try {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.idle) {
        notifier.value = value;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            notifier.value = _requestedPlaying[id] ?? value;
          } catch (_) {}
        });
      }
    } catch (_) {
      try {
        notifier.value = value;
      } catch (_) {}
    }
  }

  /// Register a playback handler for a given controller id. Pass `null`
  /// to unregister.
  static void registerPlaybackHandler(
    String id,
    FormFieldsMapPlaybackHandler? handler,
  ) {
    if (handler == null) {
      _playbackHandlers.remove(id);
    } else {
      _playbackHandlers[id] = handler;
    }
  }

  /// Control whether _MapRawMarkerOps.appendRawMarkers should auto-start playback for [id].
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
