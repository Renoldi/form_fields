/// Build Configuration System
///
/// Centralized configuration for build settings across all platforms.
/// Handles Android, iOS, macOS, Windows, Linux, and Web platforms.
///
/// ⚠️ IMPORTANT: Configuration values are stored in build_settings.dart
/// To change settings, use: dart run tool/configure_build.dart
///
/// Usage:
/// - Access current config: BuildConfig.current
/// - Get environment-specific settings: BuildConfig.androidConfig()
/// - Access API keys: BuildConfig.current.mapsApiKey
/// - Get permissions: BuildConfig.current.androidPermissions

import 'package:form_fields_example/config/environment.dart';
import 'package:form_fields_example/config/build_settings.dart';

/// Build Configuration Class
/// Centralizes all build settings for cross-platform support
class BuildConfig {
  // ============================================================================
  // STATIC DEFAULTS (Android, iOS, macOS, Windows, Linux)
  // ============================================================================

  /// Default namespace for Android package
  static const String defaultAndroidNamespace =
      'com.example.form_fields_example';

  /// Default compileSdk for Android
  static const int defaultAndroidCompileSdk = 36;

  /// Default NDK Version (for native libraries)
  static const String defaultNdkVersion = '27.0.12077973';

  /// Default minimum SDK for Android
  static const int defaultAndroidMinSdk = 21;

  /// Default target SDK for Android
  static const int defaultAndroidTargetSdk = 36;

  /// Default version code (must increment for releases)
  static const int defaultVersionCode = 1;

  /// Default version name (semantic versioning)
  static const String defaultVersionName = '1.0.0';

  /// iOS minimum deployment target
  static const String defaultIosMinimumDeploymentTarget = '12.0';

  /// macOS minimum deployment target
  static const String defaultMacosMinimumDeploymentTarget = '10.15';

  /// Windows minimum target version
  static const int defaultWindowsMinimumVersion = 10;

  /// Web platform name
  static const String webPlatformName = 'flutter_web';

  // ============================================================================
  // API KEYS (⚠️ SECURITY: Do NOT commit API keys to repository!)
  // ============================================================================

  /// Google Maps API Key
  ///
  /// SETUP INSTRUCTIONS:
  /// 1. Create your own API key at: https://console.cloud.google.com
  /// 2. Enable Google Maps API and Places API
  /// 3. Create an Android API key with your app's SHA-1 fingerprint:
  ///    - Get SHA-1: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ///    - Restrict to Android apps and add package name + SHA-1
  /// 4. For iOS: Create an iOS API key in Google Cloud Console
  /// 5. Set these values locally (NEVER commit to repo)
  /// 6. Add to .gitignore: lib/config/api_keys.dart
  static String get mapsApiKey {
    // 🔐 LOCAL SETUP: Replace with your actual key
    // Option 1: Set directly here (local development only)
    // return 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

    // Option 2: Load from environment-specific file (recommended)
    return _getEnvironmentSpecificMapsKey();
  }

  /// Get environment-specific Maps API key
  static String _getEnvironmentSpecificMapsKey() {
    switch (EnvironmentConfig.current) {
      case AppEnvironment.production:
        return 'PROD_GOOGLE_MAPS_API_KEY'; // Replace with production key
      case AppEnvironment.beta:
        return 'BETA_GOOGLE_MAPS_API_KEY'; // Replace with beta key
      case AppEnvironment.debug:
        return 'DEBUG_GOOGLE_MAPS_API_KEY'; // Replace with debug key
    }
  }

  /// Other API Keys (extend as needed)
  /// - Firebase API Key
  /// - Weather API Key
  /// - Payment API Key
  /// etc.

  // ============================================================================
  // ANDROID CONFIGURATION
  // ============================================================================

  /// Android application namespace (unique identifier)
  final String androidNamespace;

  /// Android compile SDK version
  final int androidCompileSdk;

  /// Android NDK version (for native library compilation)
  final String ndkVersion;

  /// Android minimum SDK version
  final int androidMinSdk;

  /// Android target SDK version
  final int androidTargetSdk;

  /// Your Maps API key for Android
  final String androidMapsApiKey;

  /// Android manifest permissions
  final List<String> androidPermissions;

  // ============================================================================
  // VERSION CONFIGURATION (Cross-Platform)
  // ============================================================================

  /// Application version code (increment for each release)
  /// Used for version comparison in app stores
  final int versionCode;

  /// Application version name (semantic versioning)
  /// Format: major.minor.patch (e.g., 1.0.0)
  final String versionName;

  // ============================================================================
  // iOS CONFIGURATION
  // ============================================================================

  /// iOS minimum deployment target
  final String iosMinimumDeploymentTarget;

  /// Your Maps API key for iOS
  final String iosMapsApiKey;

  // ============================================================================
  // macOS CONFIGURATION
  // ============================================================================

  /// macOS minimum deployment target
  final String macosMinimumDeploymentTarget;

  // ============================================================================
  // Windows CONFIGURATION
  // ============================================================================

  /// Windows minimum version (Windows 10 = 10, Windows 11 = 11)
  final int windowsMinimumVersion;

  // ============================================================================
  // Web CONFIGURATION
  // ============================================================================

  /// Web domain/host (for CORS and security policies)
  final String webDomain;

  // ============================================================================
  // CONSTRUCTOR & INITIALIZATION
  // ============================================================================

  BuildConfig({
    required this.androidNamespace,
    required this.androidCompileSdk,
    required this.ndkVersion,
    required this.androidMinSdk,
    required this.androidTargetSdk,
    required this.androidMapsApiKey,
    required this.androidPermissions,
    required this.versionCode,
    required this.versionName,
    required this.iosMinimumDeploymentTarget,
    required this.iosMapsApiKey,
    required this.macosMinimumDeploymentTarget,
    required this.windowsMinimumVersion,
    required this.webDomain,
  });

  // ============================================================================
  // FACTORY CONSTRUCTORS (Environment-Specific)
  // ============================================================================

  /// Create DEBUG configuration (reads from build_settings.dart)
  factory BuildConfig.debug() {
    return BuildConfig(
      androidNamespace: DebugBuildSettings.androidNamespace,
      androidCompileSdk: DebugBuildSettings.androidCompileSdk,
      ndkVersion: DebugBuildSettings.ndkVersion,
      androidMinSdk: DebugBuildSettings.androidMinSdk,
      androidTargetSdk: DebugBuildSettings.androidTargetSdk,
      androidMapsApiKey: DebugBuildSettings.androidMapsApiKey,
      androidPermissions: List.from(DebugBuildSettings.androidPermissions),
      versionCode: DebugBuildSettings.versionCode,
      versionName: DebugBuildSettings.versionName,
      iosMinimumDeploymentTarget: DebugBuildSettings.iosMinimumDeploymentTarget,
      iosMapsApiKey: DebugBuildSettings.iosMapsApiKey,
      macosMinimumDeploymentTarget:
          DebugBuildSettings.macosMinimumDeploymentTarget,
      windowsMinimumVersion: DebugBuildSettings.windowsMinimumVersion,
      webDomain: DebugBuildSettings.webDomain,
    );
  }

  /// Create BETA configuration (reads from build_settings.dart)
  factory BuildConfig.beta() {
    return BuildConfig(
      androidNamespace: BetaBuildSettings.androidNamespace,
      androidCompileSdk: BetaBuildSettings.androidCompileSdk,
      ndkVersion: BetaBuildSettings.ndkVersion,
      androidMinSdk: BetaBuildSettings.androidMinSdk,
      androidTargetSdk: BetaBuildSettings.androidTargetSdk,
      androidMapsApiKey: BetaBuildSettings.androidMapsApiKey,
      androidPermissions: List.from(BetaBuildSettings.androidPermissions),
      versionCode: BetaBuildSettings.versionCode,
      versionName: BetaBuildSettings.versionName,
      iosMinimumDeploymentTarget: BetaBuildSettings.iosMinimumDeploymentTarget,
      iosMapsApiKey: BetaBuildSettings.iosMapsApiKey,
      macosMinimumDeploymentTarget:
          BetaBuildSettings.macosMinimumDeploymentTarget,
      windowsMinimumVersion: BetaBuildSettings.windowsMinimumVersion,
      webDomain: BetaBuildSettings.webDomain,
    );
  }

  /// Create PRODUCTION configuration (reads from build_settings.dart)
  factory BuildConfig.production() {
    return BuildConfig(
      androidNamespace: ProductionBuildSettings.androidNamespace,
      androidCompileSdk: ProductionBuildSettings.androidCompileSdk,
      ndkVersion: ProductionBuildSettings.ndkVersion,
      androidMinSdk: ProductionBuildSettings.androidMinSdk,
      androidTargetSdk: ProductionBuildSettings.androidTargetSdk,
      androidMapsApiKey: ProductionBuildSettings.androidMapsApiKey,
      androidPermissions: List.from(ProductionBuildSettings.androidPermissions),
      versionCode: ProductionBuildSettings.versionCode,
      versionName: ProductionBuildSettings.versionName,
      iosMinimumDeploymentTarget:
          ProductionBuildSettings.iosMinimumDeploymentTarget,
      iosMapsApiKey: ProductionBuildSettings.iosMapsApiKey,
      macosMinimumDeploymentTarget:
          ProductionBuildSettings.macosMinimumDeploymentTarget,
      windowsMinimumVersion: ProductionBuildSettings.windowsMinimumVersion,
      webDomain: ProductionBuildSettings.webDomain,
    );
  }

  /// Create custom configuration
  factory BuildConfig.custom({
    String? androidNamespace,
    int? androidCompileSdk,
    String? ndkVersion,
    int? androidMinSdk,
    int? androidTargetSdk,
    String? androidMapsApiKey,
    List<String>? androidPermissions,
    int? versionCode,
    String? versionName,
    String? iosMinimumDeploymentTarget,
    String? iosMapsApiKey,
    String? macosMinimumDeploymentTarget,
    int? windowsMinimumVersion,
    String? webDomain,
  }) {
    return BuildConfig(
      androidNamespace: androidNamespace ?? defaultAndroidNamespace,
      androidCompileSdk: androidCompileSdk ?? defaultAndroidCompileSdk,
      ndkVersion: ndkVersion ?? defaultNdkVersion,
      androidMinSdk: androidMinSdk ?? defaultAndroidMinSdk,
      androidTargetSdk: androidTargetSdk ?? defaultAndroidTargetSdk,
      androidMapsApiKey: androidMapsApiKey ?? mapsApiKey,
      androidPermissions: androidPermissions ?? [],
      versionCode: versionCode ?? defaultVersionCode,
      versionName: versionName ?? defaultVersionName,
      iosMinimumDeploymentTarget:
          iosMinimumDeploymentTarget ?? defaultIosMinimumDeploymentTarget,
      iosMapsApiKey: iosMapsApiKey ?? mapsApiKey,
      macosMinimumDeploymentTarget:
          macosMinimumDeploymentTarget ?? defaultMacosMinimumDeploymentTarget,
      windowsMinimumVersion:
          windowsMinimumVersion ?? defaultWindowsMinimumVersion,
      webDomain: webDomain ?? 'example.com',
    );
  }

  // ============================================================================
  // STATIC GETTER FOR CURRENT CONFIGURATION
  // ============================================================================

  /// Get current BuildConfig based on active environment
  static BuildConfig get current {
    switch (EnvironmentConfig.current) {
      case AppEnvironment.debug:
        return BuildConfig.debug();
      case AppEnvironment.beta:
        return BuildConfig.beta();
      case AppEnvironment.production:
        return BuildConfig.production();
    }
  }

  // ============================================================================
  // CONFIGURATION GENERATORS (for build.gradle integration)
  // ============================================================================

  /// Get Android build configuration as formatted string
  /// Can be used to generate build.gradle configuration
  String get androidBuildGradleConfig {
    return '''
    namespace = "$androidNamespace"
    compileSdk = $androidCompileSdk
    ndkVersion = "$ndkVersion"
    
    defaultConfig {
        minSdk = $androidMinSdk
        targetSdk = $androidTargetSdk
        versionCode = $versionCode
        versionName = "$versionName"
        
        // Maps API Key
        manifestPlaceholders = ["MAPS_API_KEY": "$androidMapsApiKey"]
    }
''';
  }

  /// Get Android AndroidManifest.xml permissions as formatted string
  String get androidManifestPermissions {
    return androidPermissions
        .map((p) => '    <uses-permission android:name="$p" />')
        .join('\n');
  }

  /// Get iOS Podfile configuration
  String get iosPodfieConfig {
    return '''
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',
        'MAPS_API_KEY=$iosMapsApiKey'
      ]
    end
  end
end
''';
  }

  /// Get macOS Podfile configuration
  String get macosPodfieConfig {
    return '''
platform :osx, '$macosMinimumDeploymentTarget'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_osx_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',
        'MAPS_API_KEY=$iosMapsApiKey'
      ]
    end
  end
end
''';
  }

  /// Get Web configuration
  String get webConfig {
    return '''
<!-- Add to web/index.html head -->
<script src="https://maps.googleapis.com/maps/api/js?key=$iosMapsApiKey&libraries=places"></script>
<!-- Update domain in web/manifest.json -->
<!-- "start_url": "https://$webDomain" -->
''';
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if configuration is valid for production
  bool get isProductionReady {
    return androidMapsApiKey.isNotEmpty &&
        !androidMapsApiKey.contains('YOUR_') &&
        !androidMapsApiKey.contains('DEBUG_') &&
        !androidMapsApiKey.contains('BETA_') &&
        iosMapsApiKey.isNotEmpty &&
        !iosMapsApiKey.contains('YOUR_') &&
        !iosMapsApiKey.contains('DEBUG_') &&
        !iosMapsApiKey.contains('BETA_');
  }

  /// Combine permissions with duplicates removed
  List<String> get uniqueAndroidPermissions {
    return androidPermissions.toSet().toList();
  }

  /// Check if specific permission is granted
  bool hasAndroidPermission(String permission) {
    return androidPermissions.contains(permission);
  }

  /// Add additional permission
  void addAndroidPermission(String permission) {
    if (!androidPermissions.contains(permission)) {
      androidPermissions.add(permission);
    }
  }

  /// Remove permission
  void removeAndroidPermission(String permission) {
    androidPermissions.remove(permission);
  }

  // ============================================================================
  // DEBUG OUTPUT
  // ============================================================================

  @override
  String toString() {
    return '''
BuildConfig (${EnvironmentConfig.currentName}):
  Android:
    - Namespace: $androidNamespace
    - compileSdk: $androidCompileSdk
    - ndkVersion: $ndkVersion
    - minSdk: $androidMinSdk
    - targetSdk: $androidTargetSdk
    - Maps API Key: ${androidMapsApiKey.replaceRange(4, androidMapsApiKey.length - 4, '****')}
    - Permissions: ${uniqueAndroidPermissions.length} configured
  
  Version:
    - versionCode: $versionCode
    - versionName: $versionName
  
  Platforms:
    - iOS minimum: $iosMinimumDeploymentTarget
    - macOS minimum: $macosMinimumDeploymentTarget
    - Windows minimum: Windows $windowsMinimumVersion
    - Web domain: $webDomain
  
  Status: ${isProductionReady ? '✅ Production Ready' : '⚠️ Needs API Keys'}
''';
  }
}
