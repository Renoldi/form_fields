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
