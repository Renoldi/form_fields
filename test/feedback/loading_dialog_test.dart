import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/feedback/app_dialog_service.dart';

void main() {
  testWidgets(
    'a loading dialog shown by one service instance is closed by another',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      // Each call in the app creates a new AppDialogService.
      AppDialogService(context).unguardedLoadingVisualOnly(show: true);
      await tester.pump(const Duration(milliseconds: 300));
      expect(Navigator.of(context).canPop(), isTrue);

      AppDialogService(context).unguardedLoadingVisualOnly(show: false);
      // The spinner never settles, so pumpAndSettle would not return. Pump
      // a fixed time instead.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(Navigator.of(context).canPop(), isFalse);
    },
  );
}
