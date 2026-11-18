part of '../map_stores.dart';

extension MapRawMarkerBatchX on MapRawMarkerStore {
  /// Apply many raw-marker updates in a single batch.
  ///
  /// `updates` may contain `ShapeMeta` instances or Map-style descriptors.
  /// For entries that carry an `id` the notifier will replace the existing
  /// entry (and its derived concrete map entries) in-place. Entries without
  /// an `id` are appended. Caches are rebuilt once and listeners are
  /// notified via the normal debounced path.
  void batchUpdateRawMarkers(
    List<dynamic> updates, {
    bool createMarkerWidgets = true,
  }) {
    _ensureControlled();
    if (updates.isEmpty) return;

    // Partition updates into replacements (by id) and pure appends.
    final Map<String, dynamic> replacements = {};
    final List<dynamic> appends = [];
    for (final u in updates) {
      String? id;
      if (u is ShapeMeta) id = u.id;
      if (u is Map) id = (u['id'] as String?);
      if (id == null) {
        appends.add(u);
      } else {
        replacements[id] = u;
      }
    }

    // Build new rawMarkers list by replacing existing entries where ids
    // match, preserving order. Track which replacement ids were consumed.
    final consumed = <String>{};
    final List<dynamic> newRaw = [];
    for (final r in _rawMarkersCache) {
      String? id;
      if (r is ShapeMeta) id = r.id;
      if (r is Map) id = (r['id'] as String?);
      if (id != null && replacements.containsKey(id)) {
        newRaw.add(replacements[id]);
        consumed.add(id);
      } else {
        newRaw.add(r);
      }
    }

    // Append replacements that did not match any existing entry, then
    // append pure new entries.
    for (final entry in replacements.entries) {
      if (!consumed.contains(entry.key)) newRaw.add(entry.value);
    }
    newRaw.addAll(appends);

    // Replace raw cache once.
    _rawMarkersCache = List<dynamic>.from(newRaw);

    try {
      // Remove any concrete-layer entries for replacement ids so the new
      // values can register cleanly.
      for (final id in replacements.keys) {
        try {
          polygons.raw.remove(id);
        } catch (e, st) {
          _mapLog.fine('Ignored map update error', e, st);
        }
        try {
          polylines.raw.remove(id);
        } catch (e, st) {
          _mapLog.fine('Ignored map update error', e, st);
        }
        try {
          circles.raw.remove(id);
        } catch (e, st) {
          _mapLog.fine('Ignored map update error', e, st);
        }
        try {
          markers.raw.remove(id);
        } catch (e, st) {
          _mapLog.fine('Ignored map update error', e, st);
        }
      }

      // Re-register concrete entries for all updated/added items. This
      // mirrors the per-item logic in appendRawMarkers but is performed
      // once for the batch to avoid repeated cache rebuilds.
      final affected = <dynamic>[];
      affected.addAll(replacements.values);
      affected.addAll(appends);
      for (final r in affected) {
        try {
          // Support both ShapeMeta and Map-style descriptors.
          ShapeMeta? sm;
          String? type;
          if (r is ShapeMeta) {
            sm = r;
            type = sm.shapeType?.toLowerCase();
          } else if (r is Map) {
            type = (r['shapeType'] as String?)?.toLowerCase();
          }
          if (sm != null && sm.shapeType != null || type != null) {
            final t = type ?? sm!.shapeType!.toLowerCase();
            final pms = sm?.pointMetas;
            if (t == ShapeTypes.polygon && pms != null && pms.isNotEmpty) {
              final pts = pms.map((pm) => pm.point).toList(growable: false);
              final opts = sm?.polygonOptions();
              final poly = Polygon(
                points: pts,
                color: opts?.fillColor ?? Colors.transparent,
                borderColor: opts?.borderColor ?? Colors.transparent,
                borderStrokeWidth: opts?.borderStrokeWidth ?? 1.0,
              );
              final id =
                  sm!.id ?? 'p\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= id;
              polygons.raw[id] = poly;
            } else if (t == ShapeTypes.polyline &&
                pms != null &&
                pms.isNotEmpty) {
              final pts = pms.map((pm) => pm.point).toList(growable: false);
              final opts = sm?.polylineOptions();
              final pl = Polyline(
                points: pts,
                strokeWidth: opts?.strokeWidth ?? 2.0,
                color: opts?.color ?? Colors.transparent,
                useStrokeWidthInMeter: opts?.useStrokeWidthInMeter ?? true,
              );
              final id =
                  sm!.id ?? 'l\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= id;
              polylines.raw[id] = pl;
            } else if (t == ShapeTypes.circle &&
                pms != null &&
                pms.isNotEmpty) {
              final center = pms.first.point;
              final rad = pms.first.rotation ?? 10.0;
              final opts = sm?.circleOptions();
              final c = CircleMarker(
                point: center,
                color: opts?.borderColor ?? Colors.transparent,
                borderStrokeWidth: opts?.borderStrokeWidth ?? 0.0,
                borderColor: opts?.borderColor ?? Colors.transparent,
                useRadiusInMeter: opts?.useRadiusInMeter ?? true,
                radius: opts?.radiusMeters ?? rad,
              );
              final id =
                  sm!.id ?? 'c\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= id;
              circles.raw[id] = c;
            } else if (t == ShapeTypes.marker &&
                pms != null &&
                pms.isNotEmpty) {
              final center = pms.first.point;
              final opts = sm?.markerOptions();
              final marker = Marker(
                point: center,
                width: opts?.width?.toDouble() ?? 40,
                height: opts?.height?.toDouble() ?? 40,
                child: const SizedBox.shrink(),
              );
              final id =
                  sm!.id ?? 'm\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= id;
              if (createMarkerWidgets) markers.raw[id] = marker;
            }
          } else if (r is Map) {
            // Minimal support for Map entries: create marker-like entries
            // when shapeType indicates marker and lat/lon exist.
            final st = (r['shapeType'] as String?)?.toLowerCase();
            if (st == ShapeTypes.marker) {
              final lat = (r['lat'] as num?)?.toDouble();
              final lon = (r['lon'] as num?)?.toDouble();
              if (lat != null && lon != null) {
                final marker = Marker(
                  point: LatLng(lat, lon),
                  width: 40,
                  height: 40,
                  child: const SizedBox.shrink(),
                );
                final id =
                    (r['id'] as String?) ??
                    'm\$${DateTime.now().microsecondsSinceEpoch}';
                r['id'] ??= id;
                if (createMarkerWidgets) markers.raw[id] = marker;
              }
            }
          }
        } catch (e, st) {
          _mapLog.fine('Ignored map update error', e, st);
        }
      }

      // Rebuild caches once.
      polygons.rebuildCache();
      polylines.rebuildCache();
      circles.rebuildCache();
      if (createMarkerWidgets) {
        markers.rebuildCache();
      }
    } catch (e, st) {
      _mapLog.fine('Ignored map update error', e, st);
    }

    _scheduleNotify();
  }

  /// Fast-path: update coordinates for a single marker (or shape) identified
  /// by [id]. When the entry exists and is a `ShapeMeta`, this will replace
  /// its `pointMetas` with [newPointMetas] and refresh only the affected
  /// concrete map and cache to avoid a full rebuild.
  ///
  /// If the entry does not exist, it will be appended as a new `ShapeMeta`.
  void upsertCoordinates(
    String id,
    List<PointMeta> newPointMetas, {
    bool createMarkerWidgets = true,
  }) {
    _ensureControlled();

    // Find existing raw marker index
    int foundIndex = -1;
    for (var i = 0; i < _rawMarkersCache.length; i++) {
      final r = _rawMarkersCache[i];
      String? rid;
      if (r is ShapeMeta) rid = r.id;
      if (r is Map) rid = (r['id'] as String?);
      if (rid == id) {
        foundIndex = i;
        break;
      }
    }

    ShapeMeta? sm;
    String? shapeType;
    if (foundIndex != -1) {
      final existing = _rawMarkersCache[foundIndex];
      if (existing is ShapeMeta) {
        sm = existing;
        shapeType = sm.shapeType?.toLowerCase();
        sm.pointMetas = List<PointMeta>.from(newPointMetas);
        // replace raw cache entry with updated ShapeMeta
        _rawMarkersCache[foundIndex] = sm;
      } else if (existing is Map) {
        // Map-style entries keep a single coordinate. An empty point list
        // leaves the coordinate as it is.
        if (newPointMetas.isNotEmpty) {
          existing['lat'] = newPointMetas.first.lat;
          existing['lon'] = newPointMetas.first.lon;
        }
        _rawMarkersCache[foundIndex] = existing;
        shapeType = (existing['shapeType'] as String?)?.toLowerCase();
      }
    } else {
      // Not found -> append a new ShapeMeta entry
      final newSm = ShapeMeta(pointMetas: newPointMetas, id: id);
      _rawMarkersCache = List<dynamic>.from(_rawMarkersCache)..add(newSm);
      sm = newSm;
      shapeType = sm.shapeType?.toLowerCase();
    }

    try {
      // Remove existing concrete maps for this id
      try {
        polygons.raw.remove(id);
      } catch (e, st) {
        _mapLog.fine('Ignored map update error', e, st);
      }
      try {
        polylines.raw.remove(id);
      } catch (e, st) {
        _mapLog.fine('Ignored map update error', e, st);
      }
      try {
        circles.raw.remove(id);
      } catch (e, st) {
        _mapLog.fine('Ignored map update error', e, st);
      }
      try {
        markers.raw.remove(id);
      } catch (e, st) {
        _mapLog.fine('Ignored map update error', e, st);
      }

      // Recreate only the concrete entry for this id based on shapeType
      if (sm != null && sm.pointMetas != null && sm.pointMetas!.isNotEmpty) {
        final pms = sm.pointMetas!;
        final t = (sm.shapeType ?? ShapeTypes.marker).toLowerCase();
        if (t == ShapeTypes.polygon) {
          final pts = pms.map((pm) => pm.point).toList(growable: false);
          final opts = sm.polygonOptions();
          final poly = Polygon(
            points: pts,
            color: opts.fillColor ?? Colors.transparent,
            borderColor: opts.borderColor ?? Colors.transparent,
            borderStrokeWidth: opts.borderStrokeWidth ?? 1.0,
          );
          polygons.raw[id] = poly;
          polygons.rebuildCache();
        } else if (t == ShapeTypes.polyline) {
          final pts = pms.map((pm) => pm.point).toList(growable: false);
          final opts = sm.polylineOptions();
          final pl = Polyline(
            points: pts,
            strokeWidth: opts.strokeWidth ?? 2.0,
            color: opts.color ?? Colors.transparent,
            useStrokeWidthInMeter: opts.useStrokeWidthInMeter ?? true,
          );
          polylines.raw[id] = pl;
          polylines.rebuildCache();
        } else if (t == ShapeTypes.circle) {
          final center = pms.first.point;
          final rad = pms.first.rotation ?? 10.0;
          final opts = sm.circleOptions();
          final c = CircleMarker(
            point: center,
            color: opts.borderColor ?? Colors.transparent,
            borderStrokeWidth: opts.borderStrokeWidth ?? 0.0,
            borderColor: opts.borderColor ?? Colors.transparent,
            useRadiusInMeter: opts.useRadiusInMeter ?? true,
            radius: opts.radiusMeters ?? rad,
          );
          circles.raw[id] = c;
          circles.rebuildCache();
        } else {
          // marker or default
          final center = pms.first.point;
          final opts = sm.markerOptions();
          final marker = Marker(
            point: center,
            width: opts.width?.toDouble() ?? 40,
            height: opts.height?.toDouble() ?? 40,
            child: const SizedBox.shrink(),
          );
          if (createMarkerWidgets) {
            markers.raw[id] = marker;
            markers.rebuildCache();
          }
        }
      } else if (shapeType != null && shapeType == ShapeTypes.marker) {
        // Map-style marker update already handled via map entry mutation
      }
    } catch (e, st) {
      _mapLog.fine('Ignored map update error', e, st);
    }

    _scheduleNotify();
  }
}
