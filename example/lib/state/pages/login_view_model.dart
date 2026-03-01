import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/user.dart';

class LoginViewModel extends ChangeNotifier {
  String? errorMessage;
  String username = '';
  String password = '';

  bool get canSubmit =>
      username.trim().isNotEmpty && password.trim().isNotEmpty;

  void notify() {
    notifyListeners();
  }

  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<User> login() {
    return User.login(
      username: username.trim(),
      password: password.trim(),
    );
  }
}
