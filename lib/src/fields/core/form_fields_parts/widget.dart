part of '../form_fields.dart';

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
    BuildContext context,
    int seconds,
  ) {
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
    final resendPrefix = localizations.get(
      'otpResendPrefix',
    ); //?? 'Didn\'t receive activation code? ';
    final resendLink = localizations.get('otpResendLink'); //?? 'Resend';
    final isEnabled = onResend != null;
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Text.rich(
          TextSpan(
            text: resendPrefix,
            style:
                style ??
                TextStyle(color: resolveTextColor(context), fontSize: 14),
            children: [
              TextSpan(
                text: resendLink,
                style:
                    linkStyle ??
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
  }) : assert(verificationLength > 0),
       assert(otpBoxWidth > 0),
       assert(otpBoxSpacing >= 0);

  @override
  State<FormFields<T>> createState() => _FormFieldsState<T>();
}
