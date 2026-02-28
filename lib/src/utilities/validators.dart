/// Form field validators for validation logic
library;

import 'package:flutter/material.dart';
import 'extensions.dart';
import '../localization/form_fields_localizations.dart';

/// Collection of reusable form field validators
class FormFieldValidators {
  /// Validates that the field is not empty
  static FormFieldValidator<String> required(
    String label, {
    String? customMessage,
    FormFieldsLocalizations? l10n,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      return null;
    };
  }

  /// Validates email format
  static FormFieldValidator<String> email(
    String label,
    FormFieldsLocalizations? l10n, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      if (!value.isValidEmail) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.get('enterValidEmail');
        return 'Enter valid email address';
      }
      return null;
    };
  }

  /// Validates phone number format
  static FormFieldValidator<String> phone(
    String label,
    FormFieldsLocalizations? l10n, {
    String? customMessage,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      if (!value.isValidPhone) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.get('enterValidPhone');
        return 'Enter valid phone number';
      }
      return null;
    };
  }

  /// Validates password (minimum 6 characters)
  static FormFieldValidator<String> password(
    String label, {
    String? customMessage,
    FormFieldsLocalizations? l10n,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      if (!value.isValidPassword) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithValue('passwordMinLength', 6);
        return 'Password must be at least 6 characters';
      }
      return null;
    };
  }

  /// Validates numeric input
  static FormFieldValidator<String> number(
    String label, {
    String? customMessage,
    FormFieldsLocalizations? l10n,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      if (!value.isValidNumber) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('enterValidNumber', label);
        return 'Enter valid number';
      }
      return null;
    };
  }

  /// Validates minimum length
  static FormFieldValidator<String> minLength(
    String label,
    int minLength, {
    String? customMessage,
    FormFieldsLocalizations? l10n,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      if (value.length < minLength) {
        if (customMessage != null) return customMessage;
        if (l10n != null) {
          return l10n
              .getWithParams('tooShort', {'label': label, 'value': minLength});
        }
        return '$label must be at least $minLength characters';
      }
      return null;
    };
  }

  /// Validates maximum length
  static FormFieldValidator<String> maxLength(
    String label,
    int maxLength, {
    String? customMessage,
    FormFieldsLocalizations? l10n,
  }) {
    return (value) {
      if (value != null && value.length > maxLength) {
        if (customMessage != null) return customMessage;
        if (l10n != null) {
          return l10n
              .getWithParams('tooLong', {'label': label, 'value': maxLength});
        }
        return '$label must not exceed $maxLength characters';
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
    FormFieldsLocalizations? l10n,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      if (!value.isValidNumber) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('enterValidNumber', label);
        return 'Enter valid number';
      }
      final num? numValue = num.tryParse(value);
      if (numValue == null || numValue < min || numValue > max) {
        if (customMessage != null) return customMessage;
        return '$label must be between $min and $max';
      }
      return null;
    };
  }

  /// Validates that value matches a pattern
  static FormFieldValidator<String> pattern(
    String label,
    String pattern, {
    String? customMessage,
    FormFieldsLocalizations? l10n,
  }) {
    return (value) {
      if (value == null || value.isWhiteSpace) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('required', label);
        return 'Enter $label';
      }
      final regExp = RegExp(pattern);
      if (!regExp.hasMatch(value)) {
        if (customMessage != null) return customMessage;
        if (l10n != null) return l10n.getWithLabel('invalid', label);
        return 'Enter valid $label';
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
