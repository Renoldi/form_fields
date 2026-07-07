import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
// Use the package's Dio utility for HTTP requests instead of HttpClient.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/data/models/usgs_feed.dart';

class MapExamplesViewModel extends ChangeNotifier {
  final MapController mapController = MapController();
  MapExamplesViewModel() {
    try {
      // Ensure the controller and a notifier are registered early so
      // calls like `setBlockingLoading` from this view model target
      // the same notifier instance the `FormFieldsMap` widget listens
      // to. This prevents timing issues when the VM toggles loading
      // before the widget has registered its fallback notifier.
      mapController.registerWithNotifier();
    } catch (_) {}
  }
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

  /// Whether the example UI (and the FormFieldsMap) should enable
  /// built-in polyline playback features. Consumers can toggle this to
  /// hide playback controls and related actions in the example.
  bool enablePolylinePlayback = false;

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

  /// Enable or disable built-in polyline playback for the example.
  /// When disabling playback we also stop periodic marker updates.
  void setEnablePolylinePlayback(bool v) {
    enablePolylinePlayback = v;
    // When polyline playback is enabled, stop the periodic marker updates
    // to avoid conflicting movement simulations. When disabled, resume
    // periodic updates so markers continue to move.
    if (v) {
      try {
        stopPeriodicMarkerUpdates();
      } catch (_) {}
    } else {
      try {
        startPeriodicMarkerUpdates();
      } catch (_) {}
    }
    notifyListeners();
  }

  int generatedCircles = 0;
  int totalCircles = 0;

  int createMarkers = 1000000;
  int createPolygons = 5;
  int createPolylines = 5;
  int createCircles = 5;

  // Periodic update interval and countdown state
  Duration markerUpdateInterval = Duration.zero;
  int markerUpdateRemainingSeconds = 0;

  /// If true, periodic updates will assign fully random coordinates
  /// (within `markerUpdateRandomRangeDegrees` around `center`) instead of
  /// small nudges.
  bool markerUpdateRandomizeCoordinates = true;

  /// Range in degrees used when `markerUpdateRandomizeCoordinates` is true.
  /// Default ~3 degrees box (same scale as initial generation).
  double markerUpdateRandomRangeDegrees = 3.0;

  /// When true, `_updateMarkersOnce` will request creation of marker
  /// widgets during batch updates/append so the visible map reflects
  /// coordinate changes. Disabled by default for maximum throughput.
  bool showVisualMarkerUpdates = false;

  void setShowVisualMarkerUpdates(bool v) {
    showVisualMarkerUpdates = v;
    notifyListeners();
  }

  void commit() {
    notifyListeners();
  }

  void setShowTitle(bool v) {
    showTitle = v;
    notifyListeners();
  }

  // Try to find latitude/longitude inside a possibly nested map/list structure.
  // Returns a map with keys 'lat' and 'lon' if found, otherwise null.

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
    try {
      mapController.setBlockingLoading(true);
    } catch (_) {}
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
        final id = 'p\$${DateTime.now().microsecondsSinceEpoch}';
        // Build ShapeMeta containing the full polygon vertex list so the
        // widget can render polygons from ShapeMeta directly.
        final pmList =
            pts.map((p) => PointMeta.fromMap(p)).toList(growable: false);
        await mapController.appendRawMarkers([
          ShapeMeta(
            pointMetas: pmList,
            hit: (title: 'Polygon #${i + 1}', subtitle: null),
            id: id,
            shapeType: ShapeTypes.polygon,
          )
        ]);
        generatedPolygons = i + 1;
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

  Future<void> generateMarkers({int markerCount = 1000, String? apiUrl}) async {
    if (FormFieldsMapController.enableBatchLogging) {
      debugPrint(
          'generateMarkers called with count=$markerCount apiUrl=$apiUrl');
    }
    generatedMarkers = 0;
    totalMarkers = markerCount;
    isLoading = true;
    notifyListeners();

    // Give the UI one frame to render the blocking overlay.
    await Future.delayed(Duration.zero);

    // Prepare raw data either from an external API or by generating locally
    List<dynamic> raw;
    if (apiUrl != null) {
      // Attempt to fetch JSON from provided API. Expecting a list of
      // objects containing at least `lat` and `lon` (or common variants).
      raw = <dynamic>[];
      try {
        raw = await EarthquakeFeed.fetchRawMarkers(apiUrl);
      } catch (e) {
        debugPrint(
            'generateMarkers: failed to fetch/parse apiUrl=$apiUrl — $e');
        raw = <dynamic>[];
      }
      // If an API was used, update the total to the actual number of
      // items returned so the progress display shows a correct denominator
      // (previously `totalMarkers` remained set to the requested
      // `markerCount`, which could be different from the API response).
      totalMarkers = raw.length;
      notifyListeners();
    } else {
      // Use compute to generate marker data off the main thread.
      raw = await compute(_generateMarkersIsolate, {
        'count': markerCount,
        'seed': 424242,
        'centerLat': center.latitude,
        'centerLng': center.longitude,
      });
    }

    // Convert and append in batches on the main isolate.
    // Larger batch size reduces number of notifier append calls.
    const batchSize = 4096;
    var idx = 0;
    while (idx < raw.length) {
      final end = (idx + batchSize).clamp(0, raw.length);
      final slice = raw.sublist(idx, end);
      final batch = <dynamic>[];
      for (var m in slice) {
        final lat = (m['lat'] as num).toDouble();
        final lon = (m['lon'] as num).toDouble();
        batch.add(ShapeMeta(
          pointMetas: [
            PointMeta.fromMap(LatLng(lat, lon))
              ..hit = (
                title: m['title'] as String?,
                subtitle: m['subtitle'] as String?
              )
              ..id = m['id'] as String?
          ],
          id: m['id'] as String?,
          shapeType: m['shapeType'] as String?,
        ));
      }
      await FormFieldsMapController.appendRawMarkers(
          controllerId, List<dynamic>.from(batch),
          createMarkerWidgets: false);
      generatedMarkers = end;
      if (FormFieldsMapController.enableBatchLogging) {
        debugPrint(
            'generateMarkers appended a batch, generated=$generatedMarkers');
      }
      try {
        if (FormFieldsMapController.enableBatchLogging) {
          final cur = mapController.getRawMarkers();
          debugPrint(
              'generateMarkers after append, registry rawMarkers=${cur.length}');
        }
      } catch (_) {}
      notifyListeners();
      // Yield to the event loop so timers and UI (countdown) can run
      // while large batches are being appended. Without this, the main
      // isolate can be busy and the countdown won't update until done.
      await Future.delayed(Duration.zero);
      idx = end;
    }
    // Start periodic updates after markers are generated.
    // Start periodic updates after markers are generated.
    if (!enablePolylinePlayback) {
      startPeriodicMarkerUpdates();
    }

    isLoading = false;
    notifyListeners();
    try {
      if (FormFieldsMapController.enableBatchLogging) {
        final cur = mapController.getRawMarkers();
        debugPrint(
            'generateMarkers complete, registry rawMarkers=${cur.length}');
      }
    } catch (_) {}
    if (FormFieldsMapController.enableBatchLogging) {
      debugPrint('generateMarkers finished, total generated=$generatedMarkers');
    }
    // try {
    //   mapController.setBlockingLoading(false);
    // } catch (_) {}
  }

  Future<void> generatePolylines(
      {int shapeCount = 5, bool useRoads = true}) async {
    isLoading = true;
    notifyListeners();
    try {
      generatedPolylines = 0;
      totalPolylines = shapeCount;
      final rnd = math.Random(98765);
      try {
        mapController.setBlockingLoading(true);
      } catch (_) {}

      for (var i = 0; i < shapeCount; i++) {
        List<LatLng>? routePoints;
        if (useRoads) {
          try {
            final offsetMultiplier = 0.25;
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

        if (routePoints == null || routePoints.isEmpty) {
          // Fallback: random polyline near center
          final baseLat = center.latitude + (rnd.nextDouble() - 0.5) * 0.8;
          final baseLng = center.longitude + (rnd.nextDouble() - 0.5) * 0.8;
          final pts = <LatLng>[];
          final segs = 3 + rnd.nextInt(5);
          final step = 0.02 + rnd.nextDouble() * 0.04;
          for (var s = 0; s < segs; s++) {
            pts.add(LatLng(baseLat + (s - segs / 2) * step,
                baseLng + (rnd.nextDouble() - 0.5) * step));
          }
          final pmList = pts
              .map((p) => PointMeta(lat: p.latitude, lon: p.longitude))
              .toList(growable: false);
          final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
          await mapController.appendRawMarkers([
            ShapeMeta(
              pointMetas: pmList,
              hit: (title: 'Polyline #${i + 1}', subtitle: null),
              id: id,
              shapeType: ShapeTypes.polyline,
              properties: {
                // Make playback polyline thicker and more visible. Use pixel-based
                // stroke width so it appears consistently regardless of zoom.
                'strokeWidth': 8.0,
                'useStrokeWidthInMeter': false,
                'color': Colors.red,
              },
            )
          ]);
        } else {
          // Use routePoints as the polyline
          // If route is short, enrich by interpolating points
          if (routePoints.length < 8) {
            final enriched = <LatLng>[];
            const int interpPerSegment = 3;
            for (var j = 0; j < routePoints.length - 1; j++) {
              final a = routePoints[j];
              final b = routePoints[j + 1];
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
          final pmList = routePoints
              .map((p) => PointMeta.fromMap(p))
              .toList(growable: false);
          final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
          await mapController.appendRawMarkers([
            ShapeMeta(
              pointMetas: pmList,
              hit: (title: 'Polyline #${i + 1}', subtitle: null),
              id: id,
              shapeType: ShapeTypes.polyline,
              properties: {
                // Make playback polyline thicker and more visible. Use pixel-based
                // stroke width so it appears consistently regardless of zoom.
                'strokeWidth': 8.0,
                'useStrokeWidthInMeter': false,
                'color': Colors.red,
              },
            )
          ]);
        }

        generatedPolylines = i + 1;
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

  /// Start periodic updates of existing raw markers. Each tick will slightly
  /// perturb marker coordinates to simulate movement. Default interval is
  /// 1 minute.
  void startPeriodicMarkerUpdates(
      {Duration interval = const Duration(seconds: 30),
      bool randomize = true}) {
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
  Future<void> _updateMarkersOnce() async {
    try {
      // --- SERIALIZATION: build `serializable`, `baseHitById`, `basePropsById`
      // This snapshot is used by the compute isolate and also to
      // preserve metadata if we need to regenerate markers (clear+append).
      try {
        mapController.setBlockingLoading(true);
      } catch (_) {}

      final current = mapController.getRawMarkers();
      if (FormFieldsMapController.enableBatchLogging) {
        debugPrint('_updateMarkersOnce called, current=${current.length}');
      }
      if (current.isEmpty) return;

      // Preserve hit/title and properties for regeneration, then
      // serialize current entries to a plain-map form suitable for isolates.
      final baseHitById = <String, dynamic>{};
      final basePropsById = <String, Map<String, dynamic>>{};
      final serializable = <Map<String, dynamic>>[];
      for (final m in current) {
        if (m is ShapeMeta) {
          if (m.id != null) {
            if (m.hit != null) {
              baseHitById[m.id!] = m.hit;
            }
            // Some markers store hit (title/subtitle) on the first PointMeta
            // instead of ShapeMeta.hit. Capture that so titles aren't lost
            // when we clear and regenerate markers.
            if ((m.pointMetas ?? []).isNotEmpty) {
              final p0 = m.pointMetas!.first;
              try {
                if (p0.hit != null) baseHitById[m.id!] = p0.hit;
              } catch (_) {}
            }
          }
        } else if (m is Map) {
          serializable.add(Map<String, dynamic>.from(m));
        } else {
          serializable.add({'_raw': '$m'});
        }
      }
      // --- SERIALIZATION END

      // Build a quick lookup of the original serializable entries by id.
      // This is used by the update-in-place path to convert returned
      // deltas (`deltaLat`/`deltaLon`) into absolute `pointMetas` or
      // `lat`/`lon` payloads that the notifier understands.
      final baseSnapshotById = <String, Map<String, dynamic>>{};
      for (final b in serializable) {
        final bid = (b['id'] as String?) ?? '';
        if (bid.isNotEmpty) baseSnapshotById[bid] = b;
      }

      // --- OFFLOAD: perform heavy coordinate math in an isolate.
      // The isolate returns deltas or full pointMetas used by both
      // regenerate and update-in-place paths.
      final seed = _updateRnd.nextInt(1 << 32);
      final computed = await compute(_computeUpdatedMarkersIsolate, {
        'items': serializable,
        'seed': seed,
        'centerLat': center.latitude,
        'centerLng': center.longitude,
        'randomize': markerUpdateRandomizeCoordinates,
        'range': markerUpdateRandomRangeDegrees,
      });
      // --- OFFLOAD END

      // Apply updates in batches using notifier/controller batch API.
      // If there are very many markers then it's often faster to
      // regenerate in large append batches instead of doing per-item
      // coordinate patches. Decide automatically based on total.
      final cid = controllerId;
      final total = computed.length;

      // --- REGENERATE PATH (create new markers):
      // If there are a lot of markers, perform a fast regenerate: clear
      // the registry and append new ShapeMeta in large batches. This avoids
      // expensive per-item updates and fallback paths.
      const int regenerateThreshold = 5000;
      if (total >= regenerateThreshold) {
        try {
          debugPrint(
              '_updateMarkersOnce: large update, regenerating markers (total=$total)');
          // Build a map of base entries keyed by id so we can reconstruct
          // absolute coordinates using returned deltas.
          final baseById = <String, Map<String, dynamic>>{};
          for (final b in serializable) {
            final bid = (b['id'] as String?) ?? '';
            if (bid.isNotEmpty) baseById[bid] = b;
          }

          // Clear existing markers quickly.
          try {
            mapController.clearRawMarkers();
          } catch (_) {}

          // Append regenerated markers in batches to avoid UI stalls.
          // (This is the "buat baru" path: calls `mapController.clearRawMarkers()`
          //  then `FormFieldsMapController.appendRawMarkers(...)` to recreate.)
          const regenBatchSize = 4096;
          var ridx = 0;
          while (ridx < computed.length) {
            final rend = (ridx + regenBatchSize).clamp(0, computed.length);
            final rslice = computed.sublist(ridx, rend);
            final batch = <dynamic>[];
            for (final u in rslice) {
              try {
                // If compute returned full pointMetas, use them directly.
                if (u['pointMetas'] is List &&
                    (u['pointMetas'] as List).isNotEmpty) {
                  final pms =
                      (u['pointMetas'] as List).cast<Map<String, dynamic>>();
                  final pmList = pms
                      .map((pm) => PointMeta.fromMap(pm))
                      .toList(growable: false);
                  final sid = u['id'] as String?;
                  batch.add(ShapeMeta(
                      pointMetas: pmList,
                      id: sid,
                      shapeType: u['shapeType'] as String?,
                      hit: sid != null && baseHitById.containsKey(sid)
                          ? baseHitById[sid]
                          : null,
                      properties: sid != null && basePropsById.containsKey(sid)
                          ? basePropsById[sid]
                          : null));
                  continue;
                }

                // If only deltas were returned, reconstruct absolute coords
                // from the original serializable snapshot.
                final idv = (u['id'] as String?) ?? '';
                double? baseLat;
                double? baseLon;
                if (baseById.containsKey(idv)) {
                  final b = baseById[idv]!;
                  if (b.containsKey('lat') && b.containsKey('lon')) {
                    baseLat = (b['lat'] as num).toDouble();
                    baseLon = (b['lon'] as num).toDouble();
                  } else if (b['pointMetas'] is List &&
                      (b['pointMetas'] as List).isNotEmpty) {
                    final bp0 =
                        (b['pointMetas'] as List).first as Map<String, dynamic>;
                    baseLat = (bp0['lat'] as num).toDouble();
                    baseLon = (bp0['lon'] as num).toDouble();
                  }
                }

                if (u.containsKey('deltaLat') &&
                    u.containsKey('deltaLon') &&
                    baseLat != null &&
                    baseLon != null) {
                  final newLat = baseLat + (u['deltaLat'] as num).toDouble();
                  final newLon = baseLon + (u['deltaLon'] as num).toDouble();
                  batch.add(ShapeMeta(
                      pointMetas: [
                        PointMeta.fromMap(LatLng(newLat, newLon))..id = idv
                      ],
                      id: idv,
                      shapeType: ShapeTypes.marker,
                      hit: baseHitById.containsKey(idv)
                          ? baseHitById[idv]
                          : null,
                      properties: basePropsById.containsKey(idv)
                          ? basePropsById[idv]
                          : null));
                } else if (u.containsKey('lat') && u.containsKey('lon')) {
                  final newLat = (u['lat'] as num).toDouble();
                  final newLon = (u['lon'] as num).toDouble();
                  final sid2 = u['id'] as String?;
                  batch.add(ShapeMeta(
                      pointMetas: [
                        PointMeta.fromMap(LatLng(newLat, newLon))..id = sid2
                      ],
                      id: sid2,
                      shapeType: ShapeTypes.marker,
                      hit: sid2 != null && baseHitById.containsKey(sid2)
                          ? baseHitById[sid2]
                          : null,
                      properties:
                          sid2 != null && basePropsById.containsKey(sid2)
                              ? basePropsById[sid2]
                              : null));
                } else {
                  // Unknown payload, skip.
                }
              } catch (_) {}
            }

            if (batch.isNotEmpty) {
              try {
                await FormFieldsMapController.appendRawMarkers(
                    cid, List<dynamic>.from(batch),
                    createMarkerWidgets: showVisualMarkerUpdates);
                // Update UI counters so progress overlay reflects regeneration
                for (final b in batch) {
                  try {
                    if (b is ShapeMeta) {
                      final t =
                          (b.shapeType ?? ShapeTypes.marker).toLowerCase();
                      if (t == ShapeTypes.marker) {
                        generatedMarkers =
                            (generatedMarkers + 1).clamp(0, totalMarkers);
                      } else if (t == ShapeTypes.polygon) {
                        generatedPolygons =
                            (generatedPolygons + 1).clamp(0, totalPolygons);
                      } else if (t == ShapeTypes.polyline) {
                        generatedPolylines =
                            (generatedPolylines + 1).clamp(0, totalPolylines);
                      } else if (t == ShapeTypes.circle) {
                        generatedCircles =
                            (generatedCircles + 1).clamp(0, totalCircles);
                      }
                    }
                  } catch (_) {}
                }
              } catch (_) {
                // If append fails, ignore and continue; best-effort regeneration.
              }
            }

            ridx = rend;
            notifyListeners();
            await Future.delayed(Duration.zero);
          }

          // --- REGENERATE END
          debugPrint('_updateMarkersOnce: regeneration complete');
          return;
        } catch (e) {
          // If regeneration failed unexpectedly, fall through to normal path.
          debugPrint(
              '_updateMarkersOnce: regeneration failed, falling back to patching — $e');
        }
      }

      // --- UPDATE-IN-PLACE PATH:
      // Normal update-in-place path when total is small enough. This uses
      // `mapController.batchUpdateCoordinates(...)` to patch coordinates
      // without clearing the registry (keeps existing marker entries).
      int chunkSize;
      if (total >= 20000) {
        chunkSize = 2000;
      } else if (total >= 5000) {
        chunkSize = 1000;
      } else if (total >= 1000) {
        chunkSize = 500;
      } else {
        chunkSize = 200;
      }

      for (var start = 0; start < total; start += chunkSize) {
        final end = (start + chunkSize).clamp(0, total);
        final slice = computed.sublist(start, end);

        // Build ShapeMeta objects and let the controller handle insert vs
        // update. This centralizes logic in FormFieldsMapController so the
        // example can simply supply `List<ShapeMeta>`.
        final shapes = <ShapeMeta>[];
        for (final u in slice) {
          final idv = (u['id'] as String?) ?? '';
          if (idv.isEmpty) continue;

          if (u.containsKey('deltaLat') && u.containsKey('deltaLon')) {
            final base = baseSnapshotById[idv];
            if (base != null) {
              if (base['pointMetas'] is List &&
                  (base['pointMetas'] as List).isNotEmpty) {
                try {
                  final bpms =
                      (base['pointMetas'] as List).cast<Map<String, dynamic>>();
                  final dLat = (u['deltaLat'] as num).toDouble();
                  final dLon = (u['deltaLon'] as num).toDouble();
                  final pms = bpms.map((pm) {
                    final pt = PointMeta.fromMap(pm);
                    pt.lat = pt.lat + dLat;
                    pt.lon = pt.lon + dLon;
                    return pt;
                  }).toList(growable: false);
                  shapes.add(ShapeMeta(
                      pointMetas: pms,
                      id: idv,
                      shapeType: (base['shapeType'] as String?)));
                  continue;
                } catch (_) {}
              }

              try {
                if (base.containsKey('lat') && base.containsKey('lon')) {
                  final baseLat = (base['lat'] as num).toDouble();
                  final baseLon = (base['lon'] as num).toDouble();
                  final newLat = baseLat + (u['deltaLat'] as num).toDouble();
                  final newLon = baseLon + (u['deltaLon'] as num).toDouble();
                  shapes.add(ShapeMeta(pointMetas: [
                    PointMeta(lat: newLat, lon: newLon, id: idv)
                  ], id: idv, shapeType: ShapeTypes.marker));
                  continue;
                }
              } catch (_) {}
            }
            continue;
          } else if (u['pointMetas'] is List) {
            try {
              final pms = (u['pointMetas'] as List)
                  .cast<Map<String, dynamic>>()
                  .map((pm) => PointMeta.fromMap(pm))
                  .toList(growable: false);
              shapes.add(ShapeMeta(
                  pointMetas: pms,
                  id: idv,
                  shapeType: (u['shapeType'] as String?)));
            } catch (_) {}
          } else if (u.containsKey('lat') && u.containsKey('lon')) {
            try {
              final p = PointMeta(
                  lat: (u['lat'] as num).toDouble(),
                  lon: (u['lon'] as num).toDouble(),
                  id: idv);
              shapes.add(ShapeMeta(
                  pointMetas: [p], id: idv, shapeType: ShapeTypes.marker));
            } catch (_) {}
          }
        }

        try {
          if (shapes.isNotEmpty) {
            // Increment UI counters to reflect progress during update-in-place
            for (final s in shapes) {
              try {
                final t = (s.shapeType ?? ShapeTypes.marker).toLowerCase();
                if (t == ShapeTypes.marker) {
                  generatedMarkers =
                      (generatedMarkers + 1).clamp(0, totalMarkers);
                } else if (t == ShapeTypes.polygon) {
                  generatedPolygons =
                      (generatedPolygons + 1).clamp(0, totalPolygons);
                } else if (t == ShapeTypes.polyline) {
                  generatedPolylines =
                      (generatedPolylines + 1).clamp(0, totalPolylines);
                } else if (t == ShapeTypes.circle) {
                  generatedCircles =
                      (generatedCircles + 1).clamp(0, totalCircles);
                }
              } catch (_) {}
            }
            notifyListeners();

            await mapController.processShapeMetaList(shapes,
                createMarkerWidgets: showVisualMarkerUpdates,
                useInPlaceMutation: true);
          }
        } catch (_) {
          // Fallback: per-item update using controller convenience.
          for (final s in shapes) {
            try {
              final sid = s.id;
              if (sid == null) continue;
              if (s.pointMetas != null && s.pointMetas!.isNotEmpty) {
                FormFieldsMapController.updateRawMarkerCoordinates(
                    cid, sid, s.pointMetas!,
                    createMarkerWidgets: showVisualMarkerUpdates);
              }
            } catch (_) {}
          }
        }

        try {
          await Future.delayed(const Duration(milliseconds: 16));
        } catch (_) {}
        notifyListeners();
      }

      // --- UPDATE-IN-PLACE END

      try {
        final candidates = <LatLng>[];
        for (final u in computed) {
          if (u['pointMetas'] is List && (u['pointMetas'] as List).isNotEmpty) {
            final p0 = (u['pointMetas'] as List).first as Map<String, dynamic>;
            final lat = (p0['lat'] as num?)?.toDouble();
            final lon = (p0['lon'] as num?)?.toDouble();
            if (lat != null && lon != null) candidates.add(LatLng(lat, lon));
          } else if (u.containsKey('lat') && u.containsKey('lon')) {
            final lat = (u['lat'] as num?)?.toDouble();
            final lon = (u['lon'] as num?)?.toDouble();
            if (lat != null && lon != null) candidates.add(LatLng(lat, lon));
          }
        }
        if (candidates.isNotEmpty) {
          final chosen = candidates[_updateRnd.nextInt(candidates.length)];
          try {
            await mapController.animateCameraTo(chosen, 10,
                duration: const Duration(milliseconds: 400),
                curve: const FormFieldsMapPlaybackConfig().playbackCurve);
          } catch (_) {}
        }
      } catch (_) {}

      debugPrint('_updateMarkersOnce completed, updated=${computed.length}');
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

      final id = 'l\$${DateTime.now().microsecondsSinceEpoch}';
      // Playback marker midpoint/rotation no longer needed — polyline is
      // appended as full ShapeMeta below.

      // Append the full route as ShapeMeta so rendering and playback UI can
      // derive the polyline from ShapeMeta as the canonical source.
      final pmList =
          routePoints.map((p) => PointMeta.fromMap(p)).toList(growable: false);
      await mapController.appendRawMarkers([
        ShapeMeta(
          pointMetas: pmList,
          hit: (title: 'Playback Polyline', subtitle: id),
          id: id,
          shapeType: ShapeTypes.polyline,
          properties: {
            // Make playback polyline thicker and more visible. Use pixel-based
            // stroke width so it appears consistently regardless of zoom.
            'strokeWidth': 8.0,
            'useStrokeWidthInMeter': false,
            'color': Colors.lightGreen,
          },
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
        final id = 'c\$${DateTime.now().microsecondsSinceEpoch}';
        // Circle ShapeMeta: include center and carry radius in `rotation`.
        final centerPm = PointMeta(
            lat: lat,
            lon: lng,
            rotation: c.radius,
            id: id,
            hit: (title: 'Circle #${i + 1}', subtitle: id));
        await mapController.appendRawMarkers([
          ShapeMeta(
            pointMetas: [centerPm],
            id: id,
            shapeType: ShapeTypes.circle,
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
  final start = DateTime.now().microsecondsSinceEpoch;
  for (var i = 0; i < count; i++) {
    final lat = centerLat + (rnd.nextDouble() - 0.5) * 3;
    final lng = centerLng + (rnd.nextDouble() - 0.5) * 3;
    out.add({
      'lat': lat,
      'lon': lng,
      'title': 'Marker #${i + 1}',
      'subtitle':
          'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
      // Use a single timestamp prefix plus index to avoid repeated
      // DateTime.now() calls which are relatively expensive in large loops.
      'id': 'm${start}_$i',
      'shapeType': ShapeTypes.marker,
    });
  }
  return out;
}

// Compute isolate worker: given serializable raw items, return updated
// serializable items with new coordinates. This avoids doing CPU-bound
// coordinate math on the main isolate.
List<Map<String, dynamic>> _computeUpdatedMarkersIsolate(
    Map<String, dynamic> args) {
  final items = (args['items'] as List).cast<Map<String, dynamic>>();
  final randomSeed = args['seed'] as int? ?? 424242;
  final random = math.Random(randomSeed);
  final centerLat = (args['centerLat'] as num?)?.toDouble() ?? 0.0;
  final centerLng = (args['centerLng'] as num?)?.toDouble() ?? 0.0;
  final randomize = args['randomize'] as bool? ?? true;
  final range = (args['range'] as num?)?.toDouble() ?? 3.0;

  final out = <Map<String, dynamic>>[];
  for (final m in items) {
    try {
      final shapeType = (m['shapeType'] as String?)?.toLowerCase();
      if (shapeType != null && m['pointMetas'] is List) {
        final pms = (m['pointMetas'] as List).cast<Map<String, dynamic>>();
        if (pms.isEmpty) {
          out.add({'id': m['id']});
          continue;
        }
        final base = pms.first;
        double newLat;
        double newLon;
        if (randomize) {
          newLat = centerLat + (random.nextDouble() - 0.5) * range;
          newLon = centerLng + (random.nextDouble() - 0.5) * range;
        } else {
          final dLat = (random.nextDouble() - 0.5) * 0.01;
          final dLon = (random.nextDouble() - 0.5) * 0.01;
          newLat = (base['lat'] as num).toDouble() + dLat;
          newLon = (base['lon'] as num).toDouble() + dLon;
        }
        final deltaLat = newLat - (base['lat'] as num).toDouble();
        final deltaLon = newLon - (base['lon'] as num).toDouble();

        // Return only the id + delta to minimize isolate IPC payload.
        out.add({'id': m['id'], 'deltaLat': deltaLat, 'deltaLon': deltaLon});
      } else if (m.containsKey('lat') && m.containsKey('lon')) {
        double newLat;
        double newLon;
        if (randomize) {
          newLat = centerLat + (random.nextDouble() - 0.5) * range;
          newLon = centerLng + (random.nextDouble() - 0.5) * range;
        } else {
          final dLat = (random.nextDouble() - 0.5) * 0.01;
          final dLon = (random.nextDouble() - 0.5) * 0.01;
          newLat = (m['lat'] as num).toDouble() + dLat;
          newLon = (m['lon'] as num).toDouble() + dLon;
        }
        final deltaLat = newLat - (m['lat'] as num).toDouble();
        final deltaLon = newLon - (m['lon'] as num).toDouble();
        out.add({'id': m['id'], 'deltaLat': deltaLat, 'deltaLon': deltaLon});
      } else {
        out.add(m);
      }
    } catch (_) {
      out.add(m);
    }
  }
  return out;
}
