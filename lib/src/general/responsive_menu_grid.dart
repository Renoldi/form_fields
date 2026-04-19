import 'package:flutter/material.dart';

class ResponsiveMenuGrid extends StatelessWidget {
  /// List of widgets to display in the grid.
  final List<Widget> widgets;
  final double itemSize;
  final double horizontalMargin;
  final double verticalSpacing;

  /// Jika true, grid akan selalu rata kiri (tanpa auto-center)
  final bool alignLeft;

  const ResponsiveMenuGrid({
    super.key,
    required this.widgets,
    this.itemSize = 80,
    this.horizontalMargin = 16,
    this.verticalSpacing = 16,
    this.alignLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int countPerRow = ((width - 2 * horizontalMargin) / itemSize)
            .floor()
            .clamp(1, widgets.length);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: countPerRow,
            mainAxisSpacing: verticalSpacing,
            crossAxisSpacing: 0,
            childAspectRatio: 1,
            children: widgets
                .map((w) =>
                    SizedBox(width: itemSize, height: itemSize, child: w))
                .toList(),
          ),
        );
      },
    );
  }
}
