import 'package:flutter/material.dart';

import '../../utilities/enums.dart';
import 'form_fields_checkbox.dart';
import 'form_fields_dropdown.dart';
import 'form_fields_dropdown_multi.dart';
import 'form_fields_radio_button.dart';

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
  final double radius;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;
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
    this.radius = 10,
    this.borderColor = const Color(0xFFC7C7C7),
    this.focusedBorderColor = Colors.blue,
    this.errorBorderColor = Colors.red,
    this.itemBorderColor,
    this.itemBorderWidth = 1.0,
    this.itemBorderRadius = 8,
    this.itemMarginTop = 4,
    this.itemMarginBottom = 4,
    this.itemMarginHorizontal = 0,
    this.enableFilter = false,
    this.filterHintText = 'Search...',
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
          onChanged: widget.onChanged ?? (_) {},
          validator: widget.validator,
          labelPosition: widget.labelPosition,
          borderType: widget.borderType,
          radius: widget.radius,
          borderColor: widget.borderColor,
          focusedBorderColor: widget.focusedBorderColor,
          errorBorderColor: widget.errorBorderColor,
          enableFilter: widget.enableFilter,
          filterHintText: widget.filterHintText,
        );

      case FormType.dropdownMulti:
        return FormFieldsDropdownMulti<T>(
          label: widget.label,
          items: widget.items,
          initialValues: widget.initialValues ?? [],
          isRequired: widget.isRequired,
          itemLabelBuilder: widget.itemLabelBuilder,
          onChanged: widget.onMultiChanged ?? (_) {},
          validator: widget.multiValidator,
          labelPosition: widget.labelPosition,
          borderType: widget.borderType,
          radius: widget.radius,
          borderColor: widget.borderColor,
          focusedBorderColor: widget.focusedBorderColor,
          errorBorderColor: widget.errorBorderColor,
          enableFilter: widget.enableFilter,
          filterHintText: widget.filterHintText,
        );

      case FormType.radioButton:
        return FormFieldsRadioButton<T>(
          label: widget.label,
          items: widget.items,
          initialValue: widget.initialValue,
          isRequired: widget.isRequired,
          itemLabelBuilder: widget.itemLabelBuilder,
          onChanged: widget.onChanged ?? (_) {},
          validator: widget.validator,
          labelPosition: widget.labelPosition,
          radius: widget.radius,
          borderColor: widget.borderColor,
          errorBorderColor: widget.errorBorderColor,
          activeColor: widget.focusedBorderColor,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
        );

      case FormType.checkbox:
        return FormFieldsCheckbox<T>(
          label: widget.label,
          items: widget.items,
          initialValue: widget.initialValues ?? [],
          isRequired: widget.isRequired,
          itemLabelBuilder: widget.itemLabelBuilder,
          onChanged: widget.onMultiChanged ?? (_) {},
          validator: widget.multiValidator != null
              ? (List<T>? values) => widget.multiValidator!(values)
              : null,
          radius: widget.radius,
          borderColor: widget.borderColor,
          errorBorderColor: widget.errorBorderColor,
          activeColor: widget.focusedBorderColor,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          itemMarginHorizontal: widget.itemMarginHorizontal,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
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
