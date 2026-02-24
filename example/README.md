# FormFields Example App

This is a comprehensive example application demonstrating all features of the FormFields package.

## What's Demonstrated

### Basic Field Types
- **Text Fields**: Simple text input, email validation, phone validation
- **Password Field**: With visibility toggle
- **Numeric Fields**: Integer and double with thousands separator formatting
- **Multiline Text**: Bio and notes fields

### Date & Time Pickers
- **Date Picker**: Birth date selection
- **Time Picker (DateTime)**: Returns DateTime with current date + selected time
- **Time Picker (TimeOfDay)**: Returns TimeOfDay object (hour and minute only)
- **DateTime Picker**: Combined date and time selection
- **DateRange Picker**: Select start and end dates

### TimeOfDay ↔ DateTime Conversions
The example demonstrates:
- Converting `DateTime` to `TimeOfDay` using `.toTimeOfDay()`
- Converting `TimeOfDay` to `DateTime` using `.toDateTime()`
- Converting `TimeOfDay` to DateTime with a specific date using `.toDateTimeWithDate(date)`

### Customization Features
- Label positioning (top, bottom, left, right, inline, none)
- Border styles (outline, underline, none)
- Custom locale support for pickers
- Custom validation
- Nullable/optional fields

### Form Validation
- Required field validation
- Email format validation
- Phone format validation
- Form submission with validation feedback

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## Key Features to Try

1. **Try both time picker types** to see the difference between DateTime and TimeOfDay
2. **Watch the live conversions** in the yellow conversion box that appears after selecting times
3. **Submit the form** to see all conversions in the submitted data section
4. **Test nullable fields** to see how optional fields behave
5. **Try different locales** with the custom locale time picker

## Learning Points

- When to use `FormFields<DateTime>` vs `FormFields<TimeOfDay>` for time pickers
- How to convert between TimeOfDay and DateTime
- How to handle nullable vs non-nullable form fields
- How to validate different field types
- How to customize form field appearance

## Documentation

For more information, see:
- [README.md](../README.md) - Package overview
- [USAGE.md](../USAGE.md) - Detailed usage guide
- [API.md](../API.md) - Complete API reference
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
