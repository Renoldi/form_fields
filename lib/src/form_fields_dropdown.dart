/// FormFieldsDropdown - Flutter dropdown form field widget
import 'package:flutter/material.dart';

import 'controller.dart';
import 'enums.dart';

/// Dropdown selection form field widget
class FormFieldsDropdown<T> extends StatefulWidget {
  // ============================================================================
  // CORE PROPERTIES
  // ============================================================================
  /// Callback when field value changes
  final ValueChanged<T> onChanged;

  /// Current value
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

  /// Custom input decoration
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
  // DROPDOWN SPECIFIC
  // ============================================================================
  /// Hint text for dropdown
  final String? dropdownHint;

  /// Whether to show item count below dropdown (for info purposes)
  final bool showItemCount;

  const FormFieldsDropdown({
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
    // Dropdown Specific
    this.dropdownHint,
    this.showItemCount = false,
  });

  @override
  State<FormFieldsDropdown<T>> createState() => _FormFieldsDropdownState<T>();
}

class _FormFieldsDropdownState<T> extends State<FormFieldsDropdown<T>> {
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
  void didUpdateWidget(covariant FormFieldsDropdown<T> oldWidget) {
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
    model.formType = FormType.dropdown;
    model.label = widget.label;
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================
  /// Validate the field
  String? _validateField() {
    if (!widget.isRequired) return null;

    if (widget.currentValue == null || widget.currentValue.toString().isEmpty) {
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
  /// Build beautiful dropdown widget
  Widget _buildDropdown() {
    final currentValue = widget.currentValue;
    final displayValue =
        currentValue != null && currentValue.toString().isNotEmpty
            ? currentValue.toString()
            : null;

    return DropdownButtonFormField<String>(
      initialValue: displayValue,
      items: widget.options
          .map((option) => DropdownMenuItem<String>(
                value: option,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Text(
                    option,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          widget.onChanged(value as T);
        }
      },
      validator: widget.isRequired ? (_) => _validateField() : null,
      autovalidateMode: AutovalidateMode.always,
      decoration: widget.inputDecoration ??
          InputDecoration(
            hintText: widget.dropdownHint ?? 'Select ${widget.label}',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefix: widget.prefix,
            prefixIcon: widget.prefixIcon,
            suffix: widget.suffix,
            suffixIcon: widget.suffixIcon,
            // Enhanced borders
            border: _buildBorder(widget.borderColor),
            enabledBorder: _buildBorder(widget.borderColor),
            focusedBorder: _buildBorder(widget.focusedBorderColor),
            errorBorder: _buildBorder(widget.errorBorderColor),
            focusedErrorBorder: _buildBorder(widget.errorBorderColor),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
    );
  }

  // ============================================================================
  // STYLING UTILITIES
  // ============================================================================
  /// Build border based on type with smooth transitions
  InputBorder _buildBorder(Color color) {
    if (widget.borderType == BorderType.none) {
      return InputBorder.none;
    } else if (widget.borderType == BorderType.underlineInputBorder) {
      return UnderlineInputBorder(
        borderSide: BorderSide(color: color),
      );
    } else {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.radius),
        borderSide: BorderSide(color: color, width: 1.5),
      );
    }
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: _buildFieldWithLabel(_buildDropdown()),
    );
  }
}
