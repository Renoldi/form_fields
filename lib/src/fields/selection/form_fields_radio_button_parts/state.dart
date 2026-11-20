part of '../form_fields_radio_button.dart';

class _FormFieldsRadioButtonState<T> extends State<FormFieldsRadioButton<T>> {
  late final GlobalKey<FormFieldState<T>> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormFieldState<T>>();
  }

  @override
  void didUpdateWidget(covariant FormFieldsRadioButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalErrorText != widget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    return FormField<T>(
      key: _formKey,
      initialValue: widget.initialValue,
      validator: (value) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        if (widget.isRequired && value == null) {
          return l.getWithLabel('selectRequired', widget.label.toTitleCases);
        }
        if (widget.validator != null) return widget.validator!(value);
        return null;
      },
      builder: (FormFieldState<T> state) {
        return _FormFieldsRadioButtonBody<T>(
          label: widget.label,
          state: state,
          items: widget.items ?? [],
          sections: widget.sections ?? {},
          onChanged: widget.onChanged,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          direction: widget.direction,
          borderType: widget.borderType,
          activeColor: widget.activeColor,
          textStyle: widget.textStyle,
          itemPadding: widget.itemPadding,
          isRequired: widget.isRequired,
          sectionSpacing: widget.sectionSpacing,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
          textRightPadding: widget.textRightPadding,
          itemTextMarginRight: widget.itemTextMarginRight,
          selectedItemBackgroundColor: widget.selectedItemBackgroundColor,
          selectedItemTextColor: widget.selectedItemTextColor,
          hoverBackgroundColor: widget.hoverBackgroundColor,
          itemShadow: widget.itemShadow,
          labelPosition: widget.labelPosition,
          containerPadding: widget.containerPadding,
          containerGap: widget.containerGap,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          indicatorVerticalAlignment: widget.indicatorVerticalAlignment,
          horizontalSideBySide: widget.horizontalSideBySide,
          readOnly: widget.readOnly,
          backgroundColor: widget.backgroundColor,
          filled: widget.filled,
        );
      },
    );
  }
}
