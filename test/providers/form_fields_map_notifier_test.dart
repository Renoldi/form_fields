import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/src/providers/form_fields_map_notifier.dart';

/// Characterization tests for the shape collections of [FormFieldsMapNotifier]
/// (polygons, polylines, circles, markers). They pin the observable behavior
/// that the notifier's public API promises, so the internal storage can be
/// refactored without changing it.
void main() {
  Polygon poly() => Polygon(points: const [LatLng(0, 0), LatLng(0, 1), LatLng(1, 1)]);
  Polyline line() => Polyline(points: const [LatLng(0, 0), LatLng(1, 1)]);
  CircleMarker circle() => CircleMarker(point: const LatLng(0, 0), radius: 5);
  Marker marker() => Marker(point: const LatLng(0, 0), child: const SizedBox());

  late FormFieldsMapNotifier notifier;

  setUp(() {
    notifier = FormFieldsMapNotifier()..attachController('test-controller');
  });

  tearDown(() {
    notifier.dispose();
  });

  group('mutations require an attached controller', () {
    test('adding a polygon without a controller throws StateError', () {
      final readOnly = FormFieldsMapNotifier();
      addTearDown(readOnly.dispose);
      expect(() => readOnly.addPolygon(poly()), throwsStateError);
    });

    test('removing a marker without a controller throws StateError', () {
      final readOnly = FormFieldsMapNotifier();
      addTearDown(readOnly.dispose);
      expect(() => readOnly.removeMarker('x'), throwsStateError);
    });
  });

  group('polygons', () {
    test('addPolygon returns a p-prefixed id and exposes the value', () {
      final p = poly();
      final id = notifier.addPolygon(p);

      expect(id, startsWith('p'));
      expect(notifier.getPolygon(id), same(p));
      expect(notifier.polygons, [p]);
      expect(notifier.polygonMap.keys, [id]);
    });

    test('addOrUpdatePolygon replaces the value under the same id', () {
      final id = notifier.addPolygon(poly());
      final replacement = poly();

      notifier.addOrUpdatePolygon(id, replacement);

      expect(notifier.getPolygon(id), same(replacement));
      expect(notifier.polygons, hasLength(1));
    });

    test('removePolygon returns true once, then false', () {
      final id = notifier.addPolygon(poly());

      expect(notifier.removePolygon(id), isTrue);
      expect(notifier.removePolygon(id), isFalse);
      expect(notifier.polygons, isEmpty);
    });

    test('clearPolygons empties both the map and the list view', () {
      notifier.addPolygon(poly());
      notifier.addPolygon(poly());

      notifier.clearPolygons();

      expect(notifier.polygons, isEmpty);
      expect(notifier.polygonMap, isEmpty);
    });

    test('the polygons setter keys entries p0, p1, ... by index', () {
      final a = poly();
      final b = poly();

      notifier.polygons = [a, b];

      expect(notifier.polygonMap.keys, ['p0', 'p1']);
      expect(notifier.polygons, [a, b]);
    });

    test('polygonMap is a read-only view', () {
      notifier.addPolygon(poly());
      expect(() => notifier.polygonMap['x'] = poly(), throwsUnsupportedError);
    });
  });

  group('polylines', () {
    test('addPolyline returns an l-prefixed id; remove and clear behave', () {
      final id = notifier.addPolyline(line());

      expect(id, startsWith('l'));
      expect(notifier.getPolyline(id), isNotNull);
      expect(notifier.polylines, hasLength(1));

      expect(notifier.removePolyline(id), isTrue);
      notifier.addPolyline(line());
      notifier.clearPolylines();
      expect(notifier.polylines, isEmpty);
    });

    test('the polylines setter keys entries l0, l1, ... by index', () {
      notifier.polylines = [line(), line()];
      expect(notifier.polylineMap.keys, ['l0', 'l1']);
    });
  });

  group('circles', () {
    test('addCircle returns a c-prefixed id; remove and clear behave', () {
      final id = notifier.addCircle(circle());

      expect(id, startsWith('c'));
      expect(notifier.getCircle(id), isNotNull);

      expect(notifier.removeCircle(id), isTrue);
      expect(notifier.removeCircle(id), isFalse);

      notifier.addCircle(circle());
      notifier.clearCircles();
      expect(notifier.circles, isEmpty);
    });

    test('the circles setter keys entries c0, c1, ... by index', () {
      notifier.circles = [circle(), circle()];
      expect(notifier.circleMap.keys, ['c0', 'c1']);
    });
  });

  group('markers', () {
    test('addMarker returns an m-prefixed id; addOrUpdate replaces it', () {
      final id = notifier.addMarker(marker());
      final replacement = marker();

      expect(id, startsWith('m'));
      notifier.addOrUpdateMarker(id, replacement);

      expect(notifier.getMarker(id), same(replacement));
      expect(notifier.markers, hasLength(1));
    });

    test('removeMarker returns true once, then false; clear empties', () {
      final id = notifier.addMarker(marker());

      expect(notifier.removeMarker(id), isTrue);
      expect(notifier.removeMarker(id), isFalse);

      notifier.addMarker(marker());
      notifier.clearMarkers();
      expect(notifier.markers, isEmpty);
    });

    test('the markers setter keeps every marker it is given', () {
      notifier.markers = [marker(), marker(), marker()];
      expect(notifier.markers, hasLength(3));
    });

    test('the markers setter works without a controller (current behavior)', () {
      final readOnly = FormFieldsMapNotifier();
      addTearDown(readOnly.dispose);

      readOnly.markers = [marker()];

      expect(readOnly.markers, hasLength(1));
    });
  });

  group('notifications', () {
    test('a mutation notifies listeners once after the debounce window', () async {
      var calls = 0;
      notifier.addListener(() => calls++);

      notifier.addPolygon(poly());
      notifier.addPolygon(poly());
      expect(calls, 0, reason: 'notification is debounced');

      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(calls, 1);
    });
  });
}
