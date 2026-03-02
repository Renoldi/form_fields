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
- **label** — The label displayed above or beside the checkbox group.
```dart
FormFieldsCheckbox<String>(
  label: 'Select Your Preferences',
  items: ['Option1', 'Option2'],
  onChanged: (values) {},
)
```

- **items** — The list of items to display as checkboxes.
```dart
FormFieldsCheckbox<String>(
  label: 'Days',
  items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
  onChanged: (values) {},
)
```

- **onChanged** — Callback when the selection changes, returns the list of selected values.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  onChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)
```

- **initialValue** — Initial selected values.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  initialValue: ['A', 'B'],
  onChanged: (values) {},
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).
```dart
FormFieldsCheckbox<User>(
  label: 'Users',
  items: users,
  itemLabelBuilder: (user) => '${user.name} (${user.email})',
  onChanged: (values) {},
)
```

- **itemBuilder** — Custom widget builder for individual items.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['Premium', 'Standard', 'Basic'],
  itemBuilder: (item, isSelected) => Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: isSelected ? Colors.blue : Colors.grey,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(item, style: TextStyle(color: Colors.white)),
  ),
  onChanged: (values) {},
)
```

- **isRequired** — Whether at least one checkbox must be selected.
```dart
FormFieldsCheckbox<String>(
  label: 'Required Selection',
  items: ['Yes', 'No'],
  isRequired: true,
  onChanged: (values) {},
)
```

- **direction** — Layout direction: vertical or horizontal.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  direction: Axis.horizontal,
  onChanged: (values) {},
)
```

- **horizontalSideBySide** — Force compact horizontal side-by-side layout with wrapping.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['Option 1', 'Option 2', 'Option 3'],
  horizontalSideBySide: true,
  onChanged: (values) {},
)
```

- **indicatorVerticalAlignment** — Vertical alignment of the checkbox indicator relative to the text (top, center, bottom).
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['Multi-line\nOption 1', 'Multi-line\nOption 2'],
  indicatorVerticalAlignment: IndicatorVerticalAlignment.top,
  onChanged: (values) {},
)
```

- **textRightPadding** — Padding to the right of the text for each item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  textRightPadding: 12,
  onChanged: (values) {},
)
```

- **radius** — Border radius for the group container.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  radius: 16,
  onChanged: (values) {},
)
```

- **borderColor** — Border color for the group container.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  borderColor: Colors.teal,
  onChanged: (values) {},
)
```

- **errorBorderColor** — Border color when validation fails.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  isRequired: true,
  errorBorderColor: Colors.red,
  onChanged: (values) {},
)
```

- **activeColor** — Color of the checkbox when selected.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  activeColor: Colors.green,
  onChanged: (values) {},
)
```

- **itemPadding** — Padding for each checkbox item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemPadding: EdgeInsets.all(12),
  onChanged: (values) {},
)
```

- **itemBorderColor** — Border color for each individual item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: Colors.grey,
  onChanged: (values) {},
)
```

- **itemBorderWidth** — Border width for each item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderWidth: 2,
  onChanged: (values) {},
)
```

- **itemBorderRadius** — Border radius for each item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderRadius: 8,
  onChanged: (values) {},
)
```

- **selectedItemBackgroundColor** — Background color for selected items.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemBackgroundColor: Colors.blue.shade100,
  onChanged: (values) {},
)
```

- **selectedItemTextColor** — Text color for selected items.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemTextColor: Colors.blue,
  onChanged: (values) {},
)
```

- **hoverBackgroundColor** — Background color when hovering over items.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  hoverBackgroundColor: Colors.grey.shade200,
  onChanged: (values) {},
)
```

- **itemShadow** — Whether to show shadow for items.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemShadow: true,
  onChanged: (values) {},
)
```

- **labelPosition** — Position of the label (top, left, right, etc.).
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  labelPosition: LabelPosition.left,
  onChanged: (values) {},
)
```

- **containerPadding** — Padding for the entire checkbox group container.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  containerPadding: 16,
  onChanged: (values) {},
)
```

- **containerGap** — Gap between items in the container.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  containerGap: 12,
  onChanged: (values) {},
)
```

- **itemMarginTop** — Top margin for each item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginTop: 4,
  onChanged: (values) {},
)
```

- **itemMarginBottom** — Bottom margin for each item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginBottom: 8,
  onChanged: (values) {},
)
```

- **itemMarginHorizontal** — Horizontal margin for each item.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginHorizontal: 6,
  onChanged: (values) {},
)
```

- **validator** — Custom validation logic.
```dart
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  validator: (values) {
    if (values == null || values.length < 2) {
      return 'Please select at least 2 options';
    }
    return null;
  },
  onChanged: (values) {},
)
```

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
- **label** — The label displayed for the dropdown multi-select widget.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Select Languages',
  items: ['English', 'Spanish', 'French'],
  onChanged: (values) {},
)
```

- **items** — The list of items available for selection.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German', 'Italian'],
  onChanged: (values) {},
)
```

- **onChanged** — Callback when the selection changes, returns the list of selected values.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  onChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)
```

- **initialValues** — Initial selected values.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  initialValues: ['English', 'Spanish'],
  onChanged: (values) {},
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).
```dart
FormFieldsDropdownMulti<Language>(
  label: 'Languages',
  items: languages,
  itemLabelBuilder: (lang) => '${lang.name} (${lang.code})',
  onChanged: (values) {},
)
```

- **validator** — Custom validation logic.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  validator: (values) {
    if (values == null || values.isEmpty) {
      return 'Please select at least one language';
    }
    return null;
  },
  onChanged: (values) {},
)
```

- **isRequired** — Whether at least one item must be selected.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  isRequired: true,
  onChanged: (values) {},
)
```

- **minSelections** — Minimum number of selections required.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German'],
  minSelections: 2,
  onChanged: (values) {},
)
```

- **maxSelections** — Maximum number of selections allowed.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German'],
  maxSelections: 3,
  onChanged: (values) {},
)
```

- **labelPosition** — Position of the label (top, left, right, etc.).
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  labelPosition: LabelPosition.left,
  onChanged: (values) {},
)
```

- **borderType** — Border style for the dropdown.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  borderType: BorderType.underlineInputBorder,
  onChanged: (values) {},
)
```

- **radius** — Border radius for the dropdown field.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  radius: 12,
  onChanged: (values) {},
)
```

- **borderColor** — Border color for the dropdown.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  borderColor: Colors.teal,
  onChanged: (values) {},
)
```

- **focusedBorderColor** — Border color when the dropdown is focused.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  focusedBorderColor: Colors.teal.shade700,
  onChanged: (values) {},
)
```

- **errorBorderColor** — Border color when validation fails.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  isRequired: true,
  errorBorderColor: Colors.red,
  onChanged: (values) {},
)
```

- **hintText** — Hint text displayed when no items are selected.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  hintText: 'Select your languages',
  onChanged: (values) {},
)
```

- **showItemCount** — Show the count of selected items.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  showItemCount: true,
  onChanged: (values) {},
)
```

- **chipBackgroundColor** — Background color for selected item chips.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipBackgroundColor: Colors.blue.shade100,
  onChanged: (values) {},
)
```

- **chipTextColor** — Text color for selected item chips.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipTextColor: Colors.blue.shade900,
  onChanged: (values) {},
)
```

- **chipDeleteIconColor** — Delete icon color for selected item chips.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipDeleteIconColor: Colors.red,
  onChanged: (values) {},
)
```

- **enableFilter** — Enable search/filter functionality.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German', 'Italian'],
  enableFilter: true,
  onChanged: (values) {},
)
```

- **filterHintText** — Hint text for the filter/search field.
```dart
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  enableFilter: true,
  filterHintText: 'Search languages...',
  onChanged: (values) {},
)
```

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
- **items** — The list of items available for selection.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Australia'],
  onChanged: (value) {},
)
```

- **label** — The label displayed for the dropdown widget.
```dart
FormFieldsDropdown<String>(
  label: 'Select Your Country',
  items: ['USA', 'Canada'],
  onChanged: (value) {},
)
```

- **onChanged** — Callback when the selection changes, returns the selected value.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  onChanged: (selectedValue) {
    print('Selected: $selectedValue');
  },
)
```

- **initialValue** — Initial selected value.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: 'USA',
  onChanged: (value) {},
)
```

- **validator** — Custom validation logic.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  validator: (value) {
    if (value == null) {
      return 'Please select a country';
    }
    return null;
  },
  onChanged: (value) {},
)
```

- **isRequired** — Whether selection is required.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  isRequired: true,
  onChanged: (value) {},
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).
```dart
FormFieldsDropdown<Country>(
  label: 'Country',
  items: countries,
  itemLabelBuilder: (country) => '${country.name} (${country.code})',
  onChanged: (value) {},
)
```

- **labelPosition** — Position of the label (top, left, right, etc.).
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  labelPosition: LabelPosition.left,
  onChanged: (value) {},
)
```

- **borderType** — Border style for the dropdown.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  borderType: BorderType.underlineInputBorder,
  onChanged: (value) {},
)
```

- **radius** — Border radius for the dropdown field.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  radius: 12,
  onChanged: (value) {},
)
```

- **borderColor** — Border color for the dropdown.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  borderColor: Colors.indigo,
  onChanged: (value) {},
)
```

- **focusedBorderColor** — Border color when the dropdown is focused.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  focusedBorderColor: Colors.indigo.shade700,
  onChanged: (value) {},
)
```

- **errorBorderColor** — Border color when validation fails.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  isRequired: true,
  errorBorderColor: Colors.red,
  onChanged: (value) {},
)
```

- **decoration** — Custom input decoration.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  decoration: InputDecoration(
    hintText: 'Choose a country',
    filled: true,
    fillColor: Colors.grey.shade100,
  ),
  onChanged: (value) {},
)
```

- **prefixIcon** — Icon displayed before the dropdown field.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  prefixIcon: Icon(Icons.public),
  onChanged: (value) {},
)
```

- **suffixIcon** — Icon displayed after the dropdown field.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  suffixIcon: Icon(Icons.arrow_drop_down),
  onChanged: (value) {},
)
```

- **hintText** — Hint text displayed when no item is selected.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  hintText: 'Select your country',
  onChanged: (value) {},
)
```

- **enabled** — Whether the dropdown is enabled or disabled.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  enabled: false,
  onChanged: (value) {},
)
```

- **enableFilter** — Enable search/filter functionality.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Australia', 'Germany'],
  enableFilter: true,
  onChanged: (value) {},
)
```

- **filterHintText** — Hint text for the filter/search field.
```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  enableFilter: true,
  filterHintText: 'Search country...',
  onChanged: (value) {},
)
```

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
- **label** — The label displayed for the radio button group.
```dart
FormFieldsRadioButton<String>(
  label: 'Marital Status',
  items: ['Single', 'Married', 'Divorced'],
  onChanged: (value) {},
)
```

- **items** — The list of items to display as radio buttons.
```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  onChanged: (value) {},
)
```

- **sections** — Map of sectioned items for grouped radio buttons.
```dart
FormFieldsRadioButton<String>(
  label: 'Vehicle Type',
  sections: {
    'Two Wheelers': ['Bike', 'Scooter'],
    'Four Wheelers': ['Car', 'SUV', 'Truck'],
  },
  onChanged: (value) {},
)
```

- **onChanged** — Callback when the selection changes, returns the selected value.
```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female'],
  onChanged: (selectedValue) {
    print('Selected: $selectedValue');
  },
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).
```dart
FormFieldsRadioButton<Gender>(
  label: 'Gender',
  items: genders,
  itemLabelBuilder: (gender) => gender.label,
  onChanged: (value) {},
)
```

- **itemBuilder** — Custom widget builder for individual items.
```dart
FormFieldsRadioButton<String>(
  label: 'Plan',
  items: ['Basic', 'Premium', 'Enterprise'],
  itemBuilder: (item, isSelected) => Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isSelected ? Colors.blue : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(item, style: TextStyle(
      color: isSelected ? Colors.white : Colors.black,
    )),
  ),
  onChanged: (value) {},
)
```

- **initialValue** — Initial selected value.
```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: 'Male',
  onChanged: (value) {},
)
```

- **isRequired** — Whether a selection is required.
```dart
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female'],
  isRequired: true,
  onChanged: (value) {},
)
```

- **direction** — Layout direction: vertical or horizontal.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  direction: Axis.horizontal,
  onChanged: (value) {},
)
```

- **horizontalSideBySide** — Force compact horizontal side-by-side layout with wrapping.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['Option 1', 'Option 2', 'Option 3'],
  horizontalSideBySide: true,
  onChanged: (value) {},
)
```

- **indicatorVerticalAlignment** — Vertical alignment of the radio indicator relative to the text (top, center, bottom).
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['Multi-line\nOption 1', 'Multi-line\nOption 2'],
  indicatorVerticalAlignment: IndicatorVerticalAlignment.top,
  onChanged: (value) {},
)
```

- **textRightPadding** — Padding to the right of the text for each item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  textRightPadding: 12,
  onChanged: (value) {},
)
```

- **radius** — Border radius for the group container.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  radius: 16,
  onChanged: (value) {},
)
```

- **borderColor** — Border color for the group container.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  borderColor: Colors.teal,
  onChanged: (value) {},
)
```

- **errorBorderColor** — Border color when validation fails.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  isRequired: true,
  errorBorderColor: Colors.red,
  onChanged: (value) {},
)
```

- **activeColor** — Color of the radio button when selected.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  activeColor: Colors.green,
  onChanged: (value) {},
)
```

- **itemPadding** — Padding for each radio button item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemPadding: EdgeInsets.all(12),
  onChanged: (value) {},
)
```

- **sectionSpacing** — Spacing between sections (when using sections).
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  sections: {
    'Group 1': ['A', 'B'],
    'Group 2': ['C', 'D'],
  },
  sectionSpacing: 16,
  onChanged: (value) {},
)
```

- **itemBorderColor** — Border color for each individual item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: Colors.grey,
  onChanged: (value) {},
)
```

- **itemBorderWidth** — Border width for each item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderWidth: 2,
  onChanged: (value) {},
)
```

- **itemBorderRadius** — Border radius for each item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderRadius: 8,
  onChanged: (value) {},
)
```

- **itemTextMarginRight** — Margin to the right of item text.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemTextMarginRight: 8,
  onChanged: (value) {},
)
```

- **selectedItemBackgroundColor** — Background color for selected item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemBackgroundColor: Colors.blue.shade100,
  onChanged: (value) {},
)
```

- **selectedItemTextColor** — Text color for selected item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemTextColor: Colors.blue,
  onChanged: (value) {},
)
```

- **hoverBackgroundColor** — Background color when hovering over items.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  hoverBackgroundColor: Colors.grey.shade200,
  onChanged: (value) {},
)
```

- **itemShadow** — Whether to show shadow for items.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemShadow: true,
  onChanged: (value) {},
)
```

- **labelPosition** — Position of the label (top, left, right, etc.).
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  labelPosition: LabelPosition.left,
  onChanged: (value) {},
)
```

- **containerPadding** — Padding for the entire radio group container.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  containerPadding: 16,
  onChanged: (value) {},
)
```

- **containerGap** — Gap between items in the container.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  containerGap: 12,
  onChanged: (value) {},
)
```

- **itemMarginTop** — Top margin for each item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginTop: 4,
  onChanged: (value) {},
)
```

- **itemMarginBottom** — Bottom margin for each item.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginBottom: 8,
  onChanged: (value) {},
)
```

- **validator** — Custom validation logic.
```dart
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  validator: (value) {
    if (value == null) {
      return 'Please select an option';
    }
    return null;
  },
  onChanged: (value) {},
)
```

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
- **formType** — The type of selection widget to display (dropdown, dropdownMulti, radioButton, checkbox).
```dart
// Single select dropdown
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  onChanged: (value) {},
)

// Multi-select dropdown
FormFieldsSelect<String>(
  formType: FormType.dropdownMulti,
  label: 'Skills',
  items: ['Dart', 'Flutter', 'Firebase'],
  onMultiChanged: (values) {},
)

// Radio button group
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Gender',
  items: ['Male', 'Female'],
  onChanged: (value) {},
)

// Checkbox group
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Interests',
  items: ['Sports', 'Music', 'Reading'],
  onMultiChanged: (values) {},
)
```

- **label** — The label displayed for the select widget.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Select Your Country',
  items: ['USA', 'Canada'],
  onChanged: (value) {},
)
```

- **items** — The list of items available for selection.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Australia'],
  onChanged: (value) {},
)
```

- **initialValue** — Initial value for single select (dropdown, radioButton).
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: 'USA',
  onChanged: (value) {},
)
```

- **initialValues** — Initial values for multi-select (dropdownMulti, checkbox).
```dart
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Interests',
  items: ['Sports', 'Music', 'Reading'],
  initialValues: ['Sports', 'Music'],
  onMultiChanged: (values) {},
)
```

- **onChanged** — Callback for single value changes (dropdown, radioButton).
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  onChanged: (selectedValue) {
    print('Selected: $selectedValue');
  },
)
```

- **onMultiChanged** — Callback for multi-value changes (dropdownMulti, checkbox).
```dart
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Interests',
  items: ['Sports', 'Music', 'Reading'],
  onMultiChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).
```dart
FormFieldsSelect<Country>(
  formType: FormType.dropdown,
  label: 'Country',
  items: countries,
  itemLabelBuilder: (country) => '${country.name} (${country.code})',
  onChanged: (value) {},
)
```

- **validator** — Validator for single value selections.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  validator: (value) {
    if (value == null) {
      return 'Please select a country';
    }
    return null;
  },
  onChanged: (value) {},
)
```

- **multiValidator** — Validator for multi-value selections.
```dart
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Skills',
  items: ['Dart', 'Flutter', 'Firebase'],
  multiValidator: (values) {
    if (values == null || values.length < 2) {
      return 'Please select at least 2 skills';
    }
    return null;
  },
  onMultiChanged: (values) {},
)
```

- **isRequired** — Whether selection is required.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  isRequired: true,
  onChanged: (value) {},
)
```

- **labelPosition** — Position of the label (top, left, right, etc.).
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  labelPosition: LabelPosition.left,
  onChanged: (value) {},
)
```

- **borderType** — Border style for the widget.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  borderType: BorderType.underlineInputBorder,
  onChanged: (value) {},
)
```

- **radius** — Border radius.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  radius: 12,
  onChanged: (value) {},
)
```

- **borderColor** — Border color.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  borderColor: Colors.teal,
  onChanged: (value) {},
)
```

- **focusedBorderColor** — Border color when focused.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  focusedBorderColor: Colors.teal.shade700,
  onChanged: (value) {},
)
```

- **errorBorderColor** — Border color when validation fails.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  isRequired: true,
  errorBorderColor: Colors.red,
  onChanged: (value) {},
)
```

- **itemBorderColor** — Border color for each item (applicable to radioButton and checkbox).
```dart
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: Colors.grey,
  onChanged: (value) {},
)
```

- **itemBorderWidth** — Border width for each item.
```dart
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderWidth: 2,
  onChanged: (value) {},
)
```

- **itemBorderRadius** — Border radius for each item.
```dart
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderRadius: 10,
  onChanged: (value) {},
)
```

- **itemMarginTop** — Top margin for each item.
```dart
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginTop: 4,
  onChanged: (value) {},
)
```

- **itemMarginBottom** — Bottom margin for each item.
```dart
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginBottom: 6,
  onChanged: (value) {},
)
```

- **itemMarginHorizontal** — Horizontal margin for each item.
```dart
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemMarginHorizontal: 8,
  onChanged: (value) {},
)
```

- **enableFilter** — Enable search/filter functionality.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Australia', 'Germany'],
  enableFilter: true,
  onChanged: (value) {},
)
```

- **filterHintText** — Hint text for the filter/search field.
```dart
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  enableFilter: true,
  filterHintText: 'Search country...',
  onChanged: (value) {},
)
```

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