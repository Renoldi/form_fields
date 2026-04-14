# AppButton

Reusable Material 3 button component that supports multiple button types, loading state, custom style overrides, and safe-area/keyboard-aware layout.

`AppButton` also supports generic typed payload callbacks via `AppButton<T>`.

## Supported Types

- `AppButtonType.filled`
- `AppButtonType.filledTonal`
- `AppButtonType.elevated`
- `AppButtonType.outlined`
- `AppButtonType.text`
- `AppButtonType.icon`
- `AppButtonType.fab`
- `AppButtonType.extendedFab`

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

## Generic Typed Callback (T)

```dart
AppButton<String>(
  text: 'Select Plan',
  value: 'pro',
  onPressedWithValue: (value) {
    debugPrint('Selected: $value');
  },
)
```

You can use any type for `T`, for example:

- `AppButton<int>` with `value: 99`
- `AppButton<bool>` with `value: true`
- `AppButton<MyPayload>` with a custom class

Custom class example:

```dart
class ActionPayload {
  final String code;
  final int priority;

  const ActionPayload({required this.code, required this.priority});
}

AppButton<ActionPayload>(
  text: 'Payload custom class',
  value: const ActionPayload(code: 'checkout', priority: 1),
  onPressedWithValue: (payload) {
    if (payload != null) {
      debugPrint('${payload.code} / ${payload.priority}');
    }
  },
)
```

Callback priority:

- If `isLoading` is true: button is disabled.
- If `onPressedWithValue` is provided: it will be used.
- Otherwise `onPressed` is used.

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
- `value`: Optional typed payload passed to `onPressedWithValue`.
- `onPressedWithValue`: Typed callback for generic payload (`AppButton<T>`).
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
