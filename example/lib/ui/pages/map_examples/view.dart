import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields_example/localization/localizations.dart';

// `flutter_map` is used internally by the package; example doesn't import it directly.

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapExamplesViewModel(),
      child: Consumer<MapExamplesViewModel>(
        builder: (context, vm, _) {
          final content = Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(context.tr('mapExampleDescription')),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => vm.generateDemoData(
                              markerCount: 10000, shapeCount: 20),
                          child: const Text('Generate 10,000 markers + shapes'),
                        ),
                        ElevatedButton(
                          onPressed: () => vm.generatePolygons(shapeCount: 20),
                          child: const Text('Generate Polygons (20)'),
                        ),
                        ElevatedButton(
                          onPressed: () => vm.generatePolylines(shapeCount: 20),
                          child: const Text('Generate Polylines (20)'),
                        ),
                        ElevatedButton(
                          onPressed: () => vm.generateCircles(shapeCount: 20),
                          child: const Text('Generate Circles (20)'),
                        ),
                        ElevatedButton(
                          onPressed: () => vm.clearDemoData(),
                          child: const Text('Clear'),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Fast markers'),
                            Switch(
                              value: vm.useCanvasMarkers,
                              onChanged: (v) {
                                vm.useCanvasMarkers = v;
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                // compute points from generated shapes and raw markers
                                final pts = <LatLng>[];
                                pts.addAll(
                                    vm.mapNotifier.markers.map((m) => m.point));
                                for (final p in vm.mapNotifier.polygons) {
                                  pts.addAll(p.points);
                                }
                                for (final l in vm.mapNotifier.polylines) {
                                  pts.addAll(l.points);
                                }
                                for (final c in vm.mapNotifier.circles) {
                                  pts.add(c.point);
                                }
                                for (final r in vm.mapNotifier.rawMarkers) {
                                  if (r is List && r.length >= 2) {
                                    final lat = (r[0] as num).toDouble();
                                    final lng = (r[1] as num).toDouble();
                                    pts.add(LatLng(lat, lng));
                                  } else if (r is LatLng) {
                                    pts.add(r);
                                  } else if (r is Marker) {
                                    pts.add(r.point);
                                  } else if (r is Map) {
                                    final lat =
                                        (r['lat'] as num?)?.toDouble() ??
                                            (r['latitude'] as num?)?.toDouble();
                                    final lng = (r['lon'] as num?)
                                            ?.toDouble() ??
                                        (r['longitude'] as num?)?.toDouble();
                                    if (lat != null && lng != null) {
                                      pts.add(LatLng(lat, lng));
                                    }
                                  }
                                }

                                if (pts.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'No generated shapes to zoom to')),
                                  );
                                  return;
                                }

                                // bounds
                                double minLat = pts.first.latitude;
                                double maxLat = pts.first.latitude;
                                double minLng = pts.first.longitude;
                                double maxLng = pts.first.longitude;
                                for (final p in pts) {
                                  if (p.latitude < minLat) minLat = p.latitude;
                                  if (p.latitude > maxLat) maxLat = p.latitude;
                                  if (p.longitude < minLng) {
                                    minLng = p.longitude;
                                  }
                                  if (p.longitude > maxLng) {
                                    maxLng = p.longitude;
                                  }
                                }

                                // handle antimeridian wrap
                                double lngDelta = maxLng - minLng;
                                if (lngDelta < 0) lngDelta += 360;
                                if (lngDelta > 180) lngDelta = 360 - lngDelta;

                                final latDelta = (maxLat - minLat).abs();
                                final center = LatLng((minLat + maxLat) / 2,
                                    (minLng + maxLng) / 2);

                                final size = MediaQuery.of(context).size;
                                final tileSize = 256.0;
                                final wx = (size.width * 360) /
                                    (lngDelta == 0 ? 0.0001 : lngDelta) /
                                    tileSize;
                                final wy = (size.height * 360) /
                                    (latDelta == 0 ? 0.0001 : latDelta) /
                                    tileSize;
                                final zoomX = math.log(wx) / math.log(2);
                                final zoomY = math.log(wy) / math.log(2);
                                var zoom = math.min(zoomX, zoomY);
                                if (!zoom.isFinite) zoom = 12.0;
                                zoom = zoom.clamp(1.0, 19.0);

                                final ctrl =
                                    FormFieldsMapController.getOrCreate(
                                        'default');
                                try {
                                  ctrl.move(center, zoom);
                                } catch (e) {
                                  try {
                                    ctrl.move(center, 12.0);
                                  } catch (_) {}
                                }
                              },
                              child: const Text('Zoom to generated bounds'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fullscreen map area
                    Expanded(
                      child: FormFieldsMap(
                        notifier: vm.mapNotifier,
                        useCanvasMarkers: vm.useCanvasMarkers,
                        // Make canvas marker larger so icon appears at expected size
                        canvasMarkerRadius: 20.0,
                        // Use custom canvas marker icon from example assets.
                        // Place your marker image at example/assets/marker_pin.png
                        // (PNG with transparent background recommended).
                        canvasMarkerIcon: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 36,
                        ),
                        onMarkerTap: (m) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Marker: ${m.point.latitude}, ${m.point.longitude}')),
                          );
                        },
                        initialCenter: vm.center,
                        initialZoom: 12.0,
                        onTap: (latlng) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tapped: ${latlng.latitude}, ${latlng.longitude}',
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text('Code example',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        "FormFieldsMap(center: LatLong(-6.2, 106.8166), zoom: 12.0)",
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
              // NOTE: loading indicator for demo data generation is shown
              // by the map widget itself via the controller. The view-level
              // indicator was removed to avoid duplicate overlays.
            ],
          );
          // Progress overlay
          // Show while generation is active or when any progress > 0.
          final showProgress = vm.isLoading ||
              vm.generatedMarkers > 0 ||
              vm.generatedPolygons > 0 ||
              vm.generatedPolylines > 0 ||
              vm.generatedCircles > 0;
          if (showProgress) {
            return Stack(
              children: [
                content,
                Positioned(
                  right: 12,
                  top: 12,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Markers: ${vm.generatedMarkers}/${vm.totalMarkers}'),
                          if (vm.totalMarkers > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: vm.totalMarkers > 0
                                    ? vm.generatedMarkers / vm.totalMarkers
                                    : null,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                              'Polygons: ${vm.generatedPolygons}/${vm.totalPolygons}'),
                          if (vm.totalPolygons > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: vm.totalPolygons > 0
                                    ? vm.generatedPolygons / vm.totalPolygons
                                    : null,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                              'Polylines: ${vm.generatedPolylines}/${vm.totalPolylines}'),
                          if (vm.totalPolylines > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: vm.totalPolylines > 0
                                    ? vm.generatedPolylines / vm.totalPolylines
                                    : null,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                              'Circles: ${vm.generatedCircles}/${vm.totalCircles}'),
                          if (vm.totalCircles > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: vm.totalCircles > 0
                                    ? vm.generatedCircles / vm.totalCircles
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return content;
        },
      ),
    );
  }
}
