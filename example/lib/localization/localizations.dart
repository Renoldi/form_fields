import 'package:flutter/material.dart' as flutter;
import 'languages/en.dart';
import 'languages/id.dart';

/// Localization class for example app
class Localizations {
  final flutter.Locale locale;
  final Map<String, String> _localizedStrings;

  Localizations(this.locale, this._localizedStrings);

  /// Get localized string by key
  String get(String key) {
    final localized = _localizedStrings[key];
    if (localized != null) return localized;

    final englishFallback = enStrings[key];
    if (englishFallback != null) return englishFallback;

    return _humanizeKey(key);
  }

  String _humanizeKey(String key) {
    if (key.isEmpty) return key;

    final withSpaces = key
        .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();

    if (withSpaces.isEmpty) return key;

    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }

  /// Get the current instance from context
  static Localizations of(flutter.BuildContext context) {
    return flutter.Localizations.of<Localizations>(context, Localizations) ??
        load(flutter.Localizations.localeOf(context));
  }

  /// Load localization for specific locale
  static Localizations load(flutter.Locale locale) {
    final key = '${locale.languageCode}_${locale.countryCode}';
    final strings = _supportedLanguages[key] ?? enStrings;
    return Localizations(locale, strings);
  }

  /// Map of supported languages
  static final Map<String, Map<String, String>> _supportedLanguages = {
    'en_US': enStrings,
    'id_ID': idStrings,
  };

  /// Get list of supported locales
  static List<flutter.Locale> get supportedLocales {
    return _supportedLanguages.keys.map((key) {
      final parts = key.split('_');
      return flutter.Locale(parts[0], parts[1]);
    }).toList();
  }
}

/// Localization delegate for example app
class LocalizationsDelegate
    extends flutter.LocalizationsDelegate<Localizations> {
  const LocalizationsDelegate();

  @override
  bool isSupported(flutter.Locale locale) =>
      ['en', 'id'].contains(locale.languageCode);

  @override
  Future<Localizations> load(flutter.Locale locale) async {
    return Localizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate old) => false;
}

/// Extension for easy access to localization
extension LocalizationExtension on flutter.BuildContext {
  /// Get Localizations instance
  Localizations get l => Localizations.of(this);

  /// Translate a key (shorthand for Localizations.of(context).get(key))
  String tr(String key) => Localizations.of(this).get(key);
}
