import 'package:latlong2/latlong.dart';

/// Lightweight metadata model used for markers and shape placeholders.
class ShapeMeta {
  ShapeMeta({
    required this.lat,
    required this.lon,
    this.title,
    this.subtitle,
    this.id,
    this.shapeType,
  });

  double lat;
  double lon;
  String? title;
  String? subtitle;
  String? id;
  String? shapeType;

  LatLng get point => LatLng(lat, lon);

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lon': lon,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (id != null) 'id': id,
        if (shapeType != null) 'shapeType': shapeType,
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
      shapeType: m['shapeType']?.toString(),
    );
  }

  @override
  String toString() => toMap().toString();
}
