import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/config/error_position.dart';

/// Manages global app state including locale preference and authentication
class AppStateNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');
  bool _isLoggedIn = false;
  bool _isLoadingUser = false;
  User? _currentUser;
  String? _userError;
  String _accessToken = '';
  String _refreshToken = '';
  bool _isInitialized = false;
  ErrorPosition _errorPosition = ErrorPosition.top;

  /// Use package-level `DioUtil` for HTTP helpers

  // SharedPreferences keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUser = 'current_user';

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

      // Try to load cached user (if any) to avoid empty UI before verification
      final userJson = prefs.getString(_keyUser);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final map = jsonDecode(userJson) as Map<String, dynamic>;
          _currentUser = User.fromJson(map);
        } catch (_) {
          _currentUser = null;
        }
      }

      // Load error position preference
      final errorPosString = prefs.getString('error_position');
      if (errorPosString != null) {
        _errorPosition = ErrorPositionExtension.fromString(errorPosString);
      }

      // Verify token if logged in
      if (_isLoggedIn && _accessToken.isNotEmpty) {
        DioUtil.setAuthToken(_accessToken);

        // Try to verify the token by fetching user data
        try {
          final user = await User.getMe(accessToken: _accessToken);
          // If API returns invalid user data (e.g. literal "null" fields),
          // treat as invalid token and clear auth so user must re-login.
          if (user.displayName == null) {
            _isLoggedIn = false;
            _accessToken = '';
            _refreshToken = '';
            _currentUser = null;
            DioUtil.clearAuthToken();
            await _clearAuthState();
          } else {
            _currentUser = user;
            _userError = null;
          }
        } catch (e) {
          // Token is invalid, clear stored auth
          _isLoggedIn = false;
          _accessToken = '';
          _refreshToken = '';
          _currentUser = null;
          DioUtil.clearAuthToken();
          await _clearAuthState();
        }
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
      if (_currentUser != null) {
        try {
          await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));
        } catch (_) {}
      } else {
        await prefs.remove(_keyUser);
      }
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
      await prefs.remove(_keyUser);
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

  ErrorPosition get errorPosition => _errorPosition;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setErrorPosition(ErrorPosition position) {
    _errorPosition = position;
    // Save to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('error_position', position.toStorageString());
    });
    notifyListeners();
  }

  /// Update app state after successful login with User class
  void updateUserAfterLogin({required User user}) {
    _currentUser = user;
    _userError = null;
    _isLoggedIn = true;
    _accessToken = user.accessToken ?? '';
    _refreshToken = user.refreshToken ?? '';

    // Set auth token in global HTTP service
    if (_accessToken.isNotEmpty) {
      DioUtil.setAuthToken(_accessToken);
    }

    // Save auth state to persistent storage
    _saveAuthState();

    // Subscribe to topic(s) on successful login using user id.
    try {
      if (user.id != null) {
        FCMService.instance.subscribeToTopic(user.id.toString());
      }
    } catch (_) {}

    notifyListeners();
  }

  /// Update user data from User.getMe() or User.updateMe()
  void updateUserData(User user) {
    _currentUser = user;
    _userError = null;

    // Update tokens if provided
    if (user.accessToken != null && user.accessToken!.isNotEmpty) {
      _accessToken = user.accessToken!;
      DioUtil.setAuthToken(_accessToken);
    }
    if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
      _refreshToken = user.refreshToken!;
    }

    notifyListeners();
    // persist updated user
    _saveAuthState();
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
      final user = await User.login(username: username, password: password);
      // Centralize state updates so tokens are saved and auth persisted
      updateUserAfterLogin(user: user);
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
    final username = _currentUser?.username ?? 'kminchelle';
    final password = '0lelplR';

    _setUserLoading(true);
    try {
      final user = accessToken.isNotEmpty
          ? await User.getMe(accessToken: accessToken)
          : await User.login(username: username, password: password);
      _currentUser = user;
      _userError = null;

      // Update auth token in global HTTP service
      if (_accessToken.isNotEmpty) {
        DioUtil.setAuthToken(_accessToken);
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

      // Clear auth state if token is invalid
      _isLoggedIn = false;
      _accessToken = '';
      _refreshToken = '';
      _currentUser = null;

      // Clear auth token from global HTTP service and storage
      DioUtil.clearAuthToken();
      await _clearAuthState();

      return false;
    } finally {
      _setUserLoading(false);
    }
  }

  void logout() {
    final int? loggedOutUserId = _currentUser?.id;

    _isLoggedIn = false;
    _currentUser = null;
    _userError = null;
    _accessToken = '';
    _refreshToken = '';

    // Clear auth token from global HTTP service
    DioUtil.clearAuthToken();

    // Clear auth state from persistent storage
    _clearAuthState();

    // Unsubscribe from topics on logout using previous user id
    try {
      if (loggedOutUserId != null) {
        FCMService.instance.unsubscribeFromTopic(loggedOutUserId.toString());
      }
    } catch (_) {}

    // Defer notifying listeners to avoid calling setState/markNeedsBuild
    // during the framework's build phase (which can happen when logout is
    // triggered during route redirects). Schedule a post-frame callback
    // so widgets are safe to rebuild.
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          notifyListeners();
        } catch (_) {}
      });
    } catch (_) {
      // If WidgetsBinding isn't available for some reason, fall back to
      // immediate notification.
      try {
        notifyListeners();
      } catch (_) {}
    }
  }

  void _setUserLoading(bool value) {
    _isLoadingUser = value;
    notifyListeners();
  }

  String _formatUserError(Object error) {
    return 'Login failed. Please check your credentials.';
  }
}
