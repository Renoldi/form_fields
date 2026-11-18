import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/src/controllers/map_controller.dart';

/// Characterization tests for the static [FormFieldsMapController] API.
///
/// They pin how calls behave for a map id that has no notifier yet, and for
/// ids that do. The controller is refactored internally, so these tests must
/// keep passing without edits.
void main() {
  Polygon poly() => Polygon(points: const [LatLng(0, 0), LatLng(0, 1), LatLng(1, 1)]);
  Polyline line() => Polyline(points: const [LatLng(0, 0), LatLng(1, 1)]);
  CircleMarker circle() => CircleMarker(point: const LatLng(0, 0), radius: 5);
  Marker marker() => Marker(point: const LatLng(0, 0), child: const SizedBox());

  var seq = 0;
  String freshId() => 'shape_test_${seq++}';

  group('adding shapes creates the notifier when the id is unknown', () {
    test('addPolygon creates a notifier and returns an id', () {
      final id = freshId();
      final pid = FormFieldsMapController.addPolygon(id, poly());

      expect(pid, isNotNull);
      expect(FormFieldsMapController.getNotifier(id), isNotNull);
      expect(FormFieldsMapController.getNotifier(id)!.polygons, hasLength(1));
      addTearDown(() => FormFieldsMapController.remove(id));
    });

    test('addPolyline, addCircle, and addMarker each create a notifier', () {
      final id = freshId();
      addTearDown(() => FormFieldsMapController.remove(id));

      expect(FormFieldsMapController.addPolyline(id, line()), isNotNull);
      expect(FormFieldsMapController.addCircle(id, circle()), isNotNull);
      expect(FormFieldsMapController.addMarker(id, marker()), isNotNull);

      final n = FormFieldsMapController.getNotifier(id)!;
      expect(n.polylines, hasLength(1));
      expect(n.circles, hasLength(1));
      expect(n.markers, hasLength(1));
    });
  });

  group('updates on unknown ids do not create anything', () {
    test('addOrUpdatePolygon and clearPolygons are no-ops', () {
      final id = freshId();

      FormFieldsMapController.addOrUpdatePolygon(id, 'p1', poly());
      FormFieldsMapController.clearPolygons(id);

      expect(FormFieldsMapController.getNotifier(id), isNull);
    });

    test('removePolygon returns false for an unknown id', () {
      expect(FormFieldsMapController.removePolygon(freshId(), 'nope'), isFalse);
    });

    test('removeMarker returns false for an unknown id', () {
      expect(FormFieldsMapController.removeMarker(freshId(), 'nope'), isFalse);
    });

    test('getCenter returns null for an unknown id', () {
      expect(FormFieldsMapController.getCenter(freshId()), isNull);
    });
  });

  group('operations on a known id', () {
    test('addOrUpdatePolygon replaces a polygon and removePolygon reports it', () {
      final id = freshId();
      addTearDown(() => FormFieldsMapController.remove(id));
      final pid = FormFieldsMapController.addPolygon(id, poly())!;

      FormFieldsMapController.addOrUpdatePolygon(id, pid, poly());
      expect(FormFieldsMapController.getNotifier(id)!.polygons, hasLength(1));

      expect(FormFieldsMapController.removePolygon(id, pid), isTrue);
      expect(FormFieldsMapController.removePolygon(id, pid), isFalse);
    });

    test('clearPolygons empties the polygon layer', () {
      final id = freshId();
      addTearDown(() => FormFieldsMapController.remove(id));
      FormFieldsMapController.addPolygon(id, poly());
      FormFieldsMapController.addPolygon(id, poly());

      FormFieldsMapController.clearPolygons(id);

      expect(FormFieldsMapController.getNotifier(id)!.polygons, isEmpty);
    });

    test('removeMarker removes the marker it was given', () {
      final id = freshId();
      addTearDown(() => FormFieldsMapController.remove(id));
      final mid = FormFieldsMapController.addMarker(id, marker())!;

      expect(FormFieldsMapController.removeMarker(id, mid), isTrue);
      expect(FormFieldsMapController.removeMarker(id, mid), isFalse);
    });
  });

  group('raw markers and loading state', () {
    test('setRawMarkers with an unknown id creates the notifier', () {
      final id = freshId();
      addTearDown(() => FormFieldsMapController.remove(id));

      FormFieldsMapController.setRawMarkers(id, const []);

      expect(FormFieldsMapController.getNotifier(id), isNotNull);
      expect(FormFieldsMapController.getRawMarkers(id), isEmpty);
    });

    test('getRawMarkers returns an empty list for an unknown id', () {
      expect(FormFieldsMapController.getRawMarkers(freshId()), isEmpty);
    });

    test('setLoading updates the loading listenable', () {
      final id = freshId();
      addTearDown(() => FormFieldsMapController.remove(id));
      final listenable = FormFieldsMapController.getLoadingListenable(id);

      FormFieldsMapController.setLoading(id, true);
      expect(listenable.value, isTrue);

      FormFieldsMapController.setLoading(id, false);
      expect(listenable.value, isFalse);
    });
  });
}
