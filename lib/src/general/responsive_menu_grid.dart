import 'package:flutter/material.dart';

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

        final int countPerRow = ((usableWidth + minHorizontalSpacing) /
                (itemWidth + minHorizontalSpacing))
            .floor()
            .clamp(1, 999);
        final double extraWidth = usableWidth - (countPerRow * itemWidth);
        final double computedSpacing = countPerRow > 1
            ? (extraWidth / (countPerRow - 1)).clamp(0.0, double.infinity)
            : 0.0;
        final double spacingCap = maxCrossAxisSpacing ?? (itemWidth * 0.25);
        final double crossAxisSpacing = computedSpacing.clamp(0.0, spacingCap);

        final grid = Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: GridView.count(
            physics: allowScroll ? null : const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: countPerRow,
            mainAxisSpacing: verticalSpacing,
            crossAxisSpacing: crossAxisSpacing,
            // Use the requested item width/height to determine the cell
            // aspect ratio so items render at the expected size.
            childAspectRatio: itemWidth / itemHeight,
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

        return grid;
      },
    );
  }
}
