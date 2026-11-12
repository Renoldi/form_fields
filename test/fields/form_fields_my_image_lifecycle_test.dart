import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';

/// Counts attached listeners. `ChangeNotifier.hasListeners` is protected, so
/// the count is kept here instead.
class _TrackedController extends FormFieldsMyImageController {
  int listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }
}

Widget _host(FormFieldsMyImageController? controller) {
  return MaterialApp(
    home: Scaffold(
      body: FormFieldsMyImage(controller: controller, label: 'Photo'),
    ),
  );
}

void main() {
  testWidgets('detaching a controller stops listening to it', (tester) async {
    final first = _TrackedController();
    addTearDown(first.dispose);

    await tester.pumpWidget(_host(first));
    // The widget listens twice: its own handler and the OfflineUploadManager.
    expect(first.listeners, 2);

    await tester.pumpWidget(_host(null));
    await tester.pump();

    // The widget must not keep writing into a controller the parent gave up.
    expect(first.listeners, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swapping to another controller moves the listener over', (
    tester,
  ) async {
    final first = _TrackedController();
    final second = _TrackedController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(_host(first));
    await tester.pumpWidget(_host(second));
    await tester.pump();

    expect(first.listeners, 0);
    expect(second.listeners, 2);
  });

  testWidgets('disposing the widget releases the attached controller', (
    tester,
  ) async {
    final controller = _TrackedController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(controller));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(controller.listeners, 0);
    expect(tester.takeException(), isNull);
  });
}
