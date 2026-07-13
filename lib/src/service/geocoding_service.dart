import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../models/shape_meta.dart';

/// Lightweight reusable geocoding helper used by the package.
/// Provides a simple search and reverse-geocode API returning
/// minimal objects (no dependency on UI models).
class GeocodingService {
  final Geocoding _geocoding = Geocoding();

  /// Resolve an address string into a list of [PointMeta].
  ///
  /// This will try to produce a human-readable `address` using
  /// reverse-geocoding on each resolved coordinate where possible.
  Future<List<PointMeta>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final locs = await _geocoding.locationFromAddress(query);
      final out = <PointMeta>[];
      for (final l in locs) {
        String addr = query;
        try {
          final pls = await _geocoding.placemarkFromCoordinates(
            l.latitude,
            l.longitude,
          );
          final p = _selectBestPlacemark(pls);
          if (p != null) {
            final parts = <String?>[
              p.name,
              p.subLocality,
              p.locality,
              p.administrativeArea,
              p.country,
            ];
            addr = parts.where((s) => (s ?? '').isNotEmpty).join(', ');
          }
        } catch (_) {}
        out.add(PointMeta(lat: l.latitude, lon: l.longitude, address: addr));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Reverse-geocode a `LatLng` into a human-readable address if possible.
  Future<String?> reverse(LatLng point) async {
    try {
      final pls = await _geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (pls.isEmpty) return null;
      final p = _selectBestPlacemark(pls);
      if (p == null) return null;
      final parts = <String?>[
        p.name,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ];
      final addr = parts.where((s) => (s ?? '').isNotEmpty).join(', ');
      return addr.isEmpty ? null : addr;
    } catch (_) {
      return null;
    }
  }

  /// Reverse-geocode into a `PointMeta` containing lat/lon and address.
  Future<PointMeta?> reverseToPointMeta(LatLng point) async {
    try {
      final pls = await _geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      final p = _selectBestPlacemark(pls);
      if (p == null) return null;
      final parts = <String?>[
        p.name,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ];
      final addr = parts.where((s) => (s ?? '').isNotEmpty).join(', ');
      return PointMeta(
        lat: point.latitude,
        lon: point.longitude,
        address: addr,
      );
    } catch (_) {
      return null;
    }
  }

  Placemark? _selectBestPlacemark(List<Placemark> pls) {
    if (pls.isEmpty) return null;
    Placemark best = pls.first;
    int bestScore = _placemarkScore(best);
    for (final p in pls.skip(1)) {
      final s = _placemarkScore(p);
      if (s > bestScore) {
        best = p;
        bestScore = s;
      }
    }
    return best;
  }

  int _placemarkScore(Placemark p) {
    final fields = [
      p.name,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.country,
    ];
    return fields.where((s) => (s ?? '').trim().isNotEmpty).length;
  }
}
