/// Color utilities for form fields
import 'package:flutter/material.dart';

/// Color utility class with predefined colors
class ColorUtil {
  /// Red color for error states
  static const Color redColor = Color(0xFFFF0000);

  /// Gray color C7C7C7
  static const Color colorC7C7C7 = Color(0xFFC7C7C7);
}

/// Extension on Color for additional color utilities
extension ColorExtensions on Color? {
  /// Returns a lighter shade of the color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    if (this == null) return ColorUtil.colorC7C7C7;
    final hsl = HSLColor.fromColor(this!);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns a darker shade of the color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    if (this == null) return ColorUtil.colorC7C7C7;
    final hsl = HSLColor.fromColor(this!);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns the color with modified opacity
  Color withOpacity(double opacity) {
    assert(opacity >= 0 && opacity <= 1);
    if (this == null) return ColorUtil.colorC7C7C7;
    return Color.fromRGBO(
      (this!.r * 255.0).round().clamp(0, 255),
      (this!.g * 255.0).round().clamp(0, 255),
      (this!.b * 255.0).round().clamp(0, 255),
      opacity,
    );
  }
}
