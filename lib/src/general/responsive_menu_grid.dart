import 'package:material_ui/material_ui.dart';

class ResponsiveMenuGrid extends StatelessWidget {
  /// List of widgets to display in the grid.
  final List<Widget> widgets;
  final double itemSize;
  final double horizontalMargin;
  final double verticalSpacing;
  final double minHorizontalSpacing;

  /// Optional fixed height for the grid. If null, grid sizes to content.
  final double? height;

  /// Optional fixed width for each item. If null, falls back to `itemSize`.
  final double? width;

  /// Optional cap for computed cross-axis spacing. If null, defaults to a
  /// quarter of the item width which prevents very large gaps when the grid
  /// has few columns and large available width.
  final double? maxCrossAxisSpacing;

  /// Jika true, grid akan selalu rata kiri (tanpa auto-center)
  final bool alignLeft;

  /// Jika true, grid akan allow scrolling. Default false preserves previous behaviour.
  final bool allowScroll;

  const ResponsiveMenuGrid({
    super.key,
    required this.widgets,
    this.itemSize = 80,
    this.horizontalMargin = 20,
    this.verticalSpacing = 20,
    this.minHorizontalSpacing = 8,
    this.alignLeft = false,
    this.allowScroll = true,
    this.height,
    this.width,
    this.maxCrossAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double usableWidth =
            (maxWidth - 2 * horizontalMargin).clamp(0.0, double.infinity);
        final double itemWidth = width ?? itemSize;
        final double itemHeight = height ?? itemSize;

        final int fittingPerRow = ((usableWidth + minHorizontalSpacing) /
                (itemWidth + minHorizontalSpacing))
            .floor()
            .clamp(1, 999);
        // Never plan more columns than there are items. Otherwise the leftover
        // width is divided across columns that stay empty, so the gap
        // collapses on wide layouts.
        final int countPerRow = fittingPerRow.clamp(1, widgets.length);
        final double extraWidth = usableWidth - (countPerRow * itemWidth);
        final double computedSpacing = countPerRow > 1
            ? (extraWidth / (countPerRow - 1)).clamp(0.0, double.infinity)
            : 0.0;
        final double spacingCap = maxCrossAxisSpacing ?? (itemWidth * 0.25);
        final double crossAxisSpacing = computedSpacing.clamp(0.0, spacingCap);

        final grid = Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: GridView(
            physics: allowScroll ? null : const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: countPerRow,
              mainAxisSpacing: verticalSpacing,
              crossAxisSpacing: crossAxisSpacing,
              // Fixed row height. The column width does not change it, so
              // rows are itemHeight + verticalSpacing apart.
              mainAxisExtent: itemHeight,
            ),
            children: widgets
                .map(
                  (w) => Align(
                    alignment:
                        alignLeft ? Alignment.topLeft : Alignment.topCenter,
                    // Fill the cell and center the widget inside it. This
                    // ensures the cell size is controlled by GridView while
                    // the widget itself remains centered/aligned as requested.
                    child: SizedBox.expand(
                      child: Align(
                        alignment:
                            alignLeft ? Alignment.topLeft : Alignment.center,
                        child: SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: w,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );

        // When columns were dropped because there are fewer items, size the
        // grid to its content. Otherwise GridView splits the full width between
        // the remaining columns, and items sit at the top-left of their wide
        // cells, so the visible gap grows. At the content width each cell is
        // exactly itemWidth, so the visible gap equals crossAxisSpacing.
        if (countPerRow == fittingPerRow) {
          return grid;
        }
        final double contentWidth =
            countPerRow * itemWidth + (countPerRow - 1) * crossAxisSpacing;
        return Align(
          alignment: alignLeft ? Alignment.topLeft : Alignment.topCenter,
          child: SizedBox(
            width: contentWidth + 2 * horizontalMargin,
            child: grid,
          ),
        );
      },
    );
  }
}
