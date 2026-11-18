part of '../form_fields_checkbox.dart';

class _FormFieldsCheckboxState<T> extends State<FormFieldsCheckbox<T>> {
  late final GlobalKey<FormFieldState<List<T>>> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormFieldState<List<T>>>();
  }

  @override
  void didUpdateWidget(covariant FormFieldsCheckbox<T> oldWidget) {
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
    return FormField<List<T>>(
      key: _formKey,
      initialValue: widget.initialValue ?? [],
      validator: (value) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        if (widget.isRequired && (value == null || value.isEmpty)) {
          return l.selectAtLeastOne(widget.label.toTitleCases);
        }
        if (widget.validator != null) return widget.validator!(value ?? []);
        return null;
      },
      builder: (FormFieldState<List<T>> state) {
        return _FormFieldsCheckboxBody<T>(
          label: widget.label,
          state: state,
          items: widget.items,
          onChanged: widget.onChanged,
          direction: widget.direction,
          borderType: widget.borderType,
          activeColor: widget.activeColor,
          textStyle: widget.textStyle,
          itemPadding: widget.itemPadding,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          itemMarginHorizontal: widget.itemMarginHorizontal,
          indicatorVerticalAlignment: widget.indicatorVerticalAlignment,
          horizontalSideBySide: widget.horizontalSideBySide,
          textRightPadding: widget.textRightPadding,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          isRequired: widget.isRequired,
          labelPosition: widget.labelPosition,
          readOnly: widget.readOnly,
          containerGap: widget.containerGap,
          backgroundColor: widget.backgroundColor,
          filled: widget.filled,
        );
      },
    );
  }
}
