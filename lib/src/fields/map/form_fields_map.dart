import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/src/fields/map/canvas_raw_marker_painter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/utilities/geo_distance.dart';
import 'package:form_fields/src/utilities/debug_log.dart';
part 'form_fields_map_parts/widget.dart';

part 'form_fields_map_parts/playback.dart';
part 'form_fields_map_parts/render.dart';
part 'form_fields_map_parts/data.dart';
part 'form_fields_map_parts/interactions.dart';

part 'form_fields_map_parts/config.dart';
part 'form_fields_map_parts/layers.dart';
part 'form_fields_map_parts/overlays.dart';
part 'form_fields_map_parts/tap.dart';
part 'form_fields_map_parts/lifecycle.dart';

class FormFieldsMapState extends State<FormFieldsMap>
    with AutomaticKeepAliveClientMixin<FormFieldsMap> {
  late final MapController _mapController;
  late final GeocodingService _geocodingService;

  /// Owns the HTTP client for map tiles. Created once: `build` runs on every
  /// playback tick, and a provider created there was never closed.
  final NetworkTileProvider _tileProvider = NetworkTileProvider();
  bool _centerActionInProgress = false;
  Timer? _debounceTimer;
  // Notifier removed from widget API. Consumers should register any
  // FormFieldsMapNotifier instances via the FormFieldsMapController
  // registry; internal logic will obtain the notifier from the
  // controller when needed.
  // Fallback notifier used when no notifier is registered in the
  // `FormFieldsMapController` registry. This preserves previous
  // behavior where the widget had an internal notifier when consumers
  // did not supply one, while keeping notifier registration external.
  late final FormFieldsMapNotifier _fallbackNotifier;

  // Playback state
  Timer? _playbackTimer;

  /// Desired interval between original polyline points (user-facing).
  Duration _playbackInterval = const Duration(seconds: 1);

  /// Actual timer tick interval used for sub-steps (computed from
  /// `_playbackInterval` and interpolation steps).
  Duration _playbackSubstepInterval = const Duration(seconds: 1);
  bool _isPlaying = false;
  List<LatLng> _playbackPoints = [];
  int _playbackIndex = 0;
  String? _playbackPolylineId;
  int _playbackInterpolationSteps = 4;

  LatLng? _lastCenter;
  double? _lastZoom;
  ImageStream? _canvasMarkerImageStream;
  ImageStreamListener? _canvasMarkerImageStreamListener;
  ui.Image? _canvasMarkerImage;
  ImageStream? _playbackMarkerImageStream;
  ImageStreamListener? _playbackMarkerImageStreamListener;
  ui.Image? _playbackMarkerImage;

  bool _suppressNextMapTap = false;

  late String _controllerId;
  bool _ownsController = false;

  // Helpers to resolve playback configuration. Prefer explicit `features`
  // when provided; otherwise fallback to presence of `playbackConfig` for
  // backward compatibility.
  bool get _playbackEnabled {
    final f = widget.features;
    if (f != null) return f == FormFieldsMapFeature.playback;
    return widget.playbackConfig != null;
  }

  // Effective map configuration is accessed via `widget.mapConfig` directly.

  // Effective find/search configuration
  FormFieldsMapFindConfig get _findConfigEffective =>
      widget.findConfig ?? const FormFieldsMapFindConfig();

  /// Whether a marker should be shown at the viewport center. Preference
  /// order: explicit `findConfig.showMarkerInCenter` -> legacy
  /// `widget.showMarkerInCenter` for backward compatibility.
  bool get _showMarkerInCenterEffective {
    final enabledByFind = widget.findConfig?.showMarkerInCenter;
    // If a feature flag is provided, only show center marker when feature
    // is explicitly `find`. Otherwise preserve legacy behavior.
    if (widget.features != null) {
      return (widget.features == FormFieldsMapFeature.find) &&
          (enabledByFind ?? widget.showMarkerInCenter);
    }
    return enabledByFind ?? widget.showMarkerInCenter;
  }

  /// Effective on-center-marker callback (from find config). May be async.
  Future<void> Function(FormFieldsLocationPrediction)?
  get _onCenterMarkerEffective => widget.findConfig?.onCenterMarker;

  // Note: onCenterChanged preference removed from findConfig; use widget value.

  /// Effective reverse geocode function (from find config).
  Future<String?> Function(LatLng)? get _reverseGeocodeEffective =>
      widget.findConfig?.reverseGeocode;

  String get _tileUrlTemplateEffective => widget.tileUrlTemplate;

  // Tile attribution and clustering flags are read directly from the
  // widget properties (`widget.tileAttribution`, `widget.mapConfig`).

  // Canvas marker / title effective values moved to mapConfig.
  double get _canvasMarkerRadiusEffective =>
      widget.mapConfig?.canvasMarkerRadius ?? 20.0;

  Object? get _canvasMarkerIconEffective => widget.mapConfig?.canvasMarkerIcon;

  bool get _showTitleEffective => widget.mapConfig?.showTitle ?? true;

  // `showLabels` removed — tile label visibility controlled by tile source.

  Duration get _playbackIntervalEffective =>
      widget.playbackConfig?.playbackInterval ?? const Duration(seconds: 1);

  int get _playbackInterpolationStepsEffective =>
      widget.playbackConfig?.playbackInterpolationSteps ?? 0;

  bool get _showBuiltinPlaybackControlsEffective =>
      widget.playbackConfig?.showBuiltinPlaybackControls ?? true;

  Color? get _playbackPolylineColor =>
      widget.playbackConfig?.playbackPolylineColor;

  Color? get _playbackHaloColor =>
      widget.playbackConfig?.playbackHaloColor ?? _playbackPolylineColor;

  double get _playbackHaloScale =>
      widget.playbackConfig?.playbackHaloScale ?? 1.6;

  double get _playbackHaloOpacity =>
      widget.playbackConfig?.playbackHaloOpacity ?? 0.95;

  bool get _playbackFollowCamera =>
      widget.playbackConfig?.playbackFollowCamera ?? true;

  double get _playbackTargetZoom {
    final t = widget.playbackConfig?.playbackZoom ?? 17.0;
    // clamp to allowed widget zoom range
    final v = t.clamp(widget.minZoom, widget.maxZoom);
    return (v as num).toDouble();
  }

  Curve get _playbackCurve =>
      widget.playbackConfig?.playbackCurve ?? Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _initializeMapState();
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
    _applyWidgetUpdate(oldWidget);
  }

  /// Bumped on every [_resolveCanvasMarkerIcon] call. Rasterization is
  /// asynchronous, so a result that arrives after a newer call started is
  /// for an icon that is no longer configured and must not replace the new one.
  int _markerIconGeneration = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _playbackTimer?.cancel();
    // Release both marker image listeners. A listener left attached keeps
    // this State alive and calls setState after dispose.
    if (_canvasMarkerImageStream != null &&
        _canvasMarkerImageStreamListener != null) {
      _canvasMarkerImageStream!.removeListener(
        _canvasMarkerImageStreamListener!,
      );
    }
    if (_playbackMarkerImageStream != null &&
        _playbackMarkerImageStreamListener != null) {
      _playbackMarkerImageStream!.removeListener(
        _playbackMarkerImageStreamListener!,
      );
    }
    // Unregister and dispose fallback notifier if created.
    try {
      final existing = FormFieldsMapController.getNotifier(_controllerId);
      if (identical(existing, _fallbackNotifier)) {
        try {
          FormFieldsMapController.removeNotifier(_controllerId);
        } catch (_) {}
        try {
          _fallbackNotifier.dispose();
        } catch (_) {}
      } else {
        // Only dispose our fallback notifier if we actually registered it.
        try {
          _fallbackNotifier.dispose();
        } catch (_) {}
      }
    } catch (_) {}
    // Notifier lifecycle is managed externally via FormFieldsMapController.
    FormFieldsMapController.removeOnMarkerTap(_controllerId);
    FormFieldsMapController.unregisterPlaybackHandler(_controllerId);
    // Notifier registration is managed by consumers via the controller
    // registry; nothing to remove here.
    // If we created the controller entry for this widget instance, remove
    // it from the registry to avoid leaking entries. Do not remove external
    // controllers supplied by the consumer.
    if (_ownsController) {
      FormFieldsMapController.remove(_controllerId);
    }
    _tileProvider.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;

  Future<void> animateTo(
    LatLng dest,
    double zoom, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
  }) async {
    try {
      await _mapController.animateCameraTo(
        dest,
        zoom,
        duration: duration,
        curve: curve,
      );
    } catch (_) {
      // fallback to instant move
      try {
        _mapController.move(dest, zoom);
      } catch (_) {}
    }
    _lastCenter = dest;
    _lastZoom = zoom;
  }

  /// Returns the current map center if available, using the internal
  /// `MapController.camera.center` when possible, otherwise falling back to
  /// the last known center or `null`.
  LatLng? getCenter() {
    try {
      return _mapController.camera.center;
    } catch (_) {
      return _lastCenter;
    }
  }

  Future<void> fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = EdgeInsets.zero,
    Duration duration = const Duration(milliseconds: 400),
  }) async {
    final center = bounds.center;

    final targetZoom = widget.initialZoom;
    await animateTo(center, targetZoom, duration: duration);
  }

  /// Single entry point for rebuilds requested from the helper extensions in
  /// `*_parts/`. Keeps the protected `setState` call inside this class.
  void _applyStateChange(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final notifier =
        FormFieldsMapController.getNotifier(_controllerId) ?? _fallbackNotifier;

    final bool useFullGeocoding =
        (widget.features == FormFieldsMapFeature.find);
    final bool localAvailable =
        useFullGeocoding && _findConfigEffective.allowGeolocation;
    Future<List<FormFieldsLocationPrediction>> Function(String)?
    localFetcherForMap = localAvailable
        ? (String q) async {
            if (q.trim().isEmpty) return [];
            try {
              final results = await _geocodingService.search(q);
              return results
                  .map(
                    (r) => FormFieldsLocationPrediction(
                      latLng: r.point,
                      address: r.address ?? '',
                    ),
                  )
                  .toList(growable: false);
            } catch (_) {
              return [];
            }
          }
        : null;

    return Stack(
      children: [
        _buildMapLayer(notifier: notifier, context: context),
        // Optional search bar overlay for find operations. Uses externally
        // provided search results when available (`findConfig.externalSearchResults`).
        if ((widget.features == null ||
                widget.features == FormFieldsMapFeature.find) &&
            _findConfigEffective.showSearchBar)
          _buildSearchBar(
            localFetcherForMap: localFetcherForMap,
            localAvailable: localAvailable,
            context: context,
          ),
        if (_showMarkerInCenterEffective) _buildCenterMarker(context: context),
        _buildPlaybackControls(context: context),
        _buildBlockingLoadingOverlay(context: context),
        _buildCameraActivityIndicator(context: context),
      ],
    );
  }
}
