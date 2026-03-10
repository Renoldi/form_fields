# Form Fields Localization Guide

The Form Fields package provides comprehensive multi-language support for all validation messages, error text, and UI elements. **US English is the default language**, with built-in support for Indonesian and easy addition of new languages.

---

## 📑 Navigation

- [Supported Languages](#supported-languages) — Current language support
- [Quick Start](#quick-start) — Get localization working in 3 steps
- [Common Usage](#common-usage) — Common localization patterns
- [Adding Custom Languages](#adding-custom-languages) — Add Spanish, French, or any language to your project
- [Manually Setting Language](#manually-setting-language) — Three approaches to control app language: direct config, runtime switching, and state management
- [Advanced Features](#advanced-features) — Complete examples, testing, and advanced usage
- [Troubleshooting](#troubleshooting) — Common issues and solutions
- [Contributing](#contributing) — Help translate to your language

---

## Supported Languages

| Language         | Code               | Status       | Count       |
| ---------------- | ------------------ | ------------ | ----------- |
| 🇺🇸 English (US)  | `en_US`            | ✅ Default   | 50+ strings |
| 🇮🇩 Indonesian    | `id_ID`            | ✅ Included  | 50+ strings |
| 🌍 Your Language | `{lang}_{COUNTRY}` | ➕ Add yours | -           |

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

---

## Manually Setting Language

There are three approaches to manually control your app's language. Choose based on your requirements:

### **Option 1: Direct MaterialApp Configuration** (Simplest)

Set the `locale` property directly in `MaterialApp` for a fixed language:
// Simple getters
String cancel = l10n.cancel; // "CANCEL" (en) or "BATAL" (id)
MaterialApp(
locale: const Locale('id', 'ID'), // Set to Indonesian
// locale: const Locale('en', 'US'), // Or English
localizationsDelegates: const [
FormFieldsLocalizationsDelegate(),
GlobalMaterialLocalizations.delegate,
GlobalWidgetsLocalizations.delegate,
],
supportedLocales: FormFieldsLocalizations.supportedLocales,
home: const HomePage(),
)

````

✅ **Use when**: Language is set once at app start and doesn't need to change.

---

### **Option 2: Runtime Language Switching** (StatefulWidget)

Enable users to switch language without restarting the app:

```dart
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  // Static accessor to call setLocale from anywhere
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
✅ **Search/Filter Hints** - `"Search..."` / `"Cari..."`
✅ **Button Text** - OK, Cancel, Done
✅ **Field Error Messages** - Email, phone, password validation
ElevatedButton(
  onPressed: () {
    MyApp.of(context).setLocale(const Locale('id', 'ID'));  // Indonesian
  },
  child: const Text('Switch to Indonesian'),
)

---
✅ **Use when**: Users can change language from settings or a language selector.
## Adding Custom Languages
---
If you've imported the `form_fields` package into your project and need to add a language not included in the package (e.g., Spanish, French, Portuguese), follow these steps:
### **Option 3: State Management with Provider** (Recommended)
### Step 1: Create a Custom Language File
Use Provider (or another state manager) for persistent language settings:
Create a new file in your project's `lib/localization/` directory (or any location you prefer):

// 1. Create AppStateNotifier
class AppStateNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');
```dart
  Locale get locale => _locale;
  static const Map<String, String> strings = {
  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
    // Optional: Save to SharedPreferences for persistence
  }
    'ok': 'ACEPTAR',
    'done': 'HECHO',
// 2. Wrap app with ChangeNotifierProvider
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateNotifier(),
      child: const MyApp(),
    ),
  );
}
    'select': 'Seleccionar {label}',
// 3. Use locale in MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
    'searchHint': 'Buscar...',
    'typeToSearch': 'Escribe para buscar {label}...',
    'noResultsFound': 'No hay resultados',
    final appState = context.watch<AppStateNotifier>();


      locale: appState.locale,
    'fieldTypeString': 'texto',
    'fieldTypeEmail': 'correo electrónico',
    'fieldTypePhone': 'teléfono',
    'fieldTypePassword': 'contraseña',
    'fieldTypeNumber': 'número',
      supportedLocales: FormFieldsLocalizations.supportedLocales,

    // === VALIDATION - REQUIRED & GENERAL ===
    'required': '{label} es obligatorio',
    'enterPrefix': 'Ingresa ',
    'enter': 'Ingresa {label}',
// 4. Switch language from anywhere in your app
ElevatedButton(
  onPressed: () {
    context.read<AppStateNotifier>().setLocale(const Locale('id', 'ID'));
  },
  child: const Text('Switch to Indonesian'),
)
    'emailRequired': 'El correo es obligatorio',

✅ **Use when**: You need persistent language settings across app restarts, or complex state management.

---

### Supported Locales

| Language | Locale Code | Usage |
|----------|-------------|-------|
| 🇺🇸 English (US) | `Locale('en', 'US')` | Default |
| 🇮🇩 Indonesian | `Locale('id', 'ID')` | Included |
| 🌍 Custom | `Locale('xx', 'XX')` | See [Adding Custom Languages](#adding-custom-languages) |

---

### Date/Time Picker Locale Behavior

Date and time pickers automatically follow your app's selected language:

```dart
// Automatic: Picker uses app's current locale
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  currrentValue: _birthDate,
  onChanged: (value) => setState(() => _birthDate = value),
  // If app locale is Indonesian, picker shows in Indonesian
)

// Manual override: Force specific locale for this field
FormFields<DateTime>(
  label: 'Birth Date',
  formType: FormType.date,
  pickerLocale: 'en_US',  // Force English picker
  currrentValue: _birthDate,
  onChanged: (value) => setState(() => _birthDate = value),
)
````

**Default Behavior**: When `pickerLocale` is **not specified**, the picker automatically uses the app's current locale.

---

## Advanced Features

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

````

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
````

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

````

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
````

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

We welcome translations! Follow this comprehensive guide to add a new language directly to the plugin.

---

### Step-by-Step Guide: Adding a New Language

#### Step 1: Create the Language File

Copy the English reference file and translate all values:

```bash
# Navigate to the plugin directory
cd form_fields_package/lib/src/localization/languages/

# Copy English as template
cp en_us.dart es_es.dart  # Example: Spanish (Spain)
```

Edit the new file `es_es.dart`:

```dart
/// Spanish (Spain) localization strings for form fields package
library;

const Map<String, String> esESStrings = {
  // Common UI
  'cancel': 'Cancelar',
  'save': 'Guardar',
  'submit': 'Enviar',
  'clear': 'Limpiar',
  'selectPrefix': 'Seleccionar ',
  'enterPrefix': 'Ingresar ',
  'searchHint': 'Buscar...',

  // Validation - Required
  'required': '{label} es obligatorio',
  'selectRequired': 'Por favor selecciona {label}',
  'enterRequired': 'Por favor ingresa {label}',

  // Validation - Format
  'enterValidEmail': 'Por favor ingresa una dirección de correo válida',
  'enterValidPhone': 'Por favor ingresa un número de teléfono válido',
  'enterValidInteger': 'Por favor ingresa un número entero válido para {label}',
  'enterValidNumber': 'Por favor ingresa un número válido para {label}',

  // Selection
  'select': 'Por favor selecciona {label}',
  'selectAtLeastOne': 'Por favor selecciona al menos un {label}',
  'selectAtLeast': 'Por favor selecciona al menos {value} elementos',
  'selectAtMost': 'Por favor selecciona como máximo {value} elementos',
  'noItemsFound': 'No se encontraron elementos',
  'selectAll': 'Seleccionar Todo',
  'deselectAll': 'Deseleccionar Todo',
  'itemCount': '{value} elementos seleccionados',

  // Checkbox
  'checkboxRequired': 'Por favor selecciona al menos un {label}',
  'selectOptions': 'Seleccionar opciones',
  'cbLabelInBorder': 'Etiqueta Oculta (InBorder)',

  // Radio
  'radioRequired': 'Por favor selecciona {label}',
  'selectOption': 'Seleccionar una opción',

  // Dropdown
  'dropdownRequired': 'Por favor selecciona {label}',
  'selectFromList': 'Seleccionar de la lista',

  // Password
  'passwordRequired': 'La contraseña es obligatoria',
  'passwordMinLength': 'La contraseña debe tener al menos {value} caracteres',
  'verificationLength': 'Por favor ingresa un código de verificación de {value} dígitos',

  // Optional/Labels
  'optional': '(opcional)',
  'optionalLabel': '(opcional)',
  'notSet': 'No establecido',
};
```

**Important**:

- Keep **all keys** exactly the same as `en_us.dart`
- Only translate the **values**
- Preserve placeholder syntax: `{label}`, `{value}`, `{min}`, `{max}`
- Use proper grammar and cultural conventions for your language

---

#### Step 2: Register the Language

Edit `lib/src/localization/form_fields_localizations.dart`:

```dart
import 'package:flutter/material.dart';
import 'languages/en_us.dart';
import 'languages/id_id.dart';
import 'languages/es_es.dart';  // ← Add your import here

/// Localization class for form fields package
class FormFieldsLocalizations {
  // ... existing code ...

  /// Map of supported languages
  static final Map<String, Map<String, String>> _supportedLanguages = {
    'en_US': enUSStrings,
    'id_ID': idIDStrings,
    'es_ES': esESStrings,  // ← Add your language here
    // Add more languages below
  };

  // ... rest of the code ...
}
```

---

#### Step 3: Add Simple Code Mapping (Optional but Recommended)

For user convenience, add simple language code mapping in `lib/src/form_fields.dart`:

Find the `_getLocalizations()` method and update the `simpleCodeMap`:

```dart
/// Gets localization - from custom locale if provided, otherwise from context
FormFieldsLocalizations _getLocalizations(BuildContext context) {
  if (widget.locale != null && widget.locale!.isNotEmpty) {
    String localeCode = widget.locale!;

    // Support simple language codes (e.g., 'es', 'en', 'id')
    // Map known codes to full locale format
    final simpleCodeMap = {
      'id': 'id_ID',
      'ID': 'id_ID',
      'en': 'en_US',
      'EN': 'en_US',
      'es': 'es_ES',  // ← Add your simple code mapping here
      'ES': 'es_ES',  // ← Add uppercase variant too
      // Add more simple codes here
    };

    // ... rest of the method
  }
  return FormFieldsLocalizations.of(context);
}
```

This allows users to use `locale: 'es'` instead of `locale: 'es_ES'`.

---

#### Step 4: Test Your Translation

Create a test file to verify all strings work correctly:

```dart
// test/localization/es_es_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/localization/form_fields_localizations.dart';
import 'package:form_fields/src/localization/languages/en_us.dart';
import 'package:form_fields/src/localization/languages/es_es.dart';

void main() {
  group('Spanish (es_ES) Localization', () {
    test('should have all keys from English', () {
      final enKeys = enUSStrings.keys.toSet();
      final esKeys = esESStrings.keys.toSet();

      // Check no missing keys
      final missingKeys = enKeys.difference(esKeys);
      expect(missingKeys, isEmpty,
          reason: 'Missing keys in Spanish: $missingKeys');

      // Check no extra keys
      final extraKeys = esKeys.difference(enKeys);
      expect(extraKeys, isEmpty,
          reason: 'Extra keys in Spanish: $extraKeys');
    });

    test('should load Spanish locale correctly', () {
      final locale = Locale('es', 'ES');
      final localizations = FormFieldsLocalizations.load(locale);

      expect(localizations.get('cancel'), equals('Cancelar'));
      expect(localizations.get('save'), equals('Guardar'));
      expect(localizations.getWithLabel('required', 'Email'),
          equals('Email es obligatorio'));
    });

    test('should preserve placeholder syntax', () {
      final localizations = FormFieldsLocalizations.load(Locale('es', 'ES'));

      // Test {label} placeholder
      expect(localizations.getWithLabel('required', 'Nombre'),
          contains('Nombre'));

      // Test {value} placeholder
      expect(localizations.getWithValue('passwordMinLength', 8),
          contains('8'));
    });
  });
}
```

Run the tests:

```bash
flutter test test/localization/es_es_test.dart
```

---

#### Step 5: Update Documentation

Update this file (LOCALIZATION.md) to reflect the new language:

```markdown
## Supported Languages

| Language         | Code               | Status       | Count       |
| ---------------- | ------------------ | ------------ | ----------- |
| 🇺🇸 English (US)  | `en_US`            | ✅ Default   | 50+ strings |
| 🇮🇩 Indonesian    | `id_ID`            | ✅ Included  | 50+ strings |
| 🇪🇸 Spanish       | `es_ES`            | ✅ Included  | 50+ strings |
| 🌍 Your Language | `{lang}_{COUNTRY}` | ➕ Add yours | -           |
```

---

#### Step 6: Verify Plugin Analysis

Ensure no errors or warnings:

```bash
cd form_fields_package
flutter analyze
```

Should output:

```
Analyzing form_fields_package...
No issues found! (ran in X.Xs)
```

---

#### Step 7: Test in Example App

Test the new language in the example application:

```dart
// example/lib/main.dart
MaterialApp(
  locale: const Locale('es', 'ES'),  // ← Test your new language
  localizationsDelegates: const [
    FormFieldsLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: FormFieldsLocalizations.supportedLocales,
  home: const HomePage(),
)
```

Run the example:

```bash
cd example
flutter run
```

Test various form fields to ensure:

- ✅ Validation messages appear in your language
- ✅ Placeholders are correctly replaced
- ✅ All form types work (email, password, phone, etc.)
- ✅ Error messages display properly

---

#### Step 8: Submit Pull Request (Optional)

If contributing back to the package:

1. **Fork** the repository
2. **Create branch**: `git checkout -b add-spanish-locale`
3. **Commit changes**:
   ```bash
   git add .
   git commit -m "Add Spanish (es_ES) localization"
   ```
4. **Push**: `git push origin add-spanish-locale`
5. **Create PR** with description of your translation
6. **Wait for review** and address any feedback

---

### Translation Checklist

Before submitting, verify:

- [ ] Created `{lang}_{country}.dart` file with all strings
- [ ] Imported in `form_fields_localizations.dart`
- [ ] Added to `_supportedLanguages` map
- [ ] Added simple code mapping (optional)
- [ ] All keys match `en_us.dart` exactly
- [ ] All placeholders preserved: `{label}`, `{value}`, `{min}`, `{max}`
- [ ] Translations are culturally appropriate
- [ ] Tests pass (`flutter test`)
- [ ] No analysis errors (`flutter analyze`)
- [ ] Tested in example app
- [ ] Updated documentation (LOCALIZATION.md)

---

### Popular Languages Needed

Help us support more languages! Priority translations:

- 🇪🇸 Spanish (es_ES, es_MX)
- 🇫🇷 French (fr_FR, fr_CA)
- 🇩🇪 German (de_DE)
- 🇨🇳 Chinese (zh_CN, zh_TW)
- 🇯🇵 Japanese (ja_JP)
- 🇵🇹 Portuguese (pt_BR, pt_PT)
- 🇷🇺 Russian (ru_RU)
- 🇸🇦 Arabic (ar_SA)
- 🇮🇳 Hindi (hi_IN)
- 🇰🇷 Korean (ko_KR)
- 🇮🇹 Italian (it_IT)
- 🇳🇱 Dutch (nl_NL)
- 🇹🇷 Turkish (tr_TR)
- 🇵🇱 Polish (pl_PL)
- 🇻🇳 Vietnamese (vi_VN)
- 🇹🇭 Thai (th_TH)

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
