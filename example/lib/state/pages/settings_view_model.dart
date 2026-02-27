import 'package:flutter/material.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';

class SettingsViewModel extends ChangeNotifier {
  final AppStateNotifier _appState;

  SettingsViewModel(this._appState) {
    _appState.addListener(notifyListeners);
  }

  Locale get locale => _appState.locale;

  String get languageLabel => _appState.locale.languageCode == 'id'
      ? 'Indonesian (ID)'
      : 'English (US)';

  void logout(VoidCallback onLogout) {
    _appState.logout();
    onLogout();
  }

  @override
  void dispose() {
    _appState.removeListener(notifyListeners);
    super.dispose();
  }
}
