# 🏁 Navigation

- [FormFields](#1-formfields) — The core, highly customizable text and input field widget supporting all types and label positions.
  - [Properties](#properties) — All configurable options for FormFields.
  - [How to Use Each Property](#how-to-use-each-property-detailed) — Code examples for every property.
- [FormFieldsCheckbox](#2-formfieldscheckbox) — Checkbox group widget for multi-selection with custom item builders.
  - [Properties](#properties-1)
  - [Properties Example](#properties-example)
  - [How to Use Each Property](#how-to-use-each-property-detailed)
- [FormFieldsDropdownMulti](#3-formfieldsdropdownmulti) — Multi-select dropdown with chips, filtering, and selection limits.
  - [Properties](#properties-2)
  - [Properties Example](#properties-example-1)
  - [How to Use Each Property](#how-to-use-each-property-detailed)
- [FormFieldsDropdown](#4-formfieldsdropdown) — Single-select dropdown with search, custom labels, and decoration.
  - [Properties](#properties-3)
  - [Properties Example](#properties-example-2)
  - [How to Use Each Property](#how-to-use-each-property-detailed)
- [FormFieldsRadioButton](#5-formfieldsradiobutton) — Radio button group with sectioning, custom widgets, and advanced styling.
  - [Properties](#properties-4)
  - [Properties Example](#properties-example-3)
  - [How to Use Each Property](#how-to-use-each-property-detailed)
- [FormFieldsSelect](#6-formfieldsselect) — Unified selection widget for dropdown, multi-select, radio, and checkbox.
  - [Properties](#properties-5)
  - [Properties Example](#properties-example-4)
  - [How to Use Each Property](#how-to-use-each-property-detailed)
- [Utilities & Advanced Usage](#utilities--advanced-usage) — Enums, validators, controller, and null-safety patterns.

---

## 1. FormFields

### Properties
| Property                | Type                        | Description                                      |
|-------------------------|-----------------------------|--------------------------------------------------|
| label                   | String                      | The label to display above or beside the field.   |
| formType                | FormType                    | The type of input (string, email, phone, etc.).   |
| isRequired              | bool                        | Whether the field is required.                    |
| currrentValue           | T / T?                      | The current value of the field.                   |
| onChanged               | ValueChanged<T?>            | Callback when the value changes.                  |
| validator               | FormFieldValidator<String>?  | Custom validation logic.                          |
| labelPosition           | LabelPosition               | Position of the label (top, left, etc.).          |
| borderType              | BorderType                  | Border style (outline, underline, none).          |
| radius                  | double                      | Border radius.                                    |
| prefixIcon              | Widget?                     | Icon before the input.                            |
| suffixIcon              | Widget?                     | Icon after the input.                             |
| inputDecoration         | InputDecoration?            | Custom input decoration.                          |
| multiLine               | int                         | Number of visible lines for text input.           |
| stripSeparators         | bool                        | Format numbers with separators.                   |
| pickerLocale            | String?                     | Locale for date/time pickers.                     |
| customFormat            | String?                     | Custom date/time format.                          |
| firstDate               | DateTime?                   | Earliest selectable date.                         |
| lastDate                | DateTime?                   | Latest selectable date.                           |
| autovalidateMode        | AutovalidateMode            | When to show validation errors.                   |
| minLengthPassword       | int                         | Minimum length for password field.                |
| customPasswordValidator | FormFieldValidator<String>? | Custom password validator.                        |
| minLengthPasswordErrorText | String?                  | Error text for minimum password length.           |

### How to Use Each Property (Detailed)
- **label**
```dart
FormFields<String>(label: 'Username', onChanged: (v) {})
```
- **formType**
```dart
FormFields<String>(formType: FormType.email, onChanged: (v) {})
```
- **isRequired**
```dart
FormFields<String>(isRequired: true, onChanged: (v) {})
```
- **currrentValue**
```dart
FormFields<String>(currrentValue: 'init', onChanged: (v) {})
```
- **onChanged**
```dart
FormFields<String>(onChanged: (value) { print(value); })
```
- **validator**
```dart
FormFields<String>(validator: (v) => v == null ? 'Required' : null, onChanged: (v) {})
```
- **labelPosition**
```dart
FormFields<String>(labelPosition: LabelPosition.left, onChanged: (v) {})
```
- **borderType**
```dart
FormFields<String>(borderType: BorderType.underlineInputBorder, onChanged: (v) {})
```
- **radius**
```dart
FormFields<String>(radius: 16, onChanged: (v) {})
```
- **prefixIcon**
```dart
FormFields<String>(prefixIcon: Icon(Icons.person), onChanged: (v) {})
```
- **suffixIcon**
```dart
FormFields<String>(suffixIcon: Icon(Icons.clear), onChanged: (v) {})
```
- **inputDecoration**
```dart
FormFields<String>(inputDecoration: InputDecoration(hintText: 'Hint'), onChanged: (v) {})
```
- **multiLine**
```dart
FormFields<String>(multiLine: 3, onChanged: (v) {})
```
- **stripSeparators**
```dart
FormFields<int>(stripSeparators: true, onChanged: (v) {})
```
- **pickerLocale**
```dart
FormFields<DateTime>(pickerLocale: 'en_US', onChanged: (v) {})
```
- **customFormat**
```dart
FormFields<DateTime>(customFormat: 'dd/MM/yyyy', onChanged: (v) {})
```
- **firstDate**
```dart
FormFields<DateTime>(firstDate: DateTime(2020, 1, 1), onChanged: (v) {})
```
- **lastDate**
```dart
FormFields<DateTime>(lastDate: DateTime(2030, 1, 1), onChanged: (v) {})
```
- **autovalidateMode**
```dart
FormFields<String>(autovalidateMode: AutovalidateMode.onUserInteraction, onChanged: (v) {})
```
- **minLengthPassword**
```dart
FormFields<String>(formType: FormType.password, minLengthPassword: 8, onChanged: (v) {})
```
- **customPasswordValidator**
```dart
FormFields<String>(formType: FormType.password, customPasswordValidator: (v) => v == '123' ? 'Weak' : null, onChanged: (v) {})
```
- **minLengthPasswordErrorText**
```dart
FormFields<String>(formType: FormType.password, minLengthPasswordErrorText: 'Too short', onChanged: (v) {})
```

### Custom Class
You can use custom classes for advanced scenarios:
```dart
class Country {
  final String code;
  final String name;
  Country(this.code, this.name);
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Country && code == other.code;
  @override
  int get hashCode => code.hashCode;
}

FormFields<Country>(
  label: 'Country',
  formType: FormType.string,
  currrentValue: selectedCountry,
  onChanged: (value) => setState(() => selectedCountry = value),
)
```

---

## 2. FormFieldsCheckbox

### Properties
| Property           | Type                                 | Description                                 |
|--------------------|--------------------------------------|---------------------------------------------|
| label              | String                               | The label for the checkbox group.           |
| items              | List<T>                              | List of selectable items.                   |
| onChanged          | ValueChanged<List<T>>                | Callback when selection changes.            |
| initialValue       | List<T>?                             | Initial selected values.                    |
| isRequired         | bool                                 | Whether at least one item is required.      |
| direction          | Axis                                 | Layout direction (vertical/horizontal).     |
| radius             | double                               | Border radius for the group.                |
| borderColor        | Color                                | Border color.                               |
| errorBorderColor   | Color                                | Border color when error.                    |
| activeColor        | Color                                | Color for selected checkboxes.              |
| itemPadding        | EdgeInsets                           | Padding for each item.                      |
| itemMarginTop      | double                               | Top margin for each item.                   |
| itemMarginBottom   | double                               | Bottom margin for each item.                |
| itemMarginHorizontal| double                              | Horizontal margin for each item.            |
| indicatorVerticalAlignment| IndicatorVerticalAlignment      | Vertical alignment of indicator and content.|
| horizontalSideBySide| bool                                | Force compact horizontal side-by-side items.|
| textRightPadding   | double                               | Padding to the right of item text/content.  |
| itemBorderColor    | Color?                               | Border color for each item.                 |
| itemBorderWidth    | double                               | Border width for each item.                 |
| itemBorderRadius   | double                               | Border radius for each item.                |
| itemLabelBuilder   | String Function(T item)?             | Custom label builder for items.             |
| itemBuilder        | Widget Function(T, bool)?            | Custom widget builder for items.            |
| validator          | FormFieldValidator<List<T>>?         | Custom validation logic.                    |

### Properties Example
```dart
FormFieldsCheckbox<String>(
  label: 'Weekdays',
  items: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  initialValue: ['Mon'],
  direction: Axis.vertical,
  horizontalSideBySide: true,
  indicatorVerticalAlignment: IndicatorVerticalAlignment.center,
  textRightPadding: 8,
  itemMarginBottom: 8,
  itemMarginHorizontal: 4,
  onChanged: (values) {},
)
```

### How to Use Each Property (Detailed)
Use the `Properties Example` above as the recommended baseline, then customize only the properties you need.

### Custom Class
```dart
class Hobby {
  final String id;
  final String name;
  Hobby(this.id, this.name);
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Hobby && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

FormFieldsCheckbox<Hobby>(
  label: 'Hobbies',
  items: [Hobby('1', 'Reading'), Hobby('2', 'Music')],
  onChanged: (values) {},
  itemLabelBuilder: (hobby) => hobby.name,
)
```

---

## 3. FormFieldsDropdownMulti

### Properties
| Property           | Type                                 | Description                                 |
|--------------------|--------------------------------------|---------------------------------------------|
| label              | String                               | The label for the dropdown.                 |
| items              | List<T>                              | List of selectable items.                   |
| onChanged          | ValueChanged<List<T>>                | Callback when selection changes.            |
| initialValues      | List<T>?                             | Initial selected values.                    |
| itemLabelBuilder   | String Function(T item)?             | Custom label builder for items.             |
| validator          | String? Function(List<T>?)?          | Custom validation logic.                    |
| isRequired         | bool                                 | Whether at least one item is required.      |
| minSelections      | int?                                 | Minimum number of selections.               |
| maxSelections      | int?                                 | Maximum number of selections.               |
| labelPosition      | LabelPosition                        | Label position.                             |
| borderType         | BorderType                           | Border style.                               |
| radius             | double                               | Border radius.                              |
| borderColor        | Color                                | Border color.                               |
| focusedBorderColor | Color                                | Border color when focused.                  |
| errorBorderColor   | Color                                | Border color when error.                    |
| hintText           | String?                              | Hint text.                                  |
| showItemCount      | bool                                 | Show count of selected items.               |
| chipBackgroundColor| Color?                               | Chip background color.                      |
| chipTextColor      | Color?                               | Chip text color.                            |
| chipDeleteIconColor| Color?                               | Chip delete icon color.                     |
| enableFilter       | bool                                 | Enable search/filter.                       |
| filterHintText     | String?                              | Filter hint text.                           |

### Properties Example
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  initialValues: ['English'],
  isRequired: true,
  minSelections: 1,
  maxSelections: 3,
  enableFilter: true,
  filterHintText: 'Search...',
  showItemCount: true,
  chipBackgroundColor: Colors.teal.shade100,
  chipTextColor: Colors.teal.shade900,
  onChanged: (values) {},
)
```

### How to Use Each Property (Detailed)
Use the `Properties Example` above as the recommended baseline, then customize only the properties you need.

### Custom Class
```dart
class Language {
  final String code;
  final String name;
  Language(this.code, this.name);
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Language && code == other.code;
  @override
  int get hashCode => code.hashCode;
}

FormFieldsDropdownMulti<Language>(
  label: 'Languages',
  items: [Language('en', 'English'), Language('es', 'Spanish')],
  onChanged: (values) {},
  itemLabelBuilder: (lang) => lang.name,
)
```

---

## 4. FormFieldsDropdown

### Properties
| Property           | Type                                 | Description                                 |
|--------------------|--------------------------------------|---------------------------------------------|
| items              | List<T>                              | List of selectable items.                   |
| label              | String                               | The label for the dropdown.                 |
| onChanged          | ValueChanged<T?>?                    | Callback when selection changes.            |
| initialValue       | T?                                   | Initial selected value.                     |
| validator          | String? Function(T?)?                | Custom validation logic.                    |
| isRequired         | bool                                 | Whether selection is required.              |
| itemLabelBuilder   | String Function(T item)?             | Custom label builder for items.             |
| labelPosition      | LabelPosition                        | Label position.                             |
| borderType         | BorderType                           | Border style.                               |
| radius             | double                               | Border radius.                              |
| borderColor        | Color                                | Border color.                               |
| focusedBorderColor | Color                                | Border color when focused.                  |
| errorBorderColor   | Color                                | Border color when error.                    |
| decoration         | InputDecoration?                     | Custom input decoration.                    |
| prefixIcon         | Widget?                              | Icon before the dropdown.                   |
| suffixIcon         | Widget?                              | Icon after the dropdown.                    |
| hintText           | String?                              | Hint text.                                  |
| enabled            | bool                                 | Whether the dropdown is enabled.            |
| enableFilter       | bool                                 | Enable search/filter.                       |
| filterHintText     | String?                              | Filter hint text.                           |

### Properties Example
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: 'USA',
  isRequired: true,
  enableFilter: true,
  filterHintText: 'Search country...',
  borderColor: Colors.indigo,
  focusedBorderColor: Colors.indigo.shade700,
  onChanged: (value) {},
)
```

### How to Use Each Property (Detailed)
Use the `Properties Example` above as the recommended baseline, then customize only the properties you need.

### Custom Class
```dart
class Country {
  final String code;
  final String name;
  Country(this.code, this.name);
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Country && code == other.code;
  @override
  int get hashCode => code.hashCode;
}

FormFieldsDropdown<Country>(
  label: 'Country',
  items: [Country('US', 'United States'), Country('CA', 'Canada')],
  onChanged: (value) {},
  itemLabelBuilder: (country) => country.name,
)
```

---

## 5. FormFieldsRadioButton

### Properties
| Property           | Type                                 | Description                                 |
|--------------------|--------------------------------------|---------------------------------------------|
| label              | String                               | The label for the radio group.              |
| items              | List<T>?                             | List of selectable items.                   |
| sections           | Map<String, List<T>>?                | Sectioned items.                            |
| onChanged          | ValueChanged<T?>                     | Callback when selection changes.            |
| itemLabelBuilder   | String Function(T item)?             | Custom label builder for items.             |
| itemBuilder        | Widget Function(T, bool)?            | Custom widget builder for items.            |
| initialValue       | T?                                   | Initial selected value.                     |
| isRequired         | bool                                 | Whether selection is required.              |
| direction          | Axis                                 | Layout direction (vertical/horizontal).     |
| radius             | double                               | Border radius for the group.                |
| borderColor        | Color                                | Border color.                               |
| errorBorderColor   | Color                                | Border color when error.                    |
| activeColor        | Color                                | Color for selected radio.                   |
| itemPadding        | EdgeInsets                           | Padding for each item.                      |
| sectionSpacing     | double                               | Spacing between sections.                   |
| itemBorderColor    | Color?                               | Border color for each item.                 |
| itemBorderWidth    | double                               | Border width for each item.                 |
| itemBorderRadius   | double                               | Border radius for each item.                |
| textRightPadding   | double                               | Padding to the right of text.               |
| itemTextMarginRight| double                               | Margin to the right of item text.           |
| selectedItemBackgroundColor| Color?                       | Background color for selected item.         |
| selectedItemTextColor| Color?                             | Text color for selected item.               |
| hoverBackgroundColor| Color?                              | Background color on hover.                  |
| itemShadow         | bool                                 | Show shadow for items.                      |
| labelPosition      | LabelPosition                        | Label position.                             |
| containerPadding   | double                               | Padding for the group container.            |
| containerGap       | double                               | Gap between items.                          |
| itemMarginTop      | double                               | Top margin for each item.                   |
| itemMarginBottom   | double                               | Bottom margin for each item.                |
| indicatorVerticalAlignment| IndicatorVerticalAlignment      | Vertical alignment of indicator and content.|
| horizontalSideBySide| bool                                | Force compact horizontal side-by-side items.|
| validator          | FormFieldValidator<T>?               | Custom validation logic.                    |

### Properties Example
```dart
FormFieldsRadioButton<String>(
  label: 'Marital Status',
  items: ['Single', 'Married', 'Divorced'],
  initialValue: 'Single',
  direction: Axis.vertical,
  horizontalSideBySide: true,
  indicatorVerticalAlignment: IndicatorVerticalAlignment.center,
  textRightPadding: 8,
  itemMarginBottom: 8,
  onChanged: (value) {},
)
```

### How to Use Each Property (Detailed)
Use the `Properties Example` above as the recommended baseline, then customize only the properties you need.

### Custom Class
```dart
class Gender {
  final String code;
  final String label;
  Gender(this.code, this.label);
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Gender && code == other.code;
  @override
  int get hashCode => code.hashCode;
}

FormFieldsRadioButton<Gender>(
  label: 'Gender',
  items: [Gender('M', 'Male'), Gender('F', 'Female')],
  onChanged: (value) {},
  itemLabelBuilder: (g) => g.label,
)
```

---

## 6. FormFieldsSelect

### Properties
| Property           | Type                                 | Description                                 |
|--------------------|--------------------------------------|---------------------------------------------|
| formType           | FormType                             | The type of selection widget.               |
| label              | String                               | The label for the select widget.            |
| items              | List<T>                              | List of selectable items.                   |
| initialValue       | T?                                   | Initial value (single select).              |
| initialValues      | List<T>?                             | Initial values (multi select).              |
| onChanged          | ValueChanged<T?>?                    | Callback for single value change.           |
| onMultiChanged     | ValueChanged<List<T>>?               | Callback for multi value change.            |
| itemLabelBuilder   | String Function(T item)?             | Custom label builder for items.             |
| validator          | String? Function(T?)?                | Validator for single value.                 |
| multiValidator     | String? Function(List<T>?)?          | Validator for multi value.                  |
| isRequired         | bool                                 | Whether selection is required.              |
| labelPosition      | LabelPosition                        | Label position.                             |
| borderType         | BorderType                           | Border style.                               |
| radius             | double                               | Border radius.                              |
| borderColor        | Color                                | Border color.                               |
| focusedBorderColor | Color                                | Border color when focused.                  |
| errorBorderColor   | Color                                | Border color when error.                    |
| itemBorderColor    | Color?                               | Border color for each item.                 |
| itemBorderWidth    | double                               | Border width for each item.                 |
| itemBorderRadius   | double                               | Border radius for each item.                |
| itemMarginTop      | double                               | Top margin for each item.                   |
| itemMarginBottom   | double                               | Bottom margin for each item.                |
| itemMarginHorizontal| double                              | Horizontal margin for each item.            |
| enableFilter       | bool                                 | Enable search/filter.                       |
| filterHintText     | String                               | Filter hint text.                           |

### Properties Example
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdownMulti,
  label: 'Skills',
  items: ['Dart', 'Flutter', 'Firebase'],
  initialValues: ['Dart'],
  isRequired: true,
  enableFilter: true,
  filterHintText: 'Search skills...',
  borderColor: Colors.teal,
  itemBorderRadius: 10,
  itemMarginBottom: 6,
  onMultiChanged: (values) {},
)
```

### How to Use Each Property (Detailed)
Use the `Properties Example` above as the recommended baseline, then customize only the properties you need.

### Custom Class
```dart
class Country {
  final String code;
  final String name;
  Country(this.code, this.name);
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Country && code == other.code;
  @override
  int get hashCode => code.hashCode;
}

FormFieldsSelect<Country>(
  formType: FormType.dropdown,
  label: 'Country',
  items: [Country('US', 'United States'), Country('CA', 'Canada')],
  onChanged: (value) {},
  itemLabelBuilder: (country) => country.name,
)
```

---

## Utilities & Advanced Usage

### Enums

#### FormType
| Value           | Description                                 |
|-----------------|---------------------------------------------|
| string          | Standard text input                         |
| phone           | Phone number input                          |
| password        | Password input (obscured)                   |
| email           | Email address input                         |
| date            | Date picker                                 |
| time            | Time picker                                 |
| dateTime        | Date and time picker                        |
| dateTimeRange   | Date range picker                           |
| timeOfDay       | TimeOfDay picker                            |
| dropdown        | Dropdown selection                          |
| dropdownMulti   | Multi-select dropdown                       |
| radioButton     | Radio button group                          |
| checkbox        | Checkbox group                              |

#### Custom Class Example
You can extend or wrap the `FormType` enum for advanced scenarios, such as localization or custom types:
```dart
enum CustomFormType {
  string,
  phone,
  password,
  email,
  customType, // Add your own
}

extension CustomFormTypeExtension on CustomFormType {
  String get label {
    switch (this) {
      case CustomFormType.string:
        return 'Text';
      case CustomFormType.phone:
        return 'Phone';
      case CustomFormType.password:
        return 'Password';
      case CustomFormType.email:
        return 'Email';
      case CustomFormType.customType:
        return 'Custom';
    }
  }
}

FormFields<String>(
  label: CustomFormType.customType.label,
  formType: FormType.string, // Use closest built-in type or handle separately
  onChanged: (v) {},
)
```

#### LabelPosition
| Value         | Description                |
|---------------|---------------------------|
| top           | Label above input         |
| bottom        | Label below input         |
| left          | Label to the left         |
| right         | Label to the right        |
| inBorder      | Floating label            |
| none          | No label                  |

#### BorderType
| Value                | Description                |
|----------------------|---------------------------|
| outlineInputBorder   | Outlined border           |
| underlineInputBorder | Underline border          |
| none                 | No border                 |

---

### Validators

#### Built-in Validators
```dart
// Required field
FormFieldValidators.required('Username')

// Email format
FormFieldValidators.email('Email')

// Phone format
FormFieldValidators.phone('Phone')

// Password length >= 6
FormFieldValidators.password('Password')

// Numeric format
FormFieldValidators.number('Amount')

// Minimum length
FormFieldValidators.minLength('Username', 3)

// Maximum length
FormFieldValidators.maxLength('Code', 8)

// Range (for numbers)
FormFieldValidators.range('Age', 18, 100)

// Pattern matching
FormFieldValidators.pattern('Username', r'^[a-zA-Z0-9_]+$')

// Field matching
FormFieldValidators.match('Password', password)

// Compose multiple
FormFieldValidators.compose([
  FormFieldValidators.required('Field'),
  FormFieldValidators.minLength('Field', 3),
])
```

#### Custom Validator Example
```dart
FormFields<String>(
  label: 'Username',
  isRequired: true,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (value.length < 3) {
      return 'Min 3 chars';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only alphanumeric and _';
    }
    return null;
  },
  onChanged: (value) {},
)
```

---

### Controller

#### FormFieldsController
```dart
final controller = FormFieldsController();

// Set and get form value
controller.form = 'value';
print(controller.form);

// Set and get password obscurity
controller.obscure = false;
print(controller.obscure);

// Use with TextEditingController
controller.setController = 'new text';
print(controller.getController);
```

---

### Nullable and Non-Nullable Usage

All widgets and properties support both nullable and non-nullable types for full null safety.

#### Example: Nullable and Non-Nullable
```dart
// Non-nullable (required field)
FormFields<String>(
  label: 'First Name',
  isRequired: true,
  currrentValue: _firstName, // String, must not be null
  onChanged: (value) => setState(() => _firstName = value ?? ''),
)

// Nullable (optional field)
FormFields<String?>(
  label: 'Middle Name (optional)',
  currrentValue: _middleName, // String? (can be null)
  onChanged: (value) => setState(() => _middleName = value),
)
```

---

## FormType Usage Examples

- **FormType.string**
```dart
FormFields<String>(
  label: 'Username',
  formType: FormType.string,
  onChanged: (v) {},
)
```
- **FormType.phone**
```dart
FormFields<String>(
  label: 'Phone',
  formType: FormType.phone,
  onChanged: (v) {},
)
```
- **FormType.password**
```dart
FormFields<String>(
  label: 'Password',
  formType: FormType.password,
  onChanged: (v) {},
)
```
- **FormType.email**
```dart
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  onChanged: (v) {},
)
```
- **FormType.date**
```dart
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  onChanged: (v) {},
)
```
- **FormType.time**
```dart
FormFields<DateTime>(
  label: 'Meeting Time',
  formType: FormType.time,
  onChanged: (v) {},
)
```
- **FormType.dateTime**
```dart
FormFields<DateTime>(
  label: 'Event DateTime',
  formType: FormType.dateTime,
  onChanged: (v) {},
)
```
- **FormType.dateTimeRange**
```dart
FormFields<DateTimeRange>(
  label: 'Trip Duration',
  formType: FormType.dateTimeRange,
  onChanged: (v) {},
)
```
- **FormType.timeOfDay**
```dart
FormFields<TimeOfDay>(
  label: 'Alarm',
  formType: FormType.timeOfDay,
  onChanged: (v) {},
)
```
- **FormType.dropdown**
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  onChanged: (v) {},
)
```
- **FormType.dropdownMulti**
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  onChanged: (v) {},
)
```
- **FormType.radioButton**
```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  onChanged: (v) {},
)
```
- **FormType.checkbox**
```dart
FormFieldsCheckbox<String>(
  label: 'Hobbies',
  items: ['Reading', 'Music', 'Sports'],
  onChanged: (v) {},
)
```