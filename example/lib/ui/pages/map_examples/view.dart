import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/localization/localizations.dart';

// Simple integer formatter for thousands separators without adding
// an external dependency.
String formatNumber(int value) {
  final s = value.toString();
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return s.replaceAllMapped(reg, (m) => ',');
}

// `flutter_map` is used internally by the package; example doesn't import it directly.

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: model,
      child: Consumer<ViewModel>(
        builder: (context, vm, _) {
          // Ensure the example's notifier is registered under a stable
          // controller id so the `FormFieldsMap` widget can retrieve it
          // from `FormFieldsMapController`.
          // Notifier is registered by the ViewModel; nothing to do here.

          final content = Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('mapExampleDescription'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: vm.toggleActionsExpanded,
                              icon: Icon(
                                vm.actionsExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              label: Text(
                                vm.actionsExpanded
                                    ? 'Hide actions'
                                    : 'Show actions',
                              ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: vm.actionsExpanded
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _mapActionsPanel(
                                    context,
                                    vm,
                                    optionsRows: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Show titles'),
                                          const SizedBox(width: 6),
                                          Switch.adaptive(
                                            value: vm.showTitle,
                                            onChanged: (v) =>
                                                vm.setShowTitle(v),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Feature'),
                                          const SizedBox(width: 6),
                                          Icon(
                                            vm.selectedFeature ==
                                                    FormFieldsMapFeature
                                                        .playback
                                                ? Icons.play_arrow
                                                : vm.selectedFeature ==
                                                      FormFieldsMapFeature.map
                                                ? Icons.map
                                                : Icons.search,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          DropdownButton<FormFieldsMapFeature?>(
                                            value: vm.selectedFeature,
                                            items: const [
                                              DropdownMenuItem(
                                                value: FormFieldsMapFeature
                                                    .playback,
                                                child: Text('Playback'),
                                              ),
                                              DropdownMenuItem(
                                                value: FormFieldsMapFeature.map,
                                                child: Text('Map'),
                                              ),
                                              DropdownMenuItem(
                                                value:
                                                    FormFieldsMapFeature.find,
                                                child: Text('Find'),
                                              ),
                                            ],
                                            onChanged: (v) =>
                                                vm.setSelectedFeature(v),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FormFieldsMap(
                      controller: vm.mapController,
                      features: vm.selectedFeature,
                      // Example: use OpenStreetMap tiles and show labels
                      // tileUrlTemplate:
                      //     'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      // tileAttribution: '© OpenStreetMap contributors',
                      mapConfig: FormFieldsMapMapConfig(
                        enableClustering: false,
                        canvasMarkerRadius: 20.0,
                        canvasMarkerIcon: const Icon(
                          Icons.location_pin,
                          size: 100,
                        ),
                        showTitle: vm.showTitle,
                      ),
                      findConfig: FormFieldsMapFindConfig(
                        allowGeolocation: true,
                        findTimeout: Duration(seconds: 5),
                        showSearchBar: true,
                        showMarkerInCenter: true,
                        // Use a free public geocoding API to avoid 403 issues
                        // (geocode.maps.co is an OpenStreetMap-based free service).
                        // externalSearchResults: vm.externalSearchResults,
                        // apiUrl: 'https://geocode.maps.co/search',
                        // apiParseResults: (data) {
                        //   final out = <FormFieldsLocationPrediction>[];
                        //   try {
                        //     if (data is List) {
                        //       for (final e in data) {
                        //         try {
                        //           final lat = (e['lat'] is String)
                        //               ? double.parse(e['lat'] as String)
                        //               : (e['lat'] as num).toDouble();
                        //           final lon = (e['lon'] is String)
                        //               ? double.parse(e['lon'] as String)
                        //               : (e['lon'] as num).toDouble();
                        //           final display =
                        //               e['display_name']?.toString() ?? '';
                        //           out.add(FormFieldsLocationPrediction(
                        //               latLng: LatLng(lat, lon),
                        //               address: display));
                        //         } catch (_) {}
                        //       }
                        //     }
                        //   } catch (_) {}
                        //   return out;
                        // },
                        centerMarker: const Icon(
                          Icons.location_pin,
                          size: 50,
                          color: Colors.blueAccent,
                        ),
                        onCenterMarker: (pred) async {
                          final messenger = ScaffoldMessenger.of(context);
                          // try {
                          //   // Let the ViewModel handle animation and loading.
                          //   await vm.selectSearchResult(pred);
                          // } catch (_) {}
                          // Only show the SnackBar if still mounted to avoid
                          // using BuildContext after disposal.
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Selected: ${pred.address}'),
                              ),
                            );
                          }
                        },
                        // Use package geocoding fallback by not providing
                        // an explicit `reverseGeocode` here.
                      ),
                      playbackConfig: FormFieldsMapPlaybackConfig(
                        playbackInterval: vm.playbackInterval,
                        playbackInterpolationSteps:
                            vm.playbackInterpolationSteps,
                        showBuiltinPlaybackControls: true,
                        playbackPolylineColor: Colors.lightGreen,
                        playbackMarkerIcon: const Icon(
                          Icons.arrow_upward,
                          color: Colors.red,
                          size: 100,
                        ),
                        playbackFollowCamera: true,
                        playbackAutoStart: true,
                        onPointReached: (polylineId, index, point) async {
                          // Update VM with latest playback info so sheet content
                          // (if open) can react immediately.
                          final raw = FormFieldsMapController.getRawMarkers(
                            vm.controllerId,
                          );
                          dynamic shape;
                          if (polylineId != null) {
                            try {
                              shape = raw.firstWhere((r) {
                                try {
                                  if (r is ShapeMeta) return r.id == polylineId;
                                  if (r is Map) return r['id'] == polylineId;
                                } catch (_) {}
                                return false;
                              });
                            } catch (_) {
                              shape = null;
                            }
                          }

                          vm.setLastPlaybackInfo(
                            polylineId: polylineId,
                            index: index,
                            point: point,
                            shape: shape,
                          );

                          if (vm.isPlaybackSheetOpen) return;
                          vm.isPlaybackSheetOpen = true;
                          try {
                            await showAppModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (ctx) {
                                return ChangeNotifierProvider.value(
                                  value: vm,
                                  child: Consumer<ViewModel>(
                                    builder: (ctx2, vm2, _) {
                                      final title = () {
                                        try {
                                          final s = vm2.playbackLastShape;
                                          if (s is ShapeMeta) {
                                            return s.hit?.title;
                                          }
                                          if (s is Map) {
                                            return (s['hit'] as Map?)?['title'];
                                          }
                                        } catch (_) {}
                                        return vm2.playbackLastPolylineId !=
                                                null
                                            ? 'Polyline ${vm2.playbackLastPolylineId}'
                                            : 'Playback point';
                                      }();

                                      () {
                                        try {
                                          final s = vm2.playbackLastShape;
                                          if (s is ShapeMeta) {
                                            return s.properties ?? {};
                                          }
                                          if (s is Map) {
                                            return s['properties'] ?? {};
                                          }
                                        } catch (_) {}
                                        return <String, dynamic>{};
                                      }();

                                      final int? pointCount = () {
                                        try {
                                          final s = vm2.playbackLastShape;
                                          if (s is ShapeMeta &&
                                              s.pointMetas != null) {
                                            return s.pointMetas!.length;
                                          }
                                          if (s is Map &&
                                              s['pointMetas'] is List) {
                                            return (s['pointMetas'] as List)
                                                .length;
                                          }
                                        } catch (_) {}
                                        return null;
                                      }();

                                      final displayIndex =
                                          vm2.playbackLastIndex;
                                      final displayPoint =
                                          vm2.playbackLastPoint;

                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          20,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Center(
                                            //   child: Container(
                                            //     width: 40,
                                            //     height: 4,
                                            //     decoration: BoxDecoration(
                                            //       color: Colors.grey[300],
                                            //       borderRadius:
                                            //           BorderRadius.circular(4),
                                            //     ),
                                            //   ),
                                            // ),
                                            // const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  title ??
                                                      'Playback point reached',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.skip_previous,
                                                      ),
                                                      onPressed: () =>
                                                          FormFieldsMapController.stepPolylineBackward(
                                                            vm.controllerId,
                                                            vm.playbackPolylineId,
                                                          ),
                                                    ),
                                                    ValueListenableBuilder<
                                                      bool
                                                    >(
                                                      valueListenable:
                                                          FormFieldsMapController.getPlaybackPlayingListenable(
                                                            vm.controllerId,
                                                          ),
                                                      builder: (context, playing, _) {
                                                        return IconButton(
                                                          icon: Icon(
                                                            playing
                                                                ? Icons.pause
                                                                : Icons
                                                                      .play_arrow,
                                                          ),
                                                          onPressed: () {
                                                            if (playing) {
                                                              FormFieldsMapController.pausePolylinePlayback(
                                                                vm.controllerId,
                                                              );
                                                            } else {
                                                              FormFieldsMapController.startPolylinePlayback(
                                                                vm.controllerId,
                                                                vm.playbackPolylineId,
                                                              );
                                                            }
                                                          },
                                                          tooltip: playing
                                                              ? 'Pause'
                                                              : 'Play',
                                                        );
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.skip_next,
                                                      ),
                                                      onPressed: () =>
                                                          FormFieldsMapController.stepPolylineForward(
                                                            vm.controllerId,
                                                            vm.playbackPolylineId,
                                                          ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.replay,
                                                      ),
                                                      onPressed: () =>
                                                          FormFieldsMapController.restartPolylinePlayback(
                                                            vm.controllerId,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (displayIndex != null)
                                                      Text(
                                                        'Index: $displayIndex',
                                                      ),
                                                    if (displayPoint != null)
                                                      Text(
                                                        'Coords: ${displayPoint.latitude.toStringAsFixed(6)}, ${displayPoint.longitude.toStringAsFixed(6)}',
                                                      ),
                                                    if (pointCount != null)
                                                      Text(
                                                        'Points: $pointCount',
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // const SizedBox(height: 8),
                                            // if (properties.isNotEmpty) ...[
                                            //   const Text('Properties',
                                            //       style: TextStyle(
                                            //           fontWeight:
                                            //               FontWeight.w600)),
                                            //   const SizedBox(height: 6),
                                            //   Wrap(
                                            //     spacing: 8,
                                            //     runSpacing: 6,
                                            //     children: properties.entries
                                            //         .map((e) => Chip(
                                            //             label: Text(
                                            //                 '${e.key}: ${e.value}')))
                                            //         .toList(),
                                            //   ),
                                            //   const SizedBox(height: 12),
                                            // ],
                                            // Row(
                                            //   mainAxisAlignment:
                                            //       MainAxisAlignment.end,
                                            //   children: [
                                            //     TextButton(
                                            //         onPressed: () =>
                                            //             Navigator.of(ctx2)
                                            //                 .pop(),
                                            //         child: const Text('Close')),
                                            //     const SizedBox(width: 8),
                                            //     ElevatedButton(
                                            //       style:
                                            //           ElevatedButton.styleFrom(
                                            //         backgroundColor:
                                            //             Colors.lightGreen,
                                            //         shape:
                                            //             RoundedRectangleBorder(
                                            //                 borderRadius:
                                            //                     BorderRadius
                                            //                         .circular(
                                            //                             8)),
                                            //       ),
                                            //       onPressed: () =>
                                            //           Navigator.of(ctx2).pop(),
                                            //       child: const Text('Done'),
                                            //     ),
                                            //   ],
                                            // )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          } finally {
                            vm.isPlaybackSheetOpen = false;
                          }
                        },
                      ),
                      // moved canvas marker settings into `mapConfig`
                      onCenterChanged: (value) {
                        debugPrint('onCenterChanged: $value');
                      },
                      // showMarkerInCenter: true,
                      onTapShape: (sm) async {
                        // `sm` is a ShapeMeta
                        final title = sm.hit?.title ?? 'Detail';
                        final subtitle = sm.hit?.subtitle ?? '';
                        final id = sm.id;
                        final pt =
                            (sm.pointMetas != null && sm.pointMetas!.isNotEmpty)
                            ? sm.pointMetas!.first.point
                            : LatLng(0, 0);

                        if (sm.shapeType == ShapeTypes.marker ||
                            (id != null && id.startsWith('m\$'))) {
                          await showDialog<void>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: Text(title.toString()),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (subtitle.isNotEmpty) Text(subtitle),
                                    if (id != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'ID: $id',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    if (sm.shapeType != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Type: ${sm.shapeType}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Coords: ${pt.latitude.toStringAsFixed(6)}, ${pt.longitude.toStringAsFixed(6)}',
                                      ),
                                    ],
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                  if (id != null)
                                    TextButton(
                                      onPressed: () {
                                        if (id.startsWith('m\$')) {
                                          FormFieldsMapController.removeRawMarker(
                                            vm.controllerId,
                                            id,
                                          );
                                        } else if (id.startsWith('p\$')) {
                                          FormFieldsMapController.removePolygon(
                                            vm.controllerId,
                                            id,
                                          );
                                        } else if (id.startsWith('l\$')) {
                                          FormFieldsMapController.removePolyline(
                                            vm.controllerId,
                                            id,
                                          );
                                        } else if (id.startsWith('c\$')) {
                                          FormFieldsMapController.removeCircle(
                                            vm.controllerId,
                                            id,
                                          );
                                        }
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Deleted'),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        } else {
                          final shapeId = sm.id;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tapped: ${sm.shapeType}${shapeId != null ? ' (ID: $shapeId)' : ''}',
                              ),
                            ),
                          );
                        }
                      },
                      initialCenter: vm.center,
                      // initialZoom: 12.0,
                      onMapTap: (latlng) {
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
                ],
              ),
              // _DraggablePositioned(
              //   initialRight: 16,
              //   initialBottom: 16,
              //   initWidth: 220,
              //   initHeight: 56,
              //   child: FloatingActionButton.extended(
              //     onPressed: zoomToGeneratedBounds,
              //     icon: const Icon(Icons.zoom_out_map),
              //     label: const Text('Zoom to generated bounds'),
              //   ),
              // ),
              if (vm.totalPolylines > 0 &&
                  vm.selectedFeature == FormFieldsMapFeature.playback)
                _DraggablePositioned(
                  // initialRight: 0,
                  initWidth: 260,
                  initHeight: 140,
                  initialTop: 0,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Polyline Playback',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    FormFieldsMapController.getPlaybackPlayingListenable(
                                      vm.controllerId,
                                    ),
                                builder: (context, playing, _) {
                                  return IconButton(
                                    icon: Icon(
                                      playing ? Icons.pause : Icons.play_arrow,
                                    ),
                                    onPressed: () {
                                      if (playing) {
                                        FormFieldsMapController.pausePolylinePlayback(
                                          vm.controllerId,
                                        );
                                      } else {
                                        FormFieldsMapController.startPolylinePlayback(
                                          vm.controllerId,
                                          vm.playbackPolylineId,
                                        );
                                      }
                                    },
                                    tooltip: playing ? 'Pause' : 'Play',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_previous),
                                onPressed: () =>
                                    FormFieldsMapController.stepPolylineBackward(
                                      vm.controllerId,
                                      vm.playbackPolylineId,
                                    ),
                                tooltip: 'Previous',
                              ),
                              IconButton(
                                icon: const Icon(Icons.replay),
                                onPressed: () =>
                                    FormFieldsMapController.restartPolylinePlayback(
                                      vm.controllerId,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next),
                                onPressed: () =>
                                    FormFieldsMapController.stepPolylineForward(
                                      vm.controllerId,
                                      vm.playbackPolylineId,
                                    ),
                                tooltip: 'Next',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Interval:'),
                              _intervalButton(
                                vm,
                                '0.5s',
                                const Duration(milliseconds: 500),
                              ),
                              _intervalButton(
                                vm,
                                '1s',
                                const Duration(seconds: 1),
                              ),
                              _intervalButton(
                                vm,
                                '2s',
                                const Duration(seconds: 2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Interp:'),
                              _interpButton(vm, '0', 0),
                              _interpButton(vm, '2', 2),
                              _interpButton(vm, '4', 4),
                              _interpButton(vm, '8', 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );

          // Progress overlay
          final showProgress =
              vm.isLoading ||
              vm.generatedMarkers > 0 ||
              vm.generatedPolygons > 0 ||
              vm.generatedPolylines > 0 ||
              vm.generatedCircles > 0;
          if (showProgress) {
            return Stack(
              children: [
                content,
                _DraggablePositioned(
                  initialRight: 12,
                  initialTop: 12,
                  initWidth: 220,
                  initHeight: 160,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vm.markerUpdatesActive ? 'Processed' : 'Markers'}: ${formatNumber(vm.generatedMarkers)}/${formatNumber(vm.totalMarkers)}',
                          ),
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
                            'Polygons: ${formatNumber(vm.generatedPolygons)}/${formatNumber(vm.totalPolygons)}',
                          ),
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
                            'Polylines: ${formatNumber(vm.generatedPolylines)}/${formatNumber(vm.totalPolylines)}',
                          ),
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
                            'Circles: ${formatNumber(vm.generatedCircles)}/${formatNumber(vm.totalCircles)}',
                          ),
                          if (vm.totalCircles > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: vm.totalCircles > 0
                                    ? vm.generatedCircles / vm.totalCircles
                                    : null,
                              ),
                            ),
                          if (vm.markerUpdatesActive) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Next update in: ${vm.markerUpdateCountdownFormatted}',
                            ),
                            const SizedBox(height: 6),
                            if (vm.lastMarkerUpdatesApplied > 0)
                              Text(
                                'Updated ${formatNumber(vm.lastMarkerUpdatesApplied)} markers',
                              ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: vm.markerUpdateInterval.inSeconds > 0
                                    ? (vm.markerUpdateInterval.inSeconds -
                                              vm.markerUpdateRemainingSeconds) /
                                          vm.markerUpdateInterval.inSeconds
                                    : null,
                              ),
                            ),
                          ],
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

Widget _intervalButton(ViewModel vm, String label, Duration d) {
  final selected = vm.playbackInterval.inMilliseconds == d.inMilliseconds;
  return TextButton(
    onPressed: () => vm.setPlaybackInterval(d),
    style: TextButton.styleFrom(
      backgroundColor: selected ? Colors.lightGreen : null,
      foregroundColor: selected ? Colors.white : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(label),
  );
}

Widget _interpButton(ViewModel vm, String label, int steps) {
  final selected = vm.playbackInterpolationSteps == steps;
  return TextButton(
    onPressed: () => vm.setPlaybackInterpolationSteps(steps),
    style: TextButton.styleFrom(
      backgroundColor: selected ? Colors.lightGreen : null,
      foregroundColor: selected ? Colors.white : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(label),
  );
}

enum _ActionVariant { primary, secondary, danger }

/// Action buttons for the selected feature, grouped by purpose. The main
/// action is filled, the others are tonal, and clearing is a danger action.
Widget _mapActionsPanel(
  BuildContext context,
  ViewModel vm, {
  required List<Widget> optionsRows,
}) {
  final feature = vm.selectedFeature;
  final sections = <Widget>[];

  if (feature == FormFieldsMapFeature.map) {
    sections.add(
      _ActionSection(
        title: 'Data',
        child: _ActionGrid(
          children: [
            _ActionButton(
              label: 'Generate ${formatNumber(vm.createMarkers)} markers',
              icon: Icons.auto_awesome,
              variant: _ActionVariant.primary,
              expand: true,
              loading: vm.generatingMarkers,
              onPressed: () =>
                  vm.generateMarkers(markerCount: vm.createMarkers),
            ),
            _ActionButton(
              label: 'Generate from API',
              icon: Icons.cloud_download,
              expand: true,
              loading: vm.fetchingFromApi,
              onPressed: () => _promptApiUrlAndGenerate(context, vm),
            ),
          ],
        ),
      ),
    );
    sections.add(
      _ActionSection(
        title: 'Shapes',
        child: _ActionGrid(
          children: [
            _ActionButton(
              label: 'Polygons (${formatNumber(vm.createPolygons)})',
              icon: Icons.change_history,
              loading: vm.generatingPolygons,
              onPressed: () =>
                  vm.generatePolygons(shapeCount: vm.createPolygons),
            ),
            _ActionButton(
              label: 'Circles (${formatNumber(vm.createCircles)})',
              icon: Icons.circle,
              loading: vm.generatingCircles,
              onPressed: () => vm.generateCircles(shapeCount: vm.createCircles),
            ),
            _ActionButton(
              label: 'Polylines (${formatNumber(vm.createPolylines)})',
              icon: Icons.timeline,
              loading: vm.generatingPolylines,
              onPressed: () =>
                  vm.generatePolylines(shapeCount: vm.createPolylines),
            ),
          ],
        ),
      ),
    );
  } else if (feature == FormFieldsMapFeature.playback) {
    sections.add(
      _ActionSection(
        title: 'Playback',
        child: _ActionGrid(
          children: [
            _ActionButton(
              label: 'Generate 1 polyline for playback',
              icon: Icons.add_road,
              variant: _ActionVariant.primary,
              expand: true,
              loading: vm.generatingPolylines,
              onPressed: () => vm.generatePlaybackPolyline(),
            ),
          ],
        ),
      ),
    );
  } else if (feature == FormFieldsMapFeature.find) {
    sections.add(
      _ActionSection(
        title: 'Find',
        child: _ActionGrid(
          children: [
            _ActionButton(
              label: 'Find location',
              icon: Icons.search,
              variant: _ActionVariant.primary,
              expand: true,
              loading: vm.findingLocation,
              onPressed: () => vm.findLocation(),
            ),
          ],
        ),
      ),
    );
  }

  sections.add(
    _ActionSection(
      title: 'Clear',
      child: _ActionGrid(
        children: [
          _ActionButton(
            label: 'Clear all demo data',
            icon: Icons.delete_outline,
            variant: _ActionVariant.danger,
            expand: true,
            onPressed: () => vm.clearDemoData(),
          ),
        ],
      ),
    ),
  );

  final scheme = Theme.of(context).colorScheme;
  sections.add(
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: optionsRows,
      ),
    ),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        sections[i],
      ],
    ],
  );
}

/// Prompts for an API URL and starts loading markers from it.
Future<void> _promptApiUrlAndGenerate(
  BuildContext context,
  ViewModel vm,
) async {
  final controller = TextEditingController(
    text:
        'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson',
  );
  final ok = await showDialog<bool?>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('API URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/data.json',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
  if (ok == true && controller.text.trim().isNotEmpty) {
    vm.generateMarkers(apiUrl: controller.text.trim());
  }
}

/// Small caps-style section title above a group of actions.
class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Two equal columns. Buttons with `expand`, and an odd last button, take the
/// full row so the grid never leaves a gap.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.children});

  final List<_ActionButton> children;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - _gap) / 2;
        final lastIsSingle = children.length.isOdd;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width:
                    children[i].expand ||
                        (lastIsSingle && i == children.length - 1)
                    ? constraints.maxWidth
                    : half,
                child: children[i],
              ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = _ActionVariant.secondary,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final _ActionVariant variant;
  final bool loading;
  final bool expand;

  static const Size _minSize = Size(0, 48);
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 16);
  static const RoundedRectangleBorder _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onTap = loading ? null : onPressed;
    final spinnerColor = variant == _ActionVariant.primary
        ? scheme.onPrimary
        : scheme.primary;

    final leading = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : (icon != null ? Icon(icon, size: 18) : null);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
    final child = leading == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 8),
              Flexible(child: text),
            ],
          );

    switch (variant) {
      case _ActionVariant.primary:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: _minSize,
            padding: _padding,
            shape: _shape,
            elevation: 0,
          ),
          child: child,
        );
      case _ActionVariant.secondary:
        return FilledButton.tonal(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: _minSize,
            padding: _padding,
            shape: _shape,
            elevation: 0,
          ),
          child: child,
        );
      case _ActionVariant.danger:
        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: _minSize,
            padding: _padding,
            shape: _shape,
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
          ),
          child: child,
        );
    }
  }
}

// (Removed unused color helper)

/// A small helper that allows a child placed in a Stack to be dragged
/// around by the user. It accepts optional initial positioning via
/// `initialTop` or `initialRight`. For
/// convenience callers can provide estimated `initWidth`/`initHeight` used
/// to compute initial left/top when right is supplied.
class _DraggablePositioned extends StatefulWidget {
  const _DraggablePositioned({
    this.initialTop,
    this.initialRight,
    this.initWidth = 56.0,
    this.initHeight = 56.0,
    required this.child,
  });

  final double? initialTop;
  final double? initialRight;
  final double initWidth;
  final double initHeight;
  final Widget child;

  @override
  State<_DraggablePositioned> createState() => _DraggablePositionedState();
}

class _DraggablePositionedState extends State<_DraggablePositioned> {
  double? left;
  double? top;
  final GlobalKey _childKey = GlobalKey();
  double? childWidth;
  double? childHeight;

  void _ensureInitialized() {
    if (left != null && top != null) return;
    final size = MediaQuery.of(context).size;
    final w = childWidth ?? widget.initWidth;
    final h = childHeight ?? widget.initHeight;
    if (widget.initialRight != null) {
      left = size.width - widget.initialRight! - w;
    } else {
      left = 16.0;
    }

    if (widget.initialTop != null) {
      top = widget.initialTop;
    } else {
      top = size.height - h - 16.0;
    }
  }

  void _clampToBounds() {
    final size = MediaQuery.of(context).size;
    final w = childWidth ?? widget.initWidth;
    final h = childHeight ?? widget.initHeight;
    final maxLeft = (size.width - w).clamp(0.0, size.width);
    final maxTop = (size.height - h).clamp(0.0, size.height);
    left = (left ?? 0).clamp(0.0, maxLeft);
    top = (top ?? 0).clamp(0.0, maxTop);
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    _clampToBounds();

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {},
        onPanUpdate: (details) {
          setState(() {
            left = (left ?? 0) + details.delta.dx;
            top = (top ?? 0) + details.delta.dy;
            _clampToBounds();
          });
        },
        onPanEnd: (_) {},
        child: Container(key: _childKey, child: widget.child),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Measure child after first frame to get actual size for bounds.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChild());
  }

  void _measureChild() {
    final box = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width;
    final h = box.size.height;
    if (w != childWidth || h != childHeight) {
      setState(() {
        childWidth = w;
        childHeight = h;
        _clampToBounds();
      });
    }
  }
}
