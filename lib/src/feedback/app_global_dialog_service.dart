library;

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

/// Global dialog coordinator using a navigator key.
///
/// Configure once at app startup, then call dialog APIs from anywhere
/// without passing BuildContext around every layer.
class AppGlobalDialogService {
  AppGlobalDialogService._();

  static final AppGlobalDialogService instance = AppGlobalDialogService._();

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Returns true if the service is configured and context is available.
  bool get isConfigured => _navigatorKey?.currentContext != null;

  /// Configure the global dialog service with your root navigator key.
  ///
  /// Call this once, typically in your main() or app root widget.
  void configure(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Reset the navigator key (for testing or hot reload).
  ///
  /// Warning: After reset, dialogs cannot be shown until reconfigured.
  void reset() {
    _navigatorKey = null;
  }

  /// Returns the current BuildContext from the navigator key.
  BuildContext get context => _requireContext();

  BuildContext _requireContext() {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      throw StateError(
        'AppGlobalDialogService is not configured. '
        'Call AppGlobalDialogService.instance.configure(navigatorKey) '
        'after creating your root navigator key.',
      );
    }
    return context;
  }

  AppDialogService get _service => AppDialogService(_requireContext());

  // --- Dialog API Forwarders ---

  Future<T?> guard<T>({
    required Future<T> Function() task,
    required String errorTitle,
    AppDialogErrorMapper mapError,
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
  }) {
    return _service.guard<T>(
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
    );
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
    bool isMessageLoading = true,
    bool useSafeArea = true,
    VoidCallback? onComplete,
  }) {
    return _service.showLoading(
      message: message,
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
      position: position,
    );
  }

  /// Show a visual-only loading dialog (no message, dismissible by default).
  Future<void> showLoadingVisualOnly({
    AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator,
    AppDialogLoadingContainer loadingContainer = AppDialogLoadingContainer.card,
    AppLoadingVariant loadingVariant = AppLoadingVariant.spinner,
    AppProgressType progressType = AppProgressType.circular,
    AppDialogPosition position = AppDialogPosition.bottom,
    VoidCallback? onComplete,
    AppDialogLoadingBackBehavior loadingBackBehavior =
        AppDialogLoadingBackBehavior.allow,
    bool useSafeArea = true,
    String cancelTitle = 'Cancel Process?',
    String cancelMessage =
        'The operation is still in progress. Do you want to cancel it?',
    String stayLabel = 'Stay',
    String cancelLabel = 'Cancel',
    AppDialogCancelRequested? onCancelRequested,
    AppDialogCancelled? onCancelled,
  }) {
    // Fallback to showLoading with message empty and isMessageLoading false
    return _service.showLoading(
      message: '',
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
      position: position,
    );
  }

  void hide() => _service.hide();

  // --- Result/Info/Error Dialogs ---

  Future<void> showError({
    required String title,
    required String message,
    required AppDialogType dialogType,
    AppDialogPosition position = AppDialogPosition.top,
    String okLabel = 'OK',
  }) {
    return _service.showError(
      title: title,
      message: message,
      dialogType: dialogType,
      position: position,
      okLabel: okLabel,
    );
  }

  Future<void> showSuccess({
    required String title,
    required String message,
    AppDialogPosition position = AppDialogPosition.top,
    String okLabel = 'OK',
  }) {
    return _service.showSuccess(
      title: title,
      message: message,
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
    return _service.showInfo(
      title: title,
      message: message,
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
    return _service.showResult(
      title: title,
      message: message,
      isSuccess: isSuccess,
      dialogType: dialogType,
      position: position,
      okLabel: okLabel,
    );
  }

  Future<void> showExitConfirm({
    String title = 'Exit Application',
    String message =
        'Are you sure you want to close the application? Any unsaved changes may be lost.',
    String stayLabel = 'Stay',
    String exitLabel = 'Exit',
  }) {
    return _service.showExitConfirm(
      title: title,
      message: message,
      stayLabel: stayLabel,
      exitLabel: exitLabel,
    );
  }
}
