import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:form_fields/form_fields.dart';
import '../utilities/theme_helpers.dart';
import 'package:form_fields/src/utilities/debug_log.dart';

part 'app_dialog_service_parts/dialog_flow.dart';
part 'app_dialog_service_parts/dialog_chrome.dart';
part 'app_dialog_service_parts/guard.dart';

class AppDialogService {
  /// Example usage in UI or ViewModel:
  ///
  /// await dialogService.guard(
  ///   task: () async {
  ///     if (formInvalid) throw ValidationException('Mohon lengkapi semua field.');
  ///     // ...proses lain...
  ///   },
  ///   errorTitle: 'Terjadi Kesalahan',
  ///   mapError: customErrorMapper, // from app_dialog_error_utils.dart
  ///   onSuccess: (result) async {
  ///     // Sukses
  ///   },
  ///   onError: (error, msg, type) async {
  ///     // Logging, dsb
  ///   },
  /// );
  /// Shows or hides a visual-only loading dialog without guard or async context.
  /// Call with `show: true` to display, and `show: false` to hide.
  void unguardedLoadingVisualOnly({
    required bool show,
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppDialogLoadingContainer loadingContainer = AppDialogLoadingContainer.card,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    double? progressValue,
    AppDialogPosition position = AppDialogPosition.bottom,
    AppDialogLoadingBackBehavior loadingBackBehavior =
        AppDialogLoadingBackBehavior.allow,
    bool useSafeArea = true,
    String? cancelTitle,
    String? cancelMessage,
    String? stayLabel,
    String? cancelLabel,
  }) {
    if (show) {
      if (_isLoadingDialogVisible) return;
      _isLoadingDialogVisible = true;
      final Widget visual = _buildLoadingVisual(
        loadingVisual: loadingVisual,
        loadingVariant: loadingVariant,
        progressType: progressType,
        progressValue: progressValue,
      );
      final Widget dialogChild =
          loadingContainer == AppDialogLoadingContainer.card
          ? _defaultDialogCard(context, child: visual)
          : visual;
      _showProtectedDialog(
        alignment: _alignment(position),
        insetPadding: _inset(position),
        backgroundColor: Colors.transparent,
        barrierDismissible:
            loadingBackBehavior == AppDialogLoadingBackBehavior.allow,
        useSafeArea: useSafeArea,
        onBackPressed: () => _handleLoadingBackPressed(
          loadingBackBehavior: loadingBackBehavior,
          onCancelRequested: null,
          onCancelled: null,
          cancelTitle: cancelTitle ?? context.formTr('cancelProcessTitle'),
          cancelMessage:
              cancelMessage ?? context.formTr('cancelProcessMessage'),
          stayLabel: stayLabel ?? context.formTr('stay'),
          cancelLabel: cancelLabel ?? context.formTr('cancel'),
        ),
        child: dialogChild,
      ).whenComplete(() {
        _isLoadingDialogVisible = false;
      });
    } else {
      _dismissLoadingIfVisible();
    }
  }

  final BuildContext context;

  /// Shared by every instance. A new `AppDialogService` is created for almost
  /// every call, so a per-instance flag let `hideLoading()` on one instance miss
  /// a loading dialog that another instance had shown, and it stayed on screen.
  static bool _isLoadingDialogVisible = false;

  AppDialogService(this.context);

  /// Error payload used by [guard] for consistent dialog mapping.
  static ({
    String message,
    AppDialogType type,
    Map<String, List<String>>? details,
  })
  defaultErrorMapper(Object error) {
    if (error is ValidationException) {
      return (
        message: error.message,
        type: AppDialogType.validation,
        details: error.details,
      );
    }
    return (
      message: error.toString(),
      type: AppDialogType.server,
      details: null,
    );
  }

  /// Runs an async task and automatically shows an error dialog on failure.
  ///
  /// Returns the task result when successful, otherwise `null`.
  ///
  /// [onSuccess] is called after a successful task (after dialog feedback if enabled).
  /// [onError] is called after a failed task (after error dialog feedback).
  ///
  /// Example:
  /// ```dart
  /// dialogService.guard(
  ///   task: () async => await submitForm(),
  ///   errorTitle: 'Failed',
  ///   mapError: AppDialogService.defaultErrorMapper,
  ///   onSuccess: (result) async {
  ///     // Custom success action
  ///   },
  ///   onError: (error, msg, type) async {
  ///     // Custom error action
  ///   },
  /// );
  /// ```
  Future<T?> guard<T>({
    required Future<T> Function() task,
    required String errorTitle,
    AppDialogErrorMapper? mapError,
    AppDialogPosition loadingPosition = AppDialogPosition.top,
    AppDialogPosition resultPosition = AppDialogPosition.top,
    String? okLabel,
    bool showBlockingLoading = false,
    String? loadingMessage,
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    AppDialogLoadingBackBehavior loadingBackBehavior =
        AppDialogLoadingBackBehavior.block,
    AppDialogCancelRequested? onCancelRequested,
    AppDialogCancelled? onCancelled,
    String? cancelTitle,
    String? cancelMessage,
    String? stayLabel,
    String? cancelLabel,
    bool showSuccessDialog = false,
    String? successTitle,
    String? successMessage,
    AppDialogSuccessCallback<T>? onSuccess,
    AppDialogErrorCallback? onError,
    void Function(Map<String, List<String>> errors)? onValidationError,
  }) => _AppDialogGuard(this).guard(
    task: task,
    errorTitle: errorTitle,
    mapError: mapError,
    loadingPosition: loadingPosition,
    resultPosition: resultPosition,
    okLabel: okLabel,
    showBlockingLoading: showBlockingLoading,
    loadingMessage: loadingMessage,
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
    showSuccessDialog: showSuccessDialog,
    successTitle: successTitle,
    successMessage: successMessage,
    onSuccess: onSuccess,
    onError: onError,
    onValidationError: onValidationError,
  );

  Future<void> showLoading({
    String? message,
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppDialogLoadingContainer loadingContainer = AppDialogLoadingContainer.card,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    double? progressValue,
    ValueNotifier<double?>? progressNotifier,
    AppDialogLoadingBackBehavior loadingBackBehavior =
        AppDialogLoadingBackBehavior.block,
    AppDialogCancelRequested? onCancelRequested,
    AppDialogCancelled? onCancelled,
    String? cancelTitle,
    String? cancelMessage,
    String? stayLabel,
    String? cancelLabel,
    AppDialogPosition position = AppDialogPosition.bottom,
  }) {
    if (_isLoadingDialogVisible) {
      return Future.value();
    }

    _isLoadingDialogVisible = true;
    final displayMessage = message ?? context.formTr('loading');
    // Debug: log locale and resolved loading string to help diagnose localization
    if (kDebugMode) {
      try {
        final loc = Localizations.localeOf(context);
        debugLog(
          'AppDialogService.showLoading - locale: $loc, '
          "messageParam: ${message ?? '<null>'}, resolved: $displayMessage",
        );
      } catch (_) {}
    }
    final Widget visual = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoadingVisual(
          loadingVisual: loadingVisual,
          loadingVariant: loadingVariant,
          progressType: progressType,
          progressValue: progressValue,
          progressNotifier: progressNotifier,
        ),
        if (displayMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              displayMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
    final Widget dialogChild =
        loadingContainer == AppDialogLoadingContainer.card
        ? _defaultDialogCard(context, child: visual)
        : visual;
    return _showProtectedDialog(
      alignment: _alignment(position),
      insetPadding: _inset(position),
      backgroundColor: Colors.transparent,
      onBackPressed: () => _handleLoadingBackPressed(
        loadingBackBehavior: loadingBackBehavior,
        onCancelRequested: onCancelRequested,
        onCancelled: onCancelled,
        cancelTitle: cancelTitle ?? context.formTr('cancelProcessTitle'),
        cancelMessage: cancelMessage ?? context.formTr('cancelProcessMessage'),
        stayLabel: stayLabel ?? context.formTr('stay'),
        cancelLabel: cancelLabel ?? context.formTr('cancel'),
      ),
      barrierDismissible:
          loadingBackBehavior == AppDialogLoadingBackBehavior.allow,
      child: dialogChild,
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
    String? okLabel,
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

  Future<void> showSuccess({
    required String title,
    required String message,
    AppDialogPosition position = AppDialogPosition.top,
    String? okLabel,
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
    String? okLabel,
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
    String? okLabel,
    VoidCallback? onComplete,
  }) {
    final (icon, color) = _style(context, dialogType, isSuccess);
    final buttonColor = _buttonColor(context, dialogType, isSuccess);
    final isWarning = dialogType == AppDialogType.validation && !isSuccess;

    final theme = Theme.of(context);
    final appButtonExt = Theme.of(context).extension<AppButtonThemeData>();
    final themeFilledStyle = Theme.of(context).filledButtonTheme.style;
    final extensionFilledStyle = appButtonExt?.filledStyle;
    final callerFilledStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(buttonColor),
      foregroundColor: WidgetStatePropertyAll(
        isWarning
            ? Theme.of(context).colorScheme.onError
            : Theme.of(context).colorScheme.onPrimary,
      ),
      padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(vertical: 12)),
    );
    final dialogOkButtonStyle = resolveButtonStyle(
      context,
      themeStyle: themeFilledStyle,
      extensionStyle: extensionFilledStyle,
      callerStyle: callerFilledStyle,
    );
    final resolvedOkLabel = okLabel ?? context.formTr('ok');
    return _showProtectedDialog(
      alignment: _alignment(position),
      insetPadding: _inset(position),
      child: _defaultDialogCard(
        context,
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
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                type: AppButtonType.filled,
                text: resolvedOkLabel,
                size: AppSize.medium,
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                style: dialogOkButtonStyle,
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      onComplete?.call();
    });
  }

  Future<void> showExitConfirm({
    String? title,
    String? message,
    String? stayLabel,
    String? exitLabel,
  }) {
    final resolvedTitle = title ?? context.formTr('exitApplication');
    final resolvedMessage = message ?? context.formTr('exitApplicationMessage');
    final resolvedStay = stayLabel ?? context.formTr('stay');
    final resolvedExit = exitLabel ?? context.formTr('exit');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Builder(
            builder: (titleContext) {
              final theme = Theme.of(titleContext);
              return Row(
                children: [
                  Icon(Icons.exit_to_app, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text(resolvedTitle),
                ],
              );
            },
          ),
          content: Text(resolvedMessage),
          actions: [
            SizedBox(
              width: 92,
              child: AppButton(
                type: AppButtonType.outlined,
                size: AppSize.small,
                text: resolvedStay,
                useSafeArea: false,
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(),
              ),
            ),
            SizedBox(
              width: 92,
              child: AppButton(
                type: AppButtonType.filled,
                size: AppSize.small,
                text: resolvedExit,
                useSafeArea: false,
                onPressed: () async => _exitApplication(dialogContext),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hides the currently visible loading dialog, if any.
  void hideLoading() => _dismissLoadingIfVisible();
}
