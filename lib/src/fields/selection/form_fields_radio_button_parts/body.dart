part of '../form_fields_radio_button.dart';

class _FormFieldsRadioButtonBody<T> extends StatefulWidget {
  final String label;
  final FormFieldState<T> state;
  final List<T> items;
  final Map<String, List<T>> sections;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final Axis direction;
  final BorderType borderType;
  final Color? activeColor;
  final EdgeInsets itemPadding;
  final double sectionSpacing;
  final bool isRequired;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final double textRightPadding;
  final double itemTextMarginRight;
  final Color? selectedItemBackgroundColor;
  final Color? selectedItemTextColor;
  final Color? hoverBackgroundColor;
  final bool itemShadow;
  final LabelPosition labelPosition;
  final double containerPadding;
  final double containerGap;
  final double itemMarginTop;
  final double itemMarginBottom;
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;
  final TextStyle? textStyle;

  const _FormFieldsRadioButtonBody({
    required this.label,
    required this.state,
    required this.items,
    required this.sections,
    required this.onChanged,
    this.itemLabelBuilder,
    this.itemBuilder,
    required this.direction,
    required this.borderType,
    this.activeColor,
    required this.itemPadding,
    required this.sectionSpacing,
    required this.isRequired,
    this.itemBorderColor,
    required this.itemBorderWidth,
    required this.itemBorderRadius,
    required this.textRightPadding,
    required this.itemTextMarginRight,
    this.selectedItemBackgroundColor,
    this.selectedItemTextColor,
    this.hoverBackgroundColor,
    required this.itemShadow,
    required this.labelPosition,
    required this.containerPadding,
    required this.containerGap,
    required this.itemMarginTop,
    required this.itemMarginBottom,
    required this.indicatorVerticalAlignment,
    required this.horizontalSideBySide,
    required this.readOnly,
    this.textStyle,
    this.backgroundColor,
    this.filled = true,
  });

  @override
  State<_FormFieldsRadioButtonBody<T>> createState() =>
      _FormFieldsRadioButtonBodyView<T>();
}
