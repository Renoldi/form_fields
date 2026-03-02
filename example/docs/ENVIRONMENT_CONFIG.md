# Environment Configuration Guide

## Overview

The environment configuration system manages API endpoints and settings for different deployment environments: **Production**, **Beta**, and **Debug**.

This approach ensures:
- ✅ Easy switching between environments
- ✅ Centralized configuration management
- ✅ Environment-specific timeouts and headers
- ✅ Professional API logging
- ✅ No hardcoded URLs scattered throughout the codebase

## Quick Start

### Switch Environment

```dart
import 'package:form_fields_example/config/environment.dart';

// Set environment at app startup (in main.dart)
void main() {
  // Change to different environment
  EnvironmentConfig.current = AppEnvironment.debug; // or beta, production
  
  runApp(const MyApp());
}
```

### Access Configuration

```dart
// Get current environment settings
final baseUrl = EnvironmentConfig.currentBaseUrl;
final apiEndpoint = EnvironmentConfig.currentApiEndpoint;
final isDebug = EnvironmentConfig.isDebug;

// Check environment type
if (EnvironmentConfig.isProduction) {
  // Production-only code
}
```

## Environment Settings

### 1. Production (`🚀 PRODUCTION`)

**Purpose:** Stable, production-ready API

```dart
Base URL:        https://api.dummyjson.com
Connect Timeout: 15 seconds
Send Timeout:    15 seconds
Receive Timeout: 20 seconds
Debug Mode:      false
```

**Use Cases:**
- Release builds
- Production deployments
- Customer-facing environments

---

### 2. Beta (`🧪 BETA`)

**Purpose:** Testing new features before production

```dart
Base URL:        https://beta-api.dummyjson.com
Connect Timeout: 12 seconds
Send Timeout:    12 seconds
Receive Timeout: 18 seconds
Debug Mode:      false
```

**Use Cases:**
- Internal testing
- UAT (User Acceptance Testing)
- Pre-release feature testing
- QA environments

---

### 3. Debug (`🐛 DEBUG`)

**Purpose:** Development and debugging

```dart
Base URL:        https://dummyjson.com
Connect Timeout: 8 seconds
Send Timeout:    8 seconds
Receive Timeout: 12 seconds
Debug Mode:      true
```

**Use Cases:**
- Local development
- Debugging API issues
- Testing error handling
- Development builds

## File Structure

```
lib/
├── config/
│   ├── environment.dart          # Environment configuration (THIS FILE)
│   ├── app_router.dart
│   └── error_position.dart
├── data/
│   └── services/
│       └── http_service.dart     # Uses EnvironmentConfig
└── main.dart                     # Set environment here
```

## HTTP Service Integration

The `HttpService` automatically uses the current environment configuration:

```dart
// These are set automatically from EnvironmentConfig
- Base URL
- Connection timeouts
- Headers (including environment-specific headers)
- Debug logging
```

**Example log output:**

```
╔═══════════════════════════════════════════════════════════╗
║ 🌍 HttpService Initialization                            ║
╠═══════════════════════════════════════════════════════════╣
║ Environment: 🐛 DEBUG                                    ║
║ Base URL:    https://dummyjson.com                       ║
║ API Path:                                                ║
╚═══════════════════════════════════════════════════════════╝
```

## Adding New Endpoints

To add a new API endpoint:

### 1. Update Environment Settings

```dart
abstract class EnvironmentSettings {
  String get authEndpoint; // Add this
  
  // Override in each environment config:
}

class _ProductionConfig extends EnvironmentSettings {
  @override
  String get authEndpoint => '$baseUrl/auth';
}
```

### 2. Use in Code

```dart
final authUrl = EnvironmentConfig.config.authEndpoint;
final response = await http.get(authUrl);
```

## Best Practices

### Do ✅

- Set environment at app startup in `main.dart`
- Use `EnvironmentConfig` shortcuts (e.g., `currentBaseUrl`)
- Keep environment-specific logic minimal
- Use debug/beta for failing scenarios

### Don't ❌

- Hardcode URLs in business logic
- Mix environment configuration with UI code
- Create environment configs in UI files
- Use production endpoint for local testing

## Common Patterns

### Setting Environment Based on Build Type

```dart
import 'package:flutter/foundation.dart';

void main() {
  // Auto-detect environment
  if (kDebugMode) {
    EnvironmentConfig.current = AppEnvironment.debug;
  } else {
    EnvironmentConfig.current = AppEnvironment.production;
  }
  
  runApp(const MyApp());
}
```

### Environment-Specific Features

```dart
if (EnvironmentConfig.isDebug) {
  // Show debug UI
  debugShowCheckedModeBanner = true;
  // Advanced logging
} else if (EnvironmentConfig.isBeta) {
  // Beta-specific features
  enableBetaFeatures();
}
```

### Custom Environment (Runtime)

```dart
final customHttp = HttpService(
  baseUrl: 'https://custom-api.example.com',
  connectTimeout: const Duration(seconds: 20),
);
```

## Migration Guide

If you have hardcoded URLs:

### Before

```dart
class ApiService {
  final String baseUrl = 'https://api.example.com'; // ❌ Hardcoded
}
```

### After

```dart
class ApiService {
  String get baseUrl => EnvironmentConfig.currentBaseUrl; // ✅ Dynamic
}
```

## Troubleshooting

### Wrong Environment Being Used

1. Check `EnvironmentConfig.current` value
2. Verify setting in `main.dart` before `runApp()`
3. Check HTTP service logs for environment info

### Timeout Issues

1. Increase timeout in corresponding `EnvironmentSettings`
2. Check network conditions
3. Verify API endpoint availability

### Headers Not Sent

1. Verify `customHeaders` in environment config
2. Check `HttpService` initialization
3. See HTTP service logs for actual headers sent

## References

- See [http_service.dart](/example/lib/data/services/http_service.dart) for integration
- See [error_type.dart](/example/lib/config/error_type.dart) for error handling
- See [main.dart](/example/lib/main.dart) for app initialization
