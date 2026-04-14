# AppDialogService

Reusable dialog helper for loading, success, info, and error flows.

## Core APIs

- `showLoading`
- `showError`
- `showSuccess`
- `showInfo`
- `showResult`
- `showExitConfirm`
- `guard` (async wrapper)

## Quick Usage

```dart
final dialog = AppDialogService(context);

await dialog.showError(
  title: 'Login Failed',
  message: 'Invalid credentials',
  dialogType: AppDialogType.authentication,
);
```

## Async Guard (Simple Flow)

```dart
final user = await AppDialogService(context).guard<User>(
  task: () => userRepository.login(username, password),
  errorTitle: 'Login Failed',
  mapError: (error) => (
    message: error.toString(),
    type: AppDialogType.server,
  ),
  showBlockingLoading: true,
  loadingMessage: 'Signing in...',
);

if (user != null) {
  // Continue success flow
}
```

## Dialog Position

- `AppDialogPosition.top`
- `AppDialogPosition.center`
- `AppDialogPosition.bottom`

## Dialog Type

- `AppDialogType.validation`
- `AppDialogType.network`
- `AppDialogType.authentication`
- `AppDialogType.server`

## Loading Visual Options

`showLoading` and `guard` support two visual modes:

- `loadingVisual: AppDialogLoadingVisual.indicator`
  - `loadingVariant: AppLoadingVariant.spinner|pulse|dots`
- `loadingVisual: AppDialogLoadingVisual.progress`
  - `progressType: AppProgressType.circular|linear`

Example:

```dart
await AppDialogService(context).guard<void>(
  task: () async => syncData(),
  errorTitle: 'Sync Failed',
  mapError: (error) => (
    message: error.toString(),
    type: AppDialogType.network,
  ),
  showBlockingLoading: true,
  loadingVisual: AppDialogLoadingVisual.progress,
  progressType: AppProgressType.linear,
  loadingMessage: 'Syncing...',
);
```
