part of '../app_dialog_service.dart';

extension _AppDialogChromeX on AppDialogService {
  Widget _buildLoadingVisual({
    required AppDialogLoadingVisual loadingVisual,
    required AppLoadingVariant loadingVariant,
    required AppProgressType progressType,
    double? progressValue,
    ValueNotifier<double?>? progressNotifier,
  }) {
    if (loadingVisual == AppDialogLoadingVisual.progress) {
      if (progressNotifier != null) {
        return ValueListenableBuilder<double?>(
          valueListenable: progressNotifier,
          builder: (_, value, child) =>
              _buildProgressWidget(progressType: progressType, value: value),
        );
      }
      return _buildProgressWidget(
        progressType: progressType,
        value: progressValue,
      );
    }

    return AppLoadingIndicator(variant: loadingVariant, size: 34);
  }

  Widget _buildProgressWidget({
    required AppProgressType progressType,
    double? value,
  }) {
    if (progressType == AppProgressType.linear) {
      return SizedBox(
        width: 180,
        child: AppProgressIndicator(
          type: AppProgressType.linear,
          value: value,
          minHeight: 8,
        ),
      );
    }
    return AppProgressIndicator(
      type: AppProgressType.circular,
      value: value,
      size: 34,
    );
  }

  Widget _defaultDialogCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  (IconData, Color) _style(
    BuildContext context,
    AppDialogType? type,
    bool isSuccess,
  ) {
    final theme = Theme.of(context);
    if (isSuccess) {
      return (Icons.check_circle, theme.colorScheme.primary);
    }

    if (type == null) {
      return (Icons.error, theme.colorScheme.error);
    }

    switch (type) {
      case AppDialogType.validation:
        return (Icons.warning_outlined, Colors.orange.shade600);
      case AppDialogType.network:
        return (Icons.cloud_off, theme.colorScheme.primary);
      case AppDialogType.authentication:
        return (Icons.lock_outline, theme.colorScheme.error);
      case AppDialogType.server:
        return (Icons.error_outline, theme.colorScheme.error);
    }
  }

  Color _buttonColor(
    BuildContext context,
    AppDialogType? type,
    bool isSuccess,
  ) {
    final theme = Theme.of(context);
    if (isSuccess) return theme.colorScheme.primary;
    if (type == AppDialogType.validation) return Colors.orange.shade600;
    if (type == AppDialogType.network) return theme.colorScheme.primary;
    if (type == AppDialogType.authentication) return theme.colorScheme.error;
    return theme.colorScheme.error;
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
