import 'package:flutter/material.dart';
import 'enums.dart';

class FormFieldsDropdown<T> extends FormField<T> {
  FormFieldsDropdown({
    super.key,
    required List<T> items,
    required String label,
    required ValueChanged<T?> onChanged,
    T? initialValue,
    String? Function(T?)? validator,
    bool isRequired = false,
    String Function(T item)? itemLabelBuilder,
    LabelPosition labelPosition = LabelPosition.top,
    BorderType borderType = BorderType.outlineInputBorder,
    double radius = 10,
    Color borderColor = const Color(0xFFC7C7C7),
    Color focusedBorderColor = Colors.blue,
    Color errorBorderColor = Colors.red,
    InputDecoration? decoration,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? hintText,
    bool enabled = true,
  }) : super(
          // Only use initialValue if it exists in items and is not empty
          // For String types, empty string is treated as null
          initialValue: _sanitizeInitialValue(initialValue, items),
          validator: (value) {
            if (isRequired && value == null) {
              return 'Select $label';
            }
            if (validator != null) {
              return validator(value);
            }
            return null;
          },
          builder: (FormFieldState<T> state) {
            final effectiveDecoration = (decoration ??
                    InputDecoration(
                      hintText: hintText ?? 'Select $label',
                      prefixIcon: prefixIcon,
                      suffixIcon: suffixIcon,
                    ))
                .copyWith(
              errorText: state.errorText,
              border: _buildBorder(borderType, borderColor, radius),
              enabledBorder: _buildBorder(borderType, borderColor, radius),
              focusedBorder:
                  _buildBorder(borderType, focusedBorderColor, radius),
              errorBorder: _buildBorder(borderType, errorBorderColor, radius),
              focusedErrorBorder:
                  _buildBorder(borderType, errorBorderColor, radius),
            );

            final dropdown = DropdownButtonFormField<T>(
              value: state.value,
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabelBuilder != null
                            ? itemLabelBuilder(item)
                            : item.toString(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      state.didChange(value);
                      onChanged(value);
                    }
                  : null,
              decoration: effectiveDecoration,
            );

            if (labelPosition == LabelPosition.none) {
              return dropdown;
            }

            final labelText = label;
            final requiredIndicator = isRequired ? ' *' : '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: labelText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (isRequired)
                        TextSpan(
                          text: requiredIndicator,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                dropdown,
              ],
            );
          },
        );

  static T? _sanitizeInitialValue<T>(T? initialValue, List<T> items) {
    // Return null if initialValue is null
    if (initialValue == null) return null;

    // For String types, treat empty string as null
    if (T == String) {
      final strValue = initialValue as dynamic;
      if (strValue is String && strValue.isEmpty) return null;
    }

    // Only return initialValue if it exists in items
    if (!items.contains(initialValue)) return null;

    return initialValue;
  }

  static InputBorder _buildBorder(
    BorderType type,
    Color color,
    double radius,
  ) {
    switch (type) {
      case BorderType.none:
        return InputBorder.none;
      case BorderType.underlineInputBorder:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: color),
        );
      case BorderType.outlineInputBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: 1.5),
        );
    }
  }
}
