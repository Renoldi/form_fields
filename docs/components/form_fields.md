# FormFields

Main flexible form widget that supports multiple input types (`FormType`) with validation, formatting, localization, customizable decoration, and advanced OTP/verification field support.

## Basic Usage

```dart
FormFields<String>(
  label: 'Username',
  currentValue: value,
  onChanged: (v) => value = v,
)
```

Text mode is the default. You can omit `formType` for basic text fields.

## FormType Examples

### string — Plain text

```dart
FormFields<String>(
  label: 'Nama',
  isRequired: true,
  currentValue: viewModel.name,
  onChanged: viewModel.setName,
)
```

### email

```dart
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  isRequired: true,
  currentValue: viewModel.email,
  onChanged: viewModel.setEmail,
)
```

### phone

```dart
FormFields<String>(
  label: 'No. HP',
  formType: FormType.phone,
  isRequired: true,
  currentValue: viewModel.phone,
  onChanged: viewModel.setPhone,
)
```

### password

```dart
FormFields<String>(
  label: 'Password',
  formType: FormType.password,
  isRequired: true,
  currentValue: viewModel.password,
  onChanged: viewModel.setPassword,
)
```

### date

```dart
FormFields<DateTime>(
  label: 'Tanggal Lahir',
  formType: FormType.date,
  currentValue: viewModel.birthDate,
  onChanged: viewModel.setBirthDate,
)
```

### time

```dart
FormFields<DateTime>(
  label: 'Jam Mulai',
  formType: FormType.time,
  currentValue: viewModel.startTime,
  onChanged: viewModel.setStartTime,
)
```

`FormType.time` returns `DateTime`. Use `FormType.timeOfDay` if you want `TimeOfDay`.

### dateTime

```dart
FormFields<DateTime>(
  label: 'Jadwal',
  formType: FormType.dateTime,
  currentValue: viewModel.schedule,
  onChanged: viewModel.setSchedule,
)
```

### dateTimeRange

```dart
FormFields<DateTimeRange>(
  label: 'Periode',
  formType: FormType.dateTimeRange,
  useDatePickerForRange: true,
  currentValue: viewModel.period,
  onChanged: viewModel.setPeriod,
)
```

### timeOfDay

```dart
FormFields<TimeOfDay>(
  label: 'Waktu',
  formType: FormType.timeOfDay,
  currentValue: viewModel.time,
  onChanged: viewModel.setTime,
)
```

### multiline (string + multiLine > 1)

```dart
FormFields<String>(
  label: 'Catatan',
  multiLine: 4,
  currentValue: viewModel.notes,
  onChanged: viewModel.setNotes,
)
```

### int / double (numeric via generic `T`)

Use numeric generic types directly. Numeric parsing/formatting is inferred from `T`.

```dart
// int
FormFields<int>(
  label: 'Umur',
  currentValue: viewModel.age,
  onChanged: viewModel.setAge,
)

// double
FormFields<double>(
  label: 'Harga',
  stripSeparators: true,
  currentValue: viewModel.price,
  onChanged: viewModel.setPrice,
)
```

Avoid `T = num` because numeric behavior is implemented specifically for `int` and `double`.

### scanBarcode

```dart
FormFields<String>(
  label: 'Scan Barcode',
  formType: FormType.scanBarcode,
  labelPosition: LabelPosition.inBorder,
  currentValue: viewModel.barcode,
  isRequired: true,
  onChanged: viewModel.setBarcode,
)
```

### verification / OTP

```dart
FormFields<String>(
  label: 'Kode OTP',
  formType: FormType.verification,
  verificationAsOtp: true,
  verificationLength: 6,
  isOtpCountdown: true,
  otpCountdownDuration: const Duration(seconds: 60),
  onOtpCountdownReload: () {
    // Kirim ulang OTP
  },
  otpBorderType: OtpBorderType.box, // atau OtpBorderType.underline
  currentValue: viewModel.otp,
  onChanged: viewModel.setOtp,
)
```

## Common Options

- `formType`: Selects input behavior (see list above).
- `formType` default: text mode (omit `formType`).
- Numeric fields: use `T = int/int?/double/double?`.
- `isRequired`: Enables required-field validation.
- `validator`: Adds custom validation.
- `labelPosition`: Controls label placement (`top`, `bottom`, `left`, `right`, `inBorder`, `none`).
- `borderType` and `radius`: Border appearance.
- `multiLine`: Lines for textarea mode (text mode).
- `inputDecoration`: Additional `InputDecoration` control.
- `externalErrorText`: Show backend validation error directly on the field.

## OTP-Specific Options

- `verificationAsOtp`: Show as OTP digit boxes (`true`) or single field (`false`).
- `verificationLength`: Number of OTP digits.
- `verificationHidden`: Hide/obscure OTP input.
- `isOtpCountdown`: Enable countdown timer for resend.
- `otpCountdownDuration`: Duration for countdown.
- `onOtpCountdownReload`: Callback for resend button.
- `otpBorderType`: `OtpBorderType.box` or `OtpBorderType.underline`.
- `otpBoxWidth`, `otpBoxSpacing`, `otpTextStyle`: OTP box customization.

## Localization

All validation and UI text is fully localized (English, Indonesian, and easily extendable). See [LOCALIZATION.md](../../LOCALIZATION.md).

## Architecture Links

- [Architecture Diagram](../../ARCHITECTURE.md#architecture-diagram)
- [FormFields Validation Flow](../../ARCHITECTURE.md#formfields-validation-flow)

For full property details, see [API.md](../../API.md).
