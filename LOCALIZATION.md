# Form Fields Localization Guide

The Form Fields package provides comprehensive multi-language support for all validation messages, error text, and UI elements. **US English is the default language**, with built-in support for Indonesian and easy addition of new languages.

---

## 📑 Navigation

- [Supported Languages](#supported-languages) — Current language support
- [Quick Start](#quick-start) — Get localization working in 3 steps
- [Common Usage](#common-usage) — Common localization patterns
- [Adding Custom Languages](#adding-custom-languages) — Add Spanish, French, or any language to your project
- [Advanced Features](#advanced-features) — Runtime switching, custom validators, API reference
- [Troubleshooting](#troubleshooting) — Common issues and solutions
- [Contributing](#contributing) — Help translate to your language

---

## Supported Languages

| Language | Code | Status | Count |
|----------|------|--------|-------|
| 🇺🇸 English (US) | `en_US` | ✅ Default | 50+ strings |
| 🇮🇩 Indonesian | `id_ID` | ✅ Included | 50+ strings |
| 🌍 Your Language | `{lang}_{COUNTRY}` | ➕ Add yours | - |

---

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

---

## Common Usage

### Localized Validators

All validators support automatic localization. Access via `FormFieldsLocalizations.of(context)`:

```dart
final l10n = FormFieldsLocalizations.of(context);

// Email validator
FormFieldValidators.email(label, l10n);

// Phone validator
FormFieldValidators.phone(label, l10n);

// Password validator
FormFieldValidators.password(label, l10n: l10n);

// Number validator
FormFieldValidators.number(label, l10n: l10n);

// Length validators
FormFieldValidators.minLength(label, 8, l10n: l10n);
FormFieldValidators.maxLength(label, 20, l10n: l10n);

// Range validator
FormFieldValidators.range(label, 18, 65, l10n: l10n);

// Pattern validator
FormFieldValidators.pattern(label, '^[a-z]+\$', l10n: l10n);
```

### Accessing Localized Strings

Get localized text in your code:

```dart
final l10n = FormFieldsLocalizations.of(context);

// Simple getters
String cancel = l10n.cancel;          // "CANCEL" (en) or "BATAL" (id)
String ok = l10n.ok;                  // "OK"
String done = l10n.done;              // "DONE" (en) or "SELESAI" (id)
String search = l10n.searchHint;      // "Search..." (en) or "Cari..." (id)

// With label parameter
String msg = l10n.enter('Email');     // "Enter Email" (en) or "Masukkan Email" (id)
String msg = l10n.select('Country');  // "Select Country" (en) or "Pilih Country" (id)

// With value parameter
String msg = l10n.getWithValue('passwordMinLength', 8);
// "Password must be at least 8 characters" (en)
// "Kata sandi harus minimal 8 karakter" (id)

// With multiple parameters
String msg = l10n.getWithParams('betweenValue', {
  'label': 'Age',
  'min': 18,
  'max': 65,
});
// "Age must be between 18 and 65" (en)
// "Umur harus antara 18 dan 65" (id)

// Get by key
l10n.get('required')           // Generic getter
l10n.getWithLabel('key', 'Phone')    // Replace {label}
```

### Automatically Localized Elements

These adapt to your app's locale:

✅ **Validation Messages** - `"Email is required"` / `"Email wajib diisi"`  
✅ **Search/Filter Hints** - `"Search..."` / `"Cari..."`  
✅ **Button Text** - OK, Cancel, Done  
✅ **Field Error Messages** - Email, phone, password validation  
✅ **Selection Dialogs** - Dropdown and multi-select hints  

---

## Adding Custom Languages

If you've imported the `form_fields` package into your project and need to add a language not included in the package (e.g., Spanish, French, Portuguese), follow these steps:

### Step 1: Create a Custom Language File

Create a new file in your project's `lib/localization/` directory (or any location you prefer):

**Example: `lib/localization/es_es_localizations.dart`** (Spanish)

```dart
/// Spanish (Spain) localization strings for FormFields
class EsESLocalizations {
  static const Map<String, String> strings = {
    // === COMMON ACTIONS ===
    'cancel': 'CANCELAR',
    'ok': 'ACEPTAR',
    'done': 'HECHO',
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
    'enterValidEmail': 'Ingresa una dirección de correo válida',
    'emailRequired': 'El correo es obligatorio',

    // === PHONE VALIDATION ===
    'enterValidPhone': 'Ingresa un número de teléfono válido',
    'phoneRequired': 'El número de teléfono es obligatorio',

    // === PASSWORD VALIDATION ===
    'passwordRequired': 'La contraseña es obligatoria',
    'passwordMinLength': 'La contraseña debe tener al menos {value} caracteres',
    'passwordNeedsUppercase': 'Debe contener una letra mayúscula',
    'passwordNeedsNumber': 'Debe contener un número',
    'passwordNeedsSpecialChar': 'Debe contener un carácter especial',

    // === LENGTH VALIDATION ===
    'tooShort': '{label} es demasiado corto',
    'tooLong': '{label} es demasiado largo',

    // === RANGE & VALUE VALIDATION ===
    'minimumValue': '{label} debe ser al menos {value}',
    'maximumValue': '{label} no debe exceder {value}',
    'betweenValue': '{label} debe estar entre {min} y {max}',

    // === SELECTION/DROPDOWN ===
    'selectAtLeastOne': 'Selecciona al menos uno',
    'selectAtLeast': 'Selecciona al menos {value} elementos',
    'selectAtMost': 'Selecciona como máximo {value} elementos',

    // === ERRORS & MESSAGES ===
    'invalid': '{label} no es válido',
    'error': 'Error',
    'success': 'Éxito',
    'warning': 'Advertencia',
    'validationFailed': 'La validación falló',
  };
}
```

### Step 2: Create a Custom Localization Delegate

Create `lib/localization/custom_localizations_delegate.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'es_es_localizations.dart';

class CustomFormFieldsLocalizations extends FormFieldsLocalizations {
  final String _languageCode;
  final String _countryCode;

  CustomFormFieldsLocalizations(this._languageCode, this._countryCode);

  static const LocalizationsDelegate<FormFieldsLocalizations> delegate =
      _CustomLocalizationsDelegate();

  @override
  String get(String key, [Map<String, dynamic>? params]) {
    // Try to get from custom language first
    final localeKey = '${_languageCode}_${_countryCode}'.toUpperCase();
    
    if (localeKey == 'ES_ES') {
      String? value = EsESLocalizations.strings[key];
      if (value != null && params != null) {
        // Replace placeholders
        params.forEach((k, v) {
          value = value!.replaceAll('{$k}', v.toString());
        });
        return value!;
      }
      return value ?? key;
    }

    // Fall back to package localization
    return super.get(key, params);
  }

  static Future<CustomFormFieldsLocalizations> load(Locale locale) {
    return SynchronousFuture<CustomFormFieldsLocalizations>(
      CustomFormFieldsLocalizations(
        locale.languageCode,
        locale.countryCode ?? 'ES',
      ),
    );
  }
}

class _CustomLocalizationsDelegate
    extends LocalizationsDelegate<FormFieldsLocalizations> {
  const _CustomLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support Spanish and all package-supported locales
    return locale.languageCode == 'es' ||
        FormFieldsLocalizations.isSupported(locale);
  }

  @override
  Future<FormFieldsLocalizations> load(Locale locale) {
    if (locale.languageCode == 'es') {
      return CustomFormFieldsLocalizations.load(locale);
    }
    return FormFieldsLocalizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<FormFieldsLocalizations> old) =>
      false;
}
```

### Step 3: Update Your App Configuration

Update your `MaterialApp` in `main.dart` or your app widget:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';
import 'localization/custom_localizations_delegate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      locale: const Locale('es', 'ES'),  // Set to Spanish
      localizationsDelegates: [
        CustomFormFieldsLocalizations.delegate,  // Use custom delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),  // English
        Locale('id', 'ID'),  // Indonesian (from package)
        Locale('es', 'ES'),  // Spanish (custom)
      ],
      home: const HomePage(),
    );
  }
}
```

### Step 4: Use in Your App

Your form fields will now display in Spanish:

```dart
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _email = '';

  @override
  Widget build(BuildContext context) {
    final l10n = FormFieldsLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Aplicación')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FormFields<String>(
          label: 'Correo Electrónico',
          formType: FormType.email,
          isRequired: true,
          onChanged: (value) => setState(() => _email = value),
          currrentValue: _email,
          // Will show Spanish validation messages from custom locale
        ),
      ),
    );
  }
}
```

### Complete Translation Keys to Include

To ensure all form fields work properly in your custom language, include ALL these keys:

```dart
const Map<String, String> customLanguageStrings = {
  // Common actions
  'cancel', 'ok', 'done', 'submit', 'validate', 'select', 'selectPrefix',
  
  // Search/Filter
  'searchHint', 'typeToSearch', 'noResultsFound',
  
  // Field labels
  'fieldTypeString', 'fieldTypeEmail', 'fieldTypePhone', 'fieldTypePassword',
  'fieldTypeNumber', 'fieldTypeInteger', 'fieldTypeDate', 'fieldTypeTime',
  'fieldTypeDateRange',
  
  // Validation
  'required', 'enterPrefix', 'enter', 'enterValid',
  'enterValidEmail', 'emailRequired',
  'enterValidPhone', 'phoneRequired',
  'enterValidInteger', 'integerRequired',
  'enterValidNumber', 'numberRequired',
  
  // Password validation
  'passwordRequired', 'passwordMinLength', 'passwordTooShort',
  'passwordNeedsUppercase', 'passwordNeedsLowercase',
  'passwordNeedsNumber', 'passwordNeedsSpecialChar',
  
  // Length validation
  'tooShort', 'tooLong',
  
  // Range validation
  'minimumValue', 'maximumValue', 'betweenValue',
  
  // Selection
  'selectAtLeastOne', 'selectAtLeast', 'selectAtMost', 'selectExactly',
  
  // Date/Time
  'selectDate', 'selectTime', 'selectDateRange', 'dateRequired', 'timeRequired',
  
  // Other
  'invalid', 'invalidFormat', 'error', 'success', 'warning', 'validationFailed',
  'selectedItems', 'noItemsSelected', 'clear', 'clearAll',
};
```

### Switching Languages at Runtime

To support language switching without restarting your app:

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
      localizationsDelegates: [
        CustomFormFieldsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('id', 'ID'),
      ],
      home: const HomePage(),
    );
  }
}

// Usage in a button or menu
MyApp.of(context).setLocale(const Locale('es', 'ES')); // Switch to Spanish
```

---

## Advanced Features
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

---

## Advanced Features

### Runtime Language Switching

Change language without restarting your app using a stateful widget approach:

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
    setState(() => _locale = locale);
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
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('id', 'ID'),
      ],
      home: const HomePage(),
    );
  }
}

// Usage - Switch language from anywhere
MyApp.of(context).setLocale(const Locale('id', 'ID'));
```

### Complete Working Example

A full example of localized form validation:

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
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final l10n = FormFieldsLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            FormFields<String>(
              label: 'Email',
              formType: FormType.email,
              isRequired: true,
              validator: FormFieldValidators.email(_email, l10n),
              onChanged: (value) => setState(() => _email = value),
              currrentValue: _email,
            ),
            const SizedBox(height: 16),
            FormFields<String>(
              label: 'Password',
              formType: FormType.password,
              isRequired: true,
              minLengthPassword: 8,
              validator: FormFieldValidators.minLength('Password', 8, l10n: l10n),
              onChanged: (value) => setState(() => _password = value),
              currrentValue: _password,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.get('formSubmitted'))),
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

### Testing Different Languages

Test localization in various languages:

```dart
// Set in your app
MaterialApp(
  locale: const Locale('id', 'ID'),  // Indonesian
)

// Or add custom locales for quick testing
const List<Locale> testLocales = [
  Locale('en', 'US'),  // English
  Locale('id', 'ID'),  // Indonesian
  Locale('es', 'ES'),  // Spanish (custom)
];
```

---

## Troubleshooting

### Q: Translations still show in English

**A:** Make sure `FormFieldsLocalizationsDelegate()` is **first** in `localizationsDelegates`:

```dart
localizationsDelegates: const [
  FormFieldsLocalizationsDelegate(),  // ✓ Must be first!
  GlobalMaterialLocalizations.delegate,
  // ...
]
```

### Q: How do I find all translation keys?

**A:** Check the package language files:
- [lib/src/localization/languages/en_us.dart](lib/src/localization/languages/en_us.dart) - English (reference)
- [lib/src/localization/languages/id_id.dart](lib/src/localization/languages/id_id.dart) - Indonesian

Or in your custom language, copy all keys from English.

### Q: What if a translation key is missing?

**A:** The package returns the key name as a fallback. Ensure your custom language has all keys from `en_us.dart`.

### Q: Can I mix multiple languages in one screen?

**A:** No. Localization is set app-wide. Change the app locale and rebuild the widget tree to switch languages.

### Q: What about RTL languages (Arabic, Hebrew)?

**A:** Add `supportedLocales` and handle RTL direction in your app:

```dart
MaterialApp(
  localizationsDelegates: [
    FormFieldsLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
)
```

---

## Contributing

### Help Translate the Package

We welcome translations! To contribute a new language:

1. **Copy** [lib/src/localization/languages/en_us.dart](lib/src/localization/languages/en_us.dart)
2. **Create** `lib/src/localization/languages/{lang}_{country}.dart`
3. **Translate** all values (keys stay the same)
4. **Register** in [lib/src/localization/form_fields_localizations.dart](lib/src/localization/form_fields_localizations.dart)
5. **Test** your translations thoroughly
6. **Submit** a pull request

**Popular languages needed:**
- 🇪🇸 Spanish (es_ES, es_MX)
- 🇫🇷 French (fr_FR, fr_CA)
- 🇩🇪 German (de_DE)
- 🇨🇳 Chinese (zh_CN, zh_TW)
- 🇯🇵 Japanese (ja_JP)
- 🇵🇹 Portuguese (pt_BR, pt_PT)
- 🇷🇺 Russian (ru_RU)
- 🇸🇦 Arabic (ar_SA)
- 🇮🇳 Hindi (hi_IN)

---

## Performance Notes

- **Minimal Impact**: Localization adds negligible overhead
- **Once Per App Start**: Translations load once at startup
- **Efficient Lookup**: String lookups use map-based access  
- **Custom Overrides**: Field parameters (validator, hintText) override localized strings

---

## Need Help?

- **Issues?** Create a [GitHub issue](https://github.com/enerren/form_fields/issues)
- **Examples?** Check [example/lib](example/lib) folder
- **Flutter Docs?** See [Flutter Localization](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)

---

**Happy translating! 🌍**
