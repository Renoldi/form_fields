import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:form_fields_example/ui/pages/login/main.dart' as login;
import 'package:form_fields_example/ui/pages/menu/main.dart' as menu;
import 'package:form_fields_example/ui/pages/form_fields_examples/main.dart'
    as form_fields_examples;
import 'package:form_fields_example/ui/pages/dropdown_examples/main.dart'
    as dropdown_examples;
import 'package:form_fields_example/ui/pages/dropdown_multi_examples/main.dart'
    as dropdown_multi_examples;
import 'package:form_fields_example/ui/pages/radio_button_examples/main.dart'
    as radio_button_examples;
import 'package:form_fields_example/ui/pages/checkbox_examples/main.dart'
    as checkbox_examples;
import 'package:form_fields_example/ui/pages/custom_class_examples/main.dart'
    as custom_class_examples;
import 'package:form_fields_example/ui/pages/null_non_null_validation_examples/main.dart'
    as null_non_null_validation_examples;
import 'package:form_fields_example/ui/pages/app_button_examples/main.dart'
    as app_button_examples;
import 'package:form_fields_example/ui/pages/loading_progress_examples/main.dart'
    as loading_progress_examples;
import 'package:form_fields_example/ui/pages/app_dialog_service_examples/main.dart'
    as app_dialog_service_examples;
import 'package:form_fields_example/ui/pages/profile/main.dart' as profile;
import 'package:form_fields_example/ui/pages/change_password/main.dart'
    as change_password;
import 'package:form_fields_example/ui/pages/settings/main.dart' as settings;
import 'package:form_fields_example/ui/pages/language/main.dart' as language;
import 'package:form_fields_example/ui/pages/app_info/main.dart' as app_info;
import 'package:form_fields_example/localization/localizations.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'app_routes.dart';

/// Creates and configures the application's [GoRouter] instance.
///
/// This router handles:
/// - Authentication-based redirects
/// - Named route navigation using [AppRoute] enum
/// - State management integration via [AppStateNotifier]
///
/// Example:
/// ```dart
/// final router = createAppRouter(appStateNotifier);
/// ```
GoRouter createAppRouter(
  AppStateNotifier appState, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    debugLogDiagnostics: kDebugMode,
    initialLocation:
        appState.isLoggedIn ? AppRoute.menu.path : AppRoute.login.path,
    refreshListenable: appState,

    // Authentication guard
    redirect: (context, state) {
      final isLoggedIn = appState.isLoggedIn;
      final isLoggingIn = state.uri.path == AppRoute.login.path;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isLoggingIn) {
        return AppRoute.login.path;
      }

      // Redirect to menu if already logged in and trying to access login
      if (isLoggedIn && isLoggingIn) {
        return AppRoute.menu.path;
      }

      return null; // No redirect needed
    },

    // Route definitions
    routes: [
      // Public routes
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => login.ViewModel(),
          child: login.Presenter(
            onLoginSuccess: () => context.goToRoute(AppRoute.menu),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.menu.path,
        name: AppRoute.menu.name,
        builder: (context, state) => menu.Presenter(
          onLogout: () => context.goToRoute(AppRoute.login),
          onMenuItemTap: (routeName) => context.pushNamed(routeName),
          onOpenSettings: () async {
            await context.pushRoute(AppRoute.settings);
          },
          onOpenProfile: () async {
            await context.pushRoute(AppRoute.profile);
          },
        ),
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => settings.ViewModel(context.read<AppStateNotifier>()),
          child: settings.Presenter(
            onBack: () => context.pop(),
            onLogout: () => context.goToRoute(AppRoute.login),
            onOpenProfile: () => context.pushRoute(AppRoute.profile),
            onOpenChangePassword: () =>
                context.pushRoute(AppRoute.changePassword),
            onOpenLanguage: () => context.pushRoute(AppRoute.language),
            onOpenAppInfo: () => context.pushRoute(AppRoute.appInfo),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: AppRoute.profile.name,
        builder: (context, state) => profile.Presenter(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoute.changePassword.path,
        name: AppRoute.changePassword.name,
        builder: (context, state) => change_password.Presenter(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoute.language.path,
        name: AppRoute.language.name,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => language.ViewModel(context.read<AppStateNotifier>()),
          child: language.Presenter(
            onBack: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.appInfo.path,
        name: AppRoute.appInfo.name,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => app_info.ViewModel(),
          child: app_info.Presenter(
            onBack: () => context.pop(),
          ),
        ),
      ),

      // Protected example routes
      GoRoute(
        path: AppRoute.formFields.path,
        name: AppRoute.formFields.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.formFields,
          child: ChangeNotifierProvider(
            create: (_) => form_fields_examples.FormFieldsExamplesViewModel(),
            child: const form_fields_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.dropdown.path,
        name: AppRoute.dropdown.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.dropdown,
          child: ChangeNotifierProvider(
            create: (_) => dropdown_examples.DropdownExamplesViewModel(),
            child: const dropdown_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.dropdownMulti.path,
        name: AppRoute.dropdownMulti.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.dropdownMulti,
          child: ChangeNotifierProvider(
            create: (_) =>
                dropdown_multi_examples.DropdownMultiExamplesViewModel(),
            child: const dropdown_multi_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.radioButton.path,
        name: AppRoute.radioButton.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.radioButton,
          child: ChangeNotifierProvider(
            create: (_) => radio_button_examples.RadioButtonExamplesViewModel(),
            child: const radio_button_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.checkbox.path,
        name: AppRoute.checkbox.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.checkbox,
          child: ChangeNotifierProvider(
            create: (_) => checkbox_examples.ViewModel(),
            child: const checkbox_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.customClass.path,
        name: AppRoute.customClass.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.customClass,
          child: ChangeNotifierProvider(
            create: (_) => custom_class_examples.CustomClassExamplesViewModel(),
            child: const custom_class_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.validation.path,
        name: AppRoute.validation.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.validation,
          child: ChangeNotifierProvider(
            create: (_) => null_non_null_validation_examples
                .NullNonNullValidationExamplesViewModel(),
            child: const null_non_null_validation_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.appButton.path,
        name: AppRoute.appButton.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.appButton,
          child: ChangeNotifierProvider(
            create: (_) => app_button_examples.ViewModel(),
            child: const app_button_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.loadingProgress.path,
        name: AppRoute.loadingProgress.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.loadingProgress,
          child: ChangeNotifierProvider(
            create: (_) => loading_progress_examples.ViewModel(),
            child: const loading_progress_examples.Presenter(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.appDialogService.path,
        name: AppRoute.appDialogService.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.appDialogService,
          child: ChangeNotifierProvider(
            create: (_) => app_dialog_service_examples.ViewModel(),
            child: const app_dialog_service_examples.Presenter(),
          ),
        ),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: Text(context.tr('pageNotFound')),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.tr('pageNotFound404'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('route')}: ${state.uri.path}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.goToRoute(AppRoute.menu),
              icon: const Icon(Icons.home),
              label: Text(context.tr('goToMenu')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildExamplePage({
  required BuildContext context,
  required AppRoute route,
  required Widget child,
}) {
  return Scaffold(
    appBar: AppBar(
      title: Text(context.tr(_routeTitleKey(route))),
    ),
    body: SafeArea(child: child),
  );
}

String _routeTitleKey(AppRoute route) {
  switch (route) {
    case AppRoute.login:
      return 'login';
    case AppRoute.menu:
      return 'menu';
    case AppRoute.formFields:
      return 'formFields';
    case AppRoute.dropdown:
      return 'dropdown';
    case AppRoute.dropdownMulti:
      return 'dropdownMulti';
    case AppRoute.radioButton:
      return 'radioButton';
    case AppRoute.checkbox:
      return 'checkbox';
    case AppRoute.customClass:
      return 'customClass';
    case AppRoute.validation:
      return 'nullNonNullValidation';
    case AppRoute.appButton:
      return 'appButton';
    case AppRoute.loadingProgress:
      return 'loadingProgress';
    case AppRoute.appDialogService:
      return 'appDialogService';
    case AppRoute.settings:
      return 'settings';
    case AppRoute.profile:
      return 'profile';
    case AppRoute.changePassword:
      return 'changePassword';
    case AppRoute.language:
      return 'language';
    case AppRoute.appInfo:
      return 'appInfo';
  }
}
