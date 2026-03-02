# 🛠️ Build Configuration Tool

Professional build configuration management for Flutter/Dart applications.

## Purpose

This tool provides a single command to configure your entire application across all platforms:
- Android
- iOS (when present)
- macOS (when present)
- Windows (when present)
- Linux (when present)
- Web (when present)

## Quick Start

```bash
# Debug environment (development)
dart run tool/configure_build.dart --env=debug

# Beta environment (testing)
dart run tool/configure_build.dart --env=beta

# Production environment (release)
dart run tool/configure_build.dart --env=production
```

## What It Does

When you run this tool, it:

1. ✅ Generates `lib/config/build_settings.dart` with your configuration
2. ✅ Updates `lib/main.dart` with the active environment
3. ✅ Updates `lib/config/environment.dart` with API URLs
4. ✅ Updates `android/app/build.gradle.kts` with Android settings
5. ✅ Updates `android/app/src/main/AndroidManifest.xml` with permissions
6. ✅ Updates iOS/macOS/Web/Windows/Linux configs (if present)
7. ✅ **🆕 Updates iOS/macOS `Podfile` with permission_handler configuration**
8. ✅ **🆕 Updates iOS/macOS `Info.plist` with permission descriptions**
9. ✅ **🆕 Automatically builds for selected platforms** with auto-fix for errors

## Configuration Storage

All configuration values are stored in:
```
lib/config/build_settings.dart
```

This file is **auto-generated** - never edit it manually!

## Usage Examples

### Basic Environment Change

```bash
dart run tool/configure_build.dart --env=production
```

### Custom Namespace

```bash
dart run tool/configure_build.dart \
  --env=production \
  --namespace=com.mycompany.myapp
```

### Set Version

```bash
dart run tool/configure_build.dart \
  --env=production \
  --version-code=42 \
  --version-name=3.2.1
```

### Set API Key

```bash
dart run tool/configure_build.dart \
  --env=production \
  --maps-key=AIzaSyYOUR_REAL_API_KEY
```

### Complete Configuration

```bash
dart run tool/configure_build.dart \
  --env=production \
  --namespace=com.mycompany.awesomeapp \
  --version-code=50 \
  --version-name=5.0.0 \
  --maps-key=AIzaSyPROD_KEY \
  --camera=true \
  --gallery=true \
  --notification=true
```

## Available Options

| Option | Description | Default |
|--------|-------------|---------|
| `--env` | Environment (debug/beta/production) | `debug` |
| `--namespace` | Android package name | `com.example.form_fields_example` |
| `--base-url` | API base URL | Environment-specific |
| `--compile-sdk` | Android compile SDK | `34` |
| `--ndk-version` | Android NDK version | `27.0.12077973` |
| `--min-sdk` | Minimum Android SDK | `21` |
| `--target-sdk` | Target Android SDK | `34` |
| `--version-code` | App version code | `1` |
| `--version-name` | App version name | `1.0.0` |
| `--maps-key` | Google Maps API key | Environment placeholder |
| `--camera` | Enable camera permission (Android + iOS/macOS) | `true` |
| `--gallery` | Enable gallery/photos permission (Android + iOS/macOS) | `true` |
| `--notification` | Enable notification permission (Android + iOS/macOS) | `true` |
| `--platform` | Build platforms (android/ios/macos/windows/linux/web/all) | `android` |
| `--skip-build` | Skip automatic build | `false` |

## Automatic Multi-Platform Building

**🆕 NEW**: The tool now builds for multiple platforms with intelligent error fixing!

### Supported Platforms:
- 🤖 **Android** - APK (default)
- 🍎 **iOS** - Debug build (no codesign)
- 🖥️ **macOS** - Desktop app
- 🧪 **Windows** - Windows app
- 🐧 **Linux** - Linux app
- 🌐 **Web** - Web build

### Usage:
```bash
# Build Android only (default)
dart run tool/configure_build.dart --env=debug

# Build multiple platforms
dart run tool/configure_build.dart --env=debug --platform=android,ios,macos

# Build all platforms
dart run tool/configure_build.dart --env=production --platform=all

# Skip build
dart run tool/configure_build.dart --env=debug --skip-build
```

### What happens:
1. Configuration is applied
2. Builds are executed for selected platforms
3. If errors occur, the tool automatically:
   
   **Android:**
   - Updates Gradle wrapper
   - Cleans Gradle cache
   - Updates gradle.properties
   - Runs flutter clean & pub get
   
   **iOS/macOS:**
   - Cleans CocoaPods cache
   - Deletes Podfile.lock
   - Updates pod repos
   - Reinstalls pods
   - Runs flutter clean & pub get
   
   **Linux:**
   - Cleans CMake build directory
   - Runs flutter clean & pub get
   - Provides dependency hints
   
   **All Platforms:**
   - Detects and fixes dependency errors
   - Detects and fixes cache errors
   - Retries build (up to 3 attempts)

### Skip the build:
```bash
dart run tool/configure_build.dart --env=debug --skip-build
```

### Auto-Fix Features:
- ✅ Detects Gradle errors (Android)
- ✅ Detects CocoaPods errors (iOS/macOS)
- ✅ Detects CMake errors (Linux)
- ✅ Detects dependency errors (all platforms)
- ✅ Detects cache errors (all platforms)
- ✅ Automatically applies platform-specific fixes
- ✅ Retries build until success (max 3 attempts)
- ✅ Shows build summary for all platforms

## iOS/macOS Permission Configuration

### Podfile Configuration

The tool automatically configures the `Podfile` with permission_handler settings:

- **Camera**: `PERMISSION_CAMERA=1` (when `--camera=true`)
- **Photos**: `PERMISSION_PHOTOS=1` (when `--gallery=true`)
- **Notifications**: `PERMISSION_NOTIFICATIONS=1` (when `--notification=true`)
- **Location**: `PERMISSION_LOCATION=1` (always enabled)

The configuration is added to the `post_install` hook automatically.

### Info.plist Permission Descriptions

Permission usage descriptions are conditionally added to `Info.plist`:

**When `--camera=true`:**
- `NSCameraUsageDescription`: "Camera is required to capture images."

**When `--gallery=true`:**
- `NSPhotoLibraryUsageDescription`: "Gallery access is required to select images."
- `NSPhotoLibraryAddUsageDescription`: "Photo library access is required to save images."

**When `--notification=true`:**
- `NSUserNotificationUsageDescription`: "Notifications are used to keep you updated."

**Always added (location):**
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

### Example:

```bash
# Configure iOS/macOS with camera and gallery only
dart run tool/configure_build.dart \
  --env=debug \
  --camera=true \
  --gallery=true \
  --notification=false
```

This will:
- ✅ Add camera and photos permissions to Podfile
- ✅ Add camera and photos descriptions to Info.plist
- ✅ Skip notification permission
- ✅ Always add location permissions

## Help

```bash
dart run tool/configure_build.dart --help
```

## Documentation

For complete documentation, see:
- **[HOW_TO_USE.md](../HOW_TO_USE.md)** - Complete usage guide
- **[CONFIGURATION_FLOW.md](../CONFIGURATION_FLOW.md)** - Where values are set and read

## Architecture

```
Tool Input
    ↓
configure_build.dart (this tool)
    ↓
Generates/Updates:
├── lib/config/build_settings.dart (configuration storage)
├── lib/main.dart (active environment)
├── lib/config/environment.dart (API URLs)
├── android/app/build.gradle.kts (Android build config)
├── android/app/src/main/AndroidManifest.xml (permissions)
└── iOS/macOS/Web/Windows/Linux configs (if present)
    ↓
App reads from:
lib/config/build_config.dart
    ↓
BuildConfig.current (used throughout app)
```

## Example Output

### Configuration + Single Platform Build
```
✅ Configuration applied successfully
  - Updated active environment in lib/main.dart -> debug
  - Generated lib/config/build_settings.dart with debug configuration
  - Updated Android build.gradle.kts

🔨 Building for platforms: android

============================================================
Platform: ANDROID
============================================================

📦 Build attempt 1 of 3...
▶️  Running: flutter build apk --debug --no-tree-shake-icons

Running Gradle task 'assembleDebug'...                              5.1s
✓ Built build/app/outputs/flutter-apk/app-debug.apk

✅ Android APK built successfully!
📱 APK Location: build/app/outputs/flutter-apk/app-debug.apk

============================================================
BUILD SUMMARY
============================================================
✅ ANDROID: SUCCESS

🎉 All platforms built successfully!
```

### Multi-Platform Build
```
🔨 Building for platforms: android, ios, macos

============================================================
Platform: ANDROID
============================================================
✅ Android APK built successfully!

============================================================
Platform: IOS
============================================================
✅ iOS built successfully!

============================================================
Platform: MACOS
============================================================
✅ macOS built successfully!

============================================================
BUILD SUMMARY
============================================================
✅ ANDROID: SUCCESS
✅ IOS: SUCCESS
✅ MACOS: SUCCESS

🎉 All platforms built successfully!
```

## Requirements

- Dart SDK
- Flutter project structure
- At minimum, Android configuration files must exist

## Notes

- The tool skips platforms that don't have configuration files present
- All values are environment-specific (debug, beta, production each have their own)
- API keys should be restricted in Google Cloud Console for security
- Never commit real API keys to version control

## License

Same as parent project.
