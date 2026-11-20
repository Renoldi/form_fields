part of '../form_fields_map.dart';

extension _FormFieldsMapDataX on FormFieldsMapState {
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
