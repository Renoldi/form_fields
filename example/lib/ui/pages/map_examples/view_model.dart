import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';

class MapExamplesViewModel extends ChangeNotifier {
  final FormFieldsMapNotifier mapNotifier = FormFieldsMapNotifier();

  // Default center (Jakarta)
  LatLng center = const LatLng(-6.2, 106.8166);

  bool useCanvasMarkers = false;

  // Progress counters
  bool isLoading = false;
  int generatedMarkers = 0;
  int totalMarkers = 0;

  int generatedPolygons = 0;
  int totalPolygons = 0;

  int generatedPolylines = 0;
  int totalPolylines = 0;

  int generatedCircles = 0;
  int totalCircles = 0;

  void commit() {
    notifyListeners();
  }

  void clearDemoData() {
    isLoading = false;
    generatedMarkers = totalMarkers = 0;
    generatedPolygons = totalPolygons = 0;
    generatedPolylines = totalPolylines = 0;
    generatedCircles = totalCircles = 0;
    mapNotifier.clearMarkers();
    mapNotifier.clearRawMarkers();
    mapNotifier.clearPolygons();
    mapNotifier.clearPolylines();
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

    await generateMarkers(markerCount);
    // await generatePolygons(shapeCount: shapeCount);
    // await generatePolylines(shapeCount: shapeCount);
    // await generateCircles(shapeCount: shapeCount);

    isLoading = false;
    notifyListeners();
  }

  Future<void> generateMarkers(int count) async {
    generatedMarkers = 0;
    final rnd = math.Random(12345);
    final markers = <Marker>[];
    final rawBatch = <dynamic>[];

    // Build in small batches so UI can update progress.
    for (var i = 0; i < count; i++) {
      final lat = center.latitude + (rnd.nextDouble() - 0.5) * 0.5;
      final lng = center.longitude + (rnd.nextDouble() - 0.5) * 0.5;
      // Title/subtitle for this marker
      final title = 'Marker #${i + 1}';
      final subtitle = 'Generated';

      // If using canvas markers, only append raw coords (with metadata)
      // for fast rendering
      if (useCanvasMarkers) {
        final id = 'm\$${DateTime.now().microsecondsSinceEpoch}_$i';
        rawBatch.add(ShapeMeta(
          lat: lat,
          lon: lng,
          title: title,
          subtitle: subtitle,
          id: id,
          shapeType: 'marker',
        ));
      } else {
        final m = Marker(
            point: LatLng(lat, lng),
            // width: 36,
            // height: 36,
            // child: markerChild,
            width: 60,
            height: 60,
            child: const Icon(Icons.location_on, color: Colors.red)
            // GestureDetector(
            //   onTap: () {
            //     // Trigger the shared map onMarkerTap handler via controller id.\
            //     debugPrint('Marker tapped: $title, $subtitle');
            //     FormFieldsMapController.invokeOnMarkerTap('default', {
            //       'title': title,
            //       'subtitle': subtitle,
            //       'point': LatLng(lat, lng),
            //     });
            //   },
            //   child:
            //       const Icon(Icons.location_pin, size: 60, color: Colors.black),
            // ),
            );
        mapNotifier.addMarker(m);
        markers.add(m);
      }

      if ((i + 1) % 100 == 0) {
        generatedMarkers = i + 1;
        // append raw batch for canvas markers
        if (rawBatch.isNotEmpty) {
          mapNotifier.appendRawMarkers(List<dynamic>.from(rawBatch));
          rawBatch.clear();
        }
        notifyListeners();
        // yield to event loop
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // append any remaining raw markers
    if (rawBatch.isNotEmpty) {
      mapNotifier.appendRawMarkers(List<dynamic>.from(rawBatch));
    }
    generatedMarkers = count;
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
