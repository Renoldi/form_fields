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

// Extra padding (pixels) added to hit areas to make shapes easier to tap.
const double _tapPad = 12.0;

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

  /// Remove a raw marker or shape placeholder by ID (works for
  /// `ShapeMeta` entries and Map entries containing an `id` key).
  bool removeRawMarker(String id) {
    final before = _rawMarkersCache.length;
    _rawMarkersCache = _rawMarkersCache.where((m) {
      if (m is ShapeMeta) return m.id != id;
      if (m is Map) return m['id'] != id;
      return true;
    }).toList(growable: false);
    final removed = _rawMarkersCache.length != before;
    if (removed) notifyListeners();
    return removed;
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
    _markersCache = _markerMap.values.toList(growable: false);
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
    _polygonsCache = _polygonMap.values.toList(growable: false);
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
    _polylinesCache = _polylineMap.values.toList(growable: false);
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
    _circlesCache = _circleMap.values.toList(growable: false);
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
    this.canvasMarkerRadius = 20.0,
    this.canvasMarkerIcon,
    this.useViewportCulling = false,
    this.cullingBuffer = 1.25,
    this.notifier,
    this.onMapReady,
    this.onPositionChanged,
    this.onMapTap,
    this.onTapShape,
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
  final ValueChanged<ShapeMeta>? onTapShape;

  final VoidCallback? onMapReady;
  final ValueChanged<dynamic>? onPositionChanged;
  final ValueChanged<LatLng>? onMapTap;
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
  // When true, the next map-level onTap should be suppressed because the
  // canvas layer already handled the event (avoid double-calling callbacks).
  bool _suppressNextMapTap = false;

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
    // map-level callback receive it. We forward payloads as `ShapeMeta`.
    FormFieldsMapController.registerOnMarkerTap(
        widget.controllerId, widget.onTapShape);
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
        oldWidget.onTapShape != widget.onTapShape) {
      FormFieldsMapController.removeOnMarkerTap(oldWidget.controllerId);
      FormFieldsMapController.registerOnMarkerTap(
          widget.controllerId, widget.onTapShape);
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {});
        });
      });
      stream.addListener(_canvasMarkerImageStreamListener!);
      return;
    }

    // If an Icon widget (or IconData) is supplied, rasterize it to a ui.Image.
    if (provider is Icon) {
      _renderIconToImage(provider).then((img) {
        _canvasMarkerImage = img;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {});
        });
      });
      return;
    }

    // If an arbitrary widget is provided, rasterize it via an Overlay
    // so consumers can pass any widget (e.g., custom composed markers).
    if (provider is Widget) {
      _rasterizeWidgetToImage(provider).then((img) {
        if (img != null) {
          _canvasMarkerImage = img;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {});
          });
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
    // Adjusting the distance check to include tap padding.
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

  void _suppressNextTap() {
    _suppressNextMapTap = true;
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
              onLongPress: (tapPos, latlng) => _handleLongPress(tapPos, latlng),
            ),
            children: [
              TileLayer(
                urlTemplate: widget.tileUrlTemplate,
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                tileProvider: tileProvider,
                maxZoom: widget.maxZoom,
                minZoom: widget.minZoom,
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

              // Markers (render above shapes)
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
                      controllerId: widget.controllerId,
                      onTapShape: widget.onTapShape,
                      onMapTap: widget.onMapTap,
                      onHandledTap: _suppressNextTap,
                    );
                  },
                )
              else
                // Use Consumer so we can access the notifier's internal map
                // entries (ids) and wrap each Marker.child with a
                // GestureDetector that invokes the map-level marker tap
                // handler. This enables consumers to receive marker tap
                // events without embedding their own GestureDetector.
                Consumer<FormFieldsMapNotifier>(
                  builder: (context, notifier, _) {
                    final markersMap = notifier._markerMap;
                    if (markersMap.isEmpty) return const SizedBox.shrink();

                    final wrapped = <Marker>[];
                    markersMap.forEach((id, m) {
                      final wrappedChild = GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          final sm = ShapeMeta.fromMap({
                            'id': id,
                            'shapeType': 'marker',
                            'lat': m.point.latitude,
                            'lon': m.point.longitude,
                          });
                          try {
                            debugPrint('WidgetMarker tapped id=$id');
                          } catch (_) {}
                          // Call the widget-level handler immediately for
                          // consumers that provided `onTapShape`.
                          try {
                            widget.onTapShape?.call(sm);
                          } catch (_) {}
                          FormFieldsMapController.invokeOnMarkerTap(
                              widget.controllerId, sm);
                        },
                        onLongPress: () {
                          final sm = ShapeMeta.fromMap({
                            'id': id,
                            'shapeType': 'marker_longpress',
                            'lat': m.point.latitude,
                            'lon': m.point.longitude,
                          });
                          try {
                            debugPrint('WidgetMarker longpress id=$id');
                          } catch (_) {}
                          try {
                            widget.onTapShape?.call(sm);
                          } catch (_) {}
                          FormFieldsMapController.invokeOnMarkerTap(
                              widget.controllerId, sm);
                        },
                        child: m.child,
                      );

                      // Ensure a reasonable minimum visual size for
                      // non-canvas (widget) markers so they match
                      // the canvas default appearance.
                      const minWidgetMarker = 80.0;
                      final effectiveWidth =
                          m.width < minWidgetMarker ? minWidgetMarker : m.width;
                      final effectiveHeight = m.height < minWidgetMarker
                          ? minWidgetMarker
                          : m.height;
                      wrapped.add(Marker(
                        key: m.key,
                        point: m.point,
                        width: effectiveWidth,
                        height: effectiveHeight,
                        alignment: m.alignment,
                        rotate: m.rotate,
                        child: SizedBox(
                          width: effectiveWidth,
                          height: effectiveHeight,
                          child: Center(child: wrappedChild),
                        ),
                      ));
                    });

                    if (!widget.useViewportCulling) {
                      return MarkerLayer(markers: wrapped);
                    }

                    final center = _lastCenter ?? widget.initialCenter;
                    final zoom = _lastZoom ?? widget.initialZoom;
                    final degPerWorld = 360 / pow(2, zoom).toDouble();
                    final halfViewportDeg = degPerWorld / 2;
                    final buffer = widget.cullingBuffer;
                    final radiusDeg = halfViewportDeg * buffer;

                    final visible = wrapped.where((m) {
                      final lat = m.point.latitude;
                      final lng = m.point.longitude;
                      return (lat - center.latitude).abs() <= radiusDeg &&
                          (lng - center.longitude).abs() <= radiusDeg;
                    }).toList(growable: false);

                    if (visible.isEmpty) return const SizedBox.shrink();
                    return MarkerLayer(markers: visible);
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
    // If the canvas layer has already handled the most recent tap, skip
    // the map-level onTap to avoid double-calling handlers.
    if (_suppressNextMapTap) {
      _suppressNextMapTap = false;
      return;
    }
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
        if (candidate is Map) {
          final shapeType = candidate['shapeType'] as String?;
          if (shapeType != null && shapeType != 'marker') {
            continue; // skip shape placeholders stored in rawMarkers
          }
        }
        if (candidate == null) continue;

        double candLon;
        double candLat;
        if (candidate is Marker) {
          candLon = candidate.point.longitude;
          candLat = candidate.point.latitude;
        } else if (candidate is ShapeMeta) {
          candLon = candidate.lon;
          candLat = candidate.lat;
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
        if (dist <= widget.canvasMarkerRadius + _tapPad) {
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
        if (cand is ShapeMeta) {
          payload.addAll(cand.toMap());
        } else if (cand is Map) {
          payload.addAll(Map<String, dynamic>.from(cand));
        } else if (cand is List && cand.length >= 3) {
          payload['title'] = cand[2]?.toString();
          if (cand.length >= 4) payload['subtitle'] = cand[3]?.toString();
        }
        payload['point'] = LatLng(hitCandLat ?? 0.0, hitCandLon ?? 0.0);

        // Invoke via controller so both widget markers and canvas
        // markers use the same delivery path. Convert payload to `ShapeMeta`.
        try {
          debugPrint('FormFieldsMap: building ShapeMeta from payload=$payload');
        } catch (_) {}
        final sm = ShapeMeta.fromMap(payload);
        FormFieldsMapController.invokeOnMarkerTap(widget.controllerId, sm);
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
          // try to find metadata in rawMarkers if present and convert to ShapeMeta
          final meta = _findMetaForShape(notifier, pid);
          final mapPayload = <String, dynamic>{};
          if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
          mapPayload['id'] = pid;
          mapPayload['shapeType'] = 'polygon';
          mapPayload['lat'] = latlng.latitude;
          mapPayload['lon'] = latlng.longitude;
          try {
            debugPrint(
                'FormFieldsMap: building ShapeMeta from mapPayload=$mapPayload');
          } catch (_) {}
          final sm = ShapeMeta.fromMap(mapPayload);
          widget.onTapShape?.call(sm);
          return;
        }
      }

      // Polylines: precise per-segment hit-testing in screen pixels.
      // This is more accurate than midpoint heuristics and avoids
      // missing narrow or angled segments.
      Offset local;
      try {
        local = (tapPosition as dynamic).localPosition as Offset;
      } catch (_) {
        try {
          local = (tapPosition as dynamic).local as Offset;
        } catch (_) {
          local = Offset(
              (context.size?.width ?? 0) / 2, (context.size?.height ?? 0) / 2);
        }
      }
      final tapZoom = _lastZoom ?? widget.initialZoom;
      final center = _lastCenter ?? widget.initialCenter;
      final centerX =
          _CanvasRawMarkerPainter._worldX(center.longitude, tapZoom);
      final centerY = _CanvasRawMarkerPainter._worldY(center.latitude, tapZoom);
      final double worldSize = 256 * pow(2, tapZoom).toDouble();
      const double baseThreshPx = 24.0 + _tapPad;
      double minPolyDist = double.infinity;
      String? minPolyId;
      for (final entry in notifier._polylineMap.entries) {
        final lid = entry.key;
        final pl = entry.value;
        final pts = pl.points;
        final stroke = pl.strokeWidth;
        final threshPx = max(baseThreshPx, stroke * 2.0 + 12.0);
        for (var i = 0; i < pts.length - 1; i++) {
          final p0 = pts[i];
          final p1 = pts[i + 1];
          final x0 = _CanvasRawMarkerPainter._worldX(p0.longitude, tapZoom);
          final y0 = _CanvasRawMarkerPainter._worldY(p0.latitude, tapZoom);
          var dx0 = (x0 - centerX) + (context.size?.width ?? 0) / 2;
          var dy0 = (y0 - centerY) + (context.size?.height ?? 0) / 2;
          if (dx0.abs() > worldSize / 2) {
            if (dx0 > 0) {
              dx0 -= worldSize;
            } else {
              dx0 += worldSize;
            }
          }
          final x1 = _CanvasRawMarkerPainter._worldX(p1.longitude, tapZoom);
          final y1 = _CanvasRawMarkerPainter._worldY(p1.latitude, tapZoom);
          var dx1 = (x1 - centerX) + (context.size?.width ?? 0) / 2;
          var dy1 = (y1 - centerY) + (context.size?.height ?? 0) / 2;
          if (dx1.abs() > worldSize / 2) {
            if (dx1 > 0) {
              dx1 -= worldSize;
            } else {
              dx1 += worldSize;
            }
          }
          final distPx = _pointToSegmentDistance(
              local, Offset(dx0, dy0), Offset(dx1, dy1));
          if (distPx < minPolyDist) {
            minPolyDist = distPx;
            minPolyId = lid;
          }
          if (distPx <= threshPx) {
            final meta = _findMetaForShape(notifier, lid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = lid;
            mapPayload['shapeType'] = 'polyline';
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
            try {
              debugPrint(
                  'FormFieldsMap: polyline tap id=$lid payload=$mapPayload');
            } catch (_) {}
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
      // If no strict hit, use a relaxed fallback based on nearest distance.
      const double relaxMul = 3.0;
      if (minPolyId != null &&
          minPolyDist.isFinite &&
          minPolyDist <= baseThreshPx * relaxMul) {
        final meta = _findMetaForShape(notifier, minPolyId);
        final mapPayload = <String, dynamic>{};
        if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
        mapPayload['id'] = minPolyId;
        mapPayload['shapeType'] = 'polyline';
        mapPayload['lat'] = latlng.latitude;
        mapPayload['lon'] = latlng.longitude;
        try {
          debugPrint(
              'FormFieldsMap: polyline fallback id=$minPolyId payload=$mapPayload minDistPx=$minPolyDist');
        } catch (_) {}
        final sm = ShapeMeta.fromMap(mapPayload);
        widget.onTapShape?.call(sm);
        return;
      }

      final distance = Distance();
      // Circles: distance to center (meters if useRadiusInMeter true)
      for (final entry in notifier._circleMap.entries) {
        final cid = entry.key;
        final c = entry.value;
        final center = c.point;
        final d = distance.distance(center, latlng);
        if (c.useRadiusInMeter) {
          if (d <= c.radius) {
            final meta = _findMetaForShape(notifier, cid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = cid;
            mapPayload['shapeType'] = 'circle';
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
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
            final payload = <String, dynamic>{'id': cid, 'shapeType': 'circle'};
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            try {
              debugPrint(
                  'FormFieldsMap: building ShapeMeta from payload=$payload');
            } catch (_) {}
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
    } catch (_) {}

    widget.onMapTap?.call(latlng);
  }

  void _handleLongPress(TapPosition tapPosition, LatLng latlng) {
    // Similar to _handleTap but routes to long-press callbacks.
    // First try marker hit-testing when canvas markers are active.
    // Prepare notifier early so fallback linear hit-test can access rawMarkers.
    if (widget.useCanvasMarkers) {
      // If we have a KD-tree use it (fast). Otherwise fall back to a
      // linear scan of `rawMarkers` so taps work immediately after
      // `appendRawMarkers` without waiting for the post-frame KD-tree build.
      if (_kdTree != null) {
        final tapZoom = _lastZoom ?? widget.initialZoom;
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

        dynamic hitCandidate;
        double? hitCandLat;
        double? hitCandLon;
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

          final candX = _CanvasMarkerPainter._worldX(candLon, kdZoom);
          final candY = _CanvasMarkerPainter._worldY(candLat, kdZoom);
          final centerLon = (_lastCenter ?? widget.initialCenter).longitude;
          final centerLat = (_lastCenter ?? widget.initialCenter).latitude;
          final centerX = _CanvasMarkerPainter._worldX(centerLon, kdZoom);
          final centerY = _CanvasMarkerPainter._worldY(centerLat, kdZoom);

          var candDx = (candX - centerX) + (context.size?.width ?? 0) / 2;
          var candDy = (candY - centerY) + (context.size?.height ?? 0) / 2;

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
            hitCandidate = candidate;
            hitCandLat = candLat;
            hitCandLon = candLon;
            break;
          }
        }

        if (hitCandidate != null) {
          final cand = hitCandidate;
          final payload = <String, dynamic>{};
          if (cand is Map) {
            payload.addAll(Map<String, dynamic>.from(cand));
          } else if (cand is List && cand.length >= 3) {
            payload['title'] = cand[2]?.toString();
            if (cand.length >= 4) payload['subtitle'] = cand[3]?.toString();
          }
          payload['point'] = LatLng(hitCandLat ?? 0.0, hitCandLon ?? 0.0);
          final sm = ShapeMeta.fromMap(payload);
          widget.onTapShape?.call(sm);
          FormFieldsMapController.invokeOnMarkerTap(widget.controllerId, sm);
          return;
        }
      }
    }

    // Fallback: shapes long-press
    try {
      final notifier = widget.notifier ?? _internalNotifier;

      for (final entry in notifier._polygonMap.entries) {
        final pid = entry.key;
        final poly = entry.value;
        if (_pointInPolygon(latlng, poly.points)) {
          final meta = _findMetaForShape(notifier, pid);
          final payload = <String, dynamic>{'id': pid, 'shapeType': 'polygon'};
          if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
          payload['point'] = latlng;
          final sm = ShapeMeta.fromMap(payload);
          widget.onTapShape?.call(sm);
          return;
        }
      }

      const threshMeters = 200.0;
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
            final payload = <String, dynamic>{
              'id': lid,
              'shapeType': 'polyline'
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }

      for (final entry in notifier._circleMap.entries) {
        final cid = entry.key;
        final c = entry.value;
        final center = c.point;
        final d = Distance().distance(center, latlng);
        if (c.useRadiusInMeter) {
          if (d <= c.radius) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{'id': cid, 'shapeType': 'circle'};
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
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
            final payload = <String, dynamic>{'id': cid, 'shapeType': 'circle'};
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
    } catch (_) {}

    widget.onLongPress?.call(latlng);
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
    required this.controllerId,
    this.onTapShape,
    this.onMapTap,
    this.onHandledTap,
  });

  final List<dynamic> rawMarkers;
  final LatLng center;
  final double zoom;
  final double radius;
  final ui.Image? iconImage;
  final String controllerId;
  final ValueChanged<ShapeMeta>? onTapShape;
  final ValueChanged<LatLng>? onMapTap;
  final VoidCallback? onHandledTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return SizedBox(
        width: w,
        height: h,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            try {
              final local = details.localPosition;
              final centerX =
                  _CanvasRawMarkerPainter._worldX(center.longitude, zoom);
              final centerY =
                  _CanvasRawMarkerPainter._worldY(center.latitude, zoom);
              final double worldSize = 256 * pow(2, zoom).toDouble();

              // Helper: convert local tap to world coords and lat/lon
              double worldTapX = centerX + local.dx - w / 2;
              double worldTapY = centerY + local.dy - h / 2;
              // wrap X
              if (worldTapX < 0) worldTapX += worldSize;
              if (worldTapX > worldSize) worldTapX -= worldSize;
              final tapLon =
                  _CanvasRawMarkerPainter._lonFromWorldX(worldTapX, zoom);
              final tapLat =
                  _CanvasRawMarkerPainter._latFromWorldY(worldTapY, zoom);

              // 1) Marker hit-test (rawMarkers)
              for (final m in rawMarkers) {
                double lat;
                double lon;
                ShapeMeta? smCandidate;
                if (m is Marker) {
                  lat = m.point.latitude;
                  lon = m.point.longitude;
                } else if (m is ShapeMeta) {
                  smCandidate = m;
                  lat = smCandidate.lat;
                  lon = smCandidate.lon;
                } else if (m is LatLng) {
                  lat = m.latitude;
                  lon = m.longitude;
                } else if (m is List && m.length >= 2) {
                  lat = (m[0] as num).toDouble();
                  lon = (m[1] as num).toDouble();
                } else if (m is Map) {
                  final shapeType = m['shapeType'] as String?;
                  if (shapeType != null && shapeType != 'marker') {
                    continue; // skip shape placeholder markers
                  }
                  lat = (m['lat'] as num?)?.toDouble() ??
                      (m['latitude'] as num?)?.toDouble() ??
                      0.0;
                  lon = (m['lon'] as num?)?.toDouble() ??
                      (m['longitude'] as num?)?.toDouble() ??
                      0.0;
                } else {
                  continue;
                }

                final candX = _CanvasRawMarkerPainter._worldX(lon, zoom);
                final candY = _CanvasRawMarkerPainter._worldY(lat, zoom);
                var candDx = (candX - centerX) + w / 2;
                var candDy = (candY - centerY) + h / 2;

                if (candDx.abs() > worldSize / 2) {
                  if (candDx > 0) {
                    candDx -= worldSize;
                  } else {
                    candDx += worldSize;
                  }
                }

                final dist =
                    sqrt(pow(candDx - local.dx, 2) + pow(candDy - local.dy, 2));

                // Also treat taps on the title/subtitle label above the pin
                // as hits. Estimate the label rect using the same geometry
                // as the painter. Use MediaQuery devicePixelRatio to estimate
                // font size so hit area matches visual size reasonably well.
                final devicePixelRatio =
                    MediaQuery.of(context).devicePixelRatio;
                final radiusToUse = max(radius, 6.0);
                final headCenter = Offset(candDx, candDy - radiusToUse * 0.6);
                final headRadius = radiusToUse * 0.9;
                String? titleStr;
                String? subtitleStr;
                if (m is ShapeMeta) {
                  titleStr = m.title;
                  subtitleStr = m.subtitle;
                } else if (m is List) {
                  if (m.length >= 3) titleStr = m[2]?.toString();
                  if (m.length >= 4) subtitleStr = m[3]?.toString();
                } else if (m is Map) {
                  titleStr = m['title']?.toString();
                  subtitleStr = m['subtitle']?.toString();
                }
                var labelHit = false;
                if ((titleStr != null && titleStr.isNotEmpty) ||
                    (subtitleStr != null && subtitleStr.isNotEmpty)) {
                  final lines = <String>[];
                  if (titleStr != null && titleStr.isNotEmpty) {
                    lines.add(titleStr);
                  }
                  if (subtitleStr != null && subtitleStr.isNotEmpty) {
                    lines.add(subtitleStr);
                  }
                  final fontSize = max(10.0, devicePixelRatio * 6);
                  final pad = 4.0;
                  final tp = TextPainter(
                    text: TextSpan(
                        children:
                            lines.map((l) => TextSpan(text: '$l\n')).toList(),
                        style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.w600)),
                    textDirection: TextDirection.ltr,
                  );
                  tp.textAlign = TextAlign.center;
                  tp.layout(minWidth: 0, maxWidth: w);
                  final textHeight = tp.height;
                  final textWidth = tp.width;
                  final bgHeight = textHeight + pad * 2;
                  final bgCenterY = headCenter.dy - headRadius - bgHeight / 2 - 6.0;
                  final bgTop = bgCenterY - bgHeight / 2;
                  final bgBottom = bgCenterY + bgHeight / 2;
                  final bgWidth = max(48.0, textWidth) + pad * 2 + _tapPad * 2;
                  final bgLeft = headCenter.dx - bgWidth / 2;
                  final bgRight = headCenter.dx + bgWidth / 2;
                  if (local.dx >= bgLeft && local.dx <= bgRight && local.dy >= bgTop && local.dy <= bgBottom) {
                    labelHit = true;
                  }
                }

                if (dist <= radius || labelHit) {
                  final payload = <String, dynamic>{};
                  if (m is Map) {
                    payload.addAll(Map<String, dynamic>.from(m));
                  } else if (m is List && m.length >= 3) {
                    payload['title'] = m[2]?.toString();
                    if (m.length >= 4) payload['subtitle'] = m[3]?.toString();
                  } else if (smCandidate != null) {
                    payload.addAll(smCandidate.toMap());
                  }
                  payload['point'] = LatLng(lat, lon);
                  try {
                    debugPrint(
                        'CanvasRawMarkerLayer: marker tap -> controller=$controllerId payload=$payload');
                  } catch (_) {}
                  final sm = ShapeMeta.fromMap(payload);
                  try {
                    onTapShape?.call(sm);
                  } catch (_) {}
                  // Notify parent that canvas handled this tap so the
                  // map-level onTap can be suppressed to avoid duplication.
                  try {
                    onHandledTap?.call();
                  } catch (_) {}
                  FormFieldsMapController.invokeOnMarkerTap(controllerId, sm);
                  return;
                }
              }

              // 2) Polygons
              final notifier =
                  Provider.of<FormFieldsMapNotifier>(context, listen: false);
              if (notifier._polygonMap.isNotEmpty) {
                for (final entry in notifier._polygonMap.entries) {
                  final pid = entry.key;
                  final poly = entry.value;
                  final screenPts = <Offset>[];
                  for (final pt in poly.points) {
                    final px =
                        _CanvasRawMarkerPainter._worldX(pt.longitude, zoom);
                    final py =
                        _CanvasRawMarkerPainter._worldY(pt.latitude, zoom);
                    var dx = (px - centerX) + w / 2;
                    var dy = (py - centerY) + h / 2;
                    if (dx.abs() > worldSize / 2) {
                      if (dx > 0) {
                        dx -= worldSize;
                      } else {
                        dx += worldSize;
                      }
                    }
                    screenPts.add(Offset(dx, dy));
                  }
                  if (_pointInPolygonScreen(local, screenPts)) {
                    final meta = _findMetaForShapeMap(rawMarkers, pid);
                    final payload = <String, dynamic>{
                      'id': pid,
                      'shapeType': 'polygon'
                    };
                    if (meta is Map) {
                      payload.addAll(Map<String, dynamic>.from(meta));
                    }
                    payload['point'] = LatLng(tapLat, tapLon);
                    try {
                      debugPrint(
                          'CanvasRawMarkerLayer: polygon tap id=$pid -> controller=$controllerId payload=$payload');
                    } catch (_) {}
                    final sm = ShapeMeta.fromMap(payload);
                    onTapShape?.call(sm);
                    try {
                      onHandledTap?.call();
                    } catch (_) {}
                    return;
                  }
                  // If tap missed polygon geometry, also check label/meta
                  // position (centroid) so tapping the title triggers callback.
                  final meta = _findMetaForShapeMap(rawMarkers, pid);
                  double labelLat;
                  double labelLon;
                  if (meta is Map) {
                    labelLat = (meta['lat'] as num?)?.toDouble() ??
                        (meta['latitude'] as num?)?.toDouble() ??
                        0.0;
                    labelLon = (meta['lon'] as num?)?.toDouble() ??
                        (meta['longitude'] as num?)?.toDouble() ??
                        0.0;
                  } else {
                    final avgLat = poly.points
                            .map((p) => p.latitude)
                            .reduce((a, b) => a + b) /
                        poly.points.length;
                    final avgLon = poly.points
                            .map((p) => p.longitude)
                            .reduce((a, b) => a + b) /
                        poly.points.length;
                    labelLat = avgLat;
                    labelLon = avgLon;
                  }
                  final lx = _CanvasRawMarkerPainter._worldX(labelLon, zoom);
                  final ly = _CanvasRawMarkerPainter._worldY(labelLat, zoom);
                  var ldx = (lx - centerX) + w / 2;
                  var ldy = (ly - centerY) + h / 2;
                  if (ldx.abs() > worldSize / 2) {
                    if (ldx > 0) {
                      ldx -= worldSize;
                    } else {
                      ldx += worldSize;
                    }
                  }
                  final devicePixelRatio =
                      MediaQuery.of(context).devicePixelRatio;
                  final fontSize = max(10.0, devicePixelRatio * 6);
                  final lines = <String>[];
                  if (meta is Map) {
                    if ((meta['title'] as String?)?.isNotEmpty ?? false) {
                      lines.add(meta['title']);
                    }
                    if ((meta['subtitle'] as String?)?.isNotEmpty ?? false) {
                      lines.add(meta['subtitle']);
                    }
                  }
                  if (lines.isNotEmpty) {
                    final pad = 4.0;
                    final tp = TextPainter(
                      text: TextSpan(
                        children: lines.map((l) => TextSpan(text: '$l\n')).toList(),
                        style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                      textDirection: TextDirection.ltr,
                    );
                    tp.textAlign = TextAlign.center;
                    tp.layout(minWidth: 0, maxWidth: w);
                    final textHeight = tp.height;
                    final textWidth = tp.width;
                    final bgHeight = textHeight + pad * 2;
                    final bgCenterY = ldy - (max(radius, 6.0) * 0.9) - bgHeight / 2 - 6.0;
                    final bgTop = bgCenterY - bgHeight / 2;
                    final bgBottom = bgCenterY + bgHeight / 2;
                    final bgWidth = max(48.0, textWidth) + pad * 2 + _tapPad * 2;
                    final bgLeft = ldx - bgWidth / 2;
                    final bgRight = ldx + bgWidth / 2;
                    if (local.dx >= bgLeft && local.dx <= bgRight && local.dy >= bgTop && local.dy <= bgBottom) {
                      final payload2 = <String, dynamic>{
                        'id': pid,
                        'shapeType': 'polygon'
                      };
                      if (meta is Map) {
                        payload2.addAll(Map<String, dynamic>.from(meta));
                      }
                      payload2['point'] = LatLng(tapLat, tapLon);
                      try {
                        debugPrint(
                            'CanvasRawMarkerLayer: polygon label tap id=$pid -> controller=$controllerId payload=$payload2');
                      } catch (_) {}
                      final sm2 = ShapeMeta.fromMap(payload2);
                      onTapShape?.call(sm2);
                      return;
                    }
                  }
                }
              }

              // 3) Polylines (distance to segment)
              if (notifier._polylineMap.isNotEmpty) {
                const double baseThreshPx = 24.0 + _tapPad;
                double minPolyDist = double.infinity;
                String? minPolyId;
                for (final entry in notifier._polylineMap.entries) {
                  final lid = entry.key;
                  final pl = entry.value;
                  final pts = pl.points;
                  // Compute per-polyline hit radius in pixels, scaled by stroke width
                  final stroke = pl.strokeWidth;
                  final threshPx = max(baseThreshPx, stroke * 2.0 + 12.0);
                  for (var i = 0; i < pts.length - 1; i++) {
                    final p0 = pts[i];
                    final p1 = pts[i + 1];
                    final x0 =
                        _CanvasRawMarkerPainter._worldX(p0.longitude, zoom);
                    final y0 =
                        _CanvasRawMarkerPainter._worldY(p0.latitude, zoom);
                    var dx0 = (x0 - centerX) + w / 2;
                    var dy0 = (y0 - centerY) + h / 2;
                    if (dx0.abs() > worldSize / 2) {
                      if (dx0 > 0) {
                        dx0 -= worldSize;
                      } else {
                        dx0 += worldSize;
                      }
                    }
                    final x1 =
                        _CanvasRawMarkerPainter._worldX(p1.longitude, zoom);
                    final y1 =
                        _CanvasRawMarkerPainter._worldY(p1.latitude, zoom);
                    var dx1 = (x1 - centerX) + w / 2;
                    var dy1 = (y1 - centerY) + h / 2;
                    if (dx1.abs() > worldSize / 2) {
                      if (dx1 > 0) {
                        dx1 -= worldSize;
                      } else {
                        dx1 += worldSize;
                      }
                    }
                    final dist = _pointToSegmentDistance(
                        local, Offset(dx0, dy0), Offset(dx1, dy1));
                    if (dist < minPolyDist) {
                      minPolyDist = dist;
                      minPolyId = lid;
                    }
                    if (dist <= threshPx) {
                      final meta = _findMetaForShapeMap(rawMarkers, lid);
                      final payload = <String, dynamic>{
                        'id': lid,
                        'shapeType': 'polyline'
                      };
                      if (meta is Map) {
                        payload.addAll(Map<String, dynamic>.from(meta));
                      }
                      payload['point'] = LatLng(tapLat, tapLon);
                      try {
                        debugPrint(
                            'CanvasRawMarkerLayer: polyline tap id=$lid -> controller=$controllerId payload=$payload');
                      } catch (_) {}
                      final sm = ShapeMeta.fromMap(payload);
                      onTapShape?.call(sm);
                      try {
                        onHandledTap?.call();
                      } catch (_) {}
                      return;
                    }
                  }
                }
                // If no polyline segment was hit, check midpoint labels
                for (final entryLabel in notifier._polylineMap.entries) {
                  final lid = entryLabel.key;
                  final pl = entryLabel.value;
                  final midIndex = pl.points.length ~/ 2;
                  final mid = pl.points[midIndex];
                  final mx =
                      _CanvasRawMarkerPainter._worldX(mid.longitude, zoom);
                  final my =
                      _CanvasRawMarkerPainter._worldY(mid.latitude, zoom);
                  var mdx = (mx - centerX) + w / 2;
                  var mdy = (my - centerY) + h / 2;
                  if (mdx.abs() > worldSize / 2) {
                    if (mdx > 0) {
                      mdx -= worldSize;
                    } else {
                      mdx += worldSize;
                    }
                  }
                  final meta = _findMetaForShapeMap(rawMarkers, lid);
                  final devicePixelRatio =
                      MediaQuery.of(context).devicePixelRatio;
                  final fontSize = max(10.0, devicePixelRatio * 6);
                  final lines = <String>[];
                  if (meta is Map) {
                    if ((meta['title'] as String?)?.isNotEmpty ?? false) {
                      lines.add(meta['title']);
                    }
                    if ((meta['subtitle'] as String?)?.isNotEmpty ?? false) {
                      lines.add(meta['subtitle']);
                    }
                  }
                  if (lines.isNotEmpty) {
                    final pad = 4.0;
                    final tp = TextPainter(
                      text: TextSpan(
                        children: lines.map((l) => TextSpan(text: '$l\n')).toList(),
                        style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                      textDirection: TextDirection.ltr,
                    );
                    tp.textAlign = TextAlign.center;
                    tp.layout(minWidth: 0, maxWidth: w);
                    final textHeight = tp.height;
                    final textWidth = tp.width;
                    final bgHeight = textHeight + pad * 2;
                    final bgCenterY = mdy - (max(radius, 6.0) * 0.9) - bgHeight / 2 - 6.0;
                    final bgTop = bgCenterY - bgHeight / 2;
                    final bgBottom = bgCenterY + bgHeight / 2;
                    final bgWidth = max(48.0, textWidth) + pad * 2 + _tapPad * 2;
                    final bgLeft = mdx - bgWidth / 2;
                    final bgRight = mdx + bgWidth / 2;
                    if (local.dx >= bgLeft && local.dx <= bgRight && local.dy >= bgTop && local.dy <= bgBottom) {
                      final payload = <String, dynamic>{
                        'id': lid,
                        'shapeType': 'polyline'
                      };
                      if (meta is Map) {
                        payload.addAll(Map<String, dynamic>.from(meta));
                      }
                      payload['point'] = LatLng(tapLat, tapLon);
                      try {
                        debugPrint(
                            'CanvasRawMarkerLayer: polyline label tap id=$lid -> controller=$controllerId payload=$payload');
                      } catch (_) {}
                      final sm2 = ShapeMeta.fromMap(payload);
                      onTapShape?.call(sm2);
                      return;
                    }
                  }
                }
                try {
                  debugPrint(
                      'CanvasRawMarkerLayer: nearest polyline id=$minPolyId minDist=${minPolyDist.toStringAsFixed(1)}px baseThresh=$baseThreshPx');
                } catch (_) {}
                // Fallback: if the nearest polyline is reasonably close
                // but missed the stricter per-segment threshold, still
                // treat it as a hit to improve UX for thin or fast-rendered
                // polylines. Use a relaxed multiplier.
                const double relaxMul = 3.0;
                if (minPolyId != null &&
                    minPolyDist.isFinite &&
                    minPolyDist <= baseThreshPx * relaxMul) {
                  final meta = _findMetaForShapeMap(rawMarkers, minPolyId);
                  final payload = <String, dynamic>{
                    'id': minPolyId,
                    'shapeType': 'polyline'
                  };
                  if (meta is Map) {
                    payload.addAll(Map<String, dynamic>.from(meta));
                  }
                  payload['point'] = LatLng(tapLat, tapLon);
                  try {
                    debugPrint(
                        'CanvasRawMarkerLayer: polyline fallback tap id=$minPolyId -> controller=$controllerId payload=$payload');
                  } catch (_) {}
                  final sm = ShapeMeta.fromMap(payload);
                  onTapShape?.call(sm);
                  try {
                    onHandledTap?.call();
                  } catch (_) {}
                  return;
                }
              }

              // 4) Circles
              if (notifier._circleMap.isNotEmpty) {
                final distance = Distance();
                for (final entry in notifier._circleMap.entries) {
                  final cid = entry.key;
                  final c = entry.value;
                  final cx =
                      _CanvasRawMarkerPainter._worldX(c.point.longitude, zoom);
                  final cy =
                      _CanvasRawMarkerPainter._worldY(c.point.latitude, zoom);
                  var dx = (cx - centerX) + w / 2;
                  var dy = (cy - centerY) + h / 2;
                  if (dx.abs() > worldSize / 2) {
                    if (dx > 0) {
                      dx -= worldSize;
                    } else {
                      dx += worldSize;
                    }
                  }
                  final pixelDist =
                      sqrt(pow(dx - local.dx, 2) + pow(dy - local.dy, 2));
                  if (c.useRadiusInMeter) {
                    // compare geographic distance using converted tap lat/lon
                    final d =
                        distance.distance(c.point, LatLng(tapLat, tapLon));
                    if (d <= c.radius) {
                      final meta = _findMetaForShapeMap(rawMarkers, cid);
                      final payload = <String, dynamic>{
                        'id': cid,
                        'shapeType': 'circle'
                      };
                      if (meta is Map) {
                        payload.addAll(Map<String, dynamic>.from(meta));
                      }
                      payload['point'] = LatLng(tapLat, tapLon);
                      try {
                        debugPrint(
                            'CanvasRawMarkerLayer: circle tap id=$cid -> controller=$controllerId payload=$payload');
                      } catch (_) {}
                      final sm = ShapeMeta.fromMap(payload);
                      onTapShape?.call(sm);
                      return;
                    }
                  } else {
                    if (pixelDist <= c.radius + _tapPad) {
                      final meta = _findMetaForShapeMap(rawMarkers, cid);
                      final payload = <String, dynamic>{
                        'id': cid,
                        'shapeType': 'circle'
                      };
                      if (meta is Map) {
                        payload.addAll(Map<String, dynamic>.from(meta));
                      }
                      payload['point'] = LatLng(tapLat, tapLon);
                      try {
                        debugPrint(
                            'CanvasRawMarkerLayer: circle tap id=$cid -> controller=$controllerId payload=$payload');
                      } catch (_) {}
                      final sm = ShapeMeta.fromMap(payload);
                      onTapShape?.call(sm);
                      try {
                        onHandledTap?.call();
                      } catch (_) {}
                      return;
                    }
                  }
                }
              }

              // If nothing handled, call regular map `onTap` with point payload
              try {
                debugPrint(
                    'CanvasRawMarkerLayer: generic tap at ${LatLng(tapLat, tapLon)} for controller=$controllerId');
              } catch (_) {}
              onMapTap?.call(LatLng(tapLat, tapLon));
            } catch (_) {}
          },
          onLongPressStart: (details) {
            try {
              final local = details.localPosition;
              final centerX =
                  _CanvasRawMarkerPainter._worldX(center.longitude, zoom);
              final centerY =
                  _CanvasRawMarkerPainter._worldY(center.latitude, zoom);
              final double worldSize = 256 * pow(2, zoom).toDouble();

              double worldTapX = centerX + local.dx - w / 2;
              double worldTapY = centerY + local.dy - h / 2;
              if (worldTapX < 0) worldTapX += worldSize;
              if (worldTapX > worldSize) worldTapX -= worldSize;
              final tapLon =
                  _CanvasRawMarkerPainter._lonFromWorldX(worldTapX, zoom);
              final tapLat =
                  _CanvasRawMarkerPainter._latFromWorldY(worldTapY, zoom);

              // Marker long-press
              for (final m in rawMarkers) {
                double lat;
                double lon;
                ShapeMeta? smCandidate;
                if (m is Marker) {
                  lat = m.point.latitude;
                  lon = m.point.longitude;
                } else if (m is ShapeMeta) {
                  smCandidate = m;
                  lat = smCandidate.lat;
                  lon = smCandidate.lon;
                } else if (m is LatLng) {
                  lat = m.latitude;
                  lon = m.longitude;
                } else if (m is List && m.length >= 2) {
                  lat = (m[0] as num).toDouble();
                  lon = (m[1] as num).toDouble();
                } else if (m is Map) {
                  final shapeType = m['shapeType'] as String?;
                  if (shapeType != null && shapeType != 'marker') {
                    continue; // skip shape placeholder markers
                  }
                  lat = (m['lat'] as num?)?.toDouble() ??
                      (m['latitude'] as num?)?.toDouble() ??
                      0.0;
                  lon = (m['lon'] as num?)?.toDouble() ??
                      (m['longitude'] as num?)?.toDouble() ??
                      0.0;
                } else {
                  continue;
                }

                final candX = _CanvasRawMarkerPainter._worldX(lon, zoom);
                final candY = _CanvasRawMarkerPainter._worldY(lat, zoom);
                var candDx = (candX - centerX) + w / 2;
                var candDy = (candY - centerY) + h / 2;

                if (candDx.abs() > worldSize / 2) {
                  if (candDx > 0) {
                    candDx -= worldSize;
                  } else {
                    candDx += worldSize;
                  }
                }

                final dist =
                    sqrt(pow(candDx - local.dx, 2) + pow(candDy - local.dy, 2));
                if (dist <= radius) {
                  final payload = <String, dynamic>{};
                  if (m is Map) {
                    payload.addAll(Map<String, dynamic>.from(m));
                  } else if (m is List && m.length >= 3) {
                    payload['title'] = m[2]?.toString();
                    if (m.length >= 4) payload['subtitle'] = m[3]?.toString();
                  } else if (smCandidate != null) {
                    payload.addAll(smCandidate.toMap());
                  }
                  payload['point'] = LatLng(lat, lon);
                  try {
                    debugPrint(
                        'CanvasRawMarkerLayer: marker longpress -> controller=$controllerId payload=$payload');
                  } catch (_) {}
                  final sm = ShapeMeta.fromMap(payload);
                  onTapShape?.call(sm);
                  FormFieldsMapController.invokeOnMarkerTap(controllerId, sm);
                  return;
                }
              }

              // fallback: reuse onTap detection for shapes but call long-press callbacks
              // Polygons
              final notifier =
                  Provider.of<FormFieldsMapNotifier>(context, listen: false);
              if (notifier._polygonMap.isNotEmpty) {
                for (final entry in notifier._polygonMap.entries) {
                  final pid = entry.key;
                  final poly = entry.value;
                  final screenPts = <Offset>[];
                  for (final pt in poly.points) {
                    final px =
                        _CanvasRawMarkerPainter._worldX(pt.longitude, zoom);
                    final py =
                        _CanvasRawMarkerPainter._worldY(pt.latitude, zoom);
                    var dx = (px - centerX) + w / 2;
                    var dy = (py - centerY) + h / 2;
                    if (dx.abs() > worldSize / 2) {
                      if (dx > 0) {
                        dx -= worldSize;
                      } else {
                        dx += worldSize;
                      }
                    }
                    screenPts.add(Offset(dx, dy));
                  }
                  if (_pointInPolygonScreen(local, screenPts)) {
                    final meta = _findMetaForShapeMap(rawMarkers, pid);
                    final payload = <String, dynamic>{
                      'id': pid,
                      'shapeType': 'polygon'
                    };
                    if (meta is Map) {
                      payload.addAll(Map<String, dynamic>.from(meta));
                    }
                    payload['point'] = LatLng(tapLat, tapLon);
                    try {
                      debugPrint(
                          'CanvasRawMarkerLayer: polygon longpress id=$pid -> controller=$controllerId payload=$payload');
                    } catch (_) {}
                    final sm = ShapeMeta.fromMap(payload);
                    onTapShape?.call(sm);
                    return;
                  }
                }
              }
            } catch (_) {}
          },
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
        ),
      );
    });
  }
}

// Utility helpers used by the layer for hit-testing
double _pointToSegmentDistance(Offset p, Offset v, Offset w) {
  final l2 = pow((v.dx - w.dx), 2) + pow((v.dy - w.dy), 2);
  if (l2 == 0) return (p - v).distance;
  var t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
  t = t.clamp(0.0, 1.0);
  final proj = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
  return (p - proj).distance;
}

bool _pointInPolygonScreen(Offset p, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].dx, yi = polygon[i].dy;
    final xj = polygon[j].dx, yj = polygon[j].dy;
    final intersect = ((yi > p.dy) != (yj > p.dy)) &&
        (p.dx < (xj - xi) * (p.dy - yi) / (yj - yi + 0.0) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

dynamic _findMetaForShapeMap(List<dynamic> rawMarkers, String id) {
  for (final m in rawMarkers) {
    if (m is Map && m['id'] == id) return m;
  }
  return null;
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

  static double _lonFromWorldX(double x, double zoom) {
    final double worldSize = 256 * pow(2, zoom).toDouble();
    return x / worldSize * 360.0 - 180.0;
  }

  static double _latFromWorldY(double y, double zoom) {
    final double worldSize = 256 * pow(2, zoom).toDouble();
    final n = pi * (1 - 2 * y / worldSize);
    final s = (exp(n) - exp(-n)) / 2.0; // sinh(n)
    return atan(s) * 180.0 / pi;
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
      String? shapeType;
      if (m is Marker) {
        lat = m.point.latitude;
        lon = m.point.longitude;
        shapeType = 'marker';
      } else if (m is ShapeMeta) {
        lat = m.lat;
        lon = m.lon;
        title = m.title;
        subtitle = m.subtitle;
        shapeType = m.shapeType;
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
        lat = (m['lat'] as num?)?.toDouble() ??
            (m['latitude'] as num?)?.toDouble() ??
            0.0;
        lon = (m['lon'] as num?)?.toDouble() ??
            (m['longitude'] as num?)?.toDouble() ??
            0.0;
        title = m['title']?.toString();
        subtitle = m['subtitle']?.toString();
        shapeType = m['shapeType']?.toString();
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

      final drawPin = shapeType == null || shapeType == 'marker';
      if (drawPin && iconImage != null) {
        final src = Rect.fromLTWH(
            0, 0, iconImage!.width.toDouble(), iconImage!.height.toDouble());
        final destSize = headRadius * 2.0;
        final dst = Rect.fromCenter(
            center: headCenter, width: destSize, height: destSize);
        paint.isAntiAlias = true;
        canvas.drawImageRect(iconImage!, src, dst, paint);
      } else if (drawPin) {
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
