import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/fields/autocomplete/form_fields_autocomplete.dart';

void main() {
  testWidgets('a slow answer to an old query does not replace a newer one', (
    tester,
  ) async {
    // Two searches are in flight: 'a' and then 'ab'. The answer to 'ab' comes
    // back first, and the answer to 'a' arrives later.
    final pending = <String, Completer<List<String>>>{};
    Future<List<String>> fetch(String query) {
      final c = Completer<List<String>>();
      pending[query] = c;
      return c.future;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormFieldsAutocomplete<String>(
            fieldLabel: 'City',
            apiUrl: '',
            preferLocalOnly: true,
            localFetcher: fetch,
            onItemSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();

    pending['ab']!.complete(['Abu Dhabi']);
    await tester.pump();
    pending['a']!.complete(['Amsterdam']);
    await tester.pump();

    expect(
      find.text('Amsterdam'),
      findsNothing,
      reason: 'results for "a" must not show for the input "ab"',
    );
    expect(find.text('Abu Dhabi'), findsOneWidget);
  });
}
