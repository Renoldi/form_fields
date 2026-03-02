# Build Configuration Guide

Centralized build configuration system for cross-platform Flutter app deployment.

## Overview

The `BuildConfig` class manages all build settings for Android, iOS, macOS, Windows, Linux, and Web platforms in one place. This eliminates scattered configuration and ensures consistency across environments (Debug, Beta, Production).

**File**: `lib/config/build_config.dart`

## Quick Start

### Access Configuration

```dart
import 'package:form_fields_example/config/build_config.dart';

// Get current configuration (automatically uses current environment)
final config = BuildConfig.current;

// Access values
print(config.androidNamespace);     // "com.example.form_fields_example.debug"
print(config.versionCode);          // 1
print(config.androidMapsApiKey);    // "DEBUG_GOOGLE_MAPS_API_KEY"
```

### Use in main.dart

```dart
import 'config/environment.dart';
import 'config/build_config.dart';

void main() {
  // Set environment FIRST (BuildConfig depends on it)
  EnvironmentConfig.current = AppEnvironment.debug;
  
  // Now BuildConfig uses the correct environment
  print(BuildConfig.current);  // Shows entire configuration
  
  runApp(const MyApp());
}
```

### Use in Android build.gradle

```gradle
// android/app/build.gradle.kts

android {
    namespace = "com.example.form_fields_example.debug"
    compileSdk = 34
    ndkVersion = "27.0.12077973"
    
    defaultConfig {
        applicationId = "com.example.form_fields_example.debug"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        // Maps API Key
        manifestPlaceholders = ["MAPS_API_KEY": "YOUR_GOOGLE_MAPS_API_KEY"]
    }
}
```

### Use in AndroidManifest.xml

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest ...>
    
    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Location (if using maps) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Network -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
    
    <application>
        <!-- Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY" />
    </application>
</manifest>
```

## Environment-Specific Configurations

### Debug Environment
- **Namespace**: `com.example.form_fields_example.debug`
- **Compile SDK**: 34
- **Min SDK**: 21
- **Target SDK**: 34
- **Maps API Key**: DEBUG_GOOGLE_MAPS_API_KEY
- **Web Domain**: localhost:8080

```dart
BuildConfig.debug()  // Create debug config
```

### Beta Environment
- **Namespace**: `com.example.form_fields_example.beta`
- **Maps API Key**: BETA_GOOGLE_MAPS_API_KEY
- **Web Domain**: beta.example.com

```dart
BuildConfig.beta()  // Create beta config
```

### Production Environment
- **Namespace**: `com.example.form_fields_example` (no suffix)
- **Maps API Key**: PROD_GOOGLE_MAPS_API_KEY
- **Web Domain**: example.com

```dart
BuildConfig.production()  // Create production config
```

## API Key Management

### Security Guidelines ⚠️

**NEVER commit API keys to the repository!**

1. **Create .gitignore entry**:
   ```
   # .gitignore
   lib/config/api_keys.dart
   /android/local.properties
   /ios/local.properties
   ```

2. **Setup for Local Development**:

   **Option 1**: Direct replacement (local only, never commit)
   ```dart
   // In build_config.dart
   static String _getEnvironmentSpecificMapsKey() {
     switch (EnvironmentConfig.current) {
       case AppEnvironment.production:
         return 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxx'; // Prod key (local)
       case AppEnvironment.beta:
         return 'AIzaSyDyyyyyyyyyyyyyyyyyyyyyyyyy'; // Beta key (local)
       case AppEnvironment.debug:
         return 'AIzaSyDzzzzzzzzzzzzzzzzzzzzzzzzzz'; // Debug key (local)
     }
   }
   ```

   **Option 2**: Separate secure file (recommended)
   ```dart
   // Create lib/config/api_keys.dart (GITIGNORED)
   class ApiKeys {
     static const String mapsApiKey = 'YOUR_ACTUAL_KEY_HERE';
   }
   ```

   Then in BuildConfig:
   ```dart
   static String _getEnvironmentSpecificMapsKey() {
     // Import ApiKeys from gitignored file
     // return ApiKeys.mapsApiKey;
   }
   ```

3. **Getting Google Maps API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create new project or select existing
   - Enable **Google Maps Platform** (Maps, Routes, Places APIs)
   - Create API key for Android:
     - Get SHA-1 fingerprint:
       ```bash
       keytool -list -v -keystore ~/.android/debug.keystore \
         -alias androiddebugkey \
         -storepass android \
         -keypass android
       ```
     - Restrict to Android apps
     - Add package name + SHA-1 fingerprint
   - Create API key for iOS (separate key)

## Platform-Specific Setup

### Android

**File**: `android/app/build.gradle.kts`

Update with BuildConfig values:
```gradle
android {
    namespace = BuildConfig.androidNamespace
    compileSdk = BuildConfig.androidCompileSdk
    ndkVersion = BuildConfig.ndkVersion

    defaultConfig {
        applicationId = BuildConfig.androidNamespace
        minSdk = BuildConfig.androidMinSdk
        targetSdk = BuildConfig.androidTargetSdk
        versionCode = BuildConfig.versionCode
        versionName = BuildConfig.versionName
        
        manifestPlaceholders = [
            "MAPS_API_KEY": BuildConfig.androidMapsApiKey
        ]
    }
}
```

### iOS

**File**: `ios/Podfile`

Add Maps API key:
```ruby
target 'Runner' do
  flutter_root = File.expand_path(File.join(packages_dir, '.symlinks', 'flutter'), __FILE__)
  load File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper.rb')

  flutter_ios_podfile_setup

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
    end
  end
end
```

**File**: `ios/Runner/GeneratedPluginRegistrant.m`

Add Maps configuration.

### macOS

**File**: `macos/Podfile`

Similar to iOS setup.

### Windows

**File**: `windows/runner/CMakeLists.txt`

Add version information and API keys as CMake variables.

### Web

**File**: `web/index.html`

Add Google Maps script:
```html
<head>
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&libraries=places"></script>
</head>
```

## Version Management

### Version Code
- Integer representing app version for store rankings
- **Must increment** with each release on any platform
- Typically: `1, 2, 3, 4, ...`

### Version Name
- Human-readable version using semantic versioning
- Format: `major.minor.patch`
- Examples: `1.0.0`, `1.1.0`, `2.0.0`

**Increment rules**:
- **Patch** (1.0.x): Bug fixes and minor updates
- **Minor** (1.x.0): New features, backward compatible
- **Major** (x.0.0): Breaking changes

```dart
BuildConfig.current.versionCode   // 1
BuildConfig.current.versionName   // "1.0.0"
```

## Android Permissions

### Default Permissions
```dart
BuildConfig.current.androidPermissions
  // ["INTERNET", "ACCESS_FINE_LOCATION", ...]
```

### Add Custom Permission
```dart
final config = BuildConfig.current;
config.addAndroidPermission('android.permission.CAMERA');
config.addAndroidPermission('android.permission.RECORD_AUDIO');
```

### Check Permission
```dart
if (config.hasAndroidPermission('android.permission.CAMERA')) {
  // Permission is configured
}
```

### Common Permissions
```
android.permission.INTERNET                    // Required for API calls
android.permission.ACCESS_FINE_LOCATION        // GPS location
android.permission.ACCESS_COARSE_LOCATION      // Network-based location
android.permission.ACCESS_NETWORK_STATE        // Check network status
android.permission.CHANGE_NETWORK_STATE        // Modify network status
android.permission.CAMERA                      // Camera access
android.permission.READ_CONTACTS                // Contact list
android.permission.WRITE_EXTERNAL_STORAGE      // File write
android.permission.READ_EXTERNAL_STORAGE       // File read
```

## Integration with EnvironmentConfig

BuildConfig automatically syncs with EnvironmentConfig:

```dart
// Set environment first
EnvironmentConfig.current = AppEnvironment.production;

// BuildConfig automatically uses production settings
print(BuildConfig.current.androidNamespace);  // com.example.form_fields_example
print(BuildConfig.current.androidMapsApiKey); // PROD_GOOGLE_MAPS_API_KEY

// Switch environment
EnvironmentConfig.current = AppEnvironment.debug;

// BuildConfig automatically updates
print(BuildConfig.current.androidNamespace);  // com.example.form_fields_example.debug
```

## Validation & Debugging

### Check Production Readiness
```dart
if (BuildConfig.current.isProductionReady) {
  print("✅ Ready for production deployment");
} else {
  print("⚠️ API keys need to be configured");
}
```

### Print Full Configuration
```dart
print(BuildConfig.current);
// Outputs:
// BuildConfig (debug):
//   Android:
//     - Namespace: com.example.form_fields_example.debug
//     - compileSdk: 34
//     - ndkVersion: 27.0.12077973
//     - minSdk: 21
//     - targetSdk: 34
//     - Maps API Key: DEBA****KEY
//     - Permissions: 5 configured
//   ...
```

### Generate Build Configurations
```dart
// Get Android build.gradle configuration
print(BuildConfig.current.androidBuildGradleConfig);

// Get AndroidManifest.xml permissions
print(BuildConfig.current.androidManifestPermissions);

// Get iOS Podfile configuration
print(BuildConfig.current.iosPodfieConfig);

// Get Web configuration
print(BuildConfig.current.webConfig);
```

## File Structure

```
lib/config/
├── environment.dart         # Environment configs (Debug/Beta/Prod)
├── build_config.dart        # Build configurations
├── error_position.dart      # Error position enum
└── error_type.dart         # Error type enum
```

## Migration from Hardcoded Values

### Before (Hardcoded)
```dart
// android/app/build.gradle
android {
    namespace = "com.example.app"
    compileSdk = 34
    
    defaultConfig {
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

### After (BuildConfig)
```dart
// Use BuildConfig anywhere in your app
final config = BuildConfig.current;
// Access all values from single source of truth
```

## Troubleshooting

### Maps API Key Not Working
- **Problem**: "MapsInitializationException: Maps API key not found"
- **Solution**: 
  1. Verify API key is correct in BuildConfig
  2. Check AndroidManifest.xml has meta-data tag
  3. Verify API key restrictions match your package name + SHA-1

### Version Code Conflicts
- **Problem**: "android.versionCode smaller than version on device"
- **Solution**: Increment BuildConfig.versionCode before release

### Wrong Environment Building
- **Problem**: Debug build using production API key
- **Solution**: Ensure EnvironmentConfig is set before BuildConfig is used

### Namespace Conflicts
- **Problem**: App already installed with different namespace
- **Solution**: Uninstall previous app or use different device

## Best Practices

1. **Set Environment First**
   ```dart
   void main() {
     EnvironmentConfig.current = AppEnvironment.production;
     // Now BuildConfig will be production
     runApp(const MyApp());
   }
   ```

2. **Never Commit API Keys**
   - Use .gitignore for sensitive files
   - Store keys locally or in secure CI/CD variables

3. **Version Your Releases**
   - Increment versionCode for each store build
   - Use semantic versioning for versionName

4. **Test All Platforms**
   - Test Android with BuildConfig values
   - Test iOS with Podfile setup
   - Test Web with index.html configuration

5. **Document Custom Configuration**
   - Comment any non-standard settings
   - Explain why deviations from defaults exist

6. **Validate Before Release**
   ```dart
   assert(BuildConfig.current.isProductionReady, 
      'API keys must be configured before release!');
   ```

## Related Files

- **EnvironmentConfig**: `lib/config/environment.dart`
- **Error Position**: `lib/config/error_position.dart`
- **Error Type**: `lib/config/error_type.dart`
- **HttpService**: `lib/data/services/http_service.dart`
- **User Model**: `lib/data/models/user.dart`

## Support

For questions or issues:
1. Check this BUILD_CONFIG.md guide
2. Review code comments in build_config.dart
3. Check integration tests in test/
4. Refer to ENVIRONMENT_CONFIG.md for environment setup
