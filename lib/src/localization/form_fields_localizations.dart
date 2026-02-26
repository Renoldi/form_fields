import 'package:flutter/material.dart';
import 'languages/en_us.dart';
import 'languages/id_id.dart';

/// Localization class for form fields package
/// Provides multi-language support with US English as default
class FormFieldsLocalizations {
  final Locale locale;
  final Map<String, String> _localizedStrings;

  FormFieldsLocalizations(this.locale, this._localizedStrings);

  /// Get localized string by key
  String get(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// Get localized string with dynamic label replacement
  String getWithLabel(String key, String label) {
    final template = _localizedStrings[key] ?? key;
    return template.replaceAll('{label}', label);
  }

  /// Get localized string with dynamic value replacement
  String getWithValue(String key, dynamic value) {
    final template = _localizedStrings[key] ?? key;
    return template.replaceAll('{value}', value.toString());
  }

  /// Get localized string with multiple replacements
  String getWithParams(String key, Map<String, dynamic> params) {
    String template = _localizedStrings[key] ?? key;
    params.forEach((paramKey, paramValue) {
      template = template.replaceAll('{$paramKey}', paramValue.toString());
    });
    return template;
  }

  /// Get the current instance from context (returns default if not found)
  static FormFieldsLocalizations of(BuildContext context) {
    final localizations = Localizations.of<FormFieldsLocalizations>(
      context,
      FormFieldsLocalizations,
    );

    if (localizations != null) {
      return localizations;
    }

    // If not found in Localizations, load based on current locale
    final currentLocale = Localizations.localeOf(context);
    return load(currentLocale);
  }

  /// Check if locale is supported
  static bool isSupported(Locale locale) {
    return _supportedLanguages
        .containsKey('${locale.languageCode}_${locale.countryCode}');
  }

  /// Load localization for specific locale
  static FormFieldsLocalizations load(Locale locale) {
    final key = '${locale.languageCode}_${locale.countryCode}';
    final strings = _supportedLanguages[key] ?? enUSStrings;
    return FormFieldsLocalizations(locale, strings);
  }

  /// Map of supported languages
  static final Map<String, Map<String, String>> _supportedLanguages = {
    'en_US': enUSStrings,
    'id_ID': idIDStrings,
    // Add more languages here in the future
    // 'es_ES': esESStrings,
    // 'fr_FR': frFRStrings,
    // 'zh_CN': zhCNStrings,
    // 'ja_JP': jaJPStrings,
  };

  /// Get list of supported locales
  static List<Locale> get supportedLocales {
    return _supportedLanguages.keys.map((key) {
      final parts = key.split('_');
      return Locale(parts[0], parts[1]);
    }).toList();
  }

  // Convenience getters for common strings
  String get cancel => get('cancel');
  String get searchHint => get('searchHint');
  String get selectPrefix => get('selectPrefix');
  String get enterPrefix => get('enterPrefix');

  String select(String label) => getWithLabel('select', label);
  String selectAtLeastOne(String label) =>
      getWithLabel('selectAtLeastOne', label);
  String selectAtLeast(int count) => getWithValue('selectAtLeast', count);
  String selectAtMost(int count) => getWithValue('selectAtMost', count);
  String enter(String label) => getWithLabel('enter', label);
  String enterValid(String type, String label) =>
      getWithParams('enterValid', {'type': type, 'label': label});
  String passwordMinLength(int length) =>
      getWithValue('passwordMinLength', length);
}

/// Delegate for FormFieldsLocalizations
class FormFieldsLocalizationsDelegate
    extends LocalizationsDelegate<FormFieldsLocalizations> {
  const FormFieldsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return FormFieldsLocalizations.isSupported(locale);
  }

  @override
  Future<FormFieldsLocalizations> load(Locale locale) async {
    return FormFieldsLocalizations.load(locale);
  }

  @override
  bool shouldReload(FormFieldsLocalizationsDelegate old) => false;
}
