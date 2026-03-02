# 🎯 Build Configuration Guide

Complete guide to managing build configurations for all platforms (Android, iOS, macOS, Windows, Linux, Web).

---

## 📋 Table of Contents

1. [Quick Start](#-quick-start)
2. [Overview](#-overview)
3. [Configuration Tool](#-configuration-tool)
4. [Setting Values](#-setting-values)
5. [Examples](#-examples)
6. [Understanding the System](#-understanding-the-system)
7. [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### Change Environment to Production

```bash
cd example
dart run tool/configure_build.dart --env=production
```

### Set Custom Namespace and API Key

```bash
dart run tool/configure_build.dart \
  --env=production \
  --namespace=com.mycompany.myapp \
  --maps-key=AIzaSyC1234567890abcdefghijk
```

### Update Version for Release

```bash
dart run tool/configure_build.dart \
  --env=production \
  --version-code=15 \
  --version-name=2.1.5
```

---

## 📖 Overview

The build configuration system consists of three main files:

```
lib/config/
├── build_settings.dart    🔧 Configuration values (AUTO-GENERATED)
├── build_config.dart      📦 Configuration logic (DO NOT EDIT)
└── environment.dart       🌍 Environment settings

tool/
└── configure_build.dart   ⚙️ Configuration CLI tool
```

### File Responsibilities

| File | Purpose | Edit? |
|------|---------|-------|
| `build_settings.dart` | Stores all configuration values | ❌ Never (auto-generated) |
| `build_config.dart` | Reads and provides configuration | ❌ Never (system file) |
| `environment.dart` | API environment URLs | ✅ Manual or via tool |
| `configure_build.dart` | CLI tool to change configs | ✅ Yes (if needed) |

---
flutter build apk --debug --no-tree-shake-icons
## ⚙️ Configuration Tool

### Basic Usage

```bash
dart run tool/configure_build.dart --env=<environment> [options]
```

### Available Environments

- **`debug`** - Development environment (localhost, detailed logging)
- **`beta`** - Testing environment (beta API endpoint)
- **`production`** - Live production environment (production API endpoint)

### All Available Options

```bash
dart run tool/configure_build.dart \
  --env=debug|beta|production \
  --namespace=com.example.app \
  --base-url=https://api.example.com \
  --compile-sdk=34 \
  --ndk-version=27.0.12077973 \
  --min-sdk=21 \
  --target-sdk=34 \
  --version-code=1 \
  --version-name=1.0.0 \
  --maps-key=YOUR_GOOGLE_MAPS_API_KEY \
  --camera=true|false \
  --gallery=true|false \
  --notification=true|false \
  --skip-build       # Skip automatic APK build
```

### Option Details

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `--env` | Environment (debug/beta/production) | `debug` | `--env=production` |
| `--namespace` | Android package name | `com.example.form_fields_example` | `--namespace=com.myapp` |
| `--base-url` | API base URL | Env-specific | `--base-url=https://api.myapp.com` |
| `--compile-sdk` | Android compile SDK version | `34` | `--compile-sdk=34` |
| `--ndk-version` | Android NDK version | `27.0.12077973` | `--ndk-version=27.0.12077973` |
| `--min-sdk` | Minimum Android version | `21` | `--min-sdk=21` |
| `--target-sdk` | Target Android version | `34` | `--target-sdk=34` |
| `--version-code` | App version code (integer) | `1` | `--version-code=15` |
| `--version-name` | App version string | `1.0.0` | `--version-name=2.1.5` |
| `--maps-key` | Google Maps API key | Env-specific placeholder | `--maps-key=AIza...` |
| `--camera` | Enable camera permission (Android + iOS/macOS) | `true` | `--camera=false` |
| `--gallery` | Enable gallery/photos permission (Android + iOS/macOS) | `true` | `--gallery=false` |
| `--notification` | Enable notification permission (Android + iOS/macOS) | `true` | `--notification=false` |
| `--platform` | Build platforms (android/ios/macos/windows/linux/web/all) | `android` | `--platform=android,ios` or `--platform=all` |
| `--skip-build` | Skip automatic build | `false` | `--skip-build` |

### Automatic APK Building

**🆕 NEW FEATURE**: After applying configuration, the tool automatically builds for your target platforms!

**Multi-Platform Support**: Build for Android, iOS, macOS, Windows, Linux, and Web!

The tool will:
- ✅ Build for selected platforms
- ✅ Auto-fix platform-specific errors
- ✅ Retry up to 3 times with automatic fixes
- ✅ Show build summary for all platforms

#### Build for specific platforms:
```bash
# Android only (default)
dart run tool/configure_build.dart --env=debug

# Android and iOS
dart run tool/configure_build.dart --env=debug --platform=android,ios

# All platforms
dart run tool/configure_build.dart --env=debug --platform=all

# Single platform
dart run tool/configure_build.dart --env=debug --platform=macos
```

To skip the automatic build:
```bash
dart run tool/configure_build.dart --env=debug --skip-build
```

### Auto-Fix Features

If build errors occur, the tool automatically fixes issues for each platform:

#### Android
- 🔧 Updates Gradle wrapper to latest version
- 🔧 Cleans Gradle cache (.gradle directory)
- 🔧 Cleans build directories
- 🔧 Updates gradle.properties with optimal settings
- 🔧 Runs `flutter clean` and `flutter pub get`

#### iOS/macOS
- 🔧 Cleans CocoaPods cache (Pods directory)
- 🔧 Deletes Podfile.lock
- 🔧 Updates pod repos
- 🔧 Reinstalls pods with `pod install --repo-update`
- 🔧 Runs `flutter clean` and `flutter pub get`

#### Linux
- 🔧 Cleans CMake build directory
- 🔧 Runs `flutter clean` and `flutter pub get`
- 🔧 Provides dependency installation hints

#### All Platforms
- 🔧 Detects dependency errors → runs pub get
- 🔧 Detects cache errors → cleans cache
- 🔧 Retries build automatically

This means **most build issues are automatically resolved** without manual intervention!

### iOS/macOS Permission Configuration

**NEW**: The tool now automatically configures iOS and macOS permissions!

#### Podfile Configuration

Automatically updates `ios/Podfile` and `macos/Podfile` with permission_handler configuration:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    # Permission handler configuration
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',         # When --camera=true
        'PERMISSION_PHOTOS=1',         # When --gallery=true
        'PERMISSION_NOTIFICATIONS=1',  # When --notification=true
        'PERMISSION_LOCATION=1',       # Always enabled
      ]
    end
  end
end
```

#### Info.plist Permission Descriptions

Automatically adds permission usage descriptions to `Info.plist`:

**Conditional (based on flags):**
- `--camera=true` → `NSCameraUsageDescription`
- `--gallery=true` → `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`
- `--notification=true` → `NSUserNotificationUsageDescription`

**Always added:**
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

**Example:**
```bash
dart run tool/configure_build.dart --env=debug --camera=true --gallery=true --notification=false
```

This configures both Android AND iOS/macOS with matching permissions!

---

## 🔧 Setting Values

### Where Configuration Values Are Stored

All configuration values are stored in **`lib/config/build_settings.dart`**:

```dart
/// Build settings for DEBUG environment
class DebugBuildSettings {
  static const String androidNamespace = 'com.example.app.debug';
  static const int androidCompileSdk = 34;
  static const String androidMapsApiKey = 'DEBUG_GOOGLE_MAPS_API_KEY';
  // ... more settings
}

/// Build settings for BETA environment
class BetaBuildSettings {
  static const String androidNamespace = 'com.example.app.beta';
  // ... more settings
}

/// Build settings for PRODUCTION environment
class ProductionBuildSettings {
  static const String androidNamespace = 'com.example.app';
  // ... more settings
}
```

### How Values Are Set

1. **Run the Configuration Tool**: Use the CLI tool to set values
2. **Tool Generates Settings**: The tool writes to `build_settings.dart`
3. **Build Config Reads**: `build_config.dart` reads from `build_settings.dart`
4. **App Uses Config**: Your app uses `BuildConfig.current`

```
┌─────────────────────────┐
│ 1. Run CLI Tool         │
│ configure_build.dart    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 2. Generates Settings   │
│ build_settings.dart     │ ← Values stored here
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 3. Reads Settings       │
│ build_config.dart       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 4. App Uses Config      │
│ BuildConfig.current     │
└─────────────────────────┘
```

---

## 💡 Examples

### Example 1: Setup for Development

```bash
# Configure for debug environment with custom settings
dart run tool/configure_build.dart \
  --env=debug \
  --namespace=com.mycompany.myapp \
  --maps-key=AIzaSyDEBUG_KEY_HERE
```

**What this does:**
- Sets environment to `debug`
- Updates namespace to `com.mycompany.myapp.debug`
- Sets Maps API key for debug environment
- Updates all platforms (Android, iOS if present, etc.)

### Example 2: Prepare Beta Release

```bash
# Configure for beta testing
dart run tool/configure_build.dart \
  --env=beta \
  --namespace=com.mycompany.myapp \
  --version-code=10 \
  --version-name=1.5.0-beta \
  --maps-key=AIzaSyBETA_KEY_HERE
```

**What this does:**
- Sets environment to `beta`
- Updates namespace to `com.mycompany.myapp.beta`
- Sets version code to 10
- Sets version name to "1.5.0-beta"
- Sets beta Maps API key

### Example 3: Production Release

```bash
# Configure for production release
dart run tool/configure_build.dart \
  --env=production \
  --namespace=com.mycompany.myapp \
  --version-code=15 \
  --version-name=2.0.0 \
  --maps-key=AIzaSyPROD_KEY_HERE
```

**What this does:**
- Sets environment to `production`
- Updates namespace to `com.mycompany.myapp` (no suffix)
- Sets version code to 15
- Sets version name to "2.0.0"
- Sets production Maps API key

### Example 4: Disable Permissions

```bash
# Configure without camera and notification
dart run tool/configure_build.dart \
  --env=debug \
  --camera=false \
  --notification=false
```

**What this does:**
- Removes camera permission
- Removes notification permission
- Keeps gallery permission (default)

### Example 5: Custom SDK Versions

```bash
# Configure with custom SDK versions
dart run tool/configure_build.dart \
  --env=production \
  --min-sdk=24 \
  --target-sdk=34 \
  --compile-sdk=34
```

**What this does:**
- Sets minimum SDK to 24 (Android 7.0)
- Sets target SDK to 34 (Android 14)
- Sets compile SDK to 34

### Example 6: Multi-Platform Development Build

```bash
# Build for Android, iOS, and macOS
dart run tool/configure_build.dart \
  --env=debug \
  --platform=android,ios,macos \
  --namespace=com.mycompany.myapp
```

**What this does:**
- Sets environment to debug
- Builds for Android (APK), iOS, and macOS
- Auto-fixes any build errors for each platform
- Shows summary of all builds

### Example 7: Complete Cross-Platform Release

```bash
# Build for all platforms in production
dart run tool/configure_build.dart \
  --env=production \
  --platform=all \
  --namespace=com.mycompany.myapp \
  --version-code=20 \
  --version-name=3.0.0 \
  --maps-key=PROD_KEY
```

**What this does:**
- Sets production environment
- Builds for ALL platforms (Android, iOS, macOS, Windows, Linux, Web)
- Sets version 3.0.0 (build 20)
- Uses production API key
- Auto-fixes all platform-specific errors

---

## 🧠 Understanding the System

### How Environments Work

The system uses three environments, each with its own configuration:

```dart
// In your app
switch (EnvironmentConfig.current) {
  case AppEnvironment.debug:
    return BuildConfig.debug();    // Uses DebugBuildSettings
  case AppEnvironment.beta:
    return BuildConfig.beta();     // Uses BetaBuildSettings
  case AppEnvironment.production:
    return BuildConfig.production(); // Uses ProductionBuildSettings
}
```

### Namespace Per Environment

Each environment gets its own namespace to allow side-by-side installation:

- **Debug**: `com.example.app.debug`
- **Beta**: `com.example.app.beta`
- **Production**: `com.example.app`

### What Gets Updated

When you run the configuration tool, it updates:

✅ `lib/main.dart` - Active environment setting  
✅ `lib/config/environment.dart` - API base URLs  
✅ `lib/config/build_settings.dart` - All configuration values  
✅ `android/app/build.gradle.kts` - Android build configuration  
✅ `android/app/src/main/AndroidManifest.xml` - Android permissions  
✅ `ios/Runner/Info.plist` - iOS permissions (if present)  
✅ `macos/Runner/Info.plist` - macOS permissions (if present)  
✅ `web/index.html` - Web map key (if present)  
✅ `windows/runner/Runner.rc` - Windows version (if present)  
✅ `linux/CMakeLists.txt` - Linux version (if present)  

---

## 🔍 Verification

### Check Current Configuration

```bash
# Run your app in debug mode and check the console
flutter run

# Look for output like:
# ✅ BuildConfig (debug):
#   Android:
#     - Namespace: com.example.app.debug
#     - compileSdk: 34
#     - minSdk: 21
#     - targetSdk: 34
#     - Maps API Key: DEBU****KEY
```

### Check Build Settings File

```bash
# View the generated settings
cat lib/config/build_settings.dart
```

### Check Android Build File

```bash
# View Android build configuration
cat android/app/build.gradle.kts | grep -A 10 "defaultConfig"
```

---

## 🛠️ Troubleshooting

### Issue: "Failed to apply config"

**Solution**: Make sure you're in the `example` directory:

```bash
cd example
dart run tool/configure_build.dart --env=debug
```

### Issue: "File not found"

**Solution**: The tool is looking for project files. Ensure you have:
- `lib/config/environment.dart`
- `lib/main.dart`
- `android/app/build.gradle.kts` (for Android)

### Issue: Configuration not taking effect

**Solution**: 
1. Verify the environment is set in `lib/main.dart`:
   ```dart
   EnvironmentConfig.current = AppEnvironment.debug;
   ```
2. Run `flutter clean` and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Issue: API key not working

**Solution**:
1. Verify the key is set in `build_settings.dart`
2. Check that `AndroidManifest.xml` has the meta-data:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${MAPS_API_KEY}" />
   ```
3. Check `android/app/build.gradle.kts` has:
   ```kotlin
   manifestPlaceholders["MAPS_API_KEY"] = "YOUR_KEY"
   ```

---

## 📁 File Structure

```
example/
├── lib/
│   ├── config/
│   │   ├── build_settings.dart    ← Configuration values (AUTO-GENERATED)
│   │   ├── build_config.dart      ← Configuration reader (DO NOT EDIT)
│   │   └── environment.dart       ← Environment URLs
│   └── main.dart                  ← App entry point
├── tool/
│   └── configure_build.dart       ← Configuration CLI tool
├── android/
│   └── app/
│       ├── build.gradle.kts       ← Android build config
│       └── src/main/AndroidManifest.xml ← Android permissions
├── ios/ (if present)
├── macos/ (if present)
├── web/ (if present)
├── windows/ (if present)
├── linux/ (if present)
└── HOW_TO_USE.md                  ← This guide
```

---

## 🎓 Best Practices

### 1. Use Environment-Specific API Keys

```bash
# Development
dart run tool/configure_build.dart --env=debug --maps-key=DEBUG_KEY

# Beta Testing
dart run tool/configure_build.dart --env=beta --maps-key=BETA_KEY

# Production
dart run tool/configure_build.dart --env=production --maps-key=PROD_KEY
```

### 2. Increment Version Code for Each Release

```bash
# First release
dart run tool/configure_build.dart --env=production --version-code=1

# Second release
dart run tool/configure_build.dart --env=production --version-code=2

# Third release
dart run tool/configure_build.dart --env=production --version-code=3
```

### 3. Use Semantic Versioning

```bash
# Major release (breaking changes)
--version-name=2.0.0

# Minor release (new features)
--version-name=1.5.0

# Patch release (bug fixes)
--version-name=1.0.3
```

### 4. Never Commit API Keys

Add to `.gitignore`:
```
# Do not commit generated settings with real API keys
lib/config/build_settings.dart
```

### 5. Document Your Configuration

Keep a separate secure document with your actual API keys:

```
Development:
  Maps Key: AIzaSy...

Beta:
  Maps Key: AIzaSy...

Production:
  Maps Key: AIzaSy...
```

---

## 🔐 Security Notes

⚠️ **IMPORTANT**: 

1. **Never commit real API keys** to version control
2. Use environment-specific keys
3. Restrict API keys in Google Cloud Console:
   - Android: Restrict to package name + SHA-1 fingerprint
   - iOS: Restrict to bundle identifier
   - Web: Restrict to authorized domains

### Get SHA-1 Fingerprint (Android)

```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore /path/to/release.keystore \
  -alias your-alias
```

---

## 📞 Support

For more information:

- **Build Configuration**: See `BUILD_CONFIG_IMPLEMENTATION.md`
- **API Keys Security**: See `API_KEYS_SECURITY.md`
- **Cross-Platform Setup**: See `CROSS_PLATFORM_SETUP.md`

---

## ✅ Quick Reference

### Common Commands

```bash
# Development
dart run tool/configure_build.dart --env=debug

# Beta testing
dart run tool/configure_build.dart --env=beta

# Production
dart run tool/configure_build.dart --env=production

# With custom namespace
dart run tool/configure_build.dart --env=production --namespace=com.myapp

# Update version
dart run tool/configure_build.dart --env=production --version-code=2 --version-name=1.1.0

# Set API key
dart run tool/configure_build.dart --env=production --maps-key=AIza...

# Show help
dart run tool/configure_build.dart --help
```

---

**Last Updated**: March 2026  
**Version**: 1.0.0
