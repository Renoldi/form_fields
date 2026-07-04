import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Lightweight metadata model used for markers and shape placeholders.
class ShapeMeta {
  ShapeMeta({
    required this.lat,
    required this.lon,
    this.title,
    this.subtitle,
    this.id,
    this.address,
    this.shapeType,
    this.rotation,
    this.color,
  });

  double lat;
  double lon;
  String? title;
  String? subtitle;
  String? id;
  String? address;
  double? rotation;
  String? shapeType;

  /// Optional color for this shape/marker. Stored in-memory as a Flutter
  /// [Color]; `toMap()` serializes it as an ARGB `int` for compatibility.
  /// Use [resolveColor] to get a color that falls back to the theme when
  /// unset.
  Color? color;

  LatLng get point => LatLng(lat, lon);

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lon': lon,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (id != null) 'id': id,
        if (address != null) 'address': address,
        if (rotation != null) 'rotation': rotation,
        if (shapeType != null) 'shapeType': shapeType,
        if (color != null) 'color': color!.toARGB32(),
      };

  factory ShapeMeta.fromMap(Map<String, dynamic> m) {
    double? lat;
    double? lon;
    // Accept LatLng-like `point` as well
    if (m['point'] is LatLng) {
      lat = (m['point'] as LatLng).latitude;
      lon = (m['point'] as LatLng).longitude;
    }
    lat ??=
        (m['lat'] as num?)?.toDouble() ?? (m['latitude'] as num?)?.toDouble();
    lon ??=
        (m['lon'] as num?)?.toDouble() ?? (m['longitude'] as num?)?.toDouble();
    return ShapeMeta(
      lat: lat ?? 0.0,
      lon: lon ?? 0.0,
      title: m['title']?.toString(),
      subtitle: m['subtitle']?.toString(),
      id: m['id']?.toString(),
      address: m['address']?.toString(),
      shapeType: m['shapeType']?.toString(),
      rotation: (m['rotation'] as num?)?.toDouble() ??
          (m['bearing'] as num?)?.toDouble(),
      color: _parseColorFromMap(m['color']),
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
  Color resolveColor(BuildContext context) =>
      color ?? Theme.of(context).colorScheme.primary;
}
