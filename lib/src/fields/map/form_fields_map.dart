import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/src/fields/map/canvas_raw_marker_painter.dart';
import 'package:form_fields/src/service/geocoding_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';

const double _tapPad = 12.0;

/// Playback configuration bucket for map-based polyline playback features.
///
/// Consumers can provide an instance to centralize playback-related options
/// instead of passing multiple loose parameters to `FormFieldsMap`.
class FormFieldsMapPlaybackConfig {
  const FormFieldsMapPlaybackConfig({
    this.playbackInterval = const Duration(seconds: 1),
    this.playbackInterpolationSteps = 0,
    this.showBuiltinPlaybackControls = true,
    this.playbackPolylineColor,
    this.playbackMarkerIcon,
    this.playbackZoom = 18.0,
    this.playbackFollowCamera = true,
    this.playbackCurve = Curves.easeInOut,
    this.playbackAutoStart = false,
    this.playbackHaloColor,
    this.playbackHaloScale = 1.6,
    this.playbackHaloOpacity = 0.95,
    this.onPointReached,
  });

  final Duration playbackInterval;
  final int playbackInterpolationSteps;
  final bool showBuiltinPlaybackControls;
  final Color? playbackPolylineColor;
  final Object? playbackMarkerIcon; // Icon, Widget or ImageProvider
  /// Preferred zoom level to use when starting/following playback.
  /// This value is clamped to the widget's `minZoom`/`maxZoom` when applied.
  final double playbackZoom;
  final bool playbackFollowCamera;

  /// Whether playback should automatically start when the first set of
  /// raw markers for playback is appended. Defaults to `false`.
  final bool playbackAutoStart;

  /// The easing curve used when animating the camera for playback actions.
  /// Defaults to [Curves.easeInOut].
  final Curve playbackCurve;

  /// Optional color used for the playback icon halo/border. If null, the
  /// `playbackPolylineColor` (if set) will be used.
  final Color? playbackHaloColor;

  /// Scale multiplier applied to the rasterized icon when drawing the halo.
  /// Defaults to 1.6 (slightly larger than the icon).
  final double playbackHaloScale;

  /// Opacity applied to the halo tint (0.0 - 1.0).
  final double playbackHaloOpacity;

  /// Optional callback invoked when playback reaches a point during
  /// polyline playback. Provides the `polylineId` (may be null), the
  /// zero-based `index` into the interpolated playback points, and the
  /// `LatLng` of the reached point. Consumers can use this to show
  /// details (e.g. a bottom sheet) for the current playback location.
  final void Function(String? polylineId, int index, LatLng point)?
  onPointReached;
}

/// Configuration bucket for general map options.
///
/// This mirrors the pattern used by `FormFieldsMapPlaybackConfig` so
/// consumers can centralize map-related preferences instead of passing
/// many loose parameters to `FormFieldsMap`.
class FormFieldsMapMapConfig {
  const FormFieldsMapMapConfig({
    this.enableClustering = false,
    this.canvasMarkerRadius = 20.0,
    this.canvasMarkerIcon,
    this.showTitle = true,
  });

  /// Whether marker clustering should be enabled when rendering many markers.
  final bool enableClustering;

  /// Radius used for canvas-rendered markers (in logical pixels).
  final double canvasMarkerRadius;

  /// Optional provider/widget/icon used when rasterizing canvas markers.
  final Object? canvasMarkerIcon;

  /// Whether marker titles should be displayed by the painter.
  final bool showTitle;
}

/// Configuration bucket for "find" (search) related options.
class FormFieldsMapFindConfig {
  const FormFieldsMapFindConfig({
    this.allowGeolocation = true,
    this.findTimeout = const Duration(seconds: 10),
    this.showSearchBar = true,
    this.showMarkerInCenter = false,
    this.onCenterMarker,
    this.centerMarker,
    this.reverseGeocode,
    this.externalSearchResults,
    this.apiUrl,
    this.apiParseResults,
  });

  /// Whether the example/app may request platform geolocation when performing
  /// a find operation.
  final bool allowGeolocation;

  /// Timeout used when attempting to resolve the current location.
  final Duration findTimeout;

  /// Whether a small search bar or input should be shown for find operations.
  final bool showSearchBar;

  /// Whether a marker should be shown at the viewport center when performing
  /// find operations. Consumers can use this to indicate the target point
  /// that will be returned by `onRequestCurrentLocation` or a search result.
  final bool showMarkerInCenter;

  /// Optional widget drawn at the viewport center specifically for find
  /// operations. When provided this takes precedence over the widget-level
  /// `centerMarker` property of `FormFieldsMap`.
  final Widget? centerMarker;

  /// Callback invoked when the user confirms the center marker selection.
  /// Receives a `FormFieldsLocationPrediction` with `latLng` and `address`.
  ///
  /// NOTE: this callback may be async; when provided the widget will await
  /// the returned `Future` and will not perform its own camera animation.
  final Future<void> Function(FormFieldsLocationPrediction)? onCenterMarker;

  /// Optional reverse-geocode callback used to resolve a `LatLng` into a
  /// human-readable address when confirming the center marker.
  final Future<String?> Function(LatLng)? reverseGeocode;

  /// Optional externally-provided list of predictions/search results that
  /// can be displayed by the internal autocomplete UI. Each item should be
  /// a `FormFieldsLocationPrediction`.
  final List<FormFieldsLocationPrediction>? externalSearchResults;

  /// Optional API URL used by the internal autocomplete when performing
  /// remote searches. Defaults to Nominatim search if not provided.
  final String? apiUrl;

  /// Optional parse function to convert raw API response into a
  /// `List<FormFieldsLocationPrediction>` for the internal autocomplete.
  final List<FormFieldsLocationPrediction> Function(dynamic data)?
  apiParseResults;
}

/// Prediction structure returned by find/autocomplete interactions.
class FormFieldsLocationPrediction {
  const FormFieldsLocationPrediction({
    required this.latLng,
    required this.address,
  });

  final LatLng latLng;
  final String address;

  /// Provide map-like accessors for legacy code that expects prediction
  /// entries to be indexable (e.g. `e['lat']`). This returns the
  /// corresponding value for common keys or `null` if the key is
  /// unrecognized.
  dynamic operator [](Object? key) {
    try {
      final k = key?.toString();
      if (k == 'lat' || k == 'latitude') return latLng.latitude;
      if (k == 'lon' || k == 'lng' || k == 'longitude') return latLng.longitude;
      if (k == 'display_name' || k == 'address' || k == 'name') return address;
    } catch (_) {}
    return null;
  }

  @override
  String toString() => address;
}

/// Reusable demo dataset of external search results used by the example.
/// Contains both real-city seeds and generated synthetic entries (total ~120)
// Note: demo data is provided by the example `ViewModel` to avoid
// duplicating example-only datasets inside the package library.

/// Feature set enum for `FormFieldsMap` to describe enabled/available
/// capabilities in a clear, extensible way.
enum FormFieldsMapFeature { playback, map, find }

class FormFieldsMap extends StatefulWidget {
  // Public configuration fields (backing for the constructor parameters).
  final MapController? controller;
  final FormFieldsMapPlaybackConfig? playbackConfig;
  final FormFieldsMapMapConfig? mapConfig;
  final FormFieldsMapFindConfig? findConfig;
  final FormFieldsMapFeature? features;
  final String tileUrlTemplate;
  final String tileAttribution;
  final LatLng initialCenter;
  final double initialZoom;
  final double maxZoom;
  final double minZoom;
  final double panBuffer;
  final bool keepAlive;
  final bool showMarkerInCenter;
  const FormFieldsMap({
    super.key,
    this.controller,
    this.playbackConfig,
    this.mapConfig,
    this.findConfig,
    this.features = FormFieldsMapFeature.map,
    this.tileUrlTemplate = 'https://mt1.google.com/vt/lyrs=r&x={x}&y={y}&z={z}',
    this.tileAttribution = '© Google',
    this.initialCenter = const LatLng(0, 0),
    this.initialZoom = 13,
    this.maxZoom = 19,
    this.minZoom = 4,
    this.panBuffer = 2,
    this.keepAlive = true,
    this.showMarkerInCenter = false,
    this.centerMarker,
    this.useViewportCulling = false,
    this.cullingBuffer = 1.25,
    this.onMapReady,
    this.onCenterChanged,
    this.onPositionChanged,
    this.onMapTap,
    this.onTapShape,
    this.onLongPress,
    this.onCameraIdle,
    this.cameraIdleDebounce = const Duration(milliseconds: 350),
    this.onRequestCurrentLocation,
    this.maxRenderedRawMarkers = 10000,
    this.polygonBuilder,
    this.polylineBuilder,
    this.circleBuilder,
    this.markerBuilder,
  });

  final int maxRenderedRawMarkers;

  // Optional builder callbacks allowing consumers to customize how a
  // `ShapeMeta` is converted into a concrete layer object. Builders receive
  // the original `ShapeMeta` and the default built layer instance and may
  // return a modified or replaced instance.
  final Polygon Function(ShapeMeta meta, Polygon defaultLayer)? polygonBuilder;
  final Polyline Function(ShapeMeta meta, Polyline defaultLayer)?
  polylineBuilder;
  final CircleMarker Function(ShapeMeta meta, CircleMarker defaultLayer)?
  circleBuilder;
  final Marker Function(ShapeMeta meta, Marker defaultLayer)? markerBuilder;

  /// Optional widget drawn at the viewport center when `showMarkerInCenter`
  /// is true. If null, a default pin icon is used.
  final Widget? centerMarker;

  final bool useViewportCulling;

  final double cullingBuffer;

  final ValueChanged<ShapeMeta>? onTapShape;

  final VoidCallback? onMapReady;
  final ValueChanged<LatLng>? onCenterChanged;
  final ValueChanged<dynamic>? onPositionChanged;
  final ValueChanged<LatLng>? onMapTap;
  final ValueChanged<LatLng>? onLongPress;
  final VoidCallback? onCameraIdle;
  final Duration cameraIdleDebounce;

  final Future<LatLng>? Function()? onRequestCurrentLocation;

  /// Interval between playback steps. Defaults to 1 second.
  // Playback configuration is centralized in `FormFieldsMapPlaybackConfig`.

  @override
  FormFieldsMapState createState() => FormFieldsMapState();
}

class FormFieldsMapState extends State<FormFieldsMap>
    with AutomaticKeepAliveClientMixin<FormFieldsMap> {
  late final MapController _mapController;
  late final GeocodingService _geocodingService;
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
    // Determine controller ownership and registry id. If a MapController
    // was provided by the consumer, register it under a stable id derived
    // from its hashCode so it is discoverable via the registry. Otherwise
    // create or reuse a controller in the registry using a generated id.
    if (widget.controller != null) {
      _mapController = widget.controller!;
      _controllerId = 'ff_controller_${widget.controller.hashCode}';
      FormFieldsMapController.registerController(_controllerId, _mapController);
      _ownsController = false;
    } else {
      _controllerId =
          'ff_internal_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';
      _mapController = FormFieldsMapController.getOrCreate(_controllerId);
      _ownsController = true;
    }

    _fallbackNotifier = FormFieldsMapNotifier();

    // Shared geocoding service instance for reverse/search operations.
    _geocodingService = GeocodingService();

    // Register the internal fallback notifier only when no notifier has been
    // previously registered for this controller id. This prevents the widget
    // from overwriting a notifier that a consumer (or example) already
    // registered before the widget was built.
    try {
      final existing = FormFieldsMapController.getNotifier(_controllerId);
      try {
        debugPrint(
          '[FormFieldsMap] initState controllerId=$_controllerId existingNotifier=${existing?.hashCode} fallback=${_fallbackNotifier.hashCode}',
        );
      } catch (_) {}
      if (existing == null) {
        FormFieldsMapController.registerNotifier(
          _controllerId,
          _fallbackNotifier,
        );
      }
    } catch (_) {}

    // Notifier lifecycle is managed externally via FormFieldsMapController.
    // The widget no longer accepts a `notifier` parameter.
    _resolveCanvasMarkerIcon();
    _playbackInterval = _playbackIntervalEffective;
    _playbackInterpolationSteps = _playbackInterpolationStepsEffective;
    _playbackSubstepInterval = _computeSubstepInterval(
      _playbackInterval,
      _playbackInterpolationSteps,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(widget.initialCenter, widget.initialZoom);
      } catch (_) {}
      widget.onMapReady?.call();
      // Ensure the widget rebuilds after the controller move so tile layers
      // begin fetching immediately instead of waiting for an interaction.
      try {
        _safeSetState(() {});
      } catch (_) {}
    });

    FormFieldsMapController.registerOnMarkerTap(
      _controllerId,
      widget.onTapShape,
    );

    // Register playback handler so external callers can control playback via
    // `FormFieldsMapController`.
    if (_playbackEnabled) {
      FormFieldsMapController.registerPlaybackHandler(
        _controllerId,
        FormFieldsMapPlaybackHandler(
          start: (polylineId) => _startPolylinePlayback(polylineId),
          pause: () => _pausePolylinePlayback(),
          restart: () => _restartPolylinePlayback(),
          setInterval: (d) => _setPolylinePlaybackInterval(d),
          setInterpolationSteps: (s) => _setPlaybackInterpolationSteps(s),
          toggle: (polylineId) => _togglePolylinePlayback(polylineId),
          stepForward: (polylineId) => _stepPlaybackForward(polylineId),
          stepBackward: (polylineId) => _stepPlaybackBackward(polylineId),
        ),
      );
      // Configure whether this widget wants auto-start on first append.
      try {
        FormFieldsMapController.setPlaybackAutoStart(
          _controllerId,
          widget.playbackConfig?.playbackAutoStart ?? false,
        );
      } catch (_) {}
    }
  }

  List<LatLng> _buildInterpolatedPoints(List<LatLng> pts, int steps) {
    if (pts.length < 2 || steps <= 0) return List<LatLng>.from(pts);
    final out = <LatLng>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      out.add(a);
      for (var s = 1; s <= steps; s++) {
        final t = s / (steps + 1);
        final lat = a.latitude + (b.latitude - a.latitude) * t;
        final lon = a.longitude + (b.longitude - a.longitude) * t;
        out.add(LatLng(lat, lon));
      }
    }
    out.add(pts.last);
    return out;
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
    if (oldWidget.mapConfig?.canvasMarkerIcon !=
        widget.mapConfig?.canvasMarkerIcon) {
      _resolveCanvasMarkerIcon();
    }
    // If playback-specific icon changes, ensure we re-rasterize images.
    if (oldWidget.playbackConfig?.playbackMarkerIcon !=
        widget.playbackConfig?.playbackMarkerIcon) {
      _resolveCanvasMarkerIcon();
    }

    // Notifier removed from widget API; notifier lifecycle is no-op here.

    final oldId = _controllerId;
    // If the consumer provided a different controller instance, switch to
    // a new registry id and update registrations accordingly.
    if (oldWidget.controller != widget.controller) {
      // Unregister handlers from the old id
      FormFieldsMapController.removeOnMarkerTap(oldId);
      FormFieldsMapController.unregisterPlaybackHandler(oldId);

      if (widget.controller != null) {
        _mapController = widget.controller!;
        _controllerId = 'ff_controller_${widget.controller.hashCode}';
        FormFieldsMapController.registerController(
          _controllerId,
          _mapController,
        );
        _ownsController = false;
      } else {
        _controllerId =
            'ff_internal_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';
        _mapController = FormFieldsMapController.getOrCreate(_controllerId);
        _ownsController = true;
      }
      // Register new handlers below
      // Ensure the fallback notifier is moved from the old id to the new id
      // so controller-based mutations continue to update this widget.
      try {
        final existingOld = FormFieldsMapController.getNotifier(oldId);
        if (identical(existingOld, _fallbackNotifier)) {
          FormFieldsMapController.removeNotifier(oldId);
        }
      } catch (_) {}
      try {
        final existing = FormFieldsMapController.getNotifier(_controllerId);
        try {
          debugPrint(
            '[FormFieldsMap] didUpdateWidget moved controller oldId=$oldId newId=$_controllerId existingNotifier=${existing?.hashCode} fallback=${_fallbackNotifier.hashCode}',
          );
        } catch (_) {}
        if (existing == null) {
          FormFieldsMapController.registerNotifier(
            _controllerId,
            _fallbackNotifier,
          );
        }
      } catch (_) {}
    }

    if (oldWidget.onTapShape != widget.onTapShape || oldId != _controllerId) {
      FormFieldsMapController.removeOnMarkerTap(oldId);
      FormFieldsMapController.registerOnMarkerTap(
        _controllerId,
        widget.onTapShape,
      );
      // Move playback handler registration when controller id changes.
      FormFieldsMapController.unregisterPlaybackHandler(oldId);
      if (_playbackEnabled) {
        FormFieldsMapController.registerPlaybackHandler(
          _controllerId,
          FormFieldsMapPlaybackHandler(
            start: (polylineId) => _startPolylinePlayback(polylineId),
            pause: () => _pausePolylinePlayback(),
            restart: () => _restartPolylinePlayback(),
            setInterval: (d) => _setPolylinePlaybackInterval(d),
            setInterpolationSteps: (s) => _setPlaybackInterpolationSteps(s),
            toggle: (polylineId) => _togglePolylinePlayback(polylineId),
            stepForward: (polylineId) => _stepPlaybackForward(polylineId),
            stepBackward: (polylineId) => _stepPlaybackBackward(polylineId),
          ),
        );
        try {
          FormFieldsMapController.setPlaybackAutoStart(
            _controllerId,
            widget.playbackConfig?.playbackAutoStart ?? false,
          );
        } catch (_) {}
      }
    }

    // Handle changes to playback configuration (widget-level or via playbackConfig)
    final oldInterval =
        oldWidget.playbackConfig?.playbackInterval ??
        const Duration(seconds: 1);
    final newInterval =
        widget.playbackConfig?.playbackInterval ?? const Duration(seconds: 1);
    final oldSteps = oldWidget.playbackConfig?.playbackInterpolationSteps ?? 0;
    final newSteps = widget.playbackConfig?.playbackInterpolationSteps ?? 0;
    if (oldInterval != newInterval || oldSteps != newSteps) {
      _playbackInterval = newInterval;
      _playbackInterpolationSteps = newSteps;
      _playbackSubstepInterval = _computeSubstepInterval(
        _playbackInterval,
        _playbackInterpolationSteps,
      );
      if (_isPlaying) {
        _playbackTimer?.cancel();
        _playbackTimer = Timer.periodic(
          _playbackSubstepInterval,
          (_) => _advancePlaybackStep(),
        );
      }
      // rebuild points if playing
      if (_playbackPolylineId != null) {
        final notifier =
            FormFieldsMapController.getNotifier(_controllerId) ??
            _fallbackNotifier;
        final pl = notifier.polylineMap[_playbackPolylineId];
        if (pl != null) {
          _playbackPoints = _buildInterpolatedPoints(
            pl.points,
            _playbackInterpolationSteps,
          );
        }
      }
    }
  }

  void _resolveCanvasMarkerIcon() {
    // Clean up any existing image streams/listeners for both images.
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
    if (_playbackMarkerImageStream != null &&
        _playbackMarkerImageStreamListener != null) {
      _playbackMarkerImageStream!.removeListener(
        _playbackMarkerImageStreamListener!,
      );
    }
    _canvasMarkerImageStream = null;
    _canvasMarkerImageStreamListener = null;
    _playbackMarkerImageStream = null;
    _playbackMarkerImageStreamListener = null;
    _canvasMarkerImage = null;
    _playbackMarkerImage = null;

    final canvasProvider = _canvasMarkerIconEffective;
    final playbackProvider = widget.playbackConfig?.playbackMarkerIcon;

    // Helper to resolve an ImageProvider into an ImageStream and set target
    void attachImageProvider(
      ImageProvider provider,
      void Function(ui.Image) onImage, {
      required bool isPlayback,
    }) {
      final config = createLocalImageConfiguration(context);
      final stream = provider.resolve(config);
      final listener = ImageStreamListener((ImageInfo info, bool _) {
        onImage(info.image);
        _safeSetState(() {});
      });
      stream.addListener(listener);
      if (isPlayback) {
        _playbackMarkerImageStream = stream;
        _playbackMarkerImageStreamListener = listener;
      } else {
        _canvasMarkerImageStream = stream;
        _canvasMarkerImageStreamListener = listener;
      }
    }

    // Rasterize canvas provider if present
    if (canvasProvider != null) {
      if (canvasProvider is ImageProvider) {
        attachImageProvider(canvasProvider, (img) {
          _canvasMarkerImage = img;
          // If playback provider equals canvas provider, mirror image
          if (playbackProvider == canvasProvider) _playbackMarkerImage = img;
        }, isPlayback: false);
      } else if (canvasProvider is Icon) {
        _renderIconToImage(canvasProvider).then((img) {
          _canvasMarkerImage = img;
          if (playbackProvider == canvasProvider) _playbackMarkerImage = img;
          _safeSetState(() {});
        });
      } else if (canvasProvider is Widget) {
        _rasterizeWidgetToImage(canvasProvider).then((img) {
          if (img != null) {
            _canvasMarkerImage = img;
            if (playbackProvider == canvasProvider) _playbackMarkerImage = img;
            _safeSetState(() {});
          }
        });
      }
    }

    // Rasterize playback provider if present and different from canvas provider
    if (playbackProvider != null && playbackProvider != canvasProvider) {
      if (playbackProvider is ImageProvider) {
        attachImageProvider(playbackProvider, (img) {
          _playbackMarkerImage = img;
        }, isPlayback: true);
      } else if (playbackProvider is Icon) {
        _renderIconToImage(playbackProvider).then((img) {
          _playbackMarkerImage = img;
          _safeSetState(() {});
        });
      } else if (playbackProvider is Widget) {
        _rasterizeWidgetToImage(playbackProvider).then((img) {
          if (img != null) {
            _playbackMarkerImage = img;
            _safeSetState(() {});
          }
        });
      }
    }
  }

  Future<ui.Image> _renderIconToImage(Icon icon) async {
    final iconData = icon.icon;
    final double size = icon.size ?? 24.0;
    final Color color = icon.color ?? Colors.black;

    if (iconData == null) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = color;
      final double r = size / 2.0;
      canvas.drawCircle(Offset(r, r), r, paint);
      final picture = recorder.endRecording();
      return picture.toImage(size.ceil(), size.ceil());
    }

    final textStyle = TextStyle(
      fontFamily: iconData.fontFamily,
      package: iconData.fontPackage,
      fontSize: size,
      color: color,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final w = tp.width.ceil();
    final h = tp.height.ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );
    tp.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w == 0 ? 1 : w, h == 0 ? 1 : h);
    return image;
  }

  Future<ui.Image?> _rasterizeWidgetToImage(
    Widget widget, {
    double logicalSize = 36.0,
  }) async {
    try {
      if (!mounted) return null;

      final overlay = Overlay.of(context);

      final key = GlobalKey();
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final entry = OverlayEntry(
        builder: (ctx) => Positioned(
          left: 0,
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: logicalSize,
                height: logicalSize,
                child: RepaintBoundary(
                  key: key,
                  child: Center(child: widget),
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);

      await Future.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        entry.remove();
        return null;
      }

      final contextForKey = key.currentContext;
      if (contextForKey == null) {
        entry.remove();
        return null;
      }

      if (contextForKey is! Element || !contextForKey.mounted) {
        entry.remove();
        return null;
      }

      final renderObject = contextForKey.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        final img = await renderObject.toImage(pixelRatio: devicePixelRatio);
        entry.remove();
        return img;
      }
      entry.remove();
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _playbackTimer?.cancel();
    if (_canvasMarkerImageStream != null &&
        _canvasMarkerImageStreamListener != null) {
      _canvasMarkerImageStream!.removeListener(
        _canvasMarkerImageStreamListener!,
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
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;

  void _onPositionChanged(dynamic position, bool hasGesture) {
    widget.onPositionChanged?.call(position);

    try {
      final dynamic pos = position; // Ensure position is dynamic
      if (pos != null) {
        if (pos.center != null) {
          _lastCenter = pos.center as LatLng;
        }
        if (pos.zoom != null) {
          _lastZoom = (pos.zoom as num).toDouble();
        }
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              FormFieldsMapController.setLoading(_controllerId, true);
            } catch (_) {}
            _safeSetState(() {});
          });
        }

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              FormFieldsMapController.setLoading(_controllerId, true);
            } catch (_) {}
            _safeSetState(() {});
          });
        }
      }
    } catch (_) {}

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.cameraIdleDebounce, () {
      FormFieldsMapController.setLoading(_controllerId, false);
      // During playback, do not notify center changes to consumers.
      widget.onCenterChanged?.call(_lastCenter!);
      // Only notify center after camera becomes idle so consumers get the
      // final/last center rather than a rapid stream of intermediate values.
      try {
        // Call the callbacks in a post-frame callback so user-provided
        // handlers can safely call setState() without triggering the
        // "setState() or markNeedsBuild() called during build" exception.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (_lastCenter != null) widget.onCenterChanged?.call(_lastCenter!);
          } catch (_) {}
          try {
            widget.onCameraIdle?.call();
          } catch (_) {}
        });
        // The center-marker confirmation should only be triggered explicitly
        // via the confirmation button (see the check `AppButton` below).
        // Do not automatically invoke `onCenterMarker` when the camera
        // becomes idle after panning/zooming.
      } catch (_) {}
    });
  }

  void _setPolylinePlaybackInterval(Duration interval) {
    _playbackInterval = interval;
    _playbackSubstepInterval = _computeSubstepInterval(
      _playbackInterval,
      _playbackInterpolationSteps,
    );
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
        _playbackSubstepInterval,
        (_) => _advancePlaybackStep(),
      );
    }
  }

  // Allow runtime update of interpolation steps
  void _setPlaybackInterpolationSteps(int steps) {
    _playbackInterpolationSteps = steps.clamp(0, 1000);
    _playbackSubstepInterval = _computeSubstepInterval(
      _playbackInterval,
      _playbackInterpolationSteps,
    );
    // rebuild playback list if currently playing
    if (_playbackPolylineId != null) {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      final pl = notifier.polylineMap[_playbackPolylineId];
      if (pl != null) {
        final currentPoint =
            _playbackPoints.isNotEmpty &&
                _playbackIndex < _playbackPoints.length
            ? _playbackPoints[_playbackIndex]
            : null;
        _playbackPoints = _buildInterpolatedPoints(
          pl.points,
          _playbackInterpolationSteps,
        );
        // re-find closest index to currentPoint
        if (currentPoint != null) {
          var best = 0;
          var bestDist = double.infinity;
          for (var i = 0; i < _playbackPoints.length; i++) {
            final d =
                pow((_playbackPoints[i].latitude - currentPoint.latitude), 2) +
                pow((_playbackPoints[i].longitude - currentPoint.longitude), 2);
            if (d < bestDist) {
              bestDist = d as double;
              best = i;
            }
          }
          _playbackIndex = best;
        }
      }
    }
  }

  void _togglePolylinePlayback(String? polylineId) {
    if (_isPlaying) {
      _pausePolylinePlayback();
    } else {
      _startPolylinePlayback(polylineId);
    }
  }

  Duration _computeSubstepInterval(Duration perPoint, int steps) {
    final div = (steps <= 0) ? 1 : (steps + 1);
    final ms = (perPoint.inMilliseconds / div).round();
    return Duration(milliseconds: max(1, ms));
  }

  void _startPolylinePlayback(String? polylineId) {
    try {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      String? id =
          polylineId ??
          (notifier.polylineMap.isNotEmpty
              ? notifier.polylineMap.keys.first
              : null);
      if (id == null) return;
      final pl = notifier.polylineMap[id];
      if (pl == null || pl.points.isEmpty) return;
      // If we're starting the same polyline that was previously playing and
      // there are existing playback points, treat this as a resume rather
      // than always restarting from the beginning. If the playback had
      // already reached the end, fall through and restart from zero.
      if (_playbackPolylineId == id && _playbackPoints.isNotEmpty) {
        if (_playbackIndex < _playbackPoints.length - 1) {
          _isPlaying = true;
          // ensure external listeners are notified when resuming playback
          try {
            FormFieldsMapController.setPlaybackPlaying(_controllerId, true);
          } catch (_) {}
          _safeSetState(() {});
          _playbackTimer?.cancel();
          _playbackTimer = Timer.periodic(
            _playbackSubstepInterval,
            (_) => _advancePlaybackStep(),
          );
          return;
        } else {
          // at end -> restart from beginning
          _playbackIndex = 0;
        }
      }

      // New polyline (or restarting finished one): build points and start
      _playbackPolylineId = id;
      _playbackPoints = _buildInterpolatedPoints(
        pl.points,
        _playbackInterpolationSteps,
      );
      _playbackIndex = 0;
      _isPlaying = true;
      // publish authoritative playing state
      try {
        FormFieldsMapController.setPlaybackPlaying(_controllerId, true);
      } catch (_) {}
      _safeSetState(() {});
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
        _playbackSubstepInterval,
        (_) => _advancePlaybackStep(),
      );
      // Zoom to level 17 (clamped to allowed min/max) when starting playback
      try {
        final initialPoint = _playbackPoints.isNotEmpty
            ? _playbackPoints[_playbackIndex]
            : null;
        if (initialPoint != null) {
          if (_playbackFollowCamera) {
            // animateTo is async but we don't need to await inside timer callbacks
            animateTo(initialPoint, _playbackTargetZoom, curve: _playbackCurve);
          }
        }
      } catch (_) {}
      _updatePlaybackMarker();
    } catch (_) {}
  }

  void _pausePolylinePlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
    } catch (_) {}
    _safeSetState(() {});
  }

  void _restartPolylinePlayback() {
    // If no playback polyline is currently selected, attempt to pick the
    // first available polyline from the notifier so external callers can
    // reliably restart immediately after generating a polyline.
    final notifier =
        FormFieldsMapController.getNotifier(_controllerId) ?? _fallbackNotifier;
    if (_playbackPolylineId == null) {
      if (notifier.polylineMap.isEmpty) return;
      _playbackPolylineId = notifier.polylineMap.keys.first;
      final pl = notifier.polylineMap[_playbackPolylineId];
      if (pl != null) {
        _playbackPoints = _buildInterpolatedPoints(
          pl.points,
          _playbackInterpolationSteps,
        );
      }
    }

    // If still no points, nothing to restart.
    if (_playbackPoints.isEmpty) return;

    _playbackIndex = 0;
    _isPlaying = true;
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, true);
    } catch (_) {}
    _safeSetState(() {});
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      _playbackSubstepInterval,
      (_) => _advancePlaybackStep(),
    );
    _updatePlaybackMarker();
  }

  void _advancePlaybackStep() {
    if (!_isPlaying) return;
    if (_playbackPoints.isEmpty) return;
    if (_playbackIndex < _playbackPoints.length - 1) {
      _playbackIndex++;
    } else {
      // stop at end
      _isPlaying = false;
      _playbackTimer?.cancel();
      try {
        FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
      } catch (_) {}
    }
    _updatePlaybackMarker();
  }

  void _stepPlaybackForward(String? polylineId) {
    if (_playbackPoints.isEmpty) return;
    if (_playbackIndex < _playbackPoints.length - 1) {
      _playbackIndex++;
    }
    // stop any running playback when user steps manually
    _isPlaying = false;
    _playbackTimer?.cancel();
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
    } catch (_) {}
    _updatePlaybackMarker();
    try {
      if (_playbackFollowCamera) {
        final p = _playbackPoints[_playbackIndex];
        animateTo(p, _playbackTargetZoom, curve: _playbackCurve);
      }
    } catch (_) {}
  }

  void _stepPlaybackBackward(String? polylineId) {
    if (_playbackPoints.isEmpty) return;
    if (_playbackIndex > 0) {
      _playbackIndex--;
    }
    _isPlaying = false;
    _playbackTimer?.cancel();
    try {
      FormFieldsMapController.setPlaybackPlaying(_controllerId, false);
    } catch (_) {}
    _updatePlaybackMarker();
    try {
      if (_playbackFollowCamera) {
        final p = _playbackPoints[_playbackIndex];
        animateTo(p, _playbackTargetZoom, curve: _playbackCurve);
      }
    } catch (_) {}
  }

  void _updatePlaybackMarker() {
    try {
      if (!mounted) return;
      if (_playbackPoints.isEmpty) return;
      final p = _playbackPoints[_playbackIndex];
      // compute bearing for rotation (degrees)
      double bearing = 0.0;
      try {
        if (_playbackPoints.length > 1) {
          LatLng from;
          if (_playbackIndex > 0) {
            from = _playbackPoints[_playbackIndex - 1];
          } else {
            from =
                _playbackPoints[(_playbackIndex + 1).clamp(
                  0,
                  _playbackPoints.length - 1,
                )];
          }
          final lat1 = from.latitude * pi / 180.0;
          final lat2 = p.latitude * pi / 180.0;
          final dLon = (p.longitude - from.longitude) * pi / 180.0;
          final y = sin(dLon) * cos(lat2);
          final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
          var brng = atan2(y, x) * 180.0 / pi;
          brng = (brng + 360.0) % 360.0;
          bearing = brng;
        }
      } catch (_) {}

      final payload = <String, dynamic>{
        'id': 'playback_marker',
        'shapeType': ShapeTypes.marker,
        'lat': p.latitude,
        'lon': p.longitude,
        'rotation': bearing,
        'title': null,
      };
      // Determine the effective provider used for canvas marker rasterization
      // (prefer the explicit `canvasMarkerIcon`, otherwise allow a playback
      // specific `playbackMarkerIcon` from the playback config). If no
      // provider is available, fall back to the default arrow glyph. Leaving
      // 'icon' unset allows the painter to draw the rasterized `iconImage`
      // when present.
      final effectiveProviderForPlayback =
          widget.playbackConfig?.playbackMarkerIcon ??
          _canvasMarkerIconEffective;
      if (effectiveProviderForPlayback == null) {
        payload['icon'] = 'arrow';
      }
      // Allow playback config to override the marker/polyline color for
      // playback-specific visuals.
      if (_playbackPolylineColor != null) {
        payload['color'] = _playbackPolylineColor;
      }
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      // Use controller API to mutate notifier so only controller is the
      // canonical mutator for map state. Use remove+append so we don't
      // replace the entire `rawMarkers` list (which would clear
      // derived polylines/polygons). This keeps playback marker updates
      // isolated and preserves existing shape layers.
      try {
        try {
          FormFieldsMapController.removeRawMarker(
            _controllerId,
            'playback_marker',
          );
        } catch (_) {}
        try {
          FormFieldsMapController.appendRawMarkers(_controllerId, [payload]);
        } catch (_) {
          // fallback to setRawMarkers if append isn't available for some reason
          FormFieldsMapController.setRawMarkers(_controllerId, [payload]);
        }
      } catch (_) {
        // fallback to direct notifier mutation if registry isn't available
        try {
          // replace any existing playback_marker in notifier.rawMarkers
          notifier.rawMarkers.removeWhere(
            (r) =>
                (r is Map && r['id'] == 'playback_marker') ||
                (r is ShapeMeta && r.id == 'playback_marker'),
          );
        } catch (_) {}
        try {
          notifier.appendRawMarkers([payload]);
        } catch (_) {
          notifier.rawMarkers = [payload];
        }
      }
      // If playback is active, move camera to follow the playback point
      try {
        if (_isPlaying && _playbackFollowCamera) {
          animateTo(p, _playbackTargetZoom, curve: _playbackCurve);
        }
      } catch (_) {}
      // Notify consumers when a playback point is reached so they can
      // react (e.g. show a bottom sheet with history details).
      try {
        widget.playbackConfig?.onPointReached?.call(
          _playbackPolylineId,
          _playbackIndex,
          p,
        );
      } catch (_) {}
    } catch (_) {}
  }

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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tileProvider = NetworkTileProvider();

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
        ChangeNotifierProvider<FormFieldsMapNotifier>.value(
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
                tileProvider: tileProvider,
                maxZoom: widget.maxZoom,
                minZoom: widget.minZoom,
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
                  for (final r in notifierLocal.rawMarkers) {
                    if (r is ShapeMeta && r.shapeType == ShapeTypes.polygon) {
                      final pms = r.pointMetas;
                      if (pms == null || pms.isEmpty) continue;
                      final pts = pms
                          .map((pm) => pm.point)
                          .toList(growable: false);
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
                  for (final r in notifierLocal.rawMarkers) {
                    if (r is ShapeMeta && r.shapeType == ShapeTypes.polyline) {
                      final pms = r.pointMetas;
                      if (pms == null || pms.isEmpty) continue;
                      final pts = pms
                          .map((pm) => pm.point)
                          .toList(growable: false);
                      final parsed = r.color;
                      final opts = r.polylineOptions();
                      final defaultPl = Polyline(
                        points: pts,
                        strokeWidth: opts.strokeWidth ?? 2.0,
                        color: opts.color ?? parsed ?? themeColor,
                        useStrokeWidthInMeter:
                            opts.useStrokeWidthInMeter ?? true,
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
                  for (final r in notifierLocal.rawMarkers) {
                    if (r is ShapeMeta && r.shapeType == ShapeTypes.circle) {
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
                  for (final r in notifierLocal.rawMarkers) {
                    if (r is ShapeMeta && r.shapeType == ShapeTypes.marker) {
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
                  return MarkerLayer(markers: [...mapped, ...extraMarkers]);
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable:
                    FormFieldsMapController.getBlockingLoadingListenable(
                      _controllerId,
                    ),
                builder: (context, isBlocking, _) {
                  return Selector<FormFieldsMapNotifier, List<dynamic>>(
                    selector: (_, n) => n.rawMarkers,
                    builder: (context, rawMarkers, _) {
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
                              defaultColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
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
        ),
        // Optional search bar overlay for find operations. Uses externally
        // provided search results when available (`findConfig.externalSearchResults`).
        if ((widget.features == null ||
                widget.features == FormFieldsMapFeature.find) &&
            _findConfigEffective.showSearchBar)
          Positioned(
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
                                final display =
                                    e['display_name']?.toString() ?? '';
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
                                final display =
                                    e['display_name']?.toString() ?? '';
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
                          await _onCenterMarkerEffective!(pred);
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
                            FormFieldsMapController.setLoading(
                              _controllerId,
                              false,
                            );
                          } catch (_) {}
                        });
                      } catch (_) {
                        try {
                          FormFieldsMapController.setLoading(
                            _controllerId,
                            false,
                          );
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
          ),
        if (_showMarkerInCenterEffective)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Builder(
                  builder: (ctx) {
                    // Priority: `findConfig.centerMarker` -> explicit
                    // `widget.centerMarker` -> rasterized `_canvasMarkerImage`
                    // -> provided `canvasMarkerIcon` -> default icon.
                    final centerWidget =
                        _findConfigEffective.centerMarker ??
                        widget.centerMarker;
                    if (centerWidget != null) return centerWidget;
                    if (_canvasMarkerImage != null) {
                      return RawImage(
                        image: _canvasMarkerImage,
                        width: _canvasMarkerRadiusEffective * 2,
                        height: _canvasMarkerRadiusEffective * 2,
                        fit: BoxFit.contain,
                      );
                    }
                    final provider = _canvasMarkerIconEffective;
                    if (provider is Widget) return provider;
                    if (provider is Icon) return provider;
                    if (provider is ImageProvider) {
                      return Image(
                        image: provider,
                        width: _canvasMarkerRadiusEffective * 2,
                        height: _canvasMarkerRadiusEffective * 2,
                        fit: BoxFit.contain,
                      );
                    }
                    return Icon(
                      Icons.location_pin,
                      color: Theme.of(context).colorScheme.onSecondary,
                      size: 36,
                    );
                  },
                ),
              ),
            ),
          ),
        Positioned(
          right: 10,
          top: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_playbackEnabled) ...[
                // Card(
                //   elevation: 2,
                //   child: Padding(
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 8.0, vertical: 6.0),
                //     child: Text(
                //       'Zoom: ${(_lastZoom ?? widget.initialZoom).toStringAsFixed(1)}',
                //       style: const TextStyle(fontSize: 12),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 8),
                AppButton(
                  type: AppButtonType.fab,
                  size: AppSize.small,
                  icon: const Icon(Icons.add),
                  useSafeArea: false,
                  heroTag: null,
                  onPressed: () {
                    final center = _lastCenter ?? widget.initialCenter;
                    final currentZoom = _lastZoom ?? widget.initialZoom;
                    final newZoom = (currentZoom + 1).clamp(
                      widget.minZoom,
                      widget.maxZoom,
                    );
                    animateTo(center, newZoom);
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  type: AppButtonType.fab,
                  size: AppSize.small,
                  isLoading: _centerActionInProgress,
                  icon: const Icon(Icons.my_location),
                  useSafeArea: false,
                  heroTag: null,
                  onPressed: () async {
                    if (_centerActionInProgress) return;
                    setState(() {
                      _centerActionInProgress = true;
                    });
                    try {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      LatLng? target;
                      try {
                        if (!_findConfigEffective.allowGeolocation) {
                          messenger?.showSnackBar(
                            const SnackBar(
                              content: Text('Location access disabled'),
                            ),
                          );
                        } else if (widget.onRequestCurrentLocation != null) {
                          try {
                            final Future<LatLng>? fut = widget
                                .onRequestCurrentLocation!
                                .call();
                            if (fut != null) {
                              try {
                                target = await fut.timeout(
                                  _findConfigEffective.findTimeout,
                                );
                              } on TimeoutException {
                                target = null;
                              } catch (_) {
                                target = null;
                              }
                            }
                          } catch (_) {
                            target = null;
                          }
                        } else {
                          // No callback provided yet — fall back to current map
                          // center (if available) or the widget's initial center.
                          target = _lastCenter ?? widget.initialCenter;
                        }
                      } catch (_) {
                        target = null;
                      }

                      if (!mounted) return;
                      if (target != null) {
                        final currentZoom = _lastZoom ?? widget.initialZoom;
                        // Prefer a playback-style zoom when a playback config is
                        // present and the widget is configured to follow camera.
                        final zoom = (widget.playbackConfig != null)
                            ? _playbackTargetZoom
                            : currentZoom;
                        await animateTo(target, zoom);

                        // After moving to the location, perform reverse-geocode
                        // and notify consumer via `onCenterMarker` if provided.
                        try {
                          String address = '';
                          PointMeta? pm;
                          String? cbAddress;
                          if (_reverseGeocodeEffective != null) {
                            try {
                              cbAddress = await _reverseGeocodeEffective!(
                                target,
                              );
                            } catch (_) {
                              cbAddress = null;
                            }
                          }

                          if (cbAddress != null && cbAddress.isNotEmpty) {
                            address = cbAddress;
                            pm = PointMeta(
                              lat: target.latitude,
                              lon: target.longitude,
                              address: address,
                            );
                          } else if (_findConfigEffective.allowGeolocation) {
                            pm = await _geocodingService.reverseToPointMeta(
                              target,
                            );
                            address = pm?.address ?? '';
                          } else {
                            // GeocodingService disabled by configuration; leave address empty
                            address = '';
                            pm = null;
                          }

                          if (_onCenterMarkerEffective != null) {
                            await _onCenterMarkerEffective!(
                              FormFieldsLocationPrediction(
                                latLng: pm?.point ?? target,
                                address: address,
                              ),
                            );
                          }
                        } catch (_) {}

                        return;
                      }

                      messenger?.showSnackBar(
                        const SnackBar(
                          content: Text('Current location not available'),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _centerActionInProgress = false;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (_showMarkerInCenterEffective)
                  AppButton(
                    type: AppButtonType.fab,
                    size: AppSize.small,
                    isLoading: _centerActionInProgress,
                    icon: const Icon(Icons.check),
                    useSafeArea: false,
                    heroTag: null,
                    onPressed: () async {
                      if (_centerActionInProgress) return;
                      setState(() {
                        _centerActionInProgress = true;
                      });
                      final center = _lastCenter ?? widget.initialCenter;
                      String address = '';
                      PointMeta? pm;
                      try {
                        String? cbAddress;
                        if (_reverseGeocodeEffective != null) {
                          try {
                            cbAddress = await _reverseGeocodeEffective!(center);
                          } catch (_) {
                            cbAddress = null;
                          }
                        }

                        if (cbAddress != null && cbAddress.isNotEmpty) {
                          address = cbAddress;
                          pm = PointMeta(
                            lat: center.latitude,
                            lon: center.longitude,
                            address: address,
                          );
                        } else if (_findConfigEffective.allowGeolocation) {
                          pm = await _geocodingService.reverseToPointMeta(
                            center,
                          );
                          address = pm?.address ?? '';
                        } else {
                          address = '';
                          pm = null;
                        }
                      } catch (_) {
                        address = '';
                      }
                      try {
                        if (_onCenterMarkerEffective != null) {
                          await _onCenterMarkerEffective!(
                            FormFieldsLocationPrediction(
                              latLng: pm?.point ?? center,
                              address: address,
                            ),
                          );
                        }
                      } catch (_) {
                      } finally {
                        if (mounted) {
                          setState(() {
                            _centerActionInProgress = false;
                          });
                        }
                      }
                    },
                  ),
                const SizedBox(height: 8),
                AppButton(
                  type: AppButtonType.fab,
                  size: AppSize.small,
                  icon: const Icon(Icons.remove),
                  useSafeArea: false,
                  heroTag: null,
                  onPressed: () {
                    final center = _lastCenter ?? widget.initialCenter;
                    final currentZoom = _lastZoom ?? widget.initialZoom;
                    final newZoom = (currentZoom - 1).clamp(
                      widget.minZoom,
                      widget.maxZoom,
                    );
                    animateTo(center, newZoom);
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (_playbackEnabled &&
                  _showBuiltinPlaybackControlsEffective) ...[
                AppButton(
                  type: AppButtonType.fab,
                  size: AppSize.small,
                  icon: const Icon(Icons.skip_previous),
                  useSafeArea: false,
                  heroTag: null,
                  onPressed: () => _stepPlaybackBackward(null),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable:
                      FormFieldsMapController.getPlaybackPlayingListenable(
                        _controllerId,
                      ),
                  builder: (context, playing, _) {
                    return AppButton(
                      type: AppButtonType.fab,
                      size: AppSize.small,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      useSafeArea: false,
                      heroTag: null,
                      onPressed: () => _togglePolylinePlayback(null),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  type: AppButtonType.fab,
                  size: AppSize.small,
                  icon: const Icon(Icons.skip_next),
                  useSafeArea: false,
                  heroTag: null,
                  onPressed: () => _stepPlaybackForward(null),
                ),
                const SizedBox(height: 8),
                AppButton(
                  type: AppButtonType.fab,
                  size: AppSize.small,
                  icon: const Icon(Icons.replay),
                  useSafeArea: false,
                  heroTag: null,
                  onPressed: () => _restartPolylinePlayback(),
                ),
              ],
            ],
          ),
        ),
        // Full-screen blocking overlay for data loads.
        ValueListenableBuilder<bool>(
          valueListenable: FormFieldsMapController.getBlockingLoadingListenable(
            _controllerId,
          ),
          builder: (context, isBlocking, _) {
            if (isBlocking) {
              return Positioned.fill(
                child: Stack(
                  children: [
                    const ModalBarrier(
                      dismissible: false,
                      color: Colors.black38,
                    ),
                    Center(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.formTr('loading'),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Small non-blocking indicator for brief camera/position updates.
        ValueListenableBuilder<bool>(
          valueListenable: FormFieldsMapController.getLoadingListenable(
            _controllerId,
          ),
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Positioned(
                right: 12,
                top: 12,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    if (_suppressNextMapTap) {
      _suppressNextMapTap = false;
      return;
    }
    try {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;

      // Compute local tap offset once for pixel-based hit tests.
      Offset local;
      try {
        local = (tapPosition as dynamic).localPosition as Offset;
      } catch (_) {
        try {
          local = (tapPosition as dynamic).local as Offset;
        } catch (_) {
          local = Offset(
            (context.size?.width ?? 0) / 2,
            (context.size?.height ?? 0) / 2,
          );
        }
      }

      // Polygons: point-in-polygon test. If point-in-polygon fails, also
      // perform an edge-distance fallback so thin polygons or borders are
      // still tappable.
      final tapZoom = _lastZoom ?? widget.initialZoom;
      final center = _lastCenter ?? widget.initialCenter;
      final centerX = CanvasRawMarkerPainter.worldX(center.longitude, tapZoom);
      final centerY = CanvasRawMarkerPainter.worldY(center.latitude, tapZoom);
      final double worldSize = 256 * pow(2, tapZoom).toDouble();
      // Increase hit padding slightly and scale with device pixel ratio so
      // taps are easier on denser screens and at intermediate zoom levels.
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final double extraTapPad = max(_tapPad, devicePixelRatio * 6.0) + 8.0;
      final double baseThreshPx = 24.0 + extraTapPad;

      for (final entry in notifier.polygonMap.entries) {
        final pid = entry.key;
        final poly = entry.value;
        if (_pointInPolygon(latlng, poly.points)) {
          // try to find metadata in rawMarkers if present and convert to ShapeMeta
          final meta = _findMetaForShape(notifier, pid);
          final mapPayload = <String, dynamic>{};
          if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
          mapPayload['id'] = pid;
          mapPayload['shapeType'] = ShapeTypes.polygon;
          mapPayload['lat'] = latlng.latitude;
          mapPayload['lon'] = latlng.longitude;
          final cVal = _extractColorPayloadForId(notifier, pid);
          if (cVal != null) mapPayload['color'] = cVal;
          // building ShapeMeta from mapPayload (log removed)
          final sm = ShapeMeta.fromMap(mapPayload);
          widget.onTapShape?.call(sm);
          return;
        }
        // Fallback: check distance to polygon edges in screen space. This
        // helps when polygon is thin or user taps near its border.
        try {
          double minEdgeDist = double.infinity;
          final pts = poly.points;
          for (var i = 0; i < pts.length; i++) {
            final p0 = pts[i];
            final p1 = pts[(i + 1) % pts.length];
            final x0 = CanvasRawMarkerPainter.worldX(p0.longitude, tapZoom);
            final y0 = CanvasRawMarkerPainter.worldY(p0.latitude, tapZoom);
            var dx0 = (x0 - centerX) + (context.size?.width ?? 0) / 2;
            var dy0 = (y0 - centerY) + (context.size?.height ?? 0) / 2;
            if (dx0.abs() > worldSize / 2) {
              if (dx0 > 0) {
                dx0 -= worldSize;
              } else {
                dx0 += worldSize;
              }
            }
            final x1 = CanvasRawMarkerPainter.worldX(p1.longitude, tapZoom);
            final y1 = CanvasRawMarkerPainter.worldY(p1.latitude, tapZoom);
            var dx1 = (x1 - centerX) + (context.size?.width ?? 0) / 2;
            var dy1 = (y1 - centerY) + (context.size?.height ?? 0) / 2;
            if (dx1.abs() > worldSize / 2) {
              if (dx1 > 0) {
                dx1 -= worldSize;
              } else {
                dx1 += worldSize;
              }
            }
            final distPx = pointToSegmentDistance(
              local,
              Offset(dx0, dy0),
              Offset(dx1, dy1),
            );
            if (distPx < minEdgeDist) minEdgeDist = distPx;
          }
          if (minEdgeDist <= max(baseThreshPx, 16.0)) {
            final meta = _findMetaForShape(notifier, pid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = pid;
            mapPayload['shapeType'] = ShapeTypes.polygon;
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
            final cVal = _extractColorPayloadForId(notifier, pid);
            if (cVal != null) mapPayload['color'] = cVal;
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }
        } catch (_) {}
      }

      // Polylines: precise per-segment hit-testing in screen pixels. Increase
      // threshold based on stroke width and add a relaxed fallback so thin
      // or angled segments are easier to tap.
      double minPolyDist = double.infinity;
      String? minPolyId;
      for (final entry in notifier.polylineMap.entries) {
        final lid = entry.key;
        final pl = entry.value;
        final pts = pl.points;
        final stroke = pl.strokeWidth;
        final threshPx = max(baseThreshPx, stroke * 3.0 + 16.0);
        for (var i = 0; i < pts.length - 1; i++) {
          final p0 = pts[i];
          final p1 = pts[i + 1];
          final x0 = CanvasRawMarkerPainter.worldX(p0.longitude, tapZoom);
          final y0 = CanvasRawMarkerPainter.worldY(p0.latitude, tapZoom);
          var dx0 = (x0 - centerX) + (context.size?.width ?? 0) / 2;
          var dy0 = (y0 - centerY) + (context.size?.height ?? 0) / 2;
          if (dx0.abs() > worldSize / 2) {
            if (dx0 > 0) {
              dx0 -= worldSize;
            } else {
              dx0 += worldSize;
            }
          }
          final x1 = CanvasRawMarkerPainter.worldX(p1.longitude, tapZoom);
          final y1 = CanvasRawMarkerPainter.worldY(p1.latitude, tapZoom);
          var dx1 = (x1 - centerX) + (context.size?.width ?? 0) / 2;
          var dy1 = (y1 - centerY) + (context.size?.height ?? 0) / 2;
          if (dx1.abs() > worldSize / 2) {
            if (dx1 > 0) {
              dx1 -= worldSize;
            } else {
              dx1 += worldSize;
            }
          }
          final distPx = pointToSegmentDistance(
            local,
            Offset(dx0, dy0),
            Offset(dx1, dy1),
          );
          if (distPx < minPolyDist) {
            minPolyDist = distPx;
            minPolyId = lid;
          }
          if (distPx <= threshPx) {
            final meta = _findMetaForShape(notifier, lid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = lid;
            mapPayload['shapeType'] = ShapeTypes.polyline;
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
            final cVal = _extractColorPayloadForId(notifier, lid);
            if (cVal != null) mapPayload['color'] = cVal;
            // polyline tap handled (log removed)
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
      // If no strict hit, use a relaxed fallback based on nearest distance.
      const double relaxMul = 4.0;
      if (minPolyId != null &&
          minPolyDist.isFinite &&
          minPolyDist <= baseThreshPx * relaxMul) {
        final meta = _findMetaForShape(notifier, minPolyId);
        final mapPayload = <String, dynamic>{};
        if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
        mapPayload['id'] = minPolyId;
        mapPayload['shapeType'] = ShapeTypes.polyline;
        mapPayload['lat'] = latlng.latitude;
        mapPayload['lon'] = latlng.longitude;
        final cVal = _extractColorPayloadForId(notifier, minPolyId);
        if (cVal != null) mapPayload['color'] = cVal;
        // polyline fallback handled (log removed)
        final sm = ShapeMeta.fromMap(mapPayload);
        widget.onTapShape?.call(sm);
        return;
      }

      final distance = Distance();
      // Circles: distance to center (meters if useRadiusInMeter true)
      // compute meters per pixel at current latitude/zoom so we can expand
      // meter-based radii by a sensible touch padding.
      final metersPerPixel =
          (156543.03392 * cos((latlng.latitude) * pi / 180)) / pow(2, tapZoom);
      final touchPadMeters = metersPerPixel * (_tapPad + 8.0);

      for (final entry in notifier.circleMap.entries) {
        final cid = entry.key;
        final c = entry.value;
        final center = c.point;
        final d = distance.distance(center, latlng);
        if (c.useRadiusInMeter) {
          if (d <= c.radius + touchPadMeters) {
            final meta = _findMetaForShape(notifier, cid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = cid;
            mapPayload['shapeType'] = ShapeTypes.circle;
            mapPayload['lat'] = latlng.latitude;
            mapPayload['lon'] = latlng.longitude;
            final cVal = _extractColorPayloadForId(notifier, cid);
            if (cVal != null) mapPayload['color'] = cVal;
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }
        } else {
          // radius in pixels/deg: approximate with small threshold
          final approxDeg = 0.01; // conservative fallback
          final latDiff = (center.latitude - latlng.latitude).abs();
          final lonDiff = (center.longitude - latlng.longitude).abs();
          if (sqrt(latDiff * latDiff + lonDiff * lonDiff) <= approxDeg) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{
              'id': cid,
              'shapeType': ShapeTypes.circle,
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            // building ShapeMeta from payload (log removed)
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
      // Markers: check rawMarkers canvas items for proximity to tap
      try {
        final radiusToUse = max(_canvasMarkerRadiusEffective, 6.0);
        final headOffsetMul = 0.6;
        final headRadiusMul = 0.9;
        final size = context.size ?? Size.zero;
        for (final m in _rawMarkersForProcessing(notifier)) {
          double lat;
          double lon;
          String? title;
          String? subtitle;
          String? shapeType;
          String? id;
          if (m is ShapeMeta) {
            final pms = m.pointMetas;
            final pm = (pms != null && pms.isNotEmpty) ? pms.first : null;
            if (pm == null) continue;
            lat = pm.lat;
            lon = pm.lon;
            title = pm.hit?.title ?? m.hit?.title;
            subtitle = pm.hit?.subtitle ?? m.hit?.subtitle;
            shapeType = m.shapeType;
            id = m.id;
          } else if (m is LatLng) {
            lat = m.latitude;
            lon = m.longitude;
          } else if (m is List && m.length >= 2) {
            lat = (m[0] as num).toDouble();
            lon = (m[1] as num).toDouble();
            if (m.length >= 3) title = m[2]?.toString();
            if (m.length >= 4) subtitle = m[3]?.toString();
            if (m.length >= 5) shapeType = m[4]?.toString();
          } else if (m is Map) {
            lat =
                (m['lat'] as num?)?.toDouble() ??
                (m['latitude'] as num?)?.toDouble() ??
                0.0;
            lon =
                (m['lon'] as num?)?.toDouble() ??
                (m['longitude'] as num?)?.toDouble() ??
                0.0;
            title = m['title']?.toString();
            subtitle = m['subtitle']?.toString();
            shapeType = m['shapeType']?.toString();
            id = m['id']?.toString();
          } else {
            continue;
          }

          final x = CanvasRawMarkerPainter.worldX(lon, tapZoom);
          final y = CanvasRawMarkerPainter.worldY(lat, tapZoom);

          var dx = (x - centerX) + size.width / 2;
          var dy = (y - centerY) + size.height / 2;
          if (dx.abs() > worldSize / 2) {
            if (dx > 0) {
              dx -= worldSize;
            } else {
              dx += worldSize;
            }
          }

          if (dx < -radiusToUse ||
              dx > size.width + radiusToUse ||
              dy < -radiusToUse ||
              dy > size.height + radiusToUse) {
            continue;
          }

          final headCenter = Offset(dx, dy - radiusToUse * headOffsetMul);
          final headRadius = radiusToUse * headRadiusMul;
          final headHitRadius = headRadius + extraTapPad;
          final dist = (local - headCenter).distance;
          if (dist <= headHitRadius) {
            final mapPayload = <String, dynamic>{};
            if (m is Map) mapPayload.addAll(Map<String, dynamic>.from(m));
            mapPayload['lat'] = lat;
            mapPayload['lon'] = lon;
            if (id != null) mapPayload['id'] = id;
            if (id != null) {
              final cVal = _extractColorPayloadForId(notifier, id);
              if (cVal != null) mapPayload['color'] = cVal;
            }
            mapPayload['shapeType'] = shapeType ?? ShapeTypes.marker;
            if (title != null) mapPayload['title'] = title;
            if (subtitle != null) mapPayload['subtitle'] = subtitle;
            // raw marker tap handled (log removed)
            final sm = ShapeMeta.fromMap(mapPayload);
            widget.onTapShape?.call(sm);
            return;
          }

          // Also hit-test the title/subtitle background region (if present)
          if ((title != null && title.isNotEmpty) ||
              (subtitle != null && subtitle.isNotEmpty)) {
            try {
              final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
              final textStyle = TextStyle(
                color: Colors.black,
                fontSize: max(10.0, devicePixelRatio * 6),
                fontWeight: FontWeight.w600,
              );
              final lines = <String>[];
              if (title != null && title.isNotEmpty) lines.add(title);
              if (subtitle != null && subtitle.isNotEmpty) lines.add(subtitle);
              final tp = TextPainter(textDirection: TextDirection.ltr);
              final span = TextSpan(
                children: lines
                    .map((l) => TextSpan(text: '$l\n', style: textStyle))
                    .toList(),
              );
              tp.text = span;
              tp.textAlign = TextAlign.center;
              tp.layout(minWidth: 0, maxWidth: size.width);

              final pad = 4.0;
              final bgWidth = tp.width + pad * 2;
              final bgHeight = tp.height + pad * 2;
              final bgRect = Rect.fromCenter(
                center: Offset(
                  headCenter.dx,
                  headCenter.dy - headRadius - bgHeight / 2 - 6,
                ),
                width: bgWidth,
                height: bgHeight,
              );

              if (bgRect.inflate(extraTapPad).contains(local)) {
                final mapPayload = <String, dynamic>{};
                if (m is Map) mapPayload.addAll(Map<String, dynamic>.from(m));
                mapPayload['lat'] = lat;
                mapPayload['lon'] = lon;
                if (id != null) mapPayload['id'] = id;
                if (id != null) {
                  final cVal = _extractColorPayloadForId(notifier, id);
                  if (cVal != null) mapPayload['color'] = cVal;
                }
                mapPayload['shapeType'] = shapeType ?? ShapeTypes.marker;
                if (title != null) mapPayload['title'] = title;
                if (subtitle != null) mapPayload['subtitle'] = subtitle;
                // raw marker label tap handled (log removed)
                final sm = ShapeMeta.fromMap(mapPayload);
                widget.onTapShape?.call(sm);
                return;
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    } catch (_) {}

    widget.onMapTap?.call(latlng);
  }

  void _handleLongPress(TapPosition tapPosition, LatLng latlng) {
    try {
      final notifier =
          FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;

      for (final entry in notifier.polygonMap.entries) {
        final pid = entry.key;
        final poly = entry.value;
        if (_pointInPolygon(latlng, poly.points)) {
          final meta = _findMetaForShape(notifier, pid);
          final payload = <String, dynamic>{
            'id': pid,
            'shapeType': ShapeTypes.polygon,
          };
          if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
          payload['point'] = latlng;
          final cVal = _extractColorPayloadForId(notifier, pid);
          if (cVal != null) payload['color'] = cVal;
          final sm = ShapeMeta.fromMap(payload);
          widget.onTapShape?.call(sm);
          return;
        }
      }

      const threshMeters = 200.0;
      final distance = Distance();
      for (final entry in notifier.polylineMap.entries) {
        final lid = entry.key;
        final pl = entry.value;
        final pts = pl.points;
        for (var i = 0; i < pts.length - 1; i++) {
          final mid = LatLng(
            (pts[i].latitude + pts[i + 1].latitude) / 2,
            (pts[i].longitude + pts[i + 1].longitude) / 2,
          );
          final d = distance.distance(mid, latlng);
          if (d <= threshMeters) {
            final meta = _findMetaForShape(notifier, lid);
            final payload = <String, dynamic>{
              'id': lid,
              'shapeType': ShapeTypes.polyline,
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final cVal = _extractColorPayloadForId(notifier, lid);
            if (cVal != null) payload['color'] = cVal;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }

      for (final entry in notifier.circleMap.entries) {
        final cid = entry.key;
        final c = entry.value;
        final center = c.point;
        final d = Distance().distance(center, latlng);
        if (c.useRadiusInMeter) {
          if (d <= c.radius) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{
              'id': cid,
              'shapeType': ShapeTypes.circle,
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final cVal = _extractColorPayloadForId(notifier, cid);
            if (cVal != null) payload['color'] = cVal;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        } else {
          final approxDeg = 0.01;
          final latDiff = (center.latitude - latlng.latitude).abs();
          final lonDiff = (center.longitude - latlng.longitude).abs();
          if (sqrt(latDiff * latDiff + lonDiff * lonDiff) <= approxDeg) {
            final meta = _findMetaForShape(notifier, cid);
            final payload = <String, dynamic>{
              'id': cid,
              'shapeType': ShapeTypes.circle,
            };
            if (meta is Map) payload.addAll(Map<String, dynamic>.from(meta));
            payload['point'] = latlng;
            final cVal = _extractColorPayloadForId(notifier, cid);
            if (cVal != null) payload['color'] = cVal;
            final sm = ShapeMeta.fromMap(payload);
            widget.onTapShape?.call(sm);
            return;
          }
        }
      }
    } catch (_) {}

    widget.onLongPress?.call(latlng);
  }

  /// Return a capped view of `notifier.rawMarkers` suitable for painting and
  /// hit-testing. Limits the number of items to `widget.maxRenderedRawMarkers`.
  List<dynamic> _rawMarkersForProcessing(FormFieldsMapNotifier notifier) {
    final list = notifier.rawMarkers;
    final max = widget.maxRenderedRawMarkers;
    if (list.length <= max) return list;
    try {
      return list.sublist(0, max);
    } catch (_) {
      return list;
    }
  }

  dynamic _findMetaForShape(FormFieldsMapNotifier notifier, String id) {
    // rawMarkers may contain a Map with an `id` pointing to shape metadata.
    for (final m in _rawMarkersForProcessing(notifier)) {
      if (m is Map && m['id'] == id) return m;
    }
    return null;
  }

  /// Search rawMarkers for a color associated with `id`. Returns an ARGB
  /// int or a string as stored in payloads, or null if not found.
  dynamic _extractColorPayloadForId(FormFieldsMapNotifier notifier, String id) {
    for (final r in _rawMarkersForProcessing(notifier)) {
      if (r is ShapeMeta && r.id == id && r.color != null) {
        try {
          return r.color!.toARGB32();
        } catch (_) {
          return r.color!.toARGB32();
        }
      }
      if (r is Map && r['id'] == id && r['color'] != null) {
        return r['color'];
      }
    }
    return null;
  }

  /// Search rawMarkers for a color associated with a LatLng `point`.
  /// Returns the stored color value (int, String, or Color) or null.
  dynamic _extractColorPayloadForPoint(
    FormFieldsMapNotifier notifier,
    LatLng point,
  ) {
    const tol = 0.00001; // ~1m tolerance
    for (final r in _rawMarkersForProcessing(notifier)) {
      if (r is ShapeMeta) {
        final pms = r.pointMetas;
        final pm = (pms != null && pms.isNotEmpty) ? pms.first : null;
        if (pm != null) {
          final lat = pm.lat;
          final lon = pm.lon;
          if ((lat - point.latitude).abs() <= tol &&
              (lon - point.longitude).abs() <= tol) {
            if (r.color != null) return r.color;
            return null;
          }
        }
      }
      if (r is Map) {
        final lat =
            (r['lat'] as num?)?.toDouble() ??
            (r['latitude'] as num?)?.toDouble();
        final lon =
            (r['lon'] as num?)?.toDouble() ??
            (r['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          if ((lat - point.latitude).abs() <= tol &&
              (lon - point.longitude).abs() <= tol) {
            return r['color'];
          }
        }
      }
    }
    return null;
  }

  bool _pointInPolygon(LatLng p, List<LatLng> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect =
          ((yi > p.latitude) != (yj > p.latitude)) &&
          (p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
