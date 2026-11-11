import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/models/shape_meta.dart';

void main() {
  group('ShapeMeta.parseColor', () {
    test('#RRGGBB is opaque, not transparent', () {
      expect(ShapeMeta.parseColor('#FF0000'), const Color(0xFFFF0000));
      expect(ShapeMeta.parseColor('#FF0000')!.toARGB32() >>> 24, 0xFF);
    });

    test('#AARRGGBB keeps its alpha', () {
      expect(ShapeMeta.parseColor('#80112233'), const Color(0x80112233));
    });

    test('0xAARRGGBB strings are read as hex', () {
      expect(ShapeMeta.parseColor('0xFF112233'), const Color(0xFF112233));
    });

    test('a plain decimal string still parses as a decimal', () {
      expect(ShapeMeta.parseColor('123456'), const Color(0x0001E240));
    });

    test('an int and a Color pass through unchanged', () {
      expect(ShapeMeta.parseColor(0xFF00FF00), const Color(0xFF00FF00));
      expect(
        ShapeMeta.parseColor(const Color(0xFF0000FF)),
        const Color(0xFF0000FF),
      );
    });

    test('invalid or null input returns null', () {
      expect(ShapeMeta.parseColor('not-a-color'), isNull);
      expect(ShapeMeta.parseColor(null), isNull);
    });
  });
}
