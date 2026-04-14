library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';
import 'app_loading_progress_enums.dart';
import 'app_progress_indicator.dart';

enum AppDialogType {
  validation,
  network,
  authentication,
  server,
}

enum AppDialogPosition {
  top,
  center,
  bottom,
}

enum AppDialogLoadingVisual {
  indicator,
  progress,
}

typedef AppDialogErrorMapper = ({String message, AppDialogType type}) Function(
    Object error);

class AppDialogService {
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
    AppDialogPosition position = AppDialogPosition.top,
    String okLabel = 'OK',
    bool showBlockingLoading = false,
    String loadingMessage = 'Loading...',
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
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
        position: position,
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
  }) {
    if (_isLoadingDialogVisible) {
      return Future.value();
    }

    _isLoadingDialogVisible = true;

    return _showProtectedDialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: _defaultDialogCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoadingVisual(
                  loadingVisual: loadingVisual,
                  loadingVariant: loadingVariant,
                  progressType: progressType,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
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
  }) {
    return showResult(
      title: title,
      message: message,
      isSuccess: false,
      dialogType: dialogType,
      position: position,
      okLabel: okLabel,
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
  }) {
    return showResult(
      title: title,
      message: message,
      isSuccess: true,
      position: position,
      okLabel: okLabel,
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
    );
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
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                Navigator.of(dialogContext, rootNavigator: true).maybePop();
              },
              child: Text(exitLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProtectedDialog({
    Alignment? alignment,
    EdgeInsets? insetPadding,
    Color? backgroundColor,
    required Widget child,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
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
