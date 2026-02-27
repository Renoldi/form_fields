import 'package:flutter/material.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';

class LanguageViewModel extends ChangeNotifier {
  final AppStateNotifier _appState;

  LanguageViewModel(this._appState) {
    _appState.addListener(notifyListeners);
  }

  bool get isEnglish => _appState.locale.languageCode == 'en';
  bool get isIndonesian => _appState.locale.languageCode == 'id';

  void setEnglish() {
    _appState.setLocale(const Locale('en', 'US'));
  }

  void setIndonesian() {
    _appState.setLocale(const Locale('id', 'ID'));
  }

  @override
  void dispose() {
    _appState.removeListener(notifyListeners);
    super.dispose();
  }
}
