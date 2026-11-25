import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:form_fields/src/general/responsive_menu_grid.dart';

const double _itemSize = 100;
const double _verticalSpacing = 8;

/// Pumps a [ResponsiveMenuGrid] of [count] keyed items in a box [width] px
/// wide. Items are `item0`, `item1`, ... in order.
Future<void> _pumpGrid(
  WidgetTester tester, {
  required double width,
  required int count,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ResponsiveMenuGrid(
              itemSize: _itemSize,
              verticalSpacing: _verticalSpacing,
              horizontalMargin: 0,
              alignLeft: true,
              widgets: [
                for (var i = 0; i < count; i++)
                  SizedBox(
                    key: ValueKey('item$i'),
                    child: const ColoredBox(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView));
  return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
}

Rect _itemRect(WidgetTester tester, int index) =>
    tester.getRect(find.byKey(ValueKey('item$index')));

/// Horizontal distance from the right edge of item [a] to the left edge of
/// item [b]. Only meaningful when both items share a row.
double _gap(WidgetTester tester, int a, int b) =>
    _itemRect(tester, b).left - _itemRect(tester, a).right;

void main() {
  group('ResponsiveMenuGrid with 5 items', () {
    // (width, columns, items in the first row, visible gap 0->1, grid height)
    for (final (width, columns, firstRowItems, visibleGap, gridHeight) in [
      // Phone: 3 columns fill the width. Visible gap is unchanged. Rows are
      // now 108 px apart (were 118 px), so two rows are 208 px tall.
      (380.0, 3, 3, 35.0, 208.0),
      // Wide: fewer items than fit, so the grid is sized to its content.
      (800.0, 5, 5, 25.0, 100.0),
      (1200.0, 5, 5, 25.0, 100.0),
    ]) {
      testWidgets(
        'lays out $columns columns at ${width.toInt()} px with 25 px spacing',
        (tester) async {
          await _pumpGrid(tester, width: width, count: 5);

          final delegate = _gridDelegate(tester);
          expect(delegate.crossAxisCount, columns);
          expect(delegate.crossAxisSpacing, 25);

          final firstTop = _itemRect(tester, 0).top;
          for (var i = 0; i < firstRowItems; i++) {
            expect(_itemRect(tester, i).top, firstTop, reason: 'item $i');
          }
          if (firstRowItems < 5) {
            expect(
              _itemRect(tester, firstRowItems).top,
              greaterThan(firstTop),
              reason: 'item $firstRowItems should wrap',
            );
          }

          expect(_gap(tester, 0, 1), closeTo(visibleGap, 0.001));
          expect(
            tester.getSize(find.byType(GridView)).height,
            closeTo(gridHeight, 0.001),
          );
        },
      );
    }
  });

  testWidgets('5 items at 411 px keep a 108 px row pitch', (tester) async {
    await _pumpGrid(tester, width: 411, count: 5);

    // Rows are itemHeight + verticalSpacing apart, whatever the column width.
    final rowPitch = _itemRect(tester, 3).top - _itemRect(tester, 0).top;
    expect(rowPitch, closeTo(_itemSize + _verticalSpacing, 0.001));

    // The grid ends with the last row's item: no extra space below it.
    expect(
      tester.getSize(find.byType(GridView)).height,
      closeTo(2 * _itemSize + _verticalSpacing, 0.001),
    );
  });

  testWidgets('a single item keeps its own 100 px box at 380 px', (
    tester,
  ) async {
    await _pumpGrid(tester, width: 380, count: 1);

    // Before the fix this grid was a full-width square: 380 px tall.
    expect(tester.getSize(find.byType(GridView)).height, _itemSize);
    expect(
      tester.getSize(find.byKey(const ValueKey('item0'))),
      const Size(_itemSize, _itemSize),
    );
  });

  testWidgets('a short list is centered as a block when alignLeft is false', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(380, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveMenuGrid(
            itemSize: _itemSize,
            verticalSpacing: _verticalSpacing,
            horizontalMargin: 0,
            widgets: [SizedBox(key: const ValueKey('item0'))],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getRect(find.byKey(const ValueKey('item0'))).left,
      closeTo((380 - _itemSize) / 2, 0.001),
    );
  });

  testWidgets('two items at 380 px sit 25 px apart in a 100 px row', (
    tester,
  ) async {
    await _pumpGrid(tester, width: 380, count: 2);

    expect(_gap(tester, 0, 1), closeTo(25, 0.001));
    expect(tester.getSize(find.byType(GridView)).height, _itemSize);
  });

  testWidgets('13 items at 1200 px keep 11 columns and a 10 px gap', (
    tester,
  ) async {
    await _pumpGrid(tester, width: 1200, count: 13);

    final delegate = _gridDelegate(tester);
    expect(delegate.crossAxisCount, 11);
    expect(delegate.crossAxisSpacing, closeTo(10, 0.001));
    expect(_gap(tester, 0, 1), closeTo(10, 0.001));

    // Items 0-10 fill the first row, and item 11 wraps to the next one.
    final firstTop = _itemRect(tester, 0).top;
    expect(_itemRect(tester, 10).top, firstTop);
    expect(_itemRect(tester, 11).top, greaterThan(firstTop));

    // Two rows of 100 px items with 8 px between them, as before the fix.
    expect(
      tester.getSize(find.byType(GridView)).height,
      closeTo(2 * _itemSize + _verticalSpacing, 0.001),
    );
  });
}
