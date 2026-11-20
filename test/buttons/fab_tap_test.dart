import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/buttons/app_button.dart';

void main() {
  testWidgets('FAB and extended FAB respond to taps', (tester) async {
    var fab = 0, ext = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 12, children: [
            AppButton(type: AppButtonType.fab, size: AppSize.medium,
                icon: const Icon(Icons.add), onPressed: () => fab++),
            AppButton(type: AppButtonType.extendedFab, text: 'Extended FAB',
                icon: const Icon(Icons.add_task_outlined), onPressed: () => ext++),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(fab, 1, reason: 'fab tap');

    await tester.tap(find.text('Extended Fab'));
    await tester.pumpAndSettle();
    expect(ext, 1, reason: 'extended fab tap');
  });
}
