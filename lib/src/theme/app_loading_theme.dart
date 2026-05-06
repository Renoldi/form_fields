library;

import 'package:flutter/material.dart';

/// Theme extension for loading visuals used across the package.
@immutable
class AppLoadingThemeData extends ThemeExtension<AppLoadingThemeData> {
  final Color indicatorColor;
  final Color trackColor;
  final Color overlayColor;
  final Color accentColor;

  const AppLoadingThemeData({
    required this.indicatorColor,
    required this.trackColor,
    required this.overlayColor,
    required this.accentColor,
  });

  const AppLoadingThemeData.fallback()
      : indicatorColor = const Color(0xFF1976D2),
        trackColor = const Color(0x2E1976D2),
        overlayColor = const Color(0x59000000),
        accentColor = const Color(0xFFFF5722);

  @override
  AppLoadingThemeData copyWith({
    Color? indicatorColor,
    Color? trackColor,
    Color? overlayColor,
    Color? accentColor,
  }) {
    return AppLoadingThemeData(
      indicatorColor: indicatorColor ?? this.indicatorColor,
      trackColor: trackColor ?? this.trackColor,
      overlayColor: overlayColor ?? this.overlayColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  @override
  AppLoadingThemeData lerp(
      covariant ThemeExtension<AppLoadingThemeData>? other, double t) {
    if (other is! AppLoadingThemeData) return this;
    return AppLoadingThemeData(
      indicatorColor:
          Color.lerp(indicatorColor, other.indicatorColor, t) ?? indicatorColor,
      trackColor: Color.lerp(trackColor, other.trackColor, t) ?? trackColor,
      overlayColor:
          Color.lerp(overlayColor, other.overlayColor, t) ?? overlayColor,
      accentColor: Color.lerp(accentColor, other.accentColor, t) ?? accentColor,
    );
  }
}

extension AppLoadingThemeExtension on BuildContext {
  AppLoadingThemeData get appLoadingTheme =>
      Theme.of(this).extension<AppLoadingThemeData>() ??
      const AppLoadingThemeData.fallback();
}
