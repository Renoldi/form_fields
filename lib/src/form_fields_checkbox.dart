/// FormFieldsCheckbox - Flutter checkbox form field widget
import 'package:flutter/material.dart';

import 'controller.dart';
import 'enums.dart';

/// Checkbox selection form field widget
class FormFieldsCheckbox<T> extends StatefulWidget {
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
  /// Field label text
  final String label;

  /// Label position relative to input
  final LabelPosition labelPosition;

  /// Whether to allow multiple selections
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

  // ============================================================================
  // ITEM CUSTOMIZATION
  // ============================================================================
  /// Icon size for checkbox (default: 24)
  final double iconSize;

  /// Space between checkbox and label in a row
  final double itemSpacing;

  /// Icon color for checkbox (default: Colors.blue)
  final Color itemIconColor;

  /// Active icon color for checkbox (default: Colors.blue)
  final Color activeIconColor;

  /// Background color for checkbox when active
  final Color? activeCheckboxColor;

  /// Direction for checkbox layout: Axis.vertical or Axis.horizontal
  final Axis itemDirection;

  /// Custom padding for items in checkbox
  final EdgeInsets itemPadding;

  /// Whether items should fill available space
  final bool fillItems;

  const FormFieldsCheckbox({
    super.key,
    required this.onChanged,
    required this.label,
    required this.currentValue,
    required this.options,
    // Validation
    this.validator,
    this.isRequired = false,
    // Field Configuration
    this.labelPosition = LabelPosition.top,
    this.isMultiple = false,
    // Appearance & Styling
    this.radius = 10,
    this.borderType = BorderType.outlineInputBorder,
    this.borderColor = const Color(0xFFC7C7C7),
    this.errorBorderColor = Colors.red,
    this.focusedBorderColor = Colors.blue,
    this.labelTextStyle,
    // Item Customization
    this.iconSize = 24,
    this.itemSpacing = 8,
    this.itemIconColor = Colors.grey,
    this.activeIconColor = Colors.blue,
    this.activeCheckboxColor,
    this.itemDirection = Axis.vertical,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    this.fillItems = false,
  });

  @override
  State<FormFieldsCheckbox<T>> createState() => _FormFieldsCheckboxState<T>();
}

class _FormFieldsCheckboxState<T> extends State<FormFieldsCheckbox<T>> {
  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================
  late FormFieldsController model;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================
  @override
  void initState() {
    super.initState();
    model = FormFieldsController();
    _initializeValue();
    _initializeModel();
  }

  @override
  void didUpdateWidget(covariant FormFieldsCheckbox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      _initializeValue();
    }
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  void _initializeValue() {
    if (widget.currentValue == null) {
      model.setControllerSilent("");
    } else {
      model.setControllerSilent(widget.currentValue.toString());
    }
  }

  void _initializeModel() {
    model.formType = FormType.checkbox;
    model.label = widget.label;
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================
  /// Validate the field
  String? _validateField() {
    if (!widget.isRequired) return null;

    if (widget.isMultiple && widget.currentValue is List) {
      final list = widget.currentValue as List;
      if (list.isEmpty) {
        return 'Select at least one option for ${widget.label}';
      }
    } else if (widget.currentValue == null ||
        widget.currentValue.toString().isEmpty) {
      return 'Select ${widget.label}';
    }

    if (widget.validator != null) {
      return widget.validator!(widget.currentValue.toString());
    }

    return null;
  }

  // ============================================================================
  // UI BUILDERS - LABEL & LAYOUT
  // ============================================================================
  /// Build the label widget
  Widget _buildLabel() {
    if (widget.labelPosition == LabelPosition.none ||
        widget.labelPosition == LabelPosition.inBorder) {
      return const SizedBox.shrink();
    }

    final labelText = widget.label;
    final requiredMarker = widget.isRequired ? ' *' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        labelText + requiredMarker,
        style: widget.labelTextStyle ??
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
      ),
    );
  }

  /// Build field with label based on labelPosition
  Widget _buildFieldWithLabel(Widget field) {
    // Add subtle shadow container for depth
    final styledField = Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: field,
    );
    if (widget.labelPosition == LabelPosition.none) return field;

    final label = _buildLabel();

    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 12),
            styledField,
          ],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            styledField,
            const SizedBox(height: 12),
            label,
          ],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: label),
            const SizedBox(width: 16),
            Expanded(child: styledField),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: styledField),
            const SizedBox(width: 16),
            SizedBox(width: 120, child: label),
          ],
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return styledField;
    }
  }

  // ============================================================================
  // UI BUILDERS - FORM FIELD
  // ============================================================================
  /// Build beautiful checkbox options with enhanced styling
  Widget _buildCheckboxes() {
    final selectedValues = widget.isMultiple && widget.currentValue is List
        ? (widget.currentValue as List).cast<String>()
        : (widget.currentValue?.toString() ?? '').isNotEmpty
            ? [widget.currentValue.toString()]
            : <String>[];

    final errorText = _validateField();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color:
              errorText != null ? widget.errorBorderColor : widget.borderColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.itemDirection == Axis.horizontal)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: widget.itemSpacing,
                runSpacing: 8,
                children: widget.options
                    .map((option) => SizedBox(
                          width: widget.fillItems
                              ? (MediaQuery.of(context).size.width - 60) /
                                  widget.options.length
                              : null,
                          child: CheckboxListTile(
                            value: selectedValues.contains(option),
                            onChanged: (isChecked) {
                              _handleCheckboxChange(
                                  option, isChecked ?? false, selectedValues);
                            },
                            title: Text(
                              option,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            activeColor: widget.activeCheckboxColor ??
                                widget.activeIconColor,
                          ),
                        ))
                    .toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: widget.options
                    .map((option) => CheckboxListTile(
                          value: selectedValues.contains(option),
                          onChanged: (isChecked) {
                            _handleCheckboxChange(
                                option, isChecked ?? false, selectedValues);
                          },
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          dense: true,
                          contentPadding: widget.itemPadding,
                          activeColor: widget.activeCheckboxColor ??
                              widget.activeIconColor,
                        ))
                    .toList(),
              ),
            ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: widget.errorBorderColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: widget.errorBorderColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================
  /// Handle checkbox changes
  void _handleCheckboxChange(
      String option, bool isChecked, List<String> selectedValues) {
    if (widget.isMultiple) {
      final updatedList = List<String>.from(selectedValues);
      if (isChecked) {
        if (!updatedList.contains(option)) {
          updatedList.add(option);
        }
      } else {
        updatedList.remove(option);
      }
      widget.onChanged(updatedList as T);
    } else {
      if (isChecked) {
        widget.onChanged(option as T);
      } else {
        widget.onChanged('' as T);
      }
    }
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: _buildFieldWithLabel(_buildCheckboxes()),
    );
  }
}
