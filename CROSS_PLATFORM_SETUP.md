# Cross-Platform Build & Configuration Setup

Complete setup guide for managing namespace, SDKs, versions, and permissions across all platform targets (Android, iOS, macOS, Windows, Linux, Web).

## Platform Compatibility Matrix

| Feature | Android | iOS | macOS | Windows | Linux | Web |
|---------|---------|-----|-------|---------|-------|-----|
| Namespace | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| compileSdk | ✅ | N/A | N/A | N/A | N/A | N/A |
| ndkVersion | ✅ | N/A | N/A | N/A | N/A | N/A |
| minSdk | ✅ | ✅ | ✅ | N/A | N/A | N/A |
| targetSdk | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| versionCode | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| versionName | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Permissions | ✅ | ✅ | ✅ | ✅ | ✅ | N/A |
| Maps API Key | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ |

## Android Configuration

### Project Structure
```
android/
├── app/
│   ├── build.gradle.kts                    # Main app configuration
│   ├── proguard-rules.pro                  # Code obfuscation rules
│   ├── src/
│   │   ├── main/
│   │   │   ├── AndroidManifest.xml         # Permissions, components
│   │   │   ├── kotlin/
│   │   │   │   └── com/example/app/
│   │   │   │       └── MainActivity.kt
│   │   │   └── res/
│   │   │       ├── drawable/
│   │   │       ├── values/
│   │   │       │   ├── strings.xml
│   │   │       │   └── colors.xml
│   │   │       └── mipmap/
│   │   ├── debug/
│   │   │   └── AndroidManifest.xml
│   │   └── profile/
│   │       └── AndroidManifest.xml
│   └── google-services.json               # Firebase config (GITIGNORED)
├── build.gradle.kts                        # Project-level gradle
├── settings.gradle.kts
├── gradle.properties                       # Gradle configuration
├── local.properties                        # SDK path, API keys (GITIGNORED)
└── gradle/
    └── wrapper/
        └── gradle-wrapper.properties
```

### build.gradle.kts Configuration

```gradle
// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    kotlin("android")
    id("com.google.gms.google-services")  // Firebase
}

android {
    // ========================================================================
    // Build Configuration (from BuildConfig)
    // ========================================================================
    namespace = "com.example.form_fields_example.debug"  // Package ID
    compileSdk = 34                                      // Compile target
    ndkVersion = "27.0.12077973"                         // NDK for native code
    
    defaultConfig {
        applicationId = namespace
        minSdk = 21                        // Support Android 5.0+
        targetSdk = 34                     // Target Android 14+
        versionCode = 1
        versionName = "1.0.0"
        
        // Maps API Key (from BuildConfig)
        manifestPlaceholders = [
            "MAPS_API_KEY": "DEBUG_GOOGLE_MAPS_API_KEY"
        ]
        
        // Optional: Additional configuration
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables.useSupportLibrary = true
    }
```

### AndroidManifest.xml - Permissions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.form_fields_example">
    
    <!-- ====================================================================
         PERMISSIONS (from BuildConfig.androidPermissions)
         ==================================================================== -->
    
    <!-- INTERNET: Required for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- LOCATION: For maps and location-based services -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- NETWORK: Monitor and control network state -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
    
    <!-- STORAGE: File access (if needed) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- CAMERA: For photo/video capture (if needed) -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- CONTACTS: For contact list access (if needed) -->
    <uses-permission android:name="android.permission.READ_CONTACTS" />
    
    <!-- ====================================================================
         APPLICATION CONFIGURATION
         ==================================================================== -->
    <application
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false">
        
        <!-- Maps API Key (from BuildConfig) -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="${MAPS_API_KEY}" />
        
        <!-- Firebase Cloud Messaging (optional) -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
        
        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
    </application>
</manifest>
```

## iOS Configuration

### Project Structure
```
ios/
├── Podfile                          # iOS dependencies
├── Podfile.lock
├── Runner.xcworkspace              # Xcode workspace
├── Runner/
│   ├── Runner.xcodeproj
│   ├── GeneratedPluginRegistrant.h
│   ├── GeneratedPluginRegistrant.m
│   ├── Info.plist                  # Version & permissions
│   ├── GoogleService-Info.plist    # Firebase (GITIGNORED)
│   ├── Assets.xcassets/
│   ├── Base.lproj/
│   │   ├── LaunchScreen.storyboard
│   │   └── Main.storyboard
│   └── Runner-Bridging-Header.h
├── Flutter/
│   ├── Flutter.podspec
│   ├── flutter_export_environment.sh
│   └── Generated.xcconfig
└── Pods/
    └── local_pods.rb
```

### Podfile Configuration

```ruby
# ios/Podfile
platform :ios, '12.0'  # From BuildConfig.iosMinimumDeploymentTarget

# CocoaPods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Set deployment target
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Add Maps API Key
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'GOOGLE_MAPS_API_KEY=DEBUG_GOOGLE_MAPS_API_KEY'
      ]
    end
  end
end
```

### Info.plist Configuration

```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ================================================================
         VERSION INFORMATION (from BuildConfig)
         ================================================================ -->
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>  <!-- versionName -->
    
    <key>CFBundleVersion</key>
    <string>1</string>  <!-- versionCode -->
    
    <!-- ================================================================
         MINIMUM DEPLOYMENT TARGET (from BuildConfig)
         ================================================================ -->
    <key>MinimumOSVersion</key>
    <string>12.0</string>
    
    <!-- ================================================================
         PERMISSIONS (from BuildConfig.permissions)
         ================================================================ -->
    
    <!-- LOCATION -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to show nearby services on the map</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>We need your location to show nearby services on the map</string>
    
    <!-- PHOTOS -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to your photos to upload profiles</string>
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to take profile photos</string>
    
    <!-- CONTACTS -->
    <key>NSContactsUsageDescription</key>
    <string>We need access to your contacts</string>
    
    <!-- NETWORKING -->
    <key>NSBonjourServices</key>
    <array>
        <string>_http._tcp</string>
        <string>_https._tcp</string>
    </array>
    
    <!-- APP TRANSPORT SECURITY -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
    
</dict>
</plist>
```

## macOS Configuration

### Project Structure
```
macos/
├── Podfile                          # macOS dependencies
├── Runner.xcworkspace
├── Runner/
│   ├── Runner.xcodeproj
│   ├── Info.plist                  # Version & permissions
│   ├── DebugProfile.entitlements
│   ├── Release.entitlements
│   ├── GeneratedPluginRegistrant.swift
│   └── Assets.xcassets/
├── Flutter/
│   └── Generated.xcconfig
└── Pods/
```

### Podfile Configuration

```ruby
# macos/Podfile
platform :osx, '10.15'  # From BuildConfig.macosMinimumDeploymentTarget

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_osx_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'GOOGLE_MAPS_API_KEY=DEBUG_GOOGLE_MAPS_API_KEY'
      ]
    end
  end
end
```

### Info.plist Configuration

```xml
<!-- macos/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    
    <key>CFBundleVersion</key>
    <string>1</string>
    
    <key>MinimumOSVersion</key>
    <string>10.15</string>
    
    <key>NSLocationUsageDescription</key>
    <string>This app needs your location</string>
    
</dict>
</plist>
```

## Windows Configuration

### Project Structure
```
windows/
├── runner/
│   ├── CMakeLists.txt               # Build configuration
│   ├── flutter.cmake
│   ├── win32_window.cpp
│   ├── win32_window.h
│   ├── windows.cpp
│   ├── windows.h
│   ├── utils.cpp
│   └── utils.h
├── packaging/
│   └── windows_package_files.txt
└── flutter/
    └── generated_plugins.cmake
```

### CMakeLists.txt Configuration

```cmake
# windows/runner/CMakeLists.txt
cmake_minimum_required(VERSION 3.14)
project(form_fields_example LANGUAGES CXX)

# Version information (from BuildConfig)
set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_PATCH 0)
set(VERSION_CODE 1)

# Windows minimum version
set(MIN_WINDOWS_VERSION 10)

# Add version to executable
add_executable(form_fields_example)
set_target_properties(form_fields_example PROPERTIES
    VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"
    SOVERSION "${VERSION_MAJOR}"
)

# Windows-specific configuration
if (CMAKE_BUILD_TYPE STREQUAL "Release")
    # Release build flags
    set(CMAKE_CXX_FLAGS_RELEASE "/O2 /NDEBUG")
else()
    # Debug build flags
    set(CMAKE_CXX_FLAGS_DEBUG "/Zi /Od")
endif()
```

## Linux Configuration

### Project Structure
```
linux/
├── CMakeLists.txt                   # Build configuration
├── my_application/
│   ├── CMakeLists.txt
│   ├── main.cc
│   ├── my_application.cc
│   ├── my_application.h
│   ├── my_application_icons.cc
│   └── linux_window_config.h
├── flutter/
│   ├── CMakeLists.txt
│   └── generated_plugins.cmake
└── packaging/
    ├── linux_package_files.txt
    ├── org.app.form_fields_example.desktop
    ├── org.app.form_fields_example.appdata.xml.in
    └── icons/
        └── com.example.form_fields_example.png
```

### CMakeLists.txt Configuration

```cmake
# linux/CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(form_fields_example LANGUAGES CXX)

set(PROJECT_VERSION "1.0.0")
set(PROJECT_VERSION_CODE "1")

# Desktop entry file
configure_file(
    "packaging/org.app.form_fields_example.desktop.in"
    "org.app.form_fields_example.desktop"
    @ONLY
)

# AppData file
configure_file(
    "packaging/org.app.form_fields_example.appdata.xml.in"
    "org.app.form_fields_example.appdata.xml"
    @ONLY
)
```

### Desktop Entry Configuration

```ini
# linux/packaging/org.app.form_fields_example.desktop
[Desktop Entry]
Type=Application
Name=Form Fields Example
Comment=Flutter cross-platform application
Exec=$ENV{SNAP}/bin/form_fields_example
Icon=org.app.form_fields_example
Version=1.0.0
Categories=Utility;
```

## Web Configuration

### Project Structure
```
web/
├── index.html                       # Main entry point
├── manifest.json                    # Progressive Web App
├── favicon.png
└── icons/
    ├── Icon-192.png
    ├── Icon-512.png
    └── Icon-maskable-192.png
```

### index.html Configuration

```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
  <head>
    <base href="$FLUTTER_BASE_HREF">
    
    <!-- ================================================================
         META INFORMATION (from BuildConfig)
         ================================================================ -->
    <meta charset="UTF-8">
    <meta content="IE=Edge" http-equiv="X-UA-Compatible">
    <meta name="description" content="Flutter cross-platform application">
    <meta name="version" content="1.0.0">
    
    <!-- Progressive Web App -->
    <meta name="theme-color" content="#1967d2">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <meta name="apple-mobile-web-app-title" content="Form Fields Example">
    <link rel="apple-touch-icon" href="icons/Icon-192.png">
    
    <!-- ================================================================
         API KEYS (from BuildConfig)
         ================================================================ -->
    <script>
      window.flutterConfiguration = {
        mapsApiKey: 'DEBUG_GOOGLE_MAPS_API_KEY',
        baseUrl: 'https://localhost:8080',
        environment: 'debug'
      };
    </script>
    
    <!-- Google Maps -->
    <script src="https://maps.googleapis.com/maps/api/js?key=DEBUG_GOOGLE_MAPS_API_KEY&libraries=places"></script>
    
    <!-- Firebase -->
    <script src="https://www.gstatic.com/firebasejs/10.0.0/firebase-app.js"></script>
    <script src="https://www.gstatic.com/firebasejs/10.0.0/firebase-analytics.js"></script>
    <script>
      const firebaseConfig = {
        apiKey: "AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxx",
        projectId: "form-fields-example",
        appId: "1:123456789:web:abcdef123456789",
      };
      firebase.initializeApp(firebaseConfig);
    </script>
    
    <link rel="manifest" href="manifest.json">
  </head>
  <body>
    <!-- ================================================================
         FLUTTER WEB APPLICATION
         ================================================================ -->
    <script>
      {{flutter_js}}
    </script>
    
    <script>
      _flutter.loader.loadEntrypoint({
        serviceWorkerSettings: "flutter_service_worker.js?v={{service_worker_version}}"
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    </script>
  </body>
</html>
```

### manifest.json Configuration

```json
{
  "name": "Form Fields Example",
  "short_name": "Form Fields",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#1967d2",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

## Version Management Across Platforms

### Semantic Versioning

```dart
// Version: MAJOR.MINOR.PATCH
// Example: 1.2.3

// MAJOR: Breaking changes (e.g., 1.0.0 → 2.0.0)
//   - Changed package name
//   - Changed API structure
//   - Changed data format

// MINOR: New features, backward compatible (e.g., 1.0.0 → 1.1.0)
//   - Added new permission
//   - Added new API endpoint
//   - Added new feature

// PATCH: Bug fixes (e.g., 1.0.0 → 1.0.1)
//   - Fixed crash
//   - Fixed UI issue
//   - Performance improvement
```

### Version Code Strategy

```dart
// Sequential versioning (recommended)
// - Simple and predictable
// - Platform stores require increasing versionCode
// - Example: 1, 2, 3, 4, 5...

// Date-based versioning
// - Format: YYYYMMDDnn (e.g., 202603021 for March 2, 2026, build 1)
// - Pro: Shows build date
// - Con: Can exceed max int if not careful

// Version-based versioning
// - Format: MMmmPPPP (major=MM, minor=mm, patch=PPPP)
// - Example: 01010001 for 1.1.1
// - Pro: Encodes version info
// - Con: Less intuitive than sequential
```

## Release Checklist

### Pre-Release
- ✅ Update versionCode (increment by 1)
- ✅ Update versionName (semantic version)
- ✅ Update CHANGELOG.md
- ✅ Run all tests
- ✅ Run flutter analyze (0 errors)
- ✅ Test on minSdk device (Android)
- ✅ Test on iOS 12.0 (oldest supported)
- ✅ Build for all platforms
- ✅ Verify API keys are production keys
- ✅ Sign release builds

### Post-Release
- ✅ Tag commit with version (e.g., v1.0.0)
- ✅ Create GitHub release
- ✅ Monitor crash reports
- ✅ Monitor API usage
- ✅ Monitor user feedback
- ✅ Update documentation
- ✅ Communicate to users via release notes

## Quick Reference

### BuildConfig Access
```dart
// Current configuration
BuildConfig.current

// Environment-specific
BuildConfig.debug()
BuildConfig.beta()
BuildConfig.production()

// Individual values
BuildConfig.current.androidNamespace
BuildConfig.current.versionCode
BuildConfig.current.versionName
BuildConfig.current.androidMapsApiKey
```

### Build for Each Platform
```bash
# Android
flutter build apk
flutter build appbundle

# iOS
flutter build ios

# macOS
flutter build macos

# Windows
flutter build windows

# Linux
flutter build linux

# Web
flutter build web
```

## Related Documentation

- [BUILD_CONFIG.md](BUILD_CONFIG.md) - Build configuration system details
- [API_KEYS_SECURITY.md](API_KEYS_SECURITY.md) - Security best practices
- [ENVIRONMENT_CONFIG.md](example/ENVIRONMENT_CONFIG.md) - Environment setup
- [Apple Developer Documentation](https://developer.apple.com/)
- [Android Developer Documentation](https://developer.android.com/)
- [Flutter Build Documentation](https://flutter.dev/docs/deployment)
