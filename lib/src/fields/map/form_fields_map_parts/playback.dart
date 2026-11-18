part of '../form_fields_map.dart';

extension _FormFieldsMapPlaybackX on FormFieldsMapState {
  List<LatLng> _buildInterpolatedPoints(List<LatLng> pts, int steps) {
    if (pts.length < 2 || steps <= 0) return List<LatLng>.from(pts);
    final out = <LatLng>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      out.add(a);
      for (var s = 1; s <= steps; s++) {
        final t = s / (steps + 1);
        final lat = a.latitude + (b.latitude - a.latitude) * t;
        final lon = a.longitude + (b.longitude - a.longitude) * t;
        out.add(LatLng(lat, lon));
      }
    }
    out.add(pts.last);
    return out;
  }

  void _setPolylinePlaybackInterval(Duration interval) {
    _playbackInterval = interval;
    _playbackSubstepInterval = _computeSubstepInterval(
      _playbackInterval,
      _playbackInterpolationSteps,
    );
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
        _playbackSubstepInterval,
        (_) => _advancePlaybackStep(),
      );
    }
  }

  // Allow runtime update of interpolation steps
  void _setPlaybackInterpolationSteps(int steps) {
    _playbackInterpolationSteps = steps.clamp(0, 1000);
    _playbackSubstepInterval = _computeSubstepInterval(
      _playbackInterval,
      _playbackInterpolationSteps,
    );
    // The running timer keeps the old period until it is replaced. Reschedule
    // it so the new speed takes effect now.
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
        _playbackSubstepInterval,
        (_) => _advancePlaybackStep(),
      );
    }
    // rebuild playback list if currently playing
    if (_playbackPolylineId != null) {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      final pl = notifier.polylineMap[_playbackPolylineId];
      if (pl != null) {
        final currentPoint =
            _playbackPoints.isNotEmpty &&
                _playbackIndex < _playbackPoints.length
            ? _playbackPoints[_playbackIndex]
            : null;
        _playbackPoints = _buildInterpolatedPoints(
          pl.points,
          _playbackInterpolationSteps,
        );
        // re-find closest index to currentPoint
        if (currentPoint != null) {
          var best = 0;
          var bestDist = double.infinity;
          for (var i = 0; i < _playbackPoints.length; i++) {
            final d =
                pow((_playbackPoints[i].latitude - currentPoint.latitude), 2) +
                pow((_playbackPoints[i].longitude - currentPoint.longitude), 2);
            if (d < bestDist) {
              bestDist = d as double;
              best = i;
            }
          }
          _playbackIndex = best;
        }
      }
    }
  }

  void _togglePolylinePlayback(String? polylineId) {
    if (_isPlaying) {
      _pausePolylinePlayback();
    } else {
      _startPolylinePlayback(polylineId);
    }
  }

  Duration _computeSubstepInterval(Duration perPoint, int steps) {
    final div = (steps <= 0) ? 1 : (steps + 1);
    final ms = (perPoint.inMilliseconds / div).round();
    return Duration(milliseconds: max(1, ms));
  }

  void _startPolylinePlayback(String? polylineId) {
    try {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      String? id =
          polylineId ??
          (notifier.polylineMap.isNotEmpty
              ? notifier.polylineMap.keys.first
              : null);
      if (id == null) return;
      final pl = notifier.polylineMap[id];
      if (pl == null || pl.points.isEmpty) return;
      // If we're starting the same polyline that was previously playing and
      // there are existing playback points, treat this as a resume rather
      // than always restarting from the beginning. If the playback had
      // already reached the end, fall through and restart from zero.
      if (_playbackPolylineId == id && _playbackPoints.isNotEmpty) {
        if (_playbackIndex < _playbackPoints.length - 1) {
          _isPlaying = true;
          // ensure external listeners are notified when resuming playback
          try {
            FormFieldsMapController.setPlaybackPlaying(_controllerId, true);
          } catch (_) {}
          _safeSetState(() {});
          _playbackTimer?.cancel();
          _playbackTimer = Timer.periodic(
            _playbackSubstepInterval,
            (_) => _advancePlaybackStep(),
          );
          return;
        } else {
          // at end -> restart from beginning
          _playbackIndex = 0;
        }
      }

      // New polyline (or restarting finished one): build points and start
      _playbackPolylineId = id;
      _playbackPoints = _buildInterpolatedPoints(
        pl.points,
        _playbackInterpolationSteps,
      );
      _playbackIndex = 0;
      _isPlaying = true;
      // publish authoritative playing state
      try {
        FormFieldsMapController.setPlaybackPlaying(_controllerId, true);
      } catch (_) {}
      _safeSetState(() {});
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
        _playbackSubstepInterval,
        (_) => _advancePlaybackStep(),
      );
      // Zoom to level 17 (clamped to allowed min/max) when starting playback
      try {
        final initialPoint = _playbackPoints.isNotEmpty
            ? _playbackPoints[_playbackIndex]
            : null;
        if (initialPoint != null) {
          if (_playbackFollowCamera) {
            // animateTo is async but we don't need to await inside timer callbacks
            animateTo(initialPoint, _playbackTargetZoom, curve: _playbackCurve);
          }
        }
      } catch (_) {}
      _updatePlaybackMarker();
    } catch (_) {}
  }

  void _pausePolylinePlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
    } catch (_) {}
    _safeSetState(() {});
  }

  void _restartPolylinePlayback() {
    // If no playback polyline is currently selected, attempt to pick the
    // first available polyline from the notifier so external callers can
    // reliably restart immediately after generating a polyline.
    final notifier =
        FormFieldsMapController.getNotifier(_controllerId) ?? _fallbackNotifier;
    if (_playbackPolylineId == null) {
      if (notifier.polylineMap.isEmpty) return;
      _playbackPolylineId = notifier.polylineMap.keys.first;
      final pl = notifier.polylineMap[_playbackPolylineId];
      if (pl != null) {
        _playbackPoints = _buildInterpolatedPoints(
          pl.points,
          _playbackInterpolationSteps,
        );
      }
    }

    // If still no points, nothing to restart.
    if (_playbackPoints.isEmpty) return;

    _playbackIndex = 0;
    _isPlaying = true;
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, true);
    } catch (_) {}
    _safeSetState(() {});
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      _playbackSubstepInterval,
      (_) => _advancePlaybackStep(),
    );
    _updatePlaybackMarker();
  }

  void _advancePlaybackStep() {
    if (!_isPlaying) return;
    if (_playbackPoints.isEmpty) return;
    if (_playbackIndex < _playbackPoints.length - 1) {
      _playbackIndex++;
    } else {
      // stop at end
      _isPlaying = false;
      _playbackTimer?.cancel();
      try {
        FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
      } catch (_) {}
      // Rebuild so the play/pause control shows "play" again.
      _safeSetState(() {});
    }
    _updatePlaybackMarker();
  }

  void _stepPlaybackForward(String? polylineId) {
    if (_playbackPoints.isEmpty) return;
    if (_playbackIndex < _playbackPoints.length - 1) {
      _playbackIndex++;
    }
    // stop any running playback when user steps manually
    _isPlaying = false;
    _playbackTimer?.cancel();
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
    } catch (_) {}
    _updatePlaybackMarker();
    try {
      if (_playbackFollowCamera) {
        final p = _playbackPoints[_playbackIndex];
        animateTo(p, _playbackTargetZoom, curve: _playbackCurve);
      }
    } catch (_) {}
  }

  void _stepPlaybackBackward(String? polylineId) {
    if (_playbackPoints.isEmpty) return;
    if (_playbackIndex > 0) {
      _playbackIndex--;
    }
    _isPlaying = false;
    _playbackTimer?.cancel();
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
    } catch (_) {}
    _updatePlaybackMarker();
    try {
      if (_playbackFollowCamera) {
        final p = _playbackPoints[_playbackIndex];
        animateTo(p, _playbackTargetZoom, curve: _playbackCurve);
      }
    } catch (_) {}
  }

  void _updatePlaybackMarker() {
    try {
      if (!mounted) return;
      if (_playbackPoints.isEmpty) return;
      final p = _playbackPoints[_playbackIndex];
      // compute bearing for rotation (degrees)
      double bearing = 0.0;
      try {
        if (_playbackPoints.length > 1) {
          // The heading is the direction of travel. Between the previous point
          // and this one when there is a previous point. At the first point,
          // it is this point toward the next one. The reverse would turn the
          // marker around at the start.
          final LatLng from;
          final LatLng to;
          if (_playbackIndex > 0) {
            from = _playbackPoints[_playbackIndex - 1];
            to = p;
          } else {
            from = p;
            to = _playbackPoints[1];
          }
          bearing = bearingDegrees(from, to);
        }
      } catch (_) {}

      final payload = <String, dynamic>{
        'id': 'playback_marker',
        'shapeType': ShapeTypes.marker,
        'lat': p.latitude,
        'lon': p.longitude,
        'rotation': bearing,
        'title': null,
      };
      // Determine the effective provider used for canvas marker rasterization
      // (prefer the explicit `canvasMarkerIcon`, otherwise allow a playback
      // specific `playbackMarkerIcon` from the playback config). If no
      // provider is available, fall back to the default arrow glyph. Leaving
      // 'icon' unset allows the painter to draw the rasterized `iconImage`
      // when present.
      final effectiveProviderForPlayback =
          widget.playbackConfig?.playbackMarkerIcon ??
          _canvasMarkerIconEffective;
      if (effectiveProviderForPlayback == null) {
        payload['icon'] = 'arrow';
      }
      // Allow playback config to override the marker/polyline color for
      // playback-specific visuals.
      if (_playbackPolylineColor != null) {
        payload['color'] = _playbackPolylineColor;
      }
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      // Use controller API to mutate notifier so only controller is the
      // canonical mutator for map state. Use remove+append so we don't
      // replace the entire `rawMarkers` list (which would clear
      // derived polylines/polygons). This keeps playback marker updates
      // isolated and preserves existing shape layers.
      try {
        // updateRawMarker replaces the marker synchronously. appendRawMarkers
        // waits and retries while the map is not ready, and called on every
        // playback tick those retries piled up and could add the marker more
        // than once.
        FormFieldsMapController.updateRawMarker(
          _controllerId,
          'playback_marker',
          payload,
        );
      } catch (_) {
        // fallback to direct notifier mutation if registry isn't available
        try {
          // replace any existing playback_marker in notifier.rawMarkers
          notifier.rawMarkers.removeWhere(
            (r) =>
                (r is Map && r['id'] == 'playback_marker') ||
                (r is ShapeMeta && r.id == 'playback_marker'),
          );
        } catch (_) {}
        try {
          notifier.appendRawMarkers([payload]);
        } catch (_) {
          notifier.rawMarkers = [payload];
        }
      }
      // If playback is active, move camera to follow the playback point
      try {
        if (_isPlaying && _playbackFollowCamera) {
          animateTo(p, _playbackTargetZoom, curve: _playbackCurve);
        }
      } catch (_) {}
      // Notify consumers when a playback point is reached so they can
      // react (e.g. show a bottom sheet with history details).
      try {
        widget.playbackConfig?.onPointReached?.call(
          _playbackPolylineId,
          _playbackIndex,
          p,
        );
      } catch (_) {}
    } catch (_) {}
  }
}
