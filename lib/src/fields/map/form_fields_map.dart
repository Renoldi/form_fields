import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';

// `FormFieldsMapController` is exported via the package public API.

/// ChangeNotifier holding map layer collections. Use with
/// `ChangeNotifierProvider` / `ChangeNotifierProvider.value`.
class FormFieldsMapNotifier extends ChangeNotifier {
  FormFieldsMapNotifier({
    List<Marker>? markers,
    List<Polygon>? polygons,
    List<Polyline>? polylines,
    List<CircleMarker>? circles,
    Map<String, Marker>? markersMap,
    Map<String, Polygon>? polygonsMap,
    Map<String, Polyline>? polylinesMap,
    Map<String, CircleMarker>? circlesMap,
  })  : _markerMap = markersMap ?? {},
        _polygonMap = polygonsMap ?? {},
        _polylineMap = polylinesMap ?? {},
        _circleMap = circlesMap ?? {} {
    if (markers != null) {
      for (var i = 0; i < markers.length; i++) {
        _markerMap['m\$i'] = markers[i];
      }
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
  }

  Map<String, Marker> _markerMap;
  Map<String, Polygon> _polygonMap;
  Map<String, Polyline> _polylineMap;
  Map<String, CircleMarker> _circleMap;

  List<Marker> get markers => _markerMap.values.toList(growable: false);
  List<Polygon> get polygons => _polygonMap.values.toList(growable: false);
  List<Polyline> get polylines => _polylineMap.values.toList(growable: false);
  List<CircleMarker> get circles => _circleMap.values.toList(growable: false);

  /// Replace all markers (IDs will be generated automatically).
  set markers(List<Marker> m) {
    _markerMap = {};
    for (var i = 0; i < m.length; i++) {
      _markerMap['m\$i'] = m[i];
    }
    notifyListeners();
  }

  set polygons(List<Polygon> p) {
    _polygonMap = {};
    for (var i = 0; i < p.length; i++) {
      _polygonMap['p\$i'] = p[i];
    }
    notifyListeners();
  }

  set polylines(List<Polyline> p) {
    _polylineMap = {};
    for (var i = 0; i < p.length; i++) {
      _polylineMap['l\$i'] = p[i];
    }
    notifyListeners();
  }

  set circles(List<CircleMarker> c) {
    _circleMap = {};
    for (var i = 0; i < c.length; i++) {
      _circleMap['c\$i'] = c[i];
    }
    notifyListeners();
  }

  /// Add a marker and return its generated ID.
  String addMarker(Marker m) {
    final id = 'm\$${DateTime.now().microsecondsSinceEpoch}';
    _markerMap[id] = m;
    notifyListeners();
    return id;
  }

  /// Add or replace marker with given ID.
  void addOrUpdateMarker(String id, Marker marker) {
    _markerMap[id] = marker;
    notifyListeners();
  }

  Marker? getMarker(String id) => _markerMap[id];

  bool removeMarker(String id) {
    final removed = _markerMap.remove(id) != null;
    if (removed) notifyListeners();
    return removed;
  }

  void clearMarkers() {
    _markerMap.clear();
    notifyListeners();
  }

  // Polygons
  String addPolygon(Polygon p) {
    final id = 'p\$${DateTime.now().microsecondsSinceEpoch}';
    _polygonMap[id] = p;
    notifyListeners();
    return id;
  }

  void addOrUpdatePolygon(String id, Polygon polygon) {
    _polygonMap[id] = polygon;
    notifyListeners();
  }

  Polygon? getPolygon(String id) => _polygonMap[id];

  bool removePolygon(String id) {
    final removed = _polygonMap.remove(id) != null;
    if (removed) notifyListeners();
    return removed;
  }

  void clearPolygons() {
    _polygonMap.clear();
    notifyListeners();
  }

  // Polylines
  String addPolyline(Polyline p) {
    final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
    _polylineMap[id] = p;
    notifyListeners();
    return id;
  }

  void addOrUpdatePolyline(String id, Polyline polyline) {
    _polylineMap[id] = polyline;
    notifyListeners();
  }

  Polyline? getPolyline(String id) => _polylineMap[id];

  bool removePolyline(String id) {
    final removed = _polylineMap.remove(id) != null;
    if (removed) notifyListeners();
    return removed;
  }

  void clearPolylines() {
    _polylineMap.clear();
    notifyListeners();
  }

  // Circles
  String addCircle(CircleMarker c) {
    final id = 'c\$${DateTime.now().microsecondsSinceEpoch}';
    _circleMap[id] = c;
    notifyListeners();
    return id;
  }

  void addOrUpdateCircle(String id, CircleMarker circle) {
    _circleMap[id] = circle;
    notifyListeners();
  }

  CircleMarker? getCircle(String id) => _circleMap[id];

  bool removeCircle(String id) {
    final removed = _circleMap.remove(id) != null;
    if (removed) notifyListeners();
    return removed;
  }

  void clearCircles() {
    _circleMap.clear();
    notifyListeners();
  }
}

/// A performant, reusable map widget tailored for FormFields.
///
/// Features:
/// - Persistent `MapController` (via `FormFieldsMapController.getOrCreate(id)`).
/// - `ChangeNotifier`-driven layers to avoid full map rebuilds.
/// - Customizable tile URL template (Google-friendly templates accepted).
/// - panBuffer / keepAlive / tile loading indicator and debounce camera idle.
class FormFieldsMap extends StatefulWidget {
  const FormFieldsMap({
    super.key,
    this.controllerId = 'default',
    this.tileUrlTemplate = 'https://mt1.google.com/vt/lyrs=r&x={x}&y={y}&z={z}',
    this.tileAttribution = '© Google',
    this.initialCenter = const LatLng(0, 0),
    this.initialZoom = 2,
    this.maxZoom = 19,
    this.minZoom = 1,
    this.panBuffer = 2,
    this.keepAlive = true,
    this.notifier,
    this.onMapReady,
    this.onPositionChanged,
    this.onTap,
    this.onLongPress,
    this.onCameraIdle,
    this.cameraIdleDebounce = const Duration(milliseconds: 350),
    this.showMyLocation = false,
    this.myLocationMarker,
  });

  final String controllerId;
  final String tileUrlTemplate;
  final String tileAttribution;
  final LatLng initialCenter;
  final double initialZoom;
  final double maxZoom;
  final double minZoom;
  final int panBuffer;
  final bool keepAlive;

  /// Optional ChangeNotifier to manage layers (`FormFieldsMapNotifier`).
  /// If omitted, a fresh `FormFieldsMapNotifier` is created for this widget.
  final FormFieldsMapNotifier? notifier;

  final VoidCallback? onMapReady;
  final ValueChanged<dynamic>? onPositionChanged;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onLongPress;
  final VoidCallback? onCameraIdle;
  final Duration cameraIdleDebounce;

  /// Simple location layer toggle. Provide a custom marker if desired.
  final bool showMyLocation;
  final Marker? myLocationMarker;

  @override
  FormFieldsMapState createState() => FormFieldsMapState();
}

class FormFieldsMapState extends State<FormFieldsMap>
    with AutomaticKeepAliveClientMixin<FormFieldsMap> {
  late final MapController _mapController;
  Timer? _debounceTimer;

  // Track last known center/zoom to support zoom controls without relying
  // on MapController internals (some flutter_map versions differ).
  LatLng? _lastCenter;
  double? _lastZoom;

  // Loading state is shared via FormFieldsMapController so external
  // viewmodels can toggle it and the widget's ValueListenableBuilder will
  // react accordingly.

  @override
  void initState() {
    super.initState();
    _mapController = FormFieldsMapController.getOrCreate(widget.controllerId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure map starts at requested position in a version-agnostic way.
      try {
        _mapController.move(widget.initialCenter, widget.initialZoom);
      } catch (_) {}
      widget.onMapReady?.call();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;

  void _onPositionChanged(dynamic position, bool hasGesture) {
    widget.onPositionChanged?.call(position);
    // Try to extract center/zoom from position if available.
    try {
      // MapPosition has `center` and `zoom` on many flutter_map versions.
      final dynamic pos = position;
      if (pos != null) {
        if (pos.center != null) {
          _lastCenter = pos.center as LatLng;
        }
        if (pos.zoom != null) {
          _lastZoom = (pos.zoom as num).toDouble();
        }
      }
    } catch (_) {}
    // indicate loading while user moves/pans/zooms; will be cleared on camera idle
    FormFieldsMapController.setLoading(widget.controllerId, true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.cameraIdleDebounce, () {
      FormFieldsMapController.setLoading(widget.controllerId, false);
      widget.onCameraIdle?.call();
    });
  }

  // Animate move: simple linear interpolation over duration.
  Future<void> animateTo(LatLng dest, double zoom,
      {Duration duration = const Duration(milliseconds: 400)}) async {
    // Avoid reading controller internals (center/zoom) to remain compatible
    // with different `flutter_map` versions. Use direct move call which most
    // versions support. Animated interpolation may be provided by consumers
    // or by newer flutter_map APIs; keep this simple and reliable.
    _mapController.move(dest, zoom);
    _lastCenter = dest;
    _lastZoom = zoom;
  }

  Future<void> fitBounds(LatLngBounds bounds,
      {EdgeInsets padding = EdgeInsets.zero,
      Duration duration = const Duration(milliseconds: 400)}) async {
    final center = bounds.center;
    // simplistic zoom calculation: zoom to fit by reducing to a conservative value
    // For precision, consumers can calculate exact zoom and call animateTo.
    final targetZoom = widget.initialZoom;
    await animateTo(center, targetZoom, duration: duration);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tileProvider = NetworkTileProvider();

    final notifier = widget.notifier ?? FormFieldsMapNotifier();

    return Stack(
      children: [
        ChangeNotifierProvider<FormFieldsMapNotifier>.value(
          value: notifier,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Minimal options for broad compatibility; initial position set via controller in initState.
              onPositionChanged: (pos, hasGesture) =>
                  _onPositionChanged(pos, hasGesture),
              onTap: (_, latlng) => widget.onTap?.call(latlng),
              onLongPress: (_, latlng) => widget.onLongPress?.call(latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: widget.tileUrlTemplate,
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                tileProvider: tileProvider,
                maxZoom: widget.maxZoom,
                minZoom: widget.minZoom,
              ),

              // Markers (rebuilds only when markers list changes)
              Selector<FormFieldsMapNotifier, List<Marker>>(
                selector: (_, n) => n.markers,
                builder: (context, markers, _) {
                  if (markers.isEmpty) return const SizedBox.shrink();
                  return MarkerLayer(markers: markers);
                },
              ),

              // Polygons
              Selector<FormFieldsMapNotifier, List<Polygon>>(
                selector: (_, n) => n.polygons,
                builder: (context, polygons, _) {
                  if (polygons.isEmpty) return const SizedBox.shrink();
                  return PolygonLayer(polygons: polygons);
                },
              ),

              // Polylines
              Selector<FormFieldsMapNotifier, List<Polyline>>(
                selector: (_, n) => n.polylines,
                builder: (context, polylines, _) {
                  if (polylines.isEmpty) return const SizedBox.shrink();
                  return PolylineLayer(polylines: polylines);
                },
              ),

              // Circles
              Selector<FormFieldsMapNotifier, List<CircleMarker>>(
                selector: (_, n) => n.circles,
                builder: (context, circles, _) {
                  if (circles.isEmpty) return const SizedBox.shrink();
                  return CircleLayer(circles: circles);
                },
              ),

              // Optional my-location marker
              if (widget.showMyLocation) _buildMyLocationLayer(),
            ],
          ),
        ),
        // Loading indicator overlay when camera is active (debounced)
        // Zoom controls
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                type: AppButtonType.fab,
                size: AppSize.small,
                icon: const Icon(Icons.add),
                useSafeArea: false,
                heroTag: null,
                onPressed: () {
                  final center = _lastCenter ?? widget.initialCenter;
                  final currentZoom = _lastZoom ?? widget.initialZoom;
                  final newZoom =
                      (currentZoom + 1).clamp(widget.minZoom, widget.maxZoom);
                  animateTo(center, newZoom);
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                type: AppButtonType.fab,
                size: AppSize.small,
                icon: const Icon(Icons.remove),
                useSafeArea: false,
                heroTag: null,
                onPressed: () {
                  final center = _lastCenter ?? widget.initialCenter;
                  final currentZoom = _lastZoom ?? widget.initialZoom;
                  final newZoom =
                      (currentZoom - 1).clamp(widget.minZoom, widget.maxZoom);
                  animateTo(center, newZoom);
                },
              ),
            ],
          ),
        ),

        ValueListenableBuilder<bool>(
          valueListenable:
              FormFieldsMapController.getLoadingListenable(widget.controllerId),
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Positioned(
                right: 12,
                top: 12,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildMyLocationLayer() {
    if (widget.myLocationMarker != null) {
      return MarkerLayer(markers: [widget.myLocationMarker!]);
    }
    return const SizedBox.shrink();
  }
}

/// TileProvider that tracks ongoing tile loads via callbacks.
// No custom TileProvider: use NetworkTileProvider for compatibility with latest flutter_map.
