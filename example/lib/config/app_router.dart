import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/pages/login_page.dart';
import '../ui/pages/menu_page.dart';
import '../ui/pages/form_fields_examples_page.dart';
import '../ui/pages/dropdown_examples_page.dart';
import '../ui/pages/dropdown_multi_examples_page.dart';
import '../ui/pages/radio_button_examples_page.dart';
import '../ui/pages/checkbox_examples_page.dart';
import '../ui/pages/custom_class_examples_page.dart';
import '../ui/pages/null_non_null_validation_examples_page.dart';
import '../ui/pages/settings_page.dart';
import '../ui/pages/profile_page.dart';
import '../ui/pages/change_password_page.dart';
import '../ui/pages/language_page.dart';
import '../ui/pages/app_info_page.dart';
import '../state/notifiers/app_state_notifier.dart';
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
GoRouter createAppRouter(AppStateNotifier appState) {
  return GoRouter(
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
        builder: (context, state) => LoginPage(
          onLoginSuccess: () => context.goToRoute(AppRoute.menu),
        ),
      ),
      GoRoute(
        path: AppRoute.menu.path,
        name: AppRoute.menu.name,
        builder: (context, state) => MenuPage(
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
        builder: (context, state) => SettingsPage(
          onBack: () => context.pop(),
          onLogout: () => context.goToRoute(AppRoute.login),
          onOpenProfile: () => context.pushRoute(AppRoute.profile),
          onOpenChangePassword: () =>
              context.pushRoute(AppRoute.changePassword),
          onOpenLanguage: () => context.pushRoute(AppRoute.language),
          onOpenAppInfo: () => context.pushRoute(AppRoute.appInfo),
        ),
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: AppRoute.profile.name,
        builder: (context, state) => ProfilePage(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoute.changePassword.path,
        name: AppRoute.changePassword.name,
        builder: (context, state) => ChangePasswordPage(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoute.language.path,
        name: AppRoute.language.name,
        builder: (context, state) => LanguagePage(
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoute.appInfo.path,
        name: AppRoute.appInfo.name,
        builder: (context, state) => AppInfoPage(
          onBack: () => context.pop(),
        ),
      ),

      // Protected example routes
      GoRoute(
        path: AppRoute.formFields.path,
        name: AppRoute.formFields.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.formFields,
          child: const FormFieldsExamplesPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.dropdown.path,
        name: AppRoute.dropdown.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.dropdown,
          child: const DropdownExamplesPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.dropdownMulti.path,
        name: AppRoute.dropdownMulti.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.dropdownMulti,
          child: const DropdownMultiExamplesPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.radioButton.path,
        name: AppRoute.radioButton.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.radioButton,
          child: const RadioButtonExamplesPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.checkbox.path,
        name: AppRoute.checkbox.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.checkbox,
          child: const CheckboxExamplesPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.customClass.path,
        name: AppRoute.customClass.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.customClass,
          child: const CustomClassExamplesPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.validation.path,
        name: AppRoute.validation.name,
        builder: (context, state) => _buildExamplePage(
          context: context,
          route: AppRoute.validation,
          child: const NullNonNullValidationExamplesPage(),
        ),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Route: ${state.uri.path}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.goToRoute(AppRoute.menu),
              icon: const Icon(Icons.home),
              label: const Text('Go to Menu'),
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
      title: Text(route.title),
    ),
    body: SafeArea(child: child),
  );
}
