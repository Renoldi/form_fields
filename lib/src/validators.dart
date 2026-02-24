/// Form field validators for validation logic
import 'package:flutter/material.dart';
import 'utilities/extensions.dart';

/// Collection of reusable form field validators
class FormFieldValidators {
  /// Validates that the field is not empty
  static FormFieldValidator<String> required(
    String label, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      return null;
    };
  }

  /// Validates email format
  static FormFieldValidator<String> email(
    String label, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      if (!value.isValidEmail) {
        return customMessage ?? 'Enter valid email address';
      }
      return null;
    };
  }

  /// Validates phone number format
  static FormFieldValidator<String> phone(
    String label, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      if (!value.isValidPhone) {
        return customMessage ?? 'Enter valid phone number';
      }
      return null;
    };
  }

  /// Validates password (minimum 6 characters)
  static FormFieldValidator<String> password(
    String label, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      if (!value.isValidPassword) {
        return customMessage ?? 'Password must be at least 6 characters';
      }
      return null;
    };
  }

  /// Validates numeric input
  static FormFieldValidator<String> number(
    String label, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      if (!value.isValidNumber) {
        return customMessage ?? 'Enter valid number';
      }
      return null;
    };
  }

  /// Validates minimum length
  static FormFieldValidator<String> minLength(
    String label,
    int minLength, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      if (value.length < minLength) {
        return customMessage ?? '$label must be at least $minLength characters';
      }
      return null;
    };
  }

  /// Validates maximum length
  static FormFieldValidator<String> maxLength(
    String label,
    int maxLength, {
    String? customMessage,
  }) {
    return (value) {
      if (value != null && value.length > maxLength) {
        return customMessage ?? '$label must not exceed $maxLength characters';
      }
      return null;
    };
  }

  /// Validates that value is within a range (for numbers)
  static FormFieldValidator<String> range(
    String label,
    num min,
    num max, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      if (!value.isValidNumber) {
        return customMessage ?? 'Enter valid number';
      }
      final num? numValue = num.tryParse(value);
      if (numValue == null || numValue < min || numValue > max) {
        return customMessage ?? '$label must be between $min and $max';
      }
      return null;
    };
  }

  /// Validates that value matches a pattern
  static FormFieldValidator<String> pattern(
    String label,
    String pattern, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        return customMessage ?? 'Enter $label';
      }
      final regExp = RegExp(pattern);
      if (!regExp.hasMatch(value)) {
        return customMessage ?? 'Enter valid $label';
      }
      return null;
    };
  }

  /// Validates that two fields match (e.g., password confirmation)
  static FormFieldValidator<String> match(
    String label,
    String matchValue, {
    String? customMessage,
  }) {
    return (value) {
      if (value != matchValue) {
        return customMessage ?? '$label do not match';
      }
      return null;
    };
  }

  /// Combines multiple validators
  static FormFieldValidator<String> compose(
    List<FormFieldValidator<String>> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}
