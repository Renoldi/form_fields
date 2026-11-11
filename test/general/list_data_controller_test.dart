import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/general/list_data.dart';

void main() {
  // commit() reads SchedulerBinding, so the binding must exist.
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  test(
    'disposing the list controller also disposes the controllers it owns',
    () {
      final controller = ListDataComponentController<String>();
      final scroll = controller.value.scrollController;
      final search = controller.value.searchController;

      controller.dispose();

      // ChangeNotifier asserts in debug builds when used after dispose().
      expect(() => scroll.addListener(() {}), throwsAssertionError);
      expect(() => search.addListener(() {}), throwsAssertionError);
    },
  );

  test('the controllers stay usable while the list controller is alive', () {
    final controller = ListDataComponentController<String>();
    addTearDown(controller.dispose);

    var calls = 0;
    controller.value.searchController.addListener(() => calls++);
    controller.value.searchController.text = 'abc';

    expect(calls, 1);
  });

  group('sorting', () {
    final byName = ListDataSortField<String>(
      key: 'name',
      label: 'Name',
      valueOf: (item) => item,
    );

    test(
      'without sortFields the data keeps the order from the data source',
      () async {
        final controller = ListDataComponentController<String>();
        addTearDown(controller.dispose);
        controller.value.dataSource = (offset, search) async => ['b', 'a', 'c'];

        await controller.refresh(refreshDelayed: 0);

        expect(controller.value.data, ['b', 'a', 'c']);
        expect(controller.activeSortField, isNull);
      },
    );

    test(
      'sortBy orders the loaded data and flips with ascending: false',
      () async {
        final controller = ListDataComponentController<String>();
        addTearDown(controller.dispose);
        controller.value.sortFields = [byName];
        controller.value.dataSource = (offset, search) async => ['b', 'a', 'c'];
        await controller.refresh(refreshDelayed: 0);

        controller.sortBy('name');
        expect(controller.value.data, ['a', 'b', 'c']);
        expect(controller.activeSortField, same(byName));

        controller.sortBy('name', ascending: false);
        expect(controller.value.data, ['c', 'b', 'a']);
      },
    );

    test('the sort is kept when a later page is loaded', () async {
      final controller = ListDataComponentController<String>();
      addTearDown(controller.dispose);
      controller.value.sortFields = [byName];
      controller.value.dataSource = (offset, search) async =>
          offset == 0 ? ['d', 'b'] : ['c', 'a'];
      await controller.refresh(refreshDelayed: 0);
      controller.sortBy('name');

      await controller.getOther();

      expect(controller.value.data, ['a', 'b', 'c', 'd']);
    });

    test('a refresh returns the new result already sorted', () async {
      final controller = ListDataComponentController<String>();
      addTearDown(controller.dispose);
      controller.value.sortFields = [byName];
      controller.value.dataSource = (offset, search) async => ['z', 'm'];
      controller.sortBy('name', ascending: false);

      await controller.refresh(refreshDelayed: 0);

      expect(controller.value.data, ['z', 'm']);
      controller.value.dataSource = (offset, search) async => ['a', 'q'];
      await controller.refresh(refreshDelayed: 0);
      expect(controller.value.data, ['q', 'a']);
    });

    test('items without a value sort last in both directions', () async {
      final controller = ListDataComponentController<String?>();
      addTearDown(controller.dispose);
      controller.value.sortFields = [
        ListDataSortField<String?>(
          key: 'name',
          label: 'Name',
          valueOf: (item) => item,
        ),
      ];
      controller.value.dataSource = (offset, search) async => ['b', null, 'a'];
      await controller.refresh(refreshDelayed: 0);

      controller.sortBy('name');
      expect(controller.value.data, ['a', 'b', null]);

      controller.sortBy('name', ascending: false);
      expect(controller.value.data, ['b', 'a', null]);
    });
  });

  group('paging and refresh races', () {
    test(
      'a second load-more while one is running does not append the page twice',
      () async {
        final controller = ListDataComponentController<String>();
        addTearDown(controller.dispose);
        final pending = <Completer<List<String>>>[];
        final offsets = <int>[];
        controller.value.dataSource = (offset, search) {
          offsets.add(offset);
          final c = Completer<List<String>>();
          pending.add(c);
          return c.future;
        };

        final first = controller.refresh(refreshDelayed: 0);
        await Future<void>.delayed(Duration.zero);
        pending.single.complete(['a', 'b']);
        await first;

        // Two scroll-end events arrive while the next page is in flight.
        final more1 = controller.getOther();
        final more2 = controller.getOther();
        await Future<void>.delayed(Duration.zero);
        pending.last.complete(['c']);
        await Future.wait([more1, more2]);

        expect(offsets, [0, 2], reason: 'only one page request is made');
        expect(controller.value.data, ['a', 'b', 'c']);
      },
    );

    test(
      'an older refresh that answers late does not overwrite a newer one',
      () async {
        final controller = ListDataComponentController<String>();
        addTearDown(controller.dispose);
        final pending = <Completer<List<String>>>[];
        controller.value.dataSource = (offset, search) {
          final c = Completer<List<String>>();
          pending.add(c);
          return c.future;
        };

        // The user types, so a second search starts before the first answers.
        final older = controller.refresh(refreshDelayed: 0);
        final newer = controller.refresh(refreshDelayed: 0);
        await Future<void>.delayed(Duration.zero);

        pending[1].complete(['new result']);
        await newer;
        pending[0].complete(['stale result']);
        await older;

        expect(controller.value.data, ['new result']);
      },
    );
  });
}
