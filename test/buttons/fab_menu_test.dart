import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/buttons/app_fab_menu.dart';
import 'package:form_fields/src/buttons/app_button.dart';

void main() {
  testWidgets('expandable FAB opens, runs an item, and closes', (tester) async {
    var first = 0, second = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.centerRight,
          child: AppFabMenu(
            size: AppSize.small,
            items: [
              AppFabMenuItem(label: 'First', icon: const Icon(Icons.looks_one_outlined), onPressed: () => first++),
              AppFabMenuItem(label: 'Second', icon: const Icon(Icons.looks_two_outlined), onPressed: () => second++),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('First'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'open');
    expect(find.text('First'), findsOneWidget, reason: 'items should show after opening');

    await tester.tap(find.byIcon(Icons.looks_two_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'item tap');
    expect(second, 1, reason: 'item callback');
    expect(first, 0);
    expect(find.text('First'), findsNothing, reason: 'menu closes after an item');
  });
}
