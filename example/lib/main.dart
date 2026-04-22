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
import 'package:logger/logger.dart';

// Local configuration & state management
import 'config/app_router.dart';
import 'config/environment.dart';
import 'config/build_config.dart';
import 'state/app_state_notifier.dart';
import 'localization/localizations.dart' as loc;

// ============================================================================
// GLOBAL LOGGER INSTANCE
// ============================================================================

final logger = Logger();

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
  EnvironmentConfig.current = AppEnvironment.debug;

  // Option 2: BETA Environment (uncomment to use)
  // EnvironmentConfig.current = AppEnvironment.debug;

  // Option 3: PRODUCTION Environment (uncomment to use)
  // EnvironmentConfig.current = AppEnvironment.debug;

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

  logger.i('\n$divider');
  logger.i('🚀 APP STARTUP');
  logger.i(divider);

  // Environment Info
  logger.i('\n📍 ENVIRONMENT: ${EnvironmentConfig.currentName.toUpperCase()}');
  logger.i('   Base URL: ${EnvironmentConfig.currentBaseUrl}');

  // Build Configuration
  logger.i('\n⚙️  BUILD CONFIGURATION:');
  logger.i('   Android Namespace: ${config.androidNamespace}');
  logger.i('   Version: ${config.versionName} (${config.versionCode})');
  logger.i('   Min SDK: ${config.androidMinSdk}');
  logger.i('   Target SDK: ${config.androidTargetSdk}');
  logger.i('   Compile SDK: ${config.androidCompileSdk}');

  // API Keys Status
  final mapsKeyStatus = config.androidMapsApiKey.contains('DEBUG') ||
          config.androidMapsApiKey.contains('BETA') ||
          config.androidMapsApiKey.contains('PROD')
      ? '⚠️  Placeholder'
      : '✅ Configured';
  logger.i('   Maps API Key: $mapsKeyStatus');

  // Permissions
  logger.i('\n🔐 CONFIGURED PERMISSIONS:');
  final hasCamera = config.hasAndroidPermission('android.permission.CAMERA');
  final hasGallery =
      config.hasAndroidPermission('android.permission.READ_MEDIA_IMAGES');
  final hasNotification =
      config.hasAndroidPermission('android.permission.POST_NOTIFICATIONS');

  logger.i('   📷 Camera: ${hasCamera ? "✅ Enabled" : "❌ Disabled"}');
  logger.i('   🖼️  Gallery: ${hasGallery ? "✅ Enabled" : "❌ Disabled"}');
  logger.i(
      '   🔔 Notifications: ${hasNotification ? "✅ Enabled" : "❌ Disabled"}');
  logger.i('   📋 Total: ${config.androidPermissions.length} permissions');

  // Platform Info
  logger.i('\n📱 PLATFORM:');
  logger.i('   OS: ${defaultTargetPlatform.name}');
  logger.i('   Web: ${kIsWeb ? "Yes" : "No"}');
  logger.i('   Debug Mode: ${kDebugMode ? "Yes" : "No"}');

  // Production Readiness
  if (config.isProductionReady) {
    logger.i('\n✅ Status: PRODUCTION READY');
  } else {
    logger.i('\n⚠️  Status: Development (API keys need configuration)');
  }

  logger.i('\n$divider\n');
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
      logger.i('📷 Requesting Camera permission...');
    }

    if (config.hasAndroidPermission('android.permission.READ_MEDIA_IMAGES') ||
        config
            .hasAndroidPermission('android.permission.READ_EXTERNAL_STORAGE')) {
      permissions.add(Permission.photos);
      logger.i('🖼️  Requesting Gallery permission...');
    }

    if (config.hasAndroidPermission('android.permission.POST_NOTIFICATIONS')) {
      permissions.add(Permission.notification);
      logger.i('🔔 Requesting Notification permission...');
    }

    // If no permissions configured, skip
    if (permissions.isEmpty) {
      logger.i('ℹ️  No runtime permissions configured');
      return;
    }

    // Request all configured permissions
    final statuses = await permissions.request();

    logger.i('\n📋 Permission Results:');
    for (final entry in statuses.entries) {
      final icon = entry.value.isGranted
          ? '✅'
          : entry.value.isDenied
              ? '❌'
              : '⚠️';
      logger.i(
          '   $icon ${entry.key.toString().split('.').last}: ${entry.value}');
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
    // Convert permission names to localization keys
    final permissionNames = deniedPermissions.map((p) {
      final name = p.toString().split('.').last;
      switch (name) {
        case 'camera':
          return 'Camera';
        case 'photos':
          return 'Photos';
        case 'notification':
          return 'Notification';
        default:
          return name[0].toUpperCase() + name.substring(1);
      }
    }).join(', ');

    await showDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.tr('permissionRequired')),
          content: Text(
            dialogContext
                .tr('permissionsDenied')
                .replaceFirst('{permissions}', permissionNames),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.tr('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: Text(dialogContext.tr('openSettings')),
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
      extensions: <ThemeExtension<dynamic>>[
        const AppButtonThemeData(
          filledStyle: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Color(0xFF2563EB)),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            textStyle:
                WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold)),
          ),
          outlinedStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Color(0xFF2563EB)),
            side: WidgetStatePropertyAll(BorderSide(color: Color(0xFF2563EB))),
          ),
          textStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Color(0xFF2563EB)),
          ),
          iconBackgroundColor: Colors.white, // Colors.purple.shade100
          fabBackgroundColor: Colors.yellow, // Colors.green.shade100
        ),
      ],

      // InputDecoration Theme for all TextFields (including FormFieldsAutocomplete)
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        filled: true,
        fillColor: Color(0xFFF3F4F6),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(color: Color(0xFF2563EB)),
        hintStyle: TextStyle(color: Colors.grey),
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

  /// Root navigator key used by global dialog coordinator.
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Router configuration for app navigation
  late final routerConfig =
      createAppRouter(appState, navigatorKey: rootNavigatorKey);

  ViewModel() {
    AppGlobalDialogService.instance.configure(rootNavigatorKey);
  }

  /// Clean up resources on app dispose
  void dispose() {
    appState.dispose();
  }
}
