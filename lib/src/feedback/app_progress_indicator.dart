library;

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

/// Reusable progress indicator that supports linear and circular types.
class AppProgressIndicator extends StatelessWidget {
  final AppProgressType type;

  /// Progress value from 0.0 to 1.0.
  /// Set null for indeterminate state.
  final double? value;
  final double minHeight;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final BorderRadius? borderRadius;
  final bool showValueLabel;
  final String Function(double value)? valueLabelBuilder;

  const AppProgressIndicator({
    super.key,
    this.type = AppProgressType.linear,
    this.value,
    this.minHeight = 8,
    this.size = 36,
    this.strokeWidth = 4,
    this.color,
    this.trackColor,
    this.borderRadius,
    this.showValueLabel = false,
    this.valueLabelBuilder,
  }) : assert(value == null || (value >= 0 && value <= 1));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final indicatorColor = color ?? cs.primary;
    final bgColor = trackColor ?? cs.primary.withValues(alpha: 0.18);

    if (type == AppProgressType.circular) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            color: indicatorColor,
            backgroundColor: bgColor,
          ),
        ),
      );
    }

    final progress = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value,
        minHeight: minHeight,
        color: indicatorColor,
        backgroundColor: bgColor,
      ),
    );

    if (!showValueLabel || value == null) {
      return progress;
    }

    final label =
        valueLabelBuilder?.call(value!) ?? '${(value! * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        progress,
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
