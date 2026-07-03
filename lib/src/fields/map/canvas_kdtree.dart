import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';

class _KDPoint {
  _KDPoint(this.x, this.y, this.payload);
  final double x;
  final double y;
  final dynamic payload;
}

class _KDNode {
  _KDNode(this.point, this.left, this.right);
  final _KDPoint point;
  final _KDNode? left;
  final _KDNode? right;
}

/// Simple 2D KD-tree for fast nearest-neighbor queries in world/pixel space.
class KDTree {
  // Private constructor: callers should use `buildKDTreeFromMarkers` which
  // accepts public types and builds the necessary `_KDPoint` list.
  KDTree._fromPoints(List<_KDPoint> points) : _root = _build(points, 0);

  final _KDNode? _root;

  static _KDNode? _build(List<_KDPoint> pts, int depth) {
    if (pts.isEmpty) return null;
    final axis = depth % 2; // 0:x, 1:y
    pts.sort((a, b) => (axis == 0 ? a.x.compareTo(b.x) : a.y.compareTo(b.y)));
    final mid = pts.length >> 1;
    final left = pts.sublist(0, mid);
    final right = pts.sublist(mid + 1);
    return _KDNode(pts[mid], _build(left, depth + 1), _build(right, depth + 1));
  }

  /// Returns the nearest payload (Marker or LatLng) to (qx,qy) within
  /// maxDist (inclusive), or null.
  dynamic nearest(double qx, double qy, double maxDist) {
    double bestDist2 = maxDist * maxDist;
    dynamic bestPayload;

    void search(_KDNode? node, int depth) {
      if (node == null) return;
      final px = node.point.x;
      final py = node.point.y;
      final dx = px - qx;
      final dy = py - qy;
      final d2 = dx * dx + dy * dy;
      if (d2 <= bestDist2) {
        bestDist2 = d2;
        bestPayload = node.point.payload;
      }

      final axis = depth % 2;
      final delta = (axis == 0) ? (qx - px) : (qy - py);
      final first = delta <= 0 ? node.left : node.right;
      final second = delta <= 0 ? node.right : node.left;

      search(first, depth + 1);
      if (delta * delta <= bestDist2) search(second, depth + 1);
    }

    search(_root, 0);
    return bestPayload;
  }
}

/// Helper to build KDTree from a list of markers at a given zoom using
/// world pixel projection functions supplied by the caller.
KDTree buildKDTreeFromMarkers(
    List<Marker> markers,
    double zoom,
    double Function(double lon, double zoom) worldX,
    double Function(double lat, double zoom) worldY) {
  final pts = <_KDPoint>[];
  for (final m in markers) {
    final x = worldX(m.point.longitude, zoom);
    final y = worldY(m.point.latitude, zoom);
    pts.add(_KDPoint(x, y, m));
  }
  return KDTree._fromPoints(pts);
}

/// Helper to build KDTree from raw coordinate pairs `[lat, lon]`.
KDTree buildKDTreeFromRawCoords(
    List<dynamic> coords,
    double zoom,
    double Function(double lon, double zoom) worldX,
    double Function(double lat, double zoom) worldY) {
  final pts = <_KDPoint>[];
  for (final c in coords) {
    double lat;
    double lon;
    dynamic payload = c;
    if (c is Marker) {
      lat = c.point.latitude;
      lon = c.point.longitude;
      payload = c;
    } else if (c is LatLng) {
      lat = c.latitude;
      lon = c.longitude;
      payload = c;
    } else if (c is List && c.length >= 2) {
      lat = (c[0] as num).toDouble();
      lon = (c[1] as num).toDouble();
      payload = c;
    } else if (c is ShapeMeta) {
      lat = c.lat;
      lon = c.lon;
      payload = c;
    } else if (c is Map) {
      // support {'lat': ..., 'lon': ..., 'title': ..., 'subtitle': ...}
      lat = (c['lat'] as num?)?.toDouble() ??
          (c['latitude'] as num?)?.toDouble() ??
          0.0;
      lon = (c['lon'] as num?)?.toDouble() ??
          (c['longitude'] as num?)?.toDouble() ??
          0.0;
      payload = c;
    } else {
      // Unknown type — skip
      continue;
    }
    final x = worldX(lon, zoom);
    final y = worldY(lat, zoom);
    pts.add(_KDPoint(x, y, payload));
  }
  return KDTree._fromPoints(pts);
}
