// ============================================================================
// IMPORTS
// ============================================================================

// Flutter & Material Design
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';

// Local configuration & state management
import 'config/app_router.dart';
import 'config/environment.dart';
import 'config/build_config.dart';
import 'state/app_state_notifier.dart';
import 'localization/localizations.dart' as loc;

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

void main() {
  // ========================================================================
  // ENVIRONMENT CONFIGURATION
  // ========================================================================
  // Set the environment BEFORE starting the app.
  // All API endpoints will automatically use the configured environment.
  //
  // Available options:
  //   🐛 DEBUG      - Development with detailed logging
  //   🧪 BETA       - Feature testing
  //   🚀 PRODUCTION - Stable release
  //
  // ⚙️ This is automatically set by: dart run tool/configure_build.dart
  // ========================================================================

  // Option 1: DEBUG Environment (default)
  EnvironmentConfig.current = AppEnvironment.production;

  // Option 2: BETA Environment (uncomment to use)
  // EnvironmentConfig.current = AppEnvironment.production;

  // Option 3: PRODUCTION Environment (uncomment to use)
  // EnvironmentConfig.current = AppEnvironment.production;

  // ========================================================================
  // BUILD CONFIGURATION
  // ========================================================================
  // BuildConfig is automatically synced with EnvironmentConfig and provides
  // platform-specific settings (namespace, SDK versions, API keys, etc.).
  //
  // All configuration values are stored in: lib/config/build_settings.dart
  // To change configuration: dart run tool/configure_build.dart
  // ========================================================================

  if (kDebugMode) {
    _printStartupInfo();
  }

  // Start the app
  runApp(const MyApp());
}

// ============================================================================
// STARTUP DIAGNOSTICS
// ============================================================================

void _printStartupInfo() {
  final config = BuildConfig.current;
  final divider = '=' * 60;

  debugPrint('\n$divider');
  debugPrint('🚀 APP STARTUP');
  debugPrint(divider);

  // Environment Info
  debugPrint(
      '\n📍 ENVIRONMENT: ${EnvironmentConfig.currentName.toUpperCase()}');
  debugPrint('   Base URL: ${EnvironmentConfig.currentBaseUrl}');

  // Build Configuration
  debugPrint('\n⚙️  BUILD CONFIGURATION:');
  debugPrint('   Android Namespace: ${config.androidNamespace}');
  debugPrint('   Version: ${config.versionName} (${config.versionCode})');
  debugPrint('   Min SDK: ${config.androidMinSdk}');
  debugPrint('   Target SDK: ${config.androidTargetSdk}');
  debugPrint('   Compile SDK: ${config.androidCompileSdk}');

  // API Keys Status
  final mapsKeyStatus = config.androidMapsApiKey.contains('DEBUG') ||
          config.androidMapsApiKey.contains('BETA') ||
          config.androidMapsApiKey.contains('PROD')
      ? '⚠️  Placeholder'
      : '✅ Configured';
  debugPrint('   Maps API Key: $mapsKeyStatus');

  // Permissions
  debugPrint('\n🔐 CONFIGURED PERMISSIONS:');
  final hasCamera = config.hasAndroidPermission('android.permission.CAMERA');
  final hasGallery =
      config.hasAndroidPermission('android.permission.READ_MEDIA_IMAGES');
  final hasNotification =
      config.hasAndroidPermission('android.permission.POST_NOTIFICATIONS');

  debugPrint('   📷 Camera: ${hasCamera ? "✅ Enabled" : "❌ Disabled"}');
  debugPrint('   🖼️  Gallery: ${hasGallery ? "✅ Enabled" : "❌ Disabled"}');
  debugPrint(
      '   🔔 Notifications: ${hasNotification ? "✅ Enabled" : "❌ Disabled"}');
  debugPrint('   📋 Total: ${config.androidPermissions.length} permissions');

  // Platform Info
  debugPrint('\n📱 PLATFORM:');
  debugPrint('   OS: ${defaultTargetPlatform.name}');
  debugPrint('   Web: ${kIsWeb ? "Yes" : "No"}');
  debugPrint('   Debug Mode: ${kDebugMode ? "Yes" : "No"}');

  // Production Readiness
  if (config.isProductionReady) {
    debugPrint('\n✅ Status: PRODUCTION READY');
  } else {
    debugPrint('\n⚠️  Status: Development (API keys need configuration)');
  }

  debugPrint('\n$divider\n');
}

// ============================================================================
// APP WIDGET & PRESENTER
// ============================================================================

/// Root application widget with MVP architecture
///
/// ResponsibleFor:
/// - App initialization & lifecycle
/// - Global state management (AppStateNotifier)
/// - Theme configuration
/// - Localization setup
/// - Navigation routing
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => View();
}

/// Presenter for MyApp - handles lifecycle and business logic
abstract class PresenterState extends State<MyApp> {
  late final ViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ViewModel();
    _requestStartupPermissions();
  }

  Future<void> _requestStartupPermissions() async {
    // Skip permission requests for web and desktop platforms
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    // Get enabled permissions from BuildConfig
    final config = BuildConfig.current;
    final permissions = <Permission>[];

    // Only request permissions that are enabled in build configuration
    if (config.hasAndroidPermission('android.permission.CAMERA')) {
      permissions.add(Permission.camera);
      if (kDebugMode) debugPrint('📷 Requesting Camera permission...');
    }

    if (config.hasAndroidPermission('android.permission.READ_MEDIA_IMAGES') ||
        config
            .hasAndroidPermission('android.permission.READ_EXTERNAL_STORAGE')) {
      permissions.add(Permission.photos);
      if (kDebugMode) debugPrint('🖼️  Requesting Gallery permission...');
    }

    if (config.hasAndroidPermission('android.permission.POST_NOTIFICATIONS')) {
      permissions.add(Permission.notification);
      if (kDebugMode) debugPrint('🔔 Requesting Notification permission...');
    }

    // If no permissions configured, skip
    if (permissions.isEmpty) {
      if (kDebugMode) {
        debugPrint('ℹ️  No runtime permissions configured');
      }
      return;
    }

    // Request all configured permissions
    final statuses = await permissions.request();

    if (kDebugMode) {
      debugPrint('\n📋 Permission Results:');
      for (final entry in statuses.entries) {
        final icon = entry.value.isGranted
            ? '✅'
            : entry.value.isDenied
                ? '❌'
                : '⚠️';
        debugPrint(
            '   $icon ${entry.key.toString().split('.').last}: ${entry.value}');
      }
    }

    // Check for permanently denied permissions
    final permanentlyDenied = statuses.entries
        .where((e) => e.value.isPermanentlyDenied)
        .map((e) => e.key)
        .toList();

    if (permanentlyDenied.isNotEmpty && mounted) {
      await _showPermissionSettingsDialog(permanentlyDenied);
    }
  }

  Future<void> _showPermissionSettingsDialog(
      List<Permission> deniedPermissions) async {
    final permissionNames = deniedPermissions.map((p) {
      final name = p.toString().split('.').last;
      return name[0].toUpperCase() + name.substring(1);
    }).join(', ');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('🔐 Permission Required'),
          content: Text(
            'The following permissions were permanently denied:\n\n'
            '$permissionNames\n\n'
            'These permissions are required for the app to function properly. '
            'Please enable them in App Settings.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}

// ============================================================================
// VIEW
// ============================================================================

/// View for MyApp - renders the app UI with theming and routing
class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel.appState,
      child: Consumer<AppStateNotifier>(
        builder: (context, appState, _) {
          // Show loading while app initializes
          if (!appState.isInitialized) {
            return const _LoadingScreen();
          }

          return MaterialApp.router(
            // ================================================================
            // APP CONFIGURATION
            // ================================================================
            title: 'FormFields - Complete Examples',

            // ================================================================
            // THEME CONFIGURATION
            // ================================================================
            theme: _buildTheme(),

            // ================================================================
            // LOCALIZATION CONFIGURATION
            // ================================================================
            locale: appState.locale,
            localizationsDelegates: const [
              loc.LocalizationsDelegate(),
              FormFieldsLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: loc.Localizations.supportedLocales,

            // ================================================================
            // ROUTING CONFIGURATION
            // ================================================================
            routerConfig: viewModel.routerConfig,
          );
        },
      ),
    );
  }

  /// Build Material Design 3 theme with custom colors
  static ThemeData _buildTheme() {
    return ThemeData(
      // Color & Material3
      primarySwatch: Colors.blue,
      useMaterial3: true,

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ============================================================================
// LOADING SCREEN
// ============================================================================

/// Loading screen shown while app initializes
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

// ============================================================================
// VIEW MODEL
// ============================================================================

/// View model for MyApp
///
/// Responsibilities:
/// - Manage app lifecycle
/// - Provide global state (AppStateNotifier)
/// - Configure routing
class ViewModel {
  /// Global app state notifier (provider-based state management)
  final AppStateNotifier appState = AppStateNotifier();

  /// Router configuration for app navigation
  late final routerConfig = createAppRouter(appState);

  /// Clean up resources on app dispose
  void dispose() {
    appState.dispose();
  }
}
