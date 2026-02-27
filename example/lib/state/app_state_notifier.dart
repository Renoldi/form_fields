import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/data/services/http_service.dart';

/// Manages global app state including locale preference and authentication
class AppStateNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');
  bool _isLoggedIn = false;
  bool _isLoadingUser = false;
  User? _currentUser;
  String? _userError;
  String _lastUsername = '';
  String _lastPassword = '';
  String _accessToken = '';
  String _refreshToken = '';
  bool _isInitialized = false;

  /// Global HTTP service instance
  final HttpService httpClient = HttpService.instance;

  // SharedPreferences keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyIsLoggedIn = 'is_logged_in';

  AppStateNotifier() {
    _initializeAuth();
  }

  /// Initialize authentication state from saved preferences
  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_keyAccessToken) ?? '';
      _refreshToken = prefs.getString(_keyRefreshToken) ?? '';
      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      // Set auth token in HTTP service if available
      if (_accessToken.isNotEmpty) {
        httpClient.setAuthToken(_accessToken);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Save authentication state to persistent storage
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, _accessToken);
      await prefs.setString(_keyRefreshToken, _refreshToken);
      await prefs.setBool(_keyIsLoggedIn, _isLoggedIn);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear authentication state from persistent storage
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyIsLoggedIn);
    } catch (e) {
      // Handle error silently
    }
  }

  Locale get locale => _locale;

  bool get isLoggedIn => _isLoggedIn;

  bool get isLoadingUser => _isLoadingUser;

  bool get isInitialized => _isInitialized;

  User? get currentUser => _currentUser;

  String? get userError => _userError;

  String get accessToken => _accessToken;

  String get refreshToken => _refreshToken;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  /// Update app state after successful login with User class
  void updateUserAfterLogin({
    required User user,
    required String username,
    required String password,
  }) {
    _currentUser = user;
    _userError = null;
    _isLoggedIn = true;
    _lastUsername = username;
    _lastPassword = password;
    _accessToken = user.accessToken ?? '';
    _refreshToken = user.refreshToken ?? '';

    // Set auth token in global HTTP service
    if (_accessToken.isNotEmpty) {
      httpClient.setAuthToken(_accessToken);
    }

    // Save auth state to persistent storage
    _saveAuthState();

    notifyListeners();
  }

  /// Update user data from User.getMe() or User.updateMe()
  void updateUserData(User user) {
    _currentUser = user;
    _userError = null;

    // Update tokens if provided
    if (user.accessToken != null && user.accessToken!.isNotEmpty) {
      _accessToken = user.accessToken!;
      httpClient.setAuthToken(_accessToken);
    }
    if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
      _refreshToken = user.refreshToken!;
    }

    notifyListeners();
  }

  Future<bool> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      _userError = 'Username and password are required.';
      notifyListeners();
      return false;
    }

    _setUserLoading(true);
    try {
      final user = await User.login(
        username: username,
        password: password,
      );
      _currentUser = user;
      _userError = null;
      _isLoggedIn = true;

      // Set auth token in global HTTP service
      if (_accessToken.isNotEmpty) {
        httpClient.setAuthToken(_accessToken);
      }

      _lastUsername = username;
      _lastPassword = password;
      _accessToken = user.accessToken ?? '';
      _refreshToken = user.refreshToken ?? '';
      return true;
    } catch (error) {
      _currentUser = null;
      _userError = _formatUserError(error);
      _isLoggedIn = false;
      return false;
    } finally {
      _setUserLoading(false);
    }
  }

  Future<bool> refreshUser() async {
    final accessToken = _accessToken.isNotEmpty
        ? _accessToken
        : (_currentUser?.accessToken ?? '');
    final username = _lastUsername.isEmpty ? 'kminchelle' : _lastUsername;
    final password = _lastPassword.isEmpty ? '0lelplR' : _lastPassword;

    _setUserLoading(true);
    try {
      final user = accessToken.isNotEmpty
          ? await User.getMe(accessToken: accessToken)
          : await User.login(
              username: username,
              password: password,
            );
      _currentUser = user;
      _userError = null;

      // Update auth token in global HTTP service
      if (_accessToken.isNotEmpty) {
        httpClient.setAuthToken(_accessToken);
      }

      if (user.accessToken != null && user.accessToken!.isNotEmpty) {
        _accessToken = user.accessToken!;
      }
      if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
        _refreshToken = user.refreshToken!;
      }
      return true;
    } catch (error) {
      _userError = _formatUserError(error);

      // Clear auth token from global HTTP service
      httpClient.clearAuthToken();

      return false;
    } finally {
      _setUserLoading(false);
    }
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _userError = null;
    _accessToken = '';
    _refreshToken = '';

    // Clear auth token from global HTTP service
    httpClient.clearAuthToken();

    // Clear auth state from persistent storage
    _clearAuthState();

    notifyListeners();
  }

  void _setUserLoading(bool value) {
    _isLoadingUser = value;
    notifyListeners();
  }

  String _formatUserError(Object error) {
    return 'Login failed. Please check your credentials.';
  }
}
