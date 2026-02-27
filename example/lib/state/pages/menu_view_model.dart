import 'package:flutter/material.dart';
import 'package:form_fields_example/config/app_routes.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';

class MenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String routeName;

  const MenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.routeName,
  });
}

class MenuViewModel extends ChangeNotifier {
  final AppStateNotifier _appState;

  MenuViewModel(this._appState) {
    _appState.addListener(notifyListeners);
  }

  AppStateNotifier get appState => _appState;

  String get displayName => _appState.currentUser?.displayName ?? '';
  String get email => _appState.currentUser?.email ?? '';

  List<MenuItemData> get menuItems => [
        MenuItemData(
          title: 'FormFields',
          subtitle: 'Text, Number, Date & Time',
          icon: Icons.text_fields,
          color: Colors.blue,
          routeName: AppRoute.formFields.name,
        ),
        MenuItemData(
          title: 'Dropdown',
          subtitle: 'Single Select',
          icon: Icons.arrow_drop_down_circle,
          color: Colors.green,
          routeName: AppRoute.dropdown.name,
        ),
        MenuItemData(
          title: 'Dropdown Multi',
          subtitle: 'Multi-Select',
          icon: Icons.library_add_check,
          color: Colors.purple,
          routeName: AppRoute.dropdownMulti.name,
        ),
        MenuItemData(
          title: 'Radio Button',
          subtitle: 'Radio Options',
          icon: Icons.radio_button_checked,
          color: Colors.orange,
          routeName: AppRoute.radioButton.name,
        ),
        MenuItemData(
          title: 'Checkbox',
          subtitle: 'Checkbox Options',
          icon: Icons.check_box,
          color: Colors.pink,
          routeName: AppRoute.checkbox.name,
        ),
        MenuItemData(
          title: 'Custom Class',
          subtitle: 'Generic Types',
          icon: Icons.class_,
          color: Colors.teal,
          routeName: AppRoute.customClass.name,
        ),
        MenuItemData(
          title: 'Validation',
          subtitle: 'Null/Non-Null',
          icon: Icons.rule,
          color: Colors.indigo,
          routeName: AppRoute.validation.name,
        ),
      ];

  Future<String?> loadUser({bool forceRefresh = false}) async {
    if (!_appState.isLoggedIn) return null;

    final accessToken = _appState.accessToken;
    if (accessToken.isEmpty) return null;

    if (_appState.currentUser != null && !forceRefresh) {
      return null;
    }

    try {
      final user = await User.getMe(accessToken: accessToken);
      _appState.updateUserData(user);
      return null;
    } catch (error) {
      // If token is invalid, trigger logout
      final errorMsg = error.toString();
      if (errorMsg.contains('401') ||
          errorMsg.contains('403') ||
          errorMsg.contains('Bad Response')) {
        _appState.logout();
        return 'Session expired. Please login again.';
      }
      return errorMsg.contains('DioException')
          ? 'Unable to load user data'
          : errorMsg;
    }
  }

  @override
  void dispose() {
    _appState.removeListener(notifyListeners);
    super.dispose();
  }
}
