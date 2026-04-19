# AppModalBottomSheet

Reusable, beautiful, and keyboard-aware modal bottom sheet for Flutter.

## Features

- Always uses SafeArea and bottom padding for keyboard
- Accepts all `showModalBottomSheet` parameters
- Easy to use across your project: just import and call

## Basic Usage

```dart
await showAppModalBottomSheet(
  context: context,
  builder: (ctx) => YourWidget(),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
);
```

## Parameters

- All parameters from Flutter's `showModalBottomSheet`
- Keyboard-aware and safe by default

See [API.md](../../API.md) for full details.
