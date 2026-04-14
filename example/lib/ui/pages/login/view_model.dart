import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/config/error_type.dart';

class ViewModel extends ChangeNotifier {
  String? errorMessage;
  ErrorType? errorType;
  String username = 'emilys';
  String password = 'emilyspass';
  bool isLoading = false;

  bool get canSubmit =>
      username.trim().isNotEmpty && password.trim().isNotEmpty;

  void notify() {
    notifyListeners();
  }

  void setError(String message, {ErrorType type = ErrorType.server}) {
    errorMessage = message;
    errorType = type;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    errorType = null;
    notifyListeners();
  }

  Future<User> login() {
    return User.login(
      username: username.trim(),
      password: password.trim(),
    );
  }

  void setLoading(bool value) {
    if (isLoading == value) return;
    isLoading = value;
    notifyListeners();
  }
}
