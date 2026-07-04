import 'dart:math' as math;
import 'dart:convert';
// Use the package's Dio utility for HTTP requests instead of HttpClient.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';

class MapExamplesViewModel extends ChangeNotifier {
  final FormFieldsMapNotifier mapNotifier = FormFieldsMapNotifier();

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
  int playbackInterpolationSteps = 4;

  void setPlaybackPlaying(bool v) {
    isPlaybackPlaying = v;
    notifyListeners();
  }

  void setPlaybackInterval(Duration d) {
    playbackInterval = d;
    // forward to controller so the map uses the new interval
    try {
      FormFieldsMapController.setPolylinePlaybackInterval('default', d);
    } catch (_) {}
    notifyListeners();
  }

  void setPlaybackInterpolationSteps(int s) {
    playbackInterpolationSteps = s;
    try {
      FormFieldsMapController.setPolylinePlaybackInterpolationSteps(
          'default', s);
    } catch (_) {}
    notifyListeners();
  }

  int generatedCircles = 0;
  int totalCircles = 0;

  int createMarkers = 20;
  int createPolygons = 20;
  int createPolylines = 20;
  int createCircles = 20;

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
    mapNotifier.clearRawMarkers();
    mapNotifier.clearPolygons();
    mapNotifier.clearPolylines();
    playbackPolylineId = null;
    mapNotifier.clearCircles();
    notifyListeners();
  }

  Future<void> generateDemoData(
      {int markerCount = 1000, int shapeCount = 5}) async {
    clearDemoData();
    totalMarkers = markerCount;
    totalPolygons = totalPolylines = totalCircles = shapeCount;
    isLoading = true;
    notifyListeners();

    // await generatePolygons(shapeCount: shapeCount);
    // await generatePolylines(shapeCount: shapeCount);
    // await generateCircles(shapeCount: shapeCount);

    isLoading = false;
    notifyListeners();
  }

  Future<void> generatePolygons({int shapeCount = 5}) async {
    generatedPolygons = 0;
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
      final id = mapNotifier.addPolygon(poly);
      // add a small raw marker at centroid for interaction & metadata
      final avgLat =
          pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
      final avgLng =
          pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
      mapNotifier.appendRawMarkers([
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
  }

  Future<void> generateMarkers({int markerCount = 1000}) async {
    generatedMarkers = 0;
    totalMarkers = markerCount;
    isLoading = true;
    notifyListeners();
    final rnd = math.Random(424242);

    // We'll emit raw ShapeMeta markers (consistent with polygons/polylines/circles)
    // Batch them to avoid large numbers of notifyListeners calls.
    final batch = <dynamic>[];
    for (var i = 0; i < markerCount; i++) {
      final lat = center.latitude + (rnd.nextDouble() - 0.5) * 1.2;
      final lng = center.longitude + (rnd.nextDouble() - 0.5) * 1.2;

      final meta = ShapeMeta(
        lat: lat,
        lon: lng,
        title: 'Marker #${i + 1}',
        subtitle:
            'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
        id: 'm\$${DateTime.now().microsecondsSinceEpoch}_\$i',
        shapeType: 'marker',
      );
      batch.add(meta);

      generatedMarkers = i + 1;

      if ((i & 0x1FF) == 0) {
        // flush batch every 512 items
        if (batch.isNotEmpty) {
          mapNotifier.appendRawMarkers(List<dynamic>.from(batch));
          batch.clear();
        }
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    if (batch.isNotEmpty) {
      mapNotifier.appendRawMarkers(List<dynamic>.from(batch));
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> generatePolylines({int shapeCount = 5}) async {
    generatedPolylines = 0;
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
      final id = mapNotifier.addPolyline(pl);
      // place raw marker at polyline midpoint for interaction
      final midIndex = pts.length ~/ 2;
      final mid = pts[midIndex];
      mapNotifier.appendRawMarkers([
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
    final rnd = math.Random();

    List<LatLng>? routePoints;

    if (useRoads) {
      try {
        // pick start/end near center with small offsets
        final startLat = center.latitude + (rnd.nextDouble() - 0.5) * 0.03;
        final startLng = center.longitude + (rnd.nextDouble() - 0.5) * 0.03;
        final endLat = center.latitude + (rnd.nextDouble() - 0.5) * 0.03;
        final endLng = center.longitude + (rnd.nextDouble() - 0.5) * 0.03;

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
      final baseLat = center.latitude + (rnd.nextDouble() - 0.5) * 0.01;
      final baseLng = center.longitude + (rnd.nextDouble() - 0.5) * 0.01;
      final pts = <LatLng>[];
      for (var s = 0; s < 6; s++) {
        final ang = (s / 6) * math.pi * 2;
        pts.add(LatLng(
            baseLat + math.sin(ang) * 0.02, baseLng + math.cos(ang) * 0.02));
      }
      routePoints = pts;
    }

    final pl =
        Polyline(points: routePoints, strokeWidth: 10.0, color: Colors.purple);
    final id = mapNotifier.addPolyline(pl);
    // add a marker at midpoint for interactivity
    final mid = routePoints[routePoints.length ~/ 2];
    mapNotifier.appendRawMarkers([
      ShapeMeta(
        lat: mid.latitude,
        lon: mid.longitude,
        title: 'Playback Polyline',
        subtitle: id,
        id: id,
        shapeType: 'polyline',
      )
    ]);
    playbackPolylineId = id;
    generatedPolylines = generatedPolylines + 1;
    // Ensure totalPolylines reflects that a playback polyline exists so
    // example UI that checks `totalPolylines > 0` will show controls.
    totalPolylines = (totalPolylines >= 1) ? totalPolylines : 1;
    notifyListeners();
  }

  Future<void> generateCircles({int shapeCount = 5}) async {
    generatedCircles = 0;
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
      final id = mapNotifier.addCircle(c);
      mapNotifier.appendRawMarkers([
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
  }
}
