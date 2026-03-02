// ============================================================================
// ENVIRONMENT CONFIGURATION
// ============================================================================
//
// This file manages API endpoints for different environments.
// Change Environment.current to switch between configurations.
//
// Usage in code:
// ```dart
// final baseUrl = Environment.current.baseUrl;
// final apiVersion = Environment.current.apiVersion;
// ```
// ============================================================================

/// Defines available environments for the application
enum AppEnvironment {
  /// Production environment - stable release
  production,

  /// Beta environment - testing new features
  beta,

  /// Debug environment - development and testing
  debug,
}

/// Environment configuration with API endpoints and settings
///
/// This class holds all environment-specific configuration in one place.
/// Makes it easy to manage multiple APIs and environments.
class EnvironmentConfig {
  /// Current active environment (set this to switch environments)
  static AppEnvironment current = AppEnvironment.debug;

  /// Get the appropriate configuration for the current environment
  static EnvironmentSettings get config {
    switch (current) {
      case AppEnvironment.production:
        return _ProductionConfig();
      case AppEnvironment.beta:
        return _BetaConfig();
      case AppEnvironment.debug:
        return _DebugConfig();
    }
  }

  /// Get config for a specific environment
  static EnvironmentSettings getConfig(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.production:
        return _ProductionConfig();
      case AppEnvironment.beta:
        return _BetaConfig();
      case AppEnvironment.debug:
        return _DebugConfig();
    }
  }

  // ========================================================================
  // CONVENIENCE SHORTCUTS
  // ========================================================================

  /// Get current environment name
  static String get currentName => config.name;

  /// Get current base URL
  static String get currentBaseUrl => config.baseUrl;

  /// Get current API endpoint
  static String get currentApiEndpoint => config.apiEndpoint;

  /// Check if current environment is debug
  static bool get isDebug => config.isDebugMode;

  /// Check if current environment is production
  static bool get isProduction => current == AppEnvironment.production;

  /// Check if current environment is beta
  static bool get isBeta => current == AppEnvironment.beta;

  // ========================================================================
  // API ENDPOINT SHORTCUTS (for User & Auth)
  // ========================================================================

  /// Get auth login endpoint for current environment
  static String get authLoginUrl => config.authLoginEndpoint;

  /// Get auth me endpoint for current environment
  static String get authMeUrl => config.authMeEndpoint;

  /// Get user update endpoint for current environment
  static String get userUpdateUrl => config.userUpdateEndpoint;

  /// Get user get endpoint for current environment
  static String get userGetUrl => config.userGetEndpoint;
}

// ============================================================================
// BASE SETTINGS
// ============================================================================

/// Base class for environment settings
///
/// Defines the interface that all environment configurations must implement.
abstract class EnvironmentSettings {
  /// Display name of the environment (shown in logs & UI)
  String get name;

  /// API base URL for this environment
  String get baseUrl;

  /// API version path (e.g., '/api/v1')
  String get apiVersion;

  /// Full API endpoint (base URL + version)
  String get apiEndpoint => '$baseUrl$apiVersion';

  /// Connection timeout in seconds
  int get connectTimeout => 10;

  /// Send timeout in seconds
  int get sendTimeout => 10;

  /// Receive timeout in seconds
  int get receiveTimeout => 15;

  /// Whether to show detailed logs
  bool get isDebugMode => false;

  /// Environment-specific HTTP headers
  Map<String, dynamic> get customHeaders => {};

  // ========================================================================
  // USER & AUTH ENDPOINTS
  // ========================================================================

  /// User login endpoint
  String get authLoginEndpoint => '/auth/login';

  /// Get current user info endpoint
  String get authMeEndpoint => '/auth/me';

  /// Update user endpoint (/{id} appended dynamically)
  String get userUpdateEndpoint => '/users';

  /// Get user by ID endpoint (/{id} appended dynamically)
  String get userGetEndpoint => '/users';
}

// ============================================================================
// PRODUCTION CONFIGURATION
// ============================================================================

/// Production environment configuration
///
/// Uses:
/// - Stable production API
/// - Production database
/// - Minimal logging
/// - Longer timeouts for reliability
class _ProductionConfig extends EnvironmentSettings {
  @override
  String get name => '🚀 PRODUCTION';

  @override
  String get baseUrl => 'https://api.dummyjson.com';

  @override
  String get apiVersion => '';

  @override
  int get connectTimeout => 15;

  @override
  int get sendTimeout => 15;

  @override
  int get receiveTimeout => 20;

  @override
  bool get isDebugMode => false;

  @override
  Map<String, dynamic> get customHeaders => {
        'Environment': 'Production',
      };
}

// ============================================================================
// BETA CONFIGURATION
// ============================================================================

/// Beta environment configuration
///
/// Uses:
/// - Beta/staging API for testing new features
/// - Separate database (mirrors production)
/// - Moderate logging
/// - Balanced timeouts
class _BetaConfig extends EnvironmentSettings {
  @override
  String get name => '🧪 BETA';

  @override
  String get baseUrl => 'https://beta-api.dummyjson.com';

  @override
  String get apiVersion => '';

  @override
  int get connectTimeout => 12;

  @override
  int get sendTimeout => 12;

  @override
  int get receiveTimeout => 18;

  @override
  bool get isDebugMode => false;

  @override
  Map<String, dynamic> get customHeaders => {
        'Environment': 'Beta',
      };
}

// ============================================================================
// DEBUG CONFIGURATION
// ============================================================================

/// Debug environment configuration
///
/// Uses:
/// - Local or development API
/// - Development database
/// - Detailed logging for debugging
/// - Shorter timeouts for faster feedback
class _DebugConfig extends EnvironmentSettings {
  @override
  String get name => '🐛 DEBUG';

  // Using public dummy API for demo purposes
  @override
  String get baseUrl => 'https://dummyjson.com';

  @override
  String get apiVersion => '';

  @override
  int get connectTimeout => 8;

  @override
  int get sendTimeout => 8;

  @override
  int get receiveTimeout => 12;

  @override
  bool get isDebugMode => true;

  @override
  Map<String, dynamic> get customHeaders => {
        'Environment': 'Debug',
        'X-Debug-Mode': 'true',
      };
}
