# Quick Reference - Professional Architecture

## 📁 Directory Structure Overview

```
lib/
├── main.dart                           # App entry point
├── config/                             # App configuration
│   ├── app_router.dart                 # GoRouter setup
│   └── app_routes.dart                 # Route definitions
├── data/                               # Business logic & API
│   ├── models/                         # Data models
│   │   └── user.dart                   # User + auth methods
│   └── services/                       # External APIs
│       └── http_service.dart           # HTTP client (singleton)
├── state/                              # Global state
│   └── notifiers/                      # Provider notifiers
│       └── app_state_notifier.dart     # App-wide state
└── ui/                                 # User interface
    ├── pages/                          # Full-screen pages
    │   ├── login_page.dart
    │   ├── menu_page.dart
    │   ├── profile_page.dart
    │   └── ... (15 total)
    └── widgets/                        # Reusable components
        ├── blocking_dialogs.dart
        └── ... (4 total)
```

---

## 🎯 Where to Add New Code?

| Need | Location | Example |
|------|----------|---------|
| **New Page** | `lib/ui/pages/` | `my_feature_page.dart` |
| **New Widget** | `lib/ui/widgets/` | `my_widget.dart` |
| **New Model** | `lib/data/models/` | `product.dart` |
| **New API Call** | Add method to existing service in `lib/data/services/` | Add `getProducts()` to `http_service.dart` |
| **New Route** | Add enum to `lib/config/app_routes.dart` + GoRoute in `app_router.dart` | ✅ Auto-complete available |
| **Global State** | Add property/method to `lib/state/notifiers/app_state_notifier.dart` | `isNetworkConnected` |

---

## 📝 Import Reference by Layer

### 📄 UI Pages (`lib/ui/pages/my_page.dart`)
```dart
// Always available:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Your imports:
import '../../data/models/user.dart';              // Models
import '../../data/services/http_service.dart';   // HTTP Client
import '../../state/notifiers/app_state_notifier.dart';  // State
import '../../config/app_routes.dart';            // Routes
import '../widgets/blocking_dialogs.dart';        // Widgets
import './menu_page.dart';                        // Other pages
```

### 🎨 UI Widgets (`lib/ui/widgets/my_widget.dart`)
```dart
import 'package:flutter/material.dart';

import '../../data/models/user.dart';         // Models if needed
import '../../config/app_routes.dart';       // Routes if needed
import './other_widget.dart';                // Other widgets
import '../pages/profile_page.dart';         // Pages if needed
```

### 📊 Data Models (`lib/data/models/user.dart`)
```dart
import 'package:json_annotation/json_annotation.dart';
import '../services/http_service.dart';      // Services only
```

### 🔧 Data Services (`lib/data/services/http_service.dart`)
```dart
// Services are independent, minimal imports
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
```

### 🎛️ State Notifiers (`lib/state/notifiers/app_state_notifier.dart`)
```dart
import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../data/services/http_service.dart';
```

---

## ✨ Common Tasks

### **Add a New Page**
```bash
# 1. Create file
touch lib/ui/pages/new_feature_page.dart

# 2. Add route to app_routes.dart
newFeature = AppRoute('new-feature', '/new-feature')

# 3. Add GoRoute to app_router.dart
GoRoute(
  path: AppRoute.newFeature.path,
  name: AppRoute.newFeature.name,
  builder: (context, state) => const NewFeaturePage(),
)

# 4. Use in app
context.goToRoute(AppRoute.newFeature)
```

### **Call an API Endpoint**
```dart
// In a page or notifier:
try {
  final response = await HttpService.instance.get<Map<String, dynamic>>(
    '/api/endpoint',
  );
  // Use response
} catch (e) {
  print('Error: $e');
}
```

### **Access Global State**
```dart
// In a page:
final appState = context.watch<AppStateNotifier>();
print(appState.currentUser?.displayName);

// From non-widget code:
final appState = AppStateNotifier(); // Use provider instead!
```

### **Add a New Route**
```dart
// 1. Add to app_routes.dart
enum AppRoute {
  myRoute = const AppRoute('my-route', '/my-route'),
  // ...
}

// 2. Add to app_router.dart
GoRoute(
  path: AppRoute.myRoute.path,
  name: AppRoute.myRoute.name,
  builder: (context, state) => const MyRoutePage(),
)

// 3. Navigate to it:
context.go(AppRoute.myRoute.path);
// or
context.goToRoute(AppRoute.myRoute);
// or
context.pushRoute(AppRoute.myRoute);
```

---

## 🔐 Authentication Flow

```
1. User enters credentials → LoginPage
2. LoginPage calls User.login()
3. User.login() uses HttpService.post() → /auth/login
4. AppStateNotifier stores token + user
5. GoRouter redirects to menu on login
6. All requests include Bearer token
7. On logout, token is cleared
```

### **Token Lifecycle**
- ✅ Stored in SharedPreferences (persistent)
- ✅ Set in HttpService headers on init
- ✅ Updated on every API call response
- ✅ Cleared on logout
- ✅ Auto-attached to all requests

---

## 🧪 Testing Guide

### **Unit Testing**
```dart
test('User model parses JSON correctly', () {
  const json = {'id': 1, 'username': 'test'};
  final user = User.fromJson(json);
  expect(user.id, 1);
});
```

### **Widget Testing**
```dart
testWidgets('LoginPage shows error on bad credentials', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byType(ElevatedButton));
  expect(find.text('Invalid username'), findsOneWidget);
});
```

### **Integration Testing**
- Use real HttpService (or mock Dio)
- Test full flows (login → menu → profile)
- Use test credentials (emilys/emilyspass)

---

## 🚀 Performance Tips

| Issue | Solution |
|-------|----------|
| **Slow builds** | Run `flutter pub get` then `flutter clean` |
| **App crashes** | Check `flutter analyze` output |
| **HTTP timeouts** | Increase durations in HttpService._createDio() |
| **State updates everywhere** | Use Consumer/context.watch() sparingly |
| **Large pages rebuild** | Break into smaller widgets |

---

## 🐛 Debugging Tips

### **Check logger output:**
```dart
// In main.dart, before runApp():
Logger().i('🚀 App starting');
```

### **View HTTP requests:**
```dart
// HttpService logs all requests automatically
// Check console for GET/POST/PUT with emoji indicators
```

### **Debug state changes:**
```dart
// In AppStateNotifier, after notifyListeners():
Logger().d('State updated: $currentUser');
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **STRUCTURE.md** | Architecture principles & patterns |
| **MIGRATION.md** | How files were organized |
| **MIGRATION_COMPLETE.md** | Detailed migration report |
| **ARCHITECTURE_REPORT.md** | Full architecture overview |
| **lib/data/services/README.md** | HttpService documentation |

---

## ⚡ Quick Commands

```bash
# Clean & prepare
flutter clean
flutter pub get

# Check for issues
flutter analyze

# Run app
flutter run

# Build release
flutter build apk     # Android
flutter build ios    # iOS

# Generate JSON serialization
flutter pub run build_runner build
```

---

## ❓ Troubleshooting

**Q: Import errors after adding new file?**  
A: The file exists but imports are wrong. Check path relative to new location.

**Q: State not updating?**  
A: Add `context.read<AppStateNotifier>()` in callbacks, not just `context.watch()`.

**Q: HTTP requests failing?**  
A: Check HttpService logger output (🌐 GET Request:). Network issue or wrong endpoint?

**Q: Page not appearing?**  
A: Verify route exists in app_routes.dart AND app_router.dart GoRoute list.

---

## 📞 Common Classes

| Class | Purpose | Located In |
|-------|---------|-----------|
| `User` | User data + static auth methods | `lib/data/models/user.dart` |
| `HttpService` | Global HTTP client | `lib/data/services/http_service.dart` |
| `AppStateNotifier` | Global app state | `lib/state/notifiers/app_state_notifier.dart` |
| `AppRoute` | Route enum + extensions | `lib/config/app_routes.dart` |
| `LoginPage` | Authentication UI | `lib/ui/pages/login_page.dart` |
| `MenuPage` | Main navigation | `lib/ui/pages/menu_page.dart` |

---

**Last Updated:** Feb 27, 2025  
**Architecture Version:** Professional Clean Architecture v1.0  
**Status:** ✅ Production Ready
