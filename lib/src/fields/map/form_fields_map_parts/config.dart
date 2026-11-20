part of '../form_fields_map.dart';

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
    this.playbackHaloColor,
    this.playbackHaloScale = 1.6,
    this.playbackHaloOpacity = 0.95,
    this.playbackMarkerIcon,
    this.playbackFollowCamera = true,
    this.playbackZoom = 17.0,
    this.playbackCurve = Curves.easeInOut,
    this.playbackAutoStart = false,
    this.onPointReached,
  });

  final Duration playbackInterval;
  final int playbackInterpolationSteps;
  final bool showBuiltinPlaybackControls;
  final Color? playbackPolylineColor;
  final Color? playbackHaloColor;
  final double playbackHaloScale;
  final double playbackHaloOpacity;
  final Object? playbackMarkerIcon;
  final bool playbackFollowCamera;
  final double playbackZoom;
  final Curve playbackCurve;
  final bool playbackAutoStart;
  final Future<void> Function(String? polylineId, int index, LatLng point)?
  onPointReached;
}

/// Lightweight map-specific configuration bucket used to surface a few
/// canvas/map-related visual options without polluting the main widget
/// constructor. This intentionally keeps types flexible to accept icons,
/// image providers or widget-based markers for rasterization.
class FormFieldsMapMapConfig {
  const FormFieldsMapMapConfig({
    this.enableClustering = true,
    this.canvasMarkerRadius = 20.0,
    this.canvasMarkerIcon,
    this.showTitle = true,
  });

  final bool enableClustering;
  final double canvasMarkerRadius;
  final Object? canvasMarkerIcon;
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
  /// that will be returned by a search result.
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
