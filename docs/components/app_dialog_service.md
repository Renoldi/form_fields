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

## Back Behavior During Loading

Use `loadingBackBehavior` to control what happens when user presses device back while loading is visible:

- `AppDialogLoadingBackBehavior.block`: ignore back press (default).
- `AppDialogLoadingBackBehavior.allow`: close loading immediately.
- `AppDialogLoadingBackBehavior.confirmCancel`: ask confirmation first.

Example with confirm + cancellation hook:

```dart
await AppDialogService(context).guard<void>(
  task: () async => uploadFile(),
  errorTitle: 'Upload Failed',
  mapError: (error) => (
    message: error.toString(),
    type: AppDialogType.network,
  ),
  showBlockingLoading: true,
  loadingBackBehavior: AppDialogLoadingBackBehavior.confirmCancel,
  onCancelRequested: () async {
    // Return true if cancel is approved and request cancellation is triggered.
    cancelToken.cancel('User canceled upload');
    return true;
  },
  onCancelled: () async {
    // Optional cleanup after dialog is closed.
  },
  cancelTitle: 'Cancel Upload?',
  cancelMessage: 'The upload is still running. Cancel it?',
  cancelLabel: 'Cancel Upload',
  stayLabel: 'Keep Uploading',
);
```
