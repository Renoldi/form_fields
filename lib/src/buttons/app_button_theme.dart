import 'package:flutter/material.dart';

class AppButtonThemeData extends ThemeExtension<AppButtonThemeData> {
  final ButtonStyle? filledStyle;
  final ButtonStyle? filledTonalStyle;
  final ButtonStyle? elevatedStyle;
  final ButtonStyle? outlinedStyle;
  final ButtonStyle? textStyle;
  final ButtonStyle? iconStyle;
  final ButtonStyle? fabStyle;
  final ButtonStyle? extendedFabStyle;
  final Color? iconBackgroundColor;
  final Color? fabBackgroundColor;

  const AppButtonThemeData({
    this.filledStyle,
    this.filledTonalStyle,
    this.elevatedStyle,
    this.outlinedStyle,
    this.textStyle,
    this.iconStyle,
    this.fabStyle,
    this.extendedFabStyle,
    this.iconBackgroundColor,
    this.fabBackgroundColor,
  });

  @override
  AppButtonThemeData copyWith({
    ButtonStyle? filledStyle,
    ButtonStyle? filledTonalStyle,
    ButtonStyle? elevatedStyle,
    ButtonStyle? outlinedStyle,
    ButtonStyle? textStyle,
    ButtonStyle? iconStyle,
    ButtonStyle? fabStyle,
    ButtonStyle? extendedFabStyle,
    Color? iconBackgroundColor,
    Color? fabBackgroundColor,
  }) {
    return AppButtonThemeData(
      filledStyle: filledStyle ?? this.filledStyle,
      filledTonalStyle: filledTonalStyle ?? this.filledTonalStyle,
      elevatedStyle: elevatedStyle ?? this.elevatedStyle,
      outlinedStyle: outlinedStyle ?? this.outlinedStyle,
      textStyle: textStyle ?? this.textStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      fabStyle: fabStyle ?? this.fabStyle,
      extendedFabStyle: extendedFabStyle ?? this.extendedFabStyle,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      fabBackgroundColor: fabBackgroundColor ?? this.fabBackgroundColor,
    );
  }

  @override
  AppButtonThemeData lerp(ThemeExtension<AppButtonThemeData>? other, double t) {
    if (other is! AppButtonThemeData) return this;
    return AppButtonThemeData(
      filledStyle: ButtonStyle.lerp(filledStyle, other.filledStyle, t),
      filledTonalStyle:
          ButtonStyle.lerp(filledTonalStyle, other.filledTonalStyle, t),
      elevatedStyle: ButtonStyle.lerp(elevatedStyle, other.elevatedStyle, t),
      outlinedStyle: ButtonStyle.lerp(outlinedStyle, other.outlinedStyle, t),
      textStyle: ButtonStyle.lerp(textStyle, other.textStyle, t),
      iconStyle: ButtonStyle.lerp(iconStyle, other.iconStyle, t),
      fabStyle: ButtonStyle.lerp(fabStyle, other.fabStyle, t),
      extendedFabStyle:
          ButtonStyle.lerp(extendedFabStyle, other.extendedFabStyle, t),
      iconBackgroundColor:
          Color.lerp(iconBackgroundColor, other.iconBackgroundColor, t),
      fabBackgroundColor:
          Color.lerp(fabBackgroundColor, other.fabBackgroundColor, t),
    );
  }
}

extension AppButtonThemeExtension on BuildContext {
  AppButtonThemeData get appButtonTheme =>
      Theme.of(this).extension<AppButtonThemeData>() ??
      const AppButtonThemeData();
}
