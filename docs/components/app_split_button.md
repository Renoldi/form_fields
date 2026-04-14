# AppSplitButton

Two-part button with primary action and dropdown secondary actions.

## Basic Usage

```dart
AppSplitButton<String>(
  size: AppButtonSize.medium,
  text: 'Add to cart',
  onPressed: () {},
  items: const [
    AppSplitButtonItem(value: 'save', label: 'Save for later'),
  ],
  onSelected: (value) {},
)
```

## Size Presets

`AppSplitButton` now supports `AppButtonSize`:

- `AppButtonSize.small`
- `AppButtonSize.medium`
- `AppButtonSize.large`
- `AppButtonSize.custom`

You can still override dimensions manually using:

- `height`
- `mainHorizontalPadding`
- `dropdownWidth`
- `width`

Manual overrides take priority over size presets.
