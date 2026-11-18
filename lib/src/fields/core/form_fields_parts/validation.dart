part of '../form_fields.dart';

extension _FormFieldsValidationX<T> on _FormFieldsState<T> {
  // ============================================================================
  // TYPE CHECKING HELPERS
  // ============================================================================

  bool _isNullable() => null is T;
  bool _isIntType() => 0 is T;
  bool _isDoubleType() => 0.0 is T;
  bool _isStringType() => '' is T;
  bool _isDateTimeType() => DateTime(0) is T;
  bool _isPhoneType() => widget.formType == FormType.phone;
  bool _isVerificationType() => widget.formType == FormType.verification;
  bool _isTimeOfDayType() => const TimeOfDay(hour: 0, minute: 0) is T;
  bool _isDateTimeRangeType() =>
      DateTimeRange(start: DateTime(0), end: DateTime(0)) is T;

  // ============================================================================
  // VALIDATION & UI BUILDING
  // ============================================================================

  /// Validates field value based on requirements and type-specific rules
  String? _validateRequired(
    T? value,
    String? label,
    bool isRequired,
    FormFieldsController vm,
    BuildContext context,
  ) {
    final l = _getLocalizations(context);

    // 1. Custom validator takes precedence
    if (widget.validator != null) {
      final customError = widget.validator!(value);
      if (customError != null) return customError;
    }

    // If the widget is uncontrolled (parent didn't update `currentValue`)
    // but the internal controller has text (e.g. after a picker selection),
    // treat that as a non-empty value for validation purposes. This fixes
    // cases where date/time pickers update the controller but the parent
    // doesn't immediately pass the new `currentValue` back in.
    // The text only stands in for the value when T can hold a String. For other
    // types (DateTime, TimeOfDay, ...) a non-empty text just proves that
    // something was picked, so it counts as present without a cast.
    final ctrlText = vm.controller.text.trim();
    final textPresent = value == null && ctrlText.isNotEmpty;
    T? effectiveValue = value;
    if (textPresent && ctrlText is T?) {
      effectiveValue = ctrlText as T?;
    }

    // 2. Check required field constraint
    final isBlankString =
        effectiveValue is String && effectiveValue.trim().isEmpty;
    final isEmpty = !textPresent && (effectiveValue == null || isBlankString);

    if (isRequired && isEmpty) {
      return l.getWithLabel('required', label.toTitleCases);
    }

    // 3. Skip validation for optional empty fields
    if (!isRequired && isEmpty) {
      return null;
    }

    // 4. Type-specific validation
    switch (vm.formType) {
      case FormType.phone:
        if (effectiveValue is String) {
          final localDigits = _extractLocalPhoneDigits(effectiveValue);
          final fullPhone = '$_selectedCountryCode$localDigits';
          return FormFieldValidators.phone(vm.label.toTitleCases, l)(fullPhone);
        }
        break;
      case FormType.email:
        if (effectiveValue is String) {
          return FormFieldValidators.email(vm.label.toTitleCases, l)(
            effectiveValue,
          );
        }
        break;
      case FormType.password:
        if (widget.customPasswordValidator != null) {
          return widget.customPasswordValidator!(effectiveValue);
        }
        if (effectiveValue is String &&
            effectiveValue.length < widget.minLengthPassword) {
          return widget.minLengthPasswordErrorText ??
              l.getWithValue('passwordMinLength', widget.minLengthPassword);
        }
        break;
      case FormType.verification:
        if (effectiveValue is String) {
          if (effectiveValue.length != widget.verificationLength) {
            return l.getWithValue(
              'verificationLength',
              widget.verificationLength,
            );
          }
          // Validasi karakter jika verificationOtpAlphanumeric false (hanya angka)
          if (!widget.verificationOtpAlphanumeric &&
              !RegExp(r'^\d+$').hasMatch(effectiveValue)) {
            return l.getWithLabel('enterValidInteger', vm.label.toTitleCases);
          }
          // Jika verificationOtpAlphanumeric true, boleh angka/alfabet, tidak perlu validasi khusus
        }
        break;
      default:
        break;
    }

    // 5. Numeric type validation
    if (_isIntType()) {
      if (value is String) {
        final normalized = value.trim();
        final cleaned = widget.stripSeparators
            ? _stripSeparatorsForParse(normalized)
            : normalized;
        if (int.tryParse(cleaned) == null) {
          return l.getWithLabel('enterValidInteger', vm.label.toTitleCases);
        }
      }
    } else if (_isDoubleType()) {
      if (value is String) {
        final normalized = value.trim();
        final cleaned = widget.stripSeparators
            ? _stripSeparatorsForParse(normalized)
            : normalized;
        if (double.tryParse(cleaned) == null) {
          return l.getWithLabel('enterValidNumber', vm.label.toTitleCases);
        }
      }
    }

    return null;
  }

  String? _computeMainFieldValidation(
    String? value,
    FormFieldsController vm,
    BuildContext context,
  ) {
    if (_isIntType()) {
      final normalized = value?.trim() ?? '';
      if (normalized.isEmpty) {
        return _validateRequired(
          null,
          widget.label.toTitleCases,
          widget.isRequired,
          vm,
          context,
        );
      }
      final parsed = int.tryParse(
        widget.stripSeparators
            ? _stripSeparatorsForParse(normalized)
            : normalized,
      );
      return _validateRequired(
        parsed as T?,
        widget.label.toTitleCases,
        widget.isRequired,
        vm,
        context,
      );
    } else if (_isDoubleType()) {
      final normalized = value?.trim() ?? '';
      if (normalized.isEmpty) {
        return _validateRequired(
          null,
          widget.label.toTitleCases,
          widget.isRequired,
          vm,
          context,
        );
      }
      final parsed = double.tryParse(
        widget.stripSeparators
            ? _stripSeparatorsForParse(normalized)
            : normalized,
      );
      return _validateRequired(
        parsed as T?,
        widget.label.toTitleCases,
        widget.isRequired,
        vm,
        context,
      );
    } else if (_isDateTimeType() ||
        _isDateTimeRangeType() ||
        _isTimeOfDayType()) {
      // If the controller text is empty (user manually cleared), treat as
      // `null` so required validation runs correctly. Otherwise fall back
      // to the currentValue (the canonical typed value provided by parent).
      final controllerText = value?.trim() ?? '';
      if (controllerText.isEmpty) {
        return _validateRequired(
          null,
          widget.label.toTitleCases,
          widget.isRequired,
          vm,
          context,
        );
      }

      return _validateRequired(
        widget.currentValue,
        widget.label.toTitleCases,
        widget.isRequired,
        vm,
        context,
      );
    } else {
      // Show externalErrorText if present
      if (widget.externalErrorText != null &&
          widget.externalErrorText!.isNotEmpty) {
        return widget.externalErrorText;
      }
      return _validateRequired(
        value as T?,
        widget.label.toTitleCases,
        widget.isRequired,
        vm,
        context,
      );
    }
  }
}
