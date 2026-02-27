import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  login(name: 'login', path: '/login', title: 'Login'),
  menu(name: 'menu', path: '/menu', title: 'Menu'),
  formFields(name: 'form_fields', path: '/form-fields', title: 'FormFields'),
  dropdown(name: 'dropdown', path: '/dropdown', title: 'Dropdown'),
  dropdownMulti(
    name: 'dropdown_multi',
    path: '/dropdown-multi',
    title: 'Dropdown Multi',
  ),
  radioButton(
      name: 'radio_button', path: '/radio-button', title: 'Radio Button'),
  checkbox(name: 'checkbox', path: '/checkbox', title: 'Checkbox'),
  customClass(
      name: 'custom_class', path: '/custom-class', title: 'Custom Class'),
  validation(name: 'validation', path: '/validation', title: 'Validation'),
  settings(name: 'settings', path: '/settings', title: 'Settings'),
  profile(name: 'profile', path: '/profile', title: 'Profile'),
  changePassword(
    name: 'change_password',
    path: '/change-password',
    title: 'Change Password',
  ),
  language(name: 'language', path: '/language', title: 'Language'),
  appInfo(name: 'app_info', path: '/app-info', title: 'App Info');

  final String name;
  final String path;
  final String title;

  const AppRoute({
    required this.name,
    required this.path,
    required this.title,
  });
}

extension GoRouterExtensions on BuildContext {
  void goToRoute(AppRoute route) => goNamed(route.name);

  Future<T?> pushRoute<T>(AppRoute route) => push<T>(route.path);
}
