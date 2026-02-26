/// FormFields - A comprehensive Flutter form field widget
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'controller.dart';
import 'enums.dart';
import 'localization/form_fields_localizations.dart';
import 'validators.dart';
import 'utilities/phone_country_codes.dart' as phone_codes;

class FormFields<T> extends StatefulWidget {
  // ============================================================================
  // CORE PROPERTIES
  // ============================================================================
  /// Callback when field value changes
  final ValueChanged<T> onChanged;

  /// Current value
  final T currrentValue;

  // ============================================================================
  // VALIDATION
  // ============================================================================
  /// Custom validator function
  final FormFieldValidator<String>? validator;

  /// Whether field is required
  final bool isRequired;

  /// When to show validation errors (default: onUserInteraction - validate after user interaction or form submission)
  final AutovalidateMode autovalidateMode;

  /// Minimum length for password field (default: 6)
  final int minLengthPassword;

  /// Custom password validator function
  final FormFieldValidator<String>? customPasswordValidator;

  /// Error text for minimum password length (default: 'Password must be at least X characters')
  final String? minLengthPasswordErrorText;

  // ============================================================================
  // FIELD CONFIGURATION
  // ============================================================================
  /// Form field type (email, phone, password, etc.)
  final FormType formType;

  /// Field label text
  final String label;

  /// Label position relative to input
  final LabelPosition labelPosition;

  /// Number of lines for multiline input
  final int multiLine;

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
  // FOCUS & NAVIGATION
  // ============================================================================
  /// Focus node for this field
  final FocusNode? focusNode;

  /// Next focus node for keyboard navigation
  final FocusNode? nextFocusNode;

  // ============================================================================
  // TEXT & FORMATTING
  // ============================================================================
  /// Custom text prefix for input hints (default: 'Enter ')
  final String enterText;

  /// Custom error text for invalid integer (default: 'Enter valid integer for')
  final String invalidIntegerText;

  /// Custom error text for invalid number (default: 'Enter valid number for')
  final String invalidNumberText;

  /// Whether to strip separators in numbers
  final bool stripSeparators;

  // ============================================================================
  // DATE/TIME CONFIGURATION
  // ============================================================================
  /// Custom date/time format
  final String? customFormat;

  /// Locale for date/time pickers
  final String? pickerLocale;

  /// First selectable date for date pickers (default: 100 years ago)
  final DateTime? firstDate;

  /// Last selectable date for date pickers (default: today)
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

  const FormFields({
    super.key,
    required this.onChanged,
    required this.label,
    required this.currrentValue,
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
    this.enterText = 'Enter ',
    this.invalidIntegerText = 'Enter valid integer for',
    this.invalidNumberText = 'Enter valid number for',
    this.stripSeparators = true,
    // Date/Time Configuration
    this.customFormat,
    this.pickerLocale = 'id_ID',
    this.firstDate,
    this.lastDate,
    this.useDatePickerForRange = false,
    this.phoneCountryCodes = phone_codes.phoneCountryCodes,
    this.initialCountryCode,
    this.formatPhone = false,
  });

  @override
  State<FormFields<T>> createState() => _FormFieldsState<T>();
}

class _FormFieldsState<T> extends State<FormFields<T>> {
  late FormFieldsController model;
  late Timer debounce;
  FocusNode? _internalFocusNode;
  String _selectedCountryCode = '';

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
    if (_isPhoneType()) {
      _initializePhoneCountryCode(
        widget.currrentValue?.toString(),
      );
    }
    _initializeValue();
    _initializeModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild when locale changes to update localized strings
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant FormFields<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final valueChanged = oldWidget.currrentValue != widget.currrentValue;
    final formatChanged = oldWidget.customFormat != widget.customFormat;
    final stripSeparatorsChanged =
        oldWidget.stripSeparators != widget.stripSeparators;

    if (valueChanged || formatChanged || stripSeparatorsChanged) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Skip updates during active typing for non-separator numeric fields
        // to prevent cursor jumping, but only for value changes
        // (format/separator changes should still update)
        if (valueChanged && !formatChanged && !stripSeparatorsChanged) {
          final hasFocus = _effectiveFocusNode.hasFocus;
          final isNonSeparatorNumeric =
              (_isIntType() || _isDoubleType()) && !widget.stripSeparators;
          if (hasFocus && isNonSeparatorNumeric) {
            return;
          }
        }

        String newControllerText;
        if (widget.currrentValue == null) {
          newControllerText = "";
        } else if (_isDateTimeType()) {
          newControllerText = _formatDateTime(widget.currrentValue as DateTime);
        } else if (_isTimeOfDayType()) {
          newControllerText =
              _formatTimeOfDay(widget.currrentValue as TimeOfDay);
        } else if (_isDateTimeRangeType()) {
          newControllerText = _formatDateRange(
            widget.currrentValue as DateTimeRange,
          );
        } else if (_isPhoneType()) {
          _initializePhoneCountryCode(widget.currrentValue.toString());
          final localFormatted = widget.formatPhone
              ? _formatPhoneLocalOnly(widget.currrentValue.toString())
              : _extractLocalPhoneDigits(widget.currrentValue.toString());
          newControllerText = localFormatted;
        } else if ((_isIntType() || _isDoubleType()) &&
            widget.stripSeparators) {
          newControllerText = _formatNumber(widget.currrentValue as num);
        } else if (_isIntType() || _isDoubleType()) {
          newControllerText = widget.currrentValue.toString();
        } else {
          newControllerText = widget.currrentValue.toString();
        }

        // Only update controller if the text actually changed
        // This prevents cursor jumping during active typing
        if (model.controller.text != newControllerText) {
          model.setController = newControllerText;
        }
      });
    }
  }

  @override
  void dispose() {
    model.dispose();
    debounce.cancel();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _initializeValue() {
    if (widget.currrentValue == null) return;

    if (_isDateTimeType()) {
      model.setControllerSilent(
          _formatDateTime(widget.currrentValue as DateTime));
    } else if (_isTimeOfDayType()) {
      model.setControllerSilent(
          _formatTimeOfDay(widget.currrentValue as TimeOfDay));
    } else if (_isDateTimeRangeType()) {
      model.setControllerSilent(_formatDateRange(
        widget.currrentValue as DateTimeRange,
      ));
    } else if (_isPhoneType()) {
      _initializePhoneCountryCode(widget.currrentValue.toString());
      final localFormatted = widget.formatPhone
          ? _formatPhoneLocalOnly(widget.currrentValue.toString())
          : _extractLocalPhoneDigits(widget.currrentValue.toString());
      model.setControllerSilent(localFormatted);
    } else if ((_isIntType() || _isDoubleType()) && widget.stripSeparators) {
      model.setControllerSilent(_formatNumber(widget.currrentValue as num));
    } else if (_isIntType() || _isDoubleType()) {
      model.setControllerSilent(widget.currrentValue.toString());
    } else {
      model.setControllerSilent(widget.currrentValue.toString());
    }
  }

  void _initializeModel() {
    model.formType = widget.formType;
    model.label = widget.label;
  }

  // ============================================================================
  // LOCALE HELPER
  // ============================================================================

  Locale? _parseLocale() {
    if (widget.pickerLocale == null) return null;
    final parts = widget.pickerLocale!.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(widget.pickerLocale!);
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
  bool _isTimeOfDayType() => const TimeOfDay(hour: 0, minute: 0) is T;
  bool _isDateTimeRangeType() =>
      DateTimeRange(start: DateTime(0), end: DateTime(0)) is T;

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
            setState(() {
              _selectedCountryCode = value;
              // Update text field to show only local digits
              final localFormatted = widget.formatPhone
                  ? _formatPhoneLocalOnly(model.controller.text)
                  : _extractLocalPhoneDigits(model.controller.text);
              if (model.controller.text != localFormatted) {
                model.setController = localFormatted;
              }
            });
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

    final date = await showDatePicker(
      context: ctx,
      initialDate:
          now.isAfter(last) ? last : (now.isBefore(first) ? first : now),
      firstDate: first,
      lastDate: last,
      locale: _parseLocale(),
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
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
      builder: _parseLocale() == null
          ? null
          : (context, child) => Localizations.override(
                context: context,
                locale: _parseLocale()!,
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
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
      builder: _parseLocale() == null
          ? null
          : (context, child) => Localizations.override(
                context: context,
                locale: _parseLocale()!,
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

    final date = await showDatePicker(
      context: ctx,
      initialDate:
          now.isAfter(last) ? last : (now.isBefore(first) ? first : now),
      firstDate: first,
      lastDate: last,
      locale: _parseLocale(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialTime: TimeOfDay.now(),
        builder: _parseLocale() == null
            ? null
            : (context, child) => Localizations.override(
                  context: context,
                  locale: _parseLocale()!,
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
    final now = DateTime.now();
    final first = widget.firstDate ?? now.subtract(vm.d100YEARS);
    final last = widget.lastDate ?? now;

    // Calculate smart initial date range
    DateTime initialStart;
    DateTime initialEnd;

    if (widget.currrentValue != null) {
      // Use current value if available
      final currentRange = widget.currrentValue as DateTimeRange;
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
      final startDate = await showDatePicker(
        context: ctx,
        initialDate: initialStart,
        firstDate: first,
        lastDate: last,
        locale: _parseLocale(),
      );

      if (startDate == null || !mounted) {
        return;
      }

      final normalizedInitialEnd = initialEnd.isBefore(startDate)
          ? startDate
          : (initialEnd.isAfter(last) ? last : initialEnd);

      final endDate = await showDatePicker(
        context: ctx,
        initialDate: normalizedInitialEnd,
        firstDate: startDate,
        lastDate: last,
        locale: _parseLocale(),
      );

      if (endDate != null && mounted) {
        final dateRange = DateTimeRange(start: startDate, end: endDate);
        vm.setController = _formatDateRange(dateRange);
        widget.onChanged(dateRange as T);
      }
      return;
    }

    final dateRange = await showDateRangePicker(
      context: ctx,
      firstDate: first,
      lastDate: last,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: _parseLocale(),
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

  // ============================================================================
  // VALIDATION & UI BUILDING
  // ============================================================================

  String? _validateRequired(String? value, String label, bool isRequired,
      FormFieldsController vm, FormFieldsLocalizations l10n) {
    // print('VALIDATOR: label="$label", value="$value", isRequired=$isRequired');

    // === CUSTOM VALIDATOR (Run first if provided) ===
    if (widget.validator != null) {
      final customError = widget.validator!(value);
      if (customError != null) {
        return customError;
      }
    }

    // === REQUIRED FIELD CHECK ===
    if (isRequired) {
      if (value == null || value.isEmpty) {
        // print('  → RETURNING ERROR!');
        return l10n.getWithLabel('required', label);
      }
    }

    // === SKIP IF NOT REQUIRED AND EMPTY ===
    if (!isRequired && (value == null || value.isEmpty)) {
      return null;
    }

    // === TYPE-SPECIFIC VALIDATION ===
    switch (vm.formType) {
      case FormType.phone:
        // For phone validation, validate the full number with country code
        final localDigits = _extractLocalPhoneDigits(value ?? '');
        final fullPhone = '$_selectedCountryCode$localDigits';
        return FormFieldValidators.phone(vm.label, l10n)(fullPhone);
      case FormType.email:
        return FormFieldValidators.email(vm.label, l10n)(value);
      case FormType.password:
        // Use custom validator if provided
        if (widget.customPasswordValidator != null) {
          return widget.customPasswordValidator!(value);
        }
        // Check minimum length
        if (value!.length < widget.minLengthPassword) {
          final errorText = widget.minLengthPasswordErrorText ??
              l10n.getWithValue('passwordMinLength', widget.minLengthPassword);
          return errorText;
        }
        break;
      default:
        break;
    }

    if (_isIntType()) {
      final cleaned =
          widget.stripSeparators ? _stripSeparatorsForParse(value!) : value!;
      final parsed = int.tryParse(cleaned);
      if (parsed == null) {
        return l10n.getWithLabel('enterValidInteger', vm.label);
      }
    } else if (_isDoubleType()) {
      final cleaned =
          widget.stripSeparators ? _stripSeparatorsForParse(value!) : value!;
      final parsed = double.tryParse(cleaned);
      if (parsed == null) {
        return l10n.getWithLabel('enterValidNumber', vm.label);
      }
    }

    return null;
  }

  Widget _buildLabel(FormFieldsController vm) {
    if (widget.labelPosition == LabelPosition.none ||
        widget.labelPosition == LabelPosition.inBorder) {
      return const SizedBox.shrink();
    }

    final labelText = vm.label;
    final requiredIndicator = widget.isRequired ? ' *' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: labelText,
              style: (widget.labelTextStyle ??
                      const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500))
                  .copyWith(color: Colors.black87),
            ),
            if (widget.isRequired)
              TextSpan(
                text: requiredIndicator,
                style: const TextStyle(
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

  Widget _buildFieldWithLabel(Widget textField, FormFieldsController vm) {
    if (widget.labelPosition == LabelPosition.none) return textField;

    final label = _buildLabel(vm);

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
            SizedBox(width: 120, child: label),
            const SizedBox(width: 12),
            Expanded(child: textField),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: textField),
            const SizedBox(width: 12),
            SizedBox(width: 120, child: label),
          ],
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return textField;
    }
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = FormFieldsLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: model,
      child: Consumer<FormFieldsController>(
        builder: (ctx, vm, child) {
          final phonePrefixIcon = _isPhoneType() && widget.prefixIcon == null
              ? _buildPhoneCountryCodeDropdown()
              : null;

          final textField = TextFormField(
            maxLines: vm.formType == FormType.password || widget.multiLine <= 1
                ? 1
                : widget.multiLine,
            obscureText: vm.formType == FormType.password ? vm.obscure : false,
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
                        : vm.formType == FormType.email
                            ? TextInputType.emailAddress
                            : widget.multiLine == 0
                                ? TextInputType.text
                                : TextInputType.multiline,
            inputFormatters: _getInputFormatters(),
            onChanged: (v) {
              if (debounce.isActive) debounce.cancel();

              // For non-separator numeric fields, respond immediately for smoother UX
              final useDebounce =
                  widget.stripSeparators || !(_isIntType() || _isDoubleType());
              final delay = useDebounce
                  ? const Duration(milliseconds: 500)
                  : const Duration(milliseconds: 50);

              debounce = Timer(delay, () {
                // Trim whitespace from input
                final trimmed = v.trim();

                // Handle numeric types - stripSeparators only affects formatting, not parsing
                if (_isIntType()) {
                  final cleaned = widget.stripSeparators
                      ? _stripSeparatorsForParse(trimmed)
                      : trimmed;
                  if (cleaned.isEmpty || cleaned == '-') {
                    if (_isNullable()) {
                      widget.onChanged(null as T);
                    }
                    return;
                  }
                  final parsed = int.tryParse(cleaned);
                  if (parsed != null) {
                    widget.onChanged(parsed as T);
                  }
                } else if (_isDoubleType()) {
                  final cleaned = widget.stripSeparators
                      ? _stripSeparatorsForParse(trimmed)
                      : trimmed;
                  if (cleaned.isEmpty || cleaned == '-') {
                    if (_isNullable()) {
                      widget.onChanged(null as T);
                    }
                    return;
                  }
                  if (cleaned.endsWith('.')) {
                    // Don't wait, emit null or keep previous value
                    return;
                  }
                  final parsed = double.tryParse(cleaned);
                  if (parsed != null) {
                    widget.onChanged(parsed as T);
                  }
                } else if (_isPhoneType()) {
                  final formatted = _formatPhoneWithCode(trimmed);
                  final unformatted = _getPhoneWithoutFormatting(formatted);
                  widget.onChanged(unformatted as T);
                } else {
                  // Non-numeric types
                  widget.onChanged(trimmed as T);
                }
              });
            },
            onEditingComplete: () {
              // Trim whitespace from input
              vm.controller.text = vm.controller.text.trim();

              // stripSeparators only works for numeric types (int, double)
              if ((_isIntType() || _isDoubleType()) && widget.stripSeparators) {
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
            validator: (value) => _validateRequired(
              value,
              widget.label,
              widget.isRequired,
              vm,
              l10n,
            ),
            controller: vm.controller,
            onTap: () async {
              if (!mounted) return;
              final ctx = context;
              await _showPicker(ctx, vm);
            },
            autofocus: false,
            decoration: widget.inputDecoration ??
                InputDecoration(
                  suffix:
                      vm.formType == FormType.password ? null : widget.suffix,
                  suffixIcon: vm.formType == FormType.password
                      ? IconButton(
                          icon: Icon(
                            vm.obscure
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            vm.obscure = !vm.obscure;
                          },
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
                      '${widget.enterText == 'Enter ' ? l10n.enterPrefix : widget.enterText}${vm.label}',
                  labelText: widget.labelPosition == LabelPosition.inBorder
                      ? '${widget.enterText == 'Enter ' ? l10n.enterPrefix : widget.enterText}${vm.label}${widget.isRequired ? ' *' : ''}'
                      : null,
                  focusedErrorBorder: widget.borderType == BorderType.none
                      ? InputBorder.none
                      : widget.borderType == BorderType.underlineInputBorder
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
                      : widget.borderType == BorderType.underlineInputBorder
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
                      : widget.borderType == BorderType.underlineInputBorder
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
                      : widget.borderType == BorderType.underlineInputBorder
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
                      : widget.borderType == BorderType.underlineInputBorder
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
  }
}
