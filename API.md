# API Reference — FormFields Package

> **Single import:** `import 'package:form_fields/form_fields.dart';`

---

## Table of Contents

1. [Package Overview](#1-package-overview)
2. [FormFields\<T\>](#2-formfieldst) — Core text/date/time/OTP/dropdown input widget
3. [FormFieldsAutocomplete\<T\>](#3-formfieldsautocompletelt) — API-driven autocomplete field
4. [FormFieldsSelect\<T\>](#4-formfieldsselectltt) — Modal single-select field
5. [FormFieldsDropdown\<T\>](#5-formfieldsdropdownltt) — Inline dropdown field
6. [FormFieldsDropdownMulti\<T\>](#6-formfieldsdropdownmultiltt) — Multi-select dropdown field
7. [FormFieldsRadioButton\<T\>](#7-formfieldsradiobuttonltt) — Radio button group
8. [FormFieldsCheckbox\<T\>](#8-formfieldscheckboxltt) — Checkbox group
9. [FormFieldsMyImage](#9-formfieldsmyimage) — Image picker & direct uploader
10. [FormFieldsSignaturePad](#10-formfieldssignaturepad) — Signature pad with optional live camera
11. [FormFieldsLiveCameraCapture](#11-formfieldslivecameracapture) — Standalone live front-camera widget
12. [AppButton](#12-appbutton) — Unified button widget
13. [AppButtonGroup](#13-appbuttongroup) — Button layout group
14. [AppSegmentedButton\<T\>](#14-appsegmentedbuttonltt) — Material 3 segmented button wrapper
15. [AppSplitButton\<T\>](#15-appsplitbuttonltt) — Split button with dropdown actions
16. [AppFabMenu](#16-appfabmenu) — Expandable FAB menu
17. [AppDialogService](#17-appdialogservice) — Context-scoped dialog helper
18. [AppGlobalDialogService](#18-appglobaldialogservice) — Navigator-key-scoped dialog helper
19. [AppLoadingIndicator](#19-apploadingindicator) — Animated loading widget
20. [AppProgressIndicator](#20-appprogressindicator) — Determinate / indeterminate progress widget
21. [showAppModalBottomSheet](#21-showappmodalbottomsheet) — Keyboard-aware modal bottom sheet
22. [ResponsiveMenuGrid](#22-responsivemenugrid) — Auto-column responsive grid
23. [FormFieldsMyImageController](#23-formfieldsmyimagecontroller) — External image controller
24. [FormFieldsMyImageProvider](#24-formfieldsmyimageprovider) — Image state provider (ChangeNotifier)
25. [MyimageResult](#25-myimageresult) — Image data model
26. [DioUtil](#26-dioutil) — File upload & download utility
27. [FormFieldValidators](#27-formfieldvalidators) — Static validator methods
28. [Enums Reference](#28-enums-reference)
29. [String Extensions](#29-string-extensions)
30. [DateTime & TimeOfDay Extensions](#30-datetime--timeofday-extensions)

---

## 1. Package Overview

FormFields is a comprehensive Flutter form-field and UI component package. It covers all standard field types, selection widgets, media capture, dialogs, buttons, and utility helpers — all from a single import.

```dart
import 'package:form_fields/form_fields.dart';
```

**Export groups:**

| Group                | Classes                                                                                                            |
| -------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Core field           | `FormFields<T>`                                                                                                    |
| Autocomplete         | `FormFieldsAutocomplete<T>`                                                                                        |
| Selection            | `FormFieldsSelect`, `FormFieldsDropdown`, `FormFieldsDropdownMulti`, `FormFieldsRadioButton`, `FormFieldsCheckbox` |
| Media                | `FormFieldsMyImage`, `FormFieldsSignaturePad`, `FormFieldsLiveCameraCapture`                                       |
| Buttons              | `AppButton`, `AppButtonGroup`, `AppSegmentedButton`, `AppSplitButton`, `AppFabMenu`                                |
| Feedback             | `AppDialogService`, `AppGlobalDialogService`, `AppLoadingIndicator`, `AppProgressIndicator`                        |
| Utilities            | `showAppModalBottomSheet`, `ResponsiveMenuGrid`, `DioUtil`, `FormFieldValidators`                                  |
| Models & Controllers | `MyimageResult`, `FormFieldsMyImageController`, `FormFieldsMyImageProvider`                                        |
| Enums                | `FormType`, `LabelPosition`, `BorderType`, `AppButtonType`, `AppButtonSize`, `AppDialogType`, etc.                 |

---

## 2. FormFields\<T\>

The core input widget. Supports text, phone, email, password, OTP/verification, numeric, date, time, datetime, date-range, and selection types via the `formType` parameter.

### Constructor

```dart
FormFields<T>({
  required ValueChanged<T> onChanged,
  required String label,
  T? currentValue,
  FormType formType = FormType.string,
  LabelPosition labelPosition = LabelPosition.none,
  bool isRequired = false,
  FormFieldValidator<String>? validator,
  AutovalidateMode? autovalidateMode,
  FocusNode? focusNode,
  FocusNode? nextFocusNode,
  Widget? prefix,
  Widget? prefixIcon,
  Widget? suffix,
  Widget? suffixIcon,
  InputDecoration? inputDecoration,
  double radius = 10,
  BorderType borderType = BorderType.outlineInputBorder,
  int multiLine = 0,
  // OTP/Verification
  int verificationLength = 6,
  bool verificationAsOtp = false,
  bool verificationHidden = false,
  bool isOtpCountdown = false,
  Duration otpCountdownDuration,
  VoidCallback? onOtpCountdownReload,
  OtpBorderType otpBorderType = OtpBorderType.box,
  double? otpBoxWidth,
  double? otpBoxSpacing,
  TextStyle? otpTextStyle,
  // Date / time
  String? customFormat,
  bool stripSeparators = true,
  DateTime? firstDate,
  DateTime? lastDate,
  // Locale
  String? locale,
})
```

### Properties

#### Required

| Property    | Type              | Description                 |
| ----------- | ----------------- | --------------------------- |
| `onChanged` | `ValueChanged<T>` | Fires on every value change |
| `label`     | `String`          | Label text                  |

#### Common Optional

| Property                | Type                          | Default              | Description                                         |
| ----------------------- | ----------------------------- | -------------------- | --------------------------------------------------- |
| `formType`              | `FormType`                    | `string`             | Field behaviour variant                             |
| `currentValue`          | `T?`                          | `null`               | Initial / controlled value                          |
| `labelPosition`         | `LabelPosition`               | `none`               | Label placement                                     |
| `isRequired`            | `bool`                        | `false`              | Enables built-in required validation                |
| `validator`             | `FormFieldValidator<String>?` | `null`               | Custom validator                                    |
| `autovalidateMode`      | `AutovalidateMode?`           | `null`               | When to auto-validate                               |
| `focusNode`             | `FocusNode?`                  | `null`               | Focus control                                       |
| `nextFocusNode`         | `FocusNode?`                  | `null`               | Auto-advance focus                                  |
| `prefix` / `prefixIcon` | `Widget?`                     | `null`               | Leading decoration                                  |
| `suffix` / `suffixIcon` | `Widget?`                     | `null`               | Trailing decoration                                 |
| `inputDecoration`       | `InputDecoration?`            | `null`               | Full decoration override                            |
| `radius`                | `double`                      | `10`                 | Border corner radius                                |
| `borderType`            | `BorderType`                  | `outlineInputBorder` | Border style                                        |
| `multiLine`             | `int`                         | `0`                  | `> 0` = textarea with that many lines               |
| `locale`                | `String?`                     | `null`               | `'id'` / `'en'` — affects validation text & pickers |

#### OTP / Verification

| Property               | Type            | Default                 | Description                          |
| ---------------------- | --------------- | ----------------------- | ------------------------------------ |
| `verificationAsOtp`    | `bool`          | `false`                 | Show individual digit boxes          |
| `verificationLength`   | `int`           | `6`                     | Number of digit boxes                |
| `verificationHidden`   | `bool`          | `false`                 | Obscure input with visibility toggle |
| `isOtpCountdown`       | `bool`          | `false`                 | Show countdown timer                 |
| `otpCountdownDuration` | `Duration`      | `Duration(seconds: 60)` | Countdown length                     |
| `onOtpCountdownReload` | `VoidCallback?` | `null`                  | Called when resend is tapped         |
| `otpBorderType`        | `OtpBorderType` | `box`                   | `box` or `underline`                 |
| `otpBoxWidth`          | `double?`       | `null`                  | Width of each digit box              |
| `otpBoxSpacing`        | `double?`       | `null`                  | Gap between boxes                    |
| `otpTextStyle`         | `TextStyle?`    | `null`                  | Text style inside each box           |

#### Date / Time

| Property          | Type        | Default | Description                                       |
| ----------------- | ----------- | ------- | ------------------------------------------------- |
| `customFormat`    | `String?`   | `null`  | Custom `DateFormat` pattern                       |
| `stripSeparators` | `bool`      | `true`  | Strip thousand-separator for numeric types        |
| `firstDate`       | `DateTime?` | `null`  | Earliest selectable date (default: 100 years ago) |
| `lastDate`        | `DateTime?` | `null`  | Latest selectable date (default: today)           |

### Supported Generic Types

| Type            | Compatible `formType` values                           |
| --------------- | ------------------------------------------------------ |
| `String`        | `string`, `phone`, `email`, `password`, `verification` |
| `int`           | `string` (numeric)                                     |
| `double`        | `string` (decimal)                                     |
| `DateTime`      | `date`, `time`, `dateTime`                             |
| `TimeOfDay`     | `time`, `timeOfDay`                                    |
| `DateTimeRange` | `dateTimeRange`                                        |

### Usage Examples

```dart
// Basic text
FormFields<String>(
  label: 'Username',
  formType: FormType.string,
  labelPosition: LabelPosition.top,
  isRequired: true,
  onChanged: (value) => setState(() => username = value ?? ''),
)

// OTP with countdown
FormFields<String>(
  label: 'Verification Code',
  formType: FormType.verification,
  verificationAsOtp: true,
  verificationLength: 6,
  isOtpCountdown: true,
  otpCountdownDuration: const Duration(seconds: 120),
  onOtpCountdownReload: () => resendCode(),
  onChanged: (value) => setState(() => otp = value ?? ''),
)

// Date range
FormFields<DateTimeRange>(
  label: 'Stay Period',
  formType: FormType.dateTimeRange,
  labelPosition: LabelPosition.top,
  onChanged: (range) => setState(() => stayPeriod = range),
)

// Textarea
FormFields<String>(
  label: 'Notes',
  multiLine: 4,
  labelPosition: LabelPosition.top,
  onChanged: (value) => setState(() => notes = value ?? ''),
)
```

---

## 3. FormFieldsAutocomplete\<T\>

API-driven autocomplete field. Queries a remote endpoint as the user types and renders results in a Material autocomplete overlay.

### Constructor

```dart
FormFieldsAutocomplete<T>({
  required String fieldLabel,
  required String apiUrl,
  String? apiToken,
  required void Function(T?) onItemSelected,
  InputDecoration? inputDecoration,
  String searchKey = 'q',
  String tokenHeaderName = 'Authorization',
  List<T> Function(dynamic data)? parseResults,
  LabelPosition labelPlacement = LabelPosition.none,
  BorderType borderStyle = BorderType.outlineInputBorder,
  Widget? trailingIcon,
  bool hideTrailingIcon = false,
  String Function(T)? itemSelectedBuilder,
  Widget Function(T item, bool selected)? itemBuilder,
})
```

### Properties

| Property              | Type                         | Default              | Description                                                                     |
| --------------------- | ---------------------------- | -------------------- | ------------------------------------------------------------------------------- |
| `fieldLabel`          | `String`                     | —                    | Label text (required)                                                           |
| `apiUrl`              | `String`                     | —                    | Remote endpoint URL (required)                                                  |
| `apiToken`            | `String?`                    | `null`               | Bearer token appended to `Authorization` header                                 |
| `onItemSelected`      | `void Function(T?)`          | —                    | Called when user selects an item (required)                                     |
| `searchKey`           | `String`                     | `'q'`                | Query parameter name sent to the API                                            |
| `tokenHeaderName`     | `String`                     | `'Authorization'`    | Header name for the token                                                       |
| `parseResults`        | `List<T> Function(dynamic)?` | `null`               | Custom JSON-to-list parser; falls back to `data` as `List` or `data['results']` |
| `inputDecoration`     | `InputDecoration?`           | `null`               | Full decoration override                                                        |
| `labelPlacement`      | `LabelPosition`              | `none`               | Label position                                                                  |
| `borderStyle`         | `BorderType`                 | `outlineInputBorder` | Border style                                                                    |
| `itemSelectedBuilder` | `String Function(T)?`        | `null`               | Convert item to display string in the text field                                |
| `itemBuilder`         | `Widget Function(T, bool)?`  | `null`               | Custom widget for each dropdown option                                          |
| `trailingIcon`        | `Widget?`                    | `null`               | Custom trailing icon                                                            |
| `hideTrailingIcon`    | `bool`                       | `false`              | Hide the trailing icon                                                          |

### Usage Example

```dart
FormFieldsAutocomplete<Map<String, dynamic>>(
  fieldLabel: 'City',
  apiUrl: 'https://api.example.com/cities',
  apiToken: authToken,
  searchKey: 'name',
  parseResults: (data) => (data['data'] as List).cast<Map<String, dynamic>>(),
  itemSelectedBuilder: (item) => item['name'] as String,
  itemBuilder: (item, selected) => ListTile(
    title: Text(item['name'] as String),
    selected: selected,
  ),
  onItemSelected: (item) => setState(() => selectedCity = item),
)
```

---

## 4. FormFieldsSelect\<T\>

A tappable field that opens a full-screen or modal selection list. Useful for long lists.

### Key Parameters

| Property           | Type                  | Description                |
| ------------------ | --------------------- | -------------------------- |
| `label`            | `String`              | Field label                |
| `items`            | `List<T>`             | List of selectable options |
| `onChanged`        | `ValueChanged<T?>`    | Selection callback         |
| `initialValue`     | `T?`                  | Pre-selected value         |
| `itemLabelBuilder` | `String Function(T)?` | Display text per item      |
| `isRequired`       | `bool`                | Required validation        |
| `labelPosition`    | `LabelPosition`       | Label placement            |

---

## 5. FormFieldsDropdown\<T\>

Inline Material dropdown (single select).

### Key Parameters

| Property           | Type                  | Description           |
| ------------------ | --------------------- | --------------------- |
| `label`            | `String`              | Field label           |
| `items`            | `List<T>`             | Dropdown items        |
| `onChanged`        | `ValueChanged<T?>`    | Selection callback    |
| `initialValue`     | `T?`                  | Pre-selected value    |
| `itemLabelBuilder` | `String Function(T)?` | Display text per item |
| `isRequired`       | `bool`                | Required validation   |
| `labelPosition`    | `LabelPosition`       | Label placement       |

---

## 6. FormFieldsDropdownMulti\<T\>

Inline dropdown for selecting multiple values simultaneously.

### Key Parameters

| Property           | Type                    | Description                          |
| ------------------ | ----------------------- | ------------------------------------ |
| `label`            | `String`                | Field label                          |
| `items`            | `List<T>`               | All available options                |
| `onChanged`        | `ValueChanged<List<T>>` | Called with updated selection list   |
| `initialValue`     | `List<T>?`              | Pre-selected values                  |
| `itemLabelBuilder` | `String Function(T)?`   | Display text per item                |
| `isRequired`       | `bool`                  | Validates at least one item selected |
| `labelPosition`    | `LabelPosition`         | Label placement                      |

---

## 7. FormFieldsRadioButton\<T\>

Radio button group for single selection. Supports flat lists, horizontal/vertical layout, sectioned grouped lists, custom item widgets, and rich visual styling.

### Constructor

```dart
FormFieldsRadioButton<T>({
  required String label,
  List<T>? items,
  Map<String, List<T>>? sections,
  required ValueChanged<T?> onChanged,
  T? initialValue,
  bool isRequired = false,
  Axis direction = Axis.vertical,
  double radius = 10,
  Color borderColor = const Color(0xFFC7C7C7),
  Color errorBorderColor = Colors.red,
  Color activeColor = Colors.blue,
  EdgeInsets itemPadding = const EdgeInsets.symmetric(vertical: 8),
  double sectionSpacing = 12,
  Color? itemBorderColor,
  double itemBorderWidth = 1.0,
  double itemBorderRadius = 8,
  double textRightPadding = 0,
  double itemTextMarginRight = 0,
  Color? selectedItemBackgroundColor,
  Color? selectedItemTextColor,
  Color? hoverBackgroundColor,
  bool itemShadow = false,
  LabelPosition labelPosition = LabelPosition.top,
  double containerPadding = 12,
  double containerGap = 8,
  double itemMarginTop = 4,
  double itemMarginBottom = 4,
  String Function(T)? itemLabelBuilder,
  Widget Function(T, bool selected)? itemBuilder,
  FormFieldValidator<T>? validator,
})
```

> **Either `items` or `sections` must be provided**, not both.
> When using `sections`, items within each section always render horizontally.

### Properties

#### Required

| Property    | Type               | Description                |
| ----------- | ------------------ | -------------------------- |
| `label`     | `String`           | Group label                |
| `onChanged` | `ValueChanged<T?>` | Called on selection change |

#### Layout & Appearance

| Property           | Type                    | Default             | Description                       |
| ------------------ | ----------------------- | ------------------- | --------------------------------- |
| `items`            | `List<T>?`              | `null`              | Flat list of options              |
| `sections`         | `Map<String, List<T>>?` | `null`              | Grouped options by section title  |
| `initialValue`     | `T?`                    | `null`              | Pre-selected value                |
| `isRequired`       | `bool`                  | `false`             | Required validation               |
| `direction`        | `Axis`                  | `vertical`          | Layout direction for flat `items` |
| `labelPosition`    | `LabelPosition`         | `top`               | Label placement                   |
| `activeColor`      | `Color`                 | `Colors.blue`       | Active radio indicator color      |
| `borderColor`      | `Color`                 | `Color(0xFFC7C7C7)` | Container border color            |
| `errorBorderColor` | `Color`                 | `Colors.red`        | Border color when invalid         |
| `radius`           | `double`                | `10`                | Container corner radius           |
| `sectionSpacing`   | `double`                | `12`                | Vertical gap between sections     |
| `containerPadding` | `double`                | `12`                | Inner padding of the container    |
| `containerGap`     | `double`                | `8`                 | Gap between label and container   |

#### Item Styling

| Property                      | Type         | Default                  | Description                               |
| ----------------------------- | ------------ | ------------------------ | ----------------------------------------- |
| `itemPadding`                 | `EdgeInsets` | `symmetric(vertical: 8)` | Padding inside each item                  |
| `itemMarginTop`               | `double`     | `4`                      | Top margin per item                       |
| `itemMarginBottom`            | `double`     | `4`                      | Bottom margin per item                    |
| `itemBorderColor`             | `Color?`     | `null`                   | Border color per item; `null` = no border |
| `itemBorderWidth`             | `double`     | `1.0`                    | Item border thickness                     |
| `itemBorderRadius`            | `double`     | `8`                      | Item corner radius                        |
| `textRightPadding`            | `double`     | `0`                      | Right padding of label text inside item   |
| `itemTextMarginRight`         | `double`     | `0`                      | Right margin after text                   |
| `selectedItemBackgroundColor` | `Color?`     | `null`                   | Background of selected item               |
| `selectedItemTextColor`       | `Color?`     | `null`                   | Text color of selected item               |
| `hoverBackgroundColor`        | `Color?`     | `null`                   | Background on hover/press                 |
| `itemShadow`                  | `bool`       | `false`                  | Drop shadow on selected item              |

#### Builders & Validation

| Property           | Type                        | Default | Description                  |
| ------------------ | --------------------------- | ------- | ---------------------------- |
| `itemLabelBuilder` | `String Function(T)?`       | `null`  | Custom display text per item |
| `itemBuilder`      | `Widget Function(T, bool)?` | `null`  | Fully custom item widget     |
| `validator`        | `FormFieldValidator<T>?`    | `null`  | Custom validator             |

### Usage Examples

```dart
// Vertical list
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: const ['Male', 'Female', 'Other'],
  isRequired: true,
  onChanged: (value) => setState(() => gender = value ?? ''),
)

// Horizontal layout
FormFieldsRadioButton<String>(
  label: 'Priority',
  items: const ['Low', 'Medium', 'High'],
  direction: Axis.horizontal,
  activeColor: Colors.orange,
  onChanged: (value) => setState(() => priority = value ?? ''),
)

// Sectioned
FormFieldsRadioButton<String>(
  label: 'Plan',
  sections: {
    'Cloud': ['Starter', 'Pro', 'Enterprise'],
    'Support': ['Basic', 'Premium', '24/7'],
  },
  activeColor: Colors.green,
  sectionSpacing: 16,
  onChanged: (value) => setState(() => plan = value ?? ''),
)

// With selection highlight
FormFieldsRadioButton<String>(
  label: 'Delivery',
  items: const ['Pickup', 'Standard', 'Express'],
  selectedItemBackgroundColor: Colors.orange.shade50,
  selectedItemTextColor: Colors.orange.shade900,
  itemBorderColor: Colors.orange.shade300,
  itemShadow: true,
  activeColor: Colors.orange,
  onChanged: (value) => setState(() => delivery = value ?? ''),
)
```

---

## 8. FormFieldsCheckbox\<T\>

Checkbox group for multi-selection. Shares most visual options with `FormFieldsRadioButton`.

### Constructor

```dart
FormFieldsCheckbox<T>({
  required String label,
  required List<T> items,
  required ValueChanged<List<T>> onChanged,
  List<T>? initialValue,
  bool isRequired = false,
  Axis direction = Axis.vertical,
  double radius = 10,
  Color borderColor = const Color(0xFFC7C7C7),
  Color errorBorderColor = Colors.red,
  Color activeColor = Colors.blue,
  EdgeInsets itemPadding = const EdgeInsets.symmetric(vertical: 6),
  double itemMarginTop = 4,
  double itemMarginBottom = 4,
  double itemMarginHorizontal = 0,
  Color? itemBorderColor,
  double itemBorderWidth = 1.0,
  double itemBorderRadius = 8,
  String Function(T)? itemLabelBuilder,
  Widget Function(T, bool selected)? itemBuilder,
  FormFieldValidator<List<T>>? validator,
})
```

### Properties

| Property               | Type                           | Default       | Description                                   |
| ---------------------- | ------------------------------ | ------------- | --------------------------------------------- |
| `label`                | `String`                       | —             | Group label (required)                        |
| `items`                | `List<T>`                      | —             | All available options (required)              |
| `onChanged`            | `ValueChanged<List<T>>`        | —             | Called with updated selection list (required) |
| `initialValue`         | `List<T>?`                     | `null`        | Pre-selected values                           |
| `isRequired`           | `bool`                         | `false`       | Validates at least one item checked           |
| `direction`            | `Axis`                         | `vertical`    | Layout direction                              |
| `activeColor`          | `Color`                        | `Colors.blue` | Checkbox active color                         |
| `itemMarginHorizontal` | `double`                       | `0`           | Horizontal margin per item                    |
| `itemBorderColor`      | `Color?`                       | `null`        | Border per item; `null` = no border           |
| `itemLabelBuilder`     | `String Function(T)?`          | `null`        | Custom display text                           |
| `itemBuilder`          | `Widget Function(T, bool)?`    | `null`        | Custom item widget                            |
| `validator`            | `FormFieldValidator<List<T>>?` | `null`        | Custom validator                              |

### Usage Example

```dart
FormFieldsCheckbox<String>(
  label: 'Interests',
  items: const ['Sports', 'Music', 'Reading', 'Travel'],
  initialValue: const ['Music'],
  isRequired: true,
  direction: Axis.vertical,
  itemBorderColor: Colors.grey.shade300,
  onChanged: (selected) => setState(() => interests = selected),
)
```

---

## 9. FormFieldsMyImage

Widget for picking, displaying, and uploading images or scanned documents. Supports single-image and multi-image modes, direct upload with per-image progress indicator, document scanning via `CunningDocumentScanner`, optional description input, and programmatic control via `FormFieldsMyImageController`.

### Constructor

```dart
FormFieldsMyImage({
  FormFieldsMyImageController? controller,
  void Function(List<MyimageResult>)? onImagesChanged,
  void Function(MyimageResult)? onImageChanged,
  String? label,
  bool isDoc = false,
  int? maxImages,
  Widget Function(BuildContext, MyimageResult, int)? imageBuilder,
  Widget Function(BuildContext, int index, MyimageResult)? removeIconBuilder,
  void Function(int index, MyimageResult)? onRemoveImage,
  Widget Function(BuildContext)? plusBuilder,
  String? uploadUrl,
  String? uploadToken,
  bool isDirectUpload = false,
  String? uploadSuccessTitle,
  String? uploadFailedTitle,
  String? uploadErrorTitle,
  String? uploadSuccessMessage,
  String? uploadFailedMessage,
  String? uploadErrorMessage,
  String uploadFileUrlKey = 'fileUrl',
  String uploadImageIdKey = 'imageId',
  bool allow = true,
  bool showUploadResultDialog = false,
  bool showDesc = false,
  String? descriptionField,
})
```

> **Assertion:** `isDirectUpload: true` requires a non-empty `uploadUrl`.

### Properties

#### Source & Callbacks

| Property          | Type                                  | Default | Description                                            |
| ----------------- | ------------------------------------- | ------- | ------------------------------------------------------ |
| `controller`      | `FormFieldsMyImageController?`        | `null`  | External controller; bidirectional sync                |
| `onImagesChanged` | `void Function(List<MyimageResult>)?` | `null`  | Fires on any change to the image list                  |
| `onImageChanged`  | `void Function(MyimageResult)?`       | `null`  | Single-image mode only; `MyimageResult()` when removed |
| `onRemoveImage`   | `void Function(int, MyimageResult)?`  | `null`  | Fires on image removal; index is `0` in single mode    |
| `allow`           | `bool`                                | `true`  | `false` = read-only (add/remove disabled)              |

#### Display

| Property            | Type                                                 | Default | Description                                 |
| ------------------- | ---------------------------------------------------- | ------- | ------------------------------------------- |
| `label`             | `String?`                                            | `null`  | Optional label above the widget             |
| `maxImages`         | `int?`                                               | `null`  | `1` = single-image mode; `null` = unlimited |
| `imageBuilder`      | `Widget Function(BuildContext, MyimageResult, int)?` | `null`  | Custom image tile builder                   |
| `removeIconBuilder` | `Widget Function(BuildContext, int, MyimageResult)?` | `null`  | Custom remove-icon builder                  |
| `plusBuilder`       | `Widget Function(BuildContext)?`                     | `null`  | Custom add-button builder                   |

#### Document Scanner

| Property | Type   | Default | Description                                                            |
| -------- | ------ | ------- | ---------------------------------------------------------------------- |
| `isDoc`  | `bool` | `false` | Open `CunningDocumentScanner` directly, skipping camera/gallery picker |

#### Direct Upload

| Property                 | Type      | Default     | Description                                              |
| ------------------------ | --------- | ----------- | -------------------------------------------------------- |
| `isDirectUpload`         | `bool`    | `false`     | Upload immediately after picking                         |
| `uploadUrl`              | `String?` | `null`      | Upload endpoint (required when `isDirectUpload: true`)   |
| `uploadToken`            | `String?` | `null`      | Bearer token for `Authorization` header                  |
| `uploadFileUrlKey`       | `String`  | `'fileUrl'` | JSON key for the uploaded file URL in the response       |
| `uploadImageIdKey`       | `String`  | `'imageId'` | JSON key for the image ID in the response                |
| `showUploadResultDialog` | `bool`    | `false`     | Show `AppDialogService` dialog on upload success/failure |

#### Upload Messages

All message/title fields are optional; missing values fall back to `FormFieldsLocalizations`.

| Property               | Type      | Description                      |
| ---------------------- | --------- | -------------------------------- |
| `uploadSuccessTitle`   | `String?` | Success dialog title             |
| `uploadFailedTitle`    | `String?` | HTTP-error dialog title          |
| `uploadErrorTitle`     | `String?` | Network/parse-error dialog title |
| `uploadSuccessMessage` | `String?` | Success dialog body              |
| `uploadFailedMessage`  | `String?` | HTTP-error dialog body           |
| `uploadErrorMessage`   | `String?` | Network/parse-error dialog body  |

#### Description Field

| Property           | Type      | Default         | Description                                   |
| ------------------ | --------- | --------------- | --------------------------------------------- |
| `showDesc`         | `bool`    | `false`         | Show a description bottom-sheet after picking |
| `descriptionField` | `String?` | `'description'` | Form-data field name sent to the server       |

### Behavior Notes

- **Single mode** (`maxImages == 1`): new image replaces the old one. `onImageChanged` is always called; an empty `MyimageResult()` signals removal.
- **Multi mode**: images accumulate up to `maxImages`. The `+` button disappears when the limit is reached.
- **Direct upload**: after picking, `DioUtil.uploadFile` is called with a linear progress indicator. On success, `MyimageResult.link` and `MyimageResult.imageId` are populated from the server response.
- **Picker source**: a bottom-sheet lets the user choose camera or gallery. Use `controller.pickImage(source: 'camera'|'gallery')` to skip the sheet programmatically.
- **Controller sync**: every change (add, remove, upload complete) is synced to `controller.images` before any callback fires.

### Usage Examples

```dart
// Single image
FormFieldsMyImage(
  maxImages: 1,
  onImageChanged: (image) {
    setState(() => profilePhoto = image.path.isNotEmpty ? image : null);
  },
)

// Multi image with limit
FormFieldsMyImage(
  maxImages: 5,
  onImagesChanged: (images) => setState(() => attachments = images),
)

// Direct upload
FormFieldsMyImage(
  maxImages: 1,
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer $token',
  showUploadResultDialog: true,
  onImageChanged: (image) {
    if (image.link.isNotEmpty) print('URL: ${image.link}');
  },
)

// With description
FormFieldsMyImage(
  maxImages: 3,
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  showDesc: true,
  descriptionField: 'caption',
  onImagesChanged: (images) => setState(() => photos = images),
)

// Document scanner
FormFieldsMyImage(
  isDoc: true,
  maxImages: 1,
  onImageChanged: (image) => setState(() => scannedDoc = image),
)

// Programmatic control
final ctrl = FormFieldsMyImageController();

FormFieldsMyImage(controller: ctrl, maxImages: 3, onImagesChanged: (_) {})

ElevatedButton(
  onPressed: () => ctrl.pickImage(source: 'gallery'),
  child: const Text('Choose Photo'),
)
```

---

## 10. FormFieldsSignaturePad

Signature pad for capturing handwritten signatures as PNG. Supports optional integrated live front-camera preview that auto-captures a selfie the moment the user begins drawing.

### Constructor

```dart
FormFieldsSignaturePad({
  double height = 200,
  double width = double.infinity,
  Color backgroundColor = Colors.white,
  Color penColor = Colors.black,
  double penStrokeWidth = 3.0,
  Color? exportBackgroundColor,
  void Function(MyimageResult?)? onExported,
  void Function(SignaturePadExportResult)? onExportedResult,
  void Function(MyimageResult)? onLiveCaptured,
  bool showLiveCamera = false,
  double liveCameraHeight = 200,
  FormFieldsMyImageController? liveCameraController,
  Widget Function(BuildContext, Widget signaturePad, Widget? camera)? layoutBuilder,
  Widget Function(BuildContext, Widget camera)? liveCameraBuilder,
})
```

### Properties

| Property                | Type                                       | Default           | Description                                        |
| ----------------------- | ------------------------------------------ | ----------------- | -------------------------------------------------- |
| `height`                | `double`                                   | `200`             | Drawing canvas height                              |
| `width`                 | `double`                                   | `double.infinity` | Drawing canvas width                               |
| `backgroundColor`       | `Color`                                    | `Colors.white`    | Canvas background color                            |
| `penColor`              | `Color`                                    | `Colors.black`    | Stroke color                                       |
| `penStrokeWidth`        | `double`                                   | `3.0`             | Stroke thickness                                   |
| `exportBackgroundColor` | `Color?`                                   | `null`            | PNG background override; `null` = transparent      |
| `onExported`            | `void Function(MyimageResult?)?`           | `null`            | Signature-only callback (backward-compat)          |
| `onExportedResult`      | `void Function(SignaturePadExportResult)?` | `null`            | Signature + optional live capture                  |
| `onLiveCaptured`        | `void Function(MyimageResult)?`            | `null`            | Fired immediately after auto-capture on draw start |
| `showLiveCamera`        | `bool`                                     | `false`           | Enable integrated front-camera                     |
| `liveCameraHeight`      | `double`                                   | `200`             | Camera preview height                              |
| `liveCameraController`  | `FormFieldsMyImageController?`             | `null`            | External controller updated with captured selfie   |
| `layoutBuilder`         | `Widget Function(ctx, pad, camera?)?`      | `null`            | Fully custom pad + camera layout                   |
| `liveCameraBuilder`     | `Widget Function(ctx, camera)?`            | `null`            | Custom wrapper around camera section only          |

### SignaturePadExportResult

```dart
class SignaturePadExportResult {
  final MyimageResult signature;    // always present
  final MyimageResult? liveCapture; // null when camera disabled or not yet captured
}
```

### Usage Examples

```dart
// Basic
FormFieldsSignaturePad(
  height: 200,
  penColor: Colors.black,
  onExported: (result) {
    if (result != null) uploadSignature(result.base64);
  },
)

// With live camera
FormFieldsSignaturePad(
  showLiveCamera: true,
  liveCameraController: liveCameraController,
  onLiveCaptured: (selfie) => print('Selfie: ${selfie.path}'),
  onExportedResult: (result) {
    uploadBoth(result.signature, result.liveCapture);
  },
)

// Side-by-side layout
FormFieldsSignaturePad(
  showLiveCamera: true,
  layoutBuilder: (ctx, pad, camera) => Row(
    children: [
      Expanded(child: pad),
      if (camera != null) SizedBox(width: 150, child: camera),
    ],
  ),
  onExportedResult: (_) {},
)
```

### Behavior Notes

- Camera auto-captures **once per signing session** (on first `onDrawStart`).
- Pressing the clear button resets the auto-capture guard so the next draw attempt will capture again.
- Prefer `onExportedResult` over `onExported` when `showLiveCamera: true`.

---

## 11. FormFieldsLiveCameraCapture

Standalone live front-camera preview widget. Can be used independently or embedded inside `FormFieldsSignaturePad`. Capture is screenshot-based (`RepaintBoundary.toImage`) to avoid CameraX surface-combination conflicts. Front camera is used by default.

### Constructor

```dart
FormFieldsLiveCameraCapture({
  double height = 100,
  FormFieldsMyImageController? cameraController,
  void Function(MyimageResult)? onCaptured,
})
```

### Properties

| Property           | Type                            | Default | Description                                        |
| ------------------ | ------------------------------- | ------- | -------------------------------------------------- |
| `height`           | `double`                        | `100`   | Camera preview height                              |
| `cameraController` | `FormFieldsMyImageController?`  | `null`  | External controller for programmatic capture/reset |
| `onCaptured`       | `void Function(MyimageResult)?` | `null`  | Called each time `capture()` succeeds              |

### State Methods (via `GlobalKey<FormFieldsLiveCameraCaptureState>`)

| Method           | Return                   | Description                                                      |
| ---------------- | ------------------------ | ---------------------------------------------------------------- |
| `capture()`      | `Future<MyimageResult?>` | Capture current frame as PNG; returns `null` if camera not ready |
| `resetCapture()` | `void`                   | Clear capture and return to live preview                         |

### Usage Examples

```dart
// Via GlobalKey
final cameraKey = GlobalKey<FormFieldsLiveCameraCaptureState>();

FormFieldsLiveCameraCapture(
  key: cameraKey,
  height: 200,
  onCaptured: (result) => setState(() => photo = result),
)

ElevatedButton(
  onPressed: () async {
    final result = await cameraKey.currentState?.capture();
  },
  child: const Text('Capture'),
)

// Via controller (suitable for ViewModel / outside widget tree)
final cameraCtrl = FormFieldsMyImageController();

FormFieldsLiveCameraCapture(
  height: 200,
  cameraController: cameraCtrl,
)

final result = await cameraCtrl.capture();
cameraCtrl.resetCapture();
```

---

## 12. AppButton

Unified button widget supporting all Material button variants, loading states, optional `AppButtonLayout` wrapping, and typed value callbacks.

### Constructor

```dart
AppButton<T>({
  AppButtonType type = AppButtonType.filled,
  AppButtonSize size = AppButtonSize.medium,
  String? text,
  Widget? child,
  Widget? icon,
  VoidCallback? onPressed,
  T? value,
  ValueChanged<T?>? onPressedWithValue,
  bool isLoading = false,
  ButtonStyle? style,
  double? customHeight,
  double? customHorizontalPadding,
  double? customIconSize,
  double? customSpinnerSize,
  bool withLayout = false,
  EdgeInsetsGeometry? margin,
  double horizontalPadding = 16,
  double topPadding = 12,
  bool respectSafeArea = true,
  bool avoidKeyboard = true,
})
```

> At least one of `text`, `child`, or `icon` must be provided.

### Properties

| Property                  | Type                  | Default  | Description                                        |
| ------------------------- | --------------------- | -------- | -------------------------------------------------- |
| `type`                    | `AppButtonType`       | `filled` | Visual variant                                     |
| `size`                    | `AppButtonSize`       | `medium` | Size preset                                        |
| `text`                    | `String?`             | `null`   | Button label                                       |
| `child`                   | `Widget?`             | `null`   | Fully custom content                               |
| `icon`                    | `Widget?`             | `null`   | Leading / only icon                                |
| `onPressed`               | `VoidCallback?`       | `null`   | Tap callback                                       |
| `value`                   | `T?`                  | `null`   | Value passed to `onPressedWithValue`               |
| `onPressedWithValue`      | `ValueChanged<T?>?`   | `null`   | Tap callback with value                            |
| `isLoading`               | `bool`                | `false`  | Show spinner and disable interactions              |
| `style`                   | `ButtonStyle?`        | `null`   | Override button style                              |
| `customHeight`            | `double?`             | `null`   | Active when `size == custom`                       |
| `customHorizontalPadding` | `double?`             | `null`   | Active when `size == custom`                       |
| `customIconSize`          | `double?`             | `null`   | Active when `size == custom`                       |
| `withLayout`              | `bool`                | `false`  | Wrap with `AppButtonLayout` for keyboard avoidance |
| `horizontalPadding`       | `double`              | `16`     | Passed to `AppButtonLayout`                        |
| `topPadding`              | `double`              | `12`     | Passed to `AppButtonLayout`                        |
| `respectSafeArea`         | `bool`                | `true`   | Passed to `AppButtonLayout`                        |
| `avoidKeyboard`           | `bool`                | `true`   | Passed to `AppButtonLayout`                        |
| `margin`                  | `EdgeInsetsGeometry?` | `null`   | Passed to `AppButtonLayout`                        |

### AppButtonType Enum

```dart
enum AppButtonType {
  filled,       // Filled background
  filledTonal,  // Filled tonal variant
  elevated,     // Elevated with shadow
  outlined,     // Border only
  text,         // Text only
  icon,         // Icon only
  fab,          // Floating action button
  extendedFab,  // FAB with label
}
```

### AppButtonSize Enum

```dart
enum AppButtonSize {
  small,   // Compact
  medium,  // Standard (default)
  large,   // Larger touch target
  custom,  // Use customHeight / customHorizontalPadding / customIconSize
}
```

### AppButtonThemeData

Theme extension for per-app style overrides:

```dart
ThemeData(
  extensions: [
    AppButtonThemeData(
      filledStyle: FilledButton.styleFrom(backgroundColor: Colors.indigo),
      elevatedStyle: ElevatedButton.styleFrom(elevation: 4),
    ),
  ],
)
```

### Usage Examples

```dart
// Primary filled
AppButton(
  text: 'Submit',
  onPressed: () => submit(),
)

// Loading state
AppButton(
  text: 'Saving…',
  isLoading: isSaving,
  onPressed: isSaving ? null : () => save(),
)

// Icon button
AppButton(
  type: AppButtonType.icon,
  icon: const Icon(Icons.add),
  onPressed: () => addItem(),
)

// Keyboard-aware bottom button
AppButton(
  text: 'Continue',
  withLayout: true,
  onPressed: () => next(),
)
```

---

## 13. AppButtonGroup

Lightweight layout wrapper for grouping related `AppButton` widgets.

### Constructor

```dart
AppButtonGroup({
  required List<Widget> children,
  Axis direction = Axis.horizontal,
  double spacing = 8,
  double runSpacing = 8,
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  WrapAlignment wrapAlignment = WrapAlignment.start,
})
```

### Properties

| Property        | Type            | Default      | Description                                        |
| --------------- | --------------- | ------------ | -------------------------------------------------- |
| `children`      | `List<Widget>`  | —            | Buttons or any widgets (required)                  |
| `direction`     | `Axis`          | `horizontal` | `horizontal` uses `Wrap`; `vertical` uses `Column` |
| `spacing`       | `double`        | `8`          | Gap between items                                  |
| `runSpacing`    | `double`        | `8`          | Gap between wrapped rows (horizontal mode)         |
| `wrapAlignment` | `WrapAlignment` | `start`      | Alignment in horizontal/Wrap mode                  |

### Usage Example

```dart
AppButtonGroup(
  spacing: 12,
  children: [
    AppButton(text: 'Cancel', type: AppButtonType.outlined, onPressed: cancel),
    AppButton(text: 'Confirm', onPressed: confirm),
  ],
)
```

---

## 14. AppSegmentedButton\<T\>

Typed wrapper around Material 3 `SegmentedButton` with size presets.

### Constructor

```dart
AppSegmentedButton<T>({
  required List<ButtonSegment<T>> segments,
  required Set<T> selected,
  required ValueChanged<Set<T>> onSelectionChanged,
  bool multiSelectionEnabled = false,
  bool emptySelectionAllowed = false,
  AppButtonSize size = AppButtonSize.medium,
  ButtonStyle? style,
  bool showSelectedIcon = true,
  Widget? selectedIcon,
})
```

### Usage Example

```dart
AppSegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'day', label: Text('Day')),
    ButtonSegment(value: 'week', label: Text('Week')),
    ButtonSegment(value: 'month', label: Text('Month')),
  ],
  selected: {selectedRange},
  onSelectionChanged: (val) => setState(() => selectedRange = val.first),
)
```

---

## 15. AppSplitButton\<T\>

A split button combining a primary action button with a dropdown of secondary actions.

### Constructor

```dart
AppSplitButton<T>({
  required String text,
  required VoidCallback? onPressed,
  required List<AppSplitButtonItem<T>> items,
  required ValueChanged<T> onSelected,
  Widget? icon,
  bool isLoading = false,
  AppButtonSize size = AppButtonSize.medium,
  double? height,
  double? mainHorizontalPadding,
  double? dropdownWidth,
  double? width,
  bool expand = false,
})
```

### AppSplitButtonItem\<T\>

```dart
class AppSplitButtonItem<T> {
  final T value;
  final String label;
  final Widget? leading;
}
```

### Usage Example

```dart
AppSplitButton<String>(
  text: 'Save',
  icon: const Icon(Icons.save),
  onPressed: () => save(),
  items: const [
    AppSplitButtonItem(value: 'draft', label: 'Save as Draft'),
    AppSplitButtonItem(value: 'publish', label: 'Publish'),
  ],
  onSelected: (value) => handleAction(value),
)
```

---

## 16. AppFabMenu

Expandable FAB menu that floats action items above the button using an `Overlay`. No `Scaffold` required.

### Constructor

```dart
AppFabMenu({
  required List<AppFabMenuItem> items,
  Widget? mainIcon,
  AppButtonSize size = AppButtonSize.medium,
})
```

### AppFabMenuItem

```dart
class AppFabMenuItem {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
}
```

### Usage Example

```dart
AppFabMenu(
  mainIcon: const Icon(Icons.add),
  items: [
    AppFabMenuItem(
      label: 'Upload Photo',
      icon: const Icon(Icons.photo),
      onPressed: () => uploadPhoto(),
    ),
    AppFabMenuItem(
      label: 'Scan Document',
      icon: const Icon(Icons.document_scanner),
      onPressed: () => scanDoc(),
    ),
  ],
)
```

---

## 17. AppDialogService

Context-scoped dialog helper for loading spinners, result dialogs, and guarded async flows with automatic error handling.

### Constructor

```dart
AppDialogService(BuildContext context)
```

### Methods

#### `guard<T>`

Runs an async task with optional blocking loader, shows an error dialog on failure, and calls success/error callbacks.

```dart
Future<T?> guard<T>({
  required Future<T> Function() task,
  required String errorTitle,
  AppDialogErrorMapper? mapError,
  bool showBlockingLoading = false,
  String loadingMessage = 'Loading...',
  AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
  AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
  AppProgressType progressType = AppProgressType.circular,
  AppDialogLoadingBackBehavior loadingBackBehavior = AppDialogLoadingBackBehavior.block,
  AppDialogCancelRequested? onCancelRequested,
  AppDialogCancelled? onCancelled,
  bool showSuccessDialog = false,
  String successTitle = 'Success',
  String successMessage = 'Operation completed successfully.',
  AppDialogSuccessCallback<T>? onSuccess,
  AppDialogErrorCallback? onError,
  void Function(Map<String, List<String>>)? onValidationError,
  AppDialogPosition loadingPosition = AppDialogPosition.top,
  AppDialogPosition resultPosition = AppDialogPosition.top,
  String okLabel = 'OK',
})
```

#### Other Methods

| Method                                                                               | Description                                        |
| ------------------------------------------------------------------------------------ | -------------------------------------------------- |
| `showLoading({...})`                                                                 | Show a standalone loading dialog                   |
| `hide()`                                                                             | Dismiss the loading dialog                         |
| `showSuccess({title, message, position, okLabel, onComplete})`                       | Show success dialog                                |
| `showError({title, message, dialogType, position, okLabel, onComplete})`             | Show error dialog                                  |
| `showInfo({title, message, position, okLabel})`                                      | Show info/validation dialog                        |
| `showResult({title, message, isSuccess, dialogType, position, okLabel, onComplete})` | Low-level result dialog                            |
| `showExitConfirm({...})`                                                             | Show "are you sure you want to exit?" confirmation |
| `unguardedLoadingVisualOnly({show, ...})`                                            | Toggle loading dialog imperatively                 |

#### `defaultErrorMapper` (static)

Maps `ValidationException` → `AppDialogType.validation`; everything else → `AppDialogType.server`.

### Usage Example

```dart
final dialog = AppDialogService(context);

await dialog.guard<void>(
  task: () async {
    if (!formValid) throw ValidationException('Please fill all fields.');
    await api.submit(formData);
  },
  errorTitle: 'Submission Failed',
  mapError: AppDialogService.defaultErrorMapper,
  showBlockingLoading: true,
  loadingMessage: 'Submitting…',
  showSuccessDialog: true,
  successTitle: 'Done',
  successMessage: 'Form submitted successfully.',
  onSuccess: (_) async => Navigator.pop(context),
  onValidationError: (errors) => highlightErrors(errors),
);
```

---

## 18. AppGlobalDialogService

Singleton coordinator that delegates all dialog calls to `AppDialogService` using a configured root navigator key. Allows showing dialogs from anywhere without `BuildContext`.

### Setup

```dart
// main.dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  AppGlobalDialogService.instance.configure(navigatorKey);
  runApp(MyApp(navigatorKey: navigatorKey));
}
```

### Methods

Same API as `AppDialogService`:

| Method                                 | Description                                    |
| -------------------------------------- | ---------------------------------------------- |
| `configure(GlobalKey<NavigatorState>)` | Register the root navigator key                |
| `reset()`                              | Clear the navigator key (testing / hot reload) |
| `guard<T>({...})`                      | Guarded async task                             |
| `showLoading({...})`                   | Show loading dialog                            |
| `hide()`                               | Dismiss loading dialog                         |
| `showSuccess({...})`                   | Success dialog                                 |
| `showError({...})`                     | Error dialog                                   |
| `showInfo({...})`                      | Info dialog                                    |
| `showResult({...})`                    | Low-level result dialog                        |
| `showExitConfirm({...})`               | Exit confirmation                              |

### Usage Example

```dart
// From ViewModel / service layer — no BuildContext needed
await AppGlobalDialogService.instance.guard<void>(
  task: () => repository.save(data),
  errorTitle: 'Save Failed',
  showBlockingLoading: true,
);
```

---

## 19. AppLoadingIndicator

Animated loading widget with three visual variants.

### Constructor

```dart
AppLoadingIndicator({
  AppLoadingVariant variant = AppLoadingVariant.spinner,
  double size = 34,
  Color? color,
})
```

### AppLoadingVariant Enum

| Value     | Description               |
| --------- | ------------------------- |
| `spinner` | Standard circular spinner |
| `pulse`   | Pulsating circle          |
| `dots`    | Three-dot wave animation  |

### Usage Example

```dart
AppLoadingIndicator(
  variant: AppLoadingVariant.dots,
  size: 40,
  color: Colors.blue,
)
```

---

## 20. AppProgressIndicator

Determinate or indeterminate progress indicator with linear and circular types.

### Constructor

```dart
AppProgressIndicator({
  required AppProgressType type,
  double? value,       // null = indeterminate
  double? size,        // for circular
  double? minHeight,   // for linear
  Color? color,
  Color? backgroundColor,
})
```

### AppProgressType Enum

| Value      | Description             |
| ---------- | ----------------------- |
| `linear`   | Horizontal progress bar |
| `circular` | Circular progress ring  |

### Usage Example

```dart
// Indeterminate linear
AppProgressIndicator(type: AppProgressType.linear, value: null)

// Determinate circular (60 %)
AppProgressIndicator(type: AppProgressType.circular, value: 0.6, size: 48)
```

---

## 21. showAppModalBottomSheet

Top-level helper function that wraps `showModalBottomSheet` with safe-area handling and keyboard-aware bottom inset padding.

### Signature

```dart
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  bool? showDragHandle,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
  bool useRootNavigator = false,
  bool? requestFocus,
  double scrollControlDisabledMaxHeightRatio = 9 / 16,
  AnimationController? transitionAnimationController,
  AnimationStyle? sheetAnimationStyle,
  Offset? anchorPoint,
  RouteSettings? routeSettings,
  Color? barrierColor,
  String? barrierLabel,
})
```

### Key Parameters

| Parameter            | Type            | Default | Description                                    |
| -------------------- | --------------- | ------- | ---------------------------------------------- |
| `context`            | `BuildContext`  | —       | Required                                       |
| `builder`            | `WidgetBuilder` | —       | Sheet content builder (required)               |
| `isScrollControlled` | `bool`          | `true`  | Allow full-height sheet                        |
| `useSafeArea`        | `bool`          | `true`  | Wraps with `SafeArea` + keyboard inset padding |
| `isDismissible`      | `bool`          | `true`  | Dismiss on outside tap                         |
| `enableDrag`         | `bool`          | `true`  | Swipe-down to dismiss                          |
| `shape`              | `ShapeBorder?`  | `null`  | Rounded corners etc.                           |

### Usage Example

```dart
showAppModalBottomSheet(
  context: context,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (ctx) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(title: const Text('Option A'), onTap: () => Navigator.pop(ctx, 'a')),
      ListTile(title: const Text('Option B'), onTap: () => Navigator.pop(ctx, 'b')),
    ],
  ),
);
```

---

## 22. ResponsiveMenuGrid

Responsive square grid that auto-calculates column count from available width and a fixed `itemSize`.

### Constructor

```dart
ResponsiveMenuGrid({
  required List<Widget> widgets,
  double itemSize = 80,
  double horizontalMargin = 16,
  double verticalSpacing = 16,
  bool alignLeft = false,
})
```

### Properties

| Property           | Type           | Default | Description                         |
| ------------------ | -------------- | ------- | ----------------------------------- |
| `widgets`          | `List<Widget>` | —       | Grid children (required)            |
| `itemSize`         | `double`       | `80`    | Fixed width and height of each cell |
| `horizontalMargin` | `double`       | `16`    | Left and right margin               |
| `verticalSpacing`  | `double`       | `16`    | Row gap                             |
| `alignLeft`        | `bool`         | `false` | Force left alignment                |

### Usage Example

```dart
ResponsiveMenuGrid(
  itemSize: 80,
  widgets: menuItems
      .map((item) => MenuTile(icon: item.icon, label: item.title))
      .toList(),
)
```

---

## 23. FormFieldsMyImageController

`ChangeNotifier`-based external controller for `FormFieldsMyImage` and `FormFieldsLiveCameraCapture`. Provides bidirectional sync and programmatic trigger of capture and picker.

### Properties

| Property | Type                  | Description                                    |
| -------- | --------------------- | ---------------------------------------------- |
| `images` | `List<MyimageResult>` | Current image list (setter notifies listeners) |

### Methods

| Method                        | Return                   | Description                                                                                              |
| ----------------------------- | ------------------------ | -------------------------------------------------------------------------------------------------------- |
| `addImage(MyimageResult)`     | `void`                   | Append and notify                                                                                        |
| `clear()`                     | `void`                   | Remove all and notify                                                                                    |
| `capture()`                   | `Future<MyimageResult?>` | Trigger capture on linked `FormFieldsLiveCameraCapture`; no-op if none                                   |
| `resetCapture()`              | `void`                   | Trigger reset on linked `FormFieldsLiveCameraCapture`; no-op if none                                     |
| `pickImage({String? source})` | `Future<void>`           | Open picker on linked `FormFieldsMyImage`; `source`: `'camera'`, `'gallery'`, or `null` for bottom-sheet |
| `dispose()`                   | `void`                   | Release resources                                                                                        |

### Usage Example

```dart
final ctrl = FormFieldsMyImageController();

ctrl.addListener(() => print(ctrl.images.length));

await ctrl.pickImage(source: 'camera');
final selfie = await ctrl.capture();
ctrl.resetCapture();

ctrl.dispose();
```

---

## 24. FormFieldsMyImageProvider

`ChangeNotifier`-based state provider for managing a list of `MyimageResult` with per-image upload-progress tracking. Suitable for use with `provider` or `ChangeNotifierProvider`.

### Properties

| Property         | Type                  | Description                    |
| ---------------- | --------------------- | ------------------------------ |
| `images`         | `List<MyimageResult>` | Current image list             |
| `uploadProgress` | `List<double>`        | Progress per image (0.0 – 1.0) |
| `loading`        | `bool`                | Global loading state           |

### Methods

| Method                                  | Description                                 |
| --------------------------------------- | ------------------------------------------- |
| `setImages(List<MyimageResult>)`        | Replace list and reset all progress entries |
| `addImage(MyimageResult)`               | Append image with progress 0.0              |
| `removeImage(int index)`                | Remove image and its progress entry         |
| `updateImage(int index, MyimageResult)` | Replace image at index                      |
| `clearImages()`                         | Remove all images and progress              |
| `setUploadProgress(int index, double)`  | Set progress for image at index             |
| `resetUploadProgress(int index)`        | Reset progress to 0.0 for image at index    |

### Usage Example

```dart
ChangeNotifierProvider(
  create: (_) => FormFieldsMyImageProvider(),
  child: Consumer<FormFieldsMyImageProvider>(
    builder: (context, provider, _) {
      return Column(
        children: [
          for (var i = 0; i < provider.images.length; i++)
            LinearProgressIndicator(value: provider.uploadProgress[i]),
        ],
      );
    },
  ),
)
```

---

## 25. MyimageResult

Immutable data class representing a captured, picked, or uploaded image.

### Properties

| Property  | Type     | Description                              |
| --------- | -------- | ---------------------------------------- |
| `path`    | `String` | Absolute local file path                 |
| `base64`  | `String` | Data URI: `data:<mime>;base64,<data>`    |
| `link`    | `String` | Remote URL (empty before upload)         |
| `imageId` | `String` | Server-assigned ID (empty before upload) |

### Factory

```dart
static Future<MyimageResult> fromFile(File file, {String? link})
```

Reads bytes, encodes to base64, and auto-detects MIME type from extension.

**Supported MIME types:** `image/jpeg`, `image/png`, `image/gif`, `image/bmp`, `image/webp`, `image/svg+xml`, `image/heic`, `video/mp4`, `video/quicktime`, `application/pdf`, `application/octet-stream` (fallback).

### Usage Example

```dart
final result = await MyimageResult.fromFile(File('/tmp/photo.png'));
print(result.path);   // /tmp/photo.png
print(result.base64); // data:image/png;base64,...
print(result.link);   // '' (until uploaded)
```

---

## 26. DioUtil

Static utility class for file upload and download via Dio with built-in error handling and structured logging.

### Methods

#### `safeRequest<T>`

```dart
static Future<T?> safeRequest<T>(
  Future<T> Function() request, {
  String? url,
})
```

Wraps any Dio call. Returns `null` on error for non-`Response` types, or a synthetic `500` `Response` when `T == Response`.

#### `downloadFile`

```dart
static Future<String?> downloadFile(String url)
```

Downloads a file to the system temp directory. Returns the local file path on success, `null` on failure.

#### `uploadFile`

```dart
static Future<Response?> uploadFile({
  required String url,
  required String filePath,
  String? filename,
  Map<String, String>? headers,
  void Function(double progress)? onProgress,
  List<MapEntry<String, String>>? fields,
})
```

Uploads a file as `multipart/form-data`.

| Parameter    | Type                              | Description                       |
| ------------ | --------------------------------- | --------------------------------- |
| `url`        | `String`                          | Upload endpoint (required)        |
| `filePath`   | `String`                          | Absolute local path (required)    |
| `filename`   | `String?`                         | Override file name sent to server |
| `headers`    | `Map<String, String>?`            | Additional HTTP headers           |
| `onProgress` | `void Function(double)?`          | Progress callback (0.0 – 1.0)     |
| `fields`     | `List<MapEntry<String, String>>?` | Additional form fields            |

### Usage Example

```dart
final response = await DioUtil.uploadFile(
  url: 'https://api.example.com/upload',
  filePath: '/tmp/photo.png',
  headers: {'Authorization': 'Bearer $token'},
  onProgress: (p) => setState(() => progress = p),
  fields: [MapEntry('userId', '42')],
);

final localPath = await DioUtil.downloadFile('https://example.com/file.pdf');
```

---

## 27. FormFieldValidators

Static helper methods that return `FormFieldValidator<String?>` functions, compatible with any Flutter form field.

### Methods

| Method      | Signature                                                         | Description                            |
| ----------- | ----------------------------------------------------------------- | -------------------------------------- |
| `required`  | `required(String label, {String? customMessage})`                 | Non-empty                              |
| `email`     | `email(String label, {String? customMessage})`                    | Email format                           |
| `phone`     | `phone(String label, {String? customMessage})`                    | Indonesian phone (0 + 11 digits)       |
| `password`  | `password(String label, {String? customMessage})`                 | Minimum 6 characters                   |
| `number`    | `number(String label, {String? customMessage})`                   | Numeric only                           |
| `minLength` | `minLength(String label, int min, {String? customMessage})`       | Minimum length                         |
| `maxLength` | `maxLength(String label, int max, {String? customMessage})`       | Maximum length                         |
| `range`     | `range(String label, num min, num max, {String? customMessage})`  | Numeric range                          |
| `pattern`   | `pattern(String label, String pattern, {String? customMessage})`  | Regex match                            |
| `match`     | `match(String label, String matchValue, {String? customMessage})` | Equality check (e.g. confirm password) |
| `compose`   | `compose(List<FormFieldValidator<String?>> validators)`           | Chain multiple validators              |

### Usage Example

```dart
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  validator: FormFieldValidators.compose([
    FormFieldValidators.required('Email'),
    FormFieldValidators.email('Email'),
  ]),
  onChanged: (_) {},
)
```

---

## 28. Enums Reference

### FormType

```dart
enum FormType {
  phone,         // Phone number
  password,      // Password with visibility toggle
  verification,  // OTP / digit-only
  email,         // Email
  date,          // Date picker → DateTime
  time,          // Time picker → DateTime or TimeOfDay
  dateTime,      // Date + time picker → DateTime
  dateTimeRange, // Date range picker → DateTimeRange
  timeOfDay,     // Time picker → TimeOfDay
  dropdown,      // Single-select dropdown
  dropdownMulti, // Multi-select dropdown
  radioButton,   // Radio group
  checkbox,      // Checkbox group
  scanBarcode,   // Barcode scanner
}
```

### LabelPosition

```dart
enum LabelPosition { top, bottom, left, right, inBorder, none }
```

### BorderType

```dart
enum BorderType { outlineInputBorder, underlineInputBorder, none }
```

### OtpBorderType

```dart
enum OtpBorderType { box, underline }
```

### AppButtonType

```dart
enum AppButtonType { filled, filledTonal, elevated, outlined, text, icon, fab, extendedFab }
```

### AppButtonSize

```dart
enum AppButtonSize { small, medium, large, custom }
```

### AppDialogType

```dart
enum AppDialogType { validation, network, authentication, server }
```

### AppDialogPosition

```dart
enum AppDialogPosition { top, center, bottom }
```

### AppDialogLoadingVisual

```dart
enum AppDialogLoadingVisual { indicator, progress }
```

### AppDialogLoadingContainer

```dart
enum AppDialogLoadingContainer { card, nonCard }
```

### AppDialogLoadingBackBehavior

```dart
enum AppDialogLoadingBackBehavior { block, allow, confirmCancel }
```

### AppLoadingVariant

```dart
enum AppLoadingVariant { spinner, pulse, dots }
```

### AppProgressType

```dart
enum AppProgressType { linear, circular }
```

### Formats (for DateTime extensions)

```dart
enum Formats { date, time, dateTime, dayDate, dayDateTime, month, string }
```

---

## 29. String Extensions

### Validation Properties

| Extension              | Return | Description                            |
| ---------------------- | ------ | -------------------------------------- |
| `.isValidEmail`        | `bool` | Valid email format                     |
| `.isValidPhone`        | `bool` | Valid Indonesian phone (0 + 11 digits) |
| `.isValidPassword`     | `bool` | Length ≥ 6                             |
| `.isValidNumber`       | `bool` | Numeric only                           |
| `.isWhiteSpace`        | `bool` | Empty or whitespace only               |
| `.isValidVerification` | `bool` | Length ≥ 1                             |

### Manipulation Methods

| Extension      | Return   | Description                  |
| -------------- | -------- | ---------------------------- |
| `.hidePhone`   | `String` | Mask first 7 chars with `*`  |
| `.is0Phone`    | `String` | Ensure phone starts with `0` |
| `.toTitleCase` | `String` | Convert to Title Case        |

---

## 30. DateTime & TimeOfDay Extensions

### DateTime? Extensions

#### Comparison

```dart
date.isBefore(other)
date.isAfter(other)
date.isAtSameMomentAs(other)
```

#### Formatting

```dart
date.toStrings()                              // default format
date.toStrings(format: Formats.date)          // date only
date.toStrings(format: Formats.time)          // time only
date.toStrings(format: Formats.dateTime)      // date + time
date.toStrings(stringFormat: 'dd/MM/yyyy')    // custom pattern
```

#### Conversion

```dart
TimeOfDay? tod = date.toTimeOfDay();
```

### TimeOfDay? Extensions

```dart
DateTime? dt   = time.toDateTime();                              // current date + time
DateTime? dt2  = time.toDateTimeWithDate(DateTime(2026, 6, 1)); // specific date + time
```

### Usage Example

```dart
FormFields<TimeOfDay>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (time) {
    if (time != null) {
      final fullDateTime = time.toDateTimeWithDate(selectedDate);
    }
  },
)
```

---

## Related Resources

- [README](README.md) — Package overview and installation
- [USAGE](USAGE.md) — Comprehensive usage manual
- [QUICKSTART](QUICKSTART.md) — Quick start guide
- [LOCALIZATION](LOCALIZATION.md) — i18n and locale configuration
- [CHANGELOG](CHANGELOG.md) — Version history
- [Example App](example/lib/main.dart) — Runnable example application
