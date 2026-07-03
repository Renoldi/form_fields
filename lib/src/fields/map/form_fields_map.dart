import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'canvas_kdtree.dart';

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
    // initialize caches
    _markersCache = _markerMap.values.toList(growable: false);
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _circlesCache = _circleMap.values.toList(growable: false);
  }

  Map<String, Marker> _markerMap;
  Map<String, Polygon> _polygonMap;
  Map<String, Polyline> _polylineMap;
  Map<String, CircleMarker> _circleMap;
  // Cached lists to avoid allocating new List objects on every getter call.
  List<Marker> _markersCache = const [];
  // Raw marker coordinates for high-performance canvas rendering.
  // Each entry may be one of:
  // - List<double> [lat, lon]
  // - List [lat, lon, title?, subtitle?]
  // - Map {'lat':..., 'lon':..., 'title':..., 'subtitle':...}
  // - LatLng or Marker
  List<dynamic> _rawMarkersCache = const [];
  List<Polygon> _polygonsCache = const [];
  List<Polyline> _polylinesCache = const [];
  List<CircleMarker> _circlesCache = const [];

  List<Marker> get markers => _markersCache;
  List<dynamic> get rawMarkers => _rawMarkersCache;
  List<Polygon> get polygons => _polygonsCache;
  List<Polyline> get polylines => _polylinesCache;
  List<CircleMarker> get circles => _circlesCache;

  /// Replace all markers (IDs will be generated automatically).
  set markers(List<Marker> m) {
    _markerMap = {};
    for (var i = 0; i < m.length; i++) {
      _markerMap['m\$i'] = m[i];
    }
    _markersCache = _markerMap.values.toList(growable: false);
    notifyListeners();
  }

  /// Replace raw marker coordinates. Entries may include optional title/subtitle.
  set rawMarkers(List<dynamic> coords) {
    _rawMarkersCache = coords;
    notifyListeners();
  }

  /// Append raw marker coordinates (or labeled entries).
  void appendRawMarkers(List<dynamic> coords) {
    final combined = List<dynamic>.from(_rawMarkersCache)..addAll(coords);
    _rawMarkersCache = List<dynamic>.from(combined);
    notifyListeners();
  }

  void clearRawMarkers() {
    _rawMarkersCache = const [];
    notifyListeners();
  }

  set polygons(List<Polygon> p) {
    _polygonMap = {};
    for (var i = 0; i < p.length; i++) {
      _polygonMap['p\$i'] = p[i];
    }
    _polygonsCache = _polygonMap.values.toList(growable: false);
    notifyListeners();
  }

  set polylines(List<Polyline> p) {
    _polylineMap = {};
    for (var i = 0; i < p.length; i++) {
      _polylineMap['l\$i'] = p[i];
    }
    _polylinesCache = _polylineMap.values.toList(growable: false);
    notifyListeners();
  }

  set circles(List<CircleMarker> c) {
    _circleMap = {};
    for (var i = 0; i < c.length; i++) {
      _circleMap['c\$i'] = c[i];
    }
    _circlesCache = _circleMap.values.toList(growable: false);
    notifyListeners();
  }

  /// Add a marker and return its generated ID.
  String addMarker(Marker m) {
    final id = 'm\$${DateTime.now().microsecondsSinceEpoch}';
    _markerMap[id] = m;
    _markersCache = _markerMap.values.toList(growable: false);
    notifyListeners();
    return id;
  }

  /// Add or replace marker with given ID.
  void addOrUpdateMarker(String id, Marker marker) {
    _markerMap[id] = marker;
    _markersCache = _markerMap.values.toList(growable: false);
    notifyListeners();
  }

  Marker? getMarker(String id) => _markerMap[id];

  bool removeMarker(String id) {
    final removed = _markerMap.remove(id) != null;
    if (removed) {
      _markersCache = _markerMap.values.toList(growable: false);
      notifyListeners();
    }
    return removed;
  }

  void clearMarkers() {
    _markerMap.clear();
    _markersCache = const [];
    notifyListeners();
  }

  // Polygons
  String addPolygon(Polygon p) {
    final id = 'p\$${DateTime.now().microsecondsSinceEpoch}';
    _polygonMap[id] = p;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    notifyListeners();
    return id;
  }

  void addOrUpdatePolygon(String id, Polygon polygon) {
    _polygonMap[id] = polygon;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    notifyListeners();
  }

  Polygon? getPolygon(String id) => _polygonMap[id];

  bool removePolygon(String id) {
    final removed = _polygonMap.remove(id) != null;
    if (removed) {
      _polygonsCache = _polygonMap.values.toList(growable: false);
      notifyListeners();
    }
    return removed;
  }

  void clearPolygons() {
    _polygonMap.clear();
    _polygonsCache = const [];
    notifyListeners();
  }

  // Polylines
  String addPolyline(Polyline p) {
    final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
    _polylineMap[id] = p;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    notifyListeners();
    return id;
  }

  void addOrUpdatePolyline(String id, Polyline polyline) {
    _polylineMap[id] = polyline;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    notifyListeners();
  }

  Polyline? getPolyline(String id) => _polylineMap[id];

  bool removePolyline(String id) {
    final removed = _polylineMap.remove(id) != null;
    if (removed) {
      _polylinesCache = _polylineMap.values.toList(growable: false);
      notifyListeners();
    }
    return removed;
  }

  void clearPolylines() {
    _polylineMap.clear();
    _polylinesCache = const [];
    notifyListeners();
  }

  // Circles
  String addCircle(CircleMarker c) {
    final id = 'c\$${DateTime.now().microsecondsSinceEpoch}';
    _circleMap[id] = c;
    _circlesCache = _circleMap.values.toList(growable: false);
    notifyListeners();
    return id;
  }

  void addOrUpdateCircle(String id, CircleMarker circle) {
    _circleMap[id] = circle;
    _circlesCache = _circleMap.values.toList(growable: false);
    notifyListeners();
  }

  CircleMarker? getCircle(String id) => _circleMap[id];

  bool removeCircle(String id) {
    final removed = _circleMap.remove(id) != null;
    if (removed) {
      _circlesCache = _circleMap.values.toList(growable: false);
      notifyListeners();
    }
    return removed;
  }

  void clearCircles() {
    _circleMap.clear();
    _circlesCache = const [];
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
    this.useCanvasMarkers = false,
    this.canvasMarkerRadius = 4.0,
    this.canvasMarkerIcon,
    this.useViewportCulling = true,
    this.cullingBuffer = 1.25,
    this.notifier,
    this.onMapReady,
    this.onPositionChanged,
    this.onTap,
    this.onMarkerTap,
    this.onLongPress,
    this.onCameraIdle,
    this.cameraIdleDebounce = const Duration(milliseconds: 350),
    this.showMyLocation = false,
    this.myLocationMarker,
    this.onRequestCurrentLocation,
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

  /// When true, markers will be rendered using a high-performance canvas
  /// layer (CustomPainter) instead of Flutter widgets. Best for very large
  /// marker counts when markers are simple points and don't need complex
  /// widget builders or individual interactivity.
  final bool useCanvasMarkers;

  /// Radius in logical pixels for canvas-rendered markers.
  final double canvasMarkerRadius;

  /// Optional image/widget used for canvas-rendered markers. If provided,
  /// the painter will draw this image centered at each marker instead of
  /// the default pin shape. Accepts:
  /// - an [ImageProvider] (AssetImage, NetworkImage, MemoryImage, etc.),
  /// - an `Icon` widget (e.g. `const Icon(Icons.location_pin, color: Colors.red, size: 36)`),
  /// - any other `Widget` which will be rasterized to an image and used by
  ///   the painter.
  final Object? canvasMarkerIcon;

  /// When true, the widget will try to cull markers outside the viewport
  /// using a fast degree-based approximation before building `MarkerLayer`.
  final bool useViewportCulling;

  /// Multiplier applied to the half-viewport angular size when culling.
  /// Values >1 add extra buffer to avoid popping markers during small pans.
  final double cullingBuffer;

  /// Optional ChangeNotifier to manage layers (`FormFieldsMapNotifier`).
  /// If omitted, a fresh `FormFieldsMapNotifier` is created for this widget.
  final FormFieldsMapNotifier? notifier;
  final ValueChanged<dynamic>? onMarkerTap;

  final VoidCallback? onMapReady;
  final ValueChanged<dynamic>? onPositionChanged;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onLongPress;
  final VoidCallback? onCameraIdle;
  final Duration cameraIdleDebounce;

  /// Simple location layer toggle. Provide a custom marker if desired.
  final bool showMyLocation;
  final Marker? myLocationMarker;

  /// Optional async callback used to obtain the device's current location
  /// when the built-in current-location button is pressed. If omitted and
  /// `myLocationMarker` is provided, the widget will center on that marker.
  final Future<LatLng>? Function()? onRequestCurrentLocation;

  @override
  FormFieldsMapState createState() => FormFieldsMapState();
}

class FormFieldsMapState extends State<FormFieldsMap>
    with AutomaticKeepAliveClientMixin<FormFieldsMap> {
  late final MapController _mapController;
  Timer? _debounceTimer;
  // Internal notifier used when the consumer doesn't supply one. We keep a
  // persistent instance to avoid recreating a new notifier on every build
  // (which can cause notifyListeners/setState to fire during framework
  // builds and trigger the "setState() or markNeedsBuild() called during
  // build" exception).
  late FormFieldsMapNotifier _internalNotifier;
  bool _ownsInternalNotifier = false;

  // Track last known center/zoom to support zoom controls without relying
  // on MapController internals (some flutter_map versions differ).
  LatLng? _lastCenter;
  double? _lastZoom;
  KDTree? _kdTree;
  double? _kdTreeZoom;
  ui.Image? _canvasMarkerImage;
  ImageStream? _canvasMarkerImageStream;
  ImageStreamListener? _canvasMarkerImageStreamListener;

  // Loading state is shared via FormFieldsMapController so external
  // viewmodels can toggle it and the widget's ValueListenableBuilder will
  // react accordingly.

  @override
  void initState() {
    super.initState();
    _mapController = FormFieldsMapController.getOrCreate(widget.controllerId);
    // Create or reuse an internal notifier once to avoid allocating a new
    // notifier on each build.
    _ownsInternalNotifier = widget.notifier == null;
    _internalNotifier = widget.notifier ?? FormFieldsMapNotifier();
    _resolveCanvasMarkerIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure map starts at requested position in a version-agnostic way.
      try {
        _mapController.move(widget.initialCenter, widget.initialZoom);
      } catch (_) {}
      widget.onMapReady?.call();
    });
    // Register onMarkerTap handler so external marker widgets can call
    // FormFieldsMapController.invokeOnMarkerTap(id, payload) and have the
    // map-level callback receive it.
    FormFieldsMapController.registerOnMarkerTap(
        widget.controllerId, (payload) => widget.onMarkerTap?.call(payload));
  }

  @override
  void didUpdateWidget(covariant FormFieldsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canvasMarkerIcon != widget.canvasMarkerIcon) {
      _resolveCanvasMarkerIcon();
    }
    // If the user supplied a different notifier, update the internal
    // reference and dispose the previously owned one if necessary.
    if (oldWidget.notifier != widget.notifier) {
      if (_ownsInternalNotifier) {
        try {
          _internalNotifier.dispose();
        } catch (_) {}
      }
      _ownsInternalNotifier = widget.notifier == null;
      _internalNotifier = widget.notifier ?? FormFieldsMapNotifier();
    }
    // If controller id or onMarkerTap changed, update registration.
    if (oldWidget.controllerId != widget.controllerId ||
        oldWidget.onMarkerTap != widget.onMarkerTap) {
      FormFieldsMapController.removeOnMarkerTap(oldWidget.controllerId);
      FormFieldsMapController.registerOnMarkerTap(
          widget.controllerId, (payload) => widget.onMarkerTap?.call(payload));
    }
  }

  void _resolveCanvasMarkerIcon() {
    // Remove previous listener if any.
    if (_canvasMarkerImageStream != null &&
        _canvasMarkerImageStreamListener != null) {
      _canvasMarkerImageStream!
          .removeListener(_canvasMarkerImageStreamListener!);
    }
    _canvasMarkerImageStream = null;
    _canvasMarkerImageStreamListener = null;
    _canvasMarkerImage = null;
    final provider = widget.canvasMarkerIcon;
    if (provider == null) return;

    // If an ImageProvider is supplied, resolve it as before.
    if (provider is ImageProvider) {
      final config = createLocalImageConfiguration(context);
      final stream = provider.resolve(config);
      _canvasMarkerImageStream = stream;
      _canvasMarkerImageStreamListener =
          ImageStreamListener((ImageInfo info, bool _) {
        _canvasMarkerImage = info.image;
        if (mounted) setState(() {});
      });
      stream.addListener(_canvasMarkerImageStreamListener!);
      return;
    }

    // If an Icon widget (or IconData) is supplied, rasterize it to a ui.Image.
    if (provider is Icon) {
      _renderIconToImage(provider).then((img) {
        _canvasMarkerImage = img;
        if (mounted) setState(() {});
      });
      return;
    }

    // If an arbitrary widget is provided, rasterize it via an Overlay
    // so consumers can pass any widget (e.g., custom composed markers).
    if (provider is Widget) {
      _rasterizeWidgetToImage(provider).then((img) {
        if (img != null) {
          _canvasMarkerImage = img;
          if (mounted) setState(() {});
        }
      });
      return;
    }
  }

  Future<ui.Image> _renderIconToImage(Icon icon) async {
    final iconData = icon.icon;
    final double size = icon.size ?? 24.0;
    final Color color = icon.color ?? Colors.black;

    if (iconData == null) {
      // draw a simple circle fallback
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = color;
      final double r = size / 2.0;
      canvas.drawCircle(Offset(r, r), r, paint);
      final picture = recorder.endRecording();
      return picture.toImage(size.ceil(), size.ceil());
    }

    final textStyle = TextStyle(
      fontFamily: iconData.fontFamily,
      package: iconData.fontPackage,
      fontSize: size,
      color: color,
    );

    final tp = TextPainter(
      text: TextSpan(
          text: String.fromCharCode(iconData.codePoint), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final w = tp.width.ceil();
    final h = tp.height.ceil();
    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    tp.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w == 0 ? 1 : w, h == 0 ? 1 : h);
    return image;
  }

  Future<ui.Image?> _rasterizeWidgetToImage(Widget widget,
      {double logicalSize = 36.0}) async {
    try {
      // Do not access `State.context` across async gaps without verifying
      // the state is still mounted. Bail out early if not mounted.
      if (!mounted) return null;

      final overlay = Overlay.of(context);

      final key = GlobalKey();
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final entry = OverlayEntry(
        builder: (ctx) => Positioned(
          left: 0,
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: logicalSize,
                height: logicalSize,
                child: RepaintBoundary(
                  key: key,
                  child: Center(child: widget),
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);
      // Wait a frame so the widget is laid out and painted.
      await Future.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      // After awaiting, the original State may have been unmounted. If so,
      // remove the overlay entry and bail out.
      if (!mounted) {
        entry.remove();
        return null;
      }

      final contextForKey = key.currentContext;
      if (contextForKey == null) {
        entry.remove();
        return null;
      }

      // Require the grabbed context to be an Element and to be mounted
      // before using it across async gaps.
      if (contextForKey is! Element || !contextForKey.mounted) {
        entry.remove();
        return null;
      }

      final renderObject = contextForKey.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        final img = await renderObject.toImage(pixelRatio: devicePixelRatio);
        entry.remove();
        return img;
      }
      entry.remove();
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_canvasMarkerImageStream != null &&
        _canvasMarkerImageStreamListener != null) {
      _canvasMarkerImageStream!
          .removeListener(_canvasMarkerImageStreamListener!);
    }
    if (_ownsInternalNotifier) {
      try {
        _internalNotifier.dispose();
      } catch (_) {}
    }
    FormFieldsMapController.removeOnMarkerTap(widget.controllerId);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;

  void _onPositionChanged(dynamic position, bool hasGesture) {
    widget.onPositionChanged?.call(position);
    // Try to extract center/zoom from position if available.
    try {
      final dynamic pos = position;
      if (pos != null) {
        if (pos.center != null) {
          _lastCenter = pos.center as LatLng;
        }
        if (pos.zoom != null) {
          _lastZoom = (pos.zoom as num).toDouble();
        }
        // Trigger a rebuild so canvas layers receiving `center`/`zoom`
        // get updated and repaint when the map moves. Schedule the
        // rebuild and loading indicator update to the next frame to
        // avoid calling setState during the framework's build phase.
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              FormFieldsMapController.setLoading(widget.controllerId, true);
            } catch (_) {}
            if (mounted) setState(() {});
          });
        }
      }
    } catch (_) {}
    // indicate loading while user moves/pans/zooms; will be cleared on camera idle
    // (already scheduled above when appropriate).
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

    final notifier = widget.notifier ?? _internalNotifier;
    // Ensure the controller has the latest onMarkerTap handler registered.
    FormFieldsMapController.registerOnMarkerTap(
        widget.controllerId, (payload) => widget.onMarkerTap?.call(payload));

    return Stack(
      children: [
        ChangeNotifierProvider<FormFieldsMapNotifier>.value(
          value: notifier,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Provide initial center/zoom directly so the map is visible
              // immediately. Some flutter_map versions may ignore early
              // MapController.move calls, so setting options is more reliable.
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              onPositionChanged: (pos, hasGesture) =>
                  _onPositionChanged(pos, hasGesture),
              onTap: (tapPos, latlng) => _handleTap(tapPos, latlng),
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
              if (widget.useCanvasMarkers)
                Consumer<FormFieldsMapNotifier>(
                  builder: (context, notifier, _) {
                    final rawMarkers = notifier.rawMarkers;
                    if (rawMarkers.isEmpty) return const SizedBox.shrink();
                    final curZoom = _lastZoom ?? widget.initialZoom;

                    // Build KD-tree after the current build frame to avoid
                    // mutating state or triggering markNeedsBuild during
                    // the framework's build phase. If a tap happens before
                    // the KD-tree is ready, fallback hit-testing will apply.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      // Avoid rebuilding the KD-tree unnecessarily when zoom
                      // hasn't changed and we already have a tree.
                      if (_kdTreeZoom == curZoom && _kdTree != null) return;
                      _kdTree = buildKDTreeFromRawCoords(
                          rawMarkers,
                          curZoom,
                          _CanvasMarkerPainter._worldX,
                          _CanvasMarkerPainter._worldY);
                      _kdTreeZoom = curZoom;
                    });

                    return _CanvasRawMarkerLayer(
                      rawMarkers: rawMarkers,
                      center: _lastCenter ?? widget.initialCenter,
                      zoom: curZoom,
                      radius: widget.canvasMarkerRadius,
                      iconImage: _canvasMarkerImage,
                    );
                  },
                )
              else
                Selector<FormFieldsMapNotifier, List<Marker>>(
                  selector: (_, n) => n.markers,
                  builder: (context, markers, _) {
                    if (markers.isEmpty) return const SizedBox.shrink();

                    if (!widget.useViewportCulling) {
                      return MarkerLayer(markers: markers);
                    }

                    final center = _lastCenter ?? widget.initialCenter;
                    final zoom = _lastZoom ?? widget.initialZoom;
                    final degPerWorld = 360 / pow(2, zoom).toDouble();
                    final halfViewportDeg = degPerWorld / 2;
                    final buffer = widget.cullingBuffer;
                    final radiusDeg = halfViewportDeg * buffer;

                    final visible = markers.where((m) {
                      final lat = m.point.latitude;
                      final lng = m.point.longitude;
                      return (lat - center.latitude).abs() <= radiusDeg &&
                          (lng - center.longitude).abs() <= radiusDeg;
                    }).toList(growable: false);

                    if (visible.isEmpty) return const SizedBox.shrink();
                    return MarkerLayer(markers: visible);
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
              // Current zoom display
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 6.0),
                  child: Text(
                    'Zoom: ${(_lastZoom ?? widget.initialZoom).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
              // Current location button
              AppButton(
                type: AppButtonType.fab,
                size: AppSize.small,
                icon: const Icon(Icons.my_location),
                useSafeArea: false,
                heroTag: null,
                onPressed: () async {
                  // Avoid using `BuildContext` across async gaps: capture the
                  // ScaffoldMessenger synchronously and check `mounted` after
                  // any awaits.
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  LatLng? target;
                  if (widget.myLocationMarker != null) {
                    target = widget.myLocationMarker!.point;
                  } else if (widget.onRequestCurrentLocation != null) {
                    try {
                      target = await widget.onRequestCurrentLocation!();
                    } catch (_) {
                      target = null;
                    }
                  }
                  if (!mounted) return;
                  if (target != null) {
                    final currentZoom = _lastZoom ?? widget.initialZoom;
                    await animateTo(target, currentZoom);
                    return;
                  }
                  messenger?.showSnackBar(const SnackBar(
                      content: Text('Current location not available')));
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

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    // First try marker hit-testing when canvas markers are active.
    if (widget.useCanvasMarkers && _kdTree != null) {
      final tapZoom = _lastZoom ?? widget.initialZoom;
      // KD-tree was built at _kdTreeZoom; convert query coordinates into
      // the same world-pixel space as the KD-tree to avoid rebuilding.
      final qxTap = _CanvasMarkerPainter._worldX(latlng.longitude, tapZoom);
      final qyTap = _CanvasMarkerPainter._worldY(latlng.latitude, tapZoom);

      double qx = qxTap;
      double qy = qyTap;
      final kdZoom = _kdTreeZoom ?? tapZoom;
      if (kdZoom != tapZoom) {
        final double scale = pow(2, kdZoom - tapZoom).toDouble();
        qx = qxTap * scale;
        qy = qyTap * scale;
      }

      final double worldSize = 256 * pow(2, kdZoom).toDouble();

      dynamic hit;
      dynamic hitCandidate;
      double? hitCandLat;
      double? hitCandLon;
      // Query at three wrapped X positions to account for antimeridian.
      // We query the KD-tree with a large radius (worldSize) and then
      // validate the nearest candidate in screen coordinates against the
      // configured `canvasMarkerRadius`.
      for (final wrap in [0.0, -worldSize, worldSize]) {
        final candidate = _kdTree!.nearest(qx + wrap, qy, worldSize);
        if (candidate == null) continue;

        double candLon;
        double candLat;
        if (candidate is Marker) {
          candLon = candidate.point.longitude;
          candLat = candidate.point.latitude;
        } else if (candidate is LatLng) {
          candLon = candidate.longitude;
          candLat = candidate.latitude;
        } else if (candidate is List && candidate.length >= 2) {
          candLat = (candidate[0] as num).toDouble();
          candLon = (candidate[1] as num).toDouble();
        } else if (candidate is Map) {
          candLat = (candidate['lat'] as num?)?.toDouble() ??
              (candidate['latitude'] as num?)?.toDouble() ??
              0.0;
          candLon = (candidate['lon'] as num?)?.toDouble() ??
              (candidate['longitude'] as num?)?.toDouble() ??
              0.0;
        } else {
          continue;
        }

        // Candidate world coords at KD zoom
        final candX = _CanvasMarkerPainter._worldX(candLon, kdZoom);
        final candY = _CanvasMarkerPainter._worldY(candLat, kdZoom);
        final centerLon = (_lastCenter ?? widget.initialCenter).longitude;
        final centerLat = (_lastCenter ?? widget.initialCenter).latitude;
        final centerX = _CanvasMarkerPainter._worldX(centerLon, kdZoom);
        final centerY = _CanvasMarkerPainter._worldY(centerLat, kdZoom);

        var candDx = (candX - centerX) + (context.size?.width ?? 0) / 2;
        var candDy = (candY - centerY) + (context.size?.height ?? 0) / 2;

        // wrap-around correction
        if (candDx.abs() > worldSize / 2) {
          if (candDx > 0) {
            candDx -= worldSize;
          } else {
            candDx += worldSize;
          }
        }

        Offset localPos;
        try {
          localPos = (tapPosition as dynamic).localPosition as Offset;
        } catch (_) {
          try {
            localPos = (tapPosition as dynamic).local as Offset;
          } catch (_) {
            localPos = Offset((context.size?.width ?? 0) / 2,
                (context.size?.height ?? 0) / 2);
          }
        }
        final dist =
            sqrt(pow(candDx - localPos.dx, 2) + pow(candDy - localPos.dy, 2));
        if (dist <= widget.canvasMarkerRadius) {
          // Create a lightweight tap result with a `point` property so
          // consumers can access `.point.latitude` / `.point.longitude`.
          hit = _TapResult(LatLng(candLat, candLon));
          hitCandidate = candidate;
          hitCandLat = candLat;
          hitCandLon = candLon;
          break;
        }
      }

      if (hit != null) {
        // Normalize the hit into a Map payload so consumers receive the
        // same shape as widget markers (title, subtitle, point), but also
        // keep any extra metadata (like `id` or `shapeType`) if present.
        final cand = hitCandidate;
        final payload = <String, dynamic>{};
        if (cand is Map) {
          payload.addAll(Map<String, dynamic>.from(cand));
        } else if (cand is List && cand.length >= 3) {
          payload['title'] = cand[2]?.toString();
          if (cand.length >= 4) payload['subtitle'] = cand[3]?.toString();
        }
        payload['point'] = LatLng(hitCandLat ?? 0.0, hitCandLon ?? 0.0);

        // Invoke via controller so both example widget markers and canvas
        // markers use the same delivery path.
        FormFieldsMapController.invokeOnMarkerTap(widget.controllerId, payload);
        return;
      }
    }

    // Fallback: regular map tap callback
    // If no marker hit, try shapes (polygons / polylines / circles)
    try {
      final notifier = widget.notifier ?? _internalNotifier;

      // Polygons: point-in-polygon test
      for (final entry in notifier._polygonMap.entries) {
        final pid = entry.key;
        final poly = entry.value;
        if (_pointInPolygon(latlng, poly.points)) {
          // try to find metadata in rawMarkers if present
          final meta = _findMetaForShape(notifier, pid);
          final payload = <String, dynamic>{'id': pid, 'type': 'polygon'};
          if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
          payload['point'] = latlng;
          FormFieldsMapController.invokeOnMarkerTap(
              widget.controllerId, payload);
          return;
        }
      }

      // Polylines: approximate by checking distance to segment midpoints
      const threshMeters = 20.0;
      final distance = Distance();
      for (final entry in notifier._polylineMap.entries) {
        final lid = entry.key;
        final pl = entry.value;
        final pts = pl.points;
        for (var i = 0; i < pts.length - 1; i++) {
          final mid = LatLng((pts[i].latitude + pts[i + 1].latitude) / 2,
              (pts[i].longitude + pts[i + 1].longitude) / 2);
          final d = distance.distance(mid, latlng);
          if (d <= threshMeters) {
            final meta = _findMetaForShape(notifier, lid);
            final payload = <String, dynamic>{'id': lid, 'type': 'polyline'};
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            FormFieldsMapController.invokeOnMarkerTap(
                widget.controllerId, payload);
            return;
          }
        }
      }

      // Circles: distance to center (meters if useRadiusInMeter true)
      for (final entry in notifier._circleMap.entries) {
        final cid = entry.key;
        final c = entry.value;
        final center = c.point;
        final d = distance.distance(center, latlng);
        if (c.useRadiusInMeter) {
          if (d <= c.radius) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{'id': cid, 'type': 'circle'};
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            FormFieldsMapController.invokeOnMarkerTap(
                widget.controllerId, payload);
            return;
          }
        } else {
          // radius in pixels/deg: approximate with small threshold
          final approxDeg = 0.01; // conservative fallback
          final latDiff = (center.latitude - latlng.latitude).abs();
          final lonDiff = (center.longitude - latlng.longitude).abs();
          if (sqrt(latDiff * latDiff + lonDiff * lonDiff) <= approxDeg) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{'id': cid, 'type': 'circle'};
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            FormFieldsMapController.invokeOnMarkerTap(
                widget.controllerId, payload);
            return;
          }
        }
      }
    } catch (_) {}

    widget.onTap?.call(latlng);
  }

  dynamic _findMetaForShape(FormFieldsMapNotifier notifier, String id) {
    // rawMarkers may contain a Map with an `id` pointing to shape metadata.
    for (final m in notifier.rawMarkers) {
      if (m is Map && m['id'] == id) return m;
    }
    return null;
  }

  bool _pointInPolygon(LatLng p, List<LatLng> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect = ((yi > p.latitude) != (yj > p.latitude)) &&
          (p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  Widget _buildMyLocationLayer() {
    if (widget.myLocationMarker != null) {
      return MarkerLayer(markers: [widget.myLocationMarker!]);
    }
    return const SizedBox.shrink();
  }
}

/// High-performance canvas layer that draws simple markers directly with
/// a [CustomPainter]. Designed for large numbers of non-interactive points.
///
/// Note: the raw-coordinate `_CanvasRawMarkerLayer` is preferred for very
/// large datasets to avoid allocating thousands of `Marker` widgets.

class _CanvasMarkerPainter extends CustomPainter {
  _CanvasMarkerPainter({
    required this.markers,
    required this.center,
    required this.zoom,
    required this.radius,
    required this.devicePixelRatio,
  });

  final List<Marker> markers;
  final LatLng center;
  final double zoom;
  final double radius;
  final double devicePixelRatio;

  static double _worldX(double lon, double zoom) {
    final double worldSize = 256 * pow(2, zoom).toDouble();
    return (lon + 180) / 360 * worldSize;
  }

  static double _worldY(double lat, double zoom) {
    final double worldSize = 256 * pow(2, zoom).toDouble();
    final sinLat = sin(lat * pi / 180);
    final y = 0.5 - (log((1 + sinLat) / (1 - sinLat)) / (4 * pi));
    return y * worldSize;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withValues(alpha: 0.9);

    final centerX = _worldX(center.longitude, zoom);
    final centerY = _worldY(center.latitude, zoom);
    final double worldSize = 256 * pow(2, zoom).toDouble();

    for (var m in markers) {
      final x = _worldX(m.point.longitude, zoom);
      final y = _worldY(m.point.latitude, zoom);
      // translate to screen coordinates relative to center
      var dx = (x - centerX) + size.width / 2;
      var dy = (y - centerY) + size.height / 2;

      // wrap-around correction for longitude crossing (world repeats horizontally)
      if (dx.abs() > worldSize / 2) {
        if (dx > 0) {
          dx -= worldSize;
        } else {
          dx += worldSize;
        }
      }

      // quick cull
      if (dx < -radius ||
          dx > size.width + radius ||
          dy < -radius ||
          dy > size.height + radius) {
        continue;
      }

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasMarkerPainter oldDelegate) {
    return oldDelegate.markers != markers ||
        oldDelegate.center != center ||
        oldDelegate.zoom != zoom;
  }
}

/// Canvas layer variant that draws directly from raw coordinate pairs
/// (`[lat, lon]`) to avoid creating `Marker` widgets for large datasets.
class _CanvasRawMarkerLayer extends StatelessWidget {
  const _CanvasRawMarkerLayer({
    required this.rawMarkers,
    required this.center,
    required this.zoom,
    required this.radius,
    this.iconImage,
  });

  final List<dynamic> rawMarkers;
  final LatLng center;
  final double zoom;
  final double radius;
  final ui.Image? iconImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: CustomPaint(
          painter: _CanvasRawMarkerPainter(
            rawMarkers: rawMarkers,
            center: center,
            zoom: zoom,
            radius: radius,
            devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
            iconImage: iconImage,
          ),
        ),
      );
    });
  }
}

class _CanvasRawMarkerPainter extends CustomPainter {
  _CanvasRawMarkerPainter({
    required this.rawMarkers,
    required this.center,
    required this.zoom,
    required this.radius,
    required this.devicePixelRatio,
    this.iconImage,
  });

  final List<dynamic> rawMarkers;
  final LatLng center;
  final double zoom;
  final double radius;
  final double devicePixelRatio;
  final ui.Image? iconImage;

  static double _worldX(double lon, double zoom) {
    return _CanvasMarkerPainter._worldX(lon, zoom);
  }

  static double _worldY(double lat, double zoom) {
    return _CanvasMarkerPainter._worldY(lat, zoom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red.withValues(alpha: 0.95);

    final centerX = _worldX(center.longitude, zoom);
    final centerY = _worldY(center.latitude, zoom);
    final double worldSize = 256 * pow(2, zoom).toDouble();

    for (var i = 0; i < rawMarkers.length; i++) {
      final m = rawMarkers[i];
      double lat;
      double lon;
      String? title;
      String? subtitle;
      if (m is Marker) {
        lat = m.point.latitude;
        lon = m.point.longitude;
      } else if (m is LatLng) {
        lat = m.latitude;
        lon = m.longitude;
      } else if (m is List && m.length >= 2) {
        lat = (m[0] as num).toDouble();
        lon = (m[1] as num).toDouble();
        if (m.length >= 3) title = m[2]?.toString();
        if (m.length >= 4) subtitle = m[3]?.toString();
      } else if (m is Map) {
        lat = (m['lat'] as num?)?.toDouble() ??
            (m['latitude'] as num?)?.toDouble() ??
            0.0;
        lon = (m['lon'] as num?)?.toDouble() ??
            (m['longitude'] as num?)?.toDouble() ??
            0.0;
        title = m['title']?.toString();
        subtitle = m['subtitle']?.toString();
      } else {
        continue;
      }
      final x = _worldX(lon, zoom);
      final y = _worldY(lat, zoom);

      var dx = (x - centerX) + size.width / 2;
      var dy = (y - centerY) + size.height / 2;

      if (dx.abs() > worldSize / 2) {
        if (dx > 0) {
          dx -= worldSize;
        } else {
          dx += worldSize;
        }
      }

      final radiusToUse = max(radius, 6.0);
      if (dx < -radiusToUse ||
          dx > size.width + radiusToUse ||
          dy < -radiusToUse ||
          dy > size.height + radiusToUse) {
        continue;
      }

      // Draw a simple pin icon: circular head + triangular tail.
      final pinPaint = paint;
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, devicePixelRatio * 0.6);

      // head center slightly above the marker point
      final headCenter = Offset(dx, dy - radiusToUse * 0.6);
      final headRadius = radiusToUse * 0.9;

      if (iconImage != null) {
        final src = Rect.fromLTWH(
            0, 0, iconImage!.width.toDouble(), iconImage!.height.toDouble());
        final destSize = headRadius * 2.0;
        final dst = Rect.fromCenter(
            center: headCenter, width: destSize, height: destSize);
        paint.isAntiAlias = true;
        canvas.drawImageRect(iconImage!, src, dst, paint);
      } else {
        canvas.drawCircle(headCenter, headRadius, pinPaint);
        canvas.drawCircle(headCenter, headRadius, strokePaint);

        // triangular tail pointing down
        final tailTopY = dy - radiusToUse * 0.1;
        final tailPath = ui.Path()
          ..moveTo(dx, dy + radiusToUse * 1.6)
          ..lineTo(dx - radiusToUse, tailTopY)
          ..lineTo(dx + radiusToUse, tailTopY)
          ..close();
        canvas.drawPath(tailPath, pinPaint);
        canvas.drawPath(tailPath, strokePaint);
      }

      // Draw title / subtitle if present
      if ((title != null && title.isNotEmpty) ||
          (subtitle != null && subtitle.isNotEmpty)) {
        final lines = <String>[];
        if (title != null && title.isNotEmpty) lines.add(title);
        if (subtitle != null && subtitle.isNotEmpty) lines.add(subtitle);

        // Layout text via TextPainter
        final tp = TextPainter(textDirection: TextDirection.ltr);
        final textStyle = TextStyle(
            color: Colors.black,
            fontSize: max(10.0, devicePixelRatio * 6),
            fontWeight: FontWeight.w600);

        // Build a paragraph with up to two lines stacked
        final span = TextSpan(
            children: lines
                .map((l) => TextSpan(text: '$l\n', style: textStyle))
                .toList());
        tp.text = span;
        tp.textAlign = TextAlign.center;
        tp.layout(minWidth: 0, maxWidth: size.width);

        final pad = 4.0;
        final bgWidth = tp.width + pad * 2;
        final bgHeight = tp.height + pad * 2;
        final bgRect = Rect.fromCenter(
            center: Offset(
                headCenter.dx, headCenter.dy - headRadius - bgHeight / 2 - 6),
            width: bgWidth,
            height: bgHeight);

        final rrect = RRect.fromRectAndRadius(bgRect, Radius.circular(4));
        final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
        canvas.drawRRect(rrect, bgPaint);

        tp.paint(canvas, Offset(bgRect.left + pad, bgRect.top + pad));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasRawMarkerPainter oldDelegate) {
    return oldDelegate.rawMarkers != rawMarkers ||
        oldDelegate.center != center ||
        oldDelegate.zoom != zoom ||
        oldDelegate.iconImage != iconImage;
  }
}

class _TapResult {
  _TapResult(this.point);
  final LatLng point;
}

/// TileProvider that tracks ongoing tile loads via callbacks.
// No custom TileProvider: use NetworkTileProvider for compatibility with latest flutter_map.
