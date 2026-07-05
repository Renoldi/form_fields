import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/src/fields/map/canvas_raw_marker_painter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';

const double _tapPad = 12.0;

class FormFieldsMap extends StatefulWidget {
  const FormFieldsMap({
    super.key,
    this.controller,
    this.tileUrlTemplate = 'https://mt1.google.com/vt/lyrs=r&x={x}&y={y}&z={z}',
    this.tileAttribution = '© Google',
    this.initialCenter = const LatLng(0, 0),
    this.initialZoom = 13,
    this.maxZoom = 19,
    this.minZoom = 4,
    this.panBuffer = 2,
    this.keepAlive = true,
    this.canvasMarkerRadius = 20.0,
    this.canvasMarkerIcon,
    this.showTitle = true,
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
    this.enablePolylinePlayback = false,
    this.playbackInterval = const Duration(seconds: 1),
    this.playbackInterpolationSteps = 0,
    this.showBuiltinPlaybackControls = true,
    this.maxRenderedRawMarkers = 10000,
  });

  // Controller id has been removed in favor of the centralized
  // `FormFieldsMapController` registry. Instances generate their own
  // private id and expose controller operations through the registry.
  final MapController? controller;
  final String tileUrlTemplate;
  final String tileAttribution;
  final LatLng initialCenter;
  final double initialZoom;
  final double maxZoom;
  final double minZoom;
  final int panBuffer;
  final bool keepAlive;

  final double canvasMarkerRadius;

  final Object? canvasMarkerIcon;

  final bool showTitle;

  final bool showMarkerInCenter;

  /// Maximum number of `rawMarkers` items to render/process. When the
  /// notifier contains more items than this threshold, only the first
  /// `maxRenderedRawMarkers` entries are considered for painting and hit
  /// testing. This prevents out-of-memory and extreme CPU work when
  /// consumers accidentally provide very large lists (e.g. 1,000,000
  /// markers).
  final int maxRenderedRawMarkers;

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

  /// Enable an on-map polyline playback control. When enabled a small set
  /// of playback buttons are shown and the internal playback API is wired
  /// so external callers can also control playback via
  /// `FormFieldsMapController`.
  final bool enablePolylinePlayback;

  /// Interval between playback steps. Defaults to 1 second.
  final Duration playbackInterval;

  /// Number of interpolated points to insert between each pair of original
  /// polyline points. Higher values make movement smoother but increase the
  /// number of rendered steps.
  final int playbackInterpolationSteps;

  /// Whether to show the package's built-in on-map playback FAB controls.
  /// Set to `false` to hide them (for example when providing a custom
  /// external UI), defaults to `true` to preserve previous behavior.
  final bool showBuiltinPlaybackControls;

  @override
  FormFieldsMapState createState() => FormFieldsMapState();
}

class FormFieldsMapState extends State<FormFieldsMap>
    with AutomaticKeepAliveClientMixin<FormFieldsMap> {
  late final MapController _mapController;
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

  bool _suppressNextMapTap = false;

  late String _controllerId;
  bool _ownsController = false;

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

    // Register the internal fallback notifier only when no notifier has been
    // previously registered for this controller id. This prevents the widget
    // from overwriting a notifier that a consumer (or example) already
    // registered before the widget was built.
    try {
      final existing = FormFieldsMapController.getNotifier(_controllerId);
      try {
        debugPrint(
            '[FormFieldsMap] initState controllerId=$_controllerId existingNotifier=${existing?.hashCode} fallback=${_fallbackNotifier.hashCode}');
      } catch (_) {}
      if (existing == null) {
        FormFieldsMapController.registerNotifier(
            _controllerId, _fallbackNotifier);
      }
    } catch (_) {}

    // Notifier lifecycle is managed externally via FormFieldsMapController.
    // The widget no longer accepts a `notifier` parameter.
    _resolveCanvasMarkerIcon();
    _playbackInterval = widget.playbackInterval;
    _playbackInterpolationSteps = widget.playbackInterpolationSteps;
    _playbackSubstepInterval =
        _computeSubstepInterval(_playbackInterval, _playbackInterpolationSteps);
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
        _controllerId, widget.onTapShape);

    // Register playback handler so external callers can control playback via
    // `FormFieldsMapController`.
    if (widget.enablePolylinePlayback) {
      FormFieldsMapController.registerPlaybackHandler(
        _controllerId,
        FormFieldsMapPlaybackHandler(
          start: (polylineId) => _startPolylinePlayback(polylineId),
          pause: () => _pausePolylinePlayback(),
          restart: () => _restartPolylinePlayback(),
          setInterval: (d) => _setPolylinePlaybackInterval(d),
          setInterpolationSteps: (s) => _setPlaybackInterpolationSteps(s),
          toggle: (polylineId) => _togglePolylinePlayback(polylineId),
        ),
      );
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
    if (oldWidget.canvasMarkerIcon != widget.canvasMarkerIcon) {
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
            _controllerId, _mapController);
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
              '[FormFieldsMap] didUpdateWidget moved controller oldId=$oldId newId=$_controllerId existingNotifier=${existing?.hashCode} fallback=${_fallbackNotifier.hashCode}');
        } catch (_) {}
        if (existing == null) {
          FormFieldsMapController.registerNotifier(
              _controllerId, _fallbackNotifier);
        }
      } catch (_) {}
    }

    if (oldWidget.onTapShape != widget.onTapShape || oldId != _controllerId) {
      FormFieldsMapController.removeOnMarkerTap(oldId);
      FormFieldsMapController.registerOnMarkerTap(
          _controllerId, widget.onTapShape);
      // Move playback handler registration when controller id changes.
      FormFieldsMapController.unregisterPlaybackHandler(oldId);
      if (widget.enablePolylinePlayback) {
        FormFieldsMapController.registerPlaybackHandler(
          _controllerId,
          FormFieldsMapPlaybackHandler(
            start: (polylineId) => _startPolylinePlayback(polylineId),
            pause: () => _pausePolylinePlayback(),
            restart: () => _restartPolylinePlayback(),
            setInterval: (d) => _setPolylinePlaybackInterval(d),
            setInterpolationSteps: (s) => _setPlaybackInterpolationSteps(s),
            toggle: (polylineId) => _togglePolylinePlayback(polylineId),
          ),
        );
      }
    }

    // Handle changes to playback configuration
    if (oldWidget.playbackInterval != widget.playbackInterval ||
        oldWidget.playbackInterpolationSteps !=
            widget.playbackInterpolationSteps) {
      _playbackInterval = widget.playbackInterval;
      _playbackInterpolationSteps = widget.playbackInterpolationSteps;
      _playbackSubstepInterval = _computeSubstepInterval(
          _playbackInterval, _playbackInterpolationSteps);
      if (_isPlaying) {
        _playbackTimer?.cancel();
        _playbackTimer = Timer.periodic(
            _playbackSubstepInterval, (_) => _advancePlaybackStep());
      }
      // rebuild points if playing
      if (_playbackPolylineId != null) {
        final notifier = FormFieldsMapController.getNotifier(_controllerId) ??
            _fallbackNotifier;
        final pl = notifier.polylineMap[_playbackPolylineId];
        if (pl != null) {
          _playbackPoints =
              _buildInterpolatedPoints(pl.points, _playbackInterpolationSteps);
        }
      }
    }
  }

  void _resolveCanvasMarkerIcon() {
    if (_canvasMarkerImageStream != null &&
        _canvasMarkerImageStreamListener != null) {
      _canvasMarkerImageStream!
          .removeListener(_canvasMarkerImageStreamListener!);
    }
    _canvasMarkerImageStream = null;
    _canvasMarkerImageStreamListener = null;
    final provider = widget.canvasMarkerIcon;
    if (provider == null) return;

    if (provider is ImageProvider) {
      final config = createLocalImageConfiguration(context);
      final stream = provider.resolve(config);
      _canvasMarkerImageStream = stream;
      _canvasMarkerImageStreamListener =
          ImageStreamListener((ImageInfo info, bool _) {
        _canvasMarkerImage = info.image;
        _safeSetState(() {});
      });
      stream.addListener(_canvasMarkerImageStreamListener!);
      return;
    }

    if (provider is Icon) {
      _renderIconToImage(provider).then((img) {
        _canvasMarkerImage = img;
        _safeSetState(() {});
      });
      return;
    }

    if (provider is Widget) {
      _rasterizeWidgetToImage(provider).then((img) {
        if (img != null) {
          _canvasMarkerImage = img;
          _safeSetState(() {});
        }
      });
      return;
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
          text: String.fromCharCode(iconData.codePoint), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final w = tp.width.ceil();
    final h = tp.height.ceil();
    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    tp.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w == 0 ? 1 : w, h == 0 ? 1 : h);
    return image;
  }

  Future<ui.Image?> _rasterizeWidgetToImage(Widget widget,
      {double logicalSize = 36.0}) async {
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
      _canvasMarkerImageStream!
          .removeListener(_canvasMarkerImageStreamListener!);
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
      final dynamic pos = position;
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
      }
    } catch (_) {}

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.cameraIdleDebounce, () {
      FormFieldsMapController.setLoading(_controllerId, false);
      // During playback, do not notify center changes to consumers.
      if (_isPlaying) return;
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
      } catch (_) {}
    });
  }

  void _setPolylinePlaybackInterval(Duration interval) {
    _playbackInterval = interval;
    _playbackSubstepInterval =
        _computeSubstepInterval(_playbackInterval, _playbackInterpolationSteps);
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
          _playbackSubstepInterval, (_) => _advancePlaybackStep());
    }
  }

  // Allow runtime update of interpolation steps
  void _setPlaybackInterpolationSteps(int steps) {
    _playbackInterpolationSteps = steps.clamp(0, 1000);
    _playbackSubstepInterval =
        _computeSubstepInterval(_playbackInterval, _playbackInterpolationSteps);
    // rebuild playback list if currently playing
    if (_playbackPolylineId != null) {
      final notifier = FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      final pl = notifier.polylineMap[_playbackPolylineId];
      if (pl != null) {
        final currentPoint = _playbackPoints.isNotEmpty &&
                _playbackIndex < _playbackPoints.length
            ? _playbackPoints[_playbackIndex]
            : null;
        _playbackPoints =
            _buildInterpolatedPoints(pl.points, _playbackInterpolationSteps);
        // re-find closest index to currentPoint
        if (currentPoint != null) {
          var best = 0;
          var bestDist = double.infinity;
          for (var i = 0; i < _playbackPoints.length; i++) {
            final d = pow(
                    (_playbackPoints[i].latitude - currentPoint.latitude), 2) +
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
      final notifier = FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      String? id = polylineId ??
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
              _playbackSubstepInterval, (_) => _advancePlaybackStep());
          return;
        } else {
          // at end -> restart from beginning
          _playbackIndex = 0;
        }
      }

      // New polyline (or restarting finished one): build points and start
      _playbackPolylineId = id;
      _playbackPoints =
          _buildInterpolatedPoints(pl.points, _playbackInterpolationSteps);
      _playbackIndex = 0;
      _isPlaying = true;
      // publish authoritative playing state
      try {
        FormFieldsMapController.setPlaybackPlaying(_controllerId, true);
      } catch (_) {}
      _safeSetState(() {});
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
          _playbackSubstepInterval, (_) => _advancePlaybackStep());
      // Zoom to level 17 (clamped to allowed min/max) when starting playback
      try {
        final initialPoint =
            _playbackPoints.isNotEmpty ? _playbackPoints[_playbackIndex] : null;
        if (initialPoint != null) {
          final targetZoom = (17.0).clamp(widget.minZoom, widget.maxZoom);
          // animateTo is async but we don't need to await inside timer callbacks
          animateTo(initialPoint, targetZoom);
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
        _playbackPoints =
            _buildInterpolatedPoints(pl.points, _playbackInterpolationSteps);
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
    _playbackTimer =
        Timer.periodic(_playbackSubstepInterval, (_) => _advancePlaybackStep());
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
            from = _playbackPoints[
                (_playbackIndex + 1).clamp(0, _playbackPoints.length - 1)];
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
        'shapeType': 'marker',
        'lat': p.latitude,
        'lon': p.longitude,
        'rotation': bearing,
        'title': null,
      };
      // Prefer the configured canvas marker icon when available; otherwise
      // fall back to the default arrow glyph. Leaving 'icon' unset lets the
      // painter draw the rasterized `iconImage` when present.
      if (widget.canvasMarkerIcon == null) {
        payload['icon'] = 'arrow';
      }
      final notifier = FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;
      // Use controller API to mutate notifier so only controller is the
      // canonical mutator for map state.
      try {
        FormFieldsMapController.setRawMarkers(_controllerId, [payload]);
      } catch (_) {
        // fallback to direct notifier mutation if registry isn't available
        notifier.rawMarkers = [payload];
      }
      // If playback is active, move camera to follow the playback point
      try {
        if (_isPlaying) {
          final targetZoom = (17.0).clamp(widget.minZoom, widget.maxZoom);
          animateTo(p, targetZoom);
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> animateTo(LatLng dest, double zoom,
      {Duration duration = const Duration(milliseconds: 400)}) async {
    _mapController.move(dest, zoom);
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

  Future<void> fitBounds(LatLngBounds bounds,
      {EdgeInsets padding = EdgeInsets.zero,
      Duration duration = const Duration(milliseconds: 400)}) async {
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
                urlTemplate: widget.tileUrlTemplate,
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
                  final mapped = notifierLocal.polygonMap.entries.map((e) {
                    final id = e.key;
                    final p = e.value;
                    final dynColor =
                        _extractColorPayloadForId(notifierLocal, id);
                    final parsed = ShapeMeta.parseColor(dynColor);
                    return Polygon(
                      points: p.points,
                      color: parsed != null
                          ? parsed.withValues(alpha: 0.25)
                          : themeColor.withValues(alpha: 0.25),
                      borderColor: parsed ?? themeColor,
                      borderStrokeWidth: p.borderStrokeWidth,
                    );
                  }).toList(growable: false);
                  if (mapped.isEmpty) return const SizedBox.shrink();
                  return PolygonLayer(polygons: mapped);
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
                  final mapped = notifierLocal.polylineMap.entries.map((e) {
                    final id = e.key;
                    final l = e.value;
                    final dynColor =
                        _extractColorPayloadForId(notifierLocal, id);
                    final parsed = ShapeMeta.parseColor(dynColor);
                    return Polyline(
                      points: l.points,
                      strokeWidth: l.strokeWidth,
                      color: parsed ?? themeColor,
                    );
                  }).toList(growable: false);
                  if (mapped.isEmpty) return const SizedBox.shrink();
                  return PolylineLayer(polylines: mapped);
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
                  final mapped = notifierLocal.circleMap.entries.map((e) {
                    final id = e.key;
                    final c = e.value;
                    final dynColor =
                        _extractColorPayloadForId(notifierLocal, id);
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
                  }).toList(growable: false);
                  if (mapped.isEmpty) return const SizedBox.shrink();
                  return CircleLayer(circles: mapped);
                },
              ),
              Selector<FormFieldsMapNotifier, List<Marker>>(
                selector: (_, n) => n.markers,
                builder: (context, markers, _) {
                  if (markers.isEmpty) return const SizedBox.shrink();
                  final notifierLocal =
                      FormFieldsMapController.getNotifier(_controllerId) ??
                          _fallbackNotifier;
                  final mapped = markers.map((m) {
                    // try to find a color for this marker from rawMarkers (by point)
                    final dynColor =
                        _extractColorPayloadForPoint(notifierLocal, m.point);
                    ShapeMeta.parseColor(dynColor);
                    // use idiomatic colorScheme.onSecondary for marker foreground
                    final markerForeground =
                        Theme.of(context).colorScheme.onSecondary;
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
                  }).toList(growable: false);
                  return MarkerLayer(markers: mapped);
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable:
                    FormFieldsMapController.getBlockingLoadingListenable(
                        _controllerId),
                builder: (context, isBlocking, __) {
                  return Selector<FormFieldsMapNotifier, List<dynamic>>(
                    selector: (_, n) => n.rawMarkers,
                    builder: (context, rawMarkers, _) {
                      if (rawMarkers.isEmpty) return const SizedBox.shrink();
                      final renderedRawMarkers = rawMarkers.length >
                              widget.maxRenderedRawMarkers
                          ? rawMarkers.sublist(0, widget.maxRenderedRawMarkers)
                          : rawMarkers;
                      return Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: CanvasRawMarkerPainter(
                              rawMarkers: renderedRawMarkers,
                              center: _lastCenter ?? widget.initialCenter,
                              zoom: _lastZoom ?? widget.initialZoom,
                              radius: widget.canvasMarkerRadius,
                              devicePixelRatio:
                                  MediaQuery.of(context).devicePixelRatio,
                              iconImage: _canvasMarkerImage,
                              // hide titles while blocking loading is active or when zoom is low
                              showTitle: widget.showTitle &&
                                  !isBlocking &&
                                  ((_lastZoom ?? widget.initialZoom) >= 10.0),
                              defaultColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
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
        if (widget.showMarkerInCenter)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Builder(builder: (ctx) {
                  // Priority: explicit `centerMarker` widget -> rasterized
                  // `_canvasMarkerImage` -> provided `canvasMarkerIcon`
                  if (widget.centerMarker != null) return widget.centerMarker!;
                  if (_canvasMarkerImage != null) {
                    return RawImage(
                      image: _canvasMarkerImage,
                      width: widget.canvasMarkerRadius * 2,
                      height: widget.canvasMarkerRadius * 2,
                      fit: BoxFit.contain,
                    );
                  }
                  final provider = widget.canvasMarkerIcon;
                  if (provider is Widget) return provider;
                  if (provider is Icon) return provider;
                  if (provider is ImageProvider) {
                    return Image(
                      image: provider,
                      width: widget.canvasMarkerRadius * 2,
                      height: widget.canvasMarkerRadius * 2,
                      fit: BoxFit.contain,
                    );
                  }
                  return Icon(
                    Icons.location_pin,
                    color: Theme.of(context).colorScheme.onSecondary,
                    size: 36,
                  );
                }),
              ),
            ),
          ),
        Positioned(
          right: 12,
          top: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current zoom display
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 6.0),
                  child: Text(
                    'Zoom: ${(_lastZoom ?? widget.initialZoom).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                type: AppButtonType.fab,
                size: AppSize.small,
                icon: const Icon(Icons.add),
                useSafeArea: false,
                heroTag: null,
                onPressed: () {
                  final center = _lastCenter ?? widget.initialCenter;
                  final currentZoom = _lastZoom ?? widget.initialZoom;
                  final newZoom =
                      (currentZoom + 1).clamp(widget.minZoom, widget.maxZoom);
                  animateTo(center, newZoom);
                },
              ),
              const SizedBox(height: 8),

              AppButton(
                type: AppButtonType.fab,
                size: AppSize.small,
                icon: const Icon(Icons.my_location),
                useSafeArea: false,
                heroTag: null,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  LatLng? target;
                  if (widget.onRequestCurrentLocation != null) {
                    try {
                      target = await widget.onRequestCurrentLocation!();
                    } catch (_) {
                      target = null;
                    }
                  }
                  if (!mounted) return;
                  if (target != null) {
                    final currentZoom = _lastZoom ?? widget.initialZoom;
                    await animateTo(target, currentZoom);
                    return;
                  }
                  messenger?.showSnackBar(const SnackBar(
                      content: Text('Current location not available')));
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
                  final newZoom =
                      (currentZoom - 1).clamp(widget.minZoom, widget.maxZoom);
                  animateTo(center, newZoom);
                },
              ),
              const SizedBox(height: 8),
              if (widget.enablePolylinePlayback &&
                  widget.showBuiltinPlaybackControls) ...[
                ValueListenableBuilder<bool>(
                  valueListenable:
                      FormFieldsMapController.getPlaybackPlayingListenable(
                          _controllerId),
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
              _controllerId),
          builder: (context, isBlocking, _) {
            if (isBlocking) {
              return Positioned.fill(
                child: Stack(
                  children: [
                    const ModalBarrier(
                        dismissible: false, color: Colors.black38),
                    Center(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                              Text(context.formTr('loading'),
                                  style: const TextStyle(fontSize: 14)),
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
          valueListenable:
              FormFieldsMapController.getLoadingListenable(_controllerId),
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
                        child: CircularProgressIndicator(strokeWidth: 2)),
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
      final notifier = FormFieldsMapController.getNotifier(_controllerId) ??
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
              (context.size?.width ?? 0) / 2, (context.size?.height ?? 0) / 2);
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
          mapPayload['shapeType'] = 'polygon';
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
                local, Offset(dx0, dy0), Offset(dx1, dy1));
            if (distPx < minEdgeDist) minEdgeDist = distPx;
          }
          if (minEdgeDist <= max(baseThreshPx, 16.0)) {
            final meta = _findMetaForShape(notifier, pid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = pid;
            mapPayload['shapeType'] = 'polygon';
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
          final distPx =
              pointToSegmentDistance(local, Offset(dx0, dy0), Offset(dx1, dy1));
          if (distPx < minPolyDist) {
            minPolyDist = distPx;
            minPolyId = lid;
          }
          if (distPx <= threshPx) {
            final meta = _findMetaForShape(notifier, lid);
            final mapPayload = <String, dynamic>{};
            if (meta is Map) mapPayload.addAll(Map<String, dynamic>.from(meta));
            mapPayload['id'] = lid;
            mapPayload['shapeType'] = 'polyline';
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
        mapPayload['shapeType'] = 'polyline';
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
            mapPayload['shapeType'] = 'circle';
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
            final payload = <String, dynamic>{'id': cid, 'shapeType': 'circle'};
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
        final radiusToUse = max(widget.canvasMarkerRadius, 6.0);
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
            lat = m.lat;
            lon = m.lon;
            title = m.title;
            subtitle = m.subtitle;
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
            lat = (m['lat'] as num?)?.toDouble() ??
                (m['latitude'] as num?)?.toDouble() ??
                0.0;
            lon = (m['lon'] as num?)?.toDouble() ??
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
            mapPayload['shapeType'] = shapeType ?? 'marker';
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
                  fontWeight: FontWeight.w600);
              final lines = <String>[];
              if (title != null && title.isNotEmpty) lines.add(title);
              if (subtitle != null && subtitle.isNotEmpty) lines.add(subtitle);
              final tp = TextPainter(textDirection: TextDirection.ltr);
              final span = TextSpan(
                  children: lines
                      .map((l) => TextSpan(text: '$l\n', style: textStyle))
                      .toList());
              tp.text = span;
              tp.textAlign = TextAlign.center;
              tp.layout(minWidth: 0, maxWidth: size.width);

              final pad = 4.0;
              final bgWidth = tp.width + pad * 2;
              final bgHeight = tp.height + pad * 2;
              final bgRect = Rect.fromCenter(
                  center: Offset(headCenter.dx,
                      headCenter.dy - headRadius - bgHeight / 2 - 6),
                  width: bgWidth,
                  height: bgHeight);

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
                mapPayload['shapeType'] = shapeType ?? 'marker';
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
      final notifier = FormFieldsMapController.getNotifier(_controllerId) ??
          _fallbackNotifier;

      for (final entry in notifier.polygonMap.entries) {
        final pid = entry.key;
        final poly = entry.value;
        if (_pointInPolygon(latlng, poly.points)) {
          final meta = _findMetaForShape(notifier, pid);
          final payload = <String, dynamic>{'id': pid, 'shapeType': 'polygon'};
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
          final mid = LatLng((pts[i].latitude + pts[i + 1].latitude) / 2,
              (pts[i].longitude + pts[i + 1].longitude) / 2);
          final d = distance.distance(mid, latlng);
          if (d <= threshMeters) {
            final meta = _findMetaForShape(notifier, lid);
            final payload = <String, dynamic>{
              'id': lid,
              'shapeType': 'polyline'
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
            final payload = <String, dynamic>{'id': cid, 'shapeType': 'circle'};
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
            final payload = <String, dynamic>{'id': cid, 'shapeType': 'circle'};
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
      FormFieldsMapNotifier notifier, LatLng point) {
    const tol = 0.00001; // ~1m tolerance
    for (final r in _rawMarkersForProcessing(notifier)) {
      if (r is ShapeMeta) {
        final lat = r.lat;
        final lon = r.lon;
        if ((lat - point.latitude).abs() <= tol &&
            (lon - point.longitude).abs() <= tol) {
          if (r.color != null) return r.color;
          return null;
        }
      }
      if (r is Map) {
        final lat = (r['lat'] as num?)?.toDouble() ??
            (r['latitude'] as num?)?.toDouble();
        final lon = (r['lon'] as num?)?.toDouble() ??
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

      final intersect = ((yi > p.latitude) != (yj > p.latitude)) &&
          (p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
