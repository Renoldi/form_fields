part of '../app_dialog_service.dart';

extension _AppDialogFlowX on AppDialogService {
  Future<void> _exitApplication(BuildContext dialogContext) async {
    Navigator.of(dialogContext, rootNavigator: true).pop();

    if (!context.mounted) return;

    if (kIsWeb) {
      await Navigator.of(context, rootNavigator: true).maybePop();
      return;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        await SystemNavigator.pop();
        return;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        await Navigator.of(context, rootNavigator: true).maybePop();
        return;
    }
  }

  Future<void> _showProtectedDialog({
    Alignment? alignment,
    EdgeInsets? insetPadding,
    Color? backgroundColor,
    Future<void> Function()? onBackPressed,
    required Widget child,
    bool barrierDismissible = false,
    bool useSafeArea = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      useSafeArea: useSafeArea,
      builder: (dialogContext) {
        return PopScope(
          canPop: barrierDismissible,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (onBackPressed != null) {
              await onBackPressed();
              return;
            }
            await showExitConfirm();
          },
          child: Dialog(
            alignment: alignment,
            insetPadding: insetPadding,
            backgroundColor: backgroundColor,
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _handleLoadingBackPressed({
    required AppDialogLoadingBackBehavior loadingBackBehavior,
    required AppDialogCancelRequested? onCancelRequested,
    required AppDialogCancelled? onCancelled,
    required String cancelTitle,
    required String cancelMessage,
    required String stayLabel,
    required String cancelLabel,
  }) async {
    switch (loadingBackBehavior) {
      case AppDialogLoadingBackBehavior.block:
        return;
      case AppDialogLoadingBackBehavior.allow:
        final approved = await _resolveCancellation(onCancelRequested);
        if (!approved) return;
        _dismissLoadingIfVisible();
        await _runCancelled(onCancelled);
        return;
      case AppDialogLoadingBackBehavior.confirmCancel:
        final shouldCancel = await _showCancelLoadingConfirm(
          title: cancelTitle,
          message: cancelMessage,
          stayLabel: stayLabel,
          cancelLabel: cancelLabel,
        );
        if (!shouldCancel) return;

        final approved = await _resolveCancellation(onCancelRequested);
        if (!approved) return;

        _dismissLoadingIfVisible();
        await _runCancelled(onCancelled);
        return;
    }
  }

  Future<bool> _resolveCancellation(
    AppDialogCancelRequested? onCancelRequested,
  ) async {
    return await onCancelRequested?.call() ?? true;
  }

  Future<void> _runCancelled(AppDialogCancelled? onCancelled) async {
    await onCancelled?.call();
  }

  Future<bool> _showCancelLoadingConfirm({
    required String title,
    required String message,
    required String stayLabel,
    required String cancelLabel,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            SizedBox(
              width: 92,
              child: AppButton(
                type: AppButtonType.outlined,
                size: AppSize.small,
                text: stayLabel,
                useSafeArea: false,
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(false),
              ),
            ),
            SizedBox(
              width: 92,
              child: AppButton(
                type: AppButtonType.filled,
                size: AppSize.small,
                text: cancelLabel,
                useSafeArea: false,
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(true),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _dismissLoadingIfVisible() {
    if (!AppDialogService._isLoadingDialogVisible || !context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }
}
