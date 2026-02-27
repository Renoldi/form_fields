import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/user.dart';

class LoginViewModel extends ChangeNotifier {
  String? _errorMessage;
  String _username = '';
  String _password = '';

  String? get errorMessage => _errorMessage;
  String get username => _username;
  String get password => _password;

  bool get canSubmit =>
      _username.trim().isNotEmpty && _password.trim().isNotEmpty;

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setUsername(String value) {
    if (_username == value) return;
    _username = value;
    notifyListeners();
  }

  void setPassword(String value) {
    if (_password == value) return;
    _password = value;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<User> login() {
    return User.login(
      username: _username.trim(),
      password: _password.trim(),
    );
  }
}
