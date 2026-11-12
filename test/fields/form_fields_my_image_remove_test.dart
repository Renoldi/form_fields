import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';

void main() {
  testWidgets(
    'removing an image reports the new list through onImagesChanged',
    (tester) async {
      final first = MyImageResult(path: '/nonexistent/first.jpg');
      final second = MyImageResult(path: '/nonexistent/second.jpg');
      final controller = FormFieldsMyImageController(
        initialImages: [first, second],
      );
      addTearDown(controller.dispose);

      final removed = <int>[];
      List<MyImageResult>? reported;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormFieldsMyImage(
                controller: controller,
                label: 'Photos',
                onRemoveImage: (index, _) => removed.add(index),
                onImagesChanged: (images) => reported = images,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(removed, [0]);
      // Before the fix the parent was never told about the removal, so it
      // kept the removed image.
      expect(reported, isNotNull);
      expect(reported!.map((i) => i.path), ['/nonexistent/second.jpg']);
    },
  );
}
