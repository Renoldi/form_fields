import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';
import 'package:latlong2/latlong.dart';

class FormFieldsMapNotifier extends ChangeNotifier {
  FormFieldsMapNotifier({
    MapController? controller,
    List<Polygon>? polygons,
    List<Polyline>? polylines,
    List<CircleMarker>? circles,
    Map<String, Polygon>? polygonsMap,
    Map<String, Polyline>? polylinesMap,
    Map<String, CircleMarker>? circlesMap,
  })  : _polygonMap = polygonsMap ?? {},
        _polylineMap = polylinesMap ?? {},
        _circleMap = circlesMap ?? {} {
    // If a MapController is provided, register this notifier with it so
    // consumers can opt-in to automatic registry wiring.
    if (controller != null) {
      try {
        controller.registerWithNotifier(this);
      } catch (_) {}
    }
    if (polygons != null) {
      for (var i = 0; i < polygons.length; i++) {
        _polygonMap['p\$i'] = polygons[i];
      }
    }
    if (polylines != null) {
      for (var i = 0; i < polylines.length; i++) {
        _polylineMap['l\$i'] = polylines[i];
      }
    }
    if (circles != null) {
      for (var i = 0; i < circles.length; i++) {
        _circleMap['c\$i'] = circles[i];
      }
    }
    // initialize caches
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _circlesCache = _circleMap.values.toList(growable: false);
  }

  // Debounced notify to reduce UI churn when many small mutations happen
  // in rapid succession (e.g., batched marker appends). Timer is per-notifier
  // and cancels/reschedules on each mutate call. Increased default debounce
  // reduces rebuild frequency for very large batches.
  Timer? _notifyTimer;
  static const Duration _notifyDebounce = Duration(milliseconds: 120);

  void _performNotify() {
    try {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.idle) {
        notifyListeners();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            notifyListeners();
          } catch (_) {}
        });
      }
    } catch (_) {
      try {
        notifyListeners();
      } catch (_) {}
    }
  }

  void _scheduleNotify() {
    try {
      _notifyTimer?.cancel();
      _notifyTimer = Timer(_notifyDebounce, () {
        _notifyTimer = null;
        _performNotify();
      });
    } catch (_) {
      // fallback to immediate notify
      _performNotify();
    }
  }

  // Controller that is allowed to perform mutations. When null, mutating
  // methods will throw. The controller should call `attachController`.
  String? _controllerId;

  /// Attach a controller id to allow mutations via that controller.
  /// Passing `null` detaches and disables mutations.
  void attachController(String? id) {
    _controllerId = id;
    try {
      debugPrint(
          '[FormFieldsMapNotifier] attachController id=$_controllerId hash=$hashCode');
    } catch (_) {}
  }

  void _ensureControlled() {
    if (_controllerId == null) {
      throw StateError(
          'FormFieldsMapNotifier is read-only — mutate via FormFieldsMapController');
    }
  }

  Map<String, Polygon> _polygonMap;
  Map<String, Polyline> _polylineMap;
  Map<String, CircleMarker> _circleMap;

  List<dynamic> _rawMarkersCache = const [];
  List<Polygon> _polygonsCache = const [];
  List<Polyline> _polylinesCache = const [];
  List<CircleMarker> _circlesCache = const [];

  List<dynamic> get rawMarkers => _rawMarkersCache;
  List<Polygon> get polygons => _polygonsCache;
  List<Polyline> get polylines => _polylinesCache;
  List<CircleMarker> get circles => _circlesCache;

  set rawMarkers(List<dynamic> coords) {
    _ensureControlled();
    _rawMarkersCache = coords;
    _scheduleNotify();
  }

  /// Append raw markers. When [createMarkerWidgets] is false, the notifier
  /// will skip constructing `Marker` widget entries in `_markerMap` which
  /// is significantly faster for very large point sets when rendering is
  /// done via a canvas painter rather than per-marker widgets.
  void appendRawMarkers(List<dynamic> coords,
      {bool createMarkerWidgets = true}) {
    _ensureControlled();
    // Fast path: update the raw cache once, and register all ShapeMeta
    // entries into the concrete layer maps in batch to avoid repeated
    // full-map->list conversions on each single addition (which causes
    // O(n^2) behavior when appending many markers).
    final combined = List<dynamic>.from(_rawMarkersCache)..addAll(coords);
    _rawMarkersCache = List<dynamic>.from(combined);

    try {
      // Collect into the internal maps directly and update caches once.
      for (final r in coords) {
        if (r is ShapeMeta && r.shapeType != null) {
          final type = r.shapeType!.toLowerCase();
          final pms = r.pointMetas;
          if (type == ShapeTypes.polygon && pms != null && pms.isNotEmpty) {
            final pts = pms.map((pm) => pm.point).toList(growable: false);
            final opts = r.polygonOptions();
            final poly = Polygon(
              points: pts,
              color: opts.fillColor ?? Colors.transparent,
              borderColor: opts.borderColor ?? Colors.transparent,
              borderStrokeWidth: opts.borderStrokeWidth ?? 1.0,
            );
            final id = r.id ?? 'p\$${DateTime.now().microsecondsSinceEpoch}';
            r.id ??= id;
            _polygonMap[id] = poly;
          } else if (type == ShapeTypes.polyline &&
              pms != null &&
              pms.isNotEmpty) {
            final pts = pms.map((pm) => pm.point).toList(growable: false);
            final opts = r.polylineOptions();
            final pl = Polyline(
              points: pts,
              strokeWidth: opts.strokeWidth ?? 2.0,
              color: opts.color ?? Colors.transparent,
              useStrokeWidthInMeter: opts.useStrokeWidthInMeter ?? true,
            );
            final rid = r.id ?? 'l\$${DateTime.now().microsecondsSinceEpoch}';
            r.id ??= rid;
            _polylineMap[rid] = pl;
          } else if (type == ShapeTypes.circle &&
              pms != null &&
              pms.isNotEmpty) {
            final center = pms.first.point;
            final rad = pms.first.rotation ?? 10.0;
            final opts = r.circleOptions();
            final c = CircleMarker(
              point: center,
              color: opts.borderColor ?? Colors.transparent,
              borderStrokeWidth: opts.borderStrokeWidth ?? 0.0,
              borderColor: opts.borderColor ?? Colors.transparent,
              useRadiusInMeter: opts.useRadiusInMeter ?? true,
              radius: opts.radiusMeters ?? rad,
            );
            final id = r.id ?? 'c\$${DateTime.now().microsecondsSinceEpoch}';
            r.id ??= id;
            _circleMap[id] = c;
          } else if (type == ShapeTypes.marker &&
              pms != null &&
              pms.isNotEmpty) {
            final center = pms.first.point;
            final opts = r.markerOptions();
            final marker = Marker(
              point: center,
              width: opts.width?.toDouble() ?? 40,
              height: opts.height?.toDouble() ?? 40,
              child: const SizedBox.shrink(),
            );
            final id = r.id ?? 'm\$${DateTime.now().microsecondsSinceEpoch}';
            r.id ??= id;
            if (createMarkerWidgets) {
              _markerMap[id] = marker;
            }
          }
        }
      }

      // Rebuild caches once after the batch mutation.
      _polygonsCache = _polygonMap.values.toList(growable: false);
      _polylinesCache = _polylineMap.values.toList(growable: false);
      _circlesCache = _circleMap.values.toList(growable: false);
      if (createMarkerWidgets) {
        _markersCache = _markerMap.values.toList(growable: false);
      } else {
        // Keep previous _markersCache to avoid invalidating marker widgets
        // when the caller chooses canvas-only rendering.
      }
    } catch (_) {}

    _scheduleNotify();
  }

  /// Apply many raw-marker updates in a single batch.
  ///
  /// `updates` may contain `ShapeMeta` instances or Map-style descriptors.
  /// For entries that carry an `id` the notifier will replace the existing
  /// entry (and its derived concrete map entries) in-place. Entries without
  /// an `id` are appended. Caches are rebuilt once and listeners are
  /// notified via the normal debounced path.
  void batchUpdateRawMarkers(List<dynamic> updates,
      {bool createMarkerWidgets = true}) {
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
          _polygonMap.remove(id);
        } catch (_) {}
        try {
          _polylineMap.remove(id);
        } catch (_) {}
        try {
          _circleMap.remove(id);
        } catch (_) {}
        try {
          _markerMap.remove(id);
        } catch (_) {}
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
              _polygonMap[id] = poly;
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
              _polylineMap[id] = pl;
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
              _circleMap[id] = c;
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
              if (createMarkerWidgets) _markerMap[id] = marker;
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
                final id = (r['id'] as String?) ??
                    'm\$${DateTime.now().microsecondsSinceEpoch}';
                r['id'] ??= id;
                if (createMarkerWidgets) _markerMap[id] = marker;
              }
            }
          }
        } catch (_) {}
      }

      // Rebuild caches once.
      _polygonsCache = _polygonMap.values.toList(growable: false);
      _polylinesCache = _polylineMap.values.toList(growable: false);
      _circlesCache = _circleMap.values.toList(growable: false);
      if (createMarkerWidgets) {
        _markersCache = _markerMap.values.toList(growable: false);
      }
    } catch (_) {}

    _scheduleNotify();
  }

  /// Fast-path: update coordinates for a single marker (or shape) identified
  /// by [id]. When the entry exists and is a `ShapeMeta`, this will replace
  /// its `pointMetas` with [newPointMetas] and refresh only the affected
  /// concrete map and cache to avoid a full rebuild.
  ///
  /// If the entry does not exist, it will be appended as a new `ShapeMeta`.
  void upsertCoordinates(String id, List<PointMeta> newPointMetas,
      {bool createMarkerWidgets = true}) {
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
        // Update map-style entry if possible
        existing['lat'] = newPointMetas.first.lat;
        existing['lon'] = newPointMetas.first.lon;
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
        _polygonMap.remove(id);
      } catch (_) {}
      try {
        _polylineMap.remove(id);
      } catch (_) {}
      try {
        _circleMap.remove(id);
      } catch (_) {}
      try {
        _markerMap.remove(id);
      } catch (_) {}

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
          _polygonMap[id] = poly;
          _polygonsCache = _polygonMap.values.toList(growable: false);
        } else if (t == ShapeTypes.polyline) {
          final pts = pms.map((pm) => pm.point).toList(growable: false);
          final opts = sm.polylineOptions();
          final pl = Polyline(
            points: pts,
            strokeWidth: opts.strokeWidth ?? 2.0,
            color: opts.color ?? Colors.transparent,
            useStrokeWidthInMeter: opts.useStrokeWidthInMeter ?? true,
          );
          _polylineMap[id] = pl;
          _polylinesCache = _polylineMap.values.toList(growable: false);
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
          _circleMap[id] = c;
          _circlesCache = _circleMap.values.toList(growable: false);
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
            _markerMap[id] = marker;
            _markersCache = _markerMap.values.toList(growable: false);
          }
        }
      } else if (shapeType != null && shapeType == ShapeTypes.marker) {
        // Map-style marker update already handled via map entry mutation
      }
    } catch (_) {}

    _scheduleNotify();
  }

  /// Batch apply coordinate-only updates. Each entry in [updates] should be
  /// a Map with at least an `id` and either `pointMetas` (List of maps with
  /// `lat`/`lon`) or `lat`/`lon` for single-point markers. This method will
  /// update rawMarkers in-place and refresh only the affected concrete
  /// entries once, then schedule a single debounced notify.
  void batchUpdateCoordinates(List<Map<String, dynamic>> updates,
      {bool createMarkerWidgets = true, bool useInPlaceMutation = true}) {
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
                .map((pm) => PointMeta(
                    lat: (pm['lat'] as num).toDouble(),
                    lon: (pm['lon'] as num).toDouble()))
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
            } catch (_) {}
            // If we couldn't apply delta in-place, fall through to other
            // handling below (replacement or append).
          }

          if (existing is ShapeMeta) {
            if (u['pointMetas'] is List) {
              final pms = (u['pointMetas'] as List)
                  .map((pm) => PointMeta(
                      lat: (pm['lat'] as num).toDouble(),
                      lon: (pm['lon'] as num).toDouble()))
                  .toList(growable: false);
              existing.pointMetas = pms;
              _rawMarkersCache[idx] = existing;
              updatedIds.add(id);
            }
          } else if (existing is Map) {
            if (u['pointMetas'] is List) {
              final p0 =
                  (u['pointMetas'] as List).first as Map<String, dynamic>;
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
                .map((pm) => PointMeta(
                    lat: (pm['lat'] as num).toDouble(),
                    lon: (pm['lon'] as num).toDouble()))
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
      } catch (_) {}
    }

    if (updatedIds.isEmpty) {
      _scheduleNotify();
      return;
    }

    try {
      // Remove concrete entries for all updated ids first.
      for (final id in updatedIds) {
        try {
          _polygonMap.remove(id);
        } catch (_) {}
        try {
          _polylineMap.remove(id);
        } catch (_) {}
        try {
          _circleMap.remove(id);
        } catch (_) {}
        try {
          _markerMap.remove(id);
        } catch (_) {}
      }

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

          ShapeMeta? sm;
          String? type;
          if (raw is ShapeMeta) {
            sm = raw;
            type = sm.shapeType?.toLowerCase();
          } else if (raw is Map) {
            type = (raw['shapeType'] as String?)?.toLowerCase();
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
              final rid =
                  sm!.id ?? 'p\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= rid;
              _polygonMap[rid] = poly;
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
              final rid =
                  sm!.id ?? 'l\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= rid;
              _polylineMap[rid] = pl;
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
              final rid =
                  sm!.id ?? 'c\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= rid;
              _circleMap[rid] = c;
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
              final rid =
                  sm!.id ?? 'm\$${DateTime.now().microsecondsSinceEpoch}';
              sm.id ??= rid;
              if (createMarkerWidgets) _markerMap[rid] = marker;
            }
          } else if (raw is Map) {
            final st = (raw['shapeType'] as String?)?.toLowerCase();
            if (st == ShapeTypes.marker) {
              final lat = (raw['lat'] as num?)?.toDouble();
              final lon = (raw['lon'] as num?)?.toDouble();
              if (lat != null && lon != null) {
                final marker = Marker(
                  point: LatLng(lat, lon),
                  width: 40,
                  height: 40,
                  child: const SizedBox.shrink(),
                );
                final rid = (raw['id'] as String?) ??
                    'm\$${DateTime.now().microsecondsSinceEpoch}';
                raw['id'] ??= rid;
                if (createMarkerWidgets) _markerMap[rid] = marker;
              }
            }
          }
        } catch (_) {}
      }

      // Rebuild caches once.
      _polygonsCache = _polygonMap.values.toList(growable: false);
      _polylinesCache = _polylineMap.values.toList(growable: false);
      _circlesCache = _circleMap.values.toList(growable: false);
      if (createMarkerWidgets) {
        _markersCache = _markerMap.values.toList(growable: false);
      }
    } catch (_) {}

    _scheduleNotify();
  }

  void clearRawMarkers() {
    _ensureControlled();
    _rawMarkersCache = const [];
    _scheduleNotify();
  }

  bool removeRawMarker(String id) {
    _ensureControlled();
    final before = _rawMarkersCache.length;
    _rawMarkersCache = _rawMarkersCache.where((m) {
      if (m is ShapeMeta) return m.id != id;
      if (m is Map) return m['id'] != id;
      return true;
    }).toList(growable: false);
    final removed = _rawMarkersCache.length != before;
    if (removed) _scheduleNotify();
    return removed;
  }

  set polygons(List<Polygon> p) {
    _ensureControlled();
    _polygonMap = {};
    for (var i = 0; i < p.length; i++) {
      _polygonMap['p\$i'] = p[i];
    }
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _scheduleNotify();
  }

  set polylines(List<Polyline> p) {
    _ensureControlled();
    _polylineMap = {};
    for (var i = 0; i < p.length; i++) {
      _polylineMap['l\$i'] = p[i];
    }
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _scheduleNotify();
  }

  set circles(List<CircleMarker> c) {
    _ensureControlled();
    _circleMap = {};
    for (var i = 0; i < c.length; i++) {
      _circleMap['c\$i'] = c[i];
    }
    _circlesCache = _circleMap.values.toList(growable: false);
    _scheduleNotify();
  }

  // Polygons
  String addPolygon(Polygon p) {
    _ensureControlled();
    final id = 'p\$${DateTime.now().microsecondsSinceEpoch}';
    _polygonMap[id] = p;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _scheduleNotify();
    return id;
  }

  void addOrUpdatePolygon(String id, Polygon polygon) {
    _ensureControlled();
    _polygonMap[id] = polygon;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _scheduleNotify();
  }

  Polygon? getPolygon(String id) => _polygonMap[id];

  bool removePolygon(String id) {
    _ensureControlled();
    final removed = _polygonMap.remove(id) != null;
    if (removed) {
      _polygonsCache = _polygonMap.values.toList(growable: false);
      _scheduleNotify();
    }
    return removed;
  }

  void clearPolygons() {
    _ensureControlled();
    _polygonMap.clear();
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _scheduleNotify();
  }

  // Polylines
  String addPolyline(Polyline p) {
    _ensureControlled();
    final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
    _polylineMap[id] = p;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _scheduleNotify();
    return id;
  }

  void addOrUpdatePolyline(String id, Polyline polyline) {
    _ensureControlled();
    _polylineMap[id] = polyline;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _scheduleNotify();
  }

  Polyline? getPolyline(String id) => _polylineMap[id];

  bool removePolyline(String id) {
    _ensureControlled();
    final removed = _polylineMap.remove(id) != null;
    if (removed) {
      _polylinesCache = _polylineMap.values.toList(growable: false);
      _scheduleNotify();
    }
    return removed;
  }

  void clearPolylines() {
    _ensureControlled();
    _polylineMap.clear();
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _scheduleNotify();
  }

  String addCircle(CircleMarker c) {
    _ensureControlled();
    final id = 'c\$${DateTime.now().microsecondsSinceEpoch}';
    _circleMap[id] = c;
    _circlesCache = _circleMap.values.toList(growable: false);
    _scheduleNotify();
    return id;
  }

  void addOrUpdateCircle(String id, CircleMarker circle) {
    _ensureControlled();
    _circleMap[id] = circle;
    _circlesCache = _circleMap.values.toList(growable: false);
    _scheduleNotify();
  }

  CircleMarker? getCircle(String id) => _circleMap[id];

  bool removeCircle(String id) {
    _ensureControlled();
    final removed = _circleMap.remove(id) != null;
    if (removed) {
      _circlesCache = _circleMap.values.toList(growable: false);
      _scheduleNotify();
    }
    return removed;
  }

  void clearCircles() {
    _ensureControlled();
    _circleMap.clear();
    _circlesCache = _circleMap.values.toList(growable: false);
    _scheduleNotify();
  }

  // Markers
  Map<String, Marker> _markerMap = {};

  List<Marker> _markersCache = const [];

  List<Marker> get markers => _markersCache;

  /// Public accessors for internal maps so external consumers (same
  /// package files) can query or iterate entries without relying on
  /// private fields. These are intentionally read-only views.
  Map<String, Polygon> get polygonMap => Map.unmodifiable(_polygonMap);
  Map<String, Polyline> get polylineMap => Map.unmodifiable(_polylineMap);
  Map<String, CircleMarker> get circleMap => Map.unmodifiable(_circleMap);

  set markers(List<Marker> m) {
    _markerMap = {};
    for (var i = 0; i < m.length; i++) {
      final id = 'm\$${DateTime.now().microsecondsSinceEpoch}_\$i';
      _markerMap[id] = m[i];
    }
    _markersCache = _markerMap.values.toList(growable: false);
    _scheduleNotify();
  }

  String addMarker(Marker m) {
    _ensureControlled();
    final id = 'm\$${DateTime.now().microsecondsSinceEpoch}';
    _markerMap[id] = m;
    _markersCache = _markerMap.values.toList(growable: false);
    _scheduleNotify();
    return id;
  }

  void addOrUpdateMarker(String id, Marker marker) {
    _ensureControlled();
    _markerMap[id] = marker;
    _markersCache = _markerMap.values.toList(growable: false);
    _scheduleNotify();
  }

  Marker? getMarker(String id) => _markerMap[id];

  bool removeMarker(String id) {
    _ensureControlled();
    final removed = _markerMap.remove(id) != null;
    if (removed) {
      _markersCache = _markerMap.values.toList(growable: false);
      _scheduleNotify();
    }
    return removed;
  }

  void clearMarkers() {
    _ensureControlled();
    _markerMap.clear();
    _markersCache = _markerMap.values.toList(growable: false);
    _scheduleNotify();
  }

  @override
  void dispose() {
    try {
      _notifyTimer?.cancel();
    } catch (_) {}
    super.dispose();
  }
}
