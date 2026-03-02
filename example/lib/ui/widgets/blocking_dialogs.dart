import 'package:flutter/material.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:form_fields_example/config/error_position.dart';
import 'package:form_fields_example/config/error_type.dart';

class BlockingDialog {
  final BuildContext context;

  BlockingDialog(this.context);

  Future<void> showLoading({String? message}) {
    final displayMessage = message ?? context.tr('password');
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await showExitConfirm();
          },
          child: Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        displayMessage,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void hide() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Show error dialog with automatic styling based on error type
  Future<void> showError({
    required String title,
    required String message,
    required ErrorType errorType,
    ErrorPosition? errorPosition,
  }) =>
      showResult(
        title: title,
        message: message,
        isSuccess: false,
        errorType: errorType,
        errorPosition: errorPosition,
      );

  /// Show success dialog
  Future<void> showSuccess({
    required String title,
    required String message,
    ErrorPosition? errorPosition,
  }) =>
      showResult(
        title: title,
        message: message,
        isSuccess: true,
        errorPosition: errorPosition,
      );

  /// Show info dialog with info-specific styling
  Future<void> showInfo({
    required String title,
    required String message,
    ErrorPosition? errorPosition,
  }) =>
      showResult(
        title: title,
        message: message,
        isSuccess: false,
        errorType: ErrorType.validation,
        errorPosition: errorPosition,
      );

  Future<void> showResult({
    required String title,
    required String message,
    required bool isSuccess,
    ErrorType? errorType,
    ErrorPosition? errorPosition,
  }) {
    // Determine styling based on errorType or isSuccess
    final (icon, color) = _getStyleByErrorType(errorType, isSuccess);

    // Get error position from parameter or AppState
    final position = errorPosition ?? ErrorPosition.top;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await showExitConfirm();
          },
          child: Dialog(
            alignment: _getAlignmentByPosition(position),
            insetPadding: _getInsetByPosition(position),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
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
                        context.tr('ok'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  (IconData, Color) _getStyleByErrorType(ErrorType? type, bool isSuccess) {
    if (isSuccess) {
      return (Icons.check_circle, Colors.green.shade600);
    }

    if (type == null) {
      return (Icons.error, Colors.red.shade600);
    }

    switch (type) {
      case ErrorType.validation:
        return (Icons.warning_outlined, Colors.orange.shade600);
      case ErrorType.network:
        return (Icons.cloud_off, Colors.blue.shade600);
      case ErrorType.authentication:
        return (Icons.lock_outline, Colors.red.shade700);
      case ErrorType.server:
        return (Icons.error_outline, Colors.red.shade600);
    }
  }

  Alignment _getAlignmentByPosition(ErrorPosition position) {
    switch (position) {
      case ErrorPosition.top:
        return Alignment.topCenter;
      case ErrorPosition.center:
        return Alignment.center;
      case ErrorPosition.bottom:
        return Alignment.bottomCenter;
    }
  }

  EdgeInsets _getInsetByPosition(ErrorPosition position) {
    switch (position) {
      case ErrorPosition.top:
        return const EdgeInsets.fromLTRB(16, 80, 16, 0);
      case ErrorPosition.center:
        return const EdgeInsets.symmetric(horizontal: 16);
      case ErrorPosition.bottom:
        return const EdgeInsets.fromLTRB(16, 0, 16, 80);
    }
  }

  Future<void> showExitConfirm() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(context.tr('exitApplication')),
            ],
          ),
          content: Text(
            context.tr('exitWarning'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(context.tr('stay')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context, rootNavigator: true).maybePop();
              },
              child: Text(context.tr('exit')),
            ),
          ],
        );
      },
    );
  }
}
