part of '../form_fields_map.dart';

/// Tap handling for the map: resolves the tapped shape/marker and emits the
/// matching callbacks.
extension _FormFieldsMapTapX on FormFieldsMapState {
  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    if (_suppressNextMapTap) {
      _suppressNextMapTap = false;
      return;
    }
    try {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;

      // Compute local tap offset once for pixel-based hit tests.
      Offset local;
      try {
        local = (tapPosition as dynamic).localPosition as Offset;
      } catch (_) {
        try {
          local = (tapPosition as dynamic).local as Offset;
        } catch (_) {
          local = Offset(
            (context.size?.width ?? 0) / 2,
            (context.size?.height ?? 0) / 2,
          );
        }
      }

      // Polygons: point-in-polygon test. If point-in-polygon fails, also
      // perform an edge-distance fallback so thin polygons or borders are
      // still tappable.
      final tapZoom = _lastZoom ?? widget.initialZoom;
      final center = _lastCenter ?? widget.initialCenter;
      final centerX = CanvasRawMarkerPainter.worldX(center.longitude, tapZoom);
      final centerY = CanvasRawMarkerPainter.worldY(center.latitude, tapZoom);
      final double worldSize = 256 * pow(2, tapZoom).toDouble();
      // Increase hit padding slightly and scale with device pixel ratio so
      // taps are easier on denser screens and at intermediate zoom levels.
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final double extraTapPad = max(_tapPad, devicePixelRatio * 6.0) + 8.0;
      final double baseThreshPx = 24.0 + extraTapPad;

      for (final entry in notifier.polygonMap.entries) {
        final pid = entry.key;
        final poly = entry.value;
        if (_pointInPolygon(latlng, poly.points)) {
          // try to find metadata in rawMarkers if present and convert to ShapeMeta
          final meta = _findMetaForShape(notifier, pid);
          final mapPayload = <String, dynamic>{};
          if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
          mapPayload['id'] = pid;
          mapPayload['shapeType'] = ShapeTypes.polygon;
          mapPayload['lat'] = latlng.latitude;
          mapPayload['lon'] = latlng.longitude;
          final cVal = _extractColorPayloadForId(notifier, pid);
          if (cVal != null) mapPayload['color'] = cVal;
          // building ShapeMeta from mapPayload (log removed)
          final sm = ShapeMeta.fromMap(mapPayload);
          widget.onTapShape?.call(sm);
          return;
        }
        // Fallback: check distance to polygon edges in screen space. This
        // helps when polygon is thin or user taps near its border.
        try {
          double minEdgeDist = double.infinity;
          final pts = poly.points;
          for (var i = 0; i < pts.length; i++) {
            final p0 = pts[i];
            final p1 = pts[(i + 1) % pts.length];
            final x0 = CanvasRawMarkerPainter.worldX(p0.longitude, tapZoom);
            final y0 = CanvasRawMarkerPainter.worldY(p0.latitude, tapZoom);
            var dx0 = (x0 - centerX) + (context.size?.width ?? 0) / 2;
            var dy0 = (y0 - centerY) + (context.size?.height ?? 0) / 2;
            if (dx0.abs() > worldSize / 2) {
              if (dx0 > 0) {
                dx0 -= worldSize;
              } else {
                dx0 += worldSize;
              }
            }
            final x1 = CanvasRawMarkerPainter.worldX(p1.longitude, tapZoom);
            final y1 = CanvasRawMarkerPainter.worldY(p1.latitude, tapZoom);
            var dx1 = (x1 - centerX) + (context.size?.width ?? 0) / 2;
            var dy1 = (y1 - centerY) + (context.size?.height ?? 0) / 2;
            if (dx1.abs() > worldSize / 2) {
              if (dx1 > 0) {
                dx1 -= worldSize;
              } else {
                dx1 += worldSize;
              }
            }
            final distPx = pointToSegmentDistance(
              local,
              Offset(dx0, dy0),
              Offset(dx1, dy1),
            );
            if (distPx < minEdgeDist) minEdgeDist = distPx;
          }
          if (minEdgeDist <= max(baseThreshPx, 16.0)) {
            final meta = _findMetaForShape(notifier, pid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = pid;
            mapPayload['shapeType'] = ShapeTypes.polygon;
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
            final cVal = _extractColorPayloadForId(notifier, pid);
            if (cVal != null) mapPayload['color'] = cVal;
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }
        } catch (_) {}
      }

      // Polylines: precise per-segment hit-testing in screen pixels. Increase
      // threshold based on stroke width and add a relaxed fallback so thin
      // or angled segments are easier to tap.
      double minPolyDist = double.infinity;
      String? minPolyId;
      for (final entry in notifier.polylineMap.entries) {
        final lid = entry.key;
        final pl = entry.value;
        final pts = pl.points;
        final stroke = pl.strokeWidth;
        final threshPx = max(baseThreshPx, stroke * 3.0 + 16.0);
        for (var i = 0; i < pts.length - 1; i++) {
          final p0 = pts[i];
          final p1 = pts[i + 1];
          final x0 = CanvasRawMarkerPainter.worldX(p0.longitude, tapZoom);
          final y0 = CanvasRawMarkerPainter.worldY(p0.latitude, tapZoom);
          var dx0 = (x0 - centerX) + (context.size?.width ?? 0) / 2;
          var dy0 = (y0 - centerY) + (context.size?.height ?? 0) / 2;
          if (dx0.abs() > worldSize / 2) {
            if (dx0 > 0) {
              dx0 -= worldSize;
            } else {
              dx0 += worldSize;
            }
          }
          final x1 = CanvasRawMarkerPainter.worldX(p1.longitude, tapZoom);
          final y1 = CanvasRawMarkerPainter.worldY(p1.latitude, tapZoom);
          var dx1 = (x1 - centerX) + (context.size?.width ?? 0) / 2;
          var dy1 = (y1 - centerY) + (context.size?.height ?? 0) / 2;
          if (dx1.abs() > worldSize / 2) {
            if (dx1 > 0) {
              dx1 -= worldSize;
            } else {
              dx1 += worldSize;
            }
          }
          final distPx = pointToSegmentDistance(
            local,
            Offset(dx0, dy0),
            Offset(dx1, dy1),
          );
          if (distPx < minPolyDist) {
            minPolyDist = distPx;
            minPolyId = lid;
          }
          if (distPx <= threshPx) {
            final meta = _findMetaForShape(notifier, lid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = lid;
            mapPayload['shapeType'] = ShapeTypes.polyline;
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
            final cVal = _extractColorPayloadForId(notifier, lid);
            if (cVal != null) mapPayload['color'] = cVal;
            // polyline tap handled (log removed)
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
      // If no strict hit, use a relaxed fallback based on nearest distance.
      const double relaxMul = 4.0;
      if (minPolyId != null &&
          minPolyDist.isFinite &&
          minPolyDist <= baseThreshPx * relaxMul) {
        final meta = _findMetaForShape(notifier, minPolyId);
        final mapPayload = <String, dynamic>{};
        if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
        mapPayload['id'] = minPolyId;
        mapPayload['shapeType'] = ShapeTypes.polyline;
        mapPayload['lat'] = latlng.latitude;
        mapPayload['lon'] = latlng.longitude;
        final cVal = _extractColorPayloadForId(notifier, minPolyId);
        if (cVal != null) mapPayload['color'] = cVal;
        // polyline fallback handled (log removed)
        final sm = ShapeMeta.fromMap(mapPayload);
        widget.onTapShape?.call(sm);
        return;
      }

      final distance = Distance();
      // Circles: distance to center (meters if useRadiusInMeter true)
      // compute meters per pixel at current latitude/zoom so we can expand
      // meter-based radii by a sensible touch padding.
      final metersPerPixel =
          (156543.03392 * cos((latlng.latitude) * pi / 180)) / pow(2, tapZoom);
      final touchPadMeters = metersPerPixel * (_tapPad + 8.0);

      for (final entry in notifier.circleMap.entries) {
        final cid = entry.key;
        final c = entry.value;
        final center = c.point;
        final d = distance.distance(center, latlng);
        if (c.useRadiusInMeter) {
          if (d <= c.radius + touchPadMeters) {
            final meta = _findMetaForShape(notifier, cid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = cid;
            mapPayload['shapeType'] = ShapeTypes.circle;
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
            final cVal = _extractColorPayloadForId(notifier, cid);
            if (cVal != null) mapPayload['color'] = cVal;
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }
        } else {
          // radius in pixels/deg: approximate with small threshold
          final approxDeg = 0.01; // conservative fallback
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
            // building ShapeMeta from payload (log removed)
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
      // Markers: check rawMarkers canvas items for proximity to tap
      try {
        final radiusToUse = max(_canvasMarkerRadiusEffective, 6.0);
        final headOffsetMul = 0.6;
        final headRadiusMul = 0.9;
        final size = context.size ?? Size.zero;
        for (final m in _rawMarkersForProcessing(notifier)) {
          double lat;
          double lon;
          String? title;
          String? subtitle;
          String? shapeType;
          String? id;
          if (m is ShapeMeta) {
            final pms = m.pointMetas;
            final pm = (pms != null && pms.isNotEmpty) ? pms.first : null;
            if (pm == null) continue;
            lat = pm.lat;
            lon = pm.lon;
            title = pm.hit?.title ?? m.hit?.title;
            subtitle = pm.hit?.subtitle ?? m.hit?.subtitle;
            shapeType = m.shapeType;
            id = m.id;
          } else if (m is LatLng) {
            lat = m.latitude;
            lon = m.longitude;
          } else if (m is List && m.length >= 2) {
            lat = (m[0] as num).toDouble();
            lon = (m[1] as num).toDouble();
            if (m.length >= 3) title = m[2]?.toString();
            if (m.length >= 4) subtitle = m[3]?.toString();
            if (m.length >= 5) shapeType = m[4]?.toString();
          } else if (m is Map) {
            lat =
                (m['lat'] as num?)?.toDouble() ??
                (m['latitude'] as num?)?.toDouble() ??
                0.0;
            lon =
                (m['lon'] as num?)?.toDouble() ??
                (m['longitude'] as num?)?.toDouble() ??
                0.0;
            title = m['title']?.toString();
            subtitle = m['subtitle']?.toString();
            shapeType = m['shapeType']?.toString();
            id = m['id']?.toString();
          } else {
            continue;
          }

          final x = CanvasRawMarkerPainter.worldX(lon, tapZoom);
          final y = CanvasRawMarkerPainter.worldY(lat, tapZoom);

          var dx = (x - centerX) + size.width / 2;
          var dy = (y - centerY) + size.height / 2;
          if (dx.abs() > worldSize / 2) {
            if (dx > 0) {
              dx -= worldSize;
            } else {
              dx += worldSize;
            }
          }

          if (dx < -radiusToUse ||
              dx > size.width + radiusToUse ||
              dy < -radiusToUse ||
              dy > size.height + radiusToUse) {
            continue;
          }

          final headCenter = Offset(dx, dy - radiusToUse * headOffsetMul);
          final headRadius = radiusToUse * headRadiusMul;
          final headHitRadius = headRadius + extraTapPad;
          final dist = (local - headCenter).distance;
          if (dist <= headHitRadius) {
            final mapPayload = <String, dynamic>{};
            if (m is Map) mapPayload.addAll(Map<String, dynamic>.from(m));
            mapPayload['lat'] = lat;
            mapPayload['lon'] = lon;
            if (id != null) mapPayload['id'] = id;
            if (id != null) {
              final cVal = _extractColorPayloadForId(notifier, id);
              if (cVal != null) mapPayload['color'] = cVal;
            }
            mapPayload['shapeType'] = shapeType ?? ShapeTypes.marker;
            if (title != null) mapPayload['title'] = title;
            if (subtitle != null) mapPayload['subtitle'] = subtitle;
            // raw marker tap handled (log removed)
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }

          // Also hit-test the title/subtitle background region (if present)
          if ((title != null && title.isNotEmpty) ||
              (subtitle != null && subtitle.isNotEmpty)) {
            try {
              final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
              final textStyle = TextStyle(
                color: Colors.black,
                fontSize: max(10.0, devicePixelRatio * 6),
                fontWeight: FontWeight.w600,
              );
              final lines = <String>[];
              if (title != null && title.isNotEmpty) lines.add(title);
              if (subtitle != null && subtitle.isNotEmpty) lines.add(subtitle);
              final tp = TextPainter(textDirection: TextDirection.ltr);
              final span = TextSpan(
                children: lines
                    .map((l) => TextSpan(text: '$l\n', style: textStyle))
                    .toList(),
              );
              tp.text = span;
              tp.textAlign = TextAlign.center;
              tp.layout(minWidth: 0, maxWidth: size.width);

              final pad = 4.0;
              final bgWidth = tp.width + pad * 2;
              final bgHeight = tp.height + pad * 2;
              final bgRect = Rect.fromCenter(
                center: Offset(
                  headCenter.dx,
                  headCenter.dy - headRadius - bgHeight / 2 - 6,
                ),
                width: bgWidth,
                height: bgHeight,
              );

              if (bgRect.inflate(extraTapPad).contains(local)) {
                final mapPayload = <String, dynamic>{};
                if (m is Map) mapPayload.addAll(Map<String, dynamic>.from(m));
                mapPayload['lat'] = lat;
                mapPayload['lon'] = lon;
                if (id != null) mapPayload['id'] = id;
                if (id != null) {
                  final cVal = _extractColorPayloadForId(notifier, id);
                  if (cVal != null) mapPayload['color'] = cVal;
                }
                mapPayload['shapeType'] = shapeType ?? ShapeTypes.marker;
                if (title != null) mapPayload['title'] = title;
                if (subtitle != null) mapPayload['subtitle'] = subtitle;
                // raw marker label tap handled (log removed)
                final sm = ShapeMeta.fromMap(mapPayload);
                widget.onTapShape?.call(sm);
                return;
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    } catch (_) {}

    widget.onMapTap?.call(latlng);
  }
}
