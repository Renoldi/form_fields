import 'dart:math';
import 'dart:isolate';

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
        width: 48,
        height: 48,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 48,
        ),
      ),
    ];
  }

  // Helpers: recentre raw shape data so generated shapes are near `center`.
  List _recenterPolygonsRaw(dynamic polygonsRaw) {
    try {
      if (polygonsRaw is! List || polygonsRaw.isEmpty) {
        return polygonsRaw as List;
      }
      final cLat = center.latitude;
      final cLng = center.longitude;
      double sumLat = 0.0, sumLng = 0.0;
      int count = 0;
      for (final p in polygonsRaw) {
        for (final e in (p as List)) {
          sumLat += (e[0] as num).toDouble();
          sumLng += (e[1] as num).toDouble();
          count++;
        }
      }
      if (count == 0) return polygonsRaw;
      final avgLat = sumLat / count;
      final avgLng = sumLng / count;
      final dLat = cLat - avgLat;
      final dLng = cLng - avgLng;
      final out = <List>[];
      for (final p in polygonsRaw) {
        final newPts = (p as List)
            .map((e) => [
                  (e[0] as num).toDouble() + dLat,
                  (e[1] as num).toDouble() + dLng
                ])
            .toList();
        out.add(newPts);
      }
      return out;
    } catch (_) {
      return polygonsRaw as List;
    }
  }

  List _recenterPolylinesRaw(dynamic polylinesRaw) {
    // same logic as polygons
    try {
      if (polylinesRaw is! List || polylinesRaw.isEmpty) {
        return polylinesRaw as List;
      }
      final cLat = center.latitude;
      final cLng = center.longitude;
      double sumLat = 0.0, sumLng = 0.0;
      int count = 0;
      for (final l in polylinesRaw) {
        for (final e in (l as List)) {
          sumLat += (e[0] as num).toDouble();
          sumLng += (e[1] as num).toDouble();
          count++;
        }
      }
      if (count == 0) return polylinesRaw;
      final avgLat = sumLat / count;
      final avgLng = sumLng / count;
      final dLat = cLat - avgLat;
      final dLng = cLng - avgLng;
      final out = <List>[];
      for (final l in polylinesRaw) {
        final newPts = (l as List)
            .map((e) => [
                  (e[0] as num).toDouble() + dLat,
                  (e[1] as num).toDouble() + dLng
                ])
            .toList();
        out.add(newPts);
      }
      return out;
    } catch (_) {
      return polylinesRaw as List;
    }
  }

  List _recenterCirclesRaw(dynamic circlesRaw) {
    try {
      if (circlesRaw is! List || circlesRaw.isEmpty) return circlesRaw as List;
      final cLat = center.latitude;
      final cLng = center.longitude;
      double sumLat = 0.0, sumLng = 0.0;
      int count = 0;
      for (final c in circlesRaw) {
        final r = c as List;
        sumLat += ((r[0]) as num).toDouble();
        sumLng += double.parse(r[1].toString());
        count++;
      }
      if (count == 0) return circlesRaw;
      final avgLat = sumLat / count;
      final avgLng = sumLng / count;
      final dLat = cLat - avgLat;
      final dLng = cLng - avgLng;
      final out = <List>[];
      for (final c in circlesRaw) {
        final r = c as List;
        final lat = (r[0] as num).toDouble() + dLat;
        final lng = (r[1] as num).toDouble() + dLng;
        final radius = r.length >= 3 ? (r[2] as num).toDouble() : 0.0;
        out.add([lat, lng, radius]);
      }
      return out;
    } catch (_) {
      return circlesRaw as List;
    }
  }

  List _recenterMarkersRaw(dynamic markersRaw) {
    try {
      if (markersRaw is! List || markersRaw.isEmpty) return markersRaw as List;
      final cLat = center.latitude;
      final cLng = center.longitude;
      double sumLat = 0.0, sumLng = 0.0;
      int count = 0;
      for (final m in markersRaw) {
        final row = m as List;
        sumLat += ((row[0]) as num).toDouble();
        sumLng += double.parse(row[1].toString());
        count++;
      }
      if (count == 0) return markersRaw;
      final avgLat = sumLat / count;
      final avgLng = sumLng / count;
      final dLat = cLat - avgLat;
      final dLng = cLng - avgLng;
      final out = <List>[];
      for (final m in markersRaw) {
        final row = m as List;
        final lat = (row[0] as num).toDouble() + dLat;
        final lng = (row[1] as num).toDouble() + dLng;
        final newRow = <dynamic>[lat, lng];
        if (row.length >= 3) newRow.add(row[2]);
        if (row.length >= 4) newRow.add(row[3]);
        out.add(newRow);
      }
      return out;
    } catch (_) {
      return markersRaw as List;
    }
  }

  /// Zoom/pan the map to include all generated shapes (polygons, polylines, circles, markers).
  void zoomToGeneratedBounds() {
    try {
      final controller = FormFieldsMapController.getOrCreate('default');

      final pts = <LatLng>[];
      pts.addAll(mapNotifier.markers.map((m) => m.point));
      for (final p in mapNotifier.polygons) {
        pts.addAll(p.points);
      }
      for (final l in mapNotifier.polylines) {
        pts.addAll(l.points);
      }
      for (final c in mapNotifier.circles) {
        pts.add(c.point);
      }
      // include rawMarkers (canvas-mode) too
      for (final r in mapNotifier.rawMarkers) {
        if (r is List && r.length >= 2) {
          final lat = (r[0] as num).toDouble();
          final lng = (r[1] as num).toDouble();
          pts.add(LatLng(lat, lng));
        } else if (r is LatLng) {
          pts.add(r);
        } else if (r is Marker) {
          pts.add(r.point);
        } else if (r is Map) {
          final lat = (r['lat'] as num?)?.toDouble() ??
              (r['latitude'] as num?)?.toDouble();
          final lng = (r['lon'] as num?)?.toDouble() ??
              (r['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) pts.add(LatLng(lat, lng));
        }
      }

      if (pts.isEmpty) {
        debugPrint('zoomToGeneratedBounds: no generated shapes to zoom to');
        return;
      }

      final bounds = LatLngBounds.fromPoints(pts);
      // Move to center (fitBounds may not be available for this flutter_map version).
      controller.move(bounds.center, 12.0);
      debugPrint('zoomToGeneratedBounds: moved to ${bounds.center}');
    } catch (e, st) {
      debugPrint('zoomToGeneratedBounds failed: $e\n$st');
    }
  }

  // Progress tracking for generation
  int generatedMarkers = 0;
  int totalMarkers = 0;
  int generatedPolygons = 0;
  int totalPolygons = 0;
  int generatedPolylines = 0;
  int totalPolylines = 0;
  int generatedCircles = 0;
  int totalCircles = 0;
  List<String> generationLog = [];
  final List<Isolate> _workerIsolates = [];

  /// Loading indicator for long-running generation.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// When true, use canvas-based fast marker rendering in the example map.
  bool _useCanvasMarkers = true;
  bool get useCanvasMarkers => _useCanvasMarkers;
  set useCanvasMarkers(bool v) {
    if (_useCanvasMarkers == v) return;
    _useCanvasMarkers = v;
    notifyListeners();
  }

  /// Generate demo dataset. Defaults to 1000 markers and 20 shapes.
  Future<void> generateDemoData(
      {int markerCount = 10000, int shapeCount = 20}) async {
    _isLoading = true;
    // Signal the map widget to show its loading overlay via the controller
    FormFieldsMapController.setLoading('default', true);
    notifyListeners();

    try {
      // Run generation in parallel across isolates and stream progress.
      final params = {
        'centerLat': center.latitude,
        'centerLng': center.longitude,
        'seed': 12345,
        'markerCount': markerCount,
        'shapeCount': shapeCount,
      };

      totalMarkers = markerCount;
      totalPolygons = shapeCount;
      totalPolylines = shapeCount;
      totalCircles = shapeCount;
      generatedMarkers = 0;
      generatedPolygons = 0;
      generatedPolylines = 0;
      generatedCircles = 0;
      generationLog.clear();
      notifyListeners();

      // Clear previous raw markers when using canvas mode to avoid mixing datasets.
      if (useCanvasMarkers) {
        mapNotifier.clearRawMarkers();
      } else {
        mapNotifier.clearMarkers();
      }

      // Add a single marker at the center so we can verify generation worked
      if (useCanvasMarkers) {
        mapNotifier.appendRawMarkers([
          [center.latitude, center.longitude, 'Center', 'Start']
        ]);
      } else {
        mapNotifier.addMarker(Marker(
          point: center,
          width: 48,
          height: 48,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 48,
          ),
        ));
      }

      final rp = ReceivePort();
      rp.listen((dynamic message) async {
        try {
          if (message is Map) {
            final type = message['type'] as String?;
            if (message.containsKey('batch')) {
              // Handle streamed batches (from isolates)
              final batch = message['batch'] as List;
              if (type == 'markers') {
                if (useCanvasMarkers) {
                  // batches now contain optional title/subtitle: forward as-is
                  mapNotifier.appendRawMarkers(batch.cast<dynamic>());
                  debugPrint(
                      'generateDemoData: raw markers appended -> ${mapNotifier.rawMarkers.length}');
                } else {
                  final newMarkers = <Marker>[];
                  for (final m in batch) {
                    final row = m as List;
                    final lat = (row[0] as num).toDouble();
                    final lng = (row[1] as num).toDouble();
                    final title = row.length >= 3 ? row[2]?.toString() : null;
                    final subtitle =
                        row.length >= 4 ? row[3]?.toString() : null;
                    newMarkers.add(Marker(
                      point: LatLng(lat, lng),
                      width: 120,
                      height: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.blue.withValues(alpha: 0.95),
                            size: 32,
                          ),
                          if (title != null)
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          if (subtitle != null)
                            Text(subtitle,
                                style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ));
                  }
                  final existing = mapNotifier.markers;
                  final combined = List<Marker>.from(existing)
                    ..addAll(newMarkers);
                  mapNotifier.markers = combined;
                  debugPrint(
                      'generateDemoData: markers appended -> ${combined.length}');
                }
              }
              // fall through to also handle progress if present
            }

            if (message.containsKey('progress')) {
              final p = message['progress'] as int;
              if (type == 'markers') {
                generatedMarkers = p;
                debugPrint(
                    'generateDemoData: markers progress -> $generatedMarkers/$totalMarkers');
              } else if (type == 'polygons') {
                generatedPolygons = p;
                debugPrint(
                    'generateDemoData: polygons progress -> $generatedPolygons/$totalPolygons');
              } else if (type == 'polylines') {
                generatedPolylines = p;
                debugPrint(
                    'generateDemoData: polylines progress -> $generatedPolylines/$totalPolylines');
              } else if (type == 'circles') {
                generatedCircles = p;
                debugPrint(
                    'generateDemoData: circles progress -> $generatedCircles/$totalCircles');
              }
              notifyListeners();
            } else if (message.containsKey('log')) {
              generationLog.add(message['log'] as String);
              notifyListeners();
            } else if (message.containsKey('done')) {
              final typeDone = message['type'] as String?;
              final data = message['done'];
              // 'done' may be a boolean when streaming batches; only handle
              // payload-based done messages for non-streaming paths.
              if (typeDone == 'markers') {
                if (data is List) {
                  final markersRaw = _recenterMarkersRaw(data);
                  final markers = <Marker>[];
                  for (final m in markersRaw) {
                    final row = m as List;
                    final lat = (row[0] as num).toDouble();
                    final lng = (row[1] as num).toDouble();
                    final title = row.length >= 3 ? row[2]?.toString() : null;
                    final subtitle =
                        row.length >= 4 ? row[3]?.toString() : null;
                    markers.add(Marker(
                      point: LatLng(lat, lng),
                      width: 120,
                      height: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.blue.withValues(alpha: 0.95),
                            size: 32,
                          ),
                          if (title != null)
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          if (subtitle != null)
                            Text(subtitle,
                                style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ));
                  }
                  mapNotifier.markers = markers;
                  debugPrint(
                      'generateDemoData: markers set -> ${markers.length}');
                } else {
                  debugPrint('generateDemoData: markers done (streamed)');
                }
              } else if (typeDone == 'polygons') {
                final polygonsRaw = _recenterPolygonsRaw(data);
                final polygons = <Polygon>[];
                for (final p in polygonsRaw) {
                  final pts = (p as List)
                      .map<LatLng>(
                          (e) => LatLng(e[0] as double, e[1] as double))
                      .toList();
                  polygons.add(Polygon(
                    points: pts,
                    color: Colors.green.withValues(alpha: 0.25),
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.green,
                  ));
                }
                mapNotifier.polygons = polygons;
                debugPrint(
                    'generateDemoData: polygons set -> ${polygons.length}');
              } else if (typeDone == 'polylines') {
                final polylinesRaw = _recenterPolylinesRaw(data);
                final polylines = <Polyline>[];
                for (final l in polylinesRaw) {
                  final pts = (l as List)
                      .map<LatLng>(
                          (e) => LatLng(e[0] as double, e[1] as double))
                      .toList();
                  polylines.add(Polyline(
                      points: pts, strokeWidth: 2.0, color: Colors.orange));
                }
                mapNotifier.polylines = polylines;
                debugPrint(
                    'generateDemoData: polylines set -> ${polylines.length}');
              } else if (typeDone == 'circles') {
                final circlesRaw = _recenterCirclesRaw(data);
                final circles = <CircleMarker>[];
                for (final c in circlesRaw) {
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
                mapNotifier.circles = circles;
                debugPrint(
                    'generateDemoData: circles set -> ${circles.length}');
              }
            }
          }
        } catch (e, st) {
          debugPrint('Generation message handling error: $e\n$st');
        }
      });

      // spawn isolates
      _workerIsolates.clear();
      _workerIsolates.add(await Isolate.spawn(
          _markersIsolateEntry, {'send': rp.sendPort, 'params': params}));
      _workerIsolates.add(await Isolate.spawn(
          _polygonsIsolateEntry, {'send': rp.sendPort, 'params': params}));
      _workerIsolates.add(await Isolate.spawn(
          _polylinesIsolateEntry, {'send': rp.sendPort, 'params': params}));
      _workerIsolates.add(await Isolate.spawn(
          _circlesIsolateEntry, {'send': rp.sendPort, 'params': params}));

      // Wait for all isolates to finish by polling mapNotifier caches being set
      // (simple approach). We wait until generated counts equal totals.
      while ((generatedMarkers < totalMarkers) ||
          (generatedPolygons < totalPolygons) ||
          (generatedPolylines < totalPolylines) ||
          (generatedCircles < totalCircles)) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Give a moment for final messages to settle, then kill isolates and close port.
      await Future.delayed(const Duration(milliseconds: 200));
      for (final iso in _workerIsolates) {
        iso.kill(priority: Isolate.immediate);
      }
      _workerIsolates.clear();
      rp.close();
    } catch (e, st) {
      debugPrint('generateDemoData failed: $e\n$st');
    } finally {
      // After generation finishes, ensure map recenters to include generated shapes.
      try {
        zoomToGeneratedBounds();
      } catch (_) {}

      _isLoading = false;
      FormFieldsMapController.setLoading('default', false);
      notifyListeners();
    }
  }

  /// Generate polygons only.
  Future<void> generatePolygons({int shapeCount = 20}) async {
    _isLoading = true;
    FormFieldsMapController.setLoading('default', true);
    notifyListeners();

    try {
      final params = {
        'centerLat': center.latitude,
        'centerLng': center.longitude,
        'seed': 12345,
        'shapeCount': shapeCount,
      };

      totalPolygons = shapeCount;
      generatedPolygons = 0;
      generationLog.clear();
      notifyListeners();

      mapNotifier.clearPolygons();

      // Add a center marker so generated polygons are easy to spot
      // if (useCanvasMarkers) {
      //   mapNotifier.appendRawMarkers([
      //     [center.latitude, center.longitude, 'Center', 'Polygons']
      //   ]);
      // } else {
      //   mapNotifier.addMarker(Marker(
      //     point: center,
      //     width: 36,
      //     height: 36,
      //     child: const Icon(
      //       Icons.location_pin,
      //       color: Colors.green,
      //       size: 36,
      //     ),
      //   ));
      // }

      final rp = ReceivePort();
      rp.listen((dynamic message) {
        try {
          if (message is Map && message['type'] == 'polygons') {
            if (message.containsKey('progress')) {
              generatedPolygons = message['progress'] as int;
              notifyListeners();
            } else if (message.containsKey('done')) {
              final polygonsRaw = _recenterPolygonsRaw(message['done']);
              final polygons = <Polygon>[];
              for (final p in polygonsRaw) {
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
              mapNotifier.polygons = polygons;
              debugPrint(
                  'generatePolygons: polygons set -> ${polygons.length}');
            }
          }
        } catch (e, st) {
          debugPrint('generatePolygons message handling error: $e\n$st');
        }
      });

      final iso = await Isolate.spawn(
          _polygonsIsolateEntry, {'send': rp.sendPort, 'params': params});

      while (generatedPolygons < totalPolygons) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      iso.kill(priority: Isolate.immediate);
      rp.close();
    } catch (e, st) {
      debugPrint('generatePolygons failed: $e\n$st');
    } finally {
      _isLoading = false;
      FormFieldsMapController.setLoading('default', false);
      notifyListeners();
    }
  }

  /// Generate polylines only.
  Future<void> generatePolylines({int shapeCount = 20}) async {
    _isLoading = true;
    FormFieldsMapController.setLoading('default', true);
    notifyListeners();

    try {
      final params = {
        'centerLat': center.latitude,
        'centerLng': center.longitude,
        'seed': 12345,
        'shapeCount': shapeCount,
      };

      totalPolylines = shapeCount;
      generatedPolylines = 0;
      generationLog.clear();
      notifyListeners();

      mapNotifier.clearPolylines();

      // Add a center marker so generated polylines are easy to spot
      // if (useCanvasMarkers) {
      //   mapNotifier.appendRawMarkers([
      //     [center.latitude, center.longitude, 'Center', 'Polylines']
      //   ]);
      // } else {
      //   mapNotifier.addMarker(Marker(
      //     point: center,
      //     width: 36,
      //     height: 36,
      //     child: const Icon(
      //       Icons.location_pin,
      //       color: Colors.orange,
      //       size: 36,
      //     ),
      //   ));
      // }

      final rp = ReceivePort();
      rp.listen((dynamic message) {
        try {
          if (message is Map && message['type'] == 'polylines') {
            if (message.containsKey('progress')) {
              generatedPolylines = message['progress'] as int;
              notifyListeners();
            } else if (message.containsKey('done')) {
              final polylinesRaw = _recenterPolylinesRaw(message['done']);
              final polylines = <Polyline>[];
              for (final l in polylinesRaw) {
                final pts = (l as List)
                    .map<LatLng>((e) => LatLng(e[0] as double, e[1] as double))
                    .toList();
                polylines.add(Polyline(
                    points: pts, strokeWidth: 2.0, color: Colors.orange));
              }
              mapNotifier.polylines = polylines;
              debugPrint(
                  'generatePolylines: polylines set -> ${polylines.length}');
            }
          }
        } catch (e, st) {
          debugPrint('generatePolylines message handling error: $e\n$st');
        }
      });

      final iso = await Isolate.spawn(
          _polylinesIsolateEntry, {'send': rp.sendPort, 'params': params});

      while (generatedPolylines < totalPolylines) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      iso.kill(priority: Isolate.immediate);
      rp.close();
    } catch (e, st) {
      debugPrint('generatePolylines failed: $e\n$st');
    } finally {
      _isLoading = false;
      FormFieldsMapController.setLoading('default', false);
      notifyListeners();
    }
  }

  /// Generate circles only.
  Future<void> generateCircles({int shapeCount = 20}) async {
    _isLoading = true;
    FormFieldsMapController.setLoading('default', true);
    notifyListeners();

    try {
      final params = {
        'centerLat': center.latitude,
        'centerLng': center.longitude,
        'seed': 12345,
        'shapeCount': shapeCount,
      };

      totalCircles = shapeCount;
      generatedCircles = 0;
      generationLog.clear();
      notifyListeners();

      mapNotifier.clearCircles();

      // Add a center marker so generated circles are easy to spot
      // if (useCanvasMarkers) {
      //   mapNotifier.appendRawMarkers([
      //     [center.latitude, center.longitude, 'Center', 'Circles']
      //   ]);
      // } else {
      //   mapNotifier.addMarker(Marker(
      //     point: center,
      //     width: 36,
      //     height: 36,
      //     child: const Icon(
      //       Icons.location_pin,
      //       color: Colors.purple,
      //       size: 36,
      //     ),
      //   ));
      // }

      final rp = ReceivePort();
      rp.listen((dynamic message) {
        try {
          if (message is Map && message['type'] == 'circles') {
            if (message.containsKey('progress')) {
              generatedCircles = message['progress'] as int;
              notifyListeners();
            } else if (message.containsKey('done')) {
              final circlesRaw = _recenterCirclesRaw(message['done']);
              final circles = <CircleMarker>[];
              for (final c in circlesRaw) {
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
              mapNotifier.circles = circles;
              debugPrint('generateCircles: circles set -> ${circles.length}');
            }
          }
        } catch (e, st) {
          debugPrint('generateCircles message handling error: $e\n$st');
        }
      });

      final iso = await Isolate.spawn(
          _circlesIsolateEntry, {'send': rp.sendPort, 'params': params});

      while (generatedCircles < totalCircles) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      iso.kill(priority: Isolate.immediate);
      rp.close();
    } catch (e, st) {
      debugPrint('generateCircles failed: $e\n$st');
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
    // Also clear raw canvas markers if any were used
    mapNotifier.clearRawMarkers();
    notifyListeners();
  }
}

// Generator helpers removed — generation is performed inline in isolate entrypoints.

// -------------------- Isolate entrypoints with progress --------------------

void _markersIsolateEntry(Map msg) {
  final SendPort send = msg['send'] as SendPort;
  final params = msg['params'] as Map;
  final double centerLat = params['centerLat'] as double;
  final double centerLng = params['centerLng'] as double;
  final int seed = params['seed'] as int;
  final int markerCount = params['markerCount'] as int;

  final rand = Random(seed);
  final seen = <String>{};
  final batchSize = max(1, markerCount ~/ 50);
  var produced = 0;
  final currentBatch = <List<dynamic>>[];
  while (produced < markerCount) {
    final lat = centerLat + (rand.nextDouble() - 0.5) * 0.6;
    final lng = centerLng + (rand.nextDouble() - 0.5) * 0.6;
    final key = '${lat.toStringAsFixed(6)}|${lng.toStringAsFixed(6)}';
    if (seen.contains(key)) continue;
    seen.add(key);
    final index = produced + 1;
    // include title and subtitle in the payload so main isolate can render labels
    currentBatch.add([lat, lng, 'Marker #$index', 'Generated marker #$index']);
    produced++;
    if (currentBatch.length >= batchSize) {
      send.send({
        'type': 'markers',
        'batch': List.of(currentBatch),
        'progress': produced
      });
      currentBatch.clear();
    }
  }
  if (currentBatch.isNotEmpty) {
    send.send({
      'type': 'markers',
      'batch': List.of(currentBatch),
      'progress': produced
    });
  }
  // indicate done (no payload to avoid duplicating data)
  send.send({'type': 'markers', 'done': true});
}

void _polygonsIsolateEntry(Map msg) {
  final SendPort send = msg['send'] as SendPort;
  final params = msg['params'] as Map;
  final double centerLat = params['centerLat'] as double;
  final double centerLng = params['centerLng'] as double;
  final int seed = params['seed'] as int;
  final int shapeCount = params['shapeCount'] as int;

  final rand = Random(seed + 1);
  final polygons = <List<List<double>>>[];
  for (var i = 0; i < shapeCount; i++) {
    // Increase polygon size/extent so generated shapes are easier to see
    final baseLat = centerLat + (rand.nextDouble() - 0.5) * 1.5;
    final baseLng = centerLng + (rand.nextDouble() - 0.5) * 1.5;
    polygons.add([
      [baseLat, baseLng],
      [baseLat + 0.05, baseLng + 0.08],
      [baseLat - 0.05, baseLng + 0.08],
    ]);
    send.send({'type': 'polygons', 'progress': i + 1});
  }
  send.send({'type': 'polygons', 'done': polygons});
}

void _polylinesIsolateEntry(Map msg) {
  final SendPort send = msg['send'] as SendPort;
  final params = msg['params'] as Map;
  final double centerLat = params['centerLat'] as double;
  final double centerLng = params['centerLng'] as double;
  final int seed = params['seed'] as int;
  final int shapeCount = params['shapeCount'] as int;

  final rand = Random(seed + 2);
  final polylines = <List<List<double>>>[];
  for (var i = 0; i < shapeCount; i++) {
    // Create longer polylines so they're visible at typical zoom
    final baseLat = centerLat + (rand.nextDouble() - 0.5) * 1.5;
    final baseLng = centerLng + (rand.nextDouble() - 0.5) * 1.5;
    final linePoints = List<List<double>>.generate(6, (j) {
      return [baseLat + (j - 3) * 0.01, baseLng + (j % 2 == 0 ? 0.0 : 0.05)];
    });
    polylines.add(linePoints);
    send.send({'type': 'polylines', 'progress': i + 1});
  }
  send.send({'type': 'polylines', 'done': polylines});
}

void _circlesIsolateEntry(Map msg) {
  final SendPort send = msg['send'] as SendPort;
  final params = msg['params'] as Map;
  final double centerLat = params['centerLat'] as double;
  final double centerLng = params['centerLng'] as double;
  final int seed = params['seed'] as int;
  final int shapeCount = params['shapeCount'] as int;

  final rand = Random(seed + 3);
  final circles = <List<double>>[];
  for (var i = 0; i < shapeCount; i++) {
    // Make circles larger and offset so they are clearly visible
    final baseLat = centerLat + (rand.nextDouble() - 0.5) * 1.5;
    final baseLng = centerLng + (rand.nextDouble() - 0.5) * 1.5;
    circles.add([baseLat + 0.05, baseLng + 0.05, 2000.0]);
    send.send({'type': 'circles', 'progress': i + 1});
  }
  send.send({'type': 'circles', 'done': circles});
}
