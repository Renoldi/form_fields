import 'dart:io';

void main(List<String> args) {
  final config = _parseArgs(args);
  if (config.showHelp) {
    _printUsage();
    exit(0);
  }

  final root = Directory.current.path;
  final changes = <String>[];

  try {
    _updateMainDart(root, config, changes);
    _updateEnvironmentConfig(root, config, changes);
    _updateBuildConfig(root, config, changes);

    _updateAndroidGradle(root, config, changes);
    _updateAndroidManifest(root, config, changes);
    _updateMainActivity(root, config, changes);

    _updateOptionalIos(root, config, changes);
    _updateIosPodfile(root, config, changes);
    _updateOptionalMacos(root, config, changes);
    _updateMacosPodfile(root, config, changes);
    _updateOptionalWeb(root, config, changes);
    _updateOptionalWindows(root, config, changes);
    _updateOptionalLinux(root, config, changes);

    stdout.writeln('✅ Configuration applied successfully');
    for (final item in changes) {
      stdout.writeln('  - $item');
    }

    // Build for platforms (unless skipped)
    if (!config.skipBuild) {
      _buildForPlatforms(root, config.buildPlatforms);
    } else {
      stdout.writeln('\n⏭️ Skipped build (--skip-build flag set)');
    }
  } catch (error) {
    stderr.writeln('❌ Failed to apply config: $error');
    exit(1);
  }
}

class _Config {
  _Config({
    required this.environment,
    required this.baseUrl,
    required this.namespace,
    required this.compileSdk,
    required this.ndkVersion,
    required this.minSdk,
    required this.targetSdk,
    required this.versionCode,
    required this.versionName,
    required this.mapsKey,
    required this.enableCamera,
    required this.enableGallery,
    required this.enableNotification,
    required this.showHelp,
    required this.skipBuild,
    required this.buildPlatforms,
  });

  final String environment;
  final String baseUrl;
  final String namespace;
  final int compileSdk;
  final String ndkVersion;
  final int minSdk;
  final int targetSdk;
  final int versionCode;
  final String versionName;
  final String mapsKey;
  final bool enableCamera;
  final bool enableGallery;
  final bool enableNotification;
  final bool showHelp;
  final bool skipBuild;
  final List<String> buildPlatforms;

  String get environmentEnum => 'AppEnvironment.$environment';

  String get envKeyPrefix => environment.toUpperCase();

  String get envFactoryName {
    switch (environment) {
      case 'production':
        return 'production';
      case 'beta':
        return 'beta';
      default:
        return 'debug';
    }
  }

  String get androidNamespace {
    if (environment == 'production') return namespace;
    if (environment == 'beta') return '$namespace.beta';
    return '$namespace.debug';
  }

  List<String> get androidPermissions {
    final permissions = <String>[
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
      'android.permission.CHANGE_NETWORK_STATE',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
    ];

    if (enableCamera) {
      permissions.add('android.permission.CAMERA');
    }

    if (enableGallery) {
      permissions.addAll([
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_EXTERNAL_STORAGE',
      ]);
    }

    if (enableNotification) {
      permissions.add('android.permission.POST_NOTIFICATIONS');
    }

    return permissions;
  }
}

_Config _parseArgs(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    return _Config(
      environment: 'debug',
      baseUrl: 'https://dummyjson.com',
      namespace: 'com.example.form_fields_example',
      compileSdk: 36,
      ndkVersion: '27.0.12077973',
      minSdk: 21,
      targetSdk: 36,
      versionCode: 1,
      versionName: '1.0.0',
      mapsKey: 'DEBUG_GOOGLE_MAPS_API_KEY',
      enableCamera: true,
      enableGallery: true,
      enableNotification: true,
      showHelp: true,
      skipBuild: false,
      buildPlatforms: ['android'],
    );
  }

  final map = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final index = arg.indexOf('=');
    if (index == -1) {
      map[arg.substring(2)] = 'true';
    } else {
      map[arg.substring(2, index)] = arg.substring(index + 1);
    }
  }

  final environment = (map['env'] ?? 'debug').toLowerCase();
  if (!['debug', 'beta', 'production'].contains(environment)) {
    throw Exception('Invalid env. Use debug|beta|production');
  }

  final defaultBaseUrl = switch (environment) {
    'production' => 'https://api.dummyjson.com',
    'beta' => 'https://beta-api.dummyjson.com',
    _ => 'https://dummyjson.com',
  };

  final defaultMapsKey = '${environment.toUpperCase()}_GOOGLE_MAPS_API_KEY';

  return _Config(
    environment: environment,
    baseUrl: map['base-url'] ?? defaultBaseUrl,
    namespace: map['namespace'] ?? 'com.example.form_fields_example',
    compileSdk: int.tryParse(map['compile-sdk'] ?? '') ?? 36,
    ndkVersion: map['ndk-version'] ?? '27.0.12077973',
    minSdk: int.tryParse(map['min-sdk'] ?? '') ?? 21,
    targetSdk: int.tryParse(map['target-sdk'] ?? '') ?? 36,
    versionCode: int.tryParse(map['version-code'] ?? '') ?? 1,
    versionName: map['version-name'] ?? '1.0.0',
    mapsKey: map['maps-key'] ?? defaultMapsKey,
    enableCamera: _parseBool(map['camera'], true),
    enableGallery: _parseBool(map['gallery'], true),
    enableNotification: _parseBool(map['notification'], true),
    showHelp: false,
    skipBuild: _parseBool(map['skip-build'], false),
    buildPlatforms: _parsePlatforms(map['platform']),
  );
}

bool _parseBool(String? value, bool fallback) {
  if (value == null) return fallback;
  final normalized = value.toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

List<String> _parsePlatforms(String? value) {
  if (value == null || value.isEmpty) return ['android'];

  if (value.toLowerCase() == 'all') {
    return ['android', 'ios', 'macos', 'windows', 'linux', 'web'];
  }

  final platforms =
      value.toLowerCase().split(',').map((p) => p.trim()).toList();
  final valid = ['android', 'ios', 'macos', 'windows', 'linux', 'web'];

  for (final platform in platforms) {
    if (!valid.contains(platform)) {
      throw Exception(
          'Invalid platform: $platform. Use: ${valid.join(', ')} or "all"');
    }
  }

  return platforms;
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/configure_build.dart --env=debug|beta|production [options]

Options:
  --namespace=com.example.app
  --base-url=https://api.example.com
  --compile-sdk=34
  --ndk-version=27.0.12077973
  --min-sdk=21
  --target-sdk=34
  --version-code=1
  --version-name=1.0.0
  --maps-key=YOUR_GOOGLE_MAPS_API_KEY
  --camera=true|false
  --gallery=true|false
  --notification=true|false
  --platform=android|ios|macos|windows|linux|web|all (comma-separated or 'all')
  --skip-build       Skip build after configuration

Examples:
  dart run tool/configure_build.dart --env=debug
  dart run tool/configure_build.dart --env=production --namespace=com.my.app --maps-key=AIza...
  dart run tool/configure_build.dart --env=debug --platform=android,ios
  dart run tool/configure_build.dart --env=production --platform=all
''');
}

void _updateMainDart(String root, _Config config, List<String> changes) {
  final path = '$root/lib/main.dart';
  final file = File(path);
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();
  content = content.replaceAllMapped(
    RegExp(
        r'EnvironmentConfig\.current\s*=\s*AppEnvironment\.(debug|beta|production);'),
    (m) => 'EnvironmentConfig.current = ${config.environmentEnum};',
  );

  file.writeAsStringSync(content);
  changes.add(
      'Updated active environment in lib/main.dart -> ${config.environment}');
}

void _updateEnvironmentConfig(
    String root, _Config config, List<String> changes) {
  final path = '$root/lib/config/environment.dart';
  final file = File(path);
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();

  content = content.replaceAllMapped(
    RegExp(
      r"(class _DebugConfig extends EnvironmentSettings \{[\s\S]*?String get baseUrl => )'[^']*';",
    ),
    (m) =>
        "${m.group(1)}'${config.environment == 'debug' ? config.baseUrl : 'https://dummyjson.com'}';",
  );

  content = content.replaceAllMapped(
    RegExp(
      r"(class _BetaConfig extends EnvironmentSettings \{[\s\S]*?String get baseUrl => )'[^']*';",
    ),
    (m) =>
        "${m.group(1)}'${config.environment == 'beta' ? config.baseUrl : 'https://beta-api.dummyjson.com'}';",
  );

  content = content.replaceAllMapped(
    RegExp(
      r"(class _ProductionConfig extends EnvironmentSettings \{[\s\S]*?String get baseUrl => )'[^']*';",
    ),
    (m) =>
        "${m.group(1)}'${config.environment == 'production' ? config.baseUrl : 'https://api.dummyjson.com'}';",
  );

  file.writeAsStringSync(content);
  changes.add('Updated base URL mapping in lib/config/environment.dart');
}

void _updateBuildConfig(String root, _Config config, List<String> changes) {
  final path = '$root/lib/config/build_settings.dart';
  final file = File(path);

  // Generate build_settings.dart content
  final content = _generateBuildSettings(config);

  file.writeAsStringSync(content);
  changes.add(
      'Generated lib/config/build_settings.dart with ${config.environment} configuration');
}

String _generateBuildSettings(_Config config) {
  return '''// ============================================================================
// BUILD SETTINGS - AUTO-GENERATED FILE
// ============================================================================
// 
// ⚠️ DO NOT EDIT THIS FILE MANUALLY!
// 
// This file is automatically generated by:
//   dart run tool/configure_build.dart
//
// Last generated: ${DateTime.now().toIso8601String()}
// Environment: ${config.environment}
//
// To change these settings, run the configuration tool:
//   dart run tool/configure_build.dart --env=debug|beta|production [options]
//
// For more information, see: HOW_TO_USE.md
// ============================================================================

/// Build settings for DEBUG environment
class DebugBuildSettings {
  static const String androidNamespace = '${config.namespace}.debug';
  static const int androidCompileSdk = ${config.compileSdk};
  static const String ndkVersion = '${config.ndkVersion}';
  static const int androidMinSdk = ${config.minSdk};
  static const int androidTargetSdk = ${config.targetSdk};
  static const int versionCode = ${config.versionCode};
  static const String versionName = '${config.versionName}';
  static const String androidMapsApiKey = '${config.environment == 'debug' ? config.mapsKey : 'DEBUG_GOOGLE_MAPS_API_KEY'}';
  static const String iosMapsApiKey = '${config.environment == 'debug' ? config.mapsKey : 'DEBUG_GOOGLE_MAPS_API_KEY'}';
  static const String iosMinimumDeploymentTarget = '12.0';
  static const String macosMinimumDeploymentTarget = '10.15';
  static const int windowsMinimumVersion = 10;
  static const String webDomain = 'localhost:8080';
  
  static const List<String> androidPermissions = [
${_formatPermissionsList(config.androidPermissions)}
  ];
}

/// Build settings for BETA environment
class BetaBuildSettings {
  static const String androidNamespace = '${config.namespace}.beta';
  static const int androidCompileSdk = ${config.compileSdk};
  static const String ndkVersion = '${config.ndkVersion}';
  static const int androidMinSdk = ${config.minSdk};
  static const int androidTargetSdk = ${config.targetSdk};
  static const int versionCode = ${config.versionCode};
  static const String versionName = '${config.versionName}';
  static const String androidMapsApiKey = '${config.environment == 'beta' ? config.mapsKey : 'BETA_GOOGLE_MAPS_API_KEY'}';
  static const String iosMapsApiKey = '${config.environment == 'beta' ? config.mapsKey : 'BETA_GOOGLE_MAPS_API_KEY'}';
  static const String iosMinimumDeploymentTarget = '12.0';
  static const String macosMinimumDeploymentTarget = '10.15';
  static const int windowsMinimumVersion = 10;
  static const String webDomain = 'beta.example.com';
  
  static const List<String> androidPermissions = [
${_formatPermissionsList(config.androidPermissions)}
  ];
}

/// Build settings for PRODUCTION environment
class ProductionBuildSettings {
  static const String androidNamespace = '${config.namespace}';
  static const int androidCompileSdk = ${config.compileSdk};
  static const String ndkVersion = '${config.ndkVersion}';
  static const int androidMinSdk = ${config.minSdk};
  static const int androidTargetSdk = ${config.targetSdk};
  static const int versionCode = ${config.versionCode};
  static const String versionName = '${config.versionName}';
  static const String androidMapsApiKey = '${config.environment == 'production' ? config.mapsKey : 'PROD_GOOGLE_MAPS_API_KEY'}';
  static const String iosMapsApiKey = '${config.environment == 'production' ? config.mapsKey : 'PROD_GOOGLE_MAPS_API_KEY'}';
  static const String iosMinimumDeploymentTarget = '12.0';
  static const String macosMinimumDeploymentTarget = '10.15';
  static const int windowsMinimumVersion = 10;
  static const String webDomain = 'example.com';
  
  static const List<String> androidPermissions = [
${_formatPermissionsList(config.androidPermissions)}
  ];
}
''';
}

String _formatPermissionsList(List<String> permissions) {
  return permissions.map((p) => "    '$p',").join('\n');
}

void _updateAndroidGradle(String root, _Config config, List<String> changes) {
  final path = '$root/android/app/build.gradle.kts';
  final file = File(path);
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();

  content = _replaceOne(
    content,
    RegExp(r'namespace\s*=\s*"[^"]*"'),
    'namespace = "${config.androidNamespace}"',
  );
  content = _replaceOne(
    content,
    RegExp(r'compileSdk\s*=\s*[^\n]+'),
    'compileSdk = ${config.compileSdk}',
  );
  content = _replaceOne(
    content,
    RegExp(r'ndkVersion\s*=\s*[^\n]+'),
    'ndkVersion = "${config.ndkVersion}"',
  );

  content = _replaceOne(
    content,
    RegExp(r'applicationId\s*=\s*"[^"]*"'),
    'applicationId = "${config.androidNamespace}"',
  );
  content = _replaceOne(
    content,
    RegExp(r'minSdk\s*=\s*[^\n]+'),
    'minSdk = ${config.minSdk}',
  );
  content = _replaceOne(
    content,
    RegExp(r'targetSdk\s*=\s*[^\n]+'),
    'targetSdk = ${config.targetSdk}',
  );
  content = _replaceOne(
    content,
    RegExp(r'versionCode\s*=\s*[^\n]+'),
    'versionCode = ${config.versionCode}',
  );
  content = _replaceOne(
    content,
    RegExp(r'versionName\s*=\s*[^\n]+'),
    'versionName = "${config.versionName}"',
  );

  // Remove all existing manifestPlaceholders for MAPS_API_KEY
  content = content.replaceAll(
    RegExp(r'\s*manifestPlaceholders\["MAPS_API_KEY"\]\s*=\s*"[^"]*"\s*\n?'),
    '',
  );

  // Add a single manifestPlaceholders line after versionName
  content = content.replaceFirstMapped(
    RegExp(r'(versionName\s*=\s*"[^"]*")'),
    (match) =>
        '${match.group(1)}\n        manifestPlaceholders["MAPS_API_KEY"] = "${config.mapsKey}"',
  );

  file.writeAsStringSync(content);
  changes
      .add('Updated Android build.gradle.kts (namespace/sdk/version/maps key)');
}

void _updateAndroidManifest(String root, _Config config, List<String> changes) {
  final path = '$root/android/app/src/main/AndroidManifest.xml';
  final file = File(path);
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();

  // Remove all existing permissions and replace with new ones
  content = content.replaceFirst(
    RegExp(r'<manifest[^>]*>[\s\S]*?(?=<application)'),
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '${_androidPermissionLines(config)}\n    ',
  );

  if (!content.contains('com.google.android.geo.API_KEY')) {
    content = content.replaceFirstMapped(
      RegExp(r'(<application[\s\S]*?>)'),
      (match) =>
          '${match.group(1)}\n        <meta-data\n            android:name="com.google.android.geo.API_KEY"\n            android:value="\${MAPS_API_KEY}" />',
    );
  }

  file.writeAsStringSync(content);
  changes.add('Updated AndroidManifest permissions');
}

String _androidPermissionLines(_Config config) {
  final buffer = StringBuffer();
  for (final permission in config.androidPermissions) {
    if (permission == 'android.permission.READ_EXTERNAL_STORAGE') {
      buffer.writeln(
        '    <uses-permission android:name="$permission" android:maxSdkVersion="32" />',
      );
    } else {
      buffer.writeln('    <uses-permission android:name="$permission" />');
    }
  }
  return buffer.toString().trimRight();
}

void _updateMainActivity(String root, _Config config, List<String> changes) {
  final path =
      '$root/android/app/src/main/kotlin/com/example/form_fields_example/MainActivity.kt';
  final file = File(path);
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();

  // Update package name to match namespace
  content = _replaceOne(
    content,
    RegExp(r'package com\.example\.form_fields_example\S*'),
    'package ${config.androidNamespace}',
  );

  file.writeAsStringSync(content);
  changes.add('Updated MainActivity.kt package name');
}

void _updateOptionalIos(String root, _Config config, List<String> changes) {
  final path = '$root/ios/Runner/Info.plist';
  final file = File(path);
  if (!file.existsSync()) {
    changes.add('Skipped iOS (ios/Runner/Info.plist not found)');
    return;
  }

  var content = file.readAsStringSync();

  // Add permission descriptions based on enabled features
  if (config.enableCamera) {
    content = _setPlistValue(
      content,
      'NSCameraUsageDescription',
      'Camera is required to capture images.',
    );
  }

  if (config.enableGallery) {
    content = _setPlistValue(
      content,
      'NSPhotoLibraryUsageDescription',
      'Gallery access is required to select images.',
    );
    content = _setPlistValue(
      content,
      'NSPhotoLibraryAddUsageDescription',
      'Photo library access is required to save images.',
    );
  }

  if (config.enableNotification) {
    content = _setPlistValue(
      content,
      'NSUserNotificationUsageDescription',
      'Notifications are used to keep you updated.',
    );
  }

  // Always add location permissions (base requirement)
  content = _setPlistValue(
    content,
    'NSLocationWhenInUseUsageDescription',
    'Location access is required for location-based features.',
  );
  content = _setPlistValue(
    content,
    'NSLocationAlwaysUsageDescription',
    'Location access is required for location-based features.',
  );
  content = _setPlistValue(
    content,
    'NSLocationAlwaysAndWhenInUseUsageDescription',
    'Location access is required for location-based features.',
  );

  content = _setPlistValue(content, 'CFBundleVersion', '${config.versionCode}');
  content =
      _setPlistValue(content, 'CFBundleShortVersionString', config.versionName);

  file.writeAsStringSync(content);
  changes.add('Updated iOS Info.plist permissions/version');
}

void _updateIosPodfile(String root, _Config config, List<String> changes) {
  final path = '$root/ios/Podfile';
  final file = File(path);
  if (!file.existsSync()) {
    changes.add('Skipped iOS Podfile (ios/Podfile not found)');
    return;
  }

  var content = file.readAsStringSync();

  // Build the permission configuration based on enabled features
  final permissions = <String>[];

  if (config.enableCamera) {
    permissions.add(
        "        ## dart: PermissionGroup.camera\n        'PERMISSION_CAMERA=1',");
  }

  if (config.enableGallery) {
    permissions.add(
        "        ## dart: PermissionGroup.photos\n        'PERMISSION_PHOTOS=1',");
  }

  if (config.enableNotification) {
    permissions.add(
        "        ## dart: PermissionGroup.notification\n        'PERMISSION_NOTIFICATIONS=1',");
  }

  // Always add location permissions (as they're in the base android permissions)
  permissions.add(
      "        ## dart: PermissionGroup.location\n        'PERMISSION_LOCATION=1',");

  final permissionBlock = permissions.join('\n');

  // Remove existing permission_handler configuration if present
  content = content.replaceAll(
    RegExp(
      r'\s*# Start of the permission_handler configuration[\s\S]*?# End of the permission_handler configuration\s*',
      multiLine: true,
    ),
    '',
  );

  // Check if post_install exists
  if (content.contains('post_install do |installer|')) {
    // Add permission_handler configuration inside existing post_install block
    content = content.replaceFirstMapped(
      RegExp(
        r"(post_install do \|installer\|[\s\S]*?installer\.pods_project\.targets\.each do \|target\|)\s*([\s\S]*?)(end\s+end)",
        multiLine: true,
      ),
      (match) {
        final prefix = match.group(1) ?? '';
        var existing = match.group(2) ?? '';
        final suffix = match.group(3) ?? '';

        // Ensure existing content has proper indentation and spacing
        existing = existing.trim();
        if (existing.isNotEmpty) {
          existing = '\n    $existing\n  ';
        } else {
          existing = '\n  ';
        }

        return '''$prefix

    # Start of the permission_handler configuration
    target.build_configurations.each do |config|
      # Preprocessor definitions can be found at:
      # https://github.com/Baseflow/flutter-permission-handler/blob/master/permission_handler_apple/ios/Classes/PermissionHandlerEnums.h
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',

$permissionBlock
      ]
    end
    # End of the permission_handler configuration
$existing$suffix''';
      },
    );
  } else {
    // Add complete post_install block at the end of file
    content = content.trimRight();
    content += '''

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Start of the permission_handler configuration
    target.build_configurations.each do |config|
      # Preprocessor definitions can be found at:
      # https://github.com/Baseflow/flutter-permission-handler/blob/master/permission_handler_apple/ios/Classes/PermissionHandlerEnums.h
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',

$permissionBlock
      ]
    end
    # End of the permission_handler configuration
  end
end
''';
  }

  file.writeAsStringSync(content);
  changes.add('Updated iOS Podfile with permission_handler configuration');
}

void _updateOptionalMacos(String root, _Config config, List<String> changes) {
  final path = '$root/macos/Runner/Info.plist';
  final file = File(path);
  if (!file.existsSync()) {
    changes.add('Skipped macOS (macos/Runner/Info.plist not found)');
    return;
  }

  var content = file.readAsStringSync();

  // Add permission descriptions based on enabled features
  if (config.enableCamera) {
    content = _setPlistValue(
      content,
      'NSCameraUsageDescription',
      'Camera is required to capture images.',
    );
  }

  if (config.enableGallery) {
    content = _setPlistValue(
      content,
      'NSPhotoLibraryUsageDescription',
      'Gallery access is required to select images.',
    );
    content = _setPlistValue(
      content,
      'NSPhotoLibraryAddUsageDescription',
      'Photo library access is required to save images.',
    );
  }

  if (config.enableNotification) {
    content = _setPlistValue(
      content,
      'NSUserNotificationUsageDescription',
      'Notifications are used to keep you updated.',
    );
  }

  // Always add location permissions (base requirement)
  content = _setPlistValue(
    content,
    'NSLocationWhenInUseUsageDescription',
    'Location access is required for location-based features.',
  );
  content = _setPlistValue(
    content,
    'NSLocationAlwaysUsageDescription',
    'Location access is required for location-based features.',
  );
  content = _setPlistValue(
    content,
    'NSLocationAlwaysAndWhenInUseUsageDescription',
    'Location access is required for location-based features.',
  );

  file.writeAsStringSync(content);
  changes.add('Updated macOS Info.plist permissions');
}

void _updateMacosPodfile(String root, _Config config, List<String> changes) {
  final path = '$root/macos/Podfile';
  final file = File(path);
  if (!file.existsSync()) {
    changes.add('Skipped macOS Podfile (macos/Podfile not found)');
    return;
  }

  var content = file.readAsStringSync();

  // Build the permission configuration based on enabled features
  final permissions = <String>[];

  if (config.enableCamera) {
    permissions.add(
        "        ## dart: PermissionGroup.camera\n        'PERMISSION_CAMERA=1',");
  }

  if (config.enableGallery) {
    permissions.add(
        "        ## dart: PermissionGroup.photos\n        'PERMISSION_PHOTOS=1',");
  }

  if (config.enableNotification) {
    permissions.add(
        "        ## dart: PermissionGroup.notification\n        'PERMISSION_NOTIFICATIONS=1',");
  }

  // Always add location permissions
  permissions.add(
      "        ## dart: PermissionGroup.location\n        'PERMISSION_LOCATION=1',");

  final permissionBlock = permissions.join('\n');

  // Remove existing permission_handler configuration if present
  content = content.replaceAll(
    RegExp(
      r'\s*# Start of the permission_handler configuration[\s\S]*?# End of the permission_handler configuration\s*',
      multiLine: true,
    ),
    '',
  );

  // Check if post_install exists
  if (content.contains('post_install do |installer|')) {
    // Add permission_handler configuration inside existing post_install block
    content = content.replaceFirstMapped(
      RegExp(
        r"(post_install do \|installer\|[\s\S]*?installer\.pods_project\.targets\.each do \|target\|)([\s\S]*?)(end\s+end)",
        multiLine: true,
      ),
      (match) {
        final prefix = match.group(1) ?? '';
        var existing = match.group(2) ?? '';
        final suffix = match.group(3) ?? '';

        // Ensure existing content has proper indentation and spacing
        existing = existing.trim();
        if (existing.isNotEmpty) {
          existing = '\n    $existing\n  ';
        } else {
          existing = '\n  ';
        }

        return '''$prefix

    # Start of the permission_handler configuration
    target.build_configurations.each do |config|
      # Preprocessor definitions can be found at:
      # https://github.com/Baseflow/flutter-permission-handler/blob/master/permission_handler_apple/ios/Classes/PermissionHandlerEnums.h
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',

$permissionBlock
      ]
    end
    # End of the permission_handler configuration
$existing$suffix''';
      },
    );
  } else {
    // Add complete post_install block at the end of file
    content = content.trimRight();
    content += '''

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)

    # Start of the permission_handler configuration
    target.build_configurations.each do |config|
      # Preprocessor definitions can be found at:
      # https://github.com/Baseflow/flutter-permission-handler/blob/master/permission_handler_apple/ios/Classes/PermissionHandlerEnums.h
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',

$permissionBlock
      ]
    end
    # End of the permission_handler configuration
  end
end
''';
  }

  file.writeAsStringSync(content);
  changes.add('Updated macOS Podfile with permission_handler configuration');
}

void _updateOptionalWeb(String root, _Config config, List<String> changes) {
  final path = '$root/web/index.html';
  final file = File(path);
  if (!file.existsSync()) {
    changes.add('Skipped Web (web/index.html not found)');
    return;
  }

  var content = file.readAsStringSync();
  final scriptTag =
      '<script src="https://maps.googleapis.com/maps/api/js?key=${config.mapsKey}&libraries=places"></script>';
  if (!content.contains('maps.googleapis.com/maps/api/js')) {
    content = content.replaceFirst('</head>', '  $scriptTag\n</head>');
  } else {
    content = content.replaceAllMapped(
      RegExp(
          r'<script src="https://maps.googleapis.com/maps/api/js\?key=[^"]*"></script>'),
      (m) => scriptTag,
    );
  }

  file.writeAsStringSync(content);
  changes.add('Updated Web map key script');
}

void _updateOptionalWindows(String root, _Config config, List<String> changes) {
  final path = '$root/windows/runner/Runner.rc';
  final file = File(path);
  if (!file.existsSync()) {
    changes.add('Skipped Windows (windows/runner/Runner.rc not found)');
    return;
  }

  var content = file.readAsStringSync();
  content = content.replaceAllMapped(
    RegExp(r'VALUE "FileVersion", "[^"]*"'),
    (m) => 'VALUE "FileVersion", "${config.versionName}"',
  );
  content = content.replaceAllMapped(
    RegExp(r'VALUE "ProductVersion", "[^"]*"'),
    (m) => 'VALUE "ProductVersion", "${config.versionName}"',
  );

  file.writeAsStringSync(content);
  changes.add('Updated Windows version metadata');
}

void _updateOptionalLinux(String root, _Config config, List<String> changes) {
  final path = '$root/linux/CMakeLists.txt';
  final file = File(path);
  if (!file.existsSync()) {
    changes.add('Skipped Linux (linux/CMakeLists.txt not found)');
    return;
  }

  var content = file.readAsStringSync();
  if (content.contains('set(PROJECT_VERSION "')) {
    content = content.replaceAllMapped(
      RegExp(r'set\(PROJECT_VERSION\s+"[^"]*"\)'),
      (m) => 'set(PROJECT_VERSION "${config.versionName}")',
    );
  } else {
    content = 'set(PROJECT_VERSION "${config.versionName}")\n$content';
  }

  file.writeAsStringSync(content);
  changes.add('Updated Linux project version');
}

String _setPlistValue(String content, String key, String value) {
  final keyPattern = RegExp(
    '<key>$key</key>\\s*<string>[^<]*</string>',
    multiLine: true,
  );

  if (keyPattern.hasMatch(content)) {
    return content.replaceFirst(
      keyPattern,
      '<key>$key</key>\n\t<string>$value</string>',
    );
  }

  return content.replaceFirst(
    '</dict>',
    '\t<key>$key</key>\n\t<string>$value</string>\n</dict>',
  );
}

String _replaceOne(String input, RegExp pattern, String replacement) {
  if (!pattern.hasMatch(input)) return input;
  return input.replaceFirst(pattern, replacement);
}

// ============================================================================
// MULTI-PLATFORM BUILD WITH AUTO-FIX
// ============================================================================

void _buildForPlatforms(String root, List<String> platforms) {
  stdout.writeln('\n🔨 Building for platforms: ${platforms.join(', ')}');

  final results = <String, bool>{};

  for (final platform in platforms) {
    stdout.writeln('\n${'=' * 60}');
    stdout.writeln('Platform: ${platform.toUpperCase()}');
    stdout.writeln('=' * 60);

    final success = _buildPlatform(root, platform);
    results[platform] = success;
  }

  // Summary
  stdout.writeln('\n${'=' * 60}');
  stdout.writeln('BUILD SUMMARY');
  stdout.writeln('=' * 60);

  for (final entry in results.entries) {
    final icon = entry.value ? '✅' : '❌';
    stdout.writeln(
        '$icon ${entry.key.toUpperCase()}: ${entry.value ? 'SUCCESS' : 'FAILED'}');
  }

  final failed = results.values.where((v) => !v).length;
  if (failed > 0) {
    stderr.writeln('\n⚠️ $failed platform(s) failed to build');
    exit(1);
  } else {
    stdout.writeln('\n🎉 All platforms built successfully!');
  }
}

bool _buildPlatform(String root, String platform) {
  switch (platform) {
    case 'android':
      return _buildAndroidWithAutoFix(root);
    case 'ios':
      return _buildIosWithAutoFix(root);
    case 'macos':
      return _buildMacosWithAutoFix(root);
    case 'windows':
      return _buildWindowsWithAutoFix(root);
    case 'linux':
      return _buildLinuxWithAutoFix(root);
    case 'web':
      return _buildWebWithAutoFix(root);
    default:
      stderr.writeln('❌ Unknown platform: $platform');
      return false;
  }
}

// ============================================================================
// ANDROID BUILD WITH AUTO-FIX
// ============================================================================

bool _buildAndroidWithAutoFix(String root, {int maxRetries = 3}) {
  // Check if Android exists
  if (!Directory('$root/android').existsSync()) {
    stdout.writeln('⏭️ Android not configured, skipping...');
    return true;
  }

  int attempt = 0;

  while (attempt < maxRetries) {
    attempt++;
    stdout.writeln('\n📦 Build attempt $attempt of $maxRetries...');

    final result = _runFlutterBuild(root, 'android');

    if (result.exitCode == 0) {
      stdout.writeln('\n✅ Android APK built successfully!');

      // Extract APK path from output
      final apkPathMatch = RegExp(r'Built (.*\.apk)').firstMatch(result.output);
      if (apkPathMatch != null) {
        final apkPath = apkPathMatch.group(1);
        stdout.writeln('📱 APK Location: $apkPath');
      }

      return true;
    }

    // Build failed, analyze error
    stderr.writeln('⚠️ Build failed with exit code ${result.exitCode}');

    if (attempt >= maxRetries) {
      stderr.writeln('❌ Max retries reached. Android build failed.');
      stderr.writeln('\nError output:\n${result.error}');
      return false;
    }

    // Try to fix gradle errors
    if (_isGradleError(result.error)) {
      stdout.writeln('🔧 Detected Gradle error. Attempting to fix...');
      _fixGradleIssues(root, result.error);
    } else if (_isDependencyError(result.error)) {
      stdout
          .writeln('🔧 Detected dependency error. Running flutter pub get...');
      _runCommand(root, 'flutter', ['pub', 'get']);
    } else if (_isFlutterCacheError(result.error)) {
      stdout.writeln('🔧 Detected cache error. Cleaning Flutter cache...');
      _runCommand(root, 'flutter', ['clean']);
      _runCommand(root, 'flutter', ['pub', 'get']);
    } else {
      stderr.writeln('❌ Unknown error type. Retrying anyway...');
    }

    stdout.writeln('⏳ Waiting 2 seconds before retry...');
    sleep(Duration(seconds: 2));
  }

  return false; // Failed after all retries
}

// ============================================================================
// iOS BUILD WITH AUTO-FIX
// ============================================================================

bool _buildIosWithAutoFix(String root, {int maxRetries = 3}) {
  if (!Directory('$root/ios').existsSync()) {
    stdout.writeln('⏭️ iOS not configured, skipping...');
    return true;
  }

  return _buildPlatformGeneric(root, 'ios', maxRetries);
}

// ============================================================================
// macOS BUILD WITH AUTO-FIX
// ============================================================================

bool _buildMacosWithAutoFix(String root, {int maxRetries = 3}) {
  if (!Directory('$root/macos').existsSync()) {
    stdout.writeln('⏭️ macOS not configured, skipping...');
    return true;
  }

  return _buildPlatformGeneric(root, 'macos', maxRetries);
}

// ============================================================================
// WINDOWS BUILD WITH AUTO-FIX
// ============================================================================

bool _buildWindowsWithAutoFix(String root, {int maxRetries = 3}) {
  if (!Directory('$root/windows').existsSync()) {
    stdout.writeln('⏭️ Windows not configured, skipping...');
    return true;
  }

  return _buildPlatformGeneric(root, 'windows', maxRetries);
}

// ============================================================================
// LINUX BUILD WITH AUTO-FIX
// ============================================================================

bool _buildLinuxWithAutoFix(String root, {int maxRetries = 3}) {
  if (!Directory('$root/linux').existsSync()) {
    stdout.writeln('⏭️ Linux not configured, skipping...');
    return true;
  }

  return _buildPlatformGeneric(root, 'linux', maxRetries);
}

// ============================================================================
// WEB BUILD WITH AUTO-FIX
// ============================================================================

bool _buildWebWithAutoFix(String root, {int maxRetries = 3}) {
  if (!Directory('$root/web').existsSync()) {
    stdout.writeln('⏭️ Web not configured, skipping...');
    return true;
  }

  return _buildPlatformGeneric(root, 'web', maxRetries);
}

// ============================================================================
// GENERIC PLATFORM BUILD WITH AUTO-FIX
// ============================================================================

bool _buildPlatformGeneric(String root, String platform, int maxRetries) {
  int attempt = 0;

  while (attempt < maxRetries) {
    attempt++;
    stdout.writeln('\n📦 Build attempt $attempt of $maxRetries...');

    final result = _runFlutterBuild(root, platform);

    if (result.exitCode == 0) {
      stdout.writeln('\n✅ ${platform.toUpperCase()} built successfully!');

      // Extract output path
      final outputMatch = RegExp(r'Built (.*)').firstMatch(result.output);
      if (outputMatch != null) {
        final outputPath = outputMatch.group(1);
        stdout.writeln('📱 Output: $outputPath');
      }

      return true;
    }

    // Build failed
    stderr.writeln('⚠️ Build failed with exit code ${result.exitCode}');

    if (attempt >= maxRetries) {
      stderr.writeln(
          '❌ Max retries reached. ${platform.toUpperCase()} build failed.');
      stderr.writeln('\nError output:\n${result.error}');
      return false;
    }

    // Try to fix errors
    if (_isDependencyError(result.error)) {
      stdout
          .writeln('🔧 Detected dependency error. Running flutter pub get...');
      _runCommand(root, 'flutter', ['pub', 'get']);
    } else if (_isFlutterCacheError(result.error)) {
      stdout.writeln('🔧 Detected cache error. Cleaning Flutter cache...');
      _runCommand(root, 'flutter', ['clean']);
      _runCommand(root, 'flutter', ['pub', 'get']);
    } else if (_isPodError(result.error) &&
        (platform == 'ios' || platform == 'macos')) {
      stdout.writeln('🔧 Detected CocoaPods error. Running pod install...');
      _fixPodIssues(root, platform);
    } else if (_isCmakeError(result.error) && platform == 'linux') {
      stdout.writeln('🔧 Detected CMake error. Attempting to fix...');
      _fixCmakeIssues(root);
    } else {
      stderr.writeln('❌ Unknown error type. Retrying anyway...');
    }

    stdout.writeln('⏳ Waiting 2 seconds before retry...');
    sleep(Duration(seconds: 2));
  }

  return false;
}

// ============================================================================
// BUILD ARGUMENTS FOR EACH PLATFORM
// ============================================================================

List<String> _getBuildArgs(String platform) {
  switch (platform) {
    case 'android':
      return ['apk', '--debug', '--no-tree-shake-icons'];
    case 'ios':
      return ['ios', '--debug', '--no-codesign'];
    case 'macos':
      return ['macos', '--debug'];
    case 'windows':
      return ['windows', '--debug'];
    case 'linux':
      return ['linux', '--debug'];
    case 'web':
      return ['web', '--debug'];
    default:
      return [platform, '--debug'];
  }
}

class _BuildResult {
  final int exitCode;
  final String output;
  final String error;

  _BuildResult(this.exitCode, this.output, this.error);
}

_BuildResult _runFlutterBuild(String root, String platform) {
  final buildArgs = _getBuildArgs(platform);
  final command = 'flutter build ${buildArgs.join(' ')}';
  stdout.writeln('▶️  Running: $command\n');

  final process = Process.runSync(
    'flutter',
    ['build', ...buildArgs],
    workingDirectory: root,
  );

  // Print build output in real-time style
  final output = process.stdout.toString();
  if (output.isNotEmpty) {
    stdout.write(output);
  }

  return _BuildResult(
    process.exitCode,
    output,
    process.stderr.toString(),
  );
}

bool _isGradleError(String error) {
  return error.contains('Gradle') ||
      error.contains('gradle') ||
      error.contains('Could not resolve') ||
      error.contains('Could not download') ||
      error.contains('AGP') ||
      error.contains('Android Gradle Plugin') ||
      error.contains('Minimum supported Gradle version') ||
      error.contains('daemon') ||
      error.contains('build.gradle');
}

bool _isDependencyError(String error) {
  return error.contains('pub get') ||
      error.contains('pubspec.yaml') ||
      error.contains('dependencies') ||
      error.contains('package');
}

bool _isFlutterCacheError(String error) {
  return error.contains('cache') ||
      error.contains('Artifact') ||
      error.contains('download');
}

bool _isPodError(String error) {
  return error.contains('CocoaPods') ||
      error.contains('pod install') ||
      error.contains('Podfile') ||
      error.contains('.podspec') ||
      error.contains('pod repo update');
}

bool _isCmakeError(String error) {
  return error.contains('CMake') ||
      error.contains('cmake') ||
      error.contains('CMakeLists.txt') ||
      error.contains('ninja');
}

void _fixGradleIssues(String root, String error) {
  // Fix 1: Update Gradle wrapper
  if (error.contains('Gradle version') || error.contains('AGP')) {
    stdout.writeln('  → Updating Gradle wrapper to latest version...');
    _updateGradleWrapper(root);
  }

  // Fix 2: Clean Gradle cache
  stdout.writeln('  → Cleaning Gradle cache...');
  _cleanGradle(root);

  // Fix 3: Update Gradle properties
  stdout.writeln('  → Updating Gradle properties...');
  _updateGradleProperties(root);

  // Fix 4: Run Flutter clean
  stdout.writeln('  → Running Flutter clean...');
  _runCommand(root, 'flutter', ['clean']);

  // Fix 5: Run pub get
  stdout.writeln('  → Running Flutter pub get...');
  _runCommand(root, 'flutter', ['pub', 'get']);
}

void _updateGradleWrapper(String root) {
  final androidDir = '$root/android';

  // Try to update gradle wrapper
  final gradlewPath = '$androidDir/gradlew';
  if (File(gradlewPath).existsSync()) {
    _runCommand(androidDir, './gradlew', ['wrapper', '--gradle-version=8.3']);
  } else {
    stdout.writeln('  ⚠️ gradlew not found, skipping wrapper update');
  }
}

void _cleanGradle(String root) {
  final androidDir = '$root/android';

  // Delete .gradle directory
  final gradleCache = Directory('$androidDir/.gradle');
  if (gradleCache.existsSync()) {
    try {
      gradleCache.deleteSync(recursive: true);
      stdout.writeln('  ✓ Deleted .gradle cache');
    } catch (e) {
      stdout.writeln('  ⚠️ Could not delete .gradle cache: $e');
    }
  }

  // Delete build directories
  final buildDir = Directory('$androidDir/build');
  if (buildDir.existsSync()) {
    try {
      buildDir.deleteSync(recursive: true);
      stdout.writeln('  ✓ Deleted build directory');
    } catch (e) {
      stdout.writeln('  ⚠️ Could not delete build directory: $e');
    }
  }

  final appBuildDir = Directory('$androidDir/app/build');
  if (appBuildDir.existsSync()) {
    try {
      appBuildDir.deleteSync(recursive: true);
      stdout.writeln('  ✓ Deleted app/build directory');
    } catch (e) {
      stdout.writeln('  ⚠️ Could not delete app/build directory: $e');
    }
  }
}

void _updateGradleProperties(String root) {
  final propertiesPath = '$root/android/gradle.properties';
  final file = File(propertiesPath);

  if (!file.existsSync()) return;

  var content = file.readAsStringSync();

  // Add or update JVM args for better performance
  if (!content.contains('org.gradle.jvmargs')) {
    content += '\norg.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m\n';
  }

  // Enable daemon
  if (!content.contains('org.gradle.daemon')) {
    content += 'org.gradle.daemon=true\n';
  }

  // Enable parallel execution
  if (!content.contains('org.gradle.parallel')) {
    content += 'org.gradle.parallel=true\n';
  }

  // Enable configuration cache
  if (!content.contains('org.gradle.configuration-cache')) {
    content += 'org.gradle.configuration-cache=true\n';
  }

  file.writeAsStringSync(content);
  stdout.writeln('  ✓ Updated gradle.properties');
}

void _runCommand(String workingDir, String command, List<String> args) {
  stdout.writeln('  → Running: $command ${args.join(' ')}');

  final process = Process.runSync(
    command,
    args,
    workingDirectory: workingDir,
  );

  if (process.exitCode != 0) {
    stdout.writeln('  ⚠️ Command failed with exit code ${process.exitCode}');
    if (process.stderr.toString().isNotEmpty) {
      stdout.writeln('  Error: ${process.stderr}');
    }
  } else {
    stdout.writeln('  ✓ Command completed successfully');
  }
}

// ============================================================================
// iOS/macOS CocoaPods FIX
// ============================================================================

void _fixPodIssues(String root, String platform) {
  final platformDir = '$root/$platform';
  final podfilePath = '$platformDir/Podfile';

  if (!File(podfilePath).existsSync()) {
    stdout.writeln('  ⚠️ Podfile not found, skipping pod fixes');
    return;
  }

  // Fix 1: Clean pod cache
  stdout.writeln('  → Cleaning CocoaPods cache...');
  final podDir = Directory('$platformDir/Pods');
  if (podDir.existsSync()) {
    try {
      podDir.deleteSync(recursive: true);
      stdout.writeln('  ✓ Deleted Pods directory');
    } catch (e) {
      stdout.writeln('  ⚠️ Could not delete Pods directory: $e');
    }
  }

  // Fix 2: Delete Podfile.lock
  final podfileLock = File('$platformDir/Podfile.lock');
  if (podfileLock.existsSync()) {
    try {
      podfileLock.deleteSync();
      stdout.writeln('  ✓ Deleted Podfile.lock');
    } catch (e) {
      stdout.writeln('  ⚠️ Could not delete Podfile.lock: $e');
    }
  }

  // Fix 3: Update pod repo
  stdout.writeln('  → Updating CocoaPods repos...');
  _runCommand(platformDir, 'pod', ['repo', 'update']);

  // Fix 4: Install pods
  stdout.writeln('  → Installing CocoaPods dependencies...');
  _runCommand(platformDir, 'pod', ['install', '--repo-update']);

  // Fix 5: Run Flutter clean
  stdout.writeln('  → Running Flutter clean...');
  _runCommand(root, 'flutter', ['clean']);

  // Fix 6: Run pub get
  stdout.writeln('  → Running Flutter pub get...');
  _runCommand(root, 'flutter', ['pub', 'get']);
}

// ============================================================================
// LINUX CMAKE FIX
// ============================================================================

void _fixCmakeIssues(String root) {
  final linuxDir = '$root/linux';

  // Fix 1: Clean build directory
  stdout.writeln('  → Cleaning Linux build directory...');
  final buildDir = Directory('$linuxDir/build');
  if (buildDir.existsSync()) {
    try {
      buildDir.deleteSync(recursive: true);
      stdout.writeln('  ✓ Deleted Linux build directory');
    } catch (e) {
      stdout.writeln('  ⚠️ Could not delete build directory: $e');
    }
  }

  // Fix 2: Run Flutter clean
  stdout.writeln('  → Running Flutter clean...');
  _runCommand(root, 'flutter', ['clean']);

  // Fix 3: Run pub get
  stdout.writeln('  → Running Flutter pub get...');
  _runCommand(root, 'flutter', ['pub', 'get']);

  // Fix 4: Try to install dependencies (if on Linux)
  if (Platform.isLinux) {
    stdout.writeln('  → Checking Linux dependencies...');
    stdout.writeln('  ℹ️ If build still fails, install required packages:');
    stdout.writeln(
        '     sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev');
  }
}
