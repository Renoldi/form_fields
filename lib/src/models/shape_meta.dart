import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Per-point metadata used for shapes that carry additional information per
/// coordinate (e.g. Polygons, Polylines or CircleMarkers converted to lists).
class PointMeta {
  PointMeta({
    required this.lat,
    required this.lon,
    this.address,
    this.rotation,
    this.id,
    this.title,
    this.subtitle,
  });

  double lat;
  double lon;
  String? address;
  double? rotation;
  String? id;
  String? title;
  String? subtitle;

  LatLng get point => LatLng(lat, lon);

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lon': lon,
        if (address != null) 'address': address,
        if (rotation != null) 'rotation': rotation,
        if (id != null) 'id': id,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      };

  factory PointMeta.fromMap(dynamic m) {
    if (m == null) throw ArgumentError('null point meta');
    if (m is PointMeta) return m;
    if (m is LatLng) return PointMeta(lat: m.latitude, lon: m.longitude);
    if (m is Map) {
      final map = Map<String, dynamic>.from(m);
      final lat = (map['lat'] as num?)?.toDouble() ??
          (map['latitude'] as num?)?.toDouble() ??
          0.0;
      final lon = (map['lon'] as num?)?.toDouble() ??
          (map['longitude'] as num?)?.toDouble() ??
          0.0;
      return PointMeta(
        lat: lat,
        lon: lon,
        address: map['address']?.toString(),
        rotation: (map['rotation'] as num?)?.toDouble() ??
            (map['bearing'] as num?)?.toDouble(),
        id: map['id']?.toString(),
        title: map['title']?.toString(),
        subtitle: map['subtitle']?.toString(),
      );
    }
    throw ArgumentError('Unsupported point meta type: ${m.runtimeType}');
  }
}

/// Lightweight metadata model used for markers and shape placeholders.
class ShapeMeta {
  ShapeMeta({
    this.pointMetas,
    this.title,
    this.subtitle,
    this.id,
    this.shapeType,
    this.properties,
  });

  /// Optional per-point metadata (lat/lon duplicated for convenience).
  List<PointMeta>? pointMetas;

  String? title;
  String? subtitle;
  String? id;
  String? shapeType;

  /// Optional color for this shape/marker. Stored in-memory as a Flutter
  /// [Color]; `toMap()` serializes it as an ARGB `int` for compatibility.
  /// Use [resolveColor] to get a color that falls back to the theme when
  /// unset.
  // Note: color removed from ShapeMeta; use `ShapeMeta.parseColor(...)`
  // to interpret dynamic color values when needed.

  /// Arbitrary, serializable properties that consumers can attach to a
  /// `ShapeMeta` to influence rendering or carry extra options. This map is
  /// intentionally untyped so callers can pass small option bags (e.g.
  /// `{'radiusMeters': 500, 'useRadiusInMeter': true, 'strokeWidth': 4}`)
  /// and custom builders on `FormFieldsMap` can interpret them.
  Map<String, dynamic>? properties;

  /// Convenience getter to obtain a parsed `Color` from `properties`.
  /// Looks for common color keys (`color`, `fillColor`, `fill_color`,
  /// `borderColor`, `border_color`) and returns the first parsable value.
  Color? get color {
    if (properties == null) return null;
    final keys = [
      'color',
      'fillColor',
      'fill_color',
      'borderColor',
      'border_color'
    ];
    for (final k in keys) {
      if (properties!.containsKey(k)) {
        final parsed = ShapeMeta.parseColor(properties![k]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (pointMetas != null)
        'pointMetas': pointMetas!.map((pm) => pm.toMap()).toList(),
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (id != null) 'id': id,
      if (shapeType != null) 'shapeType': shapeType,
      // color intentionally omitted from serialization
      if (properties != null) 'properties': properties,
    };
  }

  factory ShapeMeta.fromMap(Map<String, dynamic> m) {
    // Parse optional per-point metadata or single point into pointMetas.
    List<PointMeta>? parsedPointMetas;
    if (m['pointMetas'] is List) {
      parsedPointMetas =
          (m['pointMetas'] as List).map((e) => PointMeta.fromMap(e)).toList();
    } else if (m['point'] != null || m['lat'] != null || m['lon'] != null) {
      // Create a single PointMeta from `point` or legacy `lat`/`lon`.
      dynamic src = m['point'] ?? m;
      parsedPointMetas = [PointMeta.fromMap(src)];
    }

    return ShapeMeta(
      pointMetas: parsedPointMetas,
      title: m['title']?.toString(),
      subtitle: m['subtitle']?.toString(),
      id: m['id']?.toString(),
      shapeType: m['shapeType']?.toString(),
      properties: (m['properties'] is Map)
          ? Map<String, dynamic>.from(m['properties'] as Map)
          : null,
    );
  }

  /// Attempt to parse a color value coming from a map. Accepts an `int`, a
  /// Flutter [Color], or a hex `String` like "#FFAABBCC" or "0xFFAABBCC".
  static Color? _parseColorFromMap(dynamic v) {
    if (v == null) return null;
    if (v is Color) return v;
    if (v is int) return Color(v);
    if (v is String) {
      var s = v.trim();
      if (s.startsWith('#')) s = s.replaceFirst('#', '0x');
      if (s.startsWith('0x')) {
        try {
          final parsed = int.parse(s);
          return Color(parsed);
        } catch (_) {
          return null;
        }
      }
      // Fallback: try parsing decimal string
      try {
        final parsed = int.parse(s);
        return Color(parsed);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Public wrapper for parsing a dynamic color value (int, Color, or String).
  /// Kept public so other modules can reuse the same parsing logic.
  static Color? parseColor(dynamic v) => _parseColorFromMap(v);

  @override
  String toString() => toMap().toString();

  /// Convert stored ARGB int to a Flutter [Color]. If `color` is null,
  /// this will return the theme's primary color from the provided [context].
  // `resolveColor` removed because `ShapeMeta` no longer stores a color.
}

/// Common shape type constants to avoid string typos when using
/// `ShapeMeta.shapeType` across the codebase.
class ShapeTypes {
  ShapeTypes._();

  static const String marker = 'marker';
  static const String polygon = 'polygon';
  static const String polyline = 'polyline';
  static const String circle = 'circle';

  /// All known types.
  static const List<String> all = [marker, polygon, polyline, circle];
}

// --- Typed option helpers ---

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) {
    final s = v.trim();
    try {
      return double.parse(s);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class PolygonOptions {
  PolygonOptions(
      {this.strokeWidth,
      this.borderStrokeWidth,
      this.borderColor,
      this.fillColor});
  final double? strokeWidth;
  final double? borderStrokeWidth;
  final Color? borderColor;
  final Color? fillColor;

  factory PolygonOptions.fromProperties(
      Map<String, dynamic>? p, ShapeMeta meta) {
    if (p == null) return PolygonOptions();
    return PolygonOptions(
      strokeWidth: _toDouble(p['strokeWidth']) ?? _toDouble(p['stroke_width']),
      borderStrokeWidth: _toDouble(p['borderStrokeWidth']) ??
          _toDouble(p['border_stroke_width']),
      borderColor: ShapeMeta.parseColor(p['borderColor']) ??
          ShapeMeta.parseColor(p['border_color']),
      fillColor: ShapeMeta.parseColor(p['fillColor']) ??
          ShapeMeta.parseColor(p['fill_color']),
    );
  }
}

class PolylineOptions {
  PolylineOptions({this.strokeWidth, this.useStrokeWidthInMeter, this.color});
  final double? strokeWidth;
  final bool? useStrokeWidthInMeter;
  final Color? color;

  factory PolylineOptions.fromProperties(
      Map<String, dynamic>? p, ShapeMeta meta) {
    if (p == null) return PolylineOptions();
    return PolylineOptions(
      strokeWidth: _toDouble(p['strokeWidth']) ?? _toDouble(p['stroke_width']),
      useStrokeWidthInMeter: p['useStrokeWidthInMeter'] is bool
          ? p['useStrokeWidthInMeter'] as bool
          : (p['use_stroke_width_in_meter'] is bool
              ? p['use_stroke_width_in_meter'] as bool
              : null),
      color: ShapeMeta.parseColor(p['color']),
    );
  }
}

class CircleOptions {
  CircleOptions(
      {this.radiusMeters,
      this.useRadiusInMeter,
      this.borderStrokeWidth,
      this.borderColor});
  final double? radiusMeters;
  final bool? useRadiusInMeter;
  final double? borderStrokeWidth;
  final Color? borderColor;

  factory CircleOptions.fromProperties(
      Map<String, dynamic>? p, ShapeMeta meta) {
    if (p == null) return CircleOptions();
    return CircleOptions(
      radiusMeters: _toDouble(p['radiusMeters']) ??
          _toDouble(p['radius_meters']) ??
          _toDouble(p['radius']),
      useRadiusInMeter: p['useRadiusInMeter'] is bool
          ? p['useRadiusInMeter'] as bool
          : (p['use_radius_in_meter'] is bool
              ? p['use_radius_in_meter'] as bool
              : null),
      borderStrokeWidth: _toDouble(p['borderStrokeWidth']) ??
          _toDouble(p['border_stroke_width']),
      borderColor: ShapeMeta.parseColor(p['borderColor']) ??
          ShapeMeta.parseColor(p['border_color']),
    );
  }
}

class MarkerOptions {
  MarkerOptions({this.width, this.height, this.rotate});
  final double? width;
  final double? height;
  final bool? rotate;

  factory MarkerOptions.fromProperties(
      Map<String, dynamic>? p, ShapeMeta meta) {
    if (p == null) return MarkerOptions();
    return MarkerOptions(
      width: _toDouble(p['width']),
      height: _toDouble(p['height']),
      rotate: p['rotate'] is bool ? p['rotate'] as bool : null,
    );
  }
}

extension ShapeMetaOptions on ShapeMeta {
  PolygonOptions polygonOptions() =>
      PolygonOptions.fromProperties(properties, this);
  PolylineOptions polylineOptions() =>
      PolylineOptions.fromProperties(properties, this);
  CircleOptions circleOptions() =>
      CircleOptions.fromProperties(properties, this);
  MarkerOptions markerOptions() =>
      MarkerOptions.fromProperties(properties, this);
}
