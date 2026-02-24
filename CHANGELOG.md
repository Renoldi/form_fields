# Changelog

All notable changes to the FormFields package will be documented in this file.

## [1.0.0] - 2026-02-24

### Added

- Initial release of FormFields package
- Core `FormFields<T>` widget with generic type support
- Multiple form field types:
  - Text (FormType.string)
  - Email (FormType.email)
  - Phone (FormType.phone)
  - Password (FormType.password)
  - Date (FormType.date)
  - Time (FormType.time) - supports both DateTime and TimeOfDay types
  - DateTime (FormType.dateTime)
  - Integer and Double numeric fields
  - Date range picker
  - Multiline text areas

- Label positioning options:
  - Top (LabelPosition.top)
  - Bottom (LabelPosition.bottom)
  - Left (LabelPosition.left)
  - Right (LabelPosition.right)
  - Inline/Floating (LabelPosition.inBorder)
  - Hidden (LabelPosition.none)

- Border style options:
  - Outline (BorderType.outlineInputBorder)
  - Underline (BorderType.underlineInputBorder)
  - None (BorderType.none)

- Built-in validators:
  - Required field validation
  - Email format validation
  - Phone format validation
  - Password strength validation
  - Numeric validation
  - Min/max length validation
  - Range validation
  - Pattern matching validation
  - Field matching/confirmation validation
  - Composable validator support

- String extensions:
  - Email validation (isValidEmail)
  - Phone validation (isValidPhone)
  - Password validation (isValidPassword)
  - Whitespace checking (isWhiteSpace)
  - Numeric validation (isValidNumber)

- DateTime extensions:
  - Date comparison helpers
  - Flexible date formatting
  - TimeOfDay conversion (toTimeOfDay)

- TimeOfDay extensions:
  - DateTime conversion (toDateTime)
  - DateTime conversion with specific date (toDateTimeWithDate)

- State management:
  - FormFieldsController for field state
  - Provider-based reactive updates
  - Debounced input handling (500ms)

- Customization features:
  - Custom validators
  - Custom input decoration
  - Custom date/time formats
  - Prefix and suffix widgets
  - Custom border radius
  - Focus node support for keyboard navigation
  - Locale support for date/time pickers (string format: 'en_US', 'id_ID', etc.)
  - Custom error messages (enterText, invalidIntegerText, invalidNumberText)
  - Custom date range (firstDate, lastDate) for date pickers

- Number formatting:
  - Automatic thousands separator formatting
  - Configurable with stripSeparators parameter
  - Support for both integer and decimal numbers

- User experience featuret
  - DateTimeRange support
  - TimeOfDay support for time-only valuespe selection
  - Validation feedback
  - Clear/reset button for fields
  - Multiline text suppor
  - TimeOfDay support for time-only valuest
  - DateTimeRange support

- Documentation:
  - Comprehensive README
  - Detailed usage manual
  - Complete example application
  - API documentation

### Features

- **Type Safety**: Generic type system for compile-time type checking
- **Flexible Validation**: Built-in and custom validator support
- **Beautiful UI**: Material Design inspired with full customization
- **Developer Friendly**: Clear API and excellent documentation
- **Production Ready**: Tested and reliable for use in production apps

### Package Dependencies

- flutter: >=3.0.0
- provider: ^6.0.0
- intl: ^0.19.0

### Known Limitations

- Phone validation supports Indonesian format primarily
- Date pickers limited to past dates by default
- Locale support depends on intl package

---

## Upcoming Features (Future Releases)

- [ ] More locale support for phone validation
- [ ] Multi-select fields
- [ ] Autocomplete/suggestion fields
- [ ] Search/filtering fields
- [ ] Custom keyboard support
- [ ] Tablet layout optimization
- [ ] Accessibility improvements
