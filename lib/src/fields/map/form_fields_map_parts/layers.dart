part of '../form_fields_map.dart';

/// Builders for the stacked layers of [FormFieldsMapState.build]. Each one
/// renders a single overlay so `build` only composes them in order.
extension _FormFieldsMapLayersX on FormFieldsMapState {
  Widget _buildMapLayer({
    required FormFieldsMapNotifier notifier,
    required BuildContext context,
  }) {
    return ChangeNotifierProvider<FormFieldsMapNotifier>.value(
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
            urlTemplate: _tileUrlTemplateEffective,
            subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
            tileProvider: _tileProvider,
            maxZoom: widget.maxZoom,
            minZoom: widget.minZoom,
            // Tiles appear at once. The default fade-in animates every tile
            // with its own layer, which is costly while the camera is moving.
            tileDisplay: const TileDisplay.instantaneous(),
          ),
          Selector<FormFieldsMapNotifier, List<Polygon>>(
            selector: (_, n) => n.polygons,
            builder: (context, polygons, _) {
              final notifierLocal =
                  FormFieldsMapController.getNotifier(_controllerId) ??
                  _fallbackNotifier;
              if (notifierLocal.polygonMap.isEmpty) {
                return const SizedBox.shrink();
              }
              final themeColor = Theme.of(context).colorScheme.primary;
              final mapped = notifierLocal.polygonMap.entries
                  .map((e) {
                    final id = e.key;
                    final p = e.value;
                    final dynColor = _extractColorPayloadForId(
                      notifierLocal,
                      id,
                    );
                    final parsed = ShapeMeta.parseColor(dynColor);
                    return Polygon(
                      points: p.points,
                      color: parsed != null
                          ? parsed.withValues(alpha: 0.25)
                          : themeColor.withValues(alpha: 0.25),
                      borderColor: parsed ?? themeColor,
                      borderStrokeWidth: p.borderStrokeWidth,
                    );
                  })
                  .toList(growable: false);
              // Also accept polygons provided as ShapeMeta in rawMarkers
              final extraPolys = <Polygon>[];
              for (final r in _rawShapeIndexFor(notifierLocal).polygons) {
                if (r.shapeType == ShapeTypes.polygon) {
                  final pms = r.pointMetas;
                  if (pms == null || pms.isEmpty) continue;
                  final pts = pms.map((pm) => pm.point).toList(growable: false);
                  final parsed = r.color;
                  final opts = r.polygonOptions();
                  final fill =
                      opts.fillColor ??
                      (parsed != null
                          ? parsed.withValues(alpha: 0.25)
                          : themeColor.withValues(alpha: 0.25));
                  final border = opts.borderColor ?? parsed ?? themeColor;
                  final defaultPoly = Polygon(
                    points: pts,
                    color: fill,
                    borderColor: border,
                    borderStrokeWidth: opts.borderStrokeWidth ?? 1.0,
                  );
                  final finalPoly = widget.polygonBuilder != null
                      ? widget.polygonBuilder!(r, defaultPoly)
                      : defaultPoly;
                  extraPolys.add(finalPoly);
                }
              }
              final allPolys = [...mapped, ...extraPolys];
              if (allPolys.isEmpty) return const SizedBox.shrink();

              // Titles for shapes (polygons/polylines/circles) are rendered
              // by `CanvasRawMarkerPainter` through `rawMarkers`. Avoid
              // creating `Marker`-based titles for polygons here so that
              // only actual `marker` shapes use `MarkerLayer` rendering.
              return PolygonLayer(polygons: allPolys);
            },
          ),
          Selector<FormFieldsMapNotifier, List<Polyline>>(
            selector: (_, n) => n.polylines,
            builder: (context, polylines, _) {
              final notifierLocal =
                  FormFieldsMapController.getNotifier(_controllerId) ??
                  _fallbackNotifier;
              if (notifierLocal.polylineMap.isEmpty) {
                return const SizedBox.shrink();
              }
              final themeColor = Theme.of(context).colorScheme.primary;
              final mapped = notifierLocal.polylineMap.entries
                  .map((e) {
                    final id = e.key;
                    final l = e.value;
                    final dynColor = _extractColorPayloadForId(
                      notifierLocal,
                      id,
                    );
                    final parsed = ShapeMeta.parseColor(dynColor);
                    return Polyline(
                      points: l.points,
                      strokeWidth: l.strokeWidth,
                      color: parsed ?? themeColor,
                    );
                  })
                  .toList(growable: false);
              // Also accept polylines provided as ShapeMeta in rawMarkers
              final extraPls = <Polyline>[];
              for (final r in _rawShapeIndexFor(notifierLocal).polylines) {
                if (r.shapeType == ShapeTypes.polyline) {
                  final pms = r.pointMetas;
                  if (pms == null || pms.isEmpty) continue;
                  final pts = pms.map((pm) => pm.point).toList(growable: false);
                  final parsed = r.color;
                  final opts = r.polylineOptions();
                  final defaultPl = Polyline(
                    points: pts,
                    strokeWidth: opts.strokeWidth ?? 2.0,
                    color: opts.color ?? parsed ?? themeColor,
                    useStrokeWidthInMeter: opts.useStrokeWidthInMeter ?? true,
                  );
                  final finalPl = widget.polylineBuilder != null
                      ? widget.polylineBuilder!(r, defaultPl)
                      : defaultPl;
                  extraPls.add(finalPl);
                }
              }
              final allPls = [...mapped, ...extraPls];
              if (allPls.isEmpty) return const SizedBox.shrink();
              return PolylineLayer(polylines: allPls);
            },
          ),
          Selector<FormFieldsMapNotifier, List<CircleMarker>>(
            selector: (_, n) => n.circles,
            builder: (context, circles, _) {
              final notifierLocal =
                  FormFieldsMapController.getNotifier(_controllerId) ??
                  _fallbackNotifier;
              if (notifierLocal.circleMap.isEmpty) {
                return const SizedBox.shrink();
              }
              final themeColor = Theme.of(context).colorScheme.primary;
              final mapped = notifierLocal.circleMap.entries
                  .map((e) {
                    final id = e.key;
                    final c = e.value;
                    final dynColor = _extractColorPayloadForId(
                      notifierLocal,
                      id,
                    );
                    final parsed = ShapeMeta.parseColor(dynColor);
                    return CircleMarker(
                      point: c.point,
                      color: parsed != null
                          ? parsed.withValues(alpha: 0.35)
                          : themeColor.withValues(alpha: 0.35),
                      borderStrokeWidth: c.borderStrokeWidth,
                      borderColor: parsed ?? themeColor,
                      useRadiusInMeter: c.useRadiusInMeter,
                      radius: c.radius,
                    );
                  })
                  .toList(growable: false);
              // Also accept circles provided as ShapeMeta in rawMarkers
              final extraCircles = <CircleMarker>[];
              for (final r in _rawShapeIndexFor(notifierLocal).circles) {
                if (r.shapeType == ShapeTypes.circle) {
                  final pms = r.pointMetas;
                  if (pms == null || pms.isEmpty) continue;
                  final center = pms.first.point;
                  // try to obtain radius from first PointMeta.rotation if present
                  final rad = pms.first.rotation ?? 10.0;
                  final parsed = r.color;
                  final opts = r.circleOptions();
                  final defaultCircle = CircleMarker(
                    point: center,
                    color: parsed != null
                        ? parsed.withValues(alpha: 0.35)
                        : themeColor.withValues(alpha: 0.35),
                    borderStrokeWidth: opts.borderStrokeWidth ?? 0.0,
                    borderColor: opts.borderColor ?? parsed ?? themeColor,
                    useRadiusInMeter: opts.useRadiusInMeter ?? true,
                    radius: opts.radiusMeters ?? rad,
                  );
                  final finalCircle = widget.circleBuilder != null
                      ? widget.circleBuilder!(r, defaultCircle)
                      : defaultCircle;
                  extraCircles.add(finalCircle);
                }
              }
              final allCircles = [...mapped, ...extraCircles];
              if (allCircles.isEmpty) return const SizedBox.shrink();
              return CircleLayer(circles: allCircles);
            },
          ),
          Selector<FormFieldsMapNotifier, List<Marker>>(
            selector: (_, n) => n.markers,
            builder: (context, markers, _) {
              if (markers.isEmpty) return const SizedBox.shrink();
              final notifierLocal =
                  FormFieldsMapController.getNotifier(_controllerId) ??
                  _fallbackNotifier;
              final mapped = markers
                  .map((m) {
                    // try to find a color for this marker from rawMarkers (by point)
                    final dynColor = _extractColorPayloadForPoint(
                      notifierLocal,
                      m.point,
                    );
                    ShapeMeta.parseColor(dynColor);
                    // use idiomatic colorScheme.onSecondary for marker foreground
                    final markerForeground = Theme.of(
                      context,
                    ).colorScheme.onSecondary;
                    final child = m.child;
                    Widget themedChild;
                    if (child is Icon) {
                      themedChild = Icon(
                        child.icon,
                        size: child.size,
                        semanticLabel: child.semanticLabel,
                        textDirection: child.textDirection,
                        color: markerForeground,
                      );
                    } else {
                      themedChild = IconTheme(
                        data: IconThemeData(color: markerForeground),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(color: markerForeground),
                          child: child,
                        ),
                      );
                    }
                    return Marker(
                      point: m.point,
                      width: m.width,
                      height: m.height,
                      rotate: m.rotate,
                      child: themedChild,
                    );
                  })
                  .toList(growable: false);
              // Also accept markers provided as ShapeMeta in rawMarkers
              final extraMarkers = <Marker>[];
              // Default marker widgets are empty placeholders (no visible child and
              // no gesture), so they are only built when a markerBuilder is given.
              // Building one per raw entry was a large part of each rebuild.
              if (widget.markerBuilder != null) {
                for (final r in _rawShapeIndexFor(notifierLocal).markers) {
                  if (r.shapeType == ShapeTypes.marker) {
                    final pms = r.pointMetas;
                    if (pms == null || pms.isEmpty) continue;
                    final center = pms.first.point;
                    // Build a default simple marker; consumer builder can
                    // replace or modify this.
                    final opts = r.markerOptions();
                    final defaultMarker = Marker(
                      point: center,
                      width: opts.width ?? 40,
                      height: opts.height ?? 40,
                      rotate: opts.rotate,
                      child: const SizedBox.shrink(),
                    );
                    final finalMarker = widget.markerBuilder != null
                        ? widget.markerBuilder!(r, defaultMarker)
                        : defaultMarker;
                    extraMarkers.add(finalMarker);
                  }
                }
              }
              return MarkerLayer(markers: [...mapped, ...extraMarkers]);
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable:
                FormFieldsMapController.getBlockingLoadingListenable(
                  _controllerId,
                ),
            builder: (context, isBlocking, _) {
              return Selector<FormFieldsMapNotifier, int>(
                selector: (_, n) => n.rawRevision,
                builder: (context, revision, _) {
                  final rawMarkers = context
                      .read<FormFieldsMapNotifier>()
                      .rawMarkers;
                  if (rawMarkers.isEmpty) return const SizedBox.shrink();
                  final renderedRawMarkers =
                      rawMarkers.length > widget.maxRenderedRawMarkers
                      ? rawMarkers.sublist(0, widget.maxRenderedRawMarkers)
                      : rawMarkers;
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CanvasRawMarkerPainter(
                          rawMarkers: renderedRawMarkers,
                          rawRevision: revision,
                          center: _lastCenter ?? widget.initialCenter,
                          zoom: _lastZoom ?? widget.initialZoom,
                          radius: _canvasMarkerRadiusEffective,
                          devicePixelRatio: MediaQuery.of(
                            context,
                          ).devicePixelRatio,
                          iconImage: _canvasMarkerImage,
                          playbackIconImage: _playbackMarkerImage,
                          playbackHaloColor: _playbackHaloColor,
                          playbackHaloScale: _playbackHaloScale,
                          playbackHaloOpacity: _playbackHaloOpacity,
                          // hide titles while blocking loading is active or when zoom is low
                          showTitle:
                              _showTitleEffective &&
                              !isBlocking &&
                              ((_lastZoom ?? widget.initialZoom) >= 10.0),
                          defaultColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar({
    required Future<List<FormFieldsLocationPrediction>> Function(String)?
    localFetcherForMap,
    required bool localAvailable,
    required BuildContext context,
  }) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 50,
      right: 50,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: FormFieldsAutocomplete<FormFieldsLocationPrediction>(
            fieldLabel: 'Search',
            hideTrailingIcon: true,
            preferLocalOnly: localAvailable,
            localFetcher: localFetcherForMap,
            apiUrl:
                _findConfigEffective.apiUrl ??
                'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1',
            parseResults:
                _findConfigEffective.apiParseResults ??
                (data) {
                  final out = <FormFieldsLocationPrediction>[];
                  try {
                    if (data is List) {
                      for (final e in data) {
                        try {
                          final lat = (e['lat'] is String)
                              ? double.parse(e['lat'] as String)
                              : (e['lat'] as num).toDouble();
                          final lon = (e['lon'] is String)
                              ? double.parse(e['lon'] as String)
                              : (e['lon'] as num).toDouble();
                          final display = e['display_name']?.toString() ?? '';
                          out.add(
                            FormFieldsLocationPrediction(
                              latLng: LatLng(lat, lon),
                              address: display,
                            ),
                          );
                        } catch (_) {}
                      }
                    } else if (data is Map && data['results'] is List) {
                      for (final e in data['results']) {
                        try {
                          final lat = (e['lat'] is String)
                              ? double.parse(e['lat'] as String)
                              : (e['lat'] as num).toDouble();
                          final lon = (e['lon'] is String)
                              ? double.parse(e['lon'] as String)
                              : (e['lon'] as num).toDouble();
                          final display = e['display_name']?.toString() ?? '';
                          out.add(
                            FormFieldsLocationPrediction(
                              latLng: LatLng(lat, lon),
                              address: display,
                            ),
                          );
                        } catch (_) {}
                      }
                    }
                  } catch (_) {}
                  return out;
                },
            externalResults: _findConfigEffective.externalSearchResults,
            onItemSelected: (pred) async {
              if (pred == null) return;
              final zoom = (widget.playbackConfig != null)
                  ? _playbackTargetZoom
                  : (_lastZoom ?? widget.initialZoom);
              // Show the short non-blocking loading indicator while we
              // animate and run any consumer-provided handler.
              try {
                FormFieldsMapController.setLoading(_controllerId, true);
                if (_onCenterMarkerEffective != null) {
                  try {
                    await animateTo(pred.latLng, zoom);
                    // await _onCenterMarkerEffective!(pred);
                  } catch (_) {}
                } else {
                  try {
                    await animateTo(pred.latLng, zoom);
                  } catch (_) {}
                }
              } finally {
                // Cancel any pending camera-idle debounce so it doesn't
                // later re-enable loading unexpectedly, and ensure we
                // clear loading on the next frame after any pending
                // post-frame callbacks from the map settle.
                try {
                  _debounceTimer?.cancel();
                } catch (_) {}
                try {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      FormFieldsMapController.setLoading(_controllerId, false);
                    } catch (_) {}
                  });
                } catch (_) {
                  try {
                    FormFieldsMapController.setLoading(_controllerId, false);
                  } catch (_) {}
                }
              }
            },
            itemSelectedBuilder: (p) => p.address,
            itemBuilder: (p, selected) {
              return ListTile(
                title: Text(p.address),
                subtitle: Text(
                  '${p.latLng.latitude.toStringAsFixed(6)}, ${p.latLng.longitude.toStringAsFixed(6)}',
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
