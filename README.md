# Form Fields Flutter Package

A reusable Flutter package for building form UIs with consistent behavior, validation, localization, and Material 3-friendly components.

## Quick Start

Add dependency:

```yaml
dependencies:
  form_fields: ^latest
```

Import package:

```dart
import 'package:form_fields/form_fields.dart';
```

Basic example:

```dart
FormFields<String>(
  label: 'Username',
  currrentValue: '',
  onChanged: (value) {},
)
```

## Component Documentation (Separated)

Each component now has its own documentation file for better readability and maintenance:

- [AppButton](docs/components/app_button.md)
- [AppButtonGroup](docs/components/app_button_group.md)
- [AppSegmentedButton](docs/components/app_segmented_button.md)
- [AppSplitButton](docs/components/app_split_button.md)
- [AppFabMenu](docs/components/app_fab_menu.md)
- [AppDialogService](docs/components/app_dialog_service.md)
- [Loading & Progress](docs/components/loading_progress.md)
- [FormFields](docs/components/form_fields.md)
- [FormFieldsAutocomplete](docs/components/form_fields_autocomplete.md)
- [FormFieldsDropdown](docs/components/form_fields_dropdown.md)
- [FormFieldsDropdownMulti](docs/components/form_fields_dropdown_multi.md)
- [FormFieldsRadioButton](docs/components/form_fields_radio_button.md)
- [FormFieldsCheckbox](docs/components/form_fields_checkbox.md)
- [FormFieldsSelect](docs/components/form_fields_select.md)

Open the docs index:

- [Documentation Index](docs/README.md)

Architecture shortcuts:

- [Architecture Diagram](ARCHITECTURE.md#architecture-diagram)
- [FormFields Validation Flow](ARCHITECTURE.md#formfields-validation-flow)
- [AppButton Family Diagram](ARCHITECTURE.md#appbutton-family-diagram)

Segmented button icon behavior note:

- `ButtonSegment.icon` can be hardcoded per segment. See [AppSegmentedButton docs](docs/components/app_segmented_button.md) for best practices with `selectedIcon`.

AppButton generic callback note:

- `AppButton<T>` supports typed payload callbacks via `value` + `onPressedWithValue`. See [AppButton docs](docs/components/app_button.md).
- Includes examples for all `AppButtonType` with generic `T` in [AppButton docs](docs/components/app_button.md#all-button-types-with-generic-t).

### AppButton<T> Quick Example

```dart
class LoginAction {
  final String source;
  final bool rememberMe;

  const LoginAction({required this.source, required this.rememberMe});
}

AppButton<LoginAction>(
  text: 'Sign in',
  value: const LoginAction(source: 'email', rememberMe: true),
  onPressedWithValue: (payload) {
    if (payload == null) return;
    login(source: payload.source, rememberMe: payload.rememberMe);
  },
)
```

## Additional References

- [API Reference](API.md)
- [Usage Guide](USAGE.md)
- [Localization Guide](LOCALIZATION.md)
- [Quickstart](QUICKSTART.md)
- [Architecture](ARCHITECTURE.md)
- [Project Structure](PROJECT_STRUCTURE.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

## License

This project is licensed under the [LICENSE](LICENSE).
