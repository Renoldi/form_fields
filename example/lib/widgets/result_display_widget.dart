import 'package:flutter/material.dart';

/// Reusable widget to display form field values in a formatted container
Widget buildResultDisplay<T>(String label, T value, {bool isOptional = false}) {
  final hasValue = value != null && value.toString().isNotEmpty;
  final displayValue = hasValue ? value.toString() : 'Not set';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (isOptional)
                Text(
                  '(Optional)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
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
