import 'package:flutter/material.dart';
import 'languages/en.dart';
import 'languages/id.dart';

/// Localization class for example app
class ExampleLocalizations {
  final Locale locale;
  final Map<String, String> _localizedStrings;

  ExampleLocalizations(this.locale, this._localizedStrings);

  /// Get localized string by key
  String get(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// Get the current instance from context
  static ExampleLocalizations of(BuildContext context) {
    return Localizations.of<ExampleLocalizations>(context, ExampleLocalizations) ??
        load(Localizations.localeOf(context));
  }

  /// Load localization for specific locale
  static ExampleLocalizations load(Locale locale) {
    final key = '${locale.languageCode}_${locale.countryCode}';
    final strings = _supportedLanguages[key] ?? enStrings;
    return ExampleLocalizations(locale, strings);
  }

  /// Map of supported languages
  static final Map<String, Map<String, String>> _supportedLanguages = {
    'en_US': enStrings,
    'id_ID': idStrings,
  };

  /// Get list of supported locales
  static List<Locale> get supportedLocales {
    return _supportedLanguages.keys.map((key) {
      final parts = key.split('_');
      return Locale(parts[0], parts[1]);
    }).toList();
  }
}

/// Localization delegate for example app
class ExampleLocalizationsDelegate extends LocalizationsDelegate<ExampleLocalizations> {
  const ExampleLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'id'].contains(locale.languageCode);

  @override
  Future<ExampleLocalizations> load(Locale locale) async {
    return ExampleLocalizations.load(locale);
  }

  @override
  bool shouldReload(ExampleLocalizationsDelegate old) => false;
}
