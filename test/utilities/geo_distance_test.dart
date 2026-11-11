import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/utilities/geo_distance.dart';
import 'package:latlong2/latlong.dart';

void main() {
  // One degree of longitude on the equator is about 111.2 km.
  final a = LatLng(0, 0);
  final b = LatLng(0, 1);

  test(
    'a point on a long segment, far from its midpoint, is at distance 0',
    () {
      // 0.1 degrees along, so about 11 km from the midpoint. The old
      // midpoint-based check missed this tap.
      expect(distanceToSegmentMeters(LatLng(0, 0.1), a, b), closeTo(0, 1e-6));
    },
  );

  test('a point beside the segment is measured perpendicular to it', () {
    // 0.001 degrees of latitude is about 111 m.
    final d = distanceToSegmentMeters(LatLng(0.001, 0.5), a, b);
    expect(d, closeTo(111.2, 1.0));
  });

  test('a point past an end is measured to that end', () {
    // 0.5 degrees past b, along the same line.
    final d = distanceToSegmentMeters(LatLng(0, 1.5), a, b);
    expect(d, closeTo(55600, 100));
  });

  test('a zero-length segment is measured to its single point', () {
    final d = distanceToSegmentMeters(LatLng(0.001, 0), a, a);
    expect(d, closeTo(111.2, 1.0));
  });

  group('bearingDegrees', () {
    final origin = LatLng(0, 0);

    test('points north, east, south and west at the cardinal bearings', () {
      expect(bearingDegrees(origin, LatLng(1, 0)), closeTo(0, 1e-6));
      expect(bearingDegrees(origin, LatLng(0, 1)), closeTo(90, 1e-6));
      expect(bearingDegrees(origin, LatLng(-1, 0)), closeTo(180, 1e-6));
      expect(bearingDegrees(origin, LatLng(0, -1)), closeTo(270, 1e-6));
    });

    test('the reverse direction is 180 degrees away', () {
      final forward = bearingDegrees(LatLng(-6.2, 106.8), LatLng(-6.1, 106.9));
      final back = bearingDegrees(LatLng(-6.1, 106.9), LatLng(-6.2, 106.8));
      expect(((forward - back).abs() - 180).abs(), lessThan(1.0));
    });

    test('the result is always in [0, 360)', () {
      final b = bearingDegrees(LatLng(10, 10), LatLng(9.5, 9.9));
      expect(b, greaterThanOrEqualTo(0));
      expect(b, lessThan(360));
    });
  });
}
