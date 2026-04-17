library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_loading_indicator.dart';
import '../utilities/enums.dart';
import '../utilities/dialog_typedefs.dart';

import 'app_progress_indicator.dart';

class AppDialogService {
  /// Shows or hides a visual-only loading dialog without guard or async context.
  /// Call with `show: true` to display, and `show: false` to hide.
  void unguardedLoadingVisualOnly({
    required bool show,
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    AppDialogPosition position = AppDialogPosition.bottom,
    bool isDismissible = false,
    bool useSafeArea = true,
  }) {
    if (show) {
      if (_isLoadingDialogVisible) return;
      _isLoadingDialogVisible = true;
      if (loadingVisual == AppDialogLoadingVisual.indicatorOnly) {
        _showProtectedDialog(
          alignment: _alignment(position),
          insetPadding: _inset(position),
          backgroundColor: Colors.transparent,
          barrierDismissible: isDismissible,
          useSafeArea: useSafeArea,
          child: _buildLoadingVisual(
            loadingVisual: AppDialogLoadingVisual.indicator,
            loadingVariant: loadingVariant,
            progressType: progressType,
          ),
        ).whenComplete(() {
          _isLoadingDialogVisible = false;
        });
      } else {
        _showProtectedDialog(
          alignment: _alignment(position),
          insetPadding: _inset(position),
          backgroundColor: Colors.transparent,
          barrierDismissible: isDismissible,
          useSafeArea: useSafeArea,
          child: _defaultDialogCard(
            child: _buildLoadingVisual(
              loadingVisual: loadingVisual,
              loadingVariant: loadingVariant,
              progressType: progressType,
            ),
          ),
        ).whenComplete(() {
          _isLoadingDialogVisible = false;
        });
      }
    } else {
      _dismissLoadingIfVisible();
    }
  }

  /// Shows only the loading visual (no message), with position and onComplete support.
  Future<void> showLoadingVisualOnly({
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    AppDialogPosition position = AppDialogPosition.bottom,
    VoidCallback? onComplete,
    bool isDismissible = false,
    bool useSafeArea = true,
  }) {
    if (_isLoadingDialogVisible) {
      return Future.value();
    }

    _isLoadingDialogVisible = true;

    if (loadingVisual == AppDialogLoadingVisual.indicatorOnly) {
      return _showProtectedDialog(
        alignment: _alignment(position),
        insetPadding: _inset(position),
        backgroundColor: Colors.transparent,
        barrierDismissible: isDismissible,
        useSafeArea: useSafeArea,
        child: _buildLoadingVisual(
          loadingVisual: AppDialogLoadingVisual.indicator,
          loadingVariant: loadingVariant,
          progressType: progressType,
        ),
      ).whenComplete(() {
        _isLoadingDialogVisible = false;
        if (onComplete != null) onComplete();
      });
    } else {
      return _showProtectedDialog(
        alignment: _alignment(position),
        insetPadding: _inset(position),
        backgroundColor: Colors.transparent,
        barrierDismissible: isDismissible,
        useSafeArea: useSafeArea,
        child: _defaultDialogCard(
          child: _buildLoadingVisual(
            loadingVisual: loadingVisual,
            loadingVariant: loadingVariant,
            progressType: progressType,
          ),
        ),
      ).whenComplete(() {
        _isLoadingDialogVisible = false;
        if (onComplete != null) onComplete();
      });
    }
  }

  final BuildContext context;
  bool _isLoadingDialogVisible = false;

  AppDialogService(this.context);

  /// Error payload used by [guard] for consistent dialog mapping.
  static ({String message, AppDialogType type}) defaultErrorMapper(
    Object error,
  ) {
    return (message: error.toString(), type: AppDialogType.server);
  }

  /// Runs an async task and automatically shows an error dialog on failure.
  ///
  /// Returns the task result when successful, otherwise `null`.
  Future<T?> guard<T>({
    required Future<T> Function() task,
    required String errorTitle,
    required AppDialogErrorMapper mapError,
    AppDialogPosition loadingPosition = AppDialogPosition.top,
    AppDialogPosition resultPosition = AppDialogPosition.top,
    String okLabel = 'OK',
    bool showBlockingLoading = false,
    String loadingMessage = 'Loading...',
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    AppDialogLoadingBackBehavior loadingBackBehavior =
        AppDialogLoadingBackBehavior.block,
    AppDialogCancelRequested? onCancelRequested,
    AppDialogCancelled? onCancelled,
    String cancelTitle = 'Cancel Process?',
    String cancelMessage =
        'The operation is still in progress. Do you want to cancel it?',
    String stayLabel = 'Stay',
    String cancelLabel = 'Cancel',
    bool isDismissible = false,
  }) async {
    var loadingShown = false;

    try {
      if (showBlockingLoading) {
        loadingShown = true;
        unawaited(
          showLoading(
            message: loadingMessage,
            loadingVisual: loadingVisual,
            loadingVariant: loadingVariant,
            progressType: progressType,
            loadingBackBehavior: loadingBackBehavior,
            onCancelRequested: onCancelRequested,
            onCancelled: onCancelled,
            cancelTitle: cancelTitle,
            cancelMessage: cancelMessage,
            stayLabel: stayLabel,
            cancelLabel: cancelLabel,
            position: loadingPosition,
            isDismissible: isDismissible,
          ),
        );
        // Give Flutter one frame to paint the blocking dialog
        // before starting the long-running task.
        await WidgetsBinding.instance.endOfFrame;
      }

      return await task();
    } catch (error) {
      _dismissLoadingIfVisible();
      loadingShown = false;

      final mapped = mapError(error);
      await showError(
        title: errorTitle,
        message: mapped.message,
        dialogType: mapped.type,
        position: resultPosition,
        okLabel: okLabel,
      );
      return null;
    } finally {
      if (loadingShown) {
        _dismissLoadingIfVisible();
      }
    }
  }

  Future<void> showLoading({
    String message = 'Loading...',
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    AppDialogLoadingBackBehavior loadingBackBehavior =
        AppDialogLoadingBackBehavior.block,
    AppDialogCancelRequested? onCancelRequested,
    AppDialogCancelled? onCancelled,
    String cancelTitle = 'Cancel Process?',
    String cancelMessage =
        'The operation is still in progress. Do you want to cancel it?',
    String stayLabel = 'Stay',
    String cancelLabel = 'Cancel',
    AppDialogPosition position = AppDialogPosition.bottom,
    bool isDismissible = false,
  }) {
    if (_isLoadingDialogVisible) {
      return Future.value();
    }

    _isLoadingDialogVisible = true;

    return _showProtectedDialog(
      alignment: _alignment(position),
      insetPadding: _inset(position),
      backgroundColor: Colors.transparent,
      onBackPressed: () => _handleLoadingBackPressed(
        loadingBackBehavior: loadingBackBehavior,
        onCancelRequested: onCancelRequested,
        onCancelled: onCancelled,
        cancelTitle: cancelTitle,
        cancelMessage: cancelMessage,
        stayLabel: stayLabel,
        cancelLabel: cancelLabel,
      ),
      child: _defaultDialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoadingVisual(
              loadingVisual: loadingVisual,
              loadingVariant: loadingVariant,
              progressType: progressType,
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    ).whenComplete(() {
      _isLoadingDialogVisible = false;
    });
  }

  void hide() {
    _dismissLoadingIfVisible();
  }

  Future<void> showError({
    required String title,
    required String message,
    required AppDialogType dialogType,
    AppDialogPosition position = AppDialogPosition.top,
    String okLabel = 'OK',
    VoidCallback? onComplete,
  }) {
    return showResult(
      title: title,
      message: message,
      isSuccess: false,
      dialogType: dialogType,
      position: position,
      okLabel: okLabel,
      onComplete: onComplete,
    );
  }

  Widget _buildLoadingVisual({
    required AppDialogLoadingVisual loadingVisual,
    required AppLoadingVariant loadingVariant,
    required AppProgressType progressType,
  }) {
    if (loadingVisual == AppDialogLoadingVisual.progress) {
      if (progressType == AppProgressType.linear) {
        return const SizedBox(
          width: 180,
          child: AppProgressIndicator(
            type: AppProgressType.linear,
            value: null,
            minHeight: 8,
          ),
        );
      }

      return const AppProgressIndicator(
        type: AppProgressType.circular,
        value: null,
        size: 34,
      );
    }

    return AppLoadingIndicator(
      variant: loadingVariant,
      size: 34,
    );
  }

  Future<void> showSuccess({
    required String title,
    required String message,
    AppDialogPosition position = AppDialogPosition.top,
    String okLabel = 'OK',
    VoidCallback? onComplete,
  }) {
    return showResult(
      title: title,
      message: message,
      isSuccess: true,
      position: position,
      okLabel: okLabel,
      onComplete: onComplete,
    );
  }

  Future<void> showInfo({
    required String title,
    required String message,
    AppDialogPosition position = AppDialogPosition.top,
    String okLabel = 'OK',
  }) {
    return showResult(
      title: title,
      message: message,
      isSuccess: false,
      dialogType: AppDialogType.validation,
      position: position,
      okLabel: okLabel,
    );
  }

  Future<void> showResult({
    required String title,
    required String message,
    required bool isSuccess,
    AppDialogType? dialogType,
    AppDialogPosition position = AppDialogPosition.top,
    String okLabel = 'OK',
    VoidCallback? onComplete,
  }) {
    final (icon, color) = _style(dialogType, isSuccess);

    return _showProtectedDialog(
      alignment: _alignment(position),
      insetPadding: _inset(position),
      child: _defaultDialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  okLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (onComplete != null) onComplete();
    });
  }

  Future<void> showExitConfirm({
    String title = 'Exit Application',
    String message =
        'Are you sure you want to close the application? Any unsaved changes may be lost.',
    String stayLabel = 'Stay',
    String exitLabel = 'Exit',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: Text(stayLabel),
            ),
            FilledButton(
              onPressed: () async => _exitApplication(dialogContext),
              child: Text(exitLabel),
            ),
          ],
        );
      },
    );
  }

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

  Widget _defaultDialogCard({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      child: child,
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
    if (onCancelRequested == null) return true;
    return await onCancelRequested();
  }

  Future<void> _runCancelled(AppDialogCancelled? onCancelled) async {
    if (onCancelled == null) return;
    await onCancelled();
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
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(false),
              child: Text(stayLabel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(true),
              child: Text(cancelLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _dismissLoadingIfVisible() {
    if (!_isLoadingDialogVisible || !context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  (IconData, Color) _style(AppDialogType? type, bool isSuccess) {
    if (isSuccess) {
      return (Icons.check_circle, Colors.green.shade600);
    }

    if (type == null) {
      return (Icons.error, Colors.red.shade600);
    }

    switch (type) {
      case AppDialogType.validation:
        return (Icons.warning_outlined, Colors.orange.shade600);
      case AppDialogType.network:
        return (Icons.cloud_off, Colors.blue.shade600);
      case AppDialogType.authentication:
        return (Icons.lock_outline, Colors.red.shade700);
      case AppDialogType.server:
        return (Icons.error_outline, Colors.red.shade600);
    }
  }

  Alignment _alignment(AppDialogPosition position) {
    switch (position) {
      case AppDialogPosition.top:
        return Alignment.topCenter;
      case AppDialogPosition.center:
        return Alignment.center;
      case AppDialogPosition.bottom:
        return Alignment.bottomCenter;
    }
  }

  EdgeInsets _inset(AppDialogPosition position) {
    switch (position) {
      case AppDialogPosition.top:
        return const EdgeInsets.fromLTRB(16, 80, 16, 0);
      case AppDialogPosition.center:
        return const EdgeInsets.symmetric(horizontal: 16);
      case AppDialogPosition.bottom:
        return const EdgeInsets.fromLTRB(16, 0, 16, 80);
    }
  }
}
