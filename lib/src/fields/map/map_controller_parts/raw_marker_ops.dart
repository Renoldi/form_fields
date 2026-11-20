part of '../map_controller.dart';

/// Internal implementation for [FormFieldsMapController]; the public API delegates here.
class _MapRawMarkerOps {
  // --- Notifier mutation helpers ---
  /// Replace the notifier's `rawMarkers` list for [id]. No-op when no
  /// notifier is registered for [id].
  static void setRawMarkers(String id, List<dynamic> coords) {
    var n = _MapRegistry._getNotifier(id);
    // Ensure a notifier exists so controller-only callers don't silently
    // fail to update raw markers (playback relies on this).
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        _MapRegistry.registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return;
    try {
      final shouldBlock = coords.length >= _MapRegistry._autoBlockingThreshold;
      if (shouldBlock) {
        try {
          _MapRegistry.setBlockingLoading(id, true);
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
          _MapRegistry.setBlockingLoading(id, false);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<bool> appendRawMarkers(
    String id,
    List<dynamic> coords, {
    bool createMarkerWidgets = true,
  }) async {
    var n = _MapRegistry._getNotifier(id);
    // Ensure a notifier exists so UI widgets can observe updates even when
    // callers only hold a `MapController` reference.
    if (n == null) {
      try {
        final created = FormFieldsMapNotifier();
        _MapRegistry.registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return false;

    // If the map/controller isn't ready yet (camera center unavailable),
    // schedule a short retry instead of mutating immediately. This fixes
    // the issue where markers are appended before the map has initialized
    // and thus are not displayed until the user interacts with the map.
    final center = FormFieldsMapController.getCenter(id);
    if (center == null) {
      final attempts = (_MapRegistry._appendRetryCounts[id] ?? 0) + 1;
      if (attempts > _MapRegistry._maxAppendRetries) {
        try {
          if (_MapRegistry.enableBatchLogging) {
            debugLog(
              '[FormFieldsMapController] appendRawMarkers id=$id aborted after $attempts attempts (map not ready)',
            );
          }
        } catch (_) {}
        _MapRegistry._appendRetryCounts.remove(id);
        return false;
      }
      _MapRegistry._appendRetryCounts[id] = attempts;
      await Future.delayed(const Duration(milliseconds: 100));
      // Pass the caller's options through. Dropping them made a retry use the
      // default, even when the caller had asked for something else.
      return await appendRawMarkers(
        id,
        coords,
        createMarkerWidgets: createMarkerWidgets,
      );
    }

    // Reset retry count on success path.
    _MapRegistry._appendRetryCounts.remove(id);

    // Detect whether this is the first append for this controller so we
    // can initialize playback UI state if a playback handler was
    // registered. Capture current emptiness now (before mutation).
    final bool wasRawMarkersEmptyBeforeAppend = (n.rawMarkers.isEmpty);

    // Decide whether this append should present the full-screen blocking
    // overlay. We only do this for larger batches to avoid blocking UI
    // for tiny updates.
    final shouldBlock = coords.length >= _MapRegistry._autoBlockingThreshold;

    try {
      if (shouldBlock) {
        // Cancel any pending clear timers (another batch is ongoing)
        try {
          _MapRegistry._blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _MapRegistry.setBlockingLoading(id, true);
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
            _MapPlaybackOps._playbackHandlers.containsKey(id) &&
            _MapPlaybackOps.getPlaybackAutoStart(id)) {
          // Auto-start playback when the first raw markers are appended
          // and playback support is enabled for this controller. Use the
          // public helper so any registered handler is invoked to start
          // the playback flow (which will also set up timers and markers).
          try {
            _MapPlaybackOps.setPlaybackPlaying(id, true);
          } catch (_) {}
          try {
            _MapPlaybackOps.startPolylinePlayback(id, null);
          } catch (_) {}
        }
      } catch (_) {}
      try {
        if (_MapRegistry.enableBatchLogging) {
          debugLog(
            '[FormFieldsMapController] appendRawMarkers id=$id notifier=${n.hashCode} appended=${coords.length} total=${n.rawMarkers.length}',
          );
        }
      } catch (_) {}
      return true;
    } finally {
      if (shouldBlock) {
        // Debounce clearing the overlay so closely spaced batches don't
        // cause flicker. If another batch arrives it will cancel this
        // timer and keep the overlay visible.
        try {
          _MapRegistry._blockingClearTimers[id]?.cancel();
        } catch (_) {}
        try {
          _MapRegistry._blockingClearTimers[id] = Timer(
            const Duration(milliseconds: 200),
            () {
              try {
                _MapRegistry.setBlockingLoading(id, false);
              } catch (_) {}
              _MapRegistry._blockingClearTimers.remove(id);
            },
          );
        } catch (_) {}
      }
    }
  }

  /// Tell the map that entries of the raw list were changed in place (for
  /// example `PointMeta` coordinates). Rebuilds the layers without copying.
  static void refreshRawMarkers(String id) {
    final n = _MapRegistry._getNotifier(id);
    if (n == null) return;
    try {
      n.touchRawMarkers();
    } catch (_) {}
  }

  static void clearRawMarkers(String id) {
    final n = _MapRegistry._getNotifier(id);
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
    final n = _MapRegistry._getNotifier(id);
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

  static bool removeRawMarker(String id, String markerId) {
    final n = _MapRegistry._getNotifier(id);
    if (n == null) return false;
    try {
      return n.removeRawMarker(markerId);
    } catch (_) {
      return false;
    }
  }
}
