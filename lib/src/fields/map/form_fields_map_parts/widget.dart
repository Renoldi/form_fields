part of '../form_fields_map.dart';

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

  /// Interval between playback steps. Defaults to 1 second.
  // Playback configuration is centralized in `FormFieldsMapPlaybackConfig`.

  @override
  FormFieldsMapState createState() => FormFieldsMapState();
}
