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
import 'package:form_fields_fcm/form_fields_fcm.dart';
import 'package:form_fields/notifications.dart';
// Workmanager is initialized by `FormFieldsInitializer.initAll(...)` when
// requested. The package will initialize the plugin and wire background
// handlers for you when you pass `workmanagerHandler` to `initAll` or
// register a handler via `WorkmanagerService.setBackgroundTaskHandler()`.
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// example-local service helpers (flush, handlers)

// Local configuration & state management
import 'config/app_router.dart';
import 'config/environment.dart';
import 'config/app_routes.dart';
import 'config/build_config.dart';
import 'state/app_state_notifier.dart';
import 'localization/localizations.dart' as loc;
import 'ui/pages/fcm_test/main.dart' as fcm_test;
import 'ui/pages/notification/main.dart' as notification;

final logger = Logger();

@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage msg) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (_) {}

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  try {
    await DBService.instance.init();
  } catch (_) {}

  try {
    // Lightweight debug logging to help diagnose payload shapes in the
    // background isolate. Keep concise to avoid noisy logs in production.
    try {
      final dynamic m = msg;
      String? mid;
      try {
        mid = (msg.messageId as dynamic)?.toString();
      } catch (_) {}
      try {
        mid ??= m is Map ? m['messageId']?.toString() : null;
      } catch (_) {}
      logger.i(
        'fcmBackgroundHandler payload: messageId=$mid, data=${msg.data}, notification_title=${msg.notification?.title}, notification_body=${msg.notification?.body}',
      );
    } catch (_) {}

    await NotificationRepository.instance.insertFromRemote(msg);
  } catch (e, st) {
    logger.w('fcmBackgroundHandler failed: $e\n$st');
  }
}

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

// Background dispatching: the package can initialize Workmanager and wire
// background handlers when `enableWorkmanager: true` is passed to
// `FormFieldsInitializer.initAll(...)`. Register a top-level handler via
// the `workmanagerHandler` argument to `initAll`, or call
// `WorkmanagerService.setBackgroundTaskHandler(myHandler)` before
// scheduling tasks. Handlers must be top-level/static so they can be
// resolved from background isolates.

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

    // Workmanager initialization and handler registration is performed by
    // `FormFieldsInitializer.initAll(...)` when `enableWorkmanager: true`.
    // Example: register a top-level background handler (choose one):
    //
    // 1) Register the handler on the service before init:
    //    WorkmanagerService.setBackgroundTaskHandler(myHandler);
    //    await FormFieldsInitializer.initAll(..., enableWorkmanager: true);
    //
    // 2) Or pass the handler into initAll directly:
    //    await FormFieldsInitializer.initAll(
    //      ...,
    //      enableWorkmanager: true,
    //      workmanagerHandler: myHandler,
    //    );
    //
    // Note: `myHandler` must be a top-level/static function so it can be
    // resolved from background isolates.

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
      // Let `initAll` initialize Workmanager and register handlers.
      enableWorkmanager: false,
      registerPeriodic: false,
      // Example: register one or more background workers.
      workerRegistrations: [
        WorkerRegistration(
          taskName: 'form_fields_flush',
          // Use a platform-appropriate minimum (15 minutes) to avoid
          // overwhelming background isolate launches during development.
          frequency: Duration(seconds: 30),
          initialDelay: Duration.zero,
          periodic: true,
          inputData: null,
          backgroundHandler: workmanagerFlushBackgroundHandler,
          foregroundHandler: workmanagerFlushPendingHandler,
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

      migrationAssetPaths: ['migrations/migration.sql', 'migrations/v3.sql'],
      dbVersion: 3,
      // Invoke each registration's handlers immediately at startup.
      // Explicitly show startup trigger and iOS deferral options.
      triggerWorkerHandlersOnStart: true,
      // If true (default) `initAll` will defer invoking startup handlers
      // on iOS by a short delay to avoid platform-not-ready crashes. Set
      // to false to keep legacy immediate behavior.
      deferStartupHandlersOnIos: true,
    );

    // Register example flush handlers so `FlushApi` can invoke them.
    //         .runOnceNowDetailed(taskName: 'dbg_now');
    //     logger.i('Debug: runOnceNowDetailed -> $err');
    //     // give a short delay for logs to populate
    //     await Future.delayed(const Duration(seconds: 2));
    //     logger.i('Debug recentLogs: ${WorkmanagerService.instance.recentLogs}');
    //   } catch (e, st) {
    //     logger.w('Debug runOnceNow failed: $e\n$st');
    //   }
    // }

    // No post-init FlushApi registration required; registration happens
    // inside FormFieldsInitializer.initAll to avoid duplicate/late registration.
  } catch (e, st) {
    logger.w('Startup initialization failed: $e\n$st');
  }

  // Initialize FCM for the example app (non-fatal)
  try {
    // `FCMService.initialize()` will call `Firebase.initializeApp()` as needed,
    // so do not call it here to avoid duplicate initialization.
    await FCMService.instance.initialize(
      backgroundHandler: fcmBackgroundHandler,

      options: const FCMOptions(showLocalNotification: true),
      onMessage: (msg) async {
        logger.i('FCM foreground: ${msg.title} ${msg.body} ${msg.data}');
        try {
          try {
            final dynamic m = msg;
            String? mid;
            try {
              mid = (m.messageId as dynamic)?.toString();
            } catch (_) {}
            try {
              mid ??= m is Map ? m['messageId']?.toString() : null;
            } catch (_) {}
            logger.i(
              'FCM foreground detailed: messageId=$mid, data=${m.data}, notification_title=${m.notification?.title}, notification_body=${m.notification?.body}',
            );
          } catch (_) {}
          await NotificationRepository.instance.insertFromRemote(msg);
        } catch (_) {}
      },
      onMessageOpenedApp: (msg) async {
        logger.i('FCM opened app: ${msg.data}');
        try {
          try {
            final dynamic m = msg;
            String? mid;
            try {
              mid = (m.messageId as dynamic)?.toString();
            } catch (_) {}
            try {
              mid ??= m is Map ? m['messageId']?.toString() : null;
            } catch (_) {}
            logger.i(
              'onMessageOpenedApp raw: messageId=$mid, data=${m.data}, notification_title=${m.notification?.title}, notification_body=${m.notification?.body}',
            );
          } catch (_) {}
          await NotificationRepository.instance.insertFromRemote(msg);
        } catch (_) {}
        try {
          // Prefer persisted DB payload when navigating after a tap.
          Map<String, dynamic> navData = {};

          try {
            final dynamic m = msg;
            String? mid;
            try {
              mid = m is Map ? m['messageId']?.toString() : null;
            } catch (_) {}
            try {
              mid ??= (m.messageId as dynamic)?.toString();
            } catch (_) {}
            try {
              mid ??= (m.data is Map ? m.data['messageId'] : null)?.toString();
            } catch (_) {}

            if (mid != null && mid.isNotEmpty) {
              final stored = await NotificationRepository.instance
                  .findByMessageId(mid);
              if (stored != null) navData = stored.data ?? {};
            }
          } catch (_) {}

          if (navData.isEmpty) {
            try {
              final dynamic m = msg;
              final t = ((m.notification?.title ?? m.title ?? '') as String)
                  .toString();
              final b = ((m.notification?.body ?? m.body ?? '') as String)
                  .toString();
              if (t.isNotEmpty && b.isNotEmpty) {
                final stored2 = await NotificationRepository.instance
                    .findRecentByTitleBody(t, b, 60000);
                if (stored2 != null) navData = stored2.data ?? {};
              }
            } catch (_) {}
          }

          if (navData.isEmpty) {
            try {
              final dynamic m = msg;
              if (m.data is Map) {
                navData = Map<String, dynamic>.from(m.data as Map);
              }
            } catch (_) {}
          }

          // If navData is still empty, synthesize a payload from available
          // notification fields (title/body/image) so the detail page can
          // render useful content even when the platform-provided data
          // map is empty.
          if (navData.isEmpty) {
            try {
              final dynamic m = msg;
              final fallback = <String, dynamic>{};
              try {
                final t = (m.notification?.title ?? m.title ?? '').toString();
                final b = (m.notification?.body ?? m.body ?? '').toString();
                if (t.isNotEmpty) fallback['title'] = t;
                if (b.isNotEmpty) fallback['body'] = b;
              } catch (_) {}
              try {
                String? img;
                try {
                  img = (m.data is Map ? m.data['image'] : null)?.toString();
                } catch (_) {}
                try {
                  img ??= (m.data is Map ? m.data['image_url'] : null)
                      ?.toString();
                } catch (_) {}
                try {
                  img ??= (m.fcmOptions?.image as dynamic)?.toString();
                } catch (_) {}
                try {
                  img ??= m.notification?.android?.imageUrl?.toString();
                } catch (_) {}
                try {
                  img ??= m.notification?.apple?.imageUrl?.toString();
                } catch (_) {}
                if (img != null && img.isNotEmpty) fallback['image'] = img;
              } catch (_) {}

              if (fallback.isNotEmpty) navData = fallback;
            } catch (_) {}
          }

          // Attempt to resolve navData robustly (may retry DB reads).
          try {
            navData = await _resolveNavData(msg, navData);
          } catch (_) {}
          // Log navData for debugging when navigation happens.
          logger.i('Computed navData for navigation: $navData');

          // Use the configured global dialog service; avoid using a
          // `BuildContext` across async gaps by not awaiting navigation
          // calls that require it. If the service isn't configured we
          // can't navigate here.
          final agds = AppGlobalDialogService.instance;
          if (!agds.isConfigured) {
            logger.w(
              'AppGlobalDialogService not configured; cannot navigate on notification click.',
            );
          } else {
            final navigator = agds.navigator;
            if (navigator == null) {
              logger.w(
                'Navigator not available; cannot navigate on notification click.',
              );
              return;
            }

            // If the notification payload contains a `route` field, try to
            // navigate using the named AppRoute. Fall back to pushing the
            // FCM test page if the route is not recognized.
            final data = navData;
            if (data.containsKey('route')) {
              final routeValue = (data['route'] ?? '').toString();
              try {
                // Support absolute path deep-links: '/some/path'. Pass other
                // payload keys as query parameters.
                if (routeValue.startsWith('/')) {
                  final params = <String, String>{};
                  data.forEach((k, v) {
                    if (k == 'route' || k == 'push') return;
                    params[k] = v?.toString() ?? '';
                  });
                  final uri = Uri(
                    path: routeValue,
                    queryParameters: params.isEmpty ? null : params,
                  );
                  try {
                    navigator.pushNamed(uri.toString());
                  } catch (_) {
                    // fallback: push via MaterialPageRoute if named route not found
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const SizedBox.shrink(),
                      ),
                    );
                  }
                  return;
                }

                // Otherwise match against named AppRoute values.
                final normalized = routeValue.replaceAll('-', '_');
                final match = AppRoute.values.firstWhere(
                  (r) => r.name == routeValue || r.name == normalized,
                  orElse: () => AppRoute.fcmTest,
                );

                // Use named navigation by default; use push if payload asks for it
                final usePush =
                    (data['push'] ?? 'false').toString().toLowerCase() ==
                    'true';
                if (usePush) {
                  try {
                    navigator.pushNamed(match.name);
                  } catch (_) {
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const SizedBox.shrink(),
                      ),
                    );
                  }
                } else {
                  // If there are additional payload keys, pass them via `arguments`.
                  try {
                    if (data.keys.length > 1) {
                      navigator.pushNamed(match.name, arguments: data);
                    } else {
                      navigator.pushNamed(match.name);
                    }
                  } catch (_) {
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const SizedBox.shrink(),
                      ),
                    );
                  }
                }
                return;
              } catch (_) {
                // fall through to default push below
              }
            }

            // Default: navigate to the notification page. Build a payload
            // object that always includes a `data` map so the detail view's
            // `prettyData()` can display useful JSON.
            try {
              final payloadForNav = <String, dynamic>{};
              try {
                payloadForNav['title'] =
                    (data['title'] ??
                            data['notification_title'] ??
                            data['title'])
                        ?.toString() ??
                    '';
              } catch (_) {}
              try {
                payloadForNav['body'] =
                    (data['body'] ?? data['notification_body'] ?? data['body'])
                        ?.toString() ??
                    '';
              } catch (_) {}
              try {
                if (data.containsKey('id')) payloadForNav['id'] = data['id'];
              } catch (_) {}
              payloadForNav['data'] = data;

              navigator.push(
                MaterialPageRoute(
                  builder: (_) =>
                      notification.Presenter(payload: payloadForNav),
                  settings: RouteSettings(arguments: payloadForNav),
                ),
              );
            } catch (_) {
              final payloadForNav = <String, dynamic>{};
              try {
                payloadForNav['title'] =
                    (data['title'] ??
                            data['notification_title'] ??
                            data['title'])
                        ?.toString() ??
                    '';
              } catch (_) {}
              try {
                payloadForNav['body'] =
                    (data['body'] ?? data['notification_body'] ?? data['body'])
                        ?.toString() ??
                    '';
              } catch (_) {}
              try {
                if (data.containsKey('id')) payloadForNav['id'] = data['id'];
              } catch (_) {}
              payloadForNav['data'] = data;

              navigator.push(
                MaterialPageRoute(
                  builder: (_) =>
                      notification.Presenter(payload: payloadForNav),
                  settings: RouteSettings(arguments: payloadForNav),
                ),
              );
            }
          }
        } catch (e, st) {
          logger.w('Failed to navigate on notification click: $e\n$st');
          try {
            // Log payload for easier debugging
            logger.w('Notification payload (for debug): ${msg.data}');

            // Attempt a safe fallback navigation to the FCM test page
            final fallbackNav = AppGlobalDialogService.instance.navigator;
            if (fallbackNav == null) {
              logger.w(
                'Fallback navigator not available; cannot navigate to FCM Test.',
              );
              return;
            }
            fallbackNav.push(
              MaterialPageRoute(
                builder: (_) => const fcm_test.Presenter(),
                settings: RouteSettings(arguments: msg.data),
              ),
            );
            try {
              if (fallbackNav.mounted) {
                ScaffoldMessenger.maybeOf(fallbackNav.context)?.showSnackBar(
                  const SnackBar(content: Text('Opened FCM Test (fallback)')),
                );
              }
            } catch (_) {}
          } catch (e2, st2) {
            logger.w('Fallback navigation also failed: $e2\n$st2');
          }
        }
      },
      onToken: (token) async {
        logger.i('FCM token: $token');
        try {
          final prefs = await SharedPreferences.getInstance();
          if (token.isNotEmpty) await prefs.setString('fcm_token', token);
        } catch (_) {}
      },
      onTokenRefresh: (newToken) async {
        logger.i('FCM token refreshed: $newToken');
        try {
          final p = await SharedPreferences.getInstance();
          await p.setString('fcm_token', newToken);
        } catch (_) {}
      },
    );
    // Initial message handling is performed later in View.initState(), where
    // navigation can safely wait for the root navigator and global dialog
    // service to become available. Avoid consuming and navigating here to
    // prevent early/incorrect navData during startup.
    // FCM token retrieval and refresh handling moved into FCMService.initialize().
  } catch (e, st) {
    logger.w('FCM initialization failed (example): $e\n$st');
  }

  // Start the app
  // Register a lifecycle observer that refreshes notifications when the
  // app resumes. This ensures the main isolate reloads DB rows inserted
  // by background handlers and updates UI counts.
  try {
    WidgetsBinding.instance.addObserver(_appLifecycleObserver);
  } catch (_) {}

  runApp(const MyApp());
}

// Lifecycle observer that refreshes the notification repository on resume.
class _AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.resumed) {
        // Call `all()` which triggers an immediate stream emission.
        NotificationRepository.instance.all();
      }
    } catch (_) {}
  }
}

final _appLifecycleObserver = _AppLifecycleObserver();

// Resolve navigation data robustly: prefer DB-stored payloads (by messageId
// or recent title+body). If not immediately present, retry a few times to
// allow background handlers to finish inserting, then synthesize a
// fallback from notification fields (title/body/image) so the UI can
// render useful content.
Future<Map<String, dynamic>> _resolveNavData(
  dynamic m,
  Map<String, dynamic> navData,
) async {
  try {
    if (navData.isNotEmpty) return navData;

    String? mid;
    try {
      mid = m is Map ? m['messageId']?.toString() : null;
    } catch (_) {}
    try {
      mid ??= (m.messageId as dynamic)?.toString();
    } catch (_) {}
    try {
      mid ??= (m.data is Map ? m.data['messageId'] : null)?.toString();
    } catch (_) {}

    if (mid != null && mid.isNotEmpty) {
      try {
        final stored = await NotificationRepository.instance.findByMessageId(
          mid,
        );
        if (stored != null && (stored.data?.isNotEmpty ?? false)) {
          final out = <String, dynamic>{};
          try {
            out.addAll(Map<String, dynamic>.from(stored.data ?? {}));
          } catch (_) {}
          try {
            out['id'] = stored.id;
          } catch (_) {}
          try {
            if (!out.containsKey('title') && stored.title != null) {
              out['title'] = stored.title;
            }
          } catch (_) {}
          try {
            if (!out.containsKey('body') && stored.body != null) {
              out['body'] = stored.body;
            }
          } catch (_) {}
          return out;
        }
      } catch (_) {}
    }

    String t = '';
    String b = '';
    try {
      t = ((m.notification?.title ?? m.title ?? m.title) ?? '').toString();
    } catch (_) {}
    try {
      b = ((m.notification?.body ?? m.body ?? m.body) ?? '').toString();
    } catch (_) {}

    if (t.isNotEmpty && b.isNotEmpty) {
      try {
        final stored2 = await NotificationRepository.instance
            .findRecentByTitleBody(t, b, 60000);
        if (stored2 != null && (stored2.data?.isNotEmpty ?? false)) {
          final out = <String, dynamic>{};
          try {
            out.addAll(Map<String, dynamic>.from(stored2.data ?? {}));
          } catch (_) {}
          try {
            out['id'] = stored2.id;
          } catch (_) {}
          try {
            if (!out.containsKey('title') && stored2.title != null) {
              out['title'] = stored2.title;
            }
          } catch (_) {}
          try {
            if (!out.containsKey('body') && stored2.body != null) {
              out['body'] = stored2.body;
            }
          } catch (_) {}
          return out;
        }
      } catch (_) {}
    }

    // Retry a few times to allow the background isolate to finish inserting.
    final delays = [100, 300, 600];
    for (final ms in delays) {
      await Future.delayed(Duration(milliseconds: ms));
      try {
        if (mid != null && mid.isNotEmpty) {
          final stored = await NotificationRepository.instance.findByMessageId(
            mid,
          );
          if (stored != null && (stored.data?.isNotEmpty ?? false)) {
            return stored.data ?? {};
          }
        }
      } catch (_) {}
      try {
        if (t.isNotEmpty && b.isNotEmpty) {
          final stored2 = await NotificationRepository.instance
              .findRecentByTitleBody(t, b, 60000);
          if (stored2 != null && (stored2.data?.isNotEmpty ?? false)) {
            return stored2.data ?? {};
          }
        }
      } catch (_) {}
    }

    // Synthesize fallback from notification fields.
    final fallback = <String, dynamic>{};
    try {
      if (t.isNotEmpty) fallback['title'] = t;
    } catch (_) {}
    try {
      if (b.isNotEmpty) fallback['body'] = b;
    } catch (_) {}
    try {
      String? img;
      try {
        img = (m.data is Map ? m.data['image'] : null)?.toString();
      } catch (_) {}
      try {
        img ??= (m.data is Map ? m.data['image_url'] : null)?.toString();
      } catch (_) {}
      try {
        img ??= (m.fcmOptions?.image as dynamic)?.toString();
      } catch (_) {}
      try {
        img ??= m.notification?.android?.imageUrl?.toString();
      } catch (_) {}
      try {
        img ??= m.notification?.apple?.imageUrl?.toString();
      } catch (_) {}
      if (img != null && img.isNotEmpty) fallback['image'] = img;
    } catch (_) {}

    return fallback;
  } catch (_) {
    return navData;
  }
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
  final mapsKeyStatus =
      config.androidMapsApiKey.contains('DEBUG') ||
          config.androidMapsApiKey.contains('BETA') ||
          config.androidMapsApiKey.contains('PROD')
      ? '⚠️  Placeholder'
      : '✅ Configured';
  logger.i('   Maps API Key: $mapsKeyStatus');

  // Permissions
  logger.i('\n🔐 CONFIGURED PERMISSIONS:');
  final hasCamera = config.hasAndroidPermission('android.permission.CAMERA');
  final hasGallery = config.hasAndroidPermission(
    'android.permission.READ_MEDIA_IMAGES',
  );
  final hasNotification = config.hasAndroidPermission(
    'android.permission.POST_NOTIFICATIONS',
  );

  logger.i('   📷 Camera: ${hasCamera ? "✅ Enabled" : "❌ Disabled"}');
  logger.i('   🖼️  Gallery: ${hasGallery ? "✅ Enabled" : "❌ Disabled"}');
  logger.i(
    '   🔔 Notifications: ${hasNotification ? "✅ Enabled" : "❌ Disabled"}',
  );
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
        config.hasAndroidPermission(
          'android.permission.READ_EXTERNAL_STORAGE',
        )) {
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
    List<Permission> deniedPermissions,
  ) async {
    // Convert permission names to localization keys
    final permissionNames = deniedPermissions
        .map((p) {
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
        })
        .join(', ');

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
  void initState() {
    super.initState();

    // Consume any initial FCM message that opened the app (terminated -> launched)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Immediately-invoked async closure: wait for the global dialog
      // service to be configured (retry briefly) and then handle the
      // initial FCM message.
      () async {
        int tries = 0;
        // Wait longer for the root navigator/context to become available.
        // Initial app frames can be slower on some devices; allow up to
        // ~2 seconds (125 * 16ms) before giving up.
        const int maxTries = 125; // ~125 frames ~= ~2000ms on 60Hz

        while (true) {
          final agds = AppGlobalDialogService.instance;
          // Consider configured either when the service has a context or
          // when the root navigator's context becomes available.
          if (agds.isConfigured ||
              viewModel.rootNavigatorKey.currentContext != null) {
            break;
          }
          tries++;
          if (tries > maxTries) {
            logger.w(
              'AppGlobalDialogService not configured after retries; cannot navigate on initial notification.',
            );
            return;
          }
          // wait approx one frame
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }

        try {
          final initial = await FCMService.instance.consumeInitialMessage();
          try {
            if (initial == null) return;

            logger.i(
              'Handling initial FCM message (app launch): ${initial.data}',
            );
            final data = initial.data;

            // Navigate to the notification page directly to ensure the
            // payload is passed into the presenter (router integration can
            // sometimes transform/omit route arguments).
            final navigator = viewModel.rootNavigatorKey.currentState;
            if (navigator == null) {
              logger.w(
                'Root navigator not available; cannot navigate on initial notification.',
              );
              return;
            }
            final payloadForNav = <String, dynamic>{};
            try {
              payloadForNav['title'] =
                  (data['title'] ?? initial.title ?? '')?.toString() ?? '';
            } catch (_) {}
            try {
              payloadForNav['body'] =
                  (data['body'] ?? initial.body ?? '')?.toString() ?? '';
            } catch (_) {}
            try {
              if (data.containsKey('id')) payloadForNav['id'] = data['id'];
            } catch (_) {}
            payloadForNav['data'] = data;
            navigator.push(
              MaterialPageRoute(
                builder: (_) => notification.Presenter(payload: payloadForNav),
                settings: RouteSettings(arguments: payloadForNav),
              ),
            );
          } catch (e, st) {
            logger.w('Failed to handle initial FCM message: $e\n$st');
          }
        } catch (_) {}
      }();
    });
  }

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
            builder: (context, child) {
              // Wrap the router child so we can show an always-available
              // FAB to open the FCM test page from anywhere in the app.
              return Stack(
                children: [
                  ?child,
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Builder(
                      builder: (fabContext) => FloatingActionButton.extended(
                        icon: const Icon(Icons.bug_report),
                        label: const Text('FCM Test'),
                        onPressed: () {
                          viewModel.rootNavigatorKey.currentContext?.pushRoute(
                            AppRoute.fcmTest,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
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
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      // datePickerTheme: DatePickerThemeData(
      //   backgroundColor: Colors.white,
      //   headerBackgroundColor: const Color(0xFFF6F6FB),
      //   headerForegroundColor: seedColor,
      //   headerHeadlineStyle:
      //       TextStyle(color: seedColor, fontWeight: FontWeight.w700),
      //   headerHelpStyle: TextStyle(color: seedColor),
      //   dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.selected)) {
      //       return Colors.white;
      //     }
      //     if (states.contains(WidgetState.disabled)) {
      //       return Colors.grey.shade600;
      //     }
      //     return null;
      //   }),
      //   dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.selected)) {
      //       return seedColor;
      //     }
      //     return null;
      //   }),
      //   dayOverlayColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.pressed)) {
      //       return seedColor.withValues(alpha: 0.12);
      //     }
      //     if (states.contains(WidgetState.hovered)) {
      //       return seedColor.withValues(alpha: 0.08);
      //     }
      //     return null;
      //   }),
      //   todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.selected)) {
      //       return Colors.white;
      //     }
      //     return seedColor;
      //   }),
      //   todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.selected)) {
      //       return seedColor;
      //     }
      //     return const Color(0xFFF6F6FB);
      //   }),
      // todayBorder: BorderSide(color: seedColor, width: 1),
      // rangePickerBackgroundColor: Colors.white,
      // rangePickerHeaderBackgroundColor: const Color(0xFFF6F6FB),
      // rangePickerHeaderForegroundColor: seedColor,
      // rangePickerHeaderHeadlineStyle:
      //     TextStyle(color: seedColor, fontWeight: FontWeight.w700),
      // rangePickerHeaderHelpStyle: TextStyle(color: seedColor),
      // toggleButtonTextStyle: const TextStyle(color: Colors.white),
      // rangeSelectionBackgroundColor: seedColor.withValues(alpha: 0.12),
      // rangeSelectionOverlayColor:
      //     WidgetStatePropertyAll(seedColor.withValues(alpha: 0.08)),
      // dividerColor: const Color(0xFFF6F6FB),
      // cancelButtonStyle: ButtonStyle(
      //     foregroundColor: WidgetStateProperty.resolveWith((states) {
      //       return Colors.grey.shade800;
      //     }),
      //     backgroundColor: WidgetStatePropertyAll(Colors.transparent)),
      // confirmButtonStyle: TextButton.styleFrom(
      //   backgroundColor: Colors.blue,
      //   foregroundColor: Colors.white,
      // ),

      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      // ),
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
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          backgroundColor: WidgetStatePropertyAll(seedColor),
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          ),
          alignment: Alignment.center,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(color: seedColor, width: 1),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(seedColor),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          textStyle: WidgetStatePropertyAll(
            const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(seedColor),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          textStyle: WidgetStatePropertyAll(
            const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(seedColor),
          side: WidgetStatePropertyAll(BorderSide(color: seedColor)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
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
            backgroundColor: WidgetStatePropertyAll(seedColor),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.bold),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          filledStyle: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(seedColor),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.bold),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          outlinedStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(seedColor),
            side: WidgetStatePropertyAll(BorderSide(color: seedColor)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          textStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(seedColor),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          iconBackgroundColor: Colors.white,
          fabBackgroundColor: Colors.white,
          iconStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(seedColor),
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
    return MaterialApp(
      // Provide localization delegates so loading text is localized
      localizationsDelegates: const [
        loc.LocalizationsDelegate(),
        FormFieldsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: loc.Localizations.supportedLocales,
      home: const SafeScaffold(
        body: Center(child: CircularProgressIndicator()),
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
  late final routerConfig = createAppRouter(
    appState,
    navigatorKey: rootNavigatorKey,
  );

  ViewModel() {
    AppGlobalDialogService.instance.configure(rootNavigatorKey);
  }

  /// Clean up resources on app dispose
  void dispose() {
    appState.dispose();
  }
}
