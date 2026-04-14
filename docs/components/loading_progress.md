# Loading & Progress

Reusable indicators for loading and progress states.

## AppDialogService

Reusable dialog helper for success, error, info, and guarded async tasks.

```dart
final dialog = AppDialogService(context);

await dialog.showSuccess(
  title: 'Success',
  message: 'Data saved successfully.',
  position: AppDialogPosition.top,
);
```

Guard async operation with optional blocking loading dialog:

```dart
final result = await dialog.guard<String>(
  task: () async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    throw Exception('Request failed');
  },
  errorTitle: 'Sync failed',
  mapError: (error) => (
    message: error.toString(),
    type: AppDialogType.network,
  ),
  showBlockingLoading: true,
  loadingMessage: 'Syncing...',
  loadingVisual: AppDialogLoadingVisual.progress,
  progressType: AppProgressType.circular,
);
```

Loading visual options for `showLoading`/`guard`:

- `loadingVisual: AppDialogLoadingVisual.indicator`
  - `loadingVariant: AppLoadingVariant.spinner|pulse|dots`
- `loadingVisual: AppDialogLoadingVisual.progress`
  - `progressType: AppProgressType.circular|linear`

## AppLoadingIndicator

Supports 3 variants:

- `AppLoadingVariant.spinner`
- `AppLoadingVariant.pulse`
- `AppLoadingVariant.dots`

```dart
AppLoadingIndicator(
  variant: AppLoadingVariant.pulse,
  size: 56,
)
```

## AppProgressIndicator

Supports linear and circular modes:

- `AppProgressType.linear`
- `AppProgressType.circular`

```dart
AppProgressIndicator(
  type: AppProgressType.linear,
  value: 0.64,
  showValueLabel: true,
)
```

Indeterminate state:

```dart
AppProgressIndicator(
  type: AppProgressType.linear,
  value: null,
)
```

Circular mode:

```dart
AppProgressIndicator(
  type: AppProgressType.circular,
  value: 0.42,
  size: 30,
)
```
