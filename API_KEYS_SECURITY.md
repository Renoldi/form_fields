# API Key & Security Management Guide

Secure configuration and management of API keys across all platforms (Android, iOS, macOS, Windows, Linux, Web).

## Security Principles

### ⚠️ Critical Rules

1. **NEVER commit API keys to the repository**
2. **NEVER hardcode API keys in production builds**
3. **NEVER share API keys via email or chat**
4. **ALWAYS rotate compromised API keys immediately**
5. **ALWAYS restrict API keys by domain/package/IP**

### GitIgnore Configuration

```bash
# .gitignore
# ============================================================================
# API KEYS & SECRETS (SECURITY)
# ============================================================================

# Dart/Flutter
lib/config/api_keys.dart
lib/config/secrets.dart

# Android
android/app/google-services.json
android/local.properties
android/key.properties

# iOS
ios/Runner/GoogleService-Info.plist
ios/local.properties
ios/Podfile.lock

# macOS
macos/local.properties
macos/Podfile.lock

# Web
web/index.html.backup
web/.env*
web/.env.*.local

# General
.env
.env.local
.env.*.local
.env.production
secrets.json
api_keys.json
config/private/
config/secrets/

# CI/CD
.github/workflows/secrets.yml
.gitlab-ci.secrets.yml
jenkins/secrets/
```

## Environment-Specific Setup

### 1. Development Environment (Local Machine)

#### Create local configuration file
```dart
// lib/config/api_keys.dart (GITIGNORED)
class ApiKeys {
  static const String mapsApiKeyDebug = 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const String mapsApiKeyBeta = 'AIzaSyDyyyyyyyyyyyyyyyyyyyyyyyyy';
  static const String mapsApiKeyProduction = 'AIzaSyDzzzzzzzzzzzzzzzzzzzzzzzzzz';
  
  static const String firebaseProjectId = 'my-project-debug';
  static const String firebaseApiKey = 'AIzaSyD...';
  
  static const String paymentApiKey = 'pk_test_xxxxx';
  static const String weatherApiKey = 'openweather_test_key';
}
```

#### Use in BuildConfig
```dart
// lib/config/build_config.dart
static String get mapsApiKey {
  switch (EnvironmentConfig.current) {
    case AppEnvironment.debug:
      return ApiKeys.mapsApiKeyDebug;
    case AppEnvironment.beta:
      return ApiKeys.mapsApiKeyBeta;
    case AppEnvironment.production:
      return ApiKeys.mapsApiKeyProduction;
  }
}
```

### 2. Testing Environment (CI/CD)

#### GitHub Actions Setup
```yaml
# .github/workflows/build.yml
name: Build & Test

on: [push, pull_request]

env:
  MAPS_API_KEY_DEBUG: ${{ secrets.MAPS_API_KEY_DEBUG }}
  MAPS_API_KEY_BETA: ${{ secrets.MAPS_API_KEY_BETA }}
  MAPS_API_KEY_PRODUCTION: ${{ secrets.MAPS_API_KEY_PRODUCTION }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.0'
      
      - name: Create API keys file
        run: |
          cat > lib/config/api_keys.dart << EOF
          class ApiKeys {
            static const String mapsApiKeyDebug = '${{ secrets.MAPS_API_KEY_DEBUG }}';
            static const String mapsApiKeyBeta = '${{ secrets.MAPS_API_KEY_BETA }}';
            static const String mapsApiKeyProduction = '${{ secrets.MAPS_API_KEY_PRODUCTION }}';
          }
          EOF
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk --release
```

#### GitLab CI Setup
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

before_script:
  - echo "Setting up API keys..."
  - |
    cat > lib/config/api_keys.dart << EOF
    class ApiKeys {
      static const String mapsApiKeyDebug = '$MAPS_API_KEY_DEBUG';
      static const String mapsApiKeyBeta = '$MAPS_API_KEY_BETA';
      static const String mapsApiKeyProduction = '$MAPS_API_KEY_PRODUCTION';
    }
    EOF

build:
  stage: build
  script:
    - flutter pub get
    - flutter build apk --release
  only:
    - main
```

### 3. Production Environment (App Stores)

#### Option 1: Gradle Secrets Plugin

```gradle
// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin") version "2.0.1"
}

secrets {
    propertiesFileName = "local.properties"
    defaultPropertiesFileName = "local.defaults.properties"
    ignoreList.add("keyToIgnore") // Ignore specific keys
    ignoreList.add("sdk.*")       // Ignore keys matching regex
}
```

#### Configure local.properties
```properties
# android/local.properties (GITIGNORED)
MAPS_API_KEY=AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### Reference in AndroidManifest.xml
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />
```

#### Option 2: BuildConfig Fields

```gradle
// android/app/build.gradle.kts
android {
    buildTypes {
        debug {
            buildConfigField("String", "MAPS_API_KEY", "\"DEBUG_KEY\"")
            buildConfigField("String", "FIREBASE_PROJECT_ID", "\"debug-project\"")
        }
        
        release {
            buildConfigField("String", "MAPS_API_KEY", "\"PROD_KEY\"")
            buildConfigField("String", "FIREBASE_PROJECT_ID", "\"prod-project\"")
        }
    }
}
```

#### Access in Dart
```dart
import 'package:flutter/services.dart';

class ConfigLoader {
  static Future<String> getMapsApiKey() async {
    try {
      const platform = MethodChannel('com.example.app/config');
      final String result = await platform.invokeMethod('getMapsApiKey');
      return result;
    } catch (e) {
      return 'DEFAULT_KEY';
    }
  }
}
```

## Platform-Specific Setup

### Android

#### 1. Google Maps API Key

**Get SHA-1 Fingerprint:**
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android

# Output: SHA1: AA:BB:CC:DD:...

# Release keystore
keytool -list -v -keystore ~/my-release-key.jks \
  -alias my-key-alias \
  -storepass my-password \
  -keypass my-password
```

**Create API Key:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project or select existing
3. Enable "Maps SDK for Android"
4. Go to Credentials → Create API Key
5. Restrict key:
   - Application restrictions → Android apps
   - Add package name: `com.example.form_fields_example.debug`
   - Add SHA-1: `AA:BB:CC:DD:...`
6. Copy key to `local.properties`

#### 2. Firebase Configuration

**Download google-services.json:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Project settings → Your apps → Android
4. Download `google-services.json`
5. Place in `android/app/google-services.json`
6. Add to `.gitignore`

### iOS

#### 1. Google Maps API Key

**Create API Key:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Go to Credentials → Create API Key
3. Restrict key:
   - Application restrictions → iOS apps
   - Add bundle ID: `com.example.formFieldsExample`
   - Add associated domain (optional)
4. Copy key

**Add to Podfile:**
```ruby
# ios/Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'GOOGLE_MAPS_API_KEY=AIzaSyD...'
      ]
    end
  end
end
```

#### 2. Firebase Configuration

**Download GoogleService-Info.plist:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Project settings → Your apps → iOS
3. Download `GoogleService-Info.plist`
4. Add to Xcode under Runner
5. Add to `.gitignore`

### Web

#### 1. Environment Variables

```html
<!-- web/index.html -->
<html>
  <head>
    <script>
      // Load API keys from environment
      const MAPS_API_KEY = '{{ MAPS_API_KEY }}';
      const FIREBASE_CONFIG = {{ FIREBASE_CONFIG }};
    </script>
    <script src="https://maps.googleapis.com/maps/api/js?key=${MAPS_API_KEY}&libraries=places"></script>
  </head>
  <body>
    <div id="app"></div>
    <script src="main.dart.js"></script>
  </body>
</html>
```

#### 2. Build-time substitution

```bash
#!/bin/bash
# build_web.sh

export MAPS_API_KEY="YOUR_PRODUCTION_KEY"
export FIREBASE_CONFIG='{"apiKey":"...","projectId":"..."}'

flutter build web \
  --web-renderer canvaskit \
  --csproto unsafe
```

## API Key Rotation

### When to Rotate

- ✓ After security breach or unauthorized access
- ✓ Employee leaves company
- ✓ Quarterly security audit
- ✓ Key leaked in commit history
- ✓ Unusual activity detected

### Rotation Process

1. **Create new key** in Google Cloud Console
2. **Add new key** to all environment configurations
3. **Test thoroughly** on all platforms
4. **Deploy to production** with new key
5. **Monitor** for 1-2 weeks
6. **Delete old key** once fully migrated
7. **Document** rotation in changelog

```bash
# Audit old key usage
gcloud logging read "resource.type=api" \
  --filter="protoPayload.request.apiKey='OLD_KEY'" \
  --limit 1000 \
  --format json

# After cutover period
gcloud services api-keys delete OLD_KEY_ID
```

## Best Practices

### 1. Principle of Least Privilege
```dart
// ✅ Good: Restrict each key to what it needs
// Maps API key - only Google Maps API
// Firebase key - only Firebase services
// Payment key - only payment processing

// ❌ Bad: Use single admin key for everything
```

### 2. Key Isolation by Environment
```dart
// ✅ Good: Separate keys for dev/beta/prod
static String get mapsApiKey {
  switch (EnvironmentConfig.current) {
    case AppEnvironment.production:
      return 'PROD_KEY_XYZ'; // High quota, monitored
    case AppEnvironment.beta:
      return 'BETA_KEY_ABC'; // Test quota
    case AppEnvironment.debug:
      return 'DEBUG_KEY_DEF'; // Local development
  }
}

// ❌ Bad: Same key for all environments
static const String mapsApiKey = 'SHARED_KEY';
```

### 3. Monitoring and Alerts
```yaml
# Set up alerts in Google Cloud Console
# Alert when:
# - API quota exceeded 80%
# - Unusual number of requests
# - Requests from unexpected IP
# - Multiple invalid requests (potential attack)
```

### 4. Secure Storage

```dart
// ✅ Good: Use platform channels for secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureConfig {
  static const platform = MethodChannel('com.example.app/secure');
  static final _storage = const FlutterSecureStorage();
  
  static Future<String> getApiKey(String name) async {
    return await _storage.read(key: name) ?? '';
  }
  
  static Future<void> setApiKey(String name, String value) async {
    await _storage.write(key: name, value: value);
  }
}

// ❌ Bad: Store in SharedPreferences
SharedPreferences.getInstance().then((prefs) {
  prefs.setString('API_KEY', 'EXPOSED'); // Unsecured!
});
```

### 5. Access Control

```gradle
// android/app/build.gradle.kts
// Only include API key in release builds
android {
    buildTypes {
        debug {
            buildConfigField("String", "MAPS_API_KEY", "\"DEBUG_KEY\"")
        }
        release {
            buildConfigField("String", "MAPS_API_KEY", "\"PROD_KEY\"")
        }
    }
}
```

## Troubleshooting

### Issue: "Maps API key not found"

**Diagnosis:**
1. Check if API key is in AndroidManifest.xml
2. Verify SHA-1 fingerprint matches
3. Confirm API key is enabled in Google Cloud

**Solution:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY" />
</application>
```

### Issue: "Quota exceeded"

**Diagnosis:**
1. Check API usage in Google Cloud Console
2. Verify key restrictions are correct
3. Look for accidental infinite loops

**Solution:**
1. Upgrade quota in Google Cloud Console
2. Implement caching to reduce requests
3. Add request batching/throttling

### Issue: "API key leaked in commit"

**Immediate Actions:**
```bash
# 1. Revoke the key immediately in Google Cloud Console
# 2. Rotate to new key
# 3. Remove from git history
cd your-repo
git-filter-repo --invert-paths --path 'lib/config/api_keys.dart'

# 4. Force push (only if private repo)
git push --force-with-lease origin main

# 5. Notify team and audit usage
```

## Compliance Checklist

- ✅ API keys stored in .gitignore
- ✅ No hardcoded keys in source files
- ✅ Environment-specific keys configured
- ✅ CI/CD uses secrets management
- ✅ API key restrictions enabled (domain/package/IP)
- ✅ Usage monitoring enabled
- ✅ Rotation policy documented
- ✅ Team trained on security practices
- ✅ Regular security audits scheduled
- ✅ Incident response plan in place

## Related Documentation

- [BUILD_CONFIG.md](BUILD_CONFIG.md) - Build configuration system
- [ENVIRONMENT_CONFIG.md](example/ENVIRONMENT_CONFIG.md) - Environment management
- [Google Cloud Security Best Practices](https://cloud.google.com/security/best-practices)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
