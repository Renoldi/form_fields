import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/fields/core/form_fields_signature_pad.dart';
import 'package:signature/signature.dart';

Widget _app(ThemeData theme) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: FormFieldsSignaturePad(
        height: 200,
        // Auto-export would leave a debounce timer behind in the test.
        autoExportOnFinish: false,
      ),
    ),
  );
}

SignatureController _controllerOf(WidgetTester tester) {
  return tester.widget<Signature>(find.byType(Signature)).controller;
}

void main() {
  testWidgets('a theme change keeps the strokes drawn so far', (tester) async {
    await tester.pumpWidget(_app(ThemeData.light()));
    await tester.pump();

    await tester.dragFrom(
      tester.getCenter(find.byType(Signature)),
      const Offset(80, 40),
    );
    await tester.pump();
    final drawn = _controllerOf(tester).points.length;
    expect(drawn, greaterThan(0), reason: 'the stroke was recorded');

    // A theme change gives the pad a new SignatureController, because the
    // pen color is fixed per controller. The strokes must come along.
    await tester.pumpWidget(_app(ThemeData.dark()));
    await tester.pump();

    expect(_controllerOf(tester).points.length, drawn);
  });

  testWidgets('a rebuild without a color change keeps the same controller', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ThemeData.light()));
    await tester.pump();
    final first = _controllerOf(tester);

    await tester.pumpWidget(_app(ThemeData.light()));
    await tester.pump();

    expect(identical(_controllerOf(tester), first), isTrue);
  });
}
