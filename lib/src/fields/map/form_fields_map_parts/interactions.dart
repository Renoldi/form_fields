part of '../form_fields_map.dart';

extension _FormFieldsMapInteractionsX on FormFieldsMapState {
  /// Center the map on the device's current location (uses internal
  /// `GeocodingService.currentLocation()` which relies on `geolocator`).
  Future<void> _centerMapOnCurrentLocation() async {
    if (_centerActionInProgress) return;
    _applyStateChange(() {
      _centerActionInProgress = true;
    });
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final msgLocationDisabled = context.formTr('locationAccessDisabled');
      final msgLocationNotAvailable = context.formTr(
        'currentLocationNotAvailable',
      );

      if (!_findConfigEffective.allowGeolocation) {
        messenger?.showSnackBar(SnackBar(content: Text(msgLocationDisabled)));
        return;
      }

      final pm = await _geocodingService.currentLocation();
      if (pm != null) {
        final target = LatLng(pm.lat, pm.lon);
        final currentZoom = _lastZoom ?? widget.initialZoom;
        final zoom = (widget.playbackConfig != null)
            ? _playbackTargetZoom
            : currentZoom;
        await animateTo(target, zoom);
        return;
      }

      messenger?.showSnackBar(SnackBar(content: Text(msgLocationNotAvailable)));
    } finally {
      if (mounted) {
        _applyStateChange(() {
          _centerActionInProgress = false;
        });
      }
    }
  }

  void _onPositionChanged(dynamic position, bool hasGesture) {
    widget.onPositionChanged?.call(position);

    try {
      final dynamic pos = position; // Ensure position is dynamic
      if (pos != null) {
        if (pos.center != null) {
          _lastCenter = pos.center as LatLng;
        }
        if (pos.zoom != null) {
          _lastZoom = (pos.zoom as num).toDouble();
        }
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              FormFieldsMapController.setLoading(_controllerId, true);
            } catch (_) {}
            _safeSetState(() {});
          });
        }
      }
    } catch (_) {}

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.cameraIdleDebounce, () {
      FormFieldsMapController.setLoading(_controllerId, false);
      // During playback, do not notify center changes to consumers.
      if (!_isPlaying) {
        // Only notify center after camera becomes idle so consumers get the
        // final/last center rather than a rapid stream of intermediate values.
        try {
          // Call the callbacks in a post-frame callback so user-provided
          // handlers can safely call _applyStateChange() without triggering the
          // "_applyStateChange() or markNeedsBuild() called during build" exception.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              if (_lastCenter != null) {
                widget.onCenterChanged?.call(_lastCenter!);
              }
            } catch (_) {}
            try {
              widget.onCameraIdle?.call();
            } catch (_) {}
          });
          // The center-marker confirmation should only be triggered explicitly
          // via the confirmation button (see the check `AppButton` below).
          // Do not automatically invoke `onCenterMarker` when the camera
          // becomes idle after panning/zooming.
        } catch (_) {}
      }
    });
  }

  void _handleLongPress(TapPosition tapPosition, LatLng latlng) {
    try {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;

      for (final entry in notifier.polygonMap.entries) {
        final pid = entry.key;
        final poly = entry.value;
        if (_pointInPolygon(latlng, poly.points)) {
          final meta = _findMetaForShape(notifier, pid);
          final payload = <String, dynamic>{
            'id': pid,
            'shapeType': ShapeTypes.polygon,
          };
          if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
          payload['point'] = latlng;
          final cVal = _extractColorPayloadForId(notifier, pid);
          if (cVal != null) payload['color'] = cVal;
          final sm = ShapeMeta.fromMap(payload);
          widget.onTapShape?.call(sm);
          return;
        }
      }

      const threshMeters = 200.0;
      for (final entry in notifier.polylineMap.entries) {
        final lid = entry.key;
        final pl = entry.value;
        final pts = pl.points;
        for (var i = 0; i < pts.length - 1; i++) {
          // Distance to the segment itself. Measuring to the midpoint missed
          // taps on long segments, which are far from their midpoint.
          final d = distanceToSegmentMeters(latlng, pts[i], pts[i + 1]);
          if (d <= threshMeters) {
            final meta = _findMetaForShape(notifier, lid);
            final payload = <String, dynamic>{
              'id': lid,
              'shapeType': ShapeTypes.polyline,
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final cVal = _extractColorPayloadForId(notifier, lid);
            if (cVal != null) payload['color'] = cVal;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }

      for (final entry in notifier.circleMap.entries) {
        final cid = entry.key;
        final c = entry.value;
        final center = c.point;
        final d = Distance().distance(center, latlng);
        if (c.useRadiusInMeter) {
          if (d <= c.radius) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{
              'id': cid,
              'shapeType': ShapeTypes.circle,
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final cVal = _extractColorPayloadForId(notifier, cid);
            if (cVal != null) payload['color'] = cVal;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        } else {
          final approxDeg = 0.01;
          final latDiff = (center.latitude - latlng.latitude).abs();
          final lonDiff = (center.longitude - latlng.longitude).abs();
          if (sqrt(latDiff * latDiff + lonDiff * lonDiff) <= approxDeg) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{
              'id': cid,
              'shapeType': ShapeTypes.circle,
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final cVal = _extractColorPayloadForId(notifier, cid);
            if (cVal != null) payload['color'] = cVal;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
    } catch (_) {}

    widget.onLongPress?.call(latlng);
  }
}
