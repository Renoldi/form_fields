import 'package:flutter/foundation.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/config/error_type.dart';

class ViewModel extends ChangeNotifier {
  String? _errorMessage;
  ErrorType? _errorType;
  String _username = 'emilys';
  String _password = 'emilyspass';
  bool _isLoading = false;
  bool _useBlockingLoadingDialog = false;

  String? get errorMessage => _errorMessage;
  ErrorType? get errorType => _errorType;
  String get username => _username;
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get useBlockingLoadingDialog => _useBlockingLoadingDialog;

  bool get canSubmit =>
      _username.trim().isNotEmpty && _password.trim().isNotEmpty;

  void notifyView() {
    notifyListeners();
  }

  void updateUsername(String value) {
    if (_username == value) return;
    _username = value;
    if (_errorMessage != null) {
      _errorMessage = null;
      _errorType = null;
    }
    notifyListeners();
  }

  void updatePassword(String value) {
    if (_password == value) return;
    _password = value;
    if (_errorMessage != null) {
      _errorMessage = null;
      _errorType = null;
    }
    notifyListeners();
  }

  void setError(String message, {ErrorType type = ErrorType.server}) {
    _errorMessage = message;
    _errorType = type;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  Future<User> login() {
    return User.login(
      username: _username.trim(),
      password: _password.trim(),
    );
  }

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void setLoadingMode({required bool useBlockingDialog}) {
    if (_useBlockingLoadingDialog == useBlockingDialog) return;
    _useBlockingLoadingDialog = useBlockingDialog;
    notifyListeners();
  }
}
