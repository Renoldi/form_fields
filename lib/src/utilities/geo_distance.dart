import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Shortest distance in meters from [p] to the segment [a]-[b].
///
/// Uses a local flat projection around [a]. That is accurate enough for the
/// short thresholds used by map hit-testing, a few hundred meters at most.
double distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  final cosLat = cos(a.latitude * pi / 180.0);

  double projectX(LatLng q) =>
      (q.longitude - a.longitude) * pi / 180.0 * cosLat * earthRadius;
  double projectY(LatLng q) =>
      (q.latitude - a.latitude) * pi / 180.0 * earthRadius;

  final px = projectX(p);
  final py = projectY(p);
  final bx = projectX(b);
  final by = projectY(b);

  // `a` projects to the origin, so the segment runs from (0, 0) to (bx, by).
  final lengthSquared = bx * bx + by * by;
  final t = lengthSquared == 0
      ? 0.0
      : ((px * bx + py * by) / lengthSquared).clamp(0.0, 1.0).toDouble();
  final dx = px - bx * t;
  final dy = py - by * t;
  return sqrt(dx * dx + dy * dy);
}

/// Initial bearing in degrees, clockwise from north, from [from] to [to].
/// Always in the range [0, 360).
double bearingDegrees(LatLng from, LatLng to) {
  final lat1 = from.latitude * pi / 180.0;
  final lat2 = to.latitude * pi / 180.0;
  final dLon = (to.longitude - from.longitude) * pi / 180.0;
  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  return (atan2(y, x) * 180.0 / pi + 360.0) % 360.0;
}
