library;

import 'package:flutter/material.dart';

import '../utilities/enums.dart';

/// Reusable loading indicator with multiple visual variants.
class AppLoadingIndicator extends StatefulWidget {
  final AppLoadingVariant variant;
  final double size;
  final Color? color;
  final Color? trackColor;
  final double strokeWidth;
  final Duration duration;
  final String? semanticsLabel;

  const AppLoadingIndicator({
    super.key,
    this.variant = AppLoadingVariant.spinner,
    this.size = 32,
    this.color,
    this.trackColor,
    this.strokeWidth = 3,
    this.duration = const Duration(milliseconds: 900),
    this.semanticsLabel,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant AppLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final indicatorColor = widget.color ?? cs.primary;
    final bgColor = widget.trackColor ?? cs.primary.withValues(alpha: 0.2);

    final child = switch (widget.variant) {
      AppLoadingVariant.spinner => SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              color: indicatorColor,
              backgroundColor: bgColor,
            ),
          ),
        ),
      AppLoadingVariant.pulse => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_controller.value);
            final scale = 0.78 + (t * 0.32);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: widget.size * 0.56,
                  height: widget.size * 0.56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: indicatorColor,
                  ),
                ),
              ),
            );
          },
        ),
      AppLoadingVariant.dots => SizedBox(
          width: widget.size * 1.4,
          height: widget.size * 0.5,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  final phase = ((_controller.value + (index * 0.2)) % 1.0);
                  final opacity =
                      0.35 + (Curves.easeInOut.transform(phase) * 0.65);
                  return Opacity(
                    opacity: opacity,
                    child: Container(
                      width: widget.size * 0.22,
                      height: widget.size * 0.22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: indicatorColor,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
    };

    return Semantics(
      label: widget.semanticsLabel ?? 'Loading',
      child: child,
    );
  }
}
