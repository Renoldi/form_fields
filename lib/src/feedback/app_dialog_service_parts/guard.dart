part of '../app_dialog_service.dart';

/// Runs [AppDialogService.guard]: wraps a task with loading, error, and result
/// dialogs. Internal; the public method on [AppDialogService] delegates here.
class _AppDialogGuard {
  _AppDialogGuard(this._service);

  final AppDialogService _service;

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
  }) async {
    var loadingShown = false;

    // Resolve localized fallbacks before any await to avoid using
    // `_service.context` across async gaps (prevents use_build_context_synchronously).
    final resolvedSuccessTitle =
        successTitle ?? _service.context.formTr('success');
    final resolvedSuccessMessage =
        successMessage ?? _service.context.formTr('successMessage');

    try {
      if (showBlockingLoading) {
        loadingShown = true;
        unawaited(
          _service.showLoading(
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
          ),
        );
        // Give Flutter one frame to paint the blocking dialog
        // before starting the long-running task.
        await WidgetsBinding.instance.endOfFrame;
      }

      final result = await task();
      if (showSuccessDialog) {
        await _service.showSuccess(
          title: resolvedSuccessTitle,
          message: resolvedSuccessMessage,
          position: resultPosition,
          okLabel: okLabel,
        );
      }
      await onSuccess?.call(result);
      return result;
    } catch (error) {
      _service._dismissLoadingIfVisible();
      loadingShown = false;

      final mapped = (mapError ?? AppDialogService.defaultErrorMapper)(error);
      if (mapped.type == AppDialogType.validation) {
        Map<String, List<String>>? validationErrors;
        if (error is ValidationException && error.details != null) {
          validationErrors = error.details;
        } else if ((mapped as dynamic).details != null) {
          validationErrors =
              (mapped as dynamic).details as Map<String, List<String>>?;
        }
        if (validationErrors != null) onValidationError?.call(validationErrors);
        await _service.showInfo(
          title: errorTitle,
          message: mapped.message,
          position: resultPosition,
          okLabel: okLabel,
        );
      } else {
        await _service.showError(
          title: errorTitle,
          message: mapped.message,
          dialogType: mapped.type,
          position: resultPosition,
          okLabel: okLabel,
        );
      }
      await onError?.call(error, mapped.message, mapped.type);
      return null;
    } finally {
      if (loadingShown) {
        _service._dismissLoadingIfVisible();
      }
    }
  }
}
