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
  // Debounce for sending the text typed into the field, and the text waiting
  // for it. Pending text is sent when the timer fires, on blur, on submit, or
  // when the field is removed.
  Timer? _emitTimer;
  String? _pendingInput;
  FocusNode? _listenedFocusNode;
  // Values sent through onChanged that the parent has not handed back yet, in
  // order. A parent value equal to one of them is an echo of this field's input.
  final List<Object?> _awaitingEcho = [];
  static const int _kMaxAwaitingEcho = 20;
  Object? _lastEmittedValue;
  bool _hasLastEmitted = false;
  // Set in didUpdateWidget when the parent echoes this field's own input. The
  // post-frame update then leaves the text the user is typing alone.
  bool _ignoreEcho = false;
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
    _listenToFocus();
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
    if (oldWidget.focusNode != widget.focusNode) _listenToFocus();

    final valueChanged = oldWidget.currentValue != widget.currentValue;
    final formatChanged = oldWidget.customFormat != widget.customFormat;
    final stripSeparatorsChanged =
        oldWidget.stripSeparators != widget.stripSeparators;
    final verificationLengthChanged =
        oldWidget.verificationLength != widget.verificationLength;
    final verificationAsOtpChanged =
        oldWidget.verificationAsOtp != widget.verificationAsOtp;
    final formTypeChanged = oldWidget.formType != widget.formType;

    if (valueChanged) {
      // A value the parent hands back that this field sent is an echo: the text
      // the user has typed since must not be rewritten. Any other value is the
      // parent's own change and is applied as before.
      final echoIndex = _awaitingEcho.lastIndexOf(widget.currentValue);
      _ignoreEcho = echoIndex >= 0;
      if (echoIndex >= 0) {
        _awaitingEcho.removeRange(0, echoIndex + 1);
      } else {
        _awaitingEcho.clear();
        _hasLastEmitted = false;
      }
    }

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

        if (_ignoreEcho) {
          _ignoreEcho = false;
          return;
        }

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
    _flushPendingInputOnDispose();
    _listenedFocusNode?.removeListener(_onFocusChanged);
    _listenedFocusNode = null;
    _otpCountdownTimer?.cancel();
    _disposeVerificationInputs();
    model.controller.removeListener(_onControllerTextChanged);
    model.dispose();
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

  // ============================================================================
  // TEXT INPUT -> onChanged
  // ============================================================================

  /// Called for every change of the text. The text is sent once typing pauses
  /// (see [_emitDelay]), and at once on blur, on submit, or when the field is
  /// removed, so the last text typed is never left behind.
  void _onTextInput(String v) {
    _pendingInput = v;
    _emitTimer?.cancel();
    _emitTimer = Timer(_emitDelay(), _commitPendingInput);
  }

  /// Debounce for sending: 50 ms for plain numbers, 500 ms otherwise.
  Duration _emitDelay() {
    final plainNumber =
        (_isIntType() || _isDoubleType()) && !widget.stripSeparators;
    return Duration(milliseconds: plainNumber ? 50 : 500);
  }

  /// Sends the pending text now. A formatted field is reformatted once the
  /// value has actually been sent.
  void _commitPendingInput() {
    _emitTimer?.cancel();
    _emitTimer = null;
    final pending = _pendingInput;
    if (pending == null) return;
    _pendingInput = null;
    final sent = _emitInput(pending);
    if (sent && mounted && _isFormattedField()) {
      _applyFormat(_lastEmittedValue);
    }
  }

  /// Sends the pending text when the widget is removed. The send runs in a
  /// microtask, so the parent is never notified while this widget is being torn
  /// down.
  void _flushPendingInputOnDispose() {
    _emitTimer?.cancel();
    _emitTimer = null;
    final pending = _pendingInput;
    if (pending == null) return;
    _pendingInput = null;
    scheduleMicrotask(() => _emitInput(pending));
  }

  /// Sends the pending text when focus leaves the field. Deferred to a
  /// microtask, so it never runs in the middle of a focus change or a build.
  void _onFocusChanged() {
    if (!_effectiveFocusNode.hasFocus) {
      scheduleMicrotask(_commitPendingInput);
    }
  }

  /// Keeps the focus listener attached to the focus node the field uses.
  void _listenToFocus() {
    final node = _effectiveFocusNode;
    if (identical(node, _listenedFocusNode)) return;
    _listenedFocusNode?.removeListener(_onFocusChanged);
    _listenedFocusNode = node;
    node.addListener(_onFocusChanged);
  }

  /// Whether the text of this field is rewritten into a formatted form.
  bool _isFormattedField() =>
      _isPhoneType() ||
      ((_isIntType() || _isDoubleType()) && widget.stripSeparators);

  /// Writes the formatted text of [value] into the field.
  void _applyFormat(Object? value) {
    final text = _formatEmittedValue(value);
    if (model.controller.text != text) {
      model.setController = text;
    }
  }

  /// The text a formatted field shows for [value].
  String _formatEmittedValue(Object? value) {
    if (value == null) return '';
    if (_isPhoneType()) {
      _initializePhoneCountryCode(value.toString());
      return widget.formatPhone
          ? _formatPhoneLocalOnly(value.toString())
          : _extractLocalPhoneDigits(value.toString());
    }
    return _formatNumber(value as num);
  }

  /// Parses [v] for the field type and sends the result through onChanged.
  /// Returns whether a value was sent.
  bool _emitInput(String v) {
    final trimmed = v.trim();
    if (_isIntType()) {
      final cleaned = widget.stripSeparators
          ? _stripSeparatorsForParse(trimmed)
          : trimmed;
      if (cleaned.isEmpty || cleaned == '-') {
        return _isNullable() && _emitChanged(null);
      }
      final parsed = int.tryParse(cleaned);
      return parsed != null && _emitChanged(parsed);
    }
    if (_isDoubleType()) {
      final cleaned = widget.stripSeparators
          ? _stripSeparatorsForParse(trimmed)
          : trimmed;
      if (cleaned.isEmpty || cleaned == '-') {
        return _isNullable() && _emitChanged(null);
      }
      if (cleaned.endsWith('.')) return false;
      final parsed = double.tryParse(cleaned);
      return parsed != null && _emitChanged(parsed);
    }
    if (_isPhoneType()) {
      final formatted = _formatPhoneWithCode(trimmed);
      return _emitChanged(_getPhoneWithoutFormatting(formatted));
    }
    if (_isDateTimeType() || _isTimeOfDayType() || _isDateTimeRangeType()) {
      // Cannot cast a String to DateTime, TimeOfDay or DateTimeRange: skip.
      return false;
    }
    return _emitChanged(trimmed);
  }

  /// Sends [value] through onChanged and records it, so the parent handing it
  /// back can be recognised as an echo. A value equal to the last one sent is
  /// not sent again.
  bool _emitChanged(Object? value) {
    if (_hasLastEmitted && value == _lastEmittedValue) return false;
    _lastEmittedValue = value;
    _hasLastEmitted = true;
    _awaitingEcho.add(value);
    if (_awaitingEcho.length > _kMaxAwaitingEcho) {
      _awaitingEcho.removeAt(0);
    }
    widget.onChanged(value as T);
    return true;
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
