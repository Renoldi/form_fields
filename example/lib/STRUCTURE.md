# App Structure Documentation

## Professional Architecture Overview

```
lib/
├── main.dart                    # App entry point
│
├── config/                      # App configuration
│   ├── app_router.dart         # Go Router setup
│   ├── app_routes.dart         # Route definitions
│   └── theme.dart              # Theme constants
│
├── constants/                   # App constants
│   └── app_constants.dart      # Global constants
│
├── data/                        # Data layer
│   ├── models/                 # Data models
│   │   ├── user.dart
│   │   └── user.g.dart
│   └── services/               # API services
│       └── http_service.dart
│
├── state/                       # State management
│   └── notifiers/              # Change notifiers
│       └── app_state_notifier.dart
│
└── ui/                          # UI layer
    ├── pages/                   # Full-page screens
    │   ├── login_page.dart
    │   ├── menu_page.dart
    │   ├── profile_page.dart
    │   ├── settings_page.dart
    │   └── ... other pages
    │
    └── widgets/                 # Reusable widgets
        ├── blocking_dialogs.dart
        ├── language_indicator.dart
        ├── result_display_widget.dart
        └── scaffold_with_drawer.dart
```

## Folder Structure Explanation

### `config/`
- **Purpose**: Application configuration and routing
- **Files**:
  - `app_router.dart`: GoRouter setup with authentication guards
  - `app_routes.dart`: Route enum definitions and extensions
  - `theme.dart`: Theme constants and Material theme setup

### `constants/`
- **Purpose**: Global application constants
- **Files**:
  - `app_constants.dart`: API URLs, timeouts, default values

### `data/`
- **Purpose**: Data access layer
- **Subfolders**:
  - `models/`: Data model classes (@JsonSerializable)
  - `services/`: HTTP client and API services

### `state/`
- **Purpose**: State management
- **Subfolders**:
  - `notifiers/`: ChangeNotifier classes for state

### `ui/`
- **Purpose**: User interface layer
- **Subfolders**:
  - `pages/`: Full-screen page widgets
  - `widgets/`: Reusable component widgets

## Import Convention

Always import from the organized structure:

```dart
// ✅ Correct
import 'package:app/config/app_routes.dart';
import 'package:app/data/models/user.dart';
import 'package:app/state/notifiers/app_state_notifier.dart';
import 'package:app/ui/pages/profile_page.dart';

// ❌ Avoid
import 'package:app/models/user.dart';
import 'package:app/services/http_service.dart';
```

## Maintenance Guidelines

1. **Add new page**: Place in `lib/ui/pages/`
2. **Add new reusable widget**: Place in `lib/ui/widgets/`
3. **Add new model**: Place in `lib/data/models/`
4. **Add new service**: Place in `lib/data/services/`
5. **Add new constant**: Add to `lib/constants/app_constants.dart`
6. **Update routing**: Edit `lib/config/app_routes.dart` and `lib/config/app_router.dart`

## File Naming Convention

- **Files**: `snake_case.dart` (lowercase with underscores)
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`

Example:
```dart
// File: profile_page.dart
class ProfilePage extends StatefulWidget {
  final String userName;
  
  Future<void> handleProfileUpdate() { }
}
```

## Benefits of This Structure

✅ **Easy Navigation**: Files organized by responsibility  
✅ **Scalability**: Clear where to add new features  
✅ **Maintainability**: Changes isolated to specific layers  
✅ **Testability**: Separation of concerns makes testing easier  
✅ **Professional**: Follows Flutter best practices  
✅ **Growth-Ready**: Can handle 1000+ lines of code
