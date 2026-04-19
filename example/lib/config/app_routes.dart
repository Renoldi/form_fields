import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  login(name: 'login', title: 'Login'),
  iconsGallery(name: 'icons_gallery', title: 'Icons Gallery'),
  menu(name: 'menu', title: 'Menu'),
  formFields(name: 'form_fields', title: 'FormFields'),
  dropdown(name: 'dropdown', title: 'Dropdown'),
  dropdownMulti(
    name: 'dropdown_multi',
    title: 'Dropdown Multi',
  ),
  radioButton(name: 'radio_button', title: 'Radio Button'),
  checkbox(name: 'checkbox', title: 'Checkbox'),
  customClass(name: 'custom_class', title: 'Custom Class'),
  validation(name: 'validation', title: 'Validation'),
  appButton(name: 'app_button', title: 'App Button'),
  loadingProgress(name: 'loading_progress', title: 'Loading Progress'),
  appDialogService(
    name: 'app_dialog_service',
    title: 'App Dialog Service',
  ),
  settings(name: 'settings', title: 'Settings'),
  profile(name: 'profile', title: 'Profile'),
  changePassword(
    name: 'change_password',
    title: 'Change Password',
  ),
  language(name: 'language', title: 'Language'),
  appInfo(name: 'app_info', title: 'App Info'),
  modalBottomSheetShapeExamples(
    name: 'modal_bottom_sheet_shape_examples',
    title: 'Bottom Sheet Shapes',
  ),
  myImage(
    name: 'myimage',
    title: 'MyImage',
  ),
  formFieldsSignaturePad(
    name: 'form_fields_signature_pad',
    title: 'Signature Pad',
  );

  final String name;
  final String title;

  const AppRoute({
    required this.name,
    required this.title,
  });

  String get path => '/${name.replaceAll('_', '-')}';
}

extension GoRouterExtensions on BuildContext {
  void goToRoute(AppRoute route) => goNamed(route.name);

  Future<T?> pushRoute<T>(AppRoute route) => push<T>(route.path);
}
