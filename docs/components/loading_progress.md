# Loading & Progress

Reusable indicators for loading and progress states.

## AppDialogService

Reusable dialog helper for success, error, info, and guarded async tasks.

```dart
await AppGlobalDialogService.instance.showSuccess(
  title: context.tr('success'),
  message: context.tr('profileUpdatedSuccessfully'),
  okLabel: context.tr('ok'),
  position: AppDialogPosition.top,
);
```

Use `AppGlobalDialogService.instance` for app-level flows where passing local
`BuildContext` is not practical.

Guard async operation with optional blocking loading dialog:

```dart
final result = await AppGlobalDialogService.instance.guard<String>(
  task: () async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    throw Exception('errorRequestFailedGeneric');
  },
  errorTitle: context.tr('updateFailed'),
  mapError: (error) {
    if (error is HttpException) {
      return (
        message: context.tr(error.messageKey),
        type: AppDialogType.network,
      );
    }

    logger.e('Unexpected sync error: $error');
    return (
      message: context.tr(error.toString().replaceFirst('Exception: ', '')),
      type: AppDialogType.server,
    );
  },
  showBlockingLoading: true,
  loadingMessage: context.tr('loading'),
  loadingVisual: AppDialogLoadingVisual.progress,
  progressType: AppProgressType.circular,
);
```

Localization-friendly guard mapping pattern:

```dart
final result = await AppGlobalDialogService.instance.guard<String>(
  task: () async => syncData(),
  errorTitle: context.tr('updateFailed'),
  mapError: (error) {
    if (error is HttpException) {
      return (
        message: context.tr(error.messageKey),
        type: AppDialogType.network,
      );
    }

    logger.e('Unexpected sync error: $error');
    return (
      message: context.tr('errorRequestFailedGeneric'),
      type: AppDialogType.server,
    );
  },
  showBlockingLoading: true,
  loadingMessage: context.tr('loading'),
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
