library;

import 'package:flutter/material.dart';

import 'app_dialog_service.dart';
import 'app_dialog_service_types.dart';
import 'app_loading_progress_enums.dart';

/// Global dialog coordinator using a navigator key.
///
/// Configure once at app startup, then call dialog APIs from anywhere
/// without passing BuildContext around every layer.
class AppGlobalDialogService {
  AppGlobalDialogService._();

  static final AppGlobalDialogService instance = AppGlobalDialogService._();

  GlobalKey<NavigatorState>? _navigatorKey;

  bool get isConfigured => _navigatorKey?.currentContext != null;

  void configure(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  void reset() {
    _navigatorKey = null;
  }

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
      position: position,
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
    );
  }

  void hide() => _service.hide();

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
