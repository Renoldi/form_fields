import 'package:flutter/material.dart';

import '../../utilities/enums.dart';
import 'form_fields_checkbox.dart';
import 'form_fields_dropdown.dart';
import 'form_fields_dropdown_multi.dart';
import 'form_fields_radio_button.dart';
import '../../utilities/theme_helpers.dart';

class FormFieldsSelect<T> extends StatefulWidget {
  // ============================================================================
  // CORE
  // ============================================================================
  final FormType formType;
  final String label;
  final List<T> items;

  /// Single value
  final T? initialValue;

  /// Multi value
  final List<T>? initialValues;

  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<T>>? onMultiChanged;

  final String Function(T item)? itemLabelBuilder;

  // ============================================================================
  // VALIDATION
  // ============================================================================
  final String? Function(T?)? validator;
  final String? Function(List<T>?)? multiValidator;
  final bool isRequired;

  // ============================================================================
  // UI CONFIG
  // ============================================================================
  final LabelPosition labelPosition;
  final BorderType borderType;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final double itemMarginTop;
  final double itemMarginBottom;
  final double itemMarginHorizontal;

  // ============================================================================
  // FILTER
  // ============================================================================
  final bool enableFilter;
  final String filterHintText;

  final String? externalErrorText;
  final Color? backgroundColor;
  final bool filled;
  final TextStyle? textStyle;
  final Color? activeColor;
  final Widget Function(T item, bool selected)? itemBuilder;
  final Color? selectedItemBackgroundColor;
  final Color? selectedItemTextColor;
  const FormFieldsSelect({
    super.key,
    required this.formType,
    required this.label,
    required this.items,

    // single
    this.initialValue,

    // multi
    this.initialValues,
    this.onChanged,
    this.onMultiChanged,
    this.itemLabelBuilder,

    // validation
    this.validator,
    this.multiValidator,
    this.isRequired = false,

    // UI
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.outlineInputBorder,
    this.itemBorderColor,
    this.itemBorderWidth = 1.0,
    this.itemBorderRadius = 8,
    this.itemMarginTop = 4,
    this.itemMarginBottom = 4,
    this.itemMarginHorizontal = 0,
    this.enableFilter = false,
    this.filterHintText = 'Search...',
    this.externalErrorText,
    this.backgroundColor,
    this.filled = true,
    this.textStyle,
    this.activeColor,
    this.itemBuilder,
    this.selectedItemBackgroundColor,
    this.selectedItemTextColor,
  });

  @override
  State<FormFieldsSelect<T>> createState() => _FormFieldsSelectView<T>();
}

abstract class _FormFieldsSelectPresenterState<T>
    extends State<FormFieldsSelect<T>> {
  late final _FormFieldsSelectViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _FormFieldsSelectViewModel();
  }

  @override
  void didUpdateWidget(covariant FormFieldsSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalErrorText != widget.externalErrorText) {
      // Force rebuild so child selection widgets receive the updated
      // externalErrorText and can validate themselves.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }
}

class _FormFieldsSelectView<T> extends _FormFieldsSelectPresenterState<T> {
  @override
  Widget build(BuildContext context) {
    switch (widget.formType) {
      case FormType.dropdown:
        return FormFieldsDropdown<T>(
          label: widget.label,
          items: widget.items,
          initialValue: widget.initialValue,
          isRequired: widget.isRequired,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          selectedItemBackgroundColor: widget.selectedItemBackgroundColor,
          selectedItemTextColor: widget.selectedItemTextColor,
          onChanged: widget.onChanged ?? (_) {},
          validator: widget.validator,
          labelPosition: widget.labelPosition,
          borderType: widget.borderType,
          enableFilter: widget.enableFilter,
          filterHintText: widget.filterHintText,
          externalErrorText: widget.externalErrorText,
          backgroundColor: widget.backgroundColor,
          filled: widget.filled,
          textStyle: widget.textStyle,
        );

      case FormType.dropdownMulti:
        return FormFieldsDropdownMulti<T>(
          label: widget.label,
          items: widget.items,
          initialValues: widget.initialValues ?? [],
          isRequired: widget.isRequired,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          selectedItemBackgroundColor: widget.selectedItemBackgroundColor,
          selectedItemTextColor: widget.selectedItemTextColor,
          onChanged: widget.onMultiChanged ?? (_) {},
          validator: widget.multiValidator,
          labelPosition: widget.labelPosition,
          borderType: widget.borderType,
          enableFilter: widget.enableFilter,
          filterHintText: widget.filterHintText,
          externalErrorText: widget.externalErrorText,
          backgroundColor: widget.backgroundColor,
          filled: widget.filled,
          textStyle: widget.textStyle,
        );

      case FormType.radioButton:
        return FormFieldsRadioButton<T>(
          label: widget.label,
          items: widget.items,
          initialValue: widget.initialValue,
          isRequired: widget.isRequired,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          onChanged: widget.onChanged ?? (_) {},
          validator: widget.validator,
          labelPosition: widget.labelPosition,
          borderType: widget.borderType,
          activeColor: widget.activeColor ?? resolveActiveColor(context, null),
          textStyle: widget.textStyle,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
          externalErrorText: widget.externalErrorText,
          selectedItemBackgroundColor: widget.selectedItemBackgroundColor,
          selectedItemTextColor: widget.selectedItemTextColor,
          hoverBackgroundColor: widget.backgroundColor,
          backgroundColor: widget.backgroundColor,
          filled: widget.filled,
        );

      case FormType.checkbox:
        return FormFieldsCheckbox<T>(
          label: widget.label,
          items: widget.items,
          initialValue: widget.initialValues ?? [],
          isRequired: widget.isRequired,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          onChanged: widget.onMultiChanged ?? (_) {},
          validator: widget.multiValidator != null
              ? (List<T>? values) => widget.multiValidator!(values)
              : null,
          borderType: widget.borderType,
          activeColor: widget.activeColor ?? resolveActiveColor(context, null),
          textStyle: widget.textStyle,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          itemMarginHorizontal: widget.itemMarginHorizontal,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
          externalErrorText: widget.externalErrorText,
          // use same background for checkbox container
          backgroundColor: widget.backgroundColor,
          selectedItemTextColor: widget.selectedItemTextColor,
          filled: widget.filled,
        );

      default:
        // For all other FormType values (string, phone, password, email, etc.)
        // that are not supported by FormFieldsSelect
        throw UnimplementedError(
          'FormType.${widget.formType} is not supported by FormFieldsSelect. '
          'This widget only supports dropdown, dropdownMulti, radioButton, and checkbox.',
        );
    }
  }
}

class _FormFieldsSelectViewModel {}
