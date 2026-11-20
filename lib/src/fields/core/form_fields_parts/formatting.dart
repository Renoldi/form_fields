part of '../form_fields.dart';

extension _FormFieldsFormattingX<T> on _FormFieldsState<T> {
  // Merge caller-provided InputDecoration with ThemeData.inputDecorationTheme
  InputDecoration _effectiveInputDecoration(InputDecoration? base) {
    final theme = Theme.of(context).inputDecorationTheme;
    return (base ?? const InputDecoration()).applyDefaults(theme);
  }

  // ============================================================================
  // LOCALE HELPER
  // ============================================================================

  Locale? _parseLocaleCode(String? localeCode) {
    final rawLocale = localeCode?.trim();
    if (rawLocale == null || rawLocale.isEmpty) {
      return null;
    }

    // Support simple language codes used by this package API.
    final simpleCodeMap = {'id': 'id_ID', 'en': 'en_US'};

    final mapped = simpleCodeMap[rawLocale.toLowerCase()] ?? rawLocale;
    final normalized = mapped.replaceAll('-', '_');
    final parts = normalized.split('_');

    if (parts.isEmpty || parts.first.isEmpty) {
      return null;
    }

    final languageCode = parts[0].toLowerCase();

    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return Locale(languageCode, parts[1].toUpperCase());
    }

    return Locale(languageCode);
  }

  Locale? _parseLocale(BuildContext context) {
    return _parseLocaleCode(widget.locale) ??
        Localizations.maybeLocaleOf(context);
  }

  /// Gets localization - from custom locale if provided, otherwise from context
  FormFieldsLocalizations _getLocalizations(BuildContext context) {
    final customLocale = _parseLocaleCode(widget.locale);
    if (customLocale != null) {
      return FormFieldsLocalizations.load(customLocale);
    }
    return FormFieldsLocalizations.of(context);
  }

  // ============================================================================
  // NUMBER FORMATTING & INPUT HANDLING
  // ============================================================================

  String _formatNumber(num value) {
    // stripSeparators only works for numeric types (int, double)
    if (!_isIntType() && !_isDoubleType()) {
      return value.toString();
    }

    if (!widget.stripSeparators) return value.toString();

    if (_isIntType()) {
      return NumberFormat('#,###', 'en_US').format(value);
    } else if (_isDoubleType()) {
      return NumberFormat('#,##0.##########', 'en_US').format(value);
    }
    return value.toString();
  }

  String _stripSeparators(String value) {
    // stripSeparators only works for numeric types (int, double)
    if (!_isIntType() && !_isDoubleType()) {
      return value;
    }

    if (!widget.stripSeparators) {
      return value;
    }

    return value.replaceAll(',', '');
  }

  String _stripSeparatorsForParse(String value) {
    return value.replaceAll(',', '');
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (_isPhoneType()) {
      return [
        TextInputFormatter.withFunction((oldValue, newValue) {
          final localDigits = _extractLocalPhoneDigits(newValue.text);
          if (!widget.formatPhone) {
            // Return unformatted local digits only (no dashes, no country code)
            return TextEditingValue(
              text: localDigits,
              selection: TextSelection.collapsed(offset: localDigits.length),
            );
          }
          // Return formatted local digits only (with dashes, no country code)
          final formatted = _formatPhoneLocalOnly(newValue.text);
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }),
      ];
    }

    if (_isVerificationType()) {
      if (widget.verificationOtpAlphanumeric) {
        // Alfanumerik: tidak ada filter, hanya batasi panjang
        return [LengthLimitingTextInputFormatter(widget.verificationLength)];
      } else {
        // Hanya angka
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.verificationLength),
        ];
      }
    }

    // For numeric types, always restrict to numeric input
    if (!_isIntType() && !_isDoubleType()) {
      return [];
    }

    return [
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) {
          return newValue;
        }

        final cleaned = widget.stripSeparators
            ? _stripSeparators(newValue.text)
            : newValue.text;

        // Validate numeric input
        if (_isIntType()) {
          final pattern = widget.stripSeparators
              ? r'^-?[0-9,]*$'
              : r'^-?[0-9]*$';
          if (!RegExp(pattern).hasMatch(cleaned)) {
            return oldValue;
          }
        } else if (_isDoubleType()) {
          final pattern = widget.stripSeparators
              ? r'^-?[0-9,]*\.?[0-9]*$'
              : r'^-?[0-9]*\.?[0-9]*$';
          if (!RegExp(pattern).hasMatch(cleaned)) {
            return oldValue;
          }
        }

        if (cleaned.isEmpty || cleaned == '-') {
          return newValue;
        }

        // Apply formatting only if stripSeparators is true
        if (!widget.stripSeparators) {
          // No formatting - just validate and return as-is
          return newValue;
        }

        try {
          if (_isIntType()) {
            final number = int.parse(cleaned);
            final formatted = _formatNumber(number);
            return TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          } else if (_isDoubleType()) {
            if (cleaned.endsWith('.')) {
              final intPart = cleaned.substring(0, cleaned.length - 1);
              if (intPart.isEmpty || intPart == '-') {
                return newValue.copyWith(text: cleaned);
              }
              final number = double.parse(intPart);
              final formatted = _formatNumber(number);
              return TextEditingValue(
                text: '$formatted.',
                selection: TextSelection.collapsed(
                  offset: formatted.length + 1,
                ),
              );
            }
            final number = double.parse(cleaned);
            final formatted = _formatNumber(number);
            return TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        } catch (e) {
          return oldValue;
        }

        return newValue;
      }),
    ];
  }

  // ============================================================================
  // DATE/TIME FORMATTING
  // ============================================================================

  String _formatDateTime(DateTime dateTime) {
    if (widget.customFormat != null) {
      return DateFormat(widget.customFormat).format(dateTime);
    }

    switch (widget.formType) {
      case FormType.date:
        return DateFormat.yMMMd().format(dateTime);
      case FormType.time:
        return DateFormat.jm().format(dateTime);
      case FormType.dateTime:
        return DateFormat.yMMMd().add_jm().format(dateTime);
      default:
        return dateTime.toString();
    }
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (widget.customFormat != null) {
      return DateFormat(widget.customFormat).format(dateTime);
    }
    return DateFormat.jm().format(dateTime);
  }

  String _formatDateRange(DateTimeRange dateRange) {
    final format = widget.customFormat != null
        ? DateFormat(widget.customFormat)
        : DateFormat.yMMMd();
    return '${format.format(dateRange.start)} - ${format.format(dateRange.end)}';
  }
}
