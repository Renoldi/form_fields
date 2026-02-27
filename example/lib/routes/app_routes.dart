import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application route definitions.
///
/// Centralizes all route names and paths for type-safe navigation
/// throughout the application. Use with [AppNavigator] extension methods
/// for navigation.
enum AppRoute {
  /// Login/authentication page
  login,

  /// Main menu/dashboard page
  menu,

  /// FormFields examples (text, number, date & time)
  formFields,

  /// Dropdown (single select) examples
  dropdown,

  /// Multi-select dropdown examples
  dropdownMulti,

  /// Radio button examples
  radioButton,

  /// Checkbox examples
  checkbox,

  /// Custom class examples
  customClass,

  /// Null/non-null validation examples
  validation,

  /// App settings
  settings,

  /// User profile page
  profile,

  /// Change password page
  changePassword,

  /// Language settings page
  language,

  /// App version/info page
  appInfo,
}

/// Extension providing route name and path generation for [AppRoute].
extension AppRouteX on AppRoute {
  /// Returns the route name used for named navigation.
  ///
  /// This is used with [GoRouter.goNamed] and [GoRouter.pushNamed].
  String get name {
    switch (this) {
      case AppRoute.login:
        return 'login';
      case AppRoute.menu:
        return 'menu';
      case AppRoute.formFields:
        return 'form-fields';
      case AppRoute.dropdown:
        return 'dropdown';
      case AppRoute.dropdownMulti:
        return 'dropdown-multi';
      case AppRoute.radioButton:
        return 'radio-button';
      case AppRoute.checkbox:
        return 'checkbox';
      case AppRoute.customClass:
        return 'custom-class';
      case AppRoute.validation:
        return 'validation';
      case AppRoute.settings:
        return 'settings';
      case AppRoute.profile:
        return 'profile';
      case AppRoute.changePassword:
        return 'change-password';
      case AppRoute.language:
        return 'language';
      case AppRoute.appInfo:
        return 'app-info';
    }
  }

  /// Returns the URL path for this route.
  ///
  /// Paths are automatically derived from the route name with a leading slash.
  String get path {
    return '/$name';
  }

  /// Returns a user-friendly title for this route.
  String get title {
    switch (this) {
      case AppRoute.login:
        return 'Login';
      case AppRoute.menu:
        return 'Menu';
      case AppRoute.formFields:
        return 'FormFields Examples';
      case AppRoute.dropdown:
        return 'Dropdown Examples';
      case AppRoute.dropdownMulti:
        return 'Multi-Select Dropdown';
      case AppRoute.radioButton:
        return 'Radio Button Examples';
      case AppRoute.checkbox:
        return 'Checkbox Examples';
      case AppRoute.customClass:
        return 'Custom Class Examples';
      case AppRoute.validation:
        return 'Null/Non-Null Validation';
      case AppRoute.settings:
        return 'Settings';
      case AppRoute.profile:
        return 'Profile';
      case AppRoute.changePassword:
        return 'Change Password';
      case AppRoute.language:
        return 'Language';
      case AppRoute.appInfo:
        return 'App Info';
    }
  }
}

/// Extension providing type-safe navigation methods on [BuildContext].
///
/// Usage:
/// ```dart
/// context.goToRoute(AppRoute.menu);
/// context.pushRoute(AppRoute.formFields);
/// ```
extension AppNavigator on BuildContext {
  /// Navigate to a route, replacing the current route in the stack.
  ///
  /// This is equivalent to calling [GoRouter.goNamed].
  void goToRoute(AppRoute route, {Object? extra}) {
    goNamed(route.name, extra: extra);
  }

  /// Push a route onto the navigation stack.
  ///
  /// This is equivalent to calling [GoRouter.pushNamed].
  Future<T?> pushRoute<T extends Object?>(AppRoute route, {Object? extra}) {
    return pushNamed<T>(route.name, extra: extra);
  }

  /// Pop the current route off the navigation stack.
  ///
  /// Returns `true` if a route was popped, `false` otherwise.
  bool goBack<T extends Object?>([T? result]) {
    if (canPop()) {
      pop(result);
      return true;
    }
    return false;
  }
}
