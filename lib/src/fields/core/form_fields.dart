/// Jika true, OTP/verification field menerima karakter alfanumerik (qwerty),
/// jika false hanya angka. Default: false (hanya angka)
library;

import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/state/form_fields_states.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/src/utilities/phone_country_codes.dart'
    as phone_codes;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../service/permission_gate.dart';
import '../../utilities/theme_helpers.dart';
part 'form_fields_parts/widget.dart';

part 'form_fields_parts/validation.dart';
part 'form_fields_parts/phone.dart';
part 'form_fields_parts/verification.dart';
part 'form_fields_parts/formatting.dart';
part 'form_fields_parts/pickers.dart';
part 'form_fields_parts/barcode.dart';
part 'form_fields_parts/field_body.dart';
part 'form_fields_parts/widgets.dart';

part 'form_fields_parts/barcode_scanner.dart';

/// ---------------------------------------------------------------------------
/// FormFields Widget
/// ---------------------------------------------------------------------------
/// A beautiful, flexible, and easy-to-use form field widget for Flutter.
///
/// Supports all label positions, field types, and professional UI out of the box.
///
/// Example:
// ignore: unintended_html_in_doc_comment

class _FormFieldsState<T> extends State<FormFields<T>> {
  static const double _kExtraFieldBottom = 20.0;
  // OTP Countdown State
  Timer? _otpCountdownTimer;
  int _otpCountdownRemaining = 0;
  bool _otpCountdownFinished = false;

  late FormFieldsController model;
  late Timer debounce;
  FocusNode? _internalFocusNode;
  late ValueNotifier<double> _effectiveFieldExtraBottom;
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
    _effectiveFieldExtraBottom = ValueNotifier<double>(0.0);
    if (_isPhoneType()) {
      _initializePhoneCountryCode(widget.currentValue?.toString());
    }
    _initializeValue();
    _initializeModel();
    _initializeVerificationInputs();
    // Keep extra-bottom spacing in sync with controller changes so layout
    // adjusts correctly when user types/deletes text (including manual
    // deletion, paste, or programmatic changes).
    model.controller.addListener(_onControllerTextChanged);
    // Mulai countdown OTP jika verificationAsOtp aktif dan isOtpCountdown true
    if (_isVerificationType() &&
        widget.verificationAsOtp &&
        widget.isOtpCountdown) {
      _startOtpCountdown();
    }
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
          newControllerText = _formatTimeOfDay(
            widget.currentValue as TimeOfDay,
          );
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
            newControllerText = newControllerText.substring(
              0,
              widget.verificationLength,
            );
          }
        }

        if (_isVerificationType() && widget.verificationAsOtp) {
          if (newControllerText.length > widget.verificationLength) {
            newControllerText = newControllerText.substring(
              0,
              widget.verificationLength,
            );
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
    _otpCountdownTimer?.cancel();
    _disposeVerificationInputs();
    model.controller.removeListener(_onControllerTextChanged);
    model.dispose();
    debounce.cancel();
    _internalFocusNode?.dispose();
    _effectiveFieldExtraBottom.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _onControllerTextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final error = _computeMainFieldValidation(
        model.controller.text,
        model,
        context,
      );
      final hasText = model.controller.text.trim().isNotEmpty;
      _effectiveFieldExtraBottom.value =
          (error != null || (hasText && _effectiveFocusNode.hasFocus))
          ? _kExtraFieldBottom
          : 0.0;
    });
  }

  void _initializeValue() {
    if (widget.currentValue == null) return;

    if (_isDateTimeType()) {
      model.setControllerSilent(
        _formatDateTime(widget.currentValue as DateTime),
      );
    } else if (_isTimeOfDayType()) {
      model.setControllerSilent(
        _formatTimeOfDay(widget.currentValue as TimeOfDay),
      );
    } else if (_isDateTimeRangeType()) {
      model.setControllerSilent(
        _formatDateRange(widget.currentValue as DateTimeRange),
      );
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
      if (_isVerificationType() && widget.verificationAsOtp) {
        if (controllerText.length > widget.verificationLength) {
          controllerText = controllerText.substring(
            0,
            widget.verificationLength,
          );
        }
      }
      model.setControllerSilent(controllerText);
    }

    if (_isVerificationType() && widget.verificationAsOtp) {
      _syncVerificationControllersFromCode(model.controller.text);
    }
  }

  void _initializeModel() {
    model.formType = widget.formType;
    model.label = widget.label ?? '';
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  /// Single entry point for rebuilds requested from the helper extensions in
  /// `form_fields_parts/`. Keeps the protected `setState` call inside this class.
  void _applyStateChange(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _notifier,
      child: Consumer<FormFieldsNotifier>(
        builder: (ctx, notifier, _) {
          return ChangeNotifierProvider.value(
            value: model,
            child: Consumer<FormFieldsController>(
              builder: (ctx, vm, child) =>
                  _buildFieldBody(ctx, vm, child, context),
            ),
          );
        },
      ),
    );
  }
}
