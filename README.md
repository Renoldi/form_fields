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
- [FormFields](docs/components/form_fields.md)
- [FormFieldsAutocomplete](docs/components/form_fields_autocomplete.md)
- [FormFieldsDropdown](docs/components/form_fields_dropdown.md)
- [FormFieldsDropdownMulti](docs/components/form_fields_dropdown_multi.md)
- [FormFieldsRadioButton](docs/components/form_fields_radio_button.md)
- [FormFieldsCheckbox](docs/components/form_fields_checkbox.md)
- [FormFieldsSelect](docs/components/form_fields_select.md)

Open the docs index:

- [Documentation Index](docs/README.md)

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
