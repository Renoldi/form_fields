/// ---------------------------------------------------------------------------
/// FormFields Widget
/// ---------------------------------------------------------------------------
/// A beautiful, flexible, and easy-to-use form field widget for Flutter.
///
/// Supports all label positions, field types, and professional UI out of the box.
///
/// Example:
// ignore: unintended_html_in_doc_comment
///   FormFields<String>(
///     label: 'Email',
///     formType: FormType.email,
///     labelPosition: LabelPosition.top,
///     onChanged: (value) { /* ... */ },
///   )
/// ---------------------------------------------------------------------------
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../utilities/controller.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/validators.dart';
import '../../utilities/phone_country_codes.dart' as phone_codes;
import '../../providers/form_fields_notifier.dart';

class FormFields<T> extends StatefulWidget {
  // -------------------------------------------------------------------------
  // CORE PROPERTIES
  // -------------------------------------------------------------------------
  /// Callback when field value changes
  final ValueChanged<T> onChanged;

  /// Current value
  final T currentValue;

  // -------------------------------------------------------------------------
  // VALIDATION
  // -------------------------------------------------------------------------
  /// Custom validator function
  final FormFieldValidator<T>? validator;

  /// Whether field is required
  final bool isRequired;

  /// When to show validation errors (default: onUserInteraction)
  final AutovalidateMode autovalidateMode;

  /// Minimum length for password field (default: 6)
  final int minLengthPassword;

  /// Custom password validator function
  final FormFieldValidator<T>? customPasswordValidator;

  /// Error text for minimum password length
  final String? minLengthPasswordErrorText;

  // -------------------------------------------------------------------------
  // FIELD CONFIGURATION
  // -------------------------------------------------------------------------
  /// Form field type (email, phone, password, etc.)
  final FormType formType;

  /// Field label text
  final String label;

  /// Label position relative to input
  final LabelPosition labelPosition;

  /// Number of lines for multiline input
  final int multiLine;

  /// Number of digits for verification input (default: 6)
  final int verificationLength;

  /// Render verification input as OTP-style segmented boxes (default: true)
  final bool verificationAsOtp;

  /// Hide verification digits like password with visibility toggle (default: false)
  final bool verificationHidden;

  /// Width of each OTP input box (default: 46)
  final double otpBoxWidth;

  /// Horizontal/vertical spacing between OTP boxes (default: 10)
  final double otpBoxSpacing;

  /// Custom text style for OTP digits
  final TextStyle? otpTextStyle;

  // -------------------------------------------------------------------------
  // LOCALIZATION
  // -------------------------------------------------------------------------
  /// Custom locale for field messages, validation, and date/time pickers
  /// (overrides app locale)
  /// Supports both simple codes ('id', 'en') and full locale codes ('id_ID', 'en_US')
  final String? locale;

  // -------------------------------------------------------------------------
  // APPEARANCE & STYLING
  // -------------------------------------------------------------------------
  /// Border radius
  final double radius;

  /// Border type
  final BorderType borderType;

  /// Border color for normal state
  final Color borderColor;

  /// Border color for error state
  final Color errorBorderColor;

  /// Custom text style for label
  final TextStyle? labelTextStyle;

  /// Custom input decoration
  final InputDecoration? inputDecoration;

  // -------------------------------------------------------------------------
  // DECORATIVE ELEMENTS
  // -------------------------------------------------------------------------
  /// Widget to display before the input
  final Widget? prefix;

  /// Icon widget to display before the input
  final Widget? prefixIcon;

  /// Widget to display after the input
  final Widget? suffix;

  /// Icon widget to display after the input
  final Widget? suffixIcon;

  // -------------------------------------------------------------------------
  // FOCUS & NAVIGATION
  // -------------------------------------------------------------------------
  /// Focus node for this field
  final FocusNode? focusNode;

  /// Next focus node for keyboard navigation
  final FocusNode? nextFocusNode;

  // -------------------------------------------------------------------------
  // TEXT & FORMATTING
  // -------------------------------------------------------------------------
  /// Whether to strip separators in numbers
  final bool stripSeparators;

  // -------------------------------------------------------------------------
  // DATE/TIME CONFIGURATION
  // -------------------------------------------------------------------------
  /// Custom date/time format
  final String? customFormat;

  /// First selectable date for date pickers
  final DateTime? firstDate;

  /// Last selectable date for date pickers
  final DateTime? lastDate;

  /// Use two date pickers for range selection instead of range picker
  final bool useDatePickerForRange;

  /// List of selectable country codes for phone input
  final List<String> phoneCountryCodes;

  /// Initial country code selection for phone input
  final String? initialCountryCode;

  /// Whether to display phone with dashes in input field (default: false)
  /// Note: Result value is always returned without dashes (e.g., +628123456789)
  final bool formatPhone;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------
  const FormFields({
    super.key,
    required this.onChanged,
    required this.label,
    required this.currentValue,
    // Validation
    this.validator,
    this.isRequired = false,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.minLengthPassword = 6,
    this.customPasswordValidator,
    this.minLengthPasswordErrorText,
    // Field Configuration
    this.formType = FormType.string,
    this.labelPosition = LabelPosition.none,
    this.multiLine = 0,
    this.verificationLength = 6,
    this.verificationAsOtp = true,
    this.verificationHidden = false,
    this.otpBoxWidth = 46,
    this.otpBoxSpacing = 10,
    this.otpTextStyle,
    // Localization
    this.locale,
    // Appearance & Styling
    this.radius = 10,
    this.borderType = BorderType.outlineInputBorder,
    this.borderColor = const Color(0xFFC7C7C7),
    this.errorBorderColor = Colors.red,
    this.labelTextStyle,
    this.inputDecoration,
    // Decorative Elements
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    // Focus & Navigation
    this.focusNode,
    this.nextFocusNode,
    // Text & Formatting
    this.stripSeparators = true,
    // Date/Time Configuration
    this.customFormat,
    this.firstDate,
    this.lastDate,
    this.useDatePickerForRange = false,
    this.phoneCountryCodes = phone_codes.phoneCountryCodes,
    this.initialCountryCode,
    this.formatPhone = false,
  })  : assert(verificationLength > 0),
        assert(otpBoxWidth > 0),
        assert(otpBoxSpacing >= 0);

  @override
  State<FormFields<T>> createState() => _FormFieldsState<T>();
}

class _FormFieldsState<T> extends State<FormFields<T>> {
  late FormFieldsController model;
  late Timer debounce;
  FocusNode? _internalFocusNode;
  String _selectedCountryCode = '';
  late FormFieldsNotifier _notifier;
  List<TextEditingController> _verificationControllers = [];
  List<FocusNode> _verificationFocusNodes = [];

  FocusNode get _effectiveFocusNode {
    if (widget.focusNode != null) {
      return widget.focusNode!;
    }
    _internalFocusNode ??= FocusNode();
    return _internalFocusNode!;
  }

  @override
  void initState() {
    super.initState();
    model = FormFieldsController();
    debounce = Timer(Duration.zero, () {});
    _notifier = FormFieldsNotifier();
    if (_isPhoneType()) {
      _initializePhoneCountryCode(
        widget.currentValue?.toString(),
      );
    }
    _initializeValue();
    _initializeModel();
    _initializeVerificationInputs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild when locale changes to update localized strings
    _notifier.rebuildOnLocaleChange();
  }

  @override
  void didUpdateWidget(covariant FormFields<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final valueChanged = oldWidget.currentValue != widget.currentValue;
    final formatChanged = oldWidget.customFormat != widget.customFormat;
    final stripSeparatorsChanged =
        oldWidget.stripSeparators != widget.stripSeparators;
    final verificationLengthChanged =
        oldWidget.verificationLength != widget.verificationLength;
    final verificationAsOtpChanged =
        oldWidget.verificationAsOtp != widget.verificationAsOtp;
    final formTypeChanged = oldWidget.formType != widget.formType;

    if (formTypeChanged ||
        verificationLengthChanged ||
        verificationAsOtpChanged) {
      _initializeVerificationInputs();
    }

    if (valueChanged ||
        formatChanged ||
        stripSeparatorsChanged ||
        verificationLengthChanged ||
        verificationAsOtpChanged ||
        formTypeChanged) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Skip updates during active typing for non-separator numeric fields
        // to prevent cursor jumping, but only for value changes
        // (format/separator changes should still update)
        if (valueChanged &&
            !formatChanged &&
            !stripSeparatorsChanged &&
            !verificationLengthChanged) {
          final hasFocus = _effectiveFocusNode.hasFocus;
          final isNonSeparatorNumeric =
              (_isIntType() || _isDoubleType()) && !widget.stripSeparators;
          if (hasFocus && isNonSeparatorNumeric) {
            return;
          }
        }

        String newControllerText;
        if (widget.currentValue == null) {
          newControllerText = "";
        } else if (_isDateTimeType()) {
          newControllerText = _formatDateTime(widget.currentValue as DateTime);
        } else if (_isTimeOfDayType()) {
          newControllerText =
              _formatTimeOfDay(widget.currentValue as TimeOfDay);
        } else if (_isDateTimeRangeType()) {
          newControllerText = _formatDateRange(
            widget.currentValue as DateTimeRange,
          );
        } else if (_isPhoneType()) {
          _initializePhoneCountryCode(widget.currentValue.toString());
          final localFormatted = widget.formatPhone
              ? _formatPhoneLocalOnly(widget.currentValue.toString())
              : _extractLocalPhoneDigits(widget.currentValue.toString());
          newControllerText = localFormatted;
        } else if ((_isIntType() || _isDoubleType()) &&
            widget.stripSeparators) {
          newControllerText = _formatNumber(widget.currentValue as num);
        } else if (_isIntType() || _isDoubleType()) {
          newControllerText = widget.currentValue.toString();
        } else {
          newControllerText = widget.currentValue.toString();
          if (_isVerificationType() &&
              newControllerText.length > widget.verificationLength) {
            newControllerText =
                newControllerText.substring(0, widget.verificationLength);
          }
        }

        if (_isVerificationType()) {
          newControllerText =
              newControllerText.replaceAll(RegExp(r'[^0-9]'), '');
          if (newControllerText.length > widget.verificationLength) {
            newControllerText =
                newControllerText.substring(0, widget.verificationLength);
          }
        }

        // Only update controller if the text actually changed
        // This prevents cursor jumping during active typing
        if (model.controller.text != newControllerText) {
          model.setController = newControllerText;
        }

        if (_isVerificationType() && widget.verificationAsOtp) {
          _syncVerificationControllersFromCode(newControllerText);
        }
      });
    }
  }

  @override
  void dispose() {
    _disposeVerificationInputs();
    model.dispose();
    debounce.cancel();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _initializeValue() {
    if (widget.currentValue == null) return;

    if (_isDateTimeType()) {
      model.setControllerSilent(
          _formatDateTime(widget.currentValue as DateTime));
    } else if (_isTimeOfDayType()) {
      model.setControllerSilent(
          _formatTimeOfDay(widget.currentValue as TimeOfDay));
    } else if (_isDateTimeRangeType()) {
      model.setControllerSilent(_formatDateRange(
        widget.currentValue as DateTimeRange,
      ));
    } else if (_isPhoneType()) {
      _initializePhoneCountryCode(widget.currentValue.toString());
      final localFormatted = widget.formatPhone
          ? _formatPhoneLocalOnly(widget.currentValue.toString())
          : _extractLocalPhoneDigits(widget.currentValue.toString());
      model.setControllerSilent(localFormatted);
    } else if ((_isIntType() || _isDoubleType()) && widget.stripSeparators) {
      model.setControllerSilent(_formatNumber(widget.currentValue as num));
    } else if (_isIntType() || _isDoubleType()) {
      model.setControllerSilent(widget.currentValue.toString());
    } else {
      var controllerText = widget.currentValue.toString();
      if (_isVerificationType()) {
        controllerText = controllerText.replaceAll(RegExp(r'[^0-9]'), '');
      }
      if (_isVerificationType() &&
          controllerText.length > widget.verificationLength) {
        controllerText = controllerText.substring(0, widget.verificationLength);
      }
      model.setControllerSilent(controllerText);
    }

    if (_isVerificationType() && widget.verificationAsOtp) {
      _syncVerificationControllersFromCode(model.controller.text);
    }
  }

  void _initializeModel() {
    model.formType = widget.formType;
    model.label = widget.label;
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
    final simpleCodeMap = {
      'id': 'id_ID',
      'en': 'en_US',
    };

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

  /// Gets localization - from custom locale if provided, otherwise from context
  FormFieldsLocalizations _getLocalizations(BuildContext context) {
    final customLocale = _parseLocaleCode(widget.locale);
    if (customLocale != null) {
      return FormFieldsLocalizations.load(customLocale);
    }
    return FormFieldsLocalizations.of(context);
  }

  // ============================================================================
  // VERIFICATION (OTP) INPUT HANDLING
  // ============================================================================

  void _initializeVerificationInputs() {
    _disposeVerificationInputs();

    if (!_isVerificationType() || !widget.verificationAsOtp) {
      return;
    }

    _verificationControllers = List.generate(
      widget.verificationLength,
      (_) => TextEditingController(),
    );

    _verificationFocusNodes = List.generate(
      widget.verificationLength,
      (_) => FocusNode(),
    );

    for (int i = 0; i < _verificationFocusNodes.length; i++) {
      final index = i;
      _verificationFocusNodes[index].addListener(() {
        if (_verificationFocusNodes[index].hasFocus) {
          _selectVerificationDigit(index);
        }
      });
    }

    _syncVerificationControllersFromCode(model.controller.text);
  }

  void _disposeVerificationInputs() {
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    for (final focusNode in _verificationFocusNodes) {
      focusNode.dispose();
    }
    _verificationControllers = [];
    _verificationFocusNodes = [];
  }

  void _syncVerificationControllersFromCode(String code) {
    if (_verificationControllers.isEmpty) return;

    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = digits.length > widget.verificationLength
        ? digits.substring(0, widget.verificationLength)
        : digits;

    for (int i = 0; i < _verificationControllers.length; i++) {
      final char = i < normalized.length ? normalized[i] : '';
      if (_verificationControllers[i].text != char) {
        _verificationControllers[i].text = char;
        _verificationControllers[i].selection =
            TextSelection.collapsed(offset: char.length);
      }
    }
  }

  String _collectVerificationCode() {
    if (_verificationControllers.isEmpty) return model.controller.text;
    return _verificationControllers.map((e) => e.text).join();
  }

  void _selectVerificationDigit(int index) {
    if (index < 0 || index >= _verificationControllers.length) {
      return;
    }

    final controller = _verificationControllers[index];
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _focusVerificationDigit(int index, {bool selectAll = true}) {
    if (index < 0 || index >= _verificationFocusNodes.length) {
      return;
    }

    _verificationFocusNodes[index].requestFocus();

    if (!selectAll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectVerificationDigit(index);
    });
  }

  void _emitVerificationValue(FormFieldState<String> state) {
    final code = _collectVerificationCode();

    if (model.controller.text != code) {
      model.setController = code;
    }

    state.didChange(code);
    widget.onChanged(code as T);

    if (code.length == widget.verificationLength) {
      widget.nextFocusNode?.requestFocus();
    }
  }

  void _handleVerificationDigitChanged(
    int index,
    String rawValue,
    FormFieldState<String> state,
  ) {
    final digits = rawValue.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      if (_verificationControllers[index].text.isNotEmpty) {
        _verificationControllers[index].clear();
      }

      if (index > 0) {
        _focusVerificationDigit(index - 1);
      }

      _emitVerificationValue(state);
      return;
    }

    if (digits.length > 1) {
      int cursor = index;
      for (int i = 0;
          i < digits.length && cursor < widget.verificationLength;
          i++) {
        final char = digits[i];
        _verificationControllers[cursor].text = char;
        _verificationControllers[cursor].selection =
            const TextSelection.collapsed(offset: 1);
        cursor++;
      }

      if (cursor < widget.verificationLength) {
        _focusVerificationDigit(cursor);
      } else {
        _verificationFocusNodes.last.unfocus();
      }

      _emitVerificationValue(state);
      return;
    }

    if (_verificationControllers[index].text != digits) {
      _verificationControllers[index].text = digits;
    }

    _verificationControllers[index].selection = TextSelection.collapsed(
        offset: _verificationControllers[index].text.length);

    if (index < widget.verificationLength - 1) {
      _focusVerificationDigit(index + 1);
    } else {
      _verificationFocusNodes[index].unfocus();
    }

    _emitVerificationValue(state);
  }

  // ============================================================================
  // PHONE INPUT HANDLING
  // ============================================================================

  List<String> _effectivePhoneCountryCodes() {
    return widget.phoneCountryCodes.isNotEmpty
        ? widget.phoneCountryCodes
        : const ['+62'];
  }

  void _initializePhoneCountryCode(String? value) {
    final candidates = _effectivePhoneCountryCodes();

    if (widget.initialCountryCode != null &&
        candidates.contains(widget.initialCountryCode)) {
      _selectedCountryCode = widget.initialCountryCode!;
      return;
    }

    if (value != null && value.startsWith('+')) {
      final prefix = value.split('-').first;
      if (candidates.contains(prefix)) {
        _selectedCountryCode = prefix;
        return;
      }
    }

    // Default to Indonesia (+62) if available, otherwise use first code
    _selectedCountryCode =
        candidates.contains('+62') ? '+62' : candidates.first;
  }

  String _stripPhoneToDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _extractLocalPhoneDigits(String value) {
    final digits = _stripPhoneToDigits(value);
    final codeDigits = _stripPhoneToDigits(_selectedCountryCode);

    if (codeDigits.isNotEmpty && digits.startsWith(codeDigits)) {
      return digits.substring(codeDigits.length);
    }

    return digits;
  }

  String _formatPhoneWithCode(String value) {
    final localDigits = _extractLocalPhoneDigits(value);
    final code = _selectedCountryCode.isNotEmpty ? _selectedCountryCode : '+62';

    if (localDigits.isEmpty) {
      return code;
    }

    final first = localDigits.substring(0, localDigits.length.clamp(0, 3));
    final remaining = localDigits.length > 3 ? localDigits.substring(3) : '';
    final second = remaining.substring(0, remaining.length.clamp(0, 4));
    final tail = remaining.length > 4 ? remaining.substring(4) : '';
    final third = tail.substring(0, tail.length.clamp(0, 4));

    final parts = <String>[];
    if (first.isNotEmpty) parts.add(first);
    if (second.isNotEmpty) parts.add(second);
    if (third.isNotEmpty) parts.add(third);

    return parts.isEmpty ? code : '$code-${parts.join('-')}';
  }

  String _formatPhoneLocalOnly(String value) {
    // Format only local digits without country code (for display in text field)
    final localDigits = _extractLocalPhoneDigits(value);

    if (localDigits.isEmpty) {
      return '';
    }

    final first = localDigits.substring(0, localDigits.length.clamp(0, 3));
    final remaining = localDigits.length > 3 ? localDigits.substring(3) : '';
    final second = remaining.substring(0, remaining.length.clamp(0, 4));
    final tail = remaining.length > 4 ? remaining.substring(4) : '';
    final third = tail.substring(0, tail.length.clamp(0, 4));

    final parts = <String>[];
    if (first.isNotEmpty) parts.add(first);
    if (second.isNotEmpty) parts.add(second);
    if (third.isNotEmpty) parts.add(third);

    return parts.join('-');
  }

  String _getPhoneWithoutFormatting(String value) {
    // Remove all dashes and return only country code + digits
    // Input: +62-812-3456-7890
    // Output: +628123456789
    return value.replaceAll('-', '');
  }

  Widget _buildPhoneCountryCodeDropdown() {
    final codes = _effectivePhoneCountryCodes();
    final selected = codes.contains(_selectedCountryCode)
        ? _selectedCountryCode
        : codes.first;

    if (_selectedCountryCode != selected) {
      _selectedCountryCode = selected;
    }

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          onChanged: (value) {
            if (value == null) return;
            _selectedCountryCode = value;
            _notifier.setSelectedCountryCode(value);
            // Update text field to show only local digits
            final localFormatted = widget.formatPhone
                ? _formatPhoneLocalOnly(model.controller.text)
                : _extractLocalPhoneDigits(model.controller.text);
            if (model.controller.text != localFormatted) {
              model.setController = localFormatted;
            }
          },
          items: codes
              .map(
                (code) => DropdownMenuItem<String>(
                  value: code,
                  child: Text(
                    code,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
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
      return [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(widget.verificationLength),
      ];
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
          final pattern =
              widget.stripSeparators ? r'^-?[0-9,]*$' : r'^-?[0-9]*$';
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
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
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

  // ============================================================================
  // DATE/TIME PICKERS
  // ============================================================================

  Future<void> _handleDatePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final now = DateTime.now();
    final first = widget.firstDate ?? now.subtract(vm.d100YEARS);
    final last = widget.lastDate ?? now;
    final locale = _parseLocale(ctx);

    final date = await showDatePicker(
      context: ctx,
      initialDate:
          now.isAfter(last) ? last : (now.isBefore(first) ? first : now),
      firstDate: first,
      lastDate: last,
      locale: locale,
    );

    if (date != null && mounted) {
      vm.setController = widget.customFormat != null
          ? DateFormat(widget.customFormat).format(date)
          : DateFormat.yMMMd().format(date);
      widget.onChanged(date as T);
    }
  }

  Future<void> _handleTimePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final locale = _parseLocale(ctx);

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
      builder: locale == null
          ? null
          : (context, child) => Localizations.override(
                context: context,
                locale: locale,
                child: child!,
              ),
    );

    if (time != null && mounted) {
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      vm.setController = widget.customFormat != null
          ? DateFormat(widget.customFormat).format(dateTime)
          : DateFormat.jm().format(dateTime);
      widget.onChanged(dateTime as T);
    }
  }

  Future<void> _handleTimeOfDayPicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final locale = _parseLocale(ctx);

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
      builder: locale == null
          ? null
          : (context, child) => Localizations.override(
                context: context,
                locale: locale,
                child: child!,
              ),
    );

    if (time != null && mounted) {
      vm.setController = _formatTimeOfDay(time);
      widget.onChanged(time as T);
    }
  }

  Future<void> _handleDateTimePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    final now = DateTime.now();
    final first = widget.firstDate ?? now.subtract(vm.d100YEARS);
    final last = widget.lastDate ?? now;
    final locale = _parseLocale(ctx);

    final date = await showDatePicker(
      context: ctx,
      initialDate:
          now.isAfter(last) ? last : (now.isBefore(first) ? first : now),
      firstDate: first,
      lastDate: last,
      locale: locale,
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialTime: TimeOfDay.now(),
        builder: locale == null
            ? null
            : (context, child) => Localizations.override(
                  context: context,
                  locale: locale,
                  child: child!,
                ),
      );

      if (time != null && mounted) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        vm.setController = widget.customFormat != null
            ? DateFormat(widget.customFormat).format(dateTime)
            : DateFormat.yMMMd().add_jm().format(dateTime);
        widget.onChanged(dateTime as T);
      }
    }
  }

  Future<void> _handleDateRangePicker(
    BuildContext ctx,
    FormFieldsController vm,
  ) async {
    if (!mounted) return;
    final now = DateTime.now();
    final first = widget.firstDate ?? now.subtract(vm.d100YEARS);
    final last = widget.lastDate ?? now;
    final locale = _parseLocale(ctx);

    // Calculate smart initial date range
    DateTime initialStart;
    DateTime initialEnd;

    if (widget.currentValue != null) {
      // Use current value if available
      final currentRange = widget.currentValue as DateTimeRange;
      initialStart = currentRange.start;
      initialEnd = currentRange.end;
    } else {
      // Create default 7-day range respecting constraints
      initialStart = now.isAfter(last)
          ? last.subtract(const Duration(days: 7))
          : (now.isBefore(first) ? first : now);
      initialEnd = initialStart.add(const Duration(days: 7));

      // Ensure end date doesn't exceed lastDate
      if (initialEnd.isAfter(last)) {
        initialEnd = last;
      }

      // Ensure start date is not before firstDate
      if (initialStart.isBefore(first)) {
        initialStart = first;
      }
    }

    if (widget.useDatePickerForRange) {
      if (!mounted) return; // Guard before first async operation
      final startDate = await showDatePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialDate: initialStart,
        firstDate: first,
        lastDate: last,
        locale: locale,
      );

      if (startDate == null) {
        return;
      }

      final normalizedInitialEnd = initialEnd.isBefore(startDate)
          ? startDate
          : (initialEnd.isAfter(last) ? last : initialEnd);

      if (!mounted) return; // Guard before second async operation
      final endDate = await showDatePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialDate: normalizedInitialEnd,
        firstDate: startDate,
        lastDate: last,
        locale: locale,
      );

      if (endDate != null && mounted) {
        final dateRange = DateTimeRange(start: startDate, end: endDate);
        vm.setController = _formatDateRange(dateRange);
        widget.onChanged(dateRange as T);
      }
      return;
    }

    if (!mounted) return; // Guard before third async operation
    final dateRange = await showDateRangePicker(
      // ignore: use_build_context_synchronously
      context: ctx,
      firstDate: first,
      lastDate: last,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: locale,
    );

    if (dateRange != null && mounted) {
      vm.setController = _formatDateRange(dateRange);
      widget.onChanged(dateRange as T);
    }
  }

  Future<void> _showPicker(BuildContext ctx, FormFieldsController vm) async {
    if (_isDateTimeType()) {
      switch (widget.formType) {
        case FormType.date:
          await _handleDatePicker(ctx, vm);
          break;
        case FormType.time:
          await _handleTimePicker(ctx, vm);
          break;
        case FormType.dateTime:
          await _handleDateTimePicker(ctx, vm);
          break;
        default:
          await _handleDatePicker(ctx, vm);
          break;
      }
    } else if (_isTimeOfDayType()) {
      await _handleTimeOfDayPicker(ctx, vm);
    } else if (_isDateTimeRangeType()) {
      await _handleDateRangePicker(ctx, vm);
    }
  }

  // ============================================================================
  // ICON HANDLING
  // ============================================================================

  IconData _getPickerIcon() {
    if (_isDateTimeRangeType()) {
      return Icons.date_range;
    }

    switch (widget.formType) {
      case FormType.time:
        return Icons.access_time;
      case FormType.dateTime:
        return Icons.calendar_today;
      case FormType.date:
      default:
        return Icons.calendar_today;
    }
  }

  void _handleClearIconTap(FormFieldsController vm) {
    if (_isIntType()) {
      if (_isNullable()) {
        vm.setController = "";
        widget.onChanged(null as T);
        return;
      }
      vm.setController = _formatNumber(0);
      widget.onChanged(0 as T);
    } else if (_isDoubleType()) {
      if (_isNullable()) {
        vm.setController = "";
        widget.onChanged(null as T);
        return;
      }
      vm.setController = _formatNumber(0.0);
      widget.onChanged(0.0 as T);
    } else if (_isStringType()) {
      vm.setController = "";
      if (_isNullable()) {
        widget.onChanged(null as T);
      } else {
        widget.onChanged("" as T);
      }
    } else if (_isDateTimeType() || _isDateTimeRangeType()) {
      vm.setController = "";
      if (_isNullable()) {
        widget.onChanged(null as T);
      }
    } else {
      vm.setController = "";
      if (_isNullable()) {
        widget.onChanged(null as T);
      }
    }
  }

  void _handleVisibilityToggleTap(FormFieldsController vm) {
    vm.obscure = !vm.obscure;
  }

  // ============================================================================
  // VALIDATION & UI BUILDING
  // ============================================================================

  /// Validates field value based on requirements and type-specific rules
  String? _validateRequired(
    T? value,
    String label,
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

    // 2. Check required field constraint
    if (isRequired && (value == null || (value is String && value.isEmpty))) {
      return l.getWithLabel('required', label);
    }

    // 3. Skip validation for optional empty fields
    if (!isRequired && (value == null || (value is String && value.isEmpty))) {
      return null;
    }

    // 4. Type-specific validation
    switch (vm.formType) {
      case FormType.phone:
        if (value is String) {
          final localDigits = _extractLocalPhoneDigits(value);
          final fullPhone = '$_selectedCountryCode$localDigits';
          return FormFieldValidators.phone(vm.label, l)(fullPhone);
        }
        break;
      case FormType.email:
        if (value is String) {
          return FormFieldValidators.email(vm.label, l)(value);
        }
        break;
      case FormType.password:
        if (widget.customPasswordValidator != null) {
          return widget.customPasswordValidator!(value);
        }
        if (value is String && value.length < widget.minLengthPassword) {
          return widget.minLengthPasswordErrorText ??
              l.getWithValue(
                'passwordMinLength',
                widget.minLengthPassword,
              );
        }
        break;
      case FormType.verification:
        if (value is String && value.length != widget.verificationLength) {
          return l.getWithValue(
            'verificationLength',
            widget.verificationLength,
          );
        }
        break;
      default:
        break;
    }

    // 5. Numeric type validation
    if (_isIntType()) {
      if (value is String) {
        final cleaned =
            widget.stripSeparators ? _stripSeparatorsForParse(value) : value;
        if (int.tryParse(cleaned) == null) {
          return l.getWithLabel('enterValidInteger', vm.label);
        }
      }
    } else if (_isDoubleType()) {
      if (value is String) {
        final cleaned =
            widget.stripSeparators ? _stripSeparatorsForParse(value) : value;
        if (double.tryParse(cleaned) == null) {
          return l.getWithLabel('enterValidNumber', vm.label);
        }
      }
    }

    return null;
  }

  /// Builds the label widget for the form field
  Widget _buildLabel(FormFieldsController vm) {
    // Don't show label for none or inBorder positions
    if (widget.labelPosition == LabelPosition.none ||
        widget.labelPosition == LabelPosition.inBorder) {
      return const SizedBox.shrink();
    }

    final defaultLabelStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final labelStyle = (widget.labelTextStyle ?? defaultLabelStyle)
        .copyWith(color: Colors.black87);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: vm.label, style: labelStyle),
            if (widget.isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Positions the text field with its label based on labelPosition setting
  Widget _buildFieldWithLabel(Widget textField, FormFieldsController vm) {
    if (widget.labelPosition == LabelPosition.none) return textField;

    final label = _buildLabel(vm);
    const labelWidth = 120.0;
    const spacing = 12.0;

    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [label, textField],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [textField, label],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: labelWidth, child: label),
            const SizedBox(width: spacing),
            Expanded(child: textField),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: textField),
            const SizedBox(width: spacing),
            SizedBox(width: labelWidth, child: label),
          ],
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return textField;
    }
  }

  /// Creates a consistent border style for OTP input boxes
  InputBorder _buildOtpBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Builds the input decoration for OTP boxes with proper error states
  InputDecoration _buildOtpInputDecoration({required bool hasError}) {
    final base = widget.inputDecoration;

    // Define border styles based on state
    final normalBorder = base?.enabledBorder ??
        base?.border ??
        _buildOtpBorder(widget.borderColor);
    final focusedBorder =
        base?.focusedBorder ?? _buildOtpBorder(widget.borderColor, width: 1.4);
    final errorBorder =
        base?.errorBorder ?? _buildOtpBorder(widget.errorBorderColor);
    final focusedErrorBorder = base?.focusedErrorBorder ??
        _buildOtpBorder(widget.errorBorderColor, width: 1.4);

    return (base ?? const InputDecoration()).copyWith(
      // Clear text-field adornments - OTP boxes should be minimal
      counterText: '',
      hintText: null,
      labelText: null,
      helperText: null,
      prefix: null,
      prefixIcon: null,
      suffix: null,
      suffixIcon: null,
      // Visual styling
      filled: base?.filled ?? true,
      fillColor: base?.fillColor ?? const Color(0xFFF1F1F1),
      contentPadding:
          base?.contentPadding ?? const EdgeInsets.symmetric(vertical: 14),
      // Border states
      border: hasError ? errorBorder : (base?.border ?? normalBorder),
      enabledBorder: hasError ? errorBorder : normalBorder,
      focusedBorder: hasError ? focusedErrorBorder : focusedBorder,
      disabledBorder:
          hasError ? errorBorder : (base?.disabledBorder ?? normalBorder),
    );
  }

  /// Builds a single OTP digit input box
  Widget _buildOtpDigitBox({
    required int index,
    required InputDecoration decoration,
    required FormFieldState<String> state,
    required FormFieldsController vm,
  }) {
    final isLastDigit = index == widget.verificationLength - 1;

    return SizedBox(
      width: widget.otpBoxWidth,
      child: TextField(
        controller: _verificationControllers[index],
        focusNode: _verificationFocusNodes[index],
        keyboardType: TextInputType.number,
        obscureText: widget.verificationHidden && vm.obscure,
        obscuringCharacter: '•',
        textInputAction:
            isLastDigit ? TextInputAction.done : TextInputAction.next,
        textAlign: TextAlign.center,
        style: widget.otpTextStyle ??
            const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onTap: () => _selectVerificationDigit(index),
        onChanged: (value) =>
            _handleVerificationDigitChanged(index, value, state),
        decoration: decoration,
      ),
    );
  }

  /// Builds the OTP verification field with multiple digit boxes
  Widget _buildVerificationOtpField(
    FormFieldsController vm,
    BuildContext context,
  ) {
    return FormField<String>(
      initialValue: model.controller.text,
      autovalidateMode: widget.autovalidateMode,
      validator: (value) => _validateRequired(
        value as T?,
        widget.label,
        widget.isRequired,
        vm,
        context,
      ),
      builder: (state) {
        final hasError = state.hasError;
        final boxDecoration = _buildOtpInputDecoration(hasError: hasError);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: widget.otpBoxSpacing,
                runSpacing: widget.otpBoxSpacing,
                children: [
                  // Generate OTP digit boxes
                  for (var i = 0; i < widget.verificationLength; i++)
                    _buildOtpDigitBox(
                      index: i,
                      decoration: boxDecoration,
                      state: state,
                      vm: vm,
                    ),
                  // Optional visibility toggle for hidden verification
                  if (widget.verificationHidden)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        iconSize: 18,
                        icon: Icon(
                          vm.obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () => _handleVisibilityToggleTap(vm),
                      ),
                    ),
                ],
              ),
            ),
            // Error message display
            if (hasError && state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: widget.errorBorderColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _notifier,
      child: Consumer<FormFieldsNotifier>(
        builder: (ctx, notifier, _) {
          return ChangeNotifierProvider.value(
            value: model,
            child: Consumer<FormFieldsController>(
              builder: (ctx, vm, child) {
                if (_isVerificationType() && widget.verificationAsOtp) {
                  final verificationField =
                      _buildVerificationOtpField(vm, context);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: _buildFieldWithLabel(verificationField, vm),
                  );
                }

                final phonePrefixIcon =
                    _isPhoneType() && widget.prefixIcon == null
                        ? _buildPhoneCountryCodeDropdown()
                        : null;

                final textField = TextFormField(
                  textAlignVertical: (widget.multiLine > 1)
                      ? TextAlignVertical.center
                      : TextAlignVertical.top,
                  textAlign: TextAlign.start,
                  maxLength:
                      _isVerificationType() ? widget.verificationLength : null,
                  maxLines: vm.formType == FormType.password ||
                          _isVerificationType() ||
                          widget.multiLine <= 1
                      ? 1
                      : widget.multiLine,
                  obscureText: vm.formType == FormType.password ||
                          (_isVerificationType() && widget.verificationHidden)
                      ? vm.obscure
                      : false,
                  obscuringCharacter: '•',
                  autovalidateMode: widget.autovalidateMode,
                  focusNode: _effectiveFocusNode,
                  onFieldSubmitted: (_) => widget.nextFocusNode?.requestFocus(),
                  keyboardType: _isDateTimeType() ||
                          _isTimeOfDayType() ||
                          _isDateTimeRangeType()
                      ? TextInputType.none
                      : _isIntType() || _isDoubleType()
                          ? TextInputType.number
                          : vm.formType == FormType.phone
                              ? TextInputType.phone
                              : _isVerificationType()
                                  ? TextInputType.number
                                  : vm.formType == FormType.email
                                      ? TextInputType.emailAddress
                                      : widget.multiLine == 0
                                          ? TextInputType.text
                                          : TextInputType.multiline,
                  inputFormatters: _getInputFormatters(),
                  onChanged: (v) {
                    if (debounce.isActive) debounce.cancel();
                    final useDebounce = widget.stripSeparators ||
                        !(_isIntType() || _isDoubleType());
                    final delay = useDebounce
                        ? const Duration(milliseconds: 500)
                        : const Duration(milliseconds: 50);
                    debounce = Timer(delay, () {
                      final trimmed = v.trim();
                      if (_isIntType()) {
                        final cleaned = widget.stripSeparators
                            ? _stripSeparatorsForParse(trimmed)
                            : trimmed;
                        if (cleaned.isEmpty || cleaned == '-') {
                          if (_isNullable()) widget.onChanged(null as T);
                          return;
                        }
                        final parsed = int.tryParse(cleaned);
                        if (parsed != null) widget.onChanged(parsed as T);
                      } else if (_isDoubleType()) {
                        final cleaned = widget.stripSeparators
                            ? _stripSeparatorsForParse(trimmed)
                            : trimmed;
                        if (cleaned.isEmpty || cleaned == '-') {
                          if (_isNullable()) widget.onChanged(null as T);
                          return;
                        }
                        if (cleaned.endsWith('.')) return;
                        final parsed = double.tryParse(cleaned);
                        if (parsed != null) widget.onChanged(parsed as T);
                      } else if (_isPhoneType()) {
                        final formatted = _formatPhoneWithCode(trimmed);
                        final unformatted =
                            _getPhoneWithoutFormatting(formatted);
                        widget.onChanged(unformatted as T);
                      } else if (_isDateTimeType() || _isTimeOfDayType()) {
                        // Do not cast String to DateTime or TimeOfDay, just skip
                        // Only update controller, not value
                      } else if (_isDateTimeRangeType()) {
                        // Do not cast String to DateTimeRange, just skip
                        // Only update controller, not value
                      } else {
                        widget.onChanged(trimmed as T);
                      }
                    });
                  },
                  onEditingComplete: () {
                    // Trim whitespace from input
                    vm.controller.text = vm.controller.text.trim();

                    // stripSeparators only works for numeric types (int, double)
                    if ((_isIntType() || _isDoubleType()) &&
                        widget.stripSeparators) {
                      final text = vm.controller.text;
                      if (text.isEmpty) return;
                      final cleaned = _stripSeparatorsForParse(text);
                      if (cleaned.isEmpty ||
                          cleaned == '-' ||
                          cleaned.endsWith('.')) {
                        return;
                      }

                      if (_isIntType()) {
                        final parsed = int.tryParse(cleaned);
                        if (parsed != null) {
                          vm.setController = _formatNumber(parsed);
                        }
                      } else if (_isDoubleType()) {
                        final parsed = double.tryParse(cleaned);
                        if (parsed != null) {
                          vm.setController = _formatNumber(parsed);
                        }
                      }
                    }
                  },
                  validator: (value) {
                    if (_isIntType()) {
                      if (value == null || value.isEmpty) {
                        return _validateRequired(
                          null,
                          widget.label,
                          widget.isRequired,
                          vm,
                          context,
                        );
                      }
                      final parsed = int.tryParse(widget.stripSeparators
                          ? _stripSeparatorsForParse(value)
                          : value);
                      return _validateRequired(
                        parsed as T?,
                        widget.label,
                        widget.isRequired,
                        vm,
                        context,
                      );
                    } else if (_isDoubleType()) {
                      if (value == null || value.isEmpty) {
                        return _validateRequired(
                          null,
                          widget.label,
                          widget.isRequired,
                          vm,
                          context,
                        );
                      }
                      final parsed = double.tryParse(widget.stripSeparators
                          ? _stripSeparatorsForParse(value)
                          : value);
                      return _validateRequired(
                        parsed as T?,
                        widget.label,
                        widget.isRequired,
                        vm,
                        context,
                      );
                    } else if (_isDateTimeType() ||
                        _isDateTimeRangeType() ||
                        _isTimeOfDayType()) {
                      // Use widget.currentValue for validation, not value from controller
                      return _validateRequired(
                        widget.currentValue,
                        widget.label,
                        widget.isRequired,
                        vm,
                        context,
                      );
                    } else {
                      return _validateRequired(
                        value as T?,
                        widget.label,
                        widget.isRequired,
                        vm,
                        context,
                      );
                    }
                  },
                  controller: vm.controller,
                  onTap: () async {
                    if (!mounted) return;
                    final ctx = context;
                    await _showPicker(ctx, vm);
                  },
                  autofocus: false,
                  decoration: widget.inputDecoration ??
                      InputDecoration(
                        contentPadding: (widget.multiLine > 1)
                            ? const EdgeInsets.symmetric(
                                vertical: 22, horizontal: 16)
                            : const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                        suffix: vm.formType == FormType.password ||
                                (_isVerificationType() &&
                                    widget.verificationHidden)
                            ? null
                            : widget.suffix,
                        suffixIcon: vm.formType == FormType.password ||
                                (_isVerificationType() &&
                                    widget.verificationHidden)
                            ? IconButton(
                                splashRadius: 20,
                                iconSize: 20,
                                icon: Icon(
                                  vm.obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () => _handleVisibilityToggleTap(vm),
                              )
                            : (_isDateTimeType() ||
                                    _isTimeOfDayType() ||
                                    _isDateTimeRangeType())
                                ? IconButton(
                                    icon: Icon(_getPickerIcon()),
                                    onPressed: () async {
                                      if (!mounted) return;
                                      final ctx = context;
                                      await _showPicker(ctx, vm);
                                    },
                                  )
                                : widget.suffixIcon ??
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _handleClearIconTap(vm),
                                    ),
                        prefix: widget.prefix,
                        prefixIcon: phonePrefixIcon ?? widget.prefixIcon,
                        hintText:
                            '${_getLocalizations(context).enterPrefix}${vm.label}',
                        labelText: widget.labelPosition ==
                                LabelPosition.inBorder
                            ? '${_getLocalizations(context).enterPrefix}${vm.label}${widget.isRequired ? ' *' : ''}'
                            : null,
                        focusedErrorBorder: widget.borderType == BorderType.none
                            ? InputBorder.none
                            : widget.borderType ==
                                    BorderType.underlineInputBorder
                                ? const UnderlineInputBorder()
                                : OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(widget.radius),
                                    borderSide: BorderSide(
                                      width: 1,
                                      color: widget.errorBorderColor,
                                    ),
                                  ),
                        focusedBorder: widget.borderType == BorderType.none
                            ? InputBorder.none
                            : widget.borderType ==
                                    BorderType.underlineInputBorder
                                ? const UnderlineInputBorder()
                                : OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(widget.radius),
                                    borderSide: BorderSide(
                                      width: 1,
                                      color: widget.borderColor,
                                    ),
                                  ),
                        enabledBorder: widget.borderType == BorderType.none
                            ? InputBorder.none
                            : widget.borderType ==
                                    BorderType.underlineInputBorder
                                ? const UnderlineInputBorder()
                                : OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(widget.radius),
                                    borderSide: BorderSide(
                                      width: 1,
                                      color: widget.borderColor,
                                    ),
                                  ),
                        border: widget.borderType == BorderType.none
                            ? InputBorder.none
                            : widget.borderType ==
                                    BorderType.underlineInputBorder
                                ? const UnderlineInputBorder()
                                : OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(widget.radius),
                                    borderSide: BorderSide(
                                      width: 1,
                                      color: widget.borderColor,
                                    ),
                                  ),
                        disabledBorder: widget.borderType == BorderType.none
                            ? InputBorder.none
                            : widget.borderType ==
                                    BorderType.underlineInputBorder
                                ? const UnderlineInputBorder()
                                : OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(widget.radius),
                                    borderSide: BorderSide(
                                      width: 1,
                                      color: widget.borderColor,
                                    ),
                                  ),
                      ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: _buildFieldWithLabel(textField, vm),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
