/// FormFieldsSelect - Convenience wrapper for selection form fields
import 'package:flutter/material.dart';

import 'enums.dart';
import 'form_fields_checkbox.dart';
import 'form_fields_dropdown.dart';
import 'form_fields_radio_button.dart';

/// Convenience widget that delegates to specific selection widgets (dropdown, radio, checkbox)
///
/// This widget provides backward compatibility and a unified interface for all selection types.
/// For new code, consider using the specific widgets directly:
/// - [FormFieldsDropdown] for dropdown selections
/// - [FormFieldsRadioButton] for radio button selections
/// - [FormFieldsCheckbox] for checkbox selections
class FormFieldsSelect<T> extends StatelessWidget {
  // ============================================================================
  // CORE PROPERTIES
  // ============================================================================
  /// Callback when field value changes
  final ValueChanged<T> onChanged;

  /// Current value(s) - can be single or list depending on isMultiple
  final T currentValue;

  /// List of options to display
  final List<String> options;

  // ============================================================================
  // VALIDATION
  // ============================================================================
  /// Custom validator function
  final FormFieldValidator<String>? validator;

  /// Whether field is required
  final bool isRequired;

  // ============================================================================
  // FIELD CONFIGURATION
  // ============================================================================
  /// Form field type (dropdown, radioButton, checkbox)
  final FormType formType;

  /// Field label text
  final String label;

  /// Label position relative to input
  final LabelPosition labelPosition;

  /// Whether to allow multiple selections (for checkbox)
  final bool isMultiple;

  // ============================================================================
  // APPEARANCE & STYLING
  // ============================================================================
  /// Border radius
  final double radius;

  /// Border type
  final BorderType borderType;

  /// Border color for normal state (default: Color(0xFFC7C7C7))
  final Color borderColor;

  /// Border color for error state (default: Colors.red)
  final Color errorBorderColor;

  /// Border color for focused state
  final Color focusedBorderColor;

  /// Custom text style for label (default: fontSize 14, fontWeight w500)
  final TextStyle? labelTextStyle;

  /// Custom input decoration (for dropdown)
  final InputDecoration? inputDecoration;

  // ============================================================================
  // DECORATIVE ELEMENTS
  // ============================================================================
  /// Widget to display before the input
  final Widget? prefix;

  /// Icon widget to display before the input
  final Widget? prefixIcon;

  /// Widget to display after the input
  final Widget? suffix;

  /// Icon widget to display after the input
  final Widget? suffixIcon;

  // ============================================================================
  // ITEM CUSTOMIZATION (Radio/Checkbox)
  // ============================================================================
  /// Icon size for radio/checkbox (default: 24)
  final double iconSize;

  /// Space between radio/checkbox and label in a row
  final double itemSpacing;

  /// Icon color for radio/checkbox (default: Colors.blue)
  final Color itemIconColor;

  /// Active icon color for radio/checkbox (default: Colors.blue)
  final Color activeIconColor;

  /// Background color for checkbox when active
  final Color? activeCheckboxColor;

  /// Direction for radio/checkbox layout: Axis.vertical or Axis.horizontal
  final Axis itemDirection;

  /// Custom padding for items in radio/checkbox
  final EdgeInsets itemPadding;

  /// Whether items should fill available space
  final bool fillItems;

  // ============================================================================
  // DROPDOWN SPECIFIC
  // ============================================================================
  /// Hint text for dropdown
  final String? dropdownHint;

  /// Whether to show item count below dropdown (for info purposes)
  final bool showItemCount;

  const FormFieldsSelect({
    super.key,
    required this.onChanged,
    required this.label,
    required this.currentValue,
    required this.options,
    // Validation
    this.validator,
    this.isRequired = false,
    // Field Configuration
    this.formType = FormType.dropdown,
    this.labelPosition = LabelPosition.top,
    this.isMultiple = false,
    // Appearance & Styling
    this.radius = 10,
    this.borderType = BorderType.outlineInputBorder,
    this.borderColor = const Color(0xFFC7C7C7),
    this.errorBorderColor = Colors.red,
    this.focusedBorderColor = Colors.blue,
    this.labelTextStyle,
    this.inputDecoration,
    // Decorative Elements
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    // Item Customization
    this.iconSize = 24,
    this.itemSpacing = 8,
    this.itemIconColor = Colors.grey,
    this.activeIconColor = Colors.blue,
    this.activeCheckboxColor,
    this.itemDirection = Axis.vertical,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    this.fillItems = false,
    // Dropdown Specific
    this.dropdownHint,
    this.showItemCount = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (formType) {
      case FormType.dropdown:
        return FormFieldsDropdown<T>(
          onChanged: onChanged,
          label: label,
          currentValue: currentValue,
          options: options,
          validator: validator,
          isRequired: isRequired,
          labelPosition: labelPosition,
          radius: radius,
          borderType: borderType,
          borderColor: borderColor,
          errorBorderColor: errorBorderColor,
          focusedBorderColor: focusedBorderColor,
          labelTextStyle: labelTextStyle,
          inputDecoration: inputDecoration,
          prefix: prefix,
          prefixIcon: prefixIcon,
          suffix: suffix,
          suffixIcon: suffixIcon,
          dropdownHint: dropdownHint,
          showItemCount: showItemCount,
        );

      case FormType.radioButton:
        return FormFieldsRadioButton<T>(
          label: label,
          items: options.cast<T>(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          initialValue: currentValue,
          validator: validator == null
              ? null
              : (value) => validator!(value?.toString() ?? ''),
          isRequired: isRequired,
          direction: itemDirection,
          radius: radius,
          borderColor: borderColor,
          errorBorderColor: errorBorderColor,
          activeColor: activeIconColor,
          itemPadding: itemPadding,
        );

      case FormType.checkbox:
        return FormFieldsCheckbox<T>(
          onChanged: onChanged,
          label: label,
          currentValue: currentValue,
          options: options,
          validator: validator,
          isRequired: isRequired,
          isMultiple: isMultiple,
          labelPosition: labelPosition,
          radius: radius,
          borderType: borderType,
          borderColor: borderColor,
          errorBorderColor: errorBorderColor,
          focusedBorderColor: focusedBorderColor,
          labelTextStyle: labelTextStyle,
          iconSize: iconSize,
          itemSpacing: itemSpacing,
          itemIconColor: itemIconColor,
          activeIconColor: activeIconColor,
          activeCheckboxColor: activeCheckboxColor,
          itemDirection: itemDirection,
          itemPadding: itemPadding,
          fillItems: fillItems,
        );

      default:
        return FormFieldsDropdown<T>(
          onChanged: onChanged,
          label: label,
          currentValue: currentValue,
          options: options,
          validator: validator,
          isRequired: isRequired,
          labelPosition: labelPosition,
          radius: radius,
          borderType: borderType,
          borderColor: borderColor,
          errorBorderColor: errorBorderColor,
          focusedBorderColor: focusedBorderColor,
          labelTextStyle: labelTextStyle,
          inputDecoration: inputDecoration,
          prefix: prefix,
          prefixIcon: prefixIcon,
          suffix: suffix,
          suffixIcon: suffixIcon,
          dropdownHint: dropdownHint,
          showItemCount: showItemCount,
        );
    }
  }
}
