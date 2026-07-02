import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';

class MapExamplesViewModel extends ChangeNotifier {
  LatLng center = const LatLng(-6.200000, 106.816666); // Jakarta as default

  // Expose a ChangeNotifier-based map notifier so the map can update layers
  // (markers/polygons/polylines/circles) without rebuilding the parent.
  final mapNotifier = FormFieldsMapNotifier(
      markers: <Marker>[],
      polygons: <Polygon>[],
      polylines: <Polyline>[],
      circles: <CircleMarker>[]);

  MapExamplesViewModel() {
    mapNotifier.markers = [
      Marker(
        point: center,
        width: 36,
        height: 36,
        builder: (_) => const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 36,
        ),
      ),
    ];
  }

  /// Loading indicator for long-running generation.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Generate demo dataset: 1000 markers and 20 polygons/polylines/circles.
  Future<void> generateDemoData() async {
    _isLoading = true;
    // Signal the map widget to show its loading overlay via the controller
    FormFieldsMapController.setLoading('default', true);
    notifyListeners();

    try {
      final raw = await compute(_generateDemoRawData, {
        'centerLat': center.latitude,
        'centerLng': center.longitude,
        'seed': 12345,
        'markerCount': 1000,
        'shapeCount': 20,
      });

      final markers = <Marker>[];
      for (final m in (raw['markers'] as List)) {
        final lat = (m as List)[0] as double;
        final lng = m[1] as double;
        markers.add(Marker(
          point: LatLng(lat, lng),
          width: 36,
          height: 36,
          builder: (_) => Icon(
            Icons.location_on,
            color: Colors.blue.withValues(alpha: 0.95),
            size: 24,
          ),
        ));
      }

      final polygons = <Polygon>[];
      for (final p in (raw['polygons'] as List)) {
        final pts = (p as List)
            .map<LatLng>((e) => LatLng(e[0] as double, e[1] as double))
            .toList();
        polygons.add(Polygon(
          points: pts,
          color: Colors.green.withValues(alpha: 0.25),
          borderStrokeWidth: 1.5,
          borderColor: Colors.green,
        ));
      }

      final polylines = <Polyline>[];
      for (final l in (raw['polylines'] as List)) {
        final pts = (l as List)
            .map<LatLng>((e) => LatLng(e[0] as double, e[1] as double))
            .toList();
        polylines
            .add(Polyline(points: pts, strokeWidth: 2.0, color: Colors.orange));
      }

      final circles = <CircleMarker>[];
      for (final c in (raw['circles'] as List)) {
        final lat = (c as List)[0] as double;
        final lng = c[1] as double;
        final radius = c[2] as double;
        circles.add(CircleMarker(
          point: LatLng(lat, lng),
          color: Colors.purple.withValues(alpha: 0.25),
          borderColor: Colors.purple,
          borderStrokeWidth: 1.5,
          useRadiusInMeter: true,
          radius: radius,
        ));
      }

      mapNotifier.markers = markers;
      mapNotifier.polygons = polygons;
      mapNotifier.polylines = polylines;
      mapNotifier.circles = circles;
    } catch (e, st) {
      debugPrint('generateDemoData failed: $e\n$st');
    } finally {
      _isLoading = false;
      FormFieldsMapController.setLoading('default', false);
      notifyListeners();
    }
  }

  void clearDemoData() {
    mapNotifier.clearMarkers();
    mapNotifier.clearPolygons();
    mapNotifier.clearPolylines();
    mapNotifier.clearCircles();
    notifyListeners();
  }
}

/// Top-level compute handler that generates raw primitive data so the heavy
/// work runs off the UI thread. Returns plain Lists/Maps suitable for sending
/// across an isolate boundary.
Map<String, dynamic> _generateDemoRawData(Map args) {
  final double centerLat = args['centerLat'] as double;
  final double centerLng = args['centerLng'] as double;
  final int seed = args['seed'] as int;
  final int markerCount = args['markerCount'] as int;
  final int shapeCount = args['shapeCount'] as int;

  final rand = Random(seed);
  final seen = <String>{};
  final markers = <List<double>>[];
  while (markers.length < markerCount) {
    final lat = centerLat + (rand.nextDouble() - 0.5) * 0.6;
    final lng = centerLng + (rand.nextDouble() - 0.5) * 0.6;
    final key = '\${lat.toStringAsFixed(6)}|\${lng.toStringAsFixed(6)}';
    if (seen.contains(key)) continue;
    seen.add(key);
    markers.add([lat, lng]);
  }

  final polygons = <List<List<double>>>[];
  final polylines = <List<List<double>>>[];
  final circles = <List<double>>[]; // [lat, lng, radiusMeters]

  for (var i = 0; i < shapeCount; i++) {
    final baseLat = centerLat + (rand.nextDouble() - 0.5) * 1.5;
    final baseLng = centerLng + (rand.nextDouble() - 0.5) * 1.5;

    polygons.add([
      [baseLat, baseLng],
      [baseLat + 0.01, baseLng + 0.02],
      [baseLat - 0.01, baseLng + 0.02],
    ]);

    final linePoints = List<List<double>>.generate(6, (j) {
      return [baseLat + (j - 3) * 0.002, baseLng + (j % 2 == 0 ? 0.0 : 0.01)];
    });
    polylines.add(linePoints);

    circles.add([baseLat + 0.02, baseLng, 200.0]);
  }

  return {
    'markers': markers,
    'polygons': polygons,
    'polylines': polylines,
    'circles': circles,
  };
}
