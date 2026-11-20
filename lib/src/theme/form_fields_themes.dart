/// Theme data for the package's themed widgets: buttons, loading indicators
/// and the MyImage field.
library;

import 'dart:ui' show lerpDouble;
import 'package:material_ui/material_ui.dart';

@immutable
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

  const AppButtonThemeData.fallback() : this();

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
      filledTonalStyle: ButtonStyle.lerp(
        filledTonalStyle,
        other.filledTonalStyle,
        t,
      ),
      elevatedStyle: ButtonStyle.lerp(elevatedStyle, other.elevatedStyle, t),
      outlinedStyle: ButtonStyle.lerp(outlinedStyle, other.outlinedStyle, t),
      textStyle: ButtonStyle.lerp(textStyle, other.textStyle, t),
      iconStyle: ButtonStyle.lerp(iconStyle, other.iconStyle, t),
      fabStyle: ButtonStyle.lerp(fabStyle, other.fabStyle, t),
      extendedFabStyle: ButtonStyle.lerp(
        extendedFabStyle,
        other.extendedFabStyle,
        t,
      ),
      iconBackgroundColor: Color.lerp(
        iconBackgroundColor,
        other.iconBackgroundColor,
        t,
      ),
      fabBackgroundColor: Color.lerp(
        fabBackgroundColor,
        other.fabBackgroundColor,
        t,
      ),
    );
  }
}

extension AppButtonThemeExtension on BuildContext {
  AppButtonThemeData get appButtonTheme =>
      Theme.of(this).extension<AppButtonThemeData>() ??
      const AppButtonThemeData.fallback();
}

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
    covariant ThemeExtension<AppLoadingThemeData>? other,
    double t,
  ) {
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

@immutable
class FormFieldsMyImageThemeData
    extends ThemeExtension<FormFieldsMyImageThemeData> {
  final Color addTileBorderColor;
  final double addTileBorderWidth;
  final double addTileBorderRadius;
  final Color addTileBackgroundColor;
  final Color addIconColor;

  const FormFieldsMyImageThemeData({
    required this.addTileBorderColor,
    required this.addTileBorderWidth,
    required this.addTileBorderRadius,
    required this.addTileBackgroundColor,
    required this.addIconColor,
  });

  const FormFieldsMyImageThemeData.fallback()
    : addTileBorderColor = Colors.blue,
      addTileBorderWidth = 2,
      addTileBorderRadius = 8,
      addTileBackgroundColor = const Color(0xFFF5F5F5),
      addIconColor = Colors.blue;

  @override
  FormFieldsMyImageThemeData copyWith({
    Color? addTileBorderColor,
    double? addTileBorderWidth,
    double? addTileBorderRadius,
    Color? addTileBackgroundColor,
    Color? addIconColor,
  }) {
    return FormFieldsMyImageThemeData(
      addTileBorderColor: addTileBorderColor ?? this.addTileBorderColor,
      addTileBorderWidth: addTileBorderWidth ?? this.addTileBorderWidth,
      addTileBorderRadius: addTileBorderRadius ?? this.addTileBorderRadius,
      addTileBackgroundColor:
          addTileBackgroundColor ?? this.addTileBackgroundColor,
      addIconColor: addIconColor ?? this.addIconColor,
    );
  }

  @override
  FormFieldsMyImageThemeData lerp(
    covariant ThemeExtension<FormFieldsMyImageThemeData>? other,
    double t,
  ) {
    if (other is! FormFieldsMyImageThemeData) return this;
    return FormFieldsMyImageThemeData(
      addTileBorderColor:
          Color.lerp(addTileBorderColor, other.addTileBorderColor, t) ??
          addTileBorderColor,
      addTileBorderWidth:
          lerpDouble(addTileBorderWidth, other.addTileBorderWidth, t) ??
          addTileBorderWidth,
      addTileBorderRadius:
          lerpDouble(addTileBorderRadius, other.addTileBorderRadius, t) ??
          addTileBorderRadius,
      addTileBackgroundColor:
          Color.lerp(addTileBackgroundColor, other.addTileBackgroundColor, t) ??
          addTileBackgroundColor,
      addIconColor:
          Color.lerp(addIconColor, other.addIconColor, t) ?? addIconColor,
    );
  }
}

extension FormFieldsMyImageThemeExtension on BuildContext {
  FormFieldsMyImageThemeData get formFieldsMyImageTheme =>
      Theme.of(this).extension<FormFieldsMyImageThemeData>() ??
      const FormFieldsMyImageThemeData.fallback();
}
