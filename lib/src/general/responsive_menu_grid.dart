import 'package:flutter/material.dart';

class ResponsiveMenuGrid extends StatelessWidget {
  /// List of widgets to display in the grid.
  final List<Widget> widgets;
  final double itemSize;
  final double horizontalMargin;
  final double verticalSpacing;
  final double minHorizontalSpacing;

  /// Jika true, grid akan selalu rata kiri (tanpa auto-center)
  final bool alignLeft;

  const ResponsiveMenuGrid({
    super.key,
    required this.widgets,
    this.itemSize = 80,
    this.horizontalMargin = 20,
    this.verticalSpacing = 20,
    this.minHorizontalSpacing = 8,
    this.alignLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double usableWidth =
            (width - 2 * horizontalMargin).clamp(0.0, double.infinity);
        final int countPerRow = ((usableWidth + minHorizontalSpacing) /
                (itemSize + minHorizontalSpacing))
            .floor()
            .clamp(1, 999);
        final double extraWidth = usableWidth - (countPerRow * itemSize);
        final double crossAxisSpacing = countPerRow > 1
            ? (extraWidth / (countPerRow - 1)).clamp(0.0, double.infinity)
            : 0.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: countPerRow,
            mainAxisSpacing: verticalSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: 1,
            children: widgets
                .map(
                  (w) => Align(
                    alignment:
                        alignLeft ? Alignment.topLeft : Alignment.topCenter,
                    child: SizedBox(
                      width: itemSize,
                      height: itemSize,
                      child: w,
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
