import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/shape_meta.dart';

/// Lightweight reusable geocoding helper used by the package.
/// Provides a simple search and reverse-geocode API returning
/// minimal objects (no dependency on UI models).
class GeocodingService {
  /// Upper bound for a single platform geocoding or location call. Platform
  /// services can stall indefinitely, which would leave callers waiting.
  static const Duration _lookupTimeout = Duration(seconds: 15);

  /// Created on first use. The constructor reaches into the platform
  /// implementation. Creating it eagerly made building a map fail on platforms
  /// without one, even if no search was ever made.
  Geocoding? _geocodingInstance;
  Geocoding get _geocoding => _geocodingInstance ??= Geocoding();

  /// Resolve an address string into a list of [PointMeta].
  ///
  /// This will try to produce a human-readable `address` using
  /// reverse-geocoding on each resolved coordinate where possible.
  Future<List<PointMeta>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final locs = await _geocoding
          .locationFromAddress(query)
          .timeout(_lookupTimeout);
      final out = <PointMeta>[];
      for (final l in locs) {
        final address = await _addressAt(l.latitude, l.longitude) ?? query;
        out.add(PointMeta(lat: l.latitude, lon: l.longitude, address: address));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Reverse-geocode a `LatLng` into a human-readable address if possible.
  Future<String?> reverse(LatLng point) =>
      _addressAt(point.latitude, point.longitude);

  /// Reverse-geocode into a `PointMeta` containing lat/lon and address.
  Future<PointMeta?> reverseToPointMeta(LatLng point) async {
    try {
      final pls = await _placemarksAt(point.latitude, point.longitude);
      final best = _selectBestPlacemark(pls);
      if (best == null) return null;
      return PointMeta(
        lat: point.latitude,
        lon: point.longitude,
        address: _formatAddress(best),
      );
    } catch (_) {
      return null;
    }
  }

  /// Obtain the device's current geolocation as a minimal `PointMeta`.
  /// Returns `null` if permissions are denied, location services are
  /// disabled, the position cannot be obtained in time, or any other error
  /// occurs.
  Future<PointMeta?> currentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition().timeout(_lookupTimeout);
      return PointMeta(lat: pos.latitude, lon: pos.longitude, address: '');
    } catch (_) {
      return null;
    }
  }

  /// Alias of [currentLocation], kept for existing callers.
  Future<PointMeta?> getCurrentLocation() => currentLocation();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<Placemark>> _placemarksAt(double lat, double lon) =>
      _geocoding.placemarkFromCoordinates(lat, lon).timeout(_lookupTimeout);

  /// Human-readable address for a coordinate, or null when none is available.
  Future<String?> _addressAt(double lat, double lon) async {
    try {
      final best = _selectBestPlacemark(await _placemarksAt(lat, lon));
      if (best == null) return null;
      final addr = _formatAddress(best);
      return addr.isEmpty ? null : addr;
    } catch (_) {
      return null;
    }
  }

  static String _formatAddress(Placemark p) {
    return [
      p.name,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.country,
    ].where((s) => (s ?? '').trim().isNotEmpty).join(', ');
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
    return [
      p.name,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.country,
    ].where((s) => (s ?? '').trim().isNotEmpty).length;
  }
}
