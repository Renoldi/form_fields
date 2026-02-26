# Form Fields Localization Guide

The Form Fields package now supports multi-language functionality with US English as the default language.

## Supported Languages

Currently supported languages:
- 🇺🇸 **English (US)** - Default language
- 🇮🇩 **Indonesian (ID)** - Example implementation

## Quick Start

### 1. Basic Usage (Using Default Language)

The package works out of the box with US English as the default language. No configuration needed:

```dart
import 'package:form_fields/form_fields.dart';

FormFieldsDropdown<String>(
  label: 'Country',
  items: countries,
  onChanged: (value) => setState(() => selectedCountry = value),
  enableFilter: true,  // Shows "Search..." in English
)
```

### 2. Adding Localization Support to Your App

To enable multi-language support in your Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Add the FormFieldsLocalizationsDelegate
      localizationsDelegates: const [
        FormFieldsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Specify supported locales
      supportedLocales: FormFieldsLocalizations.supportedLocales,
      
      // Your app configuration
      home: MyHomePage(),
    );
  }
}
```

### 3. Using Localization in Custom Validators

Access localized strings in your code:

```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: countries,
  validator: (value) {
    final l10n = FormFieldsLocalizations.of(context);
    if (value == null) {
      return l10n.select('Country'); // Returns "Select Country" or translated
    }
    return null;
  },
  onChanged: (value) => setState(() => selectedCountry = value),
)
```

## Built-in Localized Text

The following UI elements are automatically localized:

### Dialog Actions
- Cancel button: `CANCEL` / `BATAL`
- OK button: `OK` / `OK`
- Done button: `DONE` / `SELESAI`

### Filter/Search
- Search hint: `Search...` / `Cari...`
- Type to search: `Type to search {label}...` / `Ketik untuk mencari {label}...`

### Validation Messages
- Select: `Select {label}` / `Pilih {label}`
- Select at least one: `Select at least one {label}` / `Pilih setidaknya satu {label}`
- Select at least X: `Select at least {value} items` / `Pilih setidaknya {value} item`
- Select at most X: `Select at most {value} items` / `Pilih maksimal {value} item`

### Field Hints
- Enter: `Enter {label}` / `Masukkan {label}`
- Enter valid email: `Enter valid email address` / `Masukkan alamat email yang valid`
- Enter valid phone: `Enter valid phone number` / `Masukkan nomor telepon yang valid`

### Password Validation
- Minimum length: `Password must be at least {value} characters` / `Kata sandi harus minimal {value} karakter`
- Needs uppercase: `Must contain uppercase letter` / `Harus mengandung huruf besar`
- Needs number: `Must contain a number` / `Harus mengandung angka`

## Advanced Localization API

### Accessing Localizations

```dart
// In a widget with BuildContext
final l10n = FormFieldsLocalizations.of(context);

// Get simple string
String cancelText = l10n.cancel; // "CANCEL"

// Get string with label replacement
String selectCountry = l10n.select('Country'); // "Select Country"

// Get string with value replacement
String minPassword = l10n.passwordMinLength(8); // "Password must be at least 8 characters"

// Get string with multiple parameters
String customMessage = l10n.getWithParams('tooShort', {
  'label': 'Password',
  'value': 8,
}); // "Password is too short (minimum 8 characters)"
```

### Available Methods

```dart
// Simple getters
l10n.cancel                 // "CANCEL"
l10n.searchHint             // "Search..."

// Methods with label
l10n.select('Country')      // "Select Country"
l10n.enter('Email')         // "Enter Email"

// Methods with value
l10n.selectAtLeast(2)       // "Select at least 2 items"
l10n.selectAtMost(5)        // "Select at most 5 items"
l10n.passwordMinLength(8)   // "Password must be at least 8 characters"

// Generic methods
l10n.get('key')                           // Get by key
l10n.getWithLabel('key', 'Label')        // Replace {label}
l10n.getWithValue('key', 5)              // Replace {value}
l10n.getWithParams('key', {'x': 'y'})    // Replace {x} with y
```

## Adding a New Language

To add a new language (e.g., Spanish):

### Step 1: Create Language File

Create `lib/src/localization/languages/es_es.dart`:

```dart
/// Spanish (Spain) language strings
final Map<String, String> esESStrings = {
  'cancel': 'CANCELAR',
  'ok': 'ACEPTAR',
  'select': 'Seleccionar {label}',
  'searchHint': 'Buscar...',
  'selectAtLeastOne': 'Seleccione al menos uno {label}',
  'enter': 'Introducir {label}',
  'enterValidEmail': 'Ingrese una dirección de correo válida',
  'passwordMinLength': 'La contraseña debe tener al menos {value} caracteres',
  // ... add all other keys from en_us.dart or id_id.dart
};
```

### Step 2: Register Language

Update `lib/src/localization/form_fields_localizations.dart`:

```dart
import 'languages/es_es.dart';

static final Map<String, Map<String, String>> _supportedLanguages = {
  'en_US': enUSStrings,
  'id_ID': idIDStrings,
  'es_ES': esESStrings,  // Add this line
};
```

### Step 3: Use in Your App

The new language will automatically be available when you set the locale:

```dart
MaterialApp(
  locale: const Locale('es', 'ES'),
  localizationsDelegates: const [
    FormFieldsLocalizationsDelegate(),
    // ... other delegates
  ],
  supportedLocales: FormFieldsLocalizations.supportedLocales,
)
```

## Custom Filter Hints

You can override the default filter hint text:

```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: countries,
  enableFilter: true,
  filterHintText: 'Type to search countries...', // Custom hint
  onChanged: (value) => setState(() => selectedCountry = value),
)
```

## Customizing Hint Text

You can provide custom hint text for any field:

```dart
FormFieldsDropdown<String>(
  label: 'Country',
  items: countries,
  hintText: 'Please select your country', // Custom hint
  onChanged: (value) => setState(() => selectedCountry = value),
)
```

## Language File Structure

All language files must contain these keys:

```dart
{
  // Actions
  'cancel', 'ok', 'done',
  
  // Selection
  'select', 'selectPrefix', 'selectAtLeastOne', 'selectAtLeast', 'selectAtMost',
  
  // Search
  'searchHint', 'typeToSearch', 'noResultsFound',
  
  // Validation
  'enter', 'enterPrefix', 'enterValid', 'enterValidEmail', 'enterValidPhone',
  'enterValidInteger', 'enterValidNumber',
  
  // Password
  'passwordMinLength', 'passwordRequired', 'passwordTooShort',
  'passwordNeedsUppercase', 'passwordNeedsNumber', 'passwordNeedsSpecialChar',
  
  // Field Types
  'fieldTypeString', 'fieldTypeEmail', 'fieldTypePhone', 'fieldTypeNumber',
  'fieldTypeInteger', 'fieldTypeDate', 'fieldTypeTime',
  
  // Errors
  'required', 'invalid', 'tooShort', 'tooLong', 'minimumValue', 'maximumValue',
  
  // Hints
  'selectDate', 'selectTime', 'selectDateRange', 'selectFromList', 'selectMultiple',
  
  // Accessibility
  'selectedItems', 'noItemsSelected', 'tapToSelect', 'tapToEdit', 'tapToRemove',
}
```

## Example: Complete Form with Localization

```dart
import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class LocalizedForm extends StatefulWidget {
  @override
  _LocalizedFormState createState() => _LocalizedFormState();
}

class _LocalizedFormState extends State<LocalizedForm> {
  String? selectedCountry;
  List<String> selectedLanguages = [];

  @override
  Widget build(BuildContext context) {
    final l10n = FormFieldsLocalizations.of(context);

    return Column(
      children: [
        // Dropdown with filter - automatically localized
        FormFieldsDropdown<String>(
          label: 'Country',
          items: ['USA', 'Indonesia', 'Spain', 'France'],
          enableFilter: true, // Shows localized "Search..." or "Cari..."
          isRequired: true,
          onChanged: (value) => setState(() => selectedCountry = value),
        ),
        
        // Multi-select dropdown - automatically localized
        FormFieldsDropdownMulti<String>(
          label: 'Languages',
          items: ['English', 'Indonesian', 'Spanish', 'French'],
          enableFilter: true,
          isRequired: true,
          onChanged: (value) => setState(() => selectedLanguages = value),
        ),
        
        // Custom validation with localization
        FormFieldsDropdown<String>(
          label: 'Priority',
          items: ['Low', 'Medium', 'High'],
          validator: (value) {
            if (value == null) {
              return l10n.select('Priority'); // Localized message
            }
            return null;
          },
          onChanged: (value) {},
        ),
      ],
    );
  }
}
```

## Testing Localization

To test your app in different languages:

```dart
// Run with specific locale
flutter run --dart-define=LOCALE=id_ID

// Or set in your app
MaterialApp(
  locale: const Locale('id', 'ID'), // Indonesian
  // or
  locale: const Locale('en', 'US'), // English (default)
)
```

## Contributing New Languages

We welcome contributions for new language translations! To contribute:

1. Create a new language file in `lib/src/localization/languages/`
2. Copy all keys from `en_us.dart`
3. Translate all values
4. Register in `form_fields_localizations.dart`
5. Submit a pull request

Popular languages we'd love to support:
- Spanish (es_ES)
- French (fr_FR)
- German (de_DE)
- Chinese (zh_CN)
- Japanese (ja_JP)
- Portuguese (pt_BR)
- Arabic (ar_SA)
- Hindi (hi_IN)
- And more!

## Notes

- **Default Behavior**: If no localization delegate is added, the package automatically uses US English
- **Fallback**: If a translation is missing, the English text is shown
- **Performance**: Localization has minimal performance impact
- **Custom Overrides**: You can always override any text by providing `hintText`, `filterHintText`, or custom `validator` messages

## Support

For issues or questions about localization:
- Create an issue on GitHub
- Check the example app for implementation details
- Refer to Flutter's official localization documentation
