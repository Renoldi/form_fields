# 🏁 Navigation

## 🚀 FormFieldsAutocomplete (Async Autocomplete Field)

Easily add autocomplete text fields with async API search, custom result parsing, and full UI customization.

### Features

- Async search from any API endpoint (with token support)
- Custom query param and token header
- Custom result parsing and display
- Works with FormFields, LabelPosition, BorderType
- Custom option builder for dropdown list

### Example Usage

```dart
FormFieldsAutocomplete<String>(
  fieldLabel: 'City',
  apiUrl: 'https://api.example.com/cities',
  onItemSelected: (city) => print(city),
)
```

### Custom Class Example

```dart
class Country {
  final String code;
  final String name;
  Country(this.code, this.name);
  factory Country.fromJson(Map<String, dynamic> json) => Country(json['code'], json['name']);
  @override
  String toString() => name;
}

FormFieldsAutocomplete<Country>(
  fieldLabel: 'Country',
  apiUrl: 'https://api.example.com/countries',
  onItemSelected: (country) => print(country?.name),
  parseResults: (data) => (data['results'] as List).map((e) => Country.fromJson(e)).toList(),
  itemSelectedBuilder: (country) => country.name,
  itemBuilder: (country, selected) => ListTile(
    title: Text(country.name),
    subtitle: Text(country.code),
    selected: selected,
  ),
  inputDecoration: InputDecoration(hintText: 'Type to search country...'),
  labelPlacement: LabelPosition.top,
  borderStyle: BorderType.outlineInputBorder,
)
```

### Properties

| Property            | Type                                    | Description                                       |
| ------------------- | --------------------------------------- | ------------------------------------------------- |
| fieldLabel          | String                                  | The label for the autocomplete field.             |
| apiUrl              | String                                  | The API endpoint to fetch options.                |
| apiToken            | String?                                 | Optional API token for authentication.            |
| searchKey           | String                                  | Query parameter for search (default: 'q').        |
| tokenHeaderName     | String                                  | Header name for token (default: 'Authorization'). |
| onItemSelected      | void Function(T?)                       | Callback when an item is selected.                |
| parseResults        | List<T> Function(dynamic data)?         | Custom function to parse API results.             |
| itemSelectedBuilder | String Function(T)?                     | Returns string label for selected option.         |
| itemBuilder         | Widget Function(T item, bool selected)? | Custom widget for dropdown options.               |
| inputDecoration     | InputDecoration?                        | Custom input decoration.                          |
| labelPlacement      | LabelPosition                           | Label position (top, left, etc.).                 |
| borderStyle         | BorderType                              | Border style (outline, underline, none).          |
| trailingIcon        | Widget?                                 | Custom trailing icon.                             |
| hideTrailingIcon    | bool                                    | Hide the trailing icon (default: false).          |

- [Properties](#properties) — All configurable options for FormFields.
- [How to Use Each Property](#how-to-use-each-property-detailed) — Code examples for every property.
- [Properties](#properties-1)
- [Properties Example](#properties-example)
- [How to Use Each Property](#how-to-use-each-property-detailed)
- [Properties](#properties-2)
- [Properties Example](#properties-example-1)
- [How to Use Each Property](#how-to-use-each-property-detailed)
- [Properties](#properties-3)
- [Properties Example](#properties-example-2)
- [How to Use Each Property](#how-to-use-each-property-detailed)
- [Properties](#properties-4)
- [Properties Example](#properties-example-3)
- [How to Use Each Property](#how-to-use-each-property-detailed)
- [Properties](#properties-5)
- [Properties Example](#properties-example-4)
- [How to Use Each Property](#how-to-use-each-property-detailed)
- [Utilities & Advanced Usage](#utilities--advanced-usage) — Enums, validators, controller, and null-safety patterns.
- [Localization & Language Control](#localization--language-control) — How to manually set and switch languages at runtime.
- [FormType Usage Examples](#formtype-usage-examples) — Quick examples for all FormType values.

## 1. FormFields

### Properties

| Property                   | Type                        | Description                                                                                      |
| -------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------ |
| label                      | String                      | The label to display above or beside the field.                                                  |
| formType                   | FormType                    | The type of input (string, email, phone, etc.).                                                  |
| isRequired                 | bool                        | Whether the field is required.                                                                   |
| currrentValue              | T / T?                      | The current value of the field.                                                                  |
| onChanged                  | ValueChanged<T?>            | Callback when the value changes.                                                                 |
| validator                  | FormFieldValidator<String>? | Custom validation logic.                                                                         |
| labelPosition              | LabelPosition               | Position of the label (top, left, etc.).                                                         |
| borderType                 | BorderType                  | Border style (outline, underline, none).                                                         |
| radius                     | double                      | Border radius.                                                                                   |
| prefixIcon                 | Widget?                     | Icon before the input.                                                                           |
| suffixIcon                 | Widget?                     | Icon after the input.                                                                            |
| inputDecoration            | InputDecoration?            | Custom input decoration.                                                                         |
| multiLine                  | int                         | Number of visible lines for text input.                                                          |
| verificationLength         | int                         | Number of digits for verification input (default: 6).                                            |
| verificationHidden         | bool                        | Hide verification digits with visibility toggle.                                                 |
| locale                     | String?                     | Custom locale string ('id', 'en' or 'id_ID', 'en_US') for validation text and date/time pickers. |
| stripSeparators            | bool                        | Format numbers with separators.                                                                  |
| customFormat               | String?                     | Custom date/time format.                                                                         |
| firstDate                  | DateTime?                   | Earliest selectable date.                                                                        |
| lastDate                   | DateTime?                   | Latest selectable date.                                                                          |
| autovalidateMode           | AutovalidateMode            | When to show validation errors.                                                                  |
| minLengthPassword          | int                         | Minimum length for password field.                                                               |
| customPasswordValidator    | FormFieldValidator<String>? | Custom password validator.                                                                       |
| minLengthPasswordErrorText | String?                     | Error text for minimum password length.                                                          |

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

- **verificationLength**

```dart
FormFields<String>(
  formType: FormType.verification,
  verificationLength: 6,
  onChanged: (v) {},
)
```

- **verificationHidden**

```dart
FormFields<String>(
  formType: FormType.verification,
  verificationLength: 6,
  verificationHidden: true,
  onChanged: (v) {},
)
```

- **stripSeparators**

```dart
FormFields<int>(stripSeparators: true, onChanged: (v) {})
```

- **locale**

```dart
FormFields<DateTime>(locale: 'en_US', onChanged: (v) {})
```

When not provided, validation text and picker dialogs follow the selected app locale.

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
  }

FormFields<Country>(
label: 'Country',
formType: FormType.string,
currrentValue: selectedCountry,

## 2. FormFieldsCheckbox

### Properties

| Property                   | Type                         | Description                                  |
| -------------------------- | ---------------------------- | -------------------------------------------- |
| label                      | String                       | The label for the checkbox group.            |
| items                      | List<T>                      | List of selectable items.                    |
| onChanged                  | ValueChanged<List<T>>        | Callback when selection changes.             |
| initialValue               | List<T>?                     | Initial selected values.                     |
| isRequired                 | bool                         | Whether at least one item is required.       |
| direction                  | Axis                         | Layout direction (vertical/horizontal).      |
| radius                     | double                       | Border radius for the group.                 |
| borderColor                | Color                        | Border color.                                |
| errorBorderColor           | Color                        | Border color when error.                     |
| activeColor                | Color                        | Color for selected checkboxes.               |
| itemPadding                | EdgeInsets                   | Padding for each item.                       |
| itemMarginTop              | double                       | Top margin for each item.                    |
| itemMarginBottom           | double                       | Bottom margin for each item.                 |
| itemMarginHorizontal       | double                       | Horizontal margin for each item.             |
| indicatorVerticalAlignment | IndicatorVerticalAlignment   | Vertical alignment of indicator and content. |
| horizontalSideBySide       | bool                         | Force compact horizontal side-by-side items. |
| textRightPadding           | double                       | Padding to the right of item text/content.   |
| itemBorderColor            | Color?                       | Border color for each item.                  |
| itemBorderWidth            | double                       | Border width for each item.                  |
| itemBorderRadius           | double                       | Border radius for each item.                 |
| itemLabelBuilder           | String Function(T item)?     | Custom label builder for items.              |
| itemBuilder                | Widget Function(T, bool)?    | Custom widget builder for items.             |
| validator                  | FormFieldValidator<List<T>>? | Custom validation logic.                     |

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

FormFieldsCheckbox<String>(
label: 'Select Your Preferences',
items: ['Option1', 'Option2'],
onChanged: (values) {},
)

````

- **items** — The list of items to display as checkboxes.

```dart
// Non-nullable type
FormFieldsCheckbox<String>(
  label: 'Days',
  items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
  onChanged: (values) {},
)

// Nullable type (allows null items)
FormFieldsCheckbox<String?>(
  label: 'Days',
  items: ['Monday', 'Tuesday', null, 'Thursday', 'Friday'],
  onChanged: (values) {},
)
````

- **onChanged** — Callback when the selection changes, returns the list of selected values.

```dart
// Non-nullable type
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  onChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)

// Nullable type
FormFieldsCheckbox<String?>(
  label: 'Options',
  items: ['A', null, 'C'],
  onChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)
```

- **initialValue** — Initial selected values.

```dart
// With initial values
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  initialValue: ['A', 'B'],
  onChanged: (values) {},
)

// Nullable: No items selected initially
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  initialValue: null,
  onChanged: (values) {},
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).

```dart
// With custom label builder
FormFieldsCheckbox<User>(
  label: 'Users',
  items: users,
  itemLabelBuilder: (user) => '${user.name} (${user.email})',
  onChanged: (values) {},
)

// Nullable: Uses toString() by default
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemLabelBuilder: null,
  onChanged: (values) {},
)

// With nullable type
FormFieldsCheckbox<String?>(
  label: 'Options',
  items: ['A', 'B', null, 'D'],
  itemLabelBuilder: (item) => item ?? 'None',
  onChanged: (values) {},
)
```

- **itemBuilder** — Custom widget builder for individual items.

```dart
// With custom item builder
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

// Nullable: Uses default checkbox rendering
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['Premium', 'Standard', 'Basic'],
  itemBuilder: null,
  onChanged: (values) {},
)

// With nullable type
FormFieldsCheckbox<String?>(
  label: 'Options',
  items: ['Premium', null, 'Basic'],
  itemBuilder: (item, isSelected) => Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: isSelected ? Colors.blue : Colors.grey,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(item ?? 'Not specified', style: TextStyle(color: Colors.white)),
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
// With custom border color
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: Colors.grey,
  onChanged: (values) {},
)

// Nullable: No border color applied
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: null,
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
// With custom background color
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemBackgroundColor: Colors.blue.shade100,
  onChanged: (values) {},
)

// Nullable: No background color change on selection
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemBackgroundColor: null,
  onChanged: (values) {},
)
```

- **selectedItemTextColor** — Text color for selected items.

```dart
// With custom text color
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemTextColor: Colors.blue,
  onChanged: (values) {},
)

// Nullable: No text color change on selection
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemTextColor: null,
  onChanged: (values) {},
)
```

- **hoverBackgroundColor** — Background color when hovering over items.

```dart
// With hover effect
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  hoverBackgroundColor: Colors.grey.shade200,
  onChanged: (values) {},
)

// Nullable: No hover background color
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  hoverBackgroundColor: null,
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

- **labelPosition** — Position of the label relative to the checkbox group (top, bottom, left, right, inBorder, none).

All supported label positions:

- `LabelPosition.top` — Label positioned above the checkboxes
- `LabelPosition.bottom` — Label positioned below the checkboxes
- `LabelPosition.left` — Label positioned to the left of the checkboxes
- `LabelPosition.right` — Label positioned to the right of the checkboxes
- `LabelPosition.inBorder` — Label hidden inside the border
- `LabelPosition.none` — Label completely hidden

```dart
// Label at the top (default)
FormFieldsCheckbox<String>(
  label: 'Preferences',
  items: ['Option 1', 'Option 2'],
  labelPosition: LabelPosition.top,
  onChanged: (values) {},
)

// Label at the bottom
FormFieldsCheckbox<String>(
  label: 'Features',
  items: ['Feature A', 'Feature B'],
  labelPosition: LabelPosition.bottom,
  onChanged: (values) {},
)

// Label on the left
FormFieldsCheckbox<String>(
  label: 'Selections',
  items: ['Item 1', 'Item 2'],
  labelPosition: LabelPosition.left,
  onChanged: (values) {},
)

// Label on the right
FormFieldsCheckbox<String>(
  label: 'Choices',
  items: ['Choice A', 'Choice B'],
  labelPosition: LabelPosition.right,
  onChanged: (values) {},
)

// Label hidden in border
FormFieldsCheckbox<String>(
  label: 'Permissions',
  items: ['Read', 'Write', 'Delete'],
  labelPosition: LabelPosition.inBorder,
  onChanged: (values) {},
)

// Label completely hidden
FormFieldsCheckbox<String>(
  label: 'Hidden Label',
  items: ['Option 1', 'Option 2'],
  labelPosition: LabelPosition.none,
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
// With validation
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

// Nullable: No custom validation
FormFieldsCheckbox<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  validator: null,
  onChanged: (values) {},
)

// With nullable type
FormFieldsCheckbox<String?>(
  label: 'Options',
  items: ['A', null, 'C'],
  validator: (values) {
    if (values == null || values.isEmpty) {
      return 'Please select at least one option';
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

| Property            | Type                        | Description                            |
| ------------------- | --------------------------- | -------------------------------------- |
| label               | String                      | The label for the dropdown.            |
| items               | List<T>                     | List of selectable items.              |
| onChanged           | ValueChanged<List<T>>       | Callback when selection changes.       |
| initialValues       | List<T>?                    | Initial selected values.               |
| itemLabelBuilder    | String Function(T item)?    | Custom label builder for items.        |
| validator           | String? Function(List<T>?)? | Custom validation logic.               |
| isRequired          | bool                        | Whether at least one item is required. |
| minSelections       | int?                        | Minimum number of selections.          |
| maxSelections       | int?                        | Maximum number of selections.          |
| labelPosition       | LabelPosition               | Label position.                        |
| borderType          | BorderType                  | Border style.                          |
| radius              | double                      | Border radius.                         |
| borderColor         | Color                       | Border color.                          |
| focusedBorderColor  | Color                       | Border color when focused.             |
| errorBorderColor    | Color                       | Border color when error.               |
| hintText            | String?                     | Hint text.                             |
| showItemCount       | bool                        | Show count of selected items.          |
| chipBackgroundColor | Color?                      | Chip background color.                 |
| chipTextColor       | Color?                      | Chip text color.                       |
| chipDeleteIconColor | Color?                      | Chip delete icon color.                |
| enableFilter        | bool                        | Enable search/filter.                  |
| filterHintText      | String?                     | Filter hint text.                      |

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
// Non-nullable type
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German', 'Italian'],
  onChanged: (values) {},
)

// Nullable type (allows null items)
FormFieldsDropdownMulti<String?>(
  label: 'Languages',
  items: ['English', 'Spanish', null, 'German', 'Italian'],
  onChanged: (values) {},
)
```

- **onChanged** — Callback when the selection changes, returns the list of selected values.

```dart
// Non-nullable type
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  onChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)

// Nullable type
FormFieldsDropdownMulti<String?>(
  label: 'Languages',
  items: ['English', null, 'Spanish'],
  onChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)
```

- **initialValues** — Initial selected values.

```dart
// With initial values
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  initialValues: ['English', 'Spanish'],
  onChanged: (values) {},
)

// Nullable: No items selected initially
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  initialValues: null,
  onChanged: (values) {},
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).

```dart
// With custom label builder
FormFieldsDropdownMulti<Language>(
  label: 'Languages',
  items: languages,
  itemLabelBuilder: (lang) => '${lang.name} (${lang.code})',
  onChanged: (values) {},
)

// Nullable: Uses toString() by default
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  itemLabelBuilder: null,
  onChanged: (values) {},
)

// With nullable type
FormFieldsDropdownMulti<String?>(
  label: 'Languages',
  items: ['English', null, 'Spanish'],
  itemLabelBuilder: (item) => item ?? 'Unspecified',
  onChanged: (values) {},
)
```

- **validator** — Custom validation logic.

```dart
// With validation
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

// Nullable: No custom validation
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  validator: null,
  onChanged: (values) {},
)

// With nullable type
FormFieldsDropdownMulti<String?>(
  label: 'Languages',
  items: ['English', null, 'Spanish'],
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
// With minimum selections
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German'],
  minSelections: 2,
  onChanged: (values) {},
)

// Nullable: No minimum requirement
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  minSelections: null,
  onChanged: (values) {},
)
```

- **maxSelections** — Maximum number of selections allowed.

```dart
// With maximum selections
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French', 'German'],
  maxSelections: 3,
  onChanged: (values) {},
)

// Nullable: No maximum limit
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  maxSelections: null,
  onChanged: (values) {},
)
```

- **labelPosition** — Position of the label relative to the dropdown (top, bottom, left, right, inBorder, none).

All supported label positions:

- `LabelPosition.top` — Label positioned above the dropdown
- `LabelPosition.bottom` — Label positioned below the dropdown
- `LabelPosition.left` — Label positioned to the left of the dropdown
- `LabelPosition.right` — Label positioned to the right of the dropdown
- `LabelPosition.inBorder` — Label hidden inside the border
- `LabelPosition.none` — Label completely hidden

```dart
// Label at the top (default)
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  labelPosition: LabelPosition.top,
  onChanged: (values) {},
)

// Label at the bottom
FormFieldsDropdownMulti<String>(
  label: 'Skills',
  items: ['JavaScript', 'Dart', 'Python'],
  labelPosition: LabelPosition.bottom,
  onChanged: (values) {},
)

// Label on the left
FormFieldsDropdownMulti<String>(
  label: 'Interests',
  items: ['Music', 'Sports', 'Reading'],
  labelPosition: LabelPosition.left,
  onChanged: (values) {},
)

// Label on the right
FormFieldsDropdownMulti<String>(
  label: 'Hobbies',
  items: ['Gaming', 'Coding', 'Art'],
  labelPosition: LabelPosition.right,
  onChanged: (values) {},
)

// Label hidden in border
FormFieldsDropdownMulti<String>(
  label: 'Categories',
  items: ['Tech', 'Science', 'Arts'],
  labelPosition: LabelPosition.inBorder,
  onChanged: (values) {},
)

// Label completely hidden
FormFieldsDropdownMulti<String>(
  label: 'Hidden Label',
  items: ['Option 1', 'Option 2'],
  labelPosition: LabelPosition.none,
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
// With hint text
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  hintText: 'Select your languages',
  onChanged: (values) {},
)

// Nullable: No hint text displayed
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  hintText: null,
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
// With custom chip color
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipBackgroundColor: Colors.blue.shade100,
  onChanged: (values) {},
)

// Nullable: Uses default chip background
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipBackgroundColor: null,
  onChanged: (values) {},
)
```

- **chipTextColor** — Text color for selected item chips.

```dart
// With custom text color
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipTextColor: Colors.blue.shade900,
  onChanged: (values) {},
)

// Nullable: Uses default chip text color
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipTextColor: null,
  onChanged: (values) {},
)
```

- **chipDeleteIconColor** — Delete icon color for selected item chips.

```dart
// With custom delete icon color
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipDeleteIconColor: Colors.red,
  onChanged: (values) {},
)

// Nullable: Uses default delete icon color
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish'],
  chipDeleteIconColor: null,
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
// With filter hint text
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  enableFilter: true,
  filterHintText: 'Search languages...',
  onChanged: (values) {},
)

// Nullable: Default or no hint text in filter
FormFieldsDropdownMulti<String>(
  label: 'Languages',
  items: ['English', 'Spanish', 'French'],
  enableFilter: true,
  filterHintText: null,
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

| Property           | Type                     | Description                      |
| ------------------ | ------------------------ | -------------------------------- |
| items              | List<T>                  | List of selectable items.        |
| label              | String                   | The label for the dropdown.      |
| onChanged          | ValueChanged<T?>?        | Callback when selection changes. |
| initialValue       | T?                       | Initial selected value.          |
| validator          | String? Function(T?)?    | Custom validation logic.         |
| isRequired         | bool                     | Whether selection is required.   |
| itemLabelBuilder   | String Function(T item)? | Custom label builder for items.  |
| labelPosition      | LabelPosition            | Label position.                  |
| borderType         | BorderType               | Border style.                    |
| radius             | double                   | Border radius.                   |
| borderColor        | Color                    | Border color.                    |
| focusedBorderColor | Color                    | Border color when focused.       |
| errorBorderColor   | Color                    | Border color when error.         |
| decoration         | InputDecoration?         | Custom input decoration.         |
| prefixIcon         | Widget?                  | Icon before the dropdown.        |
| suffixIcon         | Widget?                  | Icon after the dropdown.         |
| hintText           | String?                  | Hint text.                       |
| enabled            | bool                     | Whether the dropdown is enabled. |
| enableFilter       | bool                     | Enable search/filter.            |
| filterHintText     | String?                  | Filter hint text.                |

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
// Non-nullable type
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Australia'],
  onChanged: (value) {},
)

// Nullable type (allows null items)
FormFieldsDropdown<String?>(
  label: 'Country',
  items: ['USA', 'Canada', null, 'Australia'],
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
// With callback
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  onChanged: (selectedValue) {
    print('Selected: $selectedValue');
  },
)

// Nullable: No callback action (read-only mode)
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  onChanged: null,
)

// With nullable type
FormFieldsDropdown<String?>(
  label: 'Country',
  items: ['USA', null, 'Canada'],
  onChanged: (selectedValue) {
    print('Selected: ${selectedValue ?? "None"}');
  },
)
```

- **initialValue** — Initial selected value.

```dart
// With initial value
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: 'USA',
  onChanged: (value) {},
)

// Nullable: No item selected initially
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: null,
  onChanged: (value) {},
)
```

- **validator** — Custom validation logic.

```dart
// With validation
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

// Nullable: No custom validation
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  validator: null,
  onChanged: (value) {},
)

// With nullable type
FormFieldsDropdown<String?>(
  label: 'Country',
  items: ['USA', null, 'Canada'],
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
// With custom label builder
FormFieldsDropdown<Country>(
  label: 'Country',
  items: countries,
  itemLabelBuilder: (country) => '${country.name} (${country.code})',
  onChanged: (value) {},
)

// Nullable: Uses toString() by default
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  itemLabelBuilder: null,
  onChanged: (value) {},
)

// With nullable type
FormFieldsDropdown<String?>(
  label: 'Country',
  items: ['USA', null, 'Canada'],
  itemLabelBuilder: (item) => item ?? 'Not Selected',
  onChanged: (value) {},
)
```

- **labelPosition** — Position of the label relative to the dropdown (top, bottom, left, right, inBorder, none).

All supported label positions:

- `LabelPosition.top` — Label positioned above the dropdown
- `LabelPosition.bottom` — Label positioned below the dropdown
- `LabelPosition.left` — Label positioned to the left of the dropdown
- `LabelPosition.right` — Label positioned to the right of the dropdown
- `LabelPosition.inBorder` — Label hidden inside the border
- `LabelPosition.none` — Label completely hidden

```dart
// Label at the top (default)
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  labelPosition: LabelPosition.top,
  onChanged: (value) {},
)

// Label at the bottom
FormFieldsDropdown<String>(
  label: 'State',
  items: ['California', 'Texas', 'Florida'],
  labelPosition: LabelPosition.bottom,
  onChanged: (value) {},
)

// Label on the left
FormFieldsDropdown<String>(
  label: 'City',
  items: ['New York', 'Los Angeles', 'Chicago'],
  labelPosition: LabelPosition.left,
  onChanged: (value) {},
)

// Label on the right
FormFieldsDropdown<String>(
  label: 'Region',
  items: ['North', 'South', 'East', 'West'],
  labelPosition: LabelPosition.right,
  onChanged: (value) {},
)

// Label hidden in border
FormFieldsDropdown<String>(
  label: 'Zone',
  items: ['Zone A', 'Zone B', 'Zone C'],
  labelPosition: LabelPosition.inBorder,
  onChanged: (value) {},
)

// Label completely hidden
FormFieldsDropdown<String>(
  label: 'Hidden Label',
  items: ['Option 1', 'Option 2'],
  labelPosition: LabelPosition.none,
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
// With custom decoration
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

// Nullable: Uses default decoration
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  decoration: null,
  onChanged: (value) {},
)
```

- **prefixIcon** — Icon displayed before the dropdown field.

```dart
// With prefix icon
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  prefixIcon: Icon(Icons.public),
  onChanged: (value) {},
)

// Nullable: No prefix icon
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  prefixIcon: null,
  onChanged: (value) {},
)
```

- **suffixIcon** — Icon displayed after the dropdown field.

```dart
// With suffix icon
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  suffixIcon: Icon(Icons.arrow_drop_down),
  onChanged: (value) {},
)

// Nullable: Uses default dropdown arrow
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  suffixIcon: null,
  onChanged: (value) {},
)
```

- **hintText** — Hint text displayed when no item is selected.

```dart
// With hint text
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  hintText: 'Select your country',
  onChanged: (value) {},
)

// Nullable: No hint text displayed
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada'],
  hintText: null,
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
// With filter hint text
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  enableFilter: true,
  filterHintText: 'Search country...',
  onChanged: (value) {},
)

// Nullable: Default or no hint text in filter
FormFieldsDropdown<String>(
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  enableFilter: true,
  filterHintText: null,
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

| Property                    | Type                       | Description                                  |
| --------------------------- | -------------------------- | -------------------------------------------- |
| label                       | String                     | The label for the radio group.               |
| items                       | List<T>?                   | List of selectable items.                    |
| sections                    | Map<String, List<T>>?      | Sectioned items.                             |
| onChanged                   | ValueChanged<T?>           | Callback when selection changes.             |
| itemLabelBuilder            | String Function(T item)?   | Custom label builder for items.              |
| itemBuilder                 | Widget Function(T, bool)?  | Custom widget builder for items.             |
| initialValue                | T?                         | Initial selected value.                      |
| isRequired                  | bool                       | Whether selection is required.               |
| direction                   | Axis                       | Layout direction (vertical/horizontal).      |
| radius                      | double                     | Border radius for the group.                 |
| borderColor                 | Color                      | Border color.                                |
| errorBorderColor            | Color                      | Border color when error.                     |
| activeColor                 | Color                      | Color for selected radio.                    |
| itemPadding                 | EdgeInsets                 | Padding for each item.                       |
| sectionSpacing              | double                     | Spacing between sections.                    |
| itemBorderColor             | Color?                     | Border color for each item.                  |
| itemBorderWidth             | double                     | Border width for each item.                  |
| itemBorderRadius            | double                     | Border radius for each item.                 |
| textRightPadding            | double                     | Padding to the right of text.                |
| itemTextMarginRight         | double                     | Margin to the right of item text.            |
| selectedItemBackgroundColor | Color?                     | Background color for selected item.          |
| selectedItemTextColor       | Color?                     | Text color for selected item.                |
| hoverBackgroundColor        | Color?                     | Background color on hover.                   |
| itemShadow                  | bool                       | Show shadow for items.                       |
| labelPosition               | LabelPosition              | Label position.                              |
| containerPadding            | double                     | Padding for the group container.             |
| containerGap                | double                     | Gap between items.                           |
| itemMarginTop               | double                     | Top margin for each item.                    |
| itemMarginBottom            | double                     | Bottom margin for each item.                 |
| indicatorVerticalAlignment  | IndicatorVerticalAlignment | Vertical alignment of indicator and content. |
| horizontalSideBySide        | bool                       | Force compact horizontal side-by-side items. |
| validator                   | FormFieldValidator<T>?     | Custom validation logic.                     |

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
// With items list
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  onChanged: (value) {},
)

// Nullable: Use sections instead
FormFieldsRadioButton<String>(
  label: 'Options',
  items: null,
  sections: {
    'Group 1': ['A', 'B'],
    'Group 2': ['C', 'D'],
  },
  onChanged: (value) {},
)

// With nullable type
FormFieldsRadioButton<String?>(
  label: 'Gender',
  items: ['Male', 'Female', null],
  onChanged: (value) {},
)
```

- **sections** — Map of sectioned items for grouped radio buttons.

```dart
// With sections
FormFieldsRadioButton<String>(
  label: 'Vehicle Type',
  sections: {
    'Two Wheelers': ['Bike', 'Scooter'],
    'Four Wheelers': ['Car', 'SUV', 'Truck'],
  },
  onChanged: (value) {},
)

// Nullable: Use items instead
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female'],
  sections: null,
  onChanged: (value) {},
)
```

- **onChanged** — Callback when the selection changes, returns the selected value.

```dart
// Non-nullable type
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female'],
  onChanged: (selectedValue) {
    print('Selected: $selectedValue');
  },
)

// Nullable type
FormFieldsRadioButton<String?>(
  label: 'Gender',
  items: ['Male', 'Female', null],
  onChanged: (selectedValue) {
    print('Selected: ${selectedValue ?? "Not specified"}');
  },
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).

```dart
// With custom label builder
FormFieldsRadioButton<Gender>(
  label: 'Gender',
  items: genders,
  itemLabelBuilder: (gender) => gender.label,
  onChanged: (value) {},
)

// Nullable: Uses toString() by default
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemLabelBuilder: null,
  onChanged: (value) {},
)

// With nullable type
FormFieldsRadioButton<String?>(
  label: 'Options',
  items: ['A', null, 'C'],
  itemLabelBuilder: (item) => item ?? 'None',
  onChanged: (value) {},
)
```

- **itemBuilder** — Custom widget builder for individual items.

```dart
// With custom item builder
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

// Nullable: Uses default radio button rendering
FormFieldsRadioButton<String>(
  label: 'Plan',
  items: ['Basic', 'Premium', 'Enterprise'],
  itemBuilder: null,
  onChanged: (value) {},
)

// With nullable type
FormFieldsRadioButton<String?>(
  label: 'Plan',
  items: ['Basic', 'Premium', null],
  itemBuilder: (item, isSelected) => Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isSelected ? Colors.blue : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(item ?? 'No plan', style: TextStyle(
      color: isSelected ? Colors.white : Colors.black,
    )),
  ),
  onChanged: (value) {},
)
```

- **initialValue** — Initial selected value.

```dart
// With initial value
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: 'Male',
  onChanged: (value) {},
)

// Nullable: No item selected initially
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  initialValue: null,
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
// With custom border color
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: Colors.grey,
  onChanged: (value) {},
)

// Nullable: No border color applied
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: null,
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
// With custom background color
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemBackgroundColor: Colors.blue.shade100,
  onChanged: (value) {},
)

// Nullable: No background color change on selection
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemBackgroundColor: null,
  onChanged: (value) {},
)
```

- **selectedItemTextColor** — Text color for selected item.

```dart
// With custom text color
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemTextColor: Colors.blue,
  onChanged: (value) {},
)

// Nullable: No text color change on selection
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  selectedItemTextColor: null,
  onChanged: (value) {},
)
```

- **hoverBackgroundColor** — Background color when hovering over items.

```dart
// With hover effect
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  hoverBackgroundColor: Colors.grey.shade200,
  onChanged: (value) {},
)

// Nullable: No hover background color
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  hoverBackgroundColor: null,
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

- **labelPosition** — Position of the label relative to the radio button group (top, bottom, left, right, inBorder, none).

All supported label positions:

- `LabelPosition.top` — Label positioned above the radio buttons
- `LabelPosition.bottom` — Label positioned below the radio buttons
- `LabelPosition.left` — Label positioned to the left of the radio buttons
- `LabelPosition.right` — Label positioned to the right of the radio buttons
- `LabelPosition.inBorder` — Label hidden inside the border
- `LabelPosition.none` — Label completely hidden

```dart
// Label at the top (default)
FormFieldsRadioButton<String>(
  label: 'Gender',
  items: ['Male', 'Female', 'Other'],
  labelPosition: LabelPosition.top,
  onChanged: (value) {},
)

// Label at the bottom
FormFieldsRadioButton<String>(
  label: 'Communication Method',
  items: ['Email', 'Phone', 'SMS'],
  labelPosition: LabelPosition.bottom,
  onChanged: (value) {},
)

// Label on the left
FormFieldsRadioButton<String>(
  label: 'Accessibility',
  items: ['Enabled', 'Disabled'],
  labelPosition: LabelPosition.left,
  onChanged: (value) {},
)

// Label on the right
FormFieldsRadioButton<String>(
  label: 'Visibility',
  items: ['Public', 'Private', 'Restricted'],
  labelPosition: LabelPosition.right,
  onChanged: (value) {},
)

// Label hidden in border
FormFieldsRadioButton<String>(
  label: 'Status',
  items: ['Active', 'Inactive'],
  labelPosition: LabelPosition.inBorder,
  onChanged: (value) {},
)

// Label completely hidden
FormFieldsRadioButton<String>(
  label: 'Hidden Label',
  items: ['Option 1', 'Option 2'],
  labelPosition: LabelPosition.none,
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
// With validation
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

// Nullable: No custom validation
FormFieldsRadioButton<String>(
  label: 'Options',
  items: ['A', 'B', 'C'],
  validator: null,
  onChanged: (value) {},
)

// With nullable type
FormFieldsRadioButton<String?>(
  label: 'Options',
  items: ['A', null, 'C'],
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

| Property             | Type                        | Description                       |
| -------------------- | --------------------------- | --------------------------------- |
| formType             | FormType                    | The type of selection widget.     |
| label                | String                      | The label for the select widget.  |
| items                | List<T>                     | List of selectable items.         |
| initialValue         | T?                          | Initial value (single select).    |
| initialValues        | List<T>?                    | Initial values (multi select).    |
| onChanged            | ValueChanged<T?>?           | Callback for single value change. |
| onMultiChanged       | ValueChanged<List<T>>?      | Callback for multi value change.  |
| itemLabelBuilder     | String Function(T item)?    | Custom label builder for items.   |
| validator            | String? Function(T?)?       | Validator for single value.       |
| multiValidator       | String? Function(List<T>?)? | Validator for multi value.        |
| isRequired           | bool                        | Whether selection is required.    |
| labelPosition        | LabelPosition               | Label position.                   |
| borderType           | BorderType                  | Border style.                     |
| radius               | double                      | Border radius.                    |
| borderColor          | Color                       | Border color.                     |
| focusedBorderColor   | Color                       | Border color when focused.        |
| errorBorderColor     | Color                       | Border color when error.          |
| itemBorderColor      | Color?                      | Border color for each item.       |
| itemBorderWidth      | double                      | Border width for each item.       |
| itemBorderRadius     | double                      | Border radius for each item.      |
| itemMarginTop        | double                      | Top margin for each item.         |
| itemMarginBottom     | double                      | Bottom margin for each item.      |
| itemMarginHorizontal | double                      | Horizontal margin for each item.  |
| enableFilter         | bool                        | Enable search/filter.             |
| filterHintText       | String                      | Filter hint text.                 |

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
// Non-nullable type
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK', 'Australia'],
  onChanged: (value) {},
)

// Nullable type (allows null items)
FormFieldsSelect<String?>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', null, 'Australia'],
  onChanged: (value) {},
)
```

- **initialValue** — Initial value for single select (dropdown, radioButton).

```dart
// With initial value
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: 'USA',
  onChanged: (value) {},
)

// Nullable: No item selected initially
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  initialValue: null,
  onChanged: (value) {},
)
```

- **initialValues** — Initial values for multi-select (dropdownMulti, checkbox).

```dart
// With initial values
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Interests',
  items: ['Sports', 'Music', 'Reading'],
  initialValues: ['Sports', 'Music'],
  onMultiChanged: (values) {},
)

// Nullable: No items selected initially
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Interests',
  items: ['Sports', 'Music', 'Reading'],
  initialValues: null,
  onMultiChanged: (values) {},
)
```

- **onChanged** — Callback for single value changes (dropdown, radioButton).

```dart
// With callback
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  onChanged: (selectedValue) {
    print('Selected: $selectedValue');
  },
)

// Nullable: No callback action (when using onMultiChanged instead)
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Options',
  items: ['A', 'B', 'C'],
  onChanged: null,
  onMultiChanged: (values) {
    print('Selected: $values');
  },
)

// With nullable type
FormFieldsSelect<String?>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', null, 'Canada'],
  onChanged: (selectedValue) {
    print('Selected: ${selectedValue ?? "None"}');
  },
)
```

- **onMultiChanged** — Callback for multi-value changes (dropdownMulti, checkbox).

```dart
// With callback
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Interests',
  items: ['Sports', 'Music', 'Reading'],
  onMultiChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)

// Nullable: No callback action (when using onChanged instead)
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  onMultiChanged: null,
  onChanged: (value) {
    print('Selected: $value');
  },
)

// With nullable type for multi-select
FormFieldsSelect<String?>(
  formType: FormType.checkbox,
  label: 'Interests',
  items: ['Sports', null, 'Reading'],
  onMultiChanged: (selectedValues) {
    print('Selected: $selectedValues');
  },
)
```

- **itemLabelBuilder** — Custom label builder for items (useful with custom classes).

```dart
// With custom label builder
FormFieldsSelect<Country>(
  formType: FormType.dropdown,
  label: 'Country',
  items: countries,
  itemLabelBuilder: (country) => '${country.name} (${country.code})',
  onChanged: (value) {},
)

// Nullable: Uses toString() by default
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  itemLabelBuilder: null,
  onChanged: (value) {},
)

// With nullable type
FormFieldsSelect<String?>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', null, 'Canada'],
  itemLabelBuilder: (item) => item ?? 'Unspecified',
  onChanged: (value) {},
)
```

- **validator** — Validator for single value selections.

```dart
// With validation
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

// Nullable: No custom validation
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada'],
  validator: null,
  onChanged: (value) {},
)

// With nullable type
FormFieldsSelect<String?>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', null, 'Canada'],
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
// With validation
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

// Nullable: No custom validation
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Skills',
  items: ['Dart', 'Flutter', 'Firebase'],
  multiValidator: null,
  onMultiChanged: (values) {},
)

// With nullable type
FormFieldsSelect<String?>(
  formType: FormType.checkbox,
  label: 'Skills',
  items: ['Dart', null, 'Firebase'],
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

- **labelPosition** — Position of the label relative to the select widget (top, bottom, left, right, inBorder, none).

All supported label positions:

- `LabelPosition.top` — Label positioned above the widget
- `LabelPosition.bottom` — Label positioned below the widget
- `LabelPosition.left` — Label positioned to the left of the widget
- `LabelPosition.right` — Label positioned to the right of the widget
- `LabelPosition.inBorder` — Label hidden inside the border
- `LabelPosition.none` — Label completely hidden

```dart
// Label at the top (default)
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Country',
  items: ['USA', 'Canada', 'UK'],
  labelPosition: LabelPosition.top,
  onChanged: (value) {},
)

// Label at the bottom
FormFieldsSelect<String>(
  formType: FormType.dropdownMulti,
  label: 'Skills',
  items: ['JavaScript', 'Dart', 'Python'],
  labelPosition: LabelPosition.bottom,
  onMultiChanged: (values) {},
)

// Label on the left
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Plan',
  items: ['Basic', 'Pro', 'Enterprise'],
  labelPosition: LabelPosition.left,
  onChanged: (value) {},
)

// Label on the right
FormFieldsSelect<String>(
  formType: FormType.checkbox,
  label: 'Features',
  items: ['Feature 1', 'Feature 2', 'Feature 3'],
  labelPosition: LabelPosition.right,
  onMultiChanged: (values) {},
)

// Label hidden in border
FormFieldsSelect<String>(
  formType: FormType.dropdown,
  label: 'Status',
  items: ['Active', 'Inactive'],
  labelPosition: LabelPosition.inBorder,
  onChanged: (value) {},
)

// Label completely hidden
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Hidden Label',
  items: ['Option 1', 'Option 2'],
  labelPosition: LabelPosition.none,
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
// With custom border color
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: Colors.grey,
  onChanged: (value) {},
)

// Nullable: No border color applied
FormFieldsSelect<String>(
  formType: FormType.radioButton,
  label: 'Options',
  items: ['A', 'B', 'C'],
  itemBorderColor: null,
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

| Value         | Description                          |
| ------------- | ------------------------------------ |
| string        | Standard text input                  |
| phone         | Phone number input                   |
| password      | Password input (obscured)            |
| verification  | Verification/OTP input (digits only) |
| email         | Email address input                  |
| date          | Date picker                          |
| time          | Time picker                          |
| dateTime      | Date and time picker                 |
| dateTimeRange | Date range picker                    |
| timeOfDay     | TimeOfDay picker                     |
| dropdown      | Dropdown selection                   |
| dropdownMulti | Multi-select dropdown                |
| radioButton   | Radio button group                   |
| checkbox      | Checkbox group                       |

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

| Value    | Description        |
| -------- | ------------------ |
| top      | Label above input  |
| bottom   | Label below input  |
| left     | Label to the left  |
| right    | Label to the right |
| inBorder | Floating label     |
| none     | No label           |

#### BorderType

| Value                | Description      |
| -------------------- | ---------------- |
| outlineInputBorder   | Outlined border  |
| underlineInputBorder | Underline border |
| none                 | No border        |

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

## Localization & Language Control

The FormFields package includes full localization support with **English (en_US)** as the default and **Indonesian (id_ID)** built-in. All validation messages, hints, buttons, and UI text automatically adapt to your app's selected language.

> 📘 **For complete localization documentation**, see [LOCALIZATION.md](LOCALIZATION.md) for adding custom languages, detailed examples, and advanced features.

---

### Quick Setup

#### 1. Enable Localization (Optional for Global Support)

**Note:** If you're using the per-field `locale` property (Option 4 below), you **don't need** to add the delegate. The field will load its locale directly.

Add the localization delegate to your `MaterialApp` only if you want app-wide localization:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';

MaterialApp(
  localizationsDelegates: const [
    FormFieldsLocalizationsDelegate(),  // Add this for app-wide localization
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: FormFieldsLocalizations.supportedLocales,
  home: const HomePage(),
)
```

---

### Manually Setting Language

There are three approaches to manually control the app language:

#### **Option 1: Direct MaterialApp Configuration** (Simplest)

Set the `locale` property directly in `MaterialApp`:

```dart
MaterialApp(
  locale: const Locale('id', 'ID'),  // Set to Indonesian
  // locale: const Locale('en', 'US'),  // Set to English
  localizationsDelegates: const [
    FormFieldsLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: FormFieldsLocalizations.supportedLocales,
  home: const HomePage(),
)
```

✅ **Use when**: Language is set once and doesn't change during runtime.

---

#### **Option 2: Runtime Language Switching with StatefulWidget**

Use a `StatefulWidget` for your `MyApp` to enable language switching without restart:

```dart
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', 'US');  // Default language

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: const [
        FormFieldsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: FormFieldsLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}

// Switch language from anywhere in your app
MyApp.of(context).setLocale(const Locale('id', 'ID'));  // Switch to Indonesian
MyApp.of(context).setLocale(const Locale('en', 'US'));  // Switch to English
```

✅ **Use when**: Users can switch language from app settings or a language selector.

---

#### **Option 3: State Management with Provider** (Recommended for larger apps)

Use Provider or another state management solution for persistent language settings:

```dart
// 1. Create an AppStateNotifier
class AppStateNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    // Optional: Save to SharedPreferences for persistence
  }
}

// 2. Wrap your app with ChangeNotifierProvider
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateNotifier(),
      child: const MyApp(),
    ),
  );
}

// 3. Use the locale in MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateNotifier>();

    return MaterialApp(
      locale: appState.locale,
      localizationsDelegates: const [
        FormFieldsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: FormFieldsLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}

// 4. Switch language from anywhere
context.read<AppStateNotifier>().setLocale(const Locale('id', 'ID'));
```

✅ **Use when**: You need persistent language settings, complex state management, or language switching across multiple screens.

---

#### **Option 4: Per-Field Language Override** (No Delegate Required!)

Set a specific language for individual fields using the `locale` property. **This works without `FormFieldsLocalizationsDelegate()`** - the field loads its locale directly:

```dart
// ✨ Simple example - No delegate needed in MaterialApp!
MaterialApp(
  home: Scaffold(
    body: FormFields<String>(
      label: 'Email',
      formType: FormType.email,
      isRequired: true,
      locale: 'id',  // Simple: just 'id' for Indonesian!
      currrentValue: '',
      onChanged: (value) => print(value),
    ),
  ),
)

// Advanced: Multiple languages in one form
FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  isRequired: true,
  locale: 'id',  // Indonesian for this field
  currrentValue: _email,
  onChanged: (value) => setState(() => _email = value),
)

FormFields<String>(
  label: 'Phone',
  formType: FormType.phone,
  locale: 'en',  // English for this field
  currrentValue: _phone,
  onChanged: (value) => setState(() => _phone = value),
)

// No locale specified - uses app's default (English fallback)
FormFields<String>(
  label: 'Name',
  formType: FormType.string,
  currrentValue: _name,
  onChanged: (value) => setState(() => _name = value),
)
```

✅ **Use when**:

- Building multilingual forms where different fields need different languages
- Creating language-specific examples or demos
- Testing localization without changing the entire app locale
- Supporting users who need mixed-language forms

---

### Supported Languages

| Language            | Locale Code          | Usage                                  |
| ------------------- | -------------------- | -------------------------------------- |
| 🇺🇸 **English (US)** | `Locale('en', 'US')` | Default, included                      |
| 🇮🇩 **Indonesian**   | `Locale('id', 'ID')` | Included                               |
| 🌍 **Custom**       | `Locale('xx', 'XX')` | See [LOCALIZATION.md](LOCALIZATION.md) |

> **Want to add a new language to the plugin?**
> See the detailed [Contributing Guide](LOCALIZATION.md#contributing) in LOCALIZATION.md for step-by-step instructions on adding Spanish, French, or any language directly to the package.

---

### Date/Time Picker Locale Behavior

Date and time pickers automatically follow your app's selected language:

```dart
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  currrentValue: _birthDate,
  onChanged: (value) => setState(() => _birthDate = value),
  // Picker will automatically use the app's locale
)

// Optional: Override language for a specific field
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  locale: 'en_US',  // Force English locale for this field's picker and messages
  currrentValue: _birthDate,
  onChanged: (value) => setState(() => _birthDate = value),
)
```

**Default Behavior**: When `locale` is **not specified**, the picker automatically uses the current app locale (e.g., if app is set to Indonesian, picker will show in Indonesian).

---

### Example: Language Selector Button

```dart
ElevatedButton(
  onPressed: () {
    // Using Option 2 (StatefulWidget)
    MyApp.of(context).setLocale(const Locale('id', 'ID'));

    // OR using Option 3 (Provider)
    // context.read<AppStateNotifier>().setLocale(const Locale('id', 'ID'));
  },
  child: const Text('Switch to Indonesian'),
)
```

---

### Localized Validation Messages

All validation messages automatically use the selected language:

```dart
final l10n = FormFieldsLocalizations.of(context);

FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  isRequired: true,
  validator: FormFieldValidators.email('Email', l10n),
  currrentValue: _email,
  onChanged: (value) => setState(() => _email = value),
)
// English: "Enter a valid email address"
// Indonesian: "Masukkan alamat email yang valid"
```

---

### Adding More Languages

To add Spanish, French, or any language:

1. Create a language file in your project (e.g., `es_es_localizations.dart`)
2. Define all translation strings
3. Create a custom delegate
4. Add to `localizationsDelegates` in `MaterialApp`

📘 **See [LOCALIZATION.md](LOCALIZATION.md)** for complete step-by-step instructions with code examples.

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

- **FormType.verification**

```dart
FormFields<String>(
  label: 'Verification Code',
  formType: FormType.verification,
  verificationLength: 6,
  verificationHidden: true,
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
