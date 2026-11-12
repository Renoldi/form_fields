import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';

/// A valid 1x1 transparent PNG.
final Uint8List _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81,
  0x84, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<void> _pumpMap(
  WidgetTester tester, {
  FormFieldsMapMapConfig? mapConfig,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FormFieldsMap(
          // No network: tiles fail quietly and do not matter in these tests.
          tileUrlTemplate: 'http://127.0.0.1:1/{z}/{x}/{y}.png',
          mapConfig: mapConfig,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // Building the map must not touch platform services. The geocoding service
  // used to create its platform object in initState, which failed wherever
  // that platform implementation is missing.
  testWidgets('a map builds without any marker icon', (tester) async {
    await _pumpMap(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a map whose marker icon is an image provider builds', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      mapConfig: FormFieldsMapMapConfig(canvasMarkerIcon: MemoryImage(_pixel)),
    );

    expect(tester.takeException(), isNull);
  });
}
