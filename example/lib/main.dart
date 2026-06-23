// ============================================================================
// IMPORTS
// ============================================================================

// Flutter & Material Design
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields_example/src/service/flush_service.dart';
import 'package:permission_handler/permission_handler.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
// Types used for configuring the foreground service initialization when
// the plugin supports custom icon data.

// Background tasks are initialized by `FormFieldsInitializer.initAll(...)`.
// The package uses a foreground-service (via `flutter_foreground_task`) to
// execute long-running work. Register top-level background handlers by
// calling `ForegroundTaskService.setBackgroundTaskHandler()` before init,
// or include per-worker registrations in `initAll`'s `workerRegistrations`.
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
// example-local service helpers (flush, handlers)

// Local configuration & state management
import 'config/app_router.dart';
import 'config/environment.dart';
import 'config/build_config.dart';
import 'state/app_state_notifier.dart';
import 'localization/localizations.dart' as loc;

final logger = Logger();

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

// Background dispatching: the package initializes a foreground-service
// (via `flutter_foreground_task`) when you call
// `FormFieldsInitializer.initAll(...)`. Register a top-level handler by
// calling `ForegroundTaskService.setBackgroundTaskHandler(myHandler)` before
// init, or include per-worker registrations in `initAll`'s
// `workerRegistrations`. Handlers must be top-level/static for callback
// resolution.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ENVIRONMENT: set before startup (change via tool/configure_build.dart)
  EnvironmentConfig.current = AppEnvironment.debug;

  DioUtil.configure(
    baseUrl: EnvironmentConfig.currentBaseUrl,
    connectTimeout: Duration(seconds: EnvironmentConfig.config.connectTimeout),
    sendTimeout: Duration(seconds: EnvironmentConfig.config.sendTimeout),
    receiveTimeout: Duration(seconds: EnvironmentConfig.config.receiveTimeout),
  );

  // Option 2: BETA Environment (uncomment to use)
  // EnvironmentConfig.current = AppEnvironment.debug;

  // Option 3: PRODUCTION Environment (uncomment to use)
  // EnvironmentConfig.current = AppEnvironment.debug;

  // BUILD CONFIGURATION: see lib/config/build_settings.dart and
  // run `dart run tool/configure_build.dart` to update settings.

  if (kDebugMode) {
    _printStartupInfo();
  }

  // Initialize package services (DB, logging, optional background worker)
  try {
    // One-time developer helper: reset DB and re-initialize from bundled
    // migrations. REMOVE this call after the DB has been reset to avoid
    // deleting user data on subsequent launches.
    // if (kDebugMode) {
    //   try {
    //     await DBService.instance.resetDatabase(reinit: true);
    //     logger.i('Developer: resetDatabase completed');
    //   } catch (e, st) {
    //     logger.w('Developer: resetDatabase failed: $e\n$st');
    //   }
    // }

    // Foreground-service initialization and handler registration is
    // performed by `FormFieldsInitializer.initAll(...)`. You can register
    // a top-level handler on the service before calling `initAll`, or
    // include handlers in the `workerRegistrations` passed to `initAll`.
    // Note: `myHandler` must be a top-level/static function so it can be
    // resolved for background callbacks.

    // Foreground-task initialization is handled by `FormFieldsInitializer.initAll`.

    if (kDebugMode) {
      try {
        await DBService.instance.resetDatabase(reinit: true);
        logger.i('Developer: resetDatabase completed');
      } catch (e, st) {
        logger.w('Developer: resetDatabase failed: $e\n$st');
      }
    }
    // Use platform-appropriate minimum for periodic work (15 minutes).

    await FormFieldsInitializer.initAll(
      dbName: 'form_fields.db',
      // Let `initAll` initialize the foreground-service plumbing and
      // register handlers.
      enableForegroundService: true,
      registerPeriodic: true,
      // Optional: customize the notification and foreground-task options
      // passed to the underlying `flutter_foreground_task` initialization.
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'form_fields_channel',
        channelName: 'FormFields Background',
        channelDescription: 'Background tasks for form_fields package',
        // Updated for newer `flutter_foreground_task` API: do not set
        // `iconData` here (handled by app resources / manifest).
        playSound: false,
        enableVibration: false,
        showWhen: false,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Default to `nothing()` here — worker intervals are scheduled
        // using each `WorkerRegistration.frequency` (recommended).
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
      // Example: register one or more background workers.
      // Recommendation: use `frequency` on each `WorkerRegistration` to
      // schedule periodic work. The initializer will convert `frequency`
      // into the appropriate `eventAction` for the foreground service.
      // Only set `eventAction` directly when you need low-level control.
      workerRegistrations: [
        WorkerRegistration(
          taskName: 'form_fields_flush',
          // Use a platform-appropriate minimum (15 minutes) to avoid
          // overwhelming background isolate launches during development.
          frequency: Duration(seconds: 30),
          initialDelay: Duration.zero,
          periodic: true,
          inputData: null,
          backgroundHandler: backgroundFlushHandler,
          foregroundHandler: foregroundFlushPendingHandler,
          register: true,
        ),
        WorkerRegistration(
          taskName: 'send_current_location',
          frequency: Duration(seconds: 20),
          initialDelay: Duration.zero,
          periodic: true,
          inputData: null,
          backgroundHandler: sendCurrentLocationBackgroundHandler,
          foregroundHandler: sendCurrentLocationForeground,
          register: true,
        ),
        WorkerRegistration(
          taskName: 'send_random_event',
          frequency: Duration(seconds: 70),
          initialDelay: Duration.zero,
          periodic: true,
          inputData: null,
          backgroundHandler: sendRandomBackgroundHandler,
          foregroundHandler: sendRandomForeground,
          register: true,
        ),
      ],
      migrationAssetPaths: [
        'migrations/migration.sql',
        // 'migrations/migration_json_file.sql',
        // 'migrations/v1.sql',
        // 'migrations/v2.sql',
        // 'migrations/v2_down.sql',
      ],
      dbVersion: 0,
      // Invoke each registration's handlers immediately at startup.
    );

    // Register example flush handlers so `FlushApi` can invoke them.
    // try {
    //   FlushApi.register(
    //       flushAll: flushPendingSubmissions,
    //       flushOne: flushPendingSubmissionById);
    // } catch (_) {}

    // // Debug helper: schedule a one-off run immediately to verify adapter
    // if (kDebugMode && !kIsWeb) {
    //   try {
    //     final err = await ForegroundTaskService.instance
    //         .runOnceNowDetailed(taskName: 'dbg_now');
    //     logger.i('Debug: runOnceNowDetailed -> $err');
    //     // give a short delay for logs to populate
    //     await Future.delayed(const Duration(seconds: 2));
    //     logger.i('Debug recentLogs: ${ForegroundTaskService.instance.recentLogs}');
    //   } catch (e, st) {
    //     logger.w('Debug runOnceNow failed: $e\n$st');
    //   }
    // }

    // No post-init FlushApi registration required; registration happens
    // inside FormFieldsInitializer.initAll to avoid duplicate/late registration.
  } catch (e, st) {
    logger.w('Startup initialization failed: $e\n$st');
  }

  // Start the app
  runApp(const MyApp());
}

void _printStartupInfo() {
  final config = BuildConfig.current;
  final divider = '=' * 60;

  logger.i('\n$divider');
  logger.i('🚀 APP STARTUP');
  logger.i(divider);

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
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final config = BuildConfig.current;
    final permissions = <Permission>[];

    if (config.hasAndroidPermission('android.permission.CAMERA')) {
      permissions.add(Permission.camera);
    }
    if (config.hasAndroidPermission('android.permission.READ_MEDIA_IMAGES') ||
        config
            .hasAndroidPermission('android.permission.READ_EXTERNAL_STORAGE')) {
      permissions.add(Permission.photos);
    }
    if (config.hasAndroidPermission('android.permission.POST_NOTIFICATIONS')) {
      permissions.add(Permission.notification);
    }

    if (permissions.isEmpty) {
      return;
    }

    final statuses = await permissions.request();
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
    // Central seed color for the example app; controls primary color scheme.
    const seedColor = Color(0xFFA1C300);

    return ThemeData.light(useMaterial3: true).copyWith(
      primaryColor: seedColor,
      // Ensure UI surfaces (cards, dialogs, canvas) use white to match inputs
      cardColor: Colors.white,
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      canvasColor: Colors.white,
      colorScheme: ThemeData.light(useMaterial3: true).colorScheme.copyWith(
            primary: seedColor,
            secondary: seedColor,
            surface: Colors.white,
            surfaceContainerHighest: Colors.white,
          ),
      textTheme: GoogleFonts.robotoTextTheme(
        ThemeData.light(useMaterial3: true).textTheme,
      ),
      primaryTextTheme: GoogleFonts.robotoTextTheme(
        ThemeData.light(useMaterial3: true).primaryTextTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: seedColor,
        elevation: 0,
        centerTitle: true,
        // titleTextStyle: TextStyles().labelMedium.copyWith(
        //   color: Colors.white,
        //   fontWeight: FontWeight.bold,
        // ),
        iconTheme: IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: Colors.white,
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return null;
        }),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor;
          }
          return null;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor;
          }
          return null;
        }),
        side: BorderSide(color: seedColor, width: 2),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor;
          }
          return null;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor;
          }
          return null;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: seedColor,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: seedColor, width: 1),
          ),
          // textStyle: TextStyles().labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: seedColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: seedColor),
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: seedColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        FormFieldsMyImageThemeData(
          addTileBorderColor: seedColor,
          addTileBorderWidth: 2,
          addTileBorderRadius: 8,
          addTileBackgroundColor: Color(0xFFF3F4F6),
          addIconColor: seedColor,
        ),
        AppButtonThemeData(
          elevatedStyle: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              seedColor,
            ),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.bold),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          filledStyle: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              seedColor,
            ),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.bold),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          outlinedStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              seedColor,
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: seedColor),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          textStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              seedColor,
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          iconBackgroundColor: Colors.white,
          fabBackgroundColor: Colors.white,
          iconStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              seedColor,
            ),
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
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
