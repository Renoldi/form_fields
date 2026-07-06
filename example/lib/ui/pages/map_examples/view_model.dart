import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
// Use the package's Dio utility for HTTP requests instead of HttpClient.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';

class MapExamplesViewModel extends ChangeNotifier {
  final MapController mapController = MapController();
  MapExamplesViewModel();
  String get controllerId =>
      FormFieldsMapController.getIdForController(mapController);

  // Timer for periodic marker updates
  Timer? _markerUpdateTimer;
  // Timer for countdown UI updates (1s ticks)
  Timer? _markerCountdownTimer;
  final math.Random _updateRnd = math.Random();

  // Default center (Jakarta)
  LatLng center = const LatLng(-6.2, 106.8166);

  bool useCanvasMarkers = false;
  bool showTitle = true;

  // Progress counters
  bool isLoading = false;
  int generatedMarkers = 0;
  int totalMarkers = 0;

  int generatedPolygons = 0;
  int totalPolygons = 0;

  int generatedPolylines = 0;
  int totalPolylines = 0;
  String? playbackPolylineId;
  bool isPlaybackPlaying = false;

  /// Local UI state for selected playback interval and interpolation steps
  /// so buttons in the example can reflect current selection.
  Duration playbackInterval = const Duration(seconds: 1);
  int playbackInterpolationSteps = 0;

  void setPlaybackPlaying(bool v) {
    isPlaybackPlaying = v;
    notifyListeners();
  }

  void setPlaybackInterval(Duration d) {
    playbackInterval = d;
    // forward to controller so the map uses the new interval
    try {
      mapController.setPolylinePlaybackInterval(d);
    } catch (_) {}
    notifyListeners();
  }

  void setPlaybackInterpolationSteps(int s) {
    playbackInterpolationSteps = s;
    try {
      mapController.setPolylinePlaybackInterpolationSteps(s);
    } catch (_) {}
    notifyListeners();
  }

  int generatedCircles = 0;
  int totalCircles = 0;

  int createMarkers = 20;
  int createPolygons = 20;
  int createPolylines = 20;
  int createCircles = 20;

  // Periodic update interval and countdown state
  Duration markerUpdateInterval = const Duration(minutes: 1);
  int markerUpdateRemainingSeconds = 0;

  /// If true, periodic updates will assign fully random coordinates
  /// (within `markerUpdateRandomRangeDegrees` around `center`) instead of
  /// small nudges.
  bool markerUpdateRandomizeCoordinates = true;

  /// Range in degrees used when `markerUpdateRandomizeCoordinates` is true.
  /// Default ~3 degrees box (same scale as initial generation).
  double markerUpdateRandomRangeDegrees = 3.0;

  void commit() {
    notifyListeners();
  }

  void setShowTitle(bool v) {
    showTitle = v;
    notifyListeners();
  }

  void clearDemoData() {
    isLoading = false;
    generatedMarkers = totalMarkers = 0;
    generatedPolygons = totalPolygons = 0;
    generatedPolylines = totalPolylines = 0;
    generatedCircles = totalCircles = 0;
    mapController.clearRawMarkers();
    mapController.clearPolygons();
    mapController.clearPolylines();
    playbackPolylineId = null;
    mapController.clearCircles();
    notifyListeners();
  }

  Future<void> generateDemoData(
      {int markerCount = 1000, int shapeCount = 5}) async {
    clearDemoData();
    totalMarkers = markerCount;
    totalPolygons = totalPolylines = totalCircles = shapeCount;
    isLoading = true;
    notifyListeners();
    try {
      mapController.setBlockingLoading(true);
    } catch (_) {}

    // await generatePolygons(shapeCount: shapeCount);
    // await generatePolylines(shapeCount: shapeCount);
    // await generateCircles(shapeCount: shapeCount);

    isLoading = false;
    notifyListeners();
    try {
      mapController.setBlockingLoading(false);
    } catch (_) {}
  }

  Future<void> generatePolygons({int shapeCount = 5}) async {
    isLoading = true;
    notifyListeners();
    // try {
    //   mapController.setBlockingLoading(true);
    // } catch (_) {}
    try {
      generatedPolygons = 0;
      totalPolygons = shapeCount;
      final rnd = math.Random(54321);

      for (var i = 0; i < shapeCount; i++) {
        final baseLat = center.latitude + (rnd.nextDouble() - 0.5) * 0.8;
        final baseLng = center.longitude + (rnd.nextDouble() - 0.5) * 0.8;
        final pts = <LatLng>[];
        final sides = 4 + (rnd.nextInt(3));
        final radiusDeg = 0.02 + rnd.nextDouble() * 0.06;
        for (var s = 0; s < sides; s++) {
          final ang = (s / sides) * math.pi * 2;
          pts.add(LatLng(baseLat + math.sin(ang) * radiusDeg,
              baseLng + math.cos(ang) * radiusDeg));
        }
        final poly = Polygon(
          points: pts,
          color: Colors.green.withValues(alpha: 0.25),
          borderColor: Colors.green,
          borderStrokeWidth: 2,
        );
        final id = FormFieldsMapController.addPolygon(controllerId, poly) ??
            'p_unknown';
        // add a small raw marker at centroid for interaction & metadata
        final avgLat =
            pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
        final avgLng =
            pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
        await mapController.appendRawMarkers([
          ShapeMeta(
            lat: avgLat,
            lon: avgLng,
            title: 'Polygon #${i + 1}',
            subtitle: id,
            id: id,
            shapeType: 'polygon',
          )
        ]);
        generatedPolygons = i + 1;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1));
      }
    } finally {
      isLoading = false;
      notifyListeners();
      // try {
      //   mapController.setBlockingLoading(false);
      // } catch (_) {}
    }
  }

  Future<void> generateMarkers({int markerCount = 1000}) async {
    debugPrint('generateMarkers called with count=$markerCount');
    generatedMarkers = 0;
    totalMarkers = markerCount;
    isLoading = true;
    notifyListeners();
    // try {
    //   mapController.setBlockingLoading(true);
    // } catch (_) {}

    // Give the UI one frame to render the blocking overlay.
    await Future.delayed(Duration.zero);

    // Use compute to generate marker data off the main thread.
    final raw = await compute(_generateMarkersIsolate, {
      'count': markerCount,
      'seed': 424242,
      'centerLat': center.latitude,
      'centerLng': center.longitude,
    });

    // Convert and append in batches on the main isolate.
    const batchSize = 512;
    var idx = 0;
    while (idx < raw.length) {
      final end = (idx + batchSize).clamp(0, raw.length);
      final slice = raw.sublist(idx, end);
      final batch = <dynamic>[];
      for (var m in slice) {
        batch.add(ShapeMeta(
          lat: (m['lat'] as num).toDouble(),
          lon: (m['lon'] as num).toDouble(),
          title: m['title'] as String?,
          subtitle: m['subtitle'] as String?,
          id: m['id'] as String?,
          shapeType: m['shapeType'] as String?,
        ));
      }
      await mapController.appendRawMarkers(List<dynamic>.from(batch));
      generatedMarkers = end;
      debugPrint(
          'generateMarkers appended a batch, generated=$generatedMarkers');
      try {
        final cur = mapController.getRawMarkers();
        debugPrint(
            'generateMarkers after append, registry rawMarkers=${cur.length}');
      } catch (_) {}
      notifyListeners();
      // yield back to event loop briefly so UI can update
      await Future.delayed(const Duration(milliseconds: 1));
      idx = end;
    }

    // Start periodic updates after markers are generated.
    startPeriodicMarkerUpdates();

    isLoading = false;
    notifyListeners();
    try {
      final cur = mapController.getRawMarkers();
      debugPrint('generateMarkers complete, registry rawMarkers=${cur.length}');
    } catch (_) {}
    debugPrint('generateMarkers finished, total generated=$generatedMarkers');
    // try {
    //   mapController.setBlockingLoading(false);
    // } catch (_) {}
  }

  Future<void> generatePolylines({int shapeCount = 5}) async {
    isLoading = true;
    notifyListeners();
    // try {
    //   mapController.setBlockingLoading(true);
    // } catch (_) {}
    try {
      generatedPolylines = 0;
      totalPolylines = shapeCount;
      final rnd = math.Random(98765);

      for (var i = 0; i < shapeCount; i++) {
        final baseLat = center.latitude + (rnd.nextDouble() - 0.5) * 0.8;
        final baseLng = center.longitude + (rnd.nextDouble() - 0.5) * 0.8;
        final pts = <LatLng>[];
        final segs = 3 + rnd.nextInt(5);
        final step = 0.02 + rnd.nextDouble() * 0.04;
        for (var s = 0; s < segs; s++) {
          pts.add(LatLng(baseLat + (s - segs / 2) * step,
              baseLng + (rnd.nextDouble() - 0.5) * step));
        }
        final pl = Polyline(points: pts, strokeWidth: 10.0, color: Colors.blue);
        final id = mapController.addPolyline(pl) ?? 'l_unknown';
        // place raw marker at polyline midpoint for interaction
        final midIndex = pts.length ~/ 2;
        final mid = pts[midIndex];
        await mapController.appendRawMarkers([
          ShapeMeta(
            lat: mid.latitude,
            lon: mid.longitude,
            title: 'Polyline #${i + 1}',
            subtitle: id,
            id: id,
            shapeType: 'polyline',
          )
        ]);
        generatedPolylines = i + 1;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1));
      }
    } finally {
      isLoading = false;
      notifyListeners();
      // try {
      //   mapController.setBlockingLoading(false);
      // } catch (_) {}
    }
  }

  /// Start periodic updates of existing raw markers. Each tick will slightly
  /// perturb marker coordinates to simulate movement. Default interval is
  /// 1 minute.
  void startPeriodicMarkerUpdates(
      {Duration interval = const Duration(minutes: 1), bool randomize = true}) {
    stopPeriodicMarkerUpdates();
    markerUpdateInterval = interval;
    markerUpdateRemainingSeconds = interval.inSeconds;
    markerUpdateRandomizeCoordinates = randomize;
    // Timer that performs the actual marker update
    _markerUpdateTimer = Timer.periodic(interval, (_) {
      _updateMarkersOnce();
      markerUpdateRemainingSeconds = interval.inSeconds;
      notifyListeners();
    });
    // Countdown timer for UI (updates every second)
    _markerCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (markerUpdateRemainingSeconds > 0) {
        markerUpdateRemainingSeconds -= 1;
      } else {
        markerUpdateRemainingSeconds = interval.inSeconds;
      }
      notifyListeners();
    });
  }

  /// Stop periodic marker updates.
  void stopPeriodicMarkerUpdates() {
    try {
      _markerUpdateTimer?.cancel();
    } catch (_) {}
    try {
      _markerCountdownTimer?.cancel();
    } catch (_) {}
    _markerUpdateTimer = null;
    _markerCountdownTimer = null;
    markerUpdateRemainingSeconds = 0;
    notifyListeners();
  }

  /// Perform a single in-place update of the raw markers (via controller)
  /// each `ShapeMeta` (or map-style marker) by a small random delta.
  void _updateMarkersOnce() {
    try {
      try {
        mapController.setBlockingLoading(true);
      } catch (_) {}

      final current = mapController.getRawMarkers();
      debugPrint('_updateMarkersOnce called, current=${current.length}');
      if (current.isEmpty) return;
      final updated = <dynamic>[];
      for (final m in current) {
        if (m is ShapeMeta) {
          double newLat;
          double newLon;
          if (markerUpdateRandomizeCoordinates) {
            // assign completely random coordinates within range around center
            newLat = center.latitude +
                (_updateRnd.nextDouble() - 0.5) *
                    markerUpdateRandomRangeDegrees;
            newLon = center.longitude +
                (_updateRnd.nextDouble() - 0.5) *
                    markerUpdateRandomRangeDegrees;
          } else {
            // small movement in degrees (~up to ~0.005 deg)
            final dLat = (_updateRnd.nextDouble() - 0.5) * 0.01;
            final dLon = (_updateRnd.nextDouble() - 0.5) * 0.01;
            newLat = m.lat + dLat;
            newLon = m.lon + dLon;
          }
          final cm = ShapeMeta(
            lat: newLat,
            lon: newLon,
            title: m.title,
            subtitle: m.subtitle,
            id: m.id,
            address: m.address,
            shapeType: m.shapeType,
            rotation: m.rotation,
            color: m.color,
          );
          updated.add(cm);
        } else if (m is Map) {
          double newLat;
          double newLon;
          if (markerUpdateRandomizeCoordinates) {
            newLat = center.latitude +
                (_updateRnd.nextDouble() - 0.5) *
                    markerUpdateRandomRangeDegrees;
            newLon = center.longitude +
                (_updateRnd.nextDouble() - 0.5) *
                    markerUpdateRandomRangeDegrees;
          } else {
            final lat = (m['lat'] as num?)?.toDouble() ?? 0.0;
            final lon = (m['lon'] as num?)?.toDouble() ?? 0.0;
            final dLat = (_updateRnd.nextDouble() - 0.5) * 0.01;
            final dLon = (_updateRnd.nextDouble() - 0.5) * 0.01;
            newLat = lat + dLat;
            newLon = lon + dLon;
          }
          final copy = Map<String, dynamic>.from(m);
          copy['lat'] = newLat;
          copy['lon'] = newLon;
          updated.add(copy);
        } else {
          updated.add(m);
        }
      }
      mapController.setRawMarkers(List<dynamic>.from(updated));
      notifyListeners();
      debugPrint('_updateMarkersOnce completed, updated=${updated.length}');
    } catch (_) {
      // ignore
    } finally {
      try {
        mapController.setBlockingLoading(false);
      } catch (_) {}
    }
  }

  /// Whether periodic marker updates are currently active.
  bool get markerUpdatesActive => _markerUpdateTimer != null;

  /// Human-friendly mm:ss countdown until next marker update.
  String get markerUpdateCountdownFormatted {
    final s = markerUpdateRemainingSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void dispose() {
    stopPeriodicMarkerUpdates();
    try {
      // Ensure notifier is removed from the global registry to avoid leaks
      // if the view registered it earlier.
      try {
        mapController.removeNotifier();
      } catch (_) {}
      super.dispose();
    } catch (_) {
      // ignore
    }
  }

  /// Generate a single polyline near the current center and mark it as the
  /// playback polyline (so the example UI can start playback for this one).
  /// Generate a single polyline for playback.
  ///
  /// If [useRoads] is true this will try to request a routed path from the
  /// public OSRM demo server between two nearby points so the polyline follows
  /// roads. If the network request fails, falls back to a simple circular
  /// polyline near the center.
  Future<void> generatePlaybackPolyline({bool useRoads = true}) async {
    isLoading = true;
    notifyListeners();
    try {
      mapController.setBlockingLoading(true);
    } catch (_) {}
    try {
      final rnd = math.Random();

      List<LatLng>? routePoints;

      if (useRoads) {
        try {
          // pick start/end near center with larger offsets so the route is
          // longer and more suitable for playback (more points / distance).
          final offsetMultiplier = 0.5; // larger than previous 0.03
          final startLat =
              center.latitude + (rnd.nextDouble() - 0.5) * offsetMultiplier;
          final startLng =
              center.longitude + (rnd.nextDouble() - 0.5) * offsetMultiplier;
          final endLat =
              center.latitude + (rnd.nextDouble() - 0.5) * offsetMultiplier;
          final endLng =
              center.longitude + (rnd.nextDouble() - 0.5) * offsetMultiplier;

          final url =
              'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';
          try {
            final resp = await DioUtil.get(url);
            if (resp.statusCode == 200 && resp.data != null) {
              final dynamic parsed = resp.data is String
                  ? json.decode(resp.data as String)
                  : resp.data;
              if (parsed is Map &&
                  parsed['routes'] is List &&
                  parsed['routes'].isNotEmpty) {
                final geom = parsed['routes'][0]['geometry'];
                if (geom is Map && geom['coordinates'] is List) {
                  final coords = geom['coordinates'] as List;
                  routePoints = coords
                      .map<LatLng?>((c) {
                        if (c is List && c.length >= 2) {
                          final lon = (c[0] as num).toDouble();
                          final lat = (c[1] as num).toDouble();
                          return LatLng(lat, lon);
                        }
                        return null;
                      })
                      .whereType<LatLng>()
                      .toList(growable: false);
                }
              }
            }
          } catch (_) {
            routePoints = null;
          }
        } catch (_) {
          routePoints = null;
        }
      }

      // Fallback: circular polyline near center
      if (routePoints == null || routePoints.isEmpty) {
        // Fallback: create a larger circular polyline with more points so
        // playback has more steps and covers a wider area.
        final baseLat = center.latitude + (rnd.nextDouble() - 0.5) * 0.02;
        final baseLng = center.longitude + (rnd.nextDouble() - 0.5) * 0.02;
        final pts = <LatLng>[];
        const int fallbackSegments = 12; // more segments -> denser path
        const double fallbackRadius = 0.04; // larger radius for longer route
        for (var s = 0; s < fallbackSegments; s++) {
          final ang = (s / fallbackSegments) * math.pi * 2;
          pts.add(LatLng(baseLat + math.sin(ang) * fallbackRadius,
              baseLng + math.cos(ang) * fallbackRadius));
        }
        routePoints = pts;
      } else {
        // If OSRM returned a very short route (few points), enrich it by
        // interpolating extra points between consecutive coordinates so
        // playback has smoother movement.
        if (routePoints.length < 8) {
          final enriched = <LatLng>[];
          const int interpPerSegment = 3;
          for (var i = 0; i < routePoints.length - 1; i++) {
            final a = routePoints[i];
            final b = routePoints[i + 1];
            enriched.add(a);
            for (var k = 1; k <= interpPerSegment; k++) {
              final t = k / (interpPerSegment + 1);
              enriched.add(LatLng(a.latitude + (b.latitude - a.latitude) * t,
                  a.longitude + (b.longitude - a.longitude) * t));
            }
          }
          enriched.add(routePoints.last);
          routePoints = enriched;
        }
      }

      // Animate camera to the first point so playback starts in view.
      try {
        final start = routePoints.first;
        final double targetZoom =
            const FormFieldsMapPlaybackConfig().playbackZoom;
        await mapController.animateCameraTo(start, targetZoom,
            duration: const Duration(milliseconds: 600),
            curve: const FormFieldsMapPlaybackConfig().playbackCurve);
      } catch (_) {}

      final pl = Polyline(
          points: routePoints, strokeWidth: 10.0, color: Colors.purple);
      final id = mapController.addPolyline(pl) ?? 'l_unknown';
      // add a marker at midpoint for interactivity and compute rotation
      final midIndex = routePoints.length ~/ 2;
      final mid = routePoints[midIndex];
      double rotation = 0.0;
      try {
        if (routePoints.length > 1) {
          final from = midIndex > 0
              ? routePoints[midIndex - 1]
              : routePoints[(midIndex + 1).clamp(0, routePoints.length - 1)];
          final lat1 = from.latitude * math.pi / 180.0;
          final lat2 = mid.latitude * math.pi / 180.0;
          final dLon = (mid.longitude - from.longitude) * math.pi / 180.0;
          final y = math.sin(dLon) * math.cos(lat2);
          final x = math.cos(lat1) * math.sin(lat2) -
              math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
          var brng = math.atan2(y, x) * 180.0 / math.pi;
          brng = (brng + 360.0) % 360.0;
          rotation = brng;
        }
      } catch (_) {
        rotation = 0.0;
      }

      await mapController.appendRawMarkers([
        ShapeMeta(
          lat: mid.latitude,
          lon: mid.longitude,
          title: 'Playback Polyline',
          subtitle: id,
          id: id,
          shapeType: 'polyline',
          rotation: rotation,
        )
      ]);
      playbackPolylineId = id;
      generatedPolylines = generatedPolylines + 1;
      // Ensure totalPolylines reflects that a playback polyline exists so
      // example UI that checks `totalPolylines > 0` will show controls.
      totalPolylines = (totalPolylines >= 1) ? totalPolylines : 1;
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
      try {
        mapController.setBlockingLoading(false);
      } catch (_) {}
    }
  }

  // animateCameraTo moved to MapController extension; use that instead.

  Future<void> generateCircles({int shapeCount = 5}) async {
    isLoading = true;
    notifyListeners();
    try {
      FormFieldsMapController.setBlockingLoading(controllerId, true);
    } catch (_) {}
    try {
      generatedCircles = 0;
      totalCircles = shapeCount;
      final rnd = math.Random(19283);

      for (var i = 0; i < shapeCount; i++) {
        final lat = center.latitude + (rnd.nextDouble() - 0.5) * 0.8;
        final lng = center.longitude + (rnd.nextDouble() - 0.5) * 0.8;
        final c = CircleMarker(
          point: LatLng(lat, lng),
          color: Colors.orange.withValues(alpha: 0.35),
          borderStrokeWidth: 2,
          borderColor: Colors.orange,
          // Use meters so circle scales with map zoom instead of fixed pixels
          useRadiusInMeter: true,
          radius: 800.0,
        );
        final id = mapController.addCircle(c) ?? 'c_unknown';
        await mapController.appendRawMarkers([
          ShapeMeta(
            lat: lat,
            lon: lng,
            title: 'Circle #${i + 1}',
            subtitle: id,
            id: id,
            shapeType: 'circle',
          )
        ]);
        generatedCircles = i + 1;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1));
      }
    } finally {
      isLoading = false;
      notifyListeners();
      try {
        mapController.setBlockingLoading(false);
      } catch (_) {}
    }
  }
}

// Top-level isolate entrypoint for generating simple marker payloads.
// Returns a List<Map<String, dynamic>> where each map is a serializable
// descriptor of a marker that can be converted to `ShapeMeta` on the
// main isolate.
List<Map<String, dynamic>> _generateMarkersIsolate(Map<String, dynamic> args) {
  final count = args['count'] as int? ?? 0;
  final seed = args['seed'] as int? ?? 0;
  final centerLat = (args['centerLat'] as num?)?.toDouble() ?? 0.0;
  final centerLng = (args['centerLng'] as num?)?.toDouble() ?? 0.0;
  final rnd = math.Random(seed);
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < count; i++) {
    final lat = centerLat + (rnd.nextDouble() - 0.5) * 3;
    final lng = centerLng + (rnd.nextDouble() - 0.5) * 3;
    out.add({
      'lat': lat,
      'lon': lng,
      'title': 'Marker #${i + 1}',
      'subtitle':
          'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
      'id': 'm${DateTime.now().microsecondsSinceEpoch}_$i',
      'shapeType': 'marker',
    });
  }
  return out;
}
