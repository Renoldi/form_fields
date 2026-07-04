import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';

const double _tapPad = 12.0;

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
    _rawMarkersCache = coords;
    _safeNotify();
  }

  void appendRawMarkers(List<dynamic> coords) {
    final combined = List<dynamic>.from(_rawMarkersCache)..addAll(coords);
    _rawMarkersCache = List<dynamic>.from(combined);
    _safeNotify();
  }

  void clearRawMarkers() {
    _rawMarkersCache = const [];
    _safeNotify();
  }

  bool removeRawMarker(String id) {
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
    _polygonMap = {};
    for (var i = 0; i < p.length; i++) {
      _polygonMap['p\$i'] = p[i];
    }
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
  }

  set polylines(List<Polyline> p) {
    _polylineMap = {};
    for (var i = 0; i < p.length; i++) {
      _polylineMap['l\$i'] = p[i];
    }
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
  }

  set circles(List<CircleMarker> c) {
    _circleMap = {};
    for (var i = 0; i < c.length; i++) {
      _circleMap['c\$i'] = c[i];
    }
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
  }

  // Polygons
  String addPolygon(Polygon p) {
    final id = 'p\$${DateTime.now().microsecondsSinceEpoch}';
    _polygonMap[id] = p;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdatePolygon(String id, Polygon polygon) {
    _polygonMap[id] = polygon;
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
  }

  Polygon? getPolygon(String id) => _polygonMap[id];

  bool removePolygon(String id) {
    final removed = _polygonMap.remove(id) != null;
    if (removed) {
      _polygonsCache = _polygonMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearPolygons() {
    _polygonMap.clear();
    _polygonsCache = _polygonMap.values.toList(growable: false);
    _safeNotify();
  }

  // Polylines
  String addPolyline(Polyline p) {
    final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
    _polylineMap[id] = p;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdatePolyline(String id, Polyline polyline) {
    _polylineMap[id] = polyline;
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
  }

  Polyline? getPolyline(String id) => _polylineMap[id];

  bool removePolyline(String id) {
    final removed = _polylineMap.remove(id) != null;
    if (removed) {
      _polylinesCache = _polylineMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearPolylines() {
    _polylineMap.clear();
    _polylinesCache = _polylineMap.values.toList(growable: false);
    _safeNotify();
  }

  String addCircle(CircleMarker c) {
    final id = 'c\$${DateTime.now().microsecondsSinceEpoch}';
    _circleMap[id] = c;
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdateCircle(String id, CircleMarker circle) {
    _circleMap[id] = circle;
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
  }

  CircleMarker? getCircle(String id) => _circleMap[id];

  bool removeCircle(String id) {
    final removed = _circleMap.remove(id) != null;
    if (removed) {
      _circlesCache = _circleMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearCircles() {
    _circleMap.clear();
    _circlesCache = _circleMap.values.toList(growable: false);
    _safeNotify();
  }

  // Markers
  Map<String, Marker> _markerMap = {};

  List<Marker> _markersCache = const [];

  List<Marker> get markers => _markersCache;

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
    final id = 'm\$${DateTime.now().microsecondsSinceEpoch}';
    _markerMap[id] = m;
    _markersCache = _markerMap.values.toList(growable: false);
    _safeNotify();
    return id;
  }

  void addOrUpdateMarker(String id, Marker marker) {
    _markerMap[id] = marker;
    _markersCache = _markerMap.values.toList(growable: false);
    _safeNotify();
  }

  Marker? getMarker(String id) => _markerMap[id];

  bool removeMarker(String id) {
    final removed = _markerMap.remove(id) != null;
    if (removed) {
      _markersCache = _markerMap.values.toList(growable: false);
      _safeNotify();
    }
    return removed;
  }

  void clearMarkers() {
    _markerMap.clear();
    _markersCache = _markerMap.values.toList(growable: false);
    _safeNotify();
  }
}

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
    this.canvasMarkerRadius = 20.0,
    this.canvasMarkerIcon,
    this.showTitle = true,
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

  final double canvasMarkerRadius;

  final Object? canvasMarkerIcon;

  final bool showTitle;

  final bool useViewportCulling;

  final double cullingBuffer;

  final FormFieldsMapNotifier? notifier;
  final ValueChanged<ShapeMeta>? onTapShape;

  final VoidCallback? onMapReady;
  final ValueChanged<dynamic>? onPositionChanged;
  final ValueChanged<LatLng>? onMapTap;
  final ValueChanged<LatLng>? onLongPress;
  final VoidCallback? onCameraIdle;
  final Duration cameraIdleDebounce;

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

  LatLng? _lastCenter;
  double? _lastZoom;
  ImageStream? _canvasMarkerImageStream;
  ImageStreamListener? _canvasMarkerImageStreamListener;
  ui.Image? _canvasMarkerImage;

  bool _suppressNextMapTap = false;

  @override
  void initState() {
    super.initState();
    _mapController = FormFieldsMapController.getOrCreate(widget.controllerId);

    _ownsInternalNotifier = widget.notifier == null;
    _internalNotifier = widget.notifier ?? FormFieldsMapNotifier();
    _resolveCanvasMarkerIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(widget.initialCenter, widget.initialZoom);
      } catch (_) {}
      widget.onMapReady?.call();
    });

    FormFieldsMapController.registerOnMarkerTap(
        widget.controllerId, widget.onTapShape);
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      setState(fn);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
    }
  }

  @override
  void didUpdateWidget(covariant FormFieldsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canvasMarkerIcon != widget.canvasMarkerIcon) {
      _resolveCanvasMarkerIcon();
    }

    if (oldWidget.notifier != widget.notifier) {
      if (_ownsInternalNotifier) {
        try {
          _internalNotifier.dispose();
        } catch (_) {}
      }
      _ownsInternalNotifier = widget.notifier == null;
      _internalNotifier = widget.notifier ?? FormFieldsMapNotifier();
    }

    if (oldWidget.controllerId != widget.controllerId ||
        oldWidget.onTapShape != widget.onTapShape) {
      FormFieldsMapController.removeOnMarkerTap(oldWidget.controllerId);
      FormFieldsMapController.registerOnMarkerTap(
          widget.controllerId, widget.onTapShape);
    }
  }

  void _resolveCanvasMarkerIcon() {
    if (_canvasMarkerImageStream != null &&
        _canvasMarkerImageStreamListener != null) {
      _canvasMarkerImageStream!
          .removeListener(_canvasMarkerImageStreamListener!);
    }
    _canvasMarkerImageStream = null;
    _canvasMarkerImageStreamListener = null;
    final provider = widget.canvasMarkerIcon;
    if (provider == null) return;

    if (provider is ImageProvider) {
      final config = createLocalImageConfiguration(context);
      final stream = provider.resolve(config);
      _canvasMarkerImageStream = stream;
      _canvasMarkerImageStreamListener =
          ImageStreamListener((ImageInfo info, bool _) {
        _canvasMarkerImage = info.image;
        _safeSetState(() {});
      });
      stream.addListener(_canvasMarkerImageStreamListener!);
      return;
    }

    if (provider is Icon) {
      _renderIconToImage(provider).then((img) {
        _canvasMarkerImage = img;
        _safeSetState(() {});
      });
      return;
    }

    if (provider is Widget) {
      _rasterizeWidgetToImage(provider).then((img) {
        if (img != null) {
          _canvasMarkerImage = img;
          _safeSetState(() {});
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

      await Future.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        entry.remove();
        return null;
      }

      final contextForKey = key.currentContext;
      if (contextForKey == null) {
        entry.remove();
        return null;
      }

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

    try {
      final dynamic pos = position;
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
              FormFieldsMapController.setLoading(widget.controllerId, true);
            } catch (_) {}
            _safeSetState(() {});
          });
        }
      }
    } catch (_) {}

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.cameraIdleDebounce, () {
      FormFieldsMapController.setLoading(widget.controllerId, false);
      widget.onCameraIdle?.call();
    });
  }

  Future<void> animateTo(LatLng dest, double zoom,
      {Duration duration = const Duration(milliseconds: 400)}) async {
    _mapController.move(dest, zoom);
    _lastCenter = dest;
    _lastZoom = zoom;
  }

  Future<void> fitBounds(LatLngBounds bounds,
      {EdgeInsets padding = EdgeInsets.zero,
      Duration duration = const Duration(milliseconds: 400)}) async {
    final center = bounds.center;

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
              Selector<FormFieldsMapNotifier, List<Polygon>>(
                selector: (_, n) => n.polygons,
                builder: (context, polygons, _) {
                  if (polygons.isEmpty) return const SizedBox.shrink();
                  return PolygonLayer(polygons: polygons);
                },
              ),
              Selector<FormFieldsMapNotifier, List<Polyline>>(
                selector: (_, n) => n.polylines,
                builder: (context, polylines, _) {
                  if (polylines.isEmpty) return const SizedBox.shrink();
                  return PolylineLayer(polylines: polylines);
                },
              ),
              Selector<FormFieldsMapNotifier, List<CircleMarker>>(
                selector: (_, n) => n.circles,
                builder: (context, circles, _) {
                  if (circles.isEmpty) return const SizedBox.shrink();
                  return CircleLayer(circles: circles);
                },
              ),
              Selector<FormFieldsMapNotifier, List<Marker>>(
                selector: (_, n) => n.markers,
                builder: (context, markers, _) {
                  if (markers.isEmpty) return const SizedBox.shrink();
                  return MarkerLayer(markers: markers);
                },
              ),
              Selector<FormFieldsMapNotifier, List<dynamic>>(
                selector: (_, n) => n.rawMarkers,
                builder: (context, rawMarkers, _) {
                  if (rawMarkers.isEmpty) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CanvasRawMarkerPainter(
                          rawMarkers: rawMarkers,
                          center: _lastCenter ?? widget.initialCenter,
                          zoom: _lastZoom ?? widget.initialZoom,
                          radius: widget.canvasMarkerRadius,
                          devicePixelRatio:
                              MediaQuery.of(context).devicePixelRatio,
                          iconImage: _canvasMarkerImage,
                          showTitle: widget.showTitle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          top: 10,
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

              AppButton(
                type: AppButtonType.fab,
                size: AppSize.small,
                icon: const Icon(Icons.my_location),
                useSafeArea: false,
                heroTag: null,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  LatLng? target;
                  if (widget.onRequestCurrentLocation != null) {
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
    if (_suppressNextMapTap) {
      _suppressNextMapTap = false;
      return;
    }
    try {
      final notifier = widget.notifier ?? _internalNotifier;

      // Compute local tap offset once for pixel-based hit tests.
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

      // Polygons: point-in-polygon test. If point-in-polygon fails, also
      // perform an edge-distance fallback so thin polygons or borders are
      // still tappable.
      final tapZoom = _lastZoom ?? widget.initialZoom;
      final center = _lastCenter ?? widget.initialCenter;
      final centerX =
          _CanvasRawMarkerPainter._worldX(center.longitude, tapZoom);
      final centerY = _CanvasRawMarkerPainter._worldY(center.latitude, tapZoom);
      final double worldSize = 256 * pow(2, tapZoom).toDouble();
      // Increase hit padding slightly and scale with device pixel ratio so
      // taps are easier on denser screens and at intermediate zoom levels.
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final double extraTapPad = max(_tapPad, devicePixelRatio * 6.0) + 8.0;
      final double baseThreshPx = 24.0 + extraTapPad;

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
            if (distPx < minEdgeDist) minEdgeDist = distPx;
          }
          if (minEdgeDist <= max(baseThreshPx, 16.0)) {
            final meta = _findMetaForShape(notifier, pid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = pid;
            mapPayload['shapeType'] = 'polygon';
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
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
      for (final entry in notifier._polylineMap.entries) {
        final lid = entry.key;
        final pl = entry.value;
        final pts = pl.points;
        final stroke = pl.strokeWidth;
        final threshPx = max(baseThreshPx, stroke * 3.0 + 16.0);
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
        mapPayload['shapeType'] = 'polyline';
        mapPayload['lat'] = latlng.latitude;
        mapPayload['lon'] = latlng.longitude;
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

      for (final entry in notifier._circleMap.entries) {
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
            // building ShapeMeta from payload (log removed)
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
      // Markers: check rawMarkers canvas items for proximity to tap
      try {
        final radiusToUse = max(widget.canvasMarkerRadius, 6.0);
        final headOffsetMul = 0.6;
        final headRadiusMul = 0.9;
        final size = context.size ?? Size.zero;
        for (final m in notifier.rawMarkers) {
          double lat;
          double lon;
          String? title;
          String? subtitle;
          String? shapeType;
          String? id;
          if (m is ShapeMeta) {
            lat = m.lat;
            lon = m.lon;
            title = m.title;
            subtitle = m.subtitle;
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
            lat = (m['lat'] as num?)?.toDouble() ??
                (m['latitude'] as num?)?.toDouble() ??
                0.0;
            lon = (m['lon'] as num?)?.toDouble() ??
                (m['longitude'] as num?)?.toDouble() ??
                0.0;
            title = m['title']?.toString();
            subtitle = m['subtitle']?.toString();
            shapeType = m['shapeType']?.toString();
            id = m['id']?.toString();
          } else {
            continue;
          }

          final x = _CanvasRawMarkerPainter._worldX(lon, tapZoom);
          final y = _CanvasRawMarkerPainter._worldY(lat, tapZoom);

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
            mapPayload['shapeType'] = shapeType ?? 'marker';
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
                  fontWeight: FontWeight.w600);
              final lines = <String>[];
              if (title != null && title.isNotEmpty) lines.add(title);
              if (subtitle != null && subtitle.isNotEmpty) lines.add(subtitle);
              final tp = TextPainter(textDirection: TextDirection.ltr);
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
                  center: Offset(headCenter.dx,
                      headCenter.dy - headRadius - bgHeight / 2 - 6),
                  width: bgWidth,
                  height: bgHeight);

              if (bgRect.inflate(extraTapPad).contains(local)) {
                final mapPayload = <String, dynamic>{};
                if (m is Map) mapPayload.addAll(Map<String, dynamic>.from(m));
                mapPayload['lat'] = lat;
                mapPayload['lon'] = lon;
                if (id != null) mapPayload['id'] = id;
                mapPayload['shapeType'] = shapeType ?? 'marker';
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

  void _handleLongPress(TapPosition tapPosition, LatLng latlng) {
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
}

double _pointToSegmentDistance(Offset p, Offset v, Offset w) {
  final l2 = pow((v.dx - w.dx), 2) + pow((v.dy - w.dy), 2);
  if (l2 == 0) return (p - v).distance;
  var t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
  t = t.clamp(0.0, 1.0);
  final proj = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
  return (p - proj).distance;
}

class _CanvasRawMarkerPainter extends CustomPainter {
  _CanvasRawMarkerPainter({
    required this.rawMarkers,
    required this.center,
    required this.zoom,
    required this.radius,
    required this.devicePixelRatio,
    this.iconImage,
    this.showTitle = true,
  });

  final List<dynamic> rawMarkers;
  final LatLng center;
  final double zoom;
  final double radius;
  final double devicePixelRatio;
  final ui.Image? iconImage;
  final bool showTitle;

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
      if (m is ShapeMeta) {
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

      // Draw title / subtitle if present and enabled
      if (showTitle &&
          ((title != null && title.isNotEmpty) ||
              (subtitle != null && subtitle.isNotEmpty))) {
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
        oldDelegate.iconImage != iconImage ||
        oldDelegate.showTitle != showTitle;
  }
}
