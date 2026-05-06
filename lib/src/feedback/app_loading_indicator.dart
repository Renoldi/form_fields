library;

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

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
    with TickerProviderStateMixin {
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
      AppLoadingVariant.orbit => SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _OrbitPainter(
                  progress: _controller.value,
                  trackColor: bgColor,
                  dotColor: indicatorColor,
                  strokeWidth: widget.strokeWidth,
                ),
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

class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color dotColor;
  final double strokeWidth;

  const _OrbitPainter({
    required this.progress,
    required this.trackColor,
    required this.dotColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Orbiting dot
    const twoPi = 2 * 3.141592653589793;
    final angle = twoPi * progress - (3.141592653589793 / 2);
    final dotCenter = Offset(
      center.dx + radius * _cos(angle),
      center.dy + radius * _sin(angle),
    );

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dotCenter, strokeWidth * 1.6, dotPaint);
  }

  static double _cos(double r) => _sinCos(r, cosine: true);
  static double _sin(double r) => _sinCos(r, cosine: false);

  // Inline trig without dart:math import (uses existing math)
  static double _sinCos(double radians, {required bool cosine}) {
    // Normalise to [0, 2π)
    const pi = 3.141592653589793;
    final x = radians % (2 * pi);
    // Taylor series — accurate enough for animation at double precision
    double result = 0;
    double term = cosine ? 1.0 : x;
    double sign = 1.0;
    double factorial = 1.0;
    final int start = cosine ? 0 : 1;
    for (int n = start; n < 20; n += 2) {
      result += sign * term / factorial;
      sign = -sign;
      final next1 = n + 1;
      final next2 = n + 2;
      term *= x * x;
      factorial *= next1 * next2;
    }
    return result;
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.dotColor != dotColor ||
      old.strokeWidth != strokeWidth;
}
