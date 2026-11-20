import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/fields/selection/form_fields_checkbox.dart';
import 'package:form_fields/src/fields/selection/form_fields_radio_button.dart';
import 'package:form_fields/src/localization/form_fields_localizations.dart';
import 'package:form_fields/src/utilities/enums.dart';

Widget _app({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      FormFieldsLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// Localizations load asynchronously, so the first frame is not enough.
Future<void> _load(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Labels for `inBorder` and `none` are drawn by the container, not beside it.
bool _showsLabel(LabelPosition position) {
  return position != LabelPosition.inBorder && position != LabelPosition.none;
}

/// Finds a [Text] or [RichText] whose plain text contains [s]. Labels use
/// [RichText] so the required asterisk can be styled.
Finder _containsText(String s) {
  return find.byWidgetPredicate((w) {
    if (w is Text) return (w.data ?? '').contains(s);
    if (w is RichText) return w.text.toPlainText().contains(s);
    return false;
  });
}

void main() {
  group('FormFieldsCheckbox', () {
    testWidgets('tapping an item adds it, tapping again removes it', (
      tester,
    ) async {
      List<String>? last;
      await _load(
        tester,
        _app(
          child: StatefulBuilder(
            builder: (context, setState) {
              return FormFieldsCheckbox<String>(
                label: 'fruits',
                items: const ['Apple', 'Banana'],
                initialValue: const [],
                onChanged: (value) => setState(() => last = value),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Apple'));
      await tester.pump();
      expect(last, ['Apple']);

      await tester.tap(find.text('Apple'));
      await tester.pump();
      expect(last, isEmpty);
    });

    testWidgets('readOnly does not change the selection', (tester) async {
      var calls = 0;
      await _load(
        tester,
        _app(
          child: FormFieldsCheckbox<String>(
            label: 'fruits',
            items: const ['Apple'],
            readOnly: true,
            onChanged: (_) => calls++,
          ),
        ),
      );

      await tester.tap(find.text('Apple'));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('required with nothing selected shows the error', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await _load(
        tester,
        _app(
          child: Form(
            key: formKey,
            child: FormFieldsCheckbox<String>(
              label: 'fruits',
              items: const ['Apple'],
              isRequired: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Please select at least one Fruits'), findsOneWidget);
    });

    testWidgets('renders in every label position', (tester) async {
      for (final position in LabelPosition.values) {
        await _load(
          tester,
          _app(
            child: FormFieldsCheckbox<String>(
              label: 'fruits',
              items: const ['Apple'],
              labelPosition: position,
              onChanged: (_) {},
            ),
          ),
        );
        if (_showsLabel(position)) {
          expect(
            _containsText('Fruits'),
            findsWidgets,
            reason: 'label position $position',
          );
        }
        expect(tester.takeException(), isNull, reason: '$position');
      }
    });
  });

  group('FormFieldsRadioButton', () {
    testWidgets('tapping an item reports the chosen value', (tester) async {
      String? last;
      await _load(
        tester,
        _app(
          child: StatefulBuilder(
            builder: (context, setState) {
              return FormFieldsRadioButton<String>(
                label: 'fruit',
                items: const ['Apple', 'Banana'],
                onChanged: (value) => setState(() => last = value),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Banana'));
      await tester.pump();
      expect(last, 'Banana');
    });

    testWidgets('renders sections with their titles', (tester) async {
      await _load(
        tester,
        _app(
          child: FormFieldsRadioButton<String>(
            label: 'fruit',
            sections: const {
              'Red': ['Apple'],
              'Yellow': ['Banana'],
            },
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Yellow'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('required with nothing selected shows the error', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await _load(
        tester,
        _app(
          child: Form(
            key: formKey,
            child: FormFieldsRadioButton<String>(
              label: 'fruit',
              items: const ['Apple'],
              isRequired: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Please select Fruit'), findsOneWidget);
    });

    testWidgets('renders in every label position', (tester) async {
      for (final position in LabelPosition.values) {
        await _load(
          tester,
          _app(
            child: FormFieldsRadioButton<String>(
              label: 'fruit',
              items: const ['Apple'],
              labelPosition: position,
              onChanged: (_) {},
            ),
          ),
        );
        if (_showsLabel(position)) {
          expect(
            _containsText('Fruit'),
            findsWidgets,
            reason: 'label position $position',
          );
        }
        expect(tester.takeException(), isNull, reason: '$position');
      }
    });
  });
}
