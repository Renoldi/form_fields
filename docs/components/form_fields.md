# FormFields

Main flexible form widget that supports multiple input types (`FormType`) with validation, formatting, localization, customizable decoration, and advanced OTP/verification field support.

## Basic Usage

```dart
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  currentValue: value,
  onChanged: (v) => value = v,
)
```

## OTP & Verification Field Example

```dart
FormFields<String>(
  label: 'OTP Code',
  formType: FormType.verification,
  verificationAsOtp: true,
  verificationLength: 6,
  isOtpCountdown: true,
  otpCountdownDuration: Duration(seconds: 60),
  onOtpCountdownReload: () => print('Resend OTP!'),
  otpBorderType: OtpBorderType.box, // or OtpBorderType.underline
  onChanged: (val) => print(val),
)
```

## Common Options

- `formType`: Selects input behavior (email, phone, password, date, verification/OTP, etc).
- `isRequired`: Enables required-field validation.
- `validator`: Adds custom validation.
- `labelPosition`: Controls label placement (top, bottom, left, right, inline, hidden).
- `borderType` and `radius`: Border appearance for standard fields.
- `inputDecoration`: Additional InputDecoration control for all fields (including OTP boxes).
- `verificationAsOtp`: Show as OTP digit boxes (true) or single field (false).
- `verificationLength`: Number of OTP digits.
- `isOtpCountdown`: Enable countdown timer for OTP resend.
- `otpCountdownDuration`: Duration for countdown.
- `onOtpCountdownReload`: Callback for resend button.
- `otpBorderType`: `OtpBorderType.box` or `OtpBorderType.underline` for OTP digit boxes.
- `otpBoxWidth`, `otpBoxSpacing`, `otpTextStyle`: OTP box customization.
- `verificationHidden`: Hide/obscure OTP input.

## Localization

All validation and UI text is fully localized (English, Indonesian, and easily extendable). See [LOCALIZATION.md](../../LOCALIZATION.md).

## Architecture Links

- [Architecture Diagram](../../ARCHITECTURE.md#architecture-diagram)
- [FormFields Validation Flow](../../ARCHITECTURE.md#formfields-validation-flow)

For full property details, see [API.md](../../API.md).
