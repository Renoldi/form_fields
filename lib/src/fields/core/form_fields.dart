/// Jika true, OTP/verification field menerima karakter alfanumerik (qwerty),
/// jika false hanya angka. Default: false (hanya angka)
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/providers/form_fields_notifier.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/src/utilities/phone_country_codes.dart'
    as phone_codes;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../service/permission_gate.dart';
import '../../utilities/theme_helpers.dart';

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
class FormFields<T> extends StatefulWidget {
  /// If true, the field is read-only (default: false)
  final bool readOnly;

  /// Tipe border untuk OTP (box/underline)
  final OtpBorderType otpBorderType;
  final bool verificationOtpAlphanumeric;

  /// Error text injected from external (e.g. backend validation)
  final String? externalErrorText;

  /// Default builder for OTP countdown text (multi-language)
  static String _defaultOtpCountdownTextBuilder(
      BuildContext context, int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final hStr = h.toString().padLeft(2, '0');
    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');
    return '$hStr:$mStr:$sStr';
  }

  /// Default resend OTP text widget (multi-language, styled, clickable)
  static Widget defaultOtpResendText({
    required BuildContext context,
    required VoidCallback? onResend,
    TextStyle? style,
    TextStyle? linkStyle,
  }) {
    final localizations = FormFieldsLocalizations.of(context);
    final resendPrefix = localizations
        .get('otpResendPrefix'); //?? 'Didn\'t receive activation code? ';
    final resendLink = localizations.get('otpResendLink'); //?? 'Resend';
    final isEnabled = onResend != null;
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Text.rich(
          TextSpan(
            text: resendPrefix,
            style: style ??
                TextStyle(color: resolveTextColor(context), fontSize: 14),
            children: [
              TextSpan(
                text: resendLink,
                style: linkStyle ??
                    TextStyle(
                      color: isEnabled
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                recognizer: isEnabled
                    ? (TapGestureRecognizer()..onTap = onResend)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builder for countdown text. Receives context and remaining seconds.
  final String Function(BuildContext context, int seconds)?
      otpCountdownTextBuilder;

  /// Custom input formatters for OTP input (default: digits only)
  final List<TextInputFormatter>? otpInputFormatters;

  /// Countdown duration for OTP (default: 60 detik)
  final Duration otpCountdownDuration;

  /// Callback ketika countdown selesai
  final VoidCallback? onOtpCountdownComplete;
  final VoidCallback? onRemove;

  /// Callback ketika tombol reload OTP ditekan
  final VoidCallback? onOtpCountdownReload;
  // -------------------------------------------------------------------------
  // CORE PROPERTIES
  // -------------------------------------------------------------------------
  /// Callback when field value changes
  final ValueChanged<T> onChanged;

  /// Current value
  final T? currentValue;

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
  final FormType? formType;

  /// Field label text
  final String? label;

  /// Label position relative to input
  final LabelPosition labelPosition;

  /// Number of lines for multiline input
  final int multiLine;

  /// Size presets for the field height. Matches `AppButtonSize` presets.
  final AppSize fieldSize;

  /// Custom height when `fieldSize` is `AppButtonSize.custom`.
  final double? customFieldHeight;

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

  /// Custom text style for label
  final TextStyle? labelTextStyle;

  /// Custom input decoration
  final InputDecoration? inputDecoration;

  /// Optional color for action buttons in pickers (e.g. Save button)
  final Color? saveButtonColor;

  /// Optional color for action button text in pickers (e.g. Save button text)
  final Color? saveButtonTextColor;

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

  /// Show OTP countdown timer (default: false)
  final bool isOtpCountdown;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------
  const FormFields({
    super.key,
    required this.onChanged,
    this.label,
    this.currentValue,
    // Validation
    this.validator,
    this.isRequired = false,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.minLengthPassword = 6,
    this.customPasswordValidator,
    this.minLengthPasswordErrorText,
    // Field Configuration
    this.formType,
    this.labelPosition = LabelPosition.none,
    this.multiLine = 0,
    this.fieldSize = AppSize.medium,
    this.customFieldHeight,
    this.verificationLength = 6,
    this.verificationAsOtp = true,
    this.verificationHidden = false,
    this.otpBoxWidth = 46,
    this.otpBoxSpacing = 10,
    this.otpTextStyle,
    this.otpInputFormatters,
    this.otpCountdownDuration = const Duration(seconds: 60),
    this.onOtpCountdownComplete,
    this.onOtpCountdownReload,
    this.otpCountdownTextBuilder,
    this.isOtpCountdown = false,
    // Localization
    this.locale,
    // Appearance & Styling
    this.radius = 10,
    this.borderType = BorderType.outlineInputBorder,
    this.labelTextStyle,
    this.inputDecoration,
    this.saveButtonColor,
    this.saveButtonTextColor,
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
    this.otpBorderType = OtpBorderType.box,
    this.verificationOtpAlphanumeric = false,
    this.externalErrorText,
    this.readOnly = false,
    this.onRemove,
  })  : assert(verificationLength > 0),
        assert(otpBoxWidth > 0),
        assert(otpBoxSpacing >= 0);

  @override
  State<FormFields<T>> createState() => _FormFieldsState<T>();
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({
    this.overlayColor,
    this.borderColor,
    this.borderWidth = 3.0,
    this.borderRadius = 16.0,
  });

  final Color? overlayColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.8;
        final height = constraints.maxHeight * 0.4;
        final theme = Theme.of(context);
        final resolvedOverlay =
            overlayColor ?? theme.colorScheme.surface.withValues(alpha: 0.5);
        final resolvedBorder = borderColor ?? theme.colorScheme.onSurface;
        return Stack(
          children: [
            Container(
              color: resolvedOverlay,
            ),
            Center(
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: resolvedBorder,
                    width: borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FormFieldsState<T> extends State<FormFields<T>> {
  static const double _kExtraFieldBottom = 20.0;
  // Merge caller-provided InputDecoration with ThemeData.inputDecorationTheme
  InputDecoration _effectiveInputDecoration(InputDecoration? base) {
    final theme = Theme.of(context).inputDecorationTheme;
    return (base ?? const InputDecoration()).applyDefaults(theme);
  }

  // Barcode scanner dialog for scanBarcode type
  Future<void> _showBarcodeScannerDialog({
    required ValueChanged<String> onScanned,
    String? cancelButtonLabel,
    Color? overlayColor,
    Color? overlayBorderColor,
    double overlayBorderWidth = 3.0,
    double overlayBorderRadius = 16.0,
  }) async {
    // Use an explicit controller configured for maximum detection speed.
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final resolvedOverlay =
            overlayColor ?? theme.colorScheme.surface.withValues(alpha: 0.54);
        final resolvedBorder =
            overlayBorderColor ?? theme.colorScheme.onSurface;
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Stack(
            children: [
              PermissionGate(
                child: MobileScanner(
                  controller: controller,
                  // Run in unrestricted detection mode for fastest scanning.
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null) {
                        Navigator.of(context).pop(code);
                      }
                    }
                  },
                ),
              ),
              _ScannerOverlay(
                overlayColor: resolvedOverlay,
                borderColor: resolvedBorder,
                borderWidth: overlayBorderWidth,
                borderRadius: overlayBorderRadius,
              ),
              Positioned(
                top: 48,
                right: 24,
                child: IconButton(
                  icon: Icon(Icons.close,
                      color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: cancelButtonLabel ?? context.formTr('cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );

    // Ensure controller is disposed after the dialog closes.
    try {
      controller.dispose();
    } catch (_) {}
    if (result != null) {
      onScanned(result);
    }
  }

  // Barcode scan field builder
  Widget _buildBarcodeScanField() {
    final String? value = widget.currentValue as String?;
    final errorText = widget.externalErrorText;
    final label = widget.label.toTitleCases;
    final scanIcon = const Icon(Icons.qr_code_scanner);
    // final scanButtonLabel = 'Scan';
    final cancelButtonLabel = context.formTr('cancel');
    final overlayColor =
        resolveTextColor(context, muted: true).withValues(alpha: 0.5);
    final overlayBorderColor = Theme.of(context).colorScheme.onSurface;
    final overlayBorderWidth = 3.0;
    final overlayBorderRadius = 16.0;

    void handleScan(String? code) {
      if (code != null) {
        widget.onChanged(code as T);
      }
    }

    // Ensure the shared controller reflects the current value without
    // creating a new controller each build (which can cause lifecycle
    // and disposal issues).
    final current = value ?? '';
    if (model.controller.text != current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        model.setControllerSilent(current);
      });
    }

    return TextFormField(
      controller: model.controller,
      readOnly: widget.readOnly,
      decoration: _effectiveInputDecoration(widget.inputDecoration).copyWith(
        labelText:
            widget.labelPosition == LabelPosition.inBorder ? label : null,
        errorText: errorText,
        suffixIcon: IconButton(
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          iconSize: 20,
          splashRadius: 20,
          icon: scanIcon,
          onPressed: widget.readOnly
              ? null
              : () {
                  _showBarcodeScannerDialog(
                    onScanned: handleScan,
                    cancelButtonLabel: cancelButtonLabel,
                    overlayColor: overlayColor,
                    overlayBorderColor: overlayBorderColor,
                    overlayBorderWidth: overlayBorderWidth,
                    overlayBorderRadius: overlayBorderRadius,
                  );
                },
        ),
      ),
      onChanged: (text) {
        widget.onChanged(text as T);
      },
    );
  }

  // OTP Countdown State
  Timer? _otpCountdownTimer;
  int _otpCountdownRemaining = 0;
  bool _otpCountdownFinished = false;

  void _startOtpCountdown() {
    _otpCountdownTimer?.cancel();
    setState(() {
      _otpCountdownRemaining = widget.otpCountdownDuration.inSeconds;
      _otpCountdownFinished = false;
    });
    _otpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_otpCountdownRemaining > 0) {
          _otpCountdownRemaining--;
        }
        _otpCountdownFinished = _otpCountdownRemaining == 0;
      });
      if (_otpCountdownRemaining == 0) {
        timer.cancel();
        if (widget.onOtpCountdownComplete != null) {
          widget.onOtpCountdownComplete!();
        }
      }
    });
  }

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
      _initializePhoneCountryCode(
        widget.currentValue?.toString(),
      );
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

        if (_isVerificationType() && widget.verificationAsOtp) {
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
    model.controller.removeListener(_onControllerTextChanged);
    model.dispose();
    debounce.cancel();
    _internalFocusNode?.dispose();
    _effectiveFieldExtraBottom.dispose();
    super.dispose();
  }

  void _onControllerTextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final error =
          _computeMainFieldValidation(model.controller.text, model, context);
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
      if (_isVerificationType() && widget.verificationAsOtp) {
        if (controllerText.length > widget.verificationLength) {
          controllerText =
              controllerText.substring(0, widget.verificationLength);
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

    final normalized = code.length > widget.verificationLength
        ? code.substring(0, widget.verificationLength)
        : code;

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
    final digits = rawValue;

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

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: TextStyle(fontSize: 14, color: resolveTextColor(context)),
          onChanged: widget.readOnly
              ? null
              : (value) {
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
      if (widget.verificationOtpAlphanumeric) {
        // Alfanumerik: tidak ada filter, hanya batasi panjang
        return [
          LengthLimitingTextInputFormatter(widget.verificationLength),
        ];
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
      builder: (dialogContext, child) {
        final parentTheme = Theme.of(dialogContext);
        // Use widget.saveButtonColor if provided, otherwise fall back to
        // the dialog's primary color. Allow overriding the text color via
        // `saveButtonTextColor` so callers can set e.g. red text.
        final resolvedSaveColor =
            widget.saveButtonColor ?? parentTheme.colorScheme.primary;

        final resolvedTextColor =
            widget.saveButtonTextColor ?? parentTheme.colorScheme.onPrimary;

        // Create an explicit ButtonStyle to ensure colors, shape and padding
        // match the datepicker's confirm button while preserving any
        // dialog-level customizations the app may provide.
        final backgroundColor = resolvedSaveColor;
        final foregroundColor = resolvedTextColor;

        // Start from the dialog's existing TextButton style so we inherit
        // padding/shape defined by the app theme, then override colors.
        final baseTextButtonStyle =
            parentTheme.textButtonTheme.style ?? const ButtonStyle();

        final buttonStyle = baseTextButtonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(backgroundColor),
          foregroundColor: WidgetStatePropertyAll(foregroundColor),
          textStyle: WidgetStatePropertyAll(TextStyle(color: foregroundColor)),
          overlayColor:
              WidgetStatePropertyAll(foregroundColor.withValues(alpha: 0.08)),
          padding: WidgetStatePropertyAll(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );

        final customTheme = parentTheme.copyWith(
          colorScheme: parentTheme.colorScheme.copyWith(
            primary: resolvedSaveColor,
            onPrimary: resolvedTextColor,
          ),
          textButtonTheme: TextButtonThemeData(style: buttonStyle),
        );

        return Theme(
            data: customTheme, child: child ?? const SizedBox.shrink());
      },
    );

    if (dateRange != null && mounted) {
      vm.setController = _formatDateRange(dateRange);
      widget.onChanged(dateRange as T);
    }
  }

  Future<void> _showPicker(BuildContext ctx, FormFieldsController vm) async {
    if (widget.readOnly) return;

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
    if (widget.readOnly) return;
    if (widget.onRemove != null) {
      widget.onRemove!();
    }
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
    // Update extra bottom spacing used to reserve room for validation
    // messages so the field height stays consistent after clearing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final error =
          _computeMainFieldValidation(vm.controller.text, vm, context);
      final hasText = vm.controller.text.trim().isNotEmpty;
      _effectiveFieldExtraBottom.value =
          (error != null || (hasText && _effectiveFocusNode.hasFocus))
              ? _kExtraFieldBottom
              : 0.0;
    });
  }

  void _handleVisibilityToggleTap(FormFieldsController vm) {
    if (widget.readOnly) return;

    vm.obscure = !vm.obscure;
  }

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
    T? effectiveValue = value;
    if (effectiveValue == null) {
      final ctrlText = vm.controller.text.trim();
      if (ctrlText.isNotEmpty) {
        effectiveValue = ctrlText as T?;
      }
    }

    // 2. Check required field constraint
    final isBlankString =
        effectiveValue is String && effectiveValue.trim().isEmpty;

    if (isRequired && (effectiveValue == null || isBlankString)) {
      return l.getWithLabel('required', label.toTitleCases);
    }

    // 3. Skip validation for optional empty fields
    if (!isRequired && (effectiveValue == null || isBlankString)) {
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
              effectiveValue);
        }
        break;
      case FormType.password:
        if (widget.customPasswordValidator != null) {
          return widget.customPasswordValidator!(effectiveValue);
        }
        if (effectiveValue is String &&
            effectiveValue.length < widget.minLengthPassword) {
          return widget.minLengthPasswordErrorText ??
              l.getWithValue(
                'passwordMinLength',
                widget.minLengthPassword,
              );
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
      String? value, FormFieldsController vm, BuildContext context) {
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
      final parsed = int.tryParse(widget.stripSeparators
          ? _stripSeparatorsForParse(normalized)
          : normalized);
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
      final parsed = double.tryParse(widget.stripSeparators
          ? _stripSeparatorsForParse(normalized)
          : normalized);
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

    final theme = Theme.of(context);
    final labelStyle = (widget.labelTextStyle ?? defaultLabelStyle)
        .copyWith(color: resolveTextColor(context));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: vm.label.toTitleCases, style: labelStyle),
            if (widget.isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Positions the text field with its label based on labelPosition setting
  Widget _buildFieldWithLabel(Widget textField, FormFieldsController vm) {
    // When label is hidden (`LabelPosition.none`) add a small top padding so
    // the field aligns vertically with other controls like `AppButton`
    // which uses a default `topPadding` of 12.
    if (widget.labelPosition == LabelPosition.none) {
      return textField;
    }

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

  /// Builds the input decoration for OTP boxes with proper error states
  InputDecoration _buildOtpInputDecoration({required bool hasError}) {
    final base = widget.inputDecoration;

    // Default style: no background
    final theme = Theme.of(context);
    final defaultDecoration = InputDecoration(
      filled: false,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.dividerColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
      ),
    );

    // For each OTP digit, we want to show underline if focused/has input/error, else border
    // But since InputDecoration is per box, we handle in _buildOtpDigitBox
    return _effectiveInputDecoration(base ?? defaultDecoration).copyWith(
      counterText: '',
      hintText: null,
      labelText: null,
      helperText: null,
      prefix: null,
      prefixIcon: null,
      suffix: null,
      suffixIcon: null,
      filled: base?.filled ?? false,
      fillColor: base?.fillColor ?? defaultDecoration.fillColor,
      contentPadding: base?.contentPadding ?? defaultDecoration.contentPadding,
    );
  }

  Color _effectiveBorderColor(BuildContext context,
      {bool isError = false, bool isFocused = false}) {
    final theme = Theme.of(context);
    final normal = theme.dividerColor;
    final focus = theme.colorScheme.primary;
    final error = theme.colorScheme.error;
    return isError ? error : (isFocused ? focus : normal);
  }

  InputBorder _buildBorderFromType(BuildContext context, BorderType type,
      {double radius = 8.0, bool isError = false, bool isFocused = false}) {
    final color =
        _effectiveBorderColor(context, isError: isError, isFocused: isFocused);
    switch (type) {
      case BorderType.none:
        return InputBorder.none;
      case BorderType.underlineInputBorder:
        return UnderlineInputBorder(borderSide: BorderSide(color: color));
      case BorderType.outlineInputBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: isFocused ? 1.8 : 1.5),
        );
    }
  }

  /// Builds a single OTP digit input box
  Widget _buildOtpDigitBox({
    required int index,
    required InputDecoration decoration,
    required FormFieldState<String> state,
    required FormFieldsController vm,
  }) {
    final isLastDigit = index == widget.verificationLength - 1;
    final isFocused = _verificationFocusNodes[index].hasFocus;
    final hasError = state.hasError;

    // Border style sesuai otpBorderType
    final color =
        _effectiveBorderColor(context, isError: hasError, isFocused: isFocused);

    // Draw the border with a parent Container instead of relying on the
    // TextField's InputBorder. This avoids stroke clipping caused by the
    // TextField internals or parent layout clipping on some devices.
    final double borderWidth = hasError ? 2 : (isFocused ? 2 : 1.2);
    final borderRadius = BorderRadius.circular(widget.radius);

    return SizedBox(
      width: widget.otpBoxWidth,
      height: widget.otpBoxWidth,
      child: Container(
        decoration: BoxDecoration(
          color: decoration.fillColor ?? Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(color: color, width: borderWidth),
        ),
        padding: EdgeInsets.zero,
        child: Center(
          child: TextField(
            controller: _verificationControllers[index],
            focusNode: _verificationFocusNodes[index],
            readOnly: widget.readOnly,
            keyboardType: widget.verificationOtpAlphanumeric
                ? TextInputType.visiblePassword
                : TextInputType.number,
            obscureText: widget.verificationHidden && vm.obscure,
            obscuringCharacter: '•',
            textInputAction:
                isLastDigit ? TextInputAction.done : TextInputAction.next,
            textAlign: TextAlign.center,
            style: widget.otpTextStyle ??
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            inputFormatters: widget.otpInputFormatters ??
                (widget.verificationOtpAlphanumeric
                    ? [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(
                            widget.verificationLength)
                      ]
                    : [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                            widget.verificationLength)
                      ]),
            onTap: () => _selectVerificationDigit(index),
            onChanged: (value) =>
                _handleVerificationDigitChanged(index, value, state),
            decoration: decoration.copyWith(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
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
        widget.label.toTitleCases,
        widget.isRequired,
        vm,
        context,
      ),
      builder: (state) {
        final hasError = state.hasError;
        final boxDecoration = _buildOtpInputDecoration(hasError: hasError);

        // Add small horizontal padding so outline borders of the first
        // and last OTP boxes are not clipped by parent layouts or pixel
        // rounding when rendered at the screen edge.
        final otpBoxes = Padding(
          // Increase horizontal + vertical padding so the outline stroke of the
          // first/last boxes isn't clipped by parent bounds or pixel
          // rounding on different devices.
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: widget.otpBoxSpacing,
              runSpacing: widget.otpBoxSpacing,
              children: [
                for (var i = 0; i < widget.verificationLength; i++)
                  _buildOtpDigitBox(
                    index: i,
                    decoration: boxDecoration,
                    state: state,
                    vm: vm,
                  ),
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
                      onPressed: widget.readOnly
                          ? null
                          : () => _handleVisibilityToggleTap(vm),
                    ),
                  ),
              ],
            ),
          ),
        );

        final countdown = widget.isOtpCountdown
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!_otpCountdownFinished)
                      Text(
                        (widget.otpCountdownTextBuilder ??
                                FormFields._defaultOtpCountdownTextBuilder)(
                            context, _otpCountdownRemaining),
                        style: TextStyle(
                          fontSize: 14,
                          color: resolveActiveColor(context, null),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: FormFields.defaultOtpResendText(
                          context: context,
                          onResend: _otpCountdownFinished
                              ? () {
                                  _startOtpCountdown();
                                  if (widget.onOtpCountdownReload != null) {
                                    widget.onOtpCountdownReload!();
                                  }
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink();

        final errorText = hasError && state.errorText != null
            ? Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: _effectiveBorderColor(context, isError: true),
                    fontSize: 12,
                  ),
                ),
              )
            : null;

        // Gabungkan semua bagian utama OTP
        final otpContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            otpBoxes,
            if (errorText != null) errorText,
            countdown,
          ],
        );

        // Gunakan _buildFieldWithLabel agar label mengikuti labelPosition
        return _buildFieldWithLabel(otpContent, vm);
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
                // Barcode scan field integration
                if (widget.formType == FormType.scanBarcode) {
                  return _buildBarcodeScanField();
                }

                if (_isVerificationType() && widget.verificationAsOtp) {
                  final verificationField =
                      _buildVerificationOtpField(vm, context);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: verificationField,
                  );
                }

                final phonePrefixIcon =
                    _isPhoneType() && widget.prefixIcon == null
                        ? _buildPhoneCountryCodeDropdown()
                        : null;

                final singleLine = (vm.formType == FormType.password ||
                    _isVerificationType() ||
                    widget.multiLine <= 1);

                final baseDecoration = widget.inputDecoration ??
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
                              onPressed: widget.readOnly
                                  ? null
                                  : () => _handleVisibilityToggleTap(vm),
                            )
                          : (_isDateTimeType() ||
                                  _isTimeOfDayType() ||
                                  _isDateTimeRangeType())
                              ? IconButton(
                                  constraints: const BoxConstraints.tightFor(
                                      width: 36, height: 36),
                                  iconSize: 20,
                                  splashRadius: 20,
                                  icon: Icon(_getPickerIcon()),
                                  onPressed: widget.readOnly
                                      ? null
                                      : () async {
                                          if (!mounted) return;
                                          final ctx = context;
                                          await _showPicker(ctx, vm);
                                        },
                                )
                              : widget.suffixIcon ??
                                  IconButton(
                                    constraints: const BoxConstraints.tightFor(
                                        width: 36, height: 36),
                                    iconSize: 20,
                                    splashRadius: 20,
                                    icon: const Icon(Icons.close),
                                    onPressed: widget.readOnly
                                        ? null
                                        : () => _handleClearIconTap(vm),
                                  ),
                      prefix: widget.prefix,
                      prefixIcon: phonePrefixIcon ?? widget.prefixIcon,
                      hintText:
                          '${_getLocalizations(context).enterPrefix}${vm.label.toTitleCases}',
                      labelText: widget.labelPosition == LabelPosition.inBorder
                          ? '${_getLocalizations(context).enterPrefix}${vm.label.toTitleCases}${widget.isRequired ? ' *' : ''}'
                          : null,
                      focusedErrorBorder: _buildBorderFromType(
                          ctx, widget.borderType,
                          radius: widget.radius,
                          isError: true,
                          isFocused: true),
                      focusedBorder: _buildBorderFromType(
                          ctx, widget.borderType,
                          radius: widget.radius, isFocused: true),
                      enabledBorder: _buildBorderFromType(
                          ctx, widget.borderType,
                          radius: widget.radius),
                      border: _buildBorderFromType(ctx, widget.borderType,
                          radius: widget.radius),
                      disabledBorder: _buildBorderFromType(
                          ctx, widget.borderType,
                          radius: widget.radius),
                    );

                final effectiveDecoration =
                    _effectiveInputDecoration(baseDecoration);

                final textField = TextFormField(
                  textAlignVertical: singleLine
                      ? TextAlignVertical.center
                      : TextAlignVertical.top,
                  textAlign: TextAlign.start,
                  readOnly: widget.readOnly,
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
                    final error =
                        _computeMainFieldValidation(value, vm, context);
                    final hasText =
                        (value != null && value.trim().isNotEmpty) ||
                            vm.controller.text.trim().isNotEmpty;
                    // Avoid updating ValueNotifier synchronously during build
                    // which can call markNeedsBuild. Defer update to next frame.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _effectiveFieldExtraBottom.value = (error != null ||
                              (hasText && _effectiveFocusNode.hasFocus))
                          ? _kExtraFieldBottom
                          : 0.0;
                    });
                    return error;
                  },
                  controller: vm.controller,
                  onTap: () async {
                    if (widget.readOnly) return;
                    if (!mounted) return;
                    final ctx = context;
                    await _showPicker(ctx, vm);
                  },
                  autofocus: false,
                  decoration: effectiveDecoration,
                );

                double fieldHeight;
                switch (widget.fieldSize) {
                  case AppSize.small:
                    fieldHeight = kFieldHeightSmall;
                    break;
                  case AppSize.medium:
                    fieldHeight = kFieldHeightMedium;
                    break;
                  case AppSize.large:
                    fieldHeight = kFieldHeightLarge;
                    break;
                  case AppSize.custom:
                    fieldHeight =
                        widget.customFieldHeight ?? kFieldHeightDefault;
                    break;
                }

                return ValueListenableBuilder<double>(
                  valueListenable: _effectiveFieldExtraBottom,
                  builder: (ctx2, extra, _) {
                    final effectiveExtra =
                        singleLine ? _kExtraFieldBottom : extra;
                    final effectiveField = singleLine
                        ? SizedBox(
                            height: fieldHeight + effectiveExtra,
                            child: textField)
                        : textField;
                    return Container(
                      margin: widget.labelPosition == LabelPosition.none
                          ? EdgeInsets.zero
                          : const EdgeInsets.only(bottom: 20),
                      child: _buildFieldWithLabel(effectiveField, vm),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
