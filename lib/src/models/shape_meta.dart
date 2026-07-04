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
  });

  double lat;
  double lon;
  String? title;
  String? subtitle;
  String? id;
  String? address;
  double? rotation;
  String? shapeType;

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
    );
  }

  @override
  String toString() => toMap().toString();
}
