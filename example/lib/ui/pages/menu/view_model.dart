import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:form_fields_example/config/app_routes.dart';
import 'package:form_fields_example/config/error_type.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/data/services/http_service.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';

final Logger _logger = Logger();

class AppMenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String routeName;

  const AppMenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.routeName,
  });
}

class ViewModel extends ChangeNotifier {
  final AppStateNotifier _appState;

  ViewModel(this._appState) {
    _appState.addListener(notifyListeners);
  }

  AppStateNotifier get appState => _appState;

  String get displayName => _appState.currentUser?.displayName ?? '';
  String get email => _appState.currentUser?.email ?? '';

  List<AppMenuItemData> get menuItems => [
        AppMenuItemData(
          title: 'FormFields',
          subtitle: 'Text, Number, Date & Time',
          icon: Icons.text_fields,
          color: Colors.blue,
          routeName: AppRoute.formFields.name,
        ),
        AppMenuItemData(
          title: 'Dropdown',
          subtitle: 'Single Select',
          icon: Icons.arrow_drop_down_circle,
          color: Colors.green,
          routeName: AppRoute.dropdown.name,
        ),
        AppMenuItemData(
          title: 'Dropdown Multi',
          subtitle: 'Multi-Select',
          icon: Icons.library_add_check,
          color: Colors.purple,
          routeName: AppRoute.dropdownMulti.name,
        ),
        AppMenuItemData(
          title: 'Radio Button',
          subtitle: 'Radio Options',
          icon: Icons.radio_button_checked,
          color: Colors.orange,
          routeName: AppRoute.radioButton.name,
        ),
        AppMenuItemData(
          title: 'Checkbox',
          subtitle: 'Checkbox Options',
          icon: Icons.check_box,
          color: Colors.pink,
          routeName: AppRoute.checkbox.name,
        ),
        AppMenuItemData(
          title: 'Custom Class',
          subtitle: 'Generic Types',
          icon: Icons.class_,
          color: Colors.teal,
          routeName: AppRoute.customClass.name,
        ),
        AppMenuItemData(
          title: 'Validation',
          subtitle: 'Null/Non-Null',
          icon: Icons.rule,
          color: Colors.indigo,
          routeName: AppRoute.validation.name,
        ),
        AppMenuItemData(
          title: 'App Button',
          subtitle: 'Material 3 Buttons',
          icon: Icons.smart_button,
          color: Colors.red,
          routeName: AppRoute.appButton.name,
        ),
        AppMenuItemData(
          title: 'Loading & Progress',
          subtitle: 'Indicators & Async States',
          icon: Icons.hourglass_top,
          color: Colors.deepPurple,
          routeName: AppRoute.loadingProgress.name,
        ),
        AppMenuItemData(
          title: 'App Dialog Service',
          subtitle: 'Success/Error/Guard Dialogs',
          icon: Icons.chat_bubble_outline,
          color: Colors.brown,
          routeName: AppRoute.appDialogService.name,
        ),
        AppMenuItemData(
          title: 'Icons Gallery',
          subtitle: 'Browse & Search Icons',
          icon: Icons.widgets,
          color: Colors.cyan,
          routeName: AppRoute.iconsGallery.name,
        ),
        AppMenuItemData(
          title: 'Bottom Sheet Shapes',
          subtitle: 'Contoh berbagai shape',
          icon: Icons.space_dashboard,
          color: Colors.deepOrange,
          routeName: AppRoute.modalBottomSheetShapeExamples.name,
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
    } catch (error, stackTrace) {
      _logger.e('Load user failed: $error');
      _logger.d(stackTrace.toString());

      if (error is HttpException && error.type == ErrorType.authentication) {
        _appState.logout();
        return 'errorSessionExpiredLoginAgain';
      }

      if (error is HttpException) {
        return error.messageKey;
      }

      return 'errorUnableToLoadUserData';
    }
  }

  @override
  void dispose() {
    _appState.removeListener(notifyListeners);
    super.dispose();
  }
}
