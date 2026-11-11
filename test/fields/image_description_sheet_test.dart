import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/fields/core/form_fields_my_image_description_sheet.dart';
import 'package:form_fields/src/localization/form_fields_localizations.dart';

/// Counts every pop, so a second close of the sheet shows up as a number > 1.
class _PopCounter extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

/// Records the value the sheet is closed with. Tests read it after pumping,
/// rather than awaiting, so a sheet that never closes fails the test instead
/// of hanging it.
class _Outcome {
  bool closed = false;
  String? value;
}

Future<void> _openSheet(
  WidgetTester tester,
  _PopCounter counter,
  _Outcome outcome,
) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [counter],
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .push<String>(
                        MaterialPageRoute<String>(
                          // The app shows the sheet in a modal, which supplies the
                          // Material ancestor that text fields need.
                          builder: (_) =>
                              const Scaffold(body: ImageDescriptionSheet()),
                        ),
                      )
                      .then((value) {
                        outcome
                          ..closed = true
                          ..value = value;
                      });
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // The sheet waits 250 ms before it asks for focus.
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

String _fieldText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  final cancelLabel = FormFieldsLocalizations.load(
    const Locale('en', 'US'),
  ).cancel;

  testWidgets('Enter closes the sheet once and returns the typed text', (
    tester,
  ) async {
    final counter = _PopCounter();
    final outcome = _Outcome();
    await _openSheet(tester, counter, outcome);
    final before = counter.pops;

    await tester.enterText(find.byType(EditableText), 'Foto ruang rapat');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(outcome.closed, isTrue);
    expect(outcome.value, 'Foto ruang rapat');
    expect(counter.pops - before, 1, reason: 'the sheet must close only once');
  });

  testWidgets('Backspace removes exactly one character while focused', (
    tester,
  ) async {
    final counter = _PopCounter();
    await _openSheet(tester, counter, _Outcome());

    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(_fieldText(tester), 'ab');
  });

  testWidgets('Cancel closes the sheet once and returns null', (tester) async {
    final counter = _PopCounter();
    final outcome = _Outcome();
    await _openSheet(tester, counter, outcome);
    final before = counter.pops;

    await tester.tap(find.text(cancelLabel));
    await tester.pumpAndSettle();

    expect(outcome.closed, isTrue);
    expect(outcome.value, isNull);
    expect(counter.pops - before, 1);
  });
}
