import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

/// Reusable widget to display form field values in a formatted container
Widget buildResultDisplay<T>(dynamic a, dynamic b, [dynamic c]) {
  BuildContext? context;
  String label;
  T value;

  if (a is BuildContext) {
    context = a;
    label = b as String;
    value = c as T;
  } else {
    label = a as String;
    value = b as T;
  }

  final l = context != null
      ? FormFieldsLocalizations.of(context)
      : FormFieldsLocalizations.load(
          WidgetsBinding.instance.platformDispatcher.locale,
        );
  final hasValue = value != null && value.toString().isNotEmpty;
  final displayValue = hasValue ? value.toString() : l.get('notSet');

  return Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 16, left: 16, right: 16),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasValue
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        border: Border.all(
          color: hasValue
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            // padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '"$displayValue"',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w500,
                color: hasValue ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Reusable widget to display section titles with gradient background
Widget buildSectionTitle(
    String title, Color primaryColor, Color secondaryColor) {
  return Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Reusable widget to display field titles with left border
Widget buildFieldTitle(String title, Color borderColor) {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Container(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    ),
  );
}
