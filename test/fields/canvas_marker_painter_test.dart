import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/fields/map/canvas_raw_marker_painter.dart';
import 'package:latlong2/latlong.dart';

void main() {
  CanvasRawMarkerPainter painterFor(List<dynamic> markers) {
    return CanvasRawMarkerPainter(
      rawMarkers: markers,
      center: LatLng(-6.2, 106.8),
      zoom: 12,
      radius: 8,
      devicePixelRatio: 1,
      defaultColor: Colors.blue,
    );
  }

  void paintOn(CanvasRawMarkerPainter painter) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
    painter.paint(canvas, const Size(400, 400));
    recorder.endRecording().dispose();
  }

  test('a malformed marker does not stop the others from painting', () {
    final painter = painterFor([
      ['not', 'a number'],
      {'lat': 'x', 'lon': null},
      [-6.2, 106.8],
      {'lat': -6.21, 'lon': 106.81},
    ]);

    expect(() => paintOn(painter), returnsNormally);
  });

  test('entries with a non-finite coordinate are skipped', () {
    final painter = painterFor([
      [double.nan, 106.8],
      [-6.2, double.infinity],
    ]);

    expect(() => paintOn(painter), returnsNormally);
  });
}
