import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

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
