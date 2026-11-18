part of '../form_fields_checkbox.dart';

class _FormFieldsCheckboxBody<T> extends StatefulWidget {
  final String label;
  final FormFieldState<List<T>> state;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final Axis direction;
  final BorderType borderType;
  final Color? activeColor;
  final EdgeInsets itemPadding;
  final double itemMarginTop;
  final double itemMarginBottom;
  final double itemMarginHorizontal;
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final double textRightPadding;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final Color? selectedItemTextColor;
  final bool isRequired;
  final LabelPosition labelPosition;
  final double containerGap;
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;
  final TextStyle? textStyle;

  const _FormFieldsCheckboxBody({
    required this.label,
    required this.state,
    required this.items,
    required this.onChanged,
    required this.direction,
    required this.borderType,
    this.activeColor,
    required this.itemPadding,
    required this.itemMarginTop,
    required this.itemMarginBottom,
    required this.itemMarginHorizontal,
    required this.indicatorVerticalAlignment,
    required this.horizontalSideBySide,
    required this.textRightPadding,
    this.itemBorderColor,
    required this.itemBorderWidth,
    required this.itemBorderRadius,
    this.itemLabelBuilder,
    this.itemBuilder,
    this.selectedItemTextColor,
    required this.isRequired,
    required this.labelPosition,
    required this.containerGap,
    required this.readOnly,
    this.textStyle,
    this.backgroundColor,
    this.filled = true,
  });

  @override
  State<_FormFieldsCheckboxBody<T>> createState() =>
      _FormFieldsCheckboxBodyView<T>();
}
