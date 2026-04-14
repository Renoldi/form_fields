# Project Structure

A comprehensive Flutter form fields package with professional MVP architecture and complete localization support.

## Root Directory

```
form_fields_package/
├── lib/                          # Main package source code
│   ├── form_fields.dart         # Package entry point
│   └── src/                      # Implementation
│       ├── buttons/                    # App button family
│       │   ├── app_button.dart
│       │   ├── app_button_content.dart
│       │   ├── app_button_enums.dart
│       │   ├── app_button_group.dart
│       │   ├── app_button_layout.dart
│       │   ├── app_fab_menu.dart
│       │   ├── app_segmented_button.dart
│       │   └── app_split_button.dart
│       ├── fields/                     # Form field domain modules
│       │   ├── core/
│       │   │   └── form_fields.dart          # Base FormFields widget
│       │   ├── autocomplete/
│       │   │   └── form_fields_autocomplete.dart
│       │   └── selection/
│       │       ├── form_fields_checkbox.dart
│       │       ├── form_fields_dropdown.dart
│       │       ├── form_fields_dropdown_multi.dart
│       │       ├── form_fields_radio_button.dart
│       │       └── form_fields_select.dart
│       ├── localization/               # Localization support
│       │   ├── form_fields_localizations.dart
│       │   └── languages/
│       │       ├── en_us.dart
│       │       └── id_id.dart
│       ├── providers/                  # State management
│       │   ├── form_fields_dropdown_notifier.dart
│       │   └── form_fields_notifier.dart
│       ├── feedback/                   # Dialogs, loading, and progress
│       │   ├── app_dialog_service.dart
│       │   ├── app_dialog_service_types.dart
│       │   ├── app_global_dialog_service.dart
│       │   ├── app_loading_indicator.dart
│       │   ├── app_progress_indicator.dart
│       │   └── app_loading_progress_enums.dart
│       └── utilities/                  # Helpers & extensions
│           ├── controller.dart
│           ├── enums.dart
│           ├── extensions.dart
│           ├── phone_country_codes.dart
│           └── validators.dart
├── example/                       # Complete demonstration app
│   ├── lib/
│   │   ├── main.dart             # App entry point (MVP pattern)
│   │   ├── config/               # Configuration
│   │   │   ├── app_router.dart   # GoRouter setup
│   │   │   └── app_routes.dart   # Route definitions
│   │   ├── state/                # Global state
│   │   │   └── app_state_notifier.dart
│   │   ├── localization/         # Multi-language support
│   │   │   ├── localizations.dart
│   │   │   └── languages/
│   │   │       ├── en.dart
│   │   │       └── id.dart
│   │   ├── data/                 # Data layer
│   │   │   ├── models/
│   │   │   │   ├── user.dart
│   │   │   │   └── user.g.dart
│   │   │   └── services/
│   │   │       └── http_service.dart
│   │   └── ui/                   # Presentation layer (MVP)
│   │       ├── pages/            # Full-page screens
│   │       │   ├── login/             (Presenter, View, ViewModel)
│   │       │   ├── menu/              (Presenter, View, ViewModel)
│   │       │   ├── profile/           (Presenter, View, ViewModel)
│   │       │   ├── settings/          (Presenter, View, ViewModel)
│   │       │   ├── language/          (Presenter, View, ViewModel)
│   │       │   ├── app_info/          (Presenter, View, ViewModel)
│   │       │   ├── change_password/   (Presenter, View, ViewModel)
│   │       │   ├── form_fields_examples/
│   │       │   ├── dropdown_examples/
│   │       │   ├── dropdown_multi_examples/
│   │       │   ├── radio_button_examples/
│   │       │   ├── checkbox_examples/
│   │       │   ├── app_button_examples/
│   │       │   ├── loading_progress_examples/
│   │       │   ├── app_dialog_service_examples/
│   │       │   ├── custom_class_examples/
│   │       │   ├── null_non_null_validation_examples/
│   │       │   └── examples_tabs/
│   │       └── widgets/          # Reusable components (MVP)
│   │           ├── language_indicator.dart
│   │           ├── scaffold_with_drawer.dart
│   │           └── result_display_widget.dart
│   ├── test/                     # (Removed - use widget tests)
│   ├── android/                  # Android native code
│   ├── ios/                      # iOS native code
│   └── pubspec.yaml             # Dependencies
├── pubspec.yaml                  # Package configuration
├── pubspec.lock                  # Lock file (auto-generated)
├── analysis_options.yaml         # Lint rules
└── README.md                     # Main documentation
```

## Architecture Patterns

### MVP (Model-View-Presenter)

Every screen and reusable component follows the MVP pattern:

```dart
// 1. Presenter: StatefulWidget entry point
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => View();
}

// 2. PresenterState: Abstract base with lifecycle
abstract class PresenterState extends State<LoginPage> {
  late final ViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ViewModel();
  }
}

// 3. View: Concrete state implementation
class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    // UI rendering here
  }
}

// 4. ViewModel: Business logic
class ViewModel {
  // State and methods here
}
```

### State Management

- **Global State**: `AppStateNotifier` via Provider for logged-in user, locale
- **Local State**: Page-specific `ViewModel` classes
- **Form State**: FormField and FormFieldState for validation

### Localization

- Supported: English (US), Indonesian
- Files: `lib/src/localization/languages/{en_us.dart, id_id.dart}`
- Usage: `context.tr('key')` via BuildContext extension

## Key Files

| File                                          | Purpose                        |
| --------------------------------------------- | ------------------------------ |
| `lib/form_fields.dart`                        | Package public API             |
| `example/lib/main.dart`                       | Example app MVP root           |
| `example/lib/config/app_router.dart`          | Navigation setup               |
| `example/lib/data/models/user.dart`           | Data model (JSON serializable) |
| `example/lib/data/services/http_service.dart` | HTTP client singleton          |
| `example/lib/ui/pages/*/presenter.dart`       | Page MVP presenters            |
| `example/lib/ui/pages/*/view.dart`            | Page MVP views                 |
| `example/lib/ui/pages/*/view_model.dart`      | Page MVP logic                 |

## Dependencies

### Runtime

- `flutter` - UI framework
- `intl` - Internationalization
- `provider` - State management
- `go_router` - Navigation
- `dio` - HTTP client
- `json_annotation` - JSON serialization

### Development

- `flutter_lints` - Code quality
- `flutter_test` - Testing
- `build_runner` - Code generation
- `json_serializable` - JSON code gen

## Documentation

- **README.md** - Package overview and showcase
- **USAGE.md** - Detailed usage guide with examples
- **API.md** - Complete API reference
- **QUICKSTART.md** - Quick start guide
- **LOCALIZATION.md** - Localization implementation guide
- **CONTRIBUTING.md** - Contribution guidelines
- **CHANGELOG.md** - Version history
