import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/utilities/enums.dart';
import 'package:form_fields/src/widgets/form_field_label.dart';

const _childKey = Key('child');

Future<void> _pump(
  WidgetTester tester, {
  String? label,
  LabelPosition position = LabelPosition.top,
  bool isRequired = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FormFieldLabelLayout(
          label: label,
          labelPosition: position,
          isRequired: isRequired,
          child: const SizedBox(key: _childKey, width: 10, height: 10),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('returns only the child when the label is null or blank', (
    tester,
  ) async {
    await _pump(tester, label: null);
    expect(find.byKey(_childKey), findsOneWidget);
    expect(find.byType(RichText), findsNothing);

    await _pump(tester, label: '');
    expect(find.byKey(_childKey), findsOneWidget);
    expect(find.byType(RichText), findsNothing);
  });

  testWidgets('returns only the child when the position is none', (
    tester,
  ) async {
    await _pump(tester, label: 'email', position: LabelPosition.none);
    expect(find.byKey(_childKey), findsOneWidget);
    expect(find.byType(RichText), findsNothing);
  });

  testWidgets('title-cases the label text', (tester) async {
    await _pump(tester, label: 'email address');
    expect(_labelFinder('Email Address'), findsOneWidget);
  });

  testWidgets('appends a red asterisk when the field is required', (
    tester,
  ) async {
    await _pump(tester, label: 'email', isRequired: true);
    expect(_labelFinder('*'), findsOneWidget);
  });

  testWidgets('no asterisk when the field is optional', (tester) async {
    await _pump(tester, label: 'email');
    expect(_labelFinder('*'), findsNothing);
  });

  for (final position in [
    LabelPosition.top,
    LabelPosition.bottom,
    LabelPosition.left,
    LabelPosition.right,
  ]) {
    testWidgets('renders label and child for ${position.name}', (tester) async {
      await _pump(tester, label: 'name', position: position);
      expect(_labelFinder('Name'), findsOneWidget);
      expect(find.byKey(_childKey), findsOneWidget);
    });
  }

  testWidgets('inBorder position renders the child without a separate label', (
    tester,
  ) async {
    await _pump(tester, label: 'name', position: LabelPosition.inBorder);
    expect(find.byKey(_childKey), findsOneWidget);
    expect(_labelFinder('Name'), findsNothing);
  });
}

/// Label text is rendered as [RichText] (so the required star can be styled
/// in red), which [find.text] does not match. Match on the plain text instead.
Finder _labelFinder(String text) => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().contains(text),
  description: 'label containing "$text"',
);
