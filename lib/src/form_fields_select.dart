import 'package:flutter/material.dart';

import 'enums.dart';
import 'form_fields_checkbox.dart';
import 'form_fields_dropdown.dart';
import 'form_fields_dropdown_multi.dart';
import 'form_fields_radio_button.dart';

class FormFieldsSelect<T> extends StatelessWidget {
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
    this.enableFilter = false,
    this.filterHintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    switch (formType) {
      case FormType.dropdown:
        return FormFieldsDropdown<T>(
          label: label,
          items: items,
          initialValue: initialValue,
          isRequired: isRequired,
          itemLabelBuilder: itemLabelBuilder,
          onChanged: onChanged ?? (_) {},
          validator: validator,
          labelPosition: labelPosition,
          borderType: borderType,
          radius: radius,
          borderColor: borderColor,
          focusedBorderColor: focusedBorderColor,
          errorBorderColor: errorBorderColor,
          enableFilter: enableFilter,
          filterHintText: filterHintText,
        );

      case FormType.dropdownMulti:
        return FormFieldsDropdownMulti<T>(
          label: label,
          items: items,
          initialValues: initialValues ?? [],
          isRequired: isRequired,
          itemLabelBuilder: itemLabelBuilder,
          onChanged: onMultiChanged ?? (_) {},
          validator: multiValidator,
          labelPosition: labelPosition,
          borderType: borderType,
          radius: radius,
          borderColor: borderColor,
          focusedBorderColor: focusedBorderColor,
          errorBorderColor: errorBorderColor,
          enableFilter: enableFilter,
          filterHintText: filterHintText,
        );

      case FormType.radioButton:
        return FormFieldsRadioButton<T>(
          label: label,
          items: items,
          initialValue: initialValue,
          isRequired: isRequired,
          itemLabelBuilder: itemLabelBuilder,
          onChanged: onChanged ?? (_) {},
          validator: validator,
        );

      case FormType.checkbox:
        return FormFieldsCheckbox<T>(
          label: label,
          items: items,
          initialValue: initialValues ?? [],
          isRequired: isRequired,
          itemLabelBuilder: itemLabelBuilder,
          onChanged: onMultiChanged ?? (_) {},
          validator: multiValidator != null
              ? (List<T>? values) => multiValidator!(values)
              : null,
        );

      default:
        // For all other FormType values (string, phone, password, email, etc.)
        // that are not supported by FormFieldsSelect
        throw UnimplementedError(
          'FormType.$formType is not supported by FormFieldsSelect. '
          'This widget only supports dropdown, dropdownMulti, radioButton, and checkbox.',
        );
    }
  }
}
