// ============================================================================
// IMPORTS
// ============================================================================

// Flutter & Material Design
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

// Third-party packages
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'package:workmanager/workmanager.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
// example-local flush helper
import 'src/service/flush_service.dart';

// Local configuration & state management
import 'config/app_router.dart';
import 'config/environment.dart';
import 'config/build_config.dart';
import 'state/app_state_notifier.dart';
import 'localization/localizations.dart' as loc;
import 'data/models/post.dart';

final logger = Logger();

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

/// Top-level background handler invoked by Workmanager in background
/// isolates. Must be a top-level function to be reachable from the
/// background isolate. Returns `true` on success.
/// Process pending submissions from DB and attempt to POST them.
///
/// Returns true on success, false on error. This helper is top-level so it
/// can be reused by both the background isolate handler and the foreground
/// flush callback without duplicating logic.
Future<bool> processPendingSubmissions() async {
  return await flushPendingSubmissions(submitHandler: (payload, id) async {
    try {
      final post = Post.fromJson(payload);
      final res = await Post.add(post: post);
      return res != null;
    } catch (e) {
      try {
        WorkmanagerService.instance.lastLogListenable.value =
            'flush handler threw for id=${id ?? '-'}: $e';
      } catch (_) {}
      return false;
    }
  });
}

Future<bool> backgroundFlushHandler(
    String task, Map<String, dynamic>? inputData) async {
  return await processPendingSubmissions();
}

/// Top-level dispatcher that Workmanager background isolate will call.
void workmanagerCallbackDispatcher() {
  Workmanager()
      .executeTask((String task, Map<String, dynamic>? inputData) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Workmanager executeTask: $task, inputData: $inputData');
    }
    try {
      final res = await backgroundFlushHandler(task, inputData);
      return Future.value(res);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('background dispatcher error: $e');
      }
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

    // Initialize Workmanager with a top-level dispatcher so background
    // isolates can reach the app's top-level `backgroundFlushHandler`.
    if (!kIsWeb) {
      await Workmanager().initialize(workmanagerCallbackDispatcher);
      // Also inform the package-level service about the handler so it can
      // include callback handles when scheduling tasks from the foreground.
      try {
        WorkmanagerService.setBackgroundTaskHandler(backgroundFlushHandler);
      } catch (_) {}
    }

    // Use platform-appropriate minimum for periodic work (15 minutes).
    final wmFreq = const Duration(minutes: 15);

    await FormFieldsInitializer.initAll(
      dbName: 'form_fields.db',
      // We've initialized Workmanager above; prevent the package from
      // initializing it again to avoid duplicate dispatcher registration.
      enableWorkmanager: false,
      registerPeriodic: true,
      workmanagerHandler: backgroundFlushHandler,
      // Example: override periodic scheduling values from host app.
      // Run every 15 minutes (minimum recommended by Android JobScheduler).
      workmanagerFrequency: wmFreq,
      workmanagerInitialDelay: Duration.zero,
      // Register a foreground flush handler so the WorkmanagerService can
      // invoke it when connectivity is restored. This handler reads the
      // example DB table `pending_submissions` and attempts to POST each
      // pending entry to the server. Successful submissions are removed.
      workmanagerFlushPendingHandler: () async {
        await processPendingSubmissions();
      },
      migrationAssetPaths: [
        'migrations/migration.sql',
        // 'migrations/migration_json_file.sql',
        // 'migrations/v1.sql',
        // 'migrations/v2.sql',
        // 'migrations/v2_down.sql',
      ],
      dbVersion: 0,
    );

    // Debug helper: schedule a one-off run immediately to verify dispatcher
    if (kDebugMode && !kIsWeb) {
      try {
        final err = await WorkmanagerService.instance
            .runOnceNowDetailed(taskName: 'dbg_now');
        logger.i('Debug: runOnceNowDetailed -> $err');
        // give a short delay for logs to populate
        await Future.delayed(const Duration(seconds: 2));
        logger.i('Debug recentLogs: ${WorkmanagerService.instance.recentLogs}');
      } catch (e, st) {
        logger.w('Debug runOnceNow failed: $e\n$st');
      }
    }

    // Start a countdown display for the configured Workmanager frequency.
    if (!kIsWeb) {
      try {
        void startCountdown(Duration freq) {
          DateTime next = DateTime.now().add(freq);
          Timer.periodic(const Duration(seconds: 1), (t) {
            final rem = next.difference(DateTime.now());
            if (rem.inMilliseconds <= 0) {
              try {
                WorkmanagerService.instance.lastLogListenable.value =
                    'next scheduled run now; resetting countdown';
              } catch (_) {}
              next = next.add(freq);
              return;
            }
            final mm = rem.inMinutes.remainder(60).toString().padLeft(2, '0');
            final ss = rem.inSeconds.remainder(60).toString().padLeft(2, '0');
            final msg = 'countdown to next run: $mm:$ss';
            try {
              WorkmanagerService.instance.lastLogListenable.value = msg;
            } catch (_) {}
            logger.i(msg);
          });
        }

        startCountdown(wmFreq);
      } catch (e, st) {
        logger.w('Failed to start countdown: $e\n$st');
      }
    }

    // flushPendingHandler is registered via the `workmanagerFlushPendingHandler`
    // parameter passed to `FormFieldsInitializer.initAll` above.
    // Background handler is registered via FormFieldsInitializer.initAll
    // (workmanagerHandler parameter) so no manual registration is needed here.
  } catch (e, st) {
    logger.w('Startup initialization failed: $e\n$st');
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
