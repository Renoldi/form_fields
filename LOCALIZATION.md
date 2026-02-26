# Form Fields Localization Guide

The Form Fields package provides comprehensive multi-language support for all validation messages, error text, and UI elements. **US English is the default language**, with built-in support for Indonesian and easy addition of new languages.

## Supported Languages

| Language | Code | Status | Count |
|----------|------|--------|-------|
| 🇺🇸 English (US) | `en_US` | ✅ Default | 50+ strings |
| 🇮🇩 Indonesian | `id_ID` | ✅ Included | 50+ strings |
| 🌍 Your Language | `{lang}_{COUNTRY}` | ➕ Add yours | - |

## Quick Start

### 1. Basic Usage (Using Default Language)

The package works out of the box with US English. No configuration needed:

```dart
import 'package:form_fields/form_fields.dart';

FormFields<String>(
  label: 'Email',
  formType: FormType.email,
  isRequired: true,
  onChanged: (value) => setState(() => _email = value),
  currrentValue: _email,
  // Error automatically shows in English: "Email is required"
)
```

### 2. Enable Multi-Language Support

Add the localization delegate to your `MaterialApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      locale: const Locale('id', 'ID'),  // Switch to Indonesian
      localizationsDelegates: const [
        FormFieldsLocalizationsDelegate(),  // Add this
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: FormFieldsLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}
```

### 3. Use Localized Validators

Built-in validators now support full localization:

```dart
import 'package:form_fields/form_fields.dart';

final l10n = FormFieldsLocalizations.of(context);

FormFields<String>(
  label: 'Email Address',
  formType: FormType.email,
  isRequired: true,
  validator: FormFieldValidators.email(_email, l10n),
  onChanged: (value) => setState(() => _email = value),
  currrentValue: _email,
)
// Shows: "Enter a valid email address" (en) or "Masukkan alamat email yang valid" (id)
```

## Localized Validators

All validators support automatic localization:

```dart
final l10n = FormFieldsLocalizations.of(context);

// Email validator with localization
FormFieldValidators.email(label, l10n);

// Phone validator with localization
FormFieldValidators.phone(label, l10n);

// Password validator with localization
FormFieldValidators.password(label, l10n: l10n);

// Number validator with localization
FormFieldValidators.number(label, l10n: l10n);

// Min/Max length validators with localization
FormFieldValidators.minLength(label, 8, l10n: l10n);
FormFieldValidators.maxLength(label, 20, l10n: l10n);

// Range validator with localization
FormFieldValidators.range(label, 18, 65, l10n: l10n);

// Pattern validator with localization
FormFieldValidators.pattern(label, '^[a-z]+\$', l10n: l10n);
```

## Accessing Localized Strings

### Simple Getters

```dart
final l10n = FormFieldsLocalizations.of(context);

String cancelText = l10n.cancel;  
// "CANCEL" (English) or "BATAL" (Indonesian)

String okText = l10n.ok;  
// "OK" (both languages)

String doneText = l10n.done;  
// "DONE" (English) or "SELESAI" (Indonesian)

String searchHint = l10n.searchHint;
// "Search..." (English) or "Cari..." (Indonesian)
```

### Methods with Parameters

```dart
final l10n = FormFieldsLocalizations.of(context);

// With label
String msg = l10n.enter('Email');
// "Enter Email" (English) or "Masukkan Email" (Indonesian)

String msg = l10n.select('Country');
// "Select Country" (English) or "Pilih Country" (Indonesian)

// With value
String msg = l10n.getWithValue('passwordMinLength', 8);
// "Password must be at least 8 characters" (English)
// "Kata sandi harus minimal 8 karakter" (Indonesian)

// With multiple parameters
String msg = l10n.getWithParams('betweenValue', {
  'label': 'Age',
  'min': 18,
  'max': 65,
});
// "Age must be between 18 and 65" (English)
// "Umur harus antara 18 dan 65" (Indonesian)
```

### Generic Methods

```dart
final l10n = FormFieldsLocalizations.of(context);

// Get by key
l10n.get('required')  // Returns translated string for key

// Replace {label}
l10n.getWithLabel('tooShort', 'Password')

// Replace {value}
l10n.getWithValue('selectAtLeast', 3)

// Replace multiple values
l10n.getWithParams('invalid', {'label': 'Email'})
```

## Automatically Localized Elements

All of these automatically adapt to the selected language:

✅ **Validation Messages**
- `"required"` → `"Email is required"` / `"Email wajib diisi"`
- `"enterValidEmail"` → `"Enter valid email address"` / `"Masukkan alamat email yang valid"`
- `"tooShort"` → `"{label} is too short"` / `"{label} terlalu pendek"`

✅ **Form Elements**
- Search/Filter hints
- Button text (OK, Cancel, Done)
- Selection dialogs
- Field-specific error messages

✅ **Password Validation**
- Minimum length requirements
- Character requirements (uppercase, numbers, special chars)
- All customizable error messages

## Language File Structure

All language files require these core keys:

```dart
final Map<String, String> {lang}_{country}Strings = {
  // === COMMON ACTIONS ===
  'cancel': '...',
  'ok': '...',
  'done': '...',
  'submit': '...',
  'validate': '...',

  // === VALIDATION - REQUIRED & GENERAL ===
  'required': '{label} ...',
  'enterPrefix': '...',
  'enter': 'Enter {label}',
  'enterValid': '...',

  // === EMAIL VALIDATION ===
  'enterValidEmail': '...',
  'emailRequired': '...',

  // === PHONE VALIDATION ===
  'enterValidPhone': '...',
  'phoneRequired': '...',

  // === INTEGER VALIDATION ===
  'enterValidInteger': '...',
  'integerRequired': '...',

  // === NUMBER/DECIMAL VALIDATION ===
  'enterValidNumber': '...',
  'numberRequired': '...',

  // === PASSWORD VALIDATION ===
  'passwordRequired': '...',
  'passwordMinLength': '... {value} ...',
  'passwordNeedsUppercase': '...',
  'passwordNeedsNumber': '...',

  // === LENGTH VALIDATION ===
  'tooShort': '{label} ... {value} ...',
  'tooLong': '{label} ... {value} ...',

  // === RANGE VALIDATION ===
  'minimumValue': '{label} ...',
  'maximumValue': '{label} ...',
  'betweenValue': '{label} ... {min} ... {max}',

  // === FIELD TYPES ===
  'fieldTypeString': '...',
  'fieldTypeEmail': '...',
  'fieldTypePhone': '...',
  // ... add all other keys
};
```

See [localization/languages/en_us.dart](lib/src/localization/languages/en_us.dart) for complete list of keys.

## Adding a New Language

### Step 1: Create Language File

Create `lib/src/localization/languages/{lang}_{country}.dart`:

**Example: Spanish (es_es.dart)**

```dart
/// Spanish (Spain) language strings
final Map<String, String> esESStrings = {
  // === COMMON ACTIONS ===
  'cancel': 'CANCELAR',
  'ok': 'ACEPTAR',
  'done': 'LISTO',
  'submit': 'ENVIAR',
  'validate': 'VALIDAR',
  'select': 'Seleccionar {label}',
  'selectPrefix': 'Seleccionar',

  // === SEARCH/FILTER ===
  'searchHint': 'Buscar...',
  'typeToSearch': 'Escribe para buscar {label}...',
  'noResultsFound': 'No hay resultados',

  // === FIELD TYPES & LABELS ===
  'fieldTypeString': 'texto',
  'fieldTypeEmail': 'correo electrónico',
  'fieldTypePhone': 'teléfono',
  'fieldTypePassword': 'contraseña',
  'fieldTypeNumber': 'número',
  'fieldTypeInteger': 'número entero',
  'fieldTypeDate': 'fecha',
  'fieldTypeTime': 'hora',
  'fieldTypeDateRange': 'rango de fechas',

  // === VALIDATION - REQUIRED & GENERAL ===
  'required': '{label} es obligatorio',
  'enterPrefix': 'Ingresa ',
  'enter': 'Ingresa {label}',
  'enterValid': 'Ingresa un {type} válido para {label}',

  // === EMAIL VALIDATION ===
  'enterValidEmail': 'Ingresa una dirección de correo válida',
  'emailRequired': 'La dirección de correo es obligatoria',

  // === PHONE VALIDATION ===
  'enterValidPhone': 'Ingresa un número de teléfono válido',
  'phoneRequired': 'El número de teléfono es obligatorio',

  // === INTEGER VALIDATION ===
  'enterValidInteger': 'Ingresa un número entero válido para {label}',
  'integerRequired': 'El número entero es obligatorio',

  // === NUMBER/DECIMAL VALIDATION ===
  'enterValidNumber': 'Ingresa un número válido para {label}',
  'numberRequired': 'El número es obligatorio',

  // === PASSWORD VALIDATION ===
  'passwordRequired': 'La contraseña es obligatoria',
  'passwordMinLength': 'La contraseña debe tener al menos {value} caracteres',
  'passwordTooShort': 'La contraseña debe tener {value}+ caracteres',
  'passwordNeedsUppercase': 'Debe contener una letra mayúscula',
  'passwordNeedsLowercase': 'Debe contener una letra minúscula',
  'passwordNeedsNumber': 'Debe contener un número',
  'passwordNeedsSpecialChar': 'Debe contener un carácter especial',

  // === LENGTH VALIDATION ===
  'tooShort': '{label} es demasiado corto (mínimo {value} caracteres)',
  'tooLong': '{label} es demasiado largo (máximo {value} caracteres)',

  // === RANGE VALIDATION ===
  'minimumValue': '{label} debe ser al menos {value}',
  'maximumValue': '{label} no debe exceder {value}',
  'betweenValue': '{label} debe estar entre {min} y {max}',

  // === PATTERN/FORMAT VALIDATION ===
  'invalid': '{label} no es válido',
  'invalidFormat': 'Formato de {label} no válido',

  // === SELECTION/DROPDOWN VALIDATION ===
  'selectAtLeastOne': 'Selecciona al menos uno {label}',
  'selectAtLeast': 'Selecciona al menos {value} elementos',
  'selectAtMost': 'Selecciona como máximo {value} elementos',
  'selectExactly': 'Selecciona exactamente {value} elementos',

  // === DATE/TIME VALIDATION ===
  'selectDate': 'Selecciona fecha',
  'selectTime': 'Selecciona hora',
  'selectDateRange': 'Selecciona rango de fechas',
  'dateRequired': 'La fecha es obligatoria',
  'timeRequired': 'La hora es obligatoria',

  // === HINTS & INSTRUCTIONS ===
  'selectFromList': 'Selecciona de la lista',
  'selectMultiple': 'Selecciona múltiples elementos',
  'typeHere': 'Escribe aquí...',

  // === ACCESSIBILITY & UI ===
  'selectedItems': '{value} elementos seleccionados',
  'noItemsSelected': 'No hay elementos seleccionados',
  'tapToSelect': 'Toca para seleccionar',
  'tapToEdit': 'Toca para editar',
  'tapToRemove': 'Toca para eliminar',
  'clear': 'Limpiar',
  'clearAll': 'Limpiar todo',

  // === MESSAGES ===
  'success': 'Éxito',
  'error': 'Error',
  'warning': 'Advertencia',
  'info': 'Información',
  'validationFailed': 'La validación falló',
  'formSubmitted': 'Formulario enviado correctamente',
};
```

### Step 2: Register Language

Edit `lib/src/localization/form_fields_localizations.dart`:

```dart
import 'languages/es_es.dart';  // Add import at the top

class FormFieldsLocalizations {
  // ... existing code ...

  /// Map of supported languages
  static final Map<String, Map<String, String>> _supportedLanguages = {
    'en_US': enUSStrings,
    'id_ID': idIDStrings,
    'es_ES': esESStrings,  // Add this line
    // Add more languages here
  };
}
```

### Step 3: Update Constructor (Optional)

If using language switching, also update the `FormFieldsLocalizationsDelegate`:

```dart
class FormFieldsLocalizationsDelegate 
    extends LocalizationsDelegate<FormFieldsLocalizations> {
  
  @override
  bool isSupported(Locale locale) {
    return FormFieldsLocalizations.isSupported(locale);
  }

  @override
  Future<FormFieldsLocalizations> load(Locale locale) {
    return SynchronousFuture<FormFieldsLocalizations>(
      FormFieldsLocalizations.load(locale),
    );
  }

  @override
  bool shouldReload(FormFieldsLocalizationsDelegate old) => false;
}
```

### Step 4: Use in Your App

```dart
MaterialApp(
  locale: const Locale('es', 'ES'),  // Spanish
  localizationsDelegates: const [
    FormFieldsLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: FormFieldsLocalizations.supportedLocales,
  home: const HomePage(),
)
```

## Runtime Language Switching

Change language without restarting the app:

```dart
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', 'US');

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

// Use it in your page
MyApp.of(context).setLocale(const Locale('id', 'ID'));  // Switch to Indonesian
```

## Testing Localization

Test your app in different languages:

```dart
// Set in code
MaterialApp(
  locale: const Locale('id', 'ID'),  // Indonesian
  // or
  locale: const Locale('es', 'ES'),  // Spanish
)

// Or run from terminal
flutter run --dart-define=LOCALE=id_ID
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localization Example',
      locale: const Locale('id', 'ID'),
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

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _email = '';
  String _phone = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final l10n = FormFieldsLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form with Localization'),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Email with localized validator
            FormFields<String>(
              label: 'Email',
              formType: FormType.email,
              isRequired: true,
              validator: FormFieldValidators.email(_email, l10n),
              onChanged: (value) => setState(() => _email = value),
              currrentValue: _email,
            ),
            const SizedBox(height: 16),

            // Phone with localized validator
            FormFields<String>(
              label: 'Phone',
              formType: FormType.phone,
              isRequired: true,
              validator: FormFieldValidators.phone(_phone, l10n),
              onChanged: (value) => setState(() => _phone = value),
              currrentValue: _phone,
            ),
            const SizedBox(height: 16),

            // Password with localized validator
            FormFields<String>(
              label: 'Password',
              formType: FormType.password,
              isRequired: true,
              minLengthPassword: 8,
              validator: FormFieldValidators.minLength(
                'Password',
                8,
                l10n: l10n,
              ),
              onChanged: (value) => setState(() => _password = value),
              currrentValue: _password,
            ),
            const SizedBox(height: 32),

            // Submit button with localized text
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.get('formSubmitted')),
                  ),
                );
              },
              child: Text(l10n.get('submit')),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Troubleshooting

**Q: Validation messages still show in English**

A: Make sure `FormFieldsLocalizationsDelegate()` is added first in `localizationsDelegates`:

```dart
localizationsDelegates: const [
  FormFieldsLocalizationsDelegate(),  // Must be first!
  GlobalMaterialLocalizations.delegate,
  // ...
]
```

**Q: How do I get all available keys?**

A: Check the language files:
- [localization/languages/en_us.dart](lib/src/localization/languages/en_us.dart)
- [localization/languages/id_id.dart](lib/src/localization/languages/id_id.dart)

**Q: Can I mix multiple languages in one screen?**

A: No, the locale is set app-wide. To use different languages, change the app locale and rebuild.

**Q: What if a translation key is missing?**

A: The package will return the key name as a fallback. Ensure all keys from `en_us.dart` are present in new language files.

## Contributing Translations

We welcome translations for new languages! To contribute:

1. Create a language file with all keys and translations
2. Test thoroughly in your language
3. Submit a
 PR with the new language file and registration

**Popular languages to contribute:**
- Spanish (es_ES / es_MX)
- French (fr_FR)
- German (de_DE)
- Portuguese (pt_BR)
- Chinese (zh_CN)
- Japanese (ja_JP)
- Russian (ru_RU)
- And more!

## Performance Notes

- Localization has minimal performance impact
- Translations are loaded once at app startup
- Language switching requires app rebuild
- Custom overrides with `hintText` or `validator` parameters take precedence over localized strings

## Support

For issues or questions:
- Create a GitHub issue
- Check the example app for implementation details
- Refer to [Flutter Localization Documentation](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)

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
