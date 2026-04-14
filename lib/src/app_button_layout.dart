library;

import 'package:flutter/material.dart';

/// Layout wrapper that keeps action buttons visible above keyboard
/// while respecting bottom safe areas.
class AppButtonLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double horizontalPadding;
  final double topPadding;
  final bool respectSafeArea;
  final bool avoidKeyboard;
  final Duration duration;
  final Curve curve;

  const AppButtonLayout({
    super.key,
    required this.child,
    this.margin,
    this.horizontalPadding = 16,
    this.topPadding = 12,
    this.respectSafeArea = true,
    this.avoidKeyboard = true,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = avoidKeyboard ? mediaQuery.viewInsets.bottom : 0.0;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: respectSafeArea,
      minimum: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        margin: margin,
        padding: EdgeInsets.only(
          top: topPadding,
          bottom: keyboardInset,
        ),
        child: child,
      ),
    );
  }
}
