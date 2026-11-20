part of '../map_stores.dart';

extension MapRawMarkerCoordinatesX on MapRawMarkerStore {
  /// Batch apply coordinate-only updates. Each entry in [updates] should be
  /// a Map with at least an `id` and either `pointMetas` (List of maps with
  /// `lat`/`lon`) or `lat`/`lon` for single-point markers. This method will
  /// update rawMarkers in-place and refresh only the affected concrete
  /// entries once, then schedule a single debounced notify.
  void batchUpdateCoordinates(
    List<Map<String, dynamic>> updates, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) {
    _ensureControlled();
    if (updates.isEmpty) return;

    // Build id -> index lookup for rawMarkers to avoid O(n^2) scans.
    final idToIndex = <String, int>{};
    for (var i = 0; i < _rawMarkersCache.length; i++) {
      final r = _rawMarkersCache[i];
      String? rid;
      if (r is ShapeMeta) rid = r.id;
      if (r is Map) rid = (r['id'] as String?);
      if (rid != null) idToIndex[rid] = i;
    }

    final updatedIds = <String>{};

    // Apply raw cache updates. Support both absolute replacements and
    // delta translations. When `deltaLat`/`deltaLon` is provided, prefer
    // mutating existing `PointMeta` in-place to avoid allocations.
    for (final u in updates) {
      try {
        final id = (u['id'] as String?) ?? '';
        if (id.isEmpty) {
          // No id -> append minimal entry
          if (u.containsKey('pointMetas') && u['pointMetas'] is List) {
            final pms = (u['pointMetas'] as List)
                .map(
                  (pm) => PointMeta(
                    lat: (pm['lat'] as num).toDouble(),
                    lon: (pm['lon'] as num).toDouble(),
                  ),
                )
                .toList(growable: false);
            final newSm = ShapeMeta(pointMetas: pms);
            _rawMarkersCache = List<dynamic>.from(_rawMarkersCache)..add(newSm);
            updatedIds.add(newSm.id ?? '');
          } else if (u.containsKey('lat') && u.containsKey('lon')) {
            final copy = Map<String, dynamic>.from(u);
            _rawMarkersCache = List<dynamic>.from(_rawMarkersCache)..add(copy);
            // No id to track
          }
          continue;
        }

        final idx = idToIndex[id];
        if (idx != null && idx >= 0 && idx < _rawMarkersCache.length) {
          final existing = _rawMarkersCache[idx];

          // Handle delta translation in-place when possible (fast path).
          if (useInPlaceMutation &&
              u.containsKey('deltaLat') &&
              u.containsKey('deltaLon')) {
            final dLat = (u['deltaLat'] as num).toDouble();
            final dLon = (u['deltaLon'] as num).toDouble();
            try {
              if (existing is ShapeMeta &&
                  existing.pointMetas != null &&
                  existing.pointMetas!.isNotEmpty) {
                for (var pm in existing.pointMetas!) {
                  pm.lat = pm.lat + dLat;
                  pm.lon = pm.lon + dLon;
                }
                _rawMarkersCache[idx] = existing;
                updatedIds.add(id);
                continue;
              } else if (existing is Map) {
                final lat = (existing['lat'] as num?)?.toDouble();
                final lon = (existing['lon'] as num?)?.toDouble();
                if (lat != null && lon != null) {
                  existing['lat'] = lat + dLat;
                  existing['lon'] = lon + dLon;
                  _rawMarkersCache[idx] = existing;
                  updatedIds.add(id);
                  continue;
                }
              }
            } catch (e, st) {
              _mapLog.fine('Ignored map update error', e, st);
            }
            // If we couldn't apply delta in-place, fall through to other
            // handling below (replacement or append).
          }

          if (existing is ShapeMeta) {
            if (u['pointMetas'] is List) {
              final pms = (u['pointMetas'] as List)
                  .map(
                    (pm) => PointMeta(
                      lat: (pm['lat'] as num).toDouble(),
                      lon: (pm['lon'] as num).toDouble(),
                    ),
                  )
                  .toList(growable: false);
              existing.pointMetas = pms;
              _rawMarkersCache[idx] = existing;
              updatedIds.add(id);
            }
          } else if (existing is Map) {
            final pointMetas = u['pointMetas'];
            // An empty list has no first point. Fall through to lat/lon so the
            // update is not dropped.
            if (pointMetas is List && pointMetas.isNotEmpty) {
              final p0 = pointMetas.first as Map<String, dynamic>;
              existing['lat'] = (p0['lat'] as num).toDouble();
              existing['lon'] = (p0['lon'] as num).toDouble();
              _rawMarkersCache[idx] = existing;
              updatedIds.add(id);
            } else if (u.containsKey('lat') && u.containsKey('lon')) {
              existing['lat'] = (u['lat'] as num).toDouble();
              existing['lon'] = (u['lon'] as num).toDouble();
              _rawMarkersCache[idx] = existing;
              updatedIds.add(id);
            }
          }
        } else {
          // Not found -> append as ShapeMeta when pointMetas provided.
          if (u['pointMetas'] is List) {
            final pms = (u['pointMetas'] as List)
                .map(
                  (pm) => PointMeta(
                    lat: (pm['lat'] as num).toDouble(),
                    lon: (pm['lon'] as num).toDouble(),
                  ),
                )
                .toList(growable: false);
            final newSm = ShapeMeta(pointMetas: pms, id: id);
            _rawMarkersCache = List<dynamic>.from(_rawMarkersCache)..add(newSm);
            updatedIds.add(id);
          } else if (u.containsKey('lat') && u.containsKey('lon')) {
            final copy = Map<String, dynamic>.from(u);
            copy['id'] ??= id;
            _rawMarkersCache = List<dynamic>.from(_rawMarkersCache)..add(copy);
          }
        }
      } catch (e, st) {
        _mapLog.fine('Ignored map update error', e, st);
      }
    }

    if (updatedIds.isEmpty) {
      _scheduleNotify();
      return;
    }

    try {
      // Remove concrete entries for all updated ids first.
      _removeConcreteEntries(updatedIds);

      // Recreate concrete entries for updated ids by scanning rawMarkers
      // for those ids and registering only those entries.
      for (final id in updatedIds) {
        try {
          // Find raw entry by id
          dynamic raw;
          for (final r in _rawMarkersCache) {
            String? rid;
            if (r is ShapeMeta) rid = r.id;
            if (r is Map) rid = (r['id'] as String?);
            if (rid == id) {
              raw = r;
              break;
            }
          }
          if (raw == null) continue;

          _registerConcreteEntry(raw, createMarkerWidgets: createMarkerWidgets);
        } catch (e, st) {
          _mapLog.fine('Ignored map update error', e, st);
        }
      }

      _rebuildConcreteCaches(createMarkerWidgets: createMarkerWidgets);
    } catch (e, st) {
      _mapLog.fine('Ignored map update error', e, st);
    }

    _scheduleNotify();
  }
}
