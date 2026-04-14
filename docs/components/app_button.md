# AppButton

Reusable Material 3 button component that supports multiple button types, loading state, custom style overrides, and safe-area/keyboard-aware layout.

## Supported Types

- `AppButtonType.filled`
- `AppButtonType.elevated`
- `AppButtonType.outlined`
- `AppButtonType.text`
- `AppButtonType.icon`

## Size Presets

- `AppButtonSize.small`
- `AppButtonSize.medium`
- `AppButtonSize.large`
- `AppButtonSize.custom`

## Basic Usage

```dart
AppButton(
  type: AppButtonType.filled,
  size: AppButtonSize.medium,
  text: 'Continue',
  icon: const Icon(Icons.arrow_forward),
  onPressed: () {},
)
```

## Loading State

```dart
AppButton(
  type: AppButtonType.elevated,
  text: 'Sign In',
  isLoading: isSubmitting,
  onPressed: isSubmitting ? null : submit,
)
```

## Style Override

```dart
AppButton(
  type: AppButtonType.filled,
  text: 'Custom Shape',
  style: FilledButton.styleFrom(
    shape: const StadiumBorder(),
  ),
  onPressed: () {},
)
```

## Custom Size

```dart
AppButton(
  type: AppButtonType.filled,
  size: AppButtonSize.custom,
  customHeight: 52,
  customHorizontalPadding: 28,
  customIconSize: 26,
  customSpinnerSize: 20,
  text: 'Custom Size',
  icon: const Icon(Icons.straighten),
  onPressed: () {},
)
```

## Keyboard + Safe Area Layout

Use `withLayout: true` when placing the button near the screen bottom.

```dart
AppButton(
  withLayout: true,
  type: AppButtonType.filled,
  text: 'Submit',
  onPressed: () {},
)
```

## Constructor Parameters

- `type`: Button visual type.
- `size`: Preset or custom size mode.
- `text`: Label text.
- `child`: Custom content widget.
- `icon`: Optional leading icon.
- `onPressed`: Tap callback (null disables button).
- `isLoading`: Disables button and shows progress indicator.
- `style`: Optional external `ButtonStyle` override.
- `customHeight`: Height for `AppButtonSize.custom`.
- `customHorizontalPadding`: Horizontal content padding for custom size.
- `customIconSize`: Icon size for custom size.
- `customSpinnerSize`: Spinner size for custom size.
- `withLayout`: Wrap with safe-area/keyboard-aware layout.
- `margin`: Margin used by layout wrapper.
- `horizontalPadding`: Horizontal safe-area minimum padding.
- `topPadding`: Top spacing inside layout wrapper.
- `respectSafeArea`: Enables bottom safe-area handling.
- `avoidKeyboard`: Moves button above keyboard (`MediaQuery.viewInsets`).
