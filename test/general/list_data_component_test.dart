import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/general/list_data.dart';

void main() {
  testWidgets('the component builds without a controller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ListDataComponent<String>())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the component builds with a controller it was given', (
    tester,
  ) async {
    final controller = ListDataComponentController<String>();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ListDataComponent<String>(controller: controller)),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the sort menu is shown only when sortFields are given', (
    tester,
  ) async {
    Future<List<String>> source(int offset, String? search) async => ['b', 'a'];
    final sortable = ListDataSortField<String>(
      key: 'name',
      label: 'Name',
      valueOf: (item) => item,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListDataComponent<String>(
            dataSource: source,
            itemBuilder: (item, index) => Text(item ?? '', key: ValueKey(item)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListDataComponent<String>(
            dataSource: source,
            sortFields: [sortable],
            itemBuilder: (item, index) => Text(item ?? '', key: ValueKey(item)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a data source given on a later build is the one used', (
    tester,
  ) async {
    final controller = ListDataComponentController<String>();
    addTearDown(controller.dispose);
    Future<List<String>> first(int offset, String? search) async => ['old'];
    Future<List<String>> second(int offset, String? search) async => ['new'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListDataComponent<String>(
            controller: controller,
            dataSource: first,
            autoLoad: false,
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListDataComponent<String>(
            controller: controller,
            dataSource: second,
            autoLoad: false,
          ),
        ),
      ),
    );

    expect(controller.value.dataSource, same(second));
  });
}
