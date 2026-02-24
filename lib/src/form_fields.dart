/// FormFields - A comprehensive Flutter form field widget
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'controller.dart';
import 'enums.dart';
import 'validators.dart';
import 'utilities/extensions.dart';
import 'utilities/colors.dart';

class FormFields<T> extends StatefulWidget {
  /// Callback when field value changes
  final ValueChanged<T> onChanged;

  /// Custom validator function
  final FormFieldValidator<String>? validator;

  /// Current value
  final T? currrentValue;

  /// Next focus node for keyboard navigation
  final FocusNode? nextFocusNode;

  /// Focus node for this field
  final FocusNode? focusNode;

  /// Widget to display before the input
  final Widget? prefix;

  /// Icon widget to display before the input
  final Widget? prefixIcon;

  /// Widget to display after the input
  final Widget? suffix;

  /// Icon widget to display after the input
  final Widget? suffixIcon;

  /// Custom input decoration
  final InputDecoration? inputDecoration;

  /// Form field type (email, phone, password, etc.)
  final FormType formType;

  /// Field label text
  final String label;

  /// Label position relative to input
  final LabelPosition labelPosition;

  /// Whether field is required
  final bool isRequired;

  /// Border radius
  final double radius;

  /// Border type
  final BorderType borderType;

  /// Number of lines for multiline input
  final int multiLine;

  /// Custom date/time format
  final String? customFormat;

  /// Whether to strip separators in numbers
  final bool stripSeparators;

  /// Locale for date/time pickers
  final String? pickerLocale;

  /// Custom text prefix for input hints (default: 'Enter ')
  final String enterText;

  /// Custom error text for invalid integer (default: 'Enter valid integer for')
  final String invalidIntegerText;

  /// Custom error text for invalid number (default: 'Enter valid number for')
  final String invalidNumberText;

  const FormFields({
    super.key,
    required this.onChanged,
    required this.label,
    this.validator,
    this.currrentValue,
    this.nextFocusNode,
    this.focusNode,
    this.prefix,
    this.inputDecoration,
    this.formType = FormType.string,
    this.labelPosition = LabelPosition.none,
    this.isRequired = false,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.radius = 10,
    this.multiLine = 0,
    this.borderType = BorderType.outlineInputBorder,
    this.customFormat,
    this.stripSeparators = true,
    this.pickerLocale = 'id_ID',
    this.enterText = 'Enter ',
    this.invalidIntegerText = 'Enter valid integer for',
    this.invalidNumberText = 'Enter valid number for',
  });

  @override
  State<FormFields<T>> createState() => _FormFieldsState<T>();
}

class _FormFieldsState<T> extends State<FormFields<T>> {
  late FormFieldsController model;
  late Timer debounce;

  @override
  void initState() {
    super.initState();
    model = FormFieldsController();
    debounce = Timer(Duration.zero, () {});
    _initializeValue();
    _initializeModel();
  }

  @override
  void didUpdateWidget(covariant FormFields<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final valueChanged = oldWidget.currrentValue != widget.currrentValue;
    final formatChanged = oldWidget.customFormat != widget.customFormat;
    final stripSeparatorsChanged =
        oldWidget.stripSeparators != widget.stripSeparators;

    if (valueChanged || formatChanged || stripSeparatorsChanged) {
      if (widget.currrentValue == null) {
        model.setController = "";
      } else if (_isDateTimeType()) {
        model.setController = _formatDateTime(widget.currrentValue as DateTime);
      } else if (_isTimeOfDayType()) {
        model.setController =
            _formatTimeOfDay(widget.currrentValue as TimeOfDay);
      } else if (_isDateTimeRangeType()) {
        model.setController = _formatDateRange(
          widget.currrentValue as DateTimeRange,
        );
      } else if ((_isIntType() || _isDoubleType()) && widget.stripSeparators) {
        model.setController = _formatNumber(widget.currrentValue as num);
      } else if (_isIntType() || _isDoubleType()) {
        model.setController = widget.currrentValue.toString();
      } else {
        model.setController = widget.currrentValue.toString();
      }
    }
  }

  @override
  void dispose() {
    model.dispose();
    debounce.cancel();
    super.dispose();
  }

  void _initializeValue() {
    if (widget.currrentValue == null) return;

    if (_isDateTimeType()) {
      model.setController = _formatDateTime(widget.currrentValue as DateTime);
    } else if (_isTimeOfDayType()) {
      model.setController = _formatTimeOfDay(widget.currrentValue as TimeOfDay);
    } else if (_isDateTimeRangeType()) {
      model.setController = _formatDateRange(
        widget.currrentValue as DateTimeRange,
      );
    } else if ((_isIntType() || _isDoubleType()) && widget.stripSeparators) {
      model.setController = _formatNumber(widget.currrentValue as num);
    } else if (_isIntType() || _isDoubleType()) {
      model.setController = widget.currrentValue.toString();
    } else {
      model.setController = widget.currrentValue.toString();
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
  bool _isTimeOfDayType() => const TimeOfDay(hour: 0, minute: 0) is T;
  bool _isDateTimeRangeType() =>
      DateTimeRange(start: DateTime(0), end: DateTime(0)) is T;

  // ============================================================================
  // NUMBER FORMATTING & INPUT HANDLING
  // ============================================================================

  String _formatNumber(num value) {
    if (!widget.stripSeparators) return value.toString();
    if (_isIntType() && widget.stripSeparators) {
      return NumberFormat('#,###', 'en_US').format(value);
    } else if (_isDoubleType() && widget.stripSeparators) {
      return NumberFormat('#,##0.##########', 'en_US').format(value);
    }
    return value.toString();
  }

  String _stripSeparators(String value) {
    if (!widget.stripSeparators ||
        (!(_isIntType() && widget.stripSeparators) &&
            !(_isDoubleType() && widget.stripSeparators))) {
      return value;
    }
    return value.replaceAll(',', '');
  }

  String _stripSeparatorsForParse(String value) {
    return value.replaceAll(',', '');
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (!widget.stripSeparators) return [];
    if ((_isIntType() || _isDoubleType()) && widget.stripSeparators) {
      return [
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) {
            return newValue;
          }

          final cleaned = _stripSeparators(newValue.text);

          if (_isIntType() && widget.stripSeparators) {
            if (!RegExp(r'^-?[0-9]*$').hasMatch(cleaned)) {
              return oldValue;
            }
          } else if (_isDoubleType() && widget.stripSeparators) {
            if (!RegExp(r'^-?[0-9]*\.?[0-9]*$').hasMatch(cleaned)) {
              return oldValue;
            }
          }

          if (cleaned.isEmpty || cleaned == '-') {
            return newValue;
          }

          try {
            if (_isIntType() && widget.stripSeparators) {
              final number = int.parse(cleaned);
              final formatted = _formatNumber(number);
              return TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            } else if (_isDoubleType() && widget.stripSeparators) {
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
    return [];
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
    final date = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(vm.d100YEARS),
      lastDate: DateTime.now(),
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
    final date = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(vm.d100YEARS),
      lastDate: DateTime.now(),
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
    final dateRange = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime.now().subtract(vm.d100YEARS),
      lastDate: DateTime.now(),
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

  String? _validateField(String? value, FormFieldsController vm) {
    switch (vm.formType) {
      case FormType.phone:
        return FormFieldValidators.phone(vm.label)(value);
      case FormType.email:
        return FormFieldValidators.email(vm.label)(value);
      case FormType.password:
        return FormFieldValidators.password(vm.label)(value);
      default:
        break;
    }

    if (_isIntType()) {
      if (value != null && !value.isWhiteSpace) {
        final cleaned = _stripSeparatorsForParse(value);
        final parsed = int.tryParse(cleaned);
        if (parsed == null) {
          return '${widget.invalidIntegerText} ${vm.label}';
        }
      } else {
        return FormFieldValidators.required(vm.label)(value);
      }
    } else if (_isDoubleType()) {
      if (value != null && !value.isWhiteSpace) {
        final cleaned = _stripSeparatorsForParse(value);
        final parsed = double.tryParse(cleaned);
        if (parsed == null) {
          return '${widget.invalidNumberText} ${vm.label}';
        }
      } else {
        return FormFieldValidators.required(vm.label)(value);
      }
    } else if (_isStringType()) {
      return FormFieldValidators.required(vm.label)(value);
    } else if (_isDateTimeType() || _isDateTimeRangeType()) {
      return FormFieldValidators.required(vm.label)(value);
    }

    return null;
  }

  Widget _buildLabel(FormFieldsController vm) {
    if (widget.labelPosition == LabelPosition.none ||
        widget.labelPosition == LabelPosition.inBorder) {
      return const SizedBox.shrink();
    }

    final labelText = '${widget.enterText}${vm.label}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        labelText,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    return ChangeNotifierProvider.value(
      value: model,
      child: Consumer<FormFieldsController>(
        builder: (ctx, vm, child) {
          final textField = TextFormField(
            maxLines: vm.formType == FormType.password || widget.multiLine <= 1
                ? 1
                : widget.multiLine,
            obscureText: vm.formType == FormType.password ? vm.obscure : false,
            autovalidateMode: AutovalidateMode.always,
            focusNode: widget.focusNode,
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
              debounce = Timer(const Duration(milliseconds: 500), () {
                if (_isIntType() && widget.stripSeparators) {
                  final cleaned = _stripSeparatorsForParse(v);
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
                } else if (_isDoubleType() && widget.stripSeparators) {
                  final cleaned = _stripSeparatorsForParse(v);
                  if (cleaned.isEmpty ||
                      cleaned == '-' ||
                      cleaned.endsWith('.')) {
                    if (_isNullable()) {
                      widget.onChanged(null as T);
                    }
                    return;
                  }
                  final parsed = double.tryParse(cleaned);
                  if (parsed != null) {
                    widget.onChanged(parsed as T);
                  }
                } else {
                  widget.onChanged(v as T);
                }
              });
            },
            onEditingComplete: () {
              if (widget.stripSeparators && (_isIntType() || _isDoubleType())) {
                final text = vm.controller.text;
                if (text.isEmpty) return;
                final cleaned = _stripSeparatorsForParse(text);
                if (cleaned.isEmpty ||
                    cleaned == '-' ||
                    cleaned.endsWith('.')) {
                  return;
                }

                if (_isIntType() && widget.stripSeparators) {
                  final parsed = int.tryParse(cleaned);
                  if (parsed != null) {
                    vm.setController = _formatNumber(parsed);
                  }
                } else if (_isDoubleType() && widget.stripSeparators) {
                  final parsed = double.tryParse(cleaned);
                  if (parsed != null) {
                    vm.setController = _formatNumber(parsed);
                  }
                }
              }
            },
            validator: widget.isRequired
                ? widget.validator ?? (value) => _validateField(value, vm)
                : null,
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
                  prefixIcon: widget.prefixIcon,
                  hintText: '${widget.enterText}${vm.label}',
                  labelText: widget.labelPosition == LabelPosition.inBorder
                      ? '${widget.enterText}${vm.label}'
                      : null,
                  focusedErrorBorder: widget.borderType == BorderType.none
                      ? InputBorder.none
                      : widget.borderType == BorderType.underlineInputBorder
                          ? const UnderlineInputBorder()
                          : OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(widget.radius),
                              borderSide: const BorderSide(
                                width: 1,
                                color: ColorUtil.redColor,
                              ),
                            ),
                  focusedBorder: widget.borderType == BorderType.none
                      ? InputBorder.none
                      : widget.borderType == BorderType.underlineInputBorder
                          ? const UnderlineInputBorder()
                          : OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(widget.radius),
                              borderSide: const BorderSide(
                                width: 1,
                                color: ColorUtil.colorC7C7C7,
                              ),
                            ),
                  enabledBorder: widget.borderType == BorderType.none
                      ? InputBorder.none
                      : widget.borderType == BorderType.underlineInputBorder
                          ? const UnderlineInputBorder()
                          : OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(widget.radius),
                              borderSide: const BorderSide(
                                width: 1,
                                color: ColorUtil.colorC7C7C7,
                              ),
                            ),
                  border: widget.borderType == BorderType.none
                      ? InputBorder.none
                      : widget.borderType == BorderType.underlineInputBorder
                          ? const UnderlineInputBorder()
                          : OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(widget.radius),
                              borderSide: const BorderSide(
                                width: 1,
                                color: ColorUtil.colorC7C7C7,
                              ),
                            ),
                  disabledBorder: widget.borderType == BorderType.none
                      ? InputBorder.none
                      : widget.borderType == BorderType.underlineInputBorder
                          ? const UnderlineInputBorder()
                          : OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(widget.radius),
                              borderSide: const BorderSide(
                                width: 1,
                                color: ColorUtil.colorC7C7C7,
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
