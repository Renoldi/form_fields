# AppDialogService

Reusable dialog helper for loading, success, info, and error flows.
Use it together with `AppGlobalDialogService` when you need to show dialogs
without passing `BuildContext` through every layer.

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
await AppGlobalDialogService.instance.showError(
  title: context.tr('loginFailed'),
  message: context.tr('invalidCredentials'),
  dialogType: AppDialogType.authentication,
  okLabel: context.tr('ok'),
);
```

## Recommended Architecture

- Use `AppDialogService(context)` for page-level flows.
- Use `AppGlobalDialogService.instance` for global/app-level flows.
- Keep technical details in logger, and map user-facing messages via localization keys.

## Async Guard (Simple Flow)

```dart
final user = await AppGlobalDialogService.instance.guard<User>(
  task: viewModel.login,
  errorTitle: context.tr('loginFailed'),
  mapError: (error) {
    if (error is HttpException) {
      return (
        message: context.tr(error.messageKey),
        type: _toDialogType(error.type),
      );
    }

    logger.e('Login failed (unexpected): $error');
    return (
      message: context.tr('errorLoginTemporarilyUnavailable'),
      type: AppDialogType.server,
    );
  },
  okLabel: context.tr('ok'),
  showBlockingLoading: true,
  loadingMessage: context.tr('signingIn'),
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
await AppGlobalDialogService.instance.guard<void>(
  task: () async => syncData(),
  errorTitle: context.tr('updateFailed'),
  mapError: (error) {
    if (error is HttpException) {
      return (
        message: context.tr(error.messageKey),
        type: AppDialogType.network,
      );
    }

    logger.e('Sync failed (unexpected): $error');
    return (
      message: context.tr('errorRequestFailedGeneric'),
      type: AppDialogType.server,
    );
  },
  showBlockingLoading: true,
  loadingVisual: AppDialogLoadingVisual.progress,
  progressType: AppProgressType.linear,
  loadingMessage: context.tr('loading'),
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
  errorTitle: context.tr('updateFailed'),
  mapError: (error) => (
    message: context.tr('errorRequestFailedGeneric'),
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
  cancelTitle: context.tr('updateFailed'),
  cancelMessage: context.tr('loading'),
  cancelLabel: context.tr('cancel'),
  stayLabel: context.tr('stay'),
);
```

## Global Dialog (No Manual Context)

Use `AppGlobalDialogService` when you want to trigger dialogs from places
that do not naturally receive `BuildContext` (for example, coordinators or app-level handlers).

Startup configuration:

```dart
final rootNavigatorKey = GlobalKey<NavigatorState>();

AppGlobalDialogService.instance.configure(rootNavigatorKey);

final router = createAppRouter(
  appState,
  navigatorKey: rootNavigatorKey,
);
```

Usage:

```dart
await AppGlobalDialogService.instance.showSuccess(
  title: context.tr('success'),
  message: context.tr('profileUpdatedSuccessfully'),
  okLabel: context.tr('ok'),
);
```

Global guard pattern:

```dart
final ok = await AppGlobalDialogService.instance.guard<bool>(
  task: () async {
    final errorKey = await viewModel.updateProfile(appState);
    if (errorKey != null) throw StateError(errorKey);
    return true;
  },
  errorTitle: context.tr('updateFailed'),
  mapError: (error) => (
    message: context.tr(error.toString().replaceFirst('Bad state: ', '')),
    type: AppDialogType.server,
  ),
  showBlockingLoading: true,
  loadingMessage: context.tr('updatingProfile'),
);
```

Global loading with back-confirm cancel:

```dart
await AppGlobalDialogService.instance.showLoading(
  message: context.tr('loading'),
  loadingBackBehavior: AppDialogLoadingBackBehavior.confirmCancel,
  cancelTitle: context.tr('updateFailed'),
  cancelMessage: context.tr('loading'),
  cancelLabel: context.tr('cancel'),
  stayLabel: context.tr('stay'),
  onCancelRequested: () async {
    cancelToken.cancel('User canceled from global loading dialog');
    return true;
  },
  onCancelled: () async {
    // Optional cleanup
  },
);
```
