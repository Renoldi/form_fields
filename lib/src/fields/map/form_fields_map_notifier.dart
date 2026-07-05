import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';

class FormFieldsMapNotifier extends ChangeNotifier {
  FormFieldsMapNotifier({
    List<Polygon>? polygons,
    List<Polyline>? polylines,
    List<CircleMarker>? circles,
    Map<String, Polygon>? polygonsMap,
    Map<String, Polyline>? polylinesMap,
    Map<String, CircleMarker>? circlesMap,
  })  : _polygonMap = polygonsMap ?? {},
        _polylineMap = polylinesMap ?? {},
        _circleMap = circlesMap ?? {} {
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

  void _safeNotify() {
    try {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.idle) {
        try {
          debugPrint(
              '[FormFieldsMapNotifier] notifyListeners controller=$_controllerId raw=${_rawMarkersCache.length}');
        } catch (_) {}
        notifyListeners();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            try {
              debugPrint(
                  '[FormFieldsMapNotifier] postFrame notifyListeners controller=$_controllerId raw=${_rawMarkersCache.length}');
            } catch (_) {}
            notifyListeners();
          } catch (_) {}
        });
      }
    } catch (_) {
      try {
        debugPrint(
            '[FormFieldsMapNotifier] fallback notifyListeners controller=$_controllerId raw=${_rawMarkersCache.length}');
        notifyListeners();
      } catch (_) {}
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
    _safeNotify();
  }

  void appendRawMarkers(List<dynamic> coords) {
    _ensureControlled();
    final combined = List<dynamic>.from(_rawMarkersCache)..addAll(coords);
    _rawMarkersCache = List<dynamic>.from(combined);
    _safeNotify();
  }

  void clearRawMarkers() {
    _ensureControlled();
    _rawMarkersCache = const [];
    _safeNotify();
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
    if (removed) _safeNotify();
    return removed;
  }

  set polygons(List<Polygon> p) {
    _ensureControlled();
    _polygonMap = {};
    for (var i = 0; i < p.length; i++) {
      _polygonMap['p\$i'] = p[i];
    }
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
  }

  set polylines(List<Polyline> p) {
    _ensureControlled();
    _polylineMap = {};
    for (var i = 0; i < p.length; i++) {
      _polylineMap['l\$i'] = p[i];
    }
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
  }

  set circles(List<CircleMarker> c) {
    _ensureControlled();
    _circleMap = {};
    for (var i = 0; i < c.length; i++) {
      _circleMap['c\$i'] = c[i];
    }
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
  }

  // Polygons
  String addPolygon(Polygon p) {
    _ensureControlled();
    final id = 'p\$${DateTime.now().microsecondsSinceEpoch}';
    _polygonMap[id] = p;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdatePolygon(String id, Polygon polygon) {
    _ensureControlled();
    _polygonMap[id] = polygon;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
  }

  Polygon? getPolygon(String id) => _polygonMap[id];

  bool removePolygon(String id) {
    _ensureControlled();
    final removed = _polygonMap.remove(id) != null;
    if (removed) {
      _polygonsCache = _polygonMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearPolygons() {
    _ensureControlled();
    _polygonMap.clear();
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
  }

  // Polylines
  String addPolyline(Polyline p) {
    _ensureControlled();
    final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
    _polylineMap[id] = p;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdatePolyline(String id, Polyline polyline) {
    _ensureControlled();
    _polylineMap[id] = polyline;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
  }

  Polyline? getPolyline(String id) => _polylineMap[id];

  bool removePolyline(String id) {
    _ensureControlled();
    final removed = _polylineMap.remove(id) != null;
    if (removed) {
      _polylinesCache = _polylineMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearPolylines() {
    _ensureControlled();
    _polylineMap.clear();
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
  }

  String addCircle(CircleMarker c) {
    _ensureControlled();
    final id = 'c\$${DateTime.now().microsecondsSinceEpoch}';
    _circleMap[id] = c;
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdateCircle(String id, CircleMarker circle) {
    _ensureControlled();
    _circleMap[id] = circle;
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
  }

  CircleMarker? getCircle(String id) => _circleMap[id];

  bool removeCircle(String id) {
    _ensureControlled();
    final removed = _circleMap.remove(id) != null;
    if (removed) {
      _circlesCache = _circleMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearCircles() {
    _ensureControlled();
    _circleMap.clear();
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
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
    _safeNotify();
  }

  String addMarker(Marker m) {
    _ensureControlled();
    final id = 'm\$${DateTime.now().microsecondsSinceEpoch}';
    _markerMap[id] = m;
    _markersCache = _markerMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdateMarker(String id, Marker marker) {
    _ensureControlled();
    _markerMap[id] = marker;
    _markersCache = _markerMap.values.toList(growable: false);
    _safeNotify();
  }

  Marker? getMarker(String id) => _markerMap[id];

  bool removeMarker(String id) {
    _ensureControlled();
    final removed = _markerMap.remove(id) != null;
    if (removed) {
      _markersCache = _markerMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearMarkers() {
    _ensureControlled();
    _markerMap.clear();
    _markersCache = _markerMap.values.toList(growable: false);
    _safeNotify();
  }
}
