import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/models/shape_meta.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('a null or text entry in pointMetas is skipped, the valid points stay', () {
    final shape = ShapeMeta.fromMap({
      'id': 'zone-1',
      'shapeType': 'polygon',
      'pointMetas': [
        {'lat': -6.2, 'lon': 106.8},
        null,
        'not a point',
        {'lat': -6.3, 'lon': 106.9},
      ],
    });

    expect(shape.id, 'zone-1');
    expect(shape.pointMetas, hasLength(2));
    expect(shape.pointMetas!.first.lat, -6.2);
    expect(shape.pointMetas!.last.lon, 106.9);
  });

  test('LatLng entries in pointMetas are accepted', () {
    final shape = ShapeMeta.fromMap({
      'pointMetas': [const LatLng(-6.2, 106.8)],
    });

    expect(shape.pointMetas!.single.lat, -6.2);
    expect(shape.pointMetas!.single.lon, 106.8);
  });
}
