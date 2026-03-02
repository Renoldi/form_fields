# 📍 Configuration Value Flow

## Where Values Are Set & Read

This document explains where configuration values are stored and how they flow through the build system.

---

## 🎯 Quick Answer

**Where to set values?**  
👉 Run: `dart run tool/configure_build.dart --env=debug|beta|production [options]`

**Where are values stored?**  
👉 `lib/config/build_settings.dart` (auto-generated)

**Where are values read?**  
👉 `lib/config/build_config.dart` (uses build_settings.dart)

**Where does the app access config?**  
👉 `BuildConfig.current` anywhere in your app

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER RUNS COMMAND                                            │
│                                                                 │
│  $ dart run tool/configure_build.dart \                        │
│      --env=production \                                         │
│      --namespace=com.myapp \                                    │
│      --maps-key=AIza... \                                       │
│      --version-code=5                                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. TOOL GENERATES SETTINGS FILE                                 │
│                                                                 │
│  tool/configure_build.dart                                      │
│  ├─ Parses command arguments                                    │
│  ├─ Validates input                                             │
│  └─ Generates build_settings.dart                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. VALUES STORED IN SETTINGS FILE                               │
│                                                                 │
│  lib/config/build_settings.dart                                 │
│                                                                 │
│  class DebugBuildSettings {                                     │
│    static const String androidNamespace = 'com.myapp.debug';   │
│    static const int versionCode = 5;                            │
│    static const String androidMapsApiKey = 'DEBUG_KEY';         │
│    // ... more settings                                         │
│  }                                                              │
│                                                                 │
│  class BetaBuildSettings { ... }                                │
│  class ProductionBuildSettings { ... }                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. BUILD CONFIG READS SETTINGS                                  │
│                                                                 │
│  lib/config/build_config.dart                                   │
│                                                                 │
│  import 'build_settings.dart';                                  │
│                                                                 │
│  factory BuildConfig.debug() {                                  │
│    return BuildConfig(                                          │
│      androidNamespace: DebugBuildSettings.androidNamespace,    │
│      versionCode: DebugBuildSettings.versionCode,              │
│      androidMapsApiKey: DebugBuildSettings.androidMapsApiKey,  │
│      // ... uses all DebugBuildSettings values                  │
│    );                                                           │
│  }                                                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. APP ACCESSES CONFIG ANYWHERE                                 │
│                                                                 │
│  Your app code:                                                 │
│                                                                 │
│  // Get current config based on environment                     │
│  final config = BuildConfig.current;                            │
│                                                                 │
│  // Access any setting                                          │
│  print(config.androidNamespace);  // "com.myapp.debug"         │
│  print(config.versionCode);       // 5                          │
│  print(config.androidMapsApiKey); // "DEBUG_KEY"                │
│                                                                 │
│  // Use in Google Maps widget                                   │
│  GoogleMap(                                                     │
│    apiKey: config.androidMapsApiKey,                            │
│  )                                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗂️ File Responsibilities

| File | Purpose | Edit Manually? | Contains |
|------|---------|----------------|----------|
| **tool/configure_build.dart** | CLI tool to set configuration | ✅ Yes (if customizing tool) | Command parsing, file generation logic |
| **lib/config/build_settings.dart** | Stores all configuration values | ❌ Never (auto-generated) | `DebugBuildSettings`, `BetaBuildSettings`, `ProductionBuildSettings` classes with static const values |
| **lib/config/build_config.dart** | Reads and provides configuration | ❌ Never (system file) | `BuildConfig` class that reads from build_settings.dart |
| **lib/config/environment.dart** | API environment URLs | ✅ Manual or via tool | `EnvironmentConfig`, `AppEnvironment` enum |
| **lib/main.dart** | App entry point | ✅ Yes | Sets `EnvironmentConfig.current` |

---

## 🔄 Configuration Lifecycle

### Step 1: Initial State

```dart
// build_settings.dart (generated with defaults)
class DebugBuildSettings {
  static const String androidNamespace = 'com.example.form_fields_example.debug';
  static const int versionCode = 1;
  static const String versionName = '1.0.0';
  // ...
}
```

### Step 2: User Changes Configuration

```bash
$ dart run tool/configure_build.dart \
    --env=debug \
    --namespace=com.mycompany.myapp \
    --version-code=10 \
    --version-name=2.5.0 \
    --maps-key=AIzaSyMY_ACTUAL_KEY
```

### Step 3: Settings File Updated

```dart
// build_settings.dart (regenerated with new values)
class DebugBuildSettings {
  static const String androidNamespace = 'com.mycompany.myapp.debug';
  static const int versionCode = 10;
  static const String versionName = '2.5.0';
  static const String androidMapsApiKey = 'AIzaSyMY_ACTUAL_KEY';
  // ...
}
```

### Step 4: Build Config Uses New Values

```dart
// build_config.dart (unchanged, automatically uses new values)
factory BuildConfig.debug() {
  return BuildConfig(
    androidNamespace: DebugBuildSettings.androidNamespace,  // 'com.mycompany.myapp.debug'
    versionCode: DebugBuildSettings.versionCode,            // 10
    versionName: DebugBuildSettings.versionName,            // '2.5.0'
    androidMapsApiKey: DebugBuildSettings.androidMapsApiKey, // 'AIzaSyMY_ACTUAL_KEY'
    // ...
  );
}
```

### Step 5: App Uses Configuration

```dart
// Anywhere in your app
void initializeMap() {
  final apiKey = BuildConfig.current.androidMapsApiKey; // 'AIzaSyMY_ACTUAL_KEY'
  
  // Use in Google Maps
  GoogleMap(
    initialCameraPosition: CameraPosition(...),
    apiKey: apiKey,
  );
}

void showAppInfo() {
  final config = BuildConfig.current;
  print('Version: ${config.versionName} (${config.versionCode})');
  // Output: Version: 2.5.0 (10)
}
```

---

## 🎨 Environment-Specific Values

Each environment has its own set of values:

### Debug Environment

```dart
class DebugBuildSettings {
  static const String androidNamespace = 'com.myapp.debug';      // .debug suffix
  static const String androidMapsApiKey = 'DEBUG_KEY';           // Debug key
  static const String webDomain = 'localhost:8080';              // Local dev
}
```

### Beta Environment

```dart
class BetaBuildSettings {
  static const String androidNamespace = 'com.myapp.beta';       // .beta suffix
  static const String androidMapsApiKey = 'BETA_KEY';            // Beta key
  static const String webDomain = 'beta.example.com';            // Beta domain
}
```

### Production Environment

```dart
class ProductionBuildSettings {
  static const String androidNamespace = 'com.myapp';            // No suffix
  static const String androidMapsApiKey = 'PROD_KEY';            // Production key
  static const String webDomain = 'example.com';                 // Production domain
}
```

---

## 📝 Example: Full Configuration Change

### Scenario: Preparing for production release

```bash
# 1. Set production configuration
dart run tool/configure_build.dart \
  --env=production \
  --namespace=com.mycompany.awesomeapp \
  --version-code=42 \
  --version-name=3.2.1 \
  --maps-key=AIzaSyProd_Real_Key_Here \
  --camera=true \
  --gallery=true \
  --notification=true
```

### What happens:

#### ✅ build_settings.dart is generated:

```dart
class ProductionBuildSettings {
  static const String androidNamespace = 'com.mycompany.awesomeapp';
  static const int versionCode = 42;
  static const String versionName = '3.2.1';
  static const String androidMapsApiKey = 'AIzaSyProd_Real_Key_Here';
  static const List<String> androidPermissions = [
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.READ_MEDIA_IMAGES',
    'android.permission.POST_NOTIFICATIONS',
    // ...
  ];
}
```

#### ✅ main.dart is updated:

```dart
void main() {
  EnvironmentConfig.current = AppEnvironment.production;  // Changed to production
  runApp(const MyApp());
}
```

#### ✅ Android build.gradle.kts is updated:

```kotlin
android {
    namespace = "com.mycompany.awesomeapp"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.mycompany.awesomeapp"
        minSdk = 21
        targetSdk = 34
        versionCode = 42
        versionName = "3.2.1"
        manifestPlaceholders["MAPS_API_KEY"] = "AIzaSyProd_Real_Key_Here"
    }
}
```

#### ✅ AndroidManifest.xml is updated:

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="${MAPS_API_KEY}" />
    </application>
</manifest>
```

### Result:

- All files updated in one command ✅
- Production environment active ✅
- Version 3.2.1 (build 42) ✅
- Real API key configured ✅
- Permissions enabled ✅

---

## 🔍 Reading Configuration in Code

### Access Config Anywhere

```dart
import 'package:form_fields_example/config/build_config.dart';

// Get current config (automatically uses correct environment)
final config = BuildConfig.current;

// Access any setting
final namespace = config.androidNamespace;
final versionCode = config.versionCode;
final versionName = config.versionName;
final mapsKey = config.androidMapsApiKey;
final permissions = config.androidPermissions;

// Check if permission is enabled
final hasCamera = config.hasAndroidPermission('android.permission.CAMERA');

// Check if production ready (has real API keys)
if (config.isProductionReady) {
  print('✅ Ready for production');
} else {
  print('⚠️ Using placeholder API keys');
}
```

### Use in Widgets

```dart
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = BuildConfig.current;
    
    return GoogleMap(
      apiKey: config.androidMapsApiKey,
      // ...
    );
  }
}
```

### Use in About Dialog

```dart
void showAbout(BuildContext context) {
  final config = BuildConfig.current;
  
  showAboutDialog(
    context: context,
    applicationName: 'My App',
    applicationVersion: '${config.versionName} (${config.versionCode})',
    applicationLegalese: 'Package: ${config.androidNamespace}',
  );
}
```

---

## 🎓 Key Concepts

### 1. Single Source of Truth

**`build_settings.dart`** is the single source of truth for all configuration values.

### 2. Environment-Specific

Each environment (debug, beta, production) has its own class with its own values.

### 3. Immutable Constants

All values are `static const`, making them compile-time constants (fast and efficient).

### 4. Type-Safe

All values are strongly typed (String, int, List<String>, etc.).

### 5. Auto-Generated

Never manually edit `build_settings.dart` - always use the CLI tool.

---

## 🛠️ Troubleshooting

### "Where do I change the namespace?"

```bash
dart run tool/configure_build.dart --env=production --namespace=com.mynew.app
```

Values are stored in `lib/config/build_settings.dart`

### "Where do I change the version?"

```bash
dart run tool/configure_build.dart --env=production --version-code=15 --version-name=2.3.0
```

Values are stored in `lib/config/build_settings.dart`

### "Where do I set my API key?"

```bash
dart run tool/configure_build.dart --env=production --maps-key=YOUR_REAL_KEY
```

Values are stored in `lib/config/build_settings.dart`

### "How do I see current values?"

```bash
# View the generated settings file
cat lib/config/build_settings.dart

# Or run app and check console output
flutter run
# Look for: ✅ BuildConfig (production): ...
```

---

## 📚 Related Documentation

- **[HOW_TO_USE.md](HOW_TO_USE.md)** - Complete usage guide
- **[BUILD_CONFIG_IMPLEMENTATION.md](BUILD_CONFIG_IMPLEMENTATION.md)** - Technical details
- **[API_KEYS_SECURITY.md](API_KEYS_SECURITY.md)** - Security best practices

---

**Last Updated**: March 2026  
**Version**: 1.0.0
