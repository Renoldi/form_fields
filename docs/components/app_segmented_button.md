# AppSegmentedButton

Wrapper around Material 3 `SegmentedButton`.

## Basic Usage

```dart
AppSegmentedButton<String>(
  size: AppButtonSize.medium,
  segments: const [
    ButtonSegment(value: 'songs', label: Text('Songs')),
    ButtonSegment(value: 'albums', label: Text('Albums')),
  ],
  selected: {'songs'},
  onSelectionChanged: (value) {},
)
```

## Size Presets

Supports `AppButtonSize` for consistent sizing:

- `AppButtonSize.small`
- `AppButtonSize.medium`
- `AppButtonSize.large`
- `AppButtonSize.custom` (uses medium fallback)

## ButtonSegment Icon Note

`ButtonSegment.icon` can be hardcoded per item. This is valid and useful when every segment has its own fixed icon.

```dart
ButtonSegment<String>(
  value: 'songs',
  icon: Icon(Icons.music_note),
  label: Text('Songs'),
)
```

If you also want a selection checkmark, prefer using `selectedIcon` on `AppSegmentedButton`.

Important:

- If a segment already has a hardcoded icon, selected state can replace that icon (default Material behavior).
- Avoid hardcoding a check icon (`Icons.check`) in one segment while also using `selectedIcon`, because it can look like the check is stuck or duplicated.

Recommended selected-check setup:

```dart
AppSegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'songs', label: Text('Songs')),
    ButtonSegment(value: 'albums', label: Text('Albums')),
  ],
  selected: {'songs'},
  selectedIcon: const Icon(Icons.check, size: 16),
  onSelectionChanged: (value) {},
)
```
