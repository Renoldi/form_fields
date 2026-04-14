# 📱 FormFields Example Application

A comprehensive example application demonstrating all features and best practices for the [FormFields Package](https://pub.dev/packages/form_fields).

## 🎯 What's Inside

This example showcases:

### ✨ Field Types

- **Text Fields**: Email, phone, and general text input with validation
- **Password Fields**: Secure input with visibility toggle
- **Numeric Fields**: Integer and decimal with thousand separators
- **Multiline Text**: Bio and notes with customizable lines
- **Custom Fields**: Dropdown, checkbox, radio buttons, and more

### 📅 Date & Time Components

- **Date Picker**: Birth date selection
- **Time Picker (DateTime)**: Full datetime with time selection
- **Time Picker (TimeOfDay)**: Hour and minute only selection
- **DateTime Picker**: Combined date and time picker
- **DateRange Picker**: Start and end date selection

### 🎨 Customization Features

- Multiple label positions (top, bottom, left, right, inline, none)
- Border styles (outline, underline, none)
- Custom locale support for date/time pickers
- Comprehensive validation (required, email, phone, custom)
- Nullable and non-nullable field variants
- Reusable button family (`AppButton`, grouped/split/segmented/fab variants)
- Reusable feedback flows (`AppDialogService`, `AppGlobalDialogService`, loading and progress indicators)

### 🏗️ Architecture Demonstrations

- **State Management**: Provider pattern with ChangeNotifier
- **Build Configuration**: Multi-environment setup (Debug, Beta, Production)
- **Localization**: Multi-language support (EN/ID)
- **Responsive UI**: Adaptive layouts for all screen sizes

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher

### Installation

```bash
# Clone or download the package
cd form_fields_package/example

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## ⚙️ Build Configuration

This example includes a professional build configuration system:

```bash
# Configure for debug environment
dart run tool/configure_build.dart --env=debug

# Configure for production
dart run tool/configure_build.dart --env=production --platform=android,ios

# For complete configuration options
dart run tool/configure_build.dart --help
```

**Documentation:**

- [HOW_TO_USE.md](HOW_TO_USE.md) - Complete build configuration guide
- [tool/README.md](tool/README.md) - Configuration tool documentation

## 📚 Additional Documentation

Detailed documentation is available in the [`docs/`](docs/) folder:

- **[BUILD_CONFIG.md](docs/BUILD_CONFIG.md)** - Build configuration system overview
- **[CONFIGURATION_FLOW.md](docs/CONFIGURATION_FLOW.md)** - Configuration data flow
- **[ENVIRONMENT_CONFIG.md](docs/ENVIRONMENT_CONFIG.md)** - Environment setup guide
- **[MULTILANG_IMPLEMENTATION.md](docs/MULTILANG_IMPLEMENTATION.md)** - Internationalization guide

## 🎓 Key Features to Try

1. **Form Validation**: Test required fields, email, and phone validation
2. **Time Picker Variants**: Compare DateTime vs TimeOfDay pickers
3. **Live Conversions**: Watch TimeOfDay ↔ DateTime conversions
4. **Custom Styling**: Experiment with different label positions and borders
5. **Localization**: Switch between English and Indonesian
6. **Button Components**: Explore button variants in App Button examples
7. **Dialog Guard Flows**: Compare blocking vs non-blocking loading behavior
8. **Loading/Progress Visuals**: Switch indicator/progress modes and styles
9. **Responsive Design**: Test on different screen sizes

## 📦 Project Structure

```
example/
├── lib/
│   ├── config/          # Build and environment configuration
│   ├── data/            # Models and services
│   ├── localization/    # Multi-language support
│   ├── state/           # State management
│   ├── ui/              # Pages and widgets
│   └── main.dart        # App entry point
├── tool/                # Build configuration tools
├── docs/                # Detailed documentation
├── android/             # Android platform files
├── pubspec.yaml         # Dependencies
└── README.md            # This file
```

## 🛠️ Build System Features

### Multi-Environment Support

- **Debug**: Development with detailed logging
- **Beta**: Testing environment
- **Production**: Release-ready configuration

### Cross-Platform Building

- Android (APK/AAB)
- iOS (IPA)
- macOS (App)
- Web
- Windows
- Linux

### Automatic Error Fixing

- Gradle issues (Android)
- CocoaPods issues (iOS/macOS)
- CMake issues (Linux)
- Dependency resolution
- Cache cleaning

## 📱 Platform-Specific Configuration

### Android

- Namespace management per environment
- SDK version control
- Permission handling
- ProGuard/R8 rules

### iOS/macOS

- Info.plist configuration
- Podfile permission_handler setup
- Usage description management
- Entitlements

## 🔧 Development Tips

1. **Environment Variables**: Use `BuildConfig.current` to access configuration
2. **Permissions**: Configure dynamically via command-line flags
3. **API Keys**: Set per-environment Google Maps keys
4. **Versioning**: Manage version codes and names via tool

## 📄 License

This example application is part of the FormFields package and follows the same license.
