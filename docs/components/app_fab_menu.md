# AppFabMenu

Expandable floating action button menu for grouped quick actions.

## Basic Usage

```dart
AppFabMenu(
  size: AppButtonSize.small,
  items: [
    AppFabMenuItem(label: 'First', icon: Icon(Icons.looks_one), onPressed: () {}),
    AppFabMenuItem(label: 'Second', icon: Icon(Icons.looks_two), onPressed: () {}),
  ],
)
```

## Size Presets

Supports `AppButtonSize` to control main FAB and menu-item FAB sizes:

- `AppButtonSize.small`
- `AppButtonSize.medium`
- `AppButtonSize.large`
- `AppButtonSize.custom` (uses medium fallback)
