library;

import 'package:flutter/material.dart';

/// A lightweight layout wrapper for grouping related buttons.
class AppButtonGroup extends StatelessWidget {
  final List<Widget> children;
  final Axis direction;
  final double spacing;
  final double runSpacing;
  final MainAxisAlignment mainAxisAlignment;
  final WrapAlignment wrapAlignment;

  const AppButtonGroup({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.spacing = 8,
    this.runSpacing = 8,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.wrapAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: wrapAlignment,
      children: children,
    );
  }
}
