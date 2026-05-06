library;

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class AppButtonContent extends StatelessWidget {
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final String? text;
  final Widget? child;
  final double? customSpinnerSize;

  const AppButtonContent({
    super.key,
    required this.type,
    required this.size,
    this.isLoading = false,
    this.icon,
    this.text,
    this.child,
    this.customSpinnerSize,
  });

  @override
  Widget build(BuildContext context) {
    final loadingTheme = Theme.of(context).extension<AppLoadingThemeData>() ??
        const AppLoadingThemeData.fallback();
    final spinnerSize = _spinnerSize;

    if (type == AppButtonType.icon) {
      if (isLoading) {
        return SizedBox(
          width: spinnerSize,
          height: spinnerSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: loadingTheme.indicatorColor,
            backgroundColor: loadingTheme.trackColor,
          ),
        );
      }
      // Icon size akan diatur oleh IconTheme di AppButton
      return icon ?? const SizedBox.shrink();
    }

    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: loadingTheme.indicatorColor,
              backgroundColor: loadingTheme.trackColor,
            ),
          ),
          if (_hasLabelOrChild) const SizedBox(width: 10),
          Flexible(child: _buildLabel(context)),
        ],
      );
    }

    if (icon != null && _hasLabelOrChild) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Flexible(child: _buildLabel(context)),
        ],
      );
    }

    if (icon != null) return icon!;

    return _buildLabel(context);
  }

  bool get _hasLabelOrChild =>
      (text != null && text!.trim().isNotEmpty) || child != null;

  Widget _buildLabel(BuildContext context) {
    if (child != null) return child!;
    return Text(
      text ?? 'Button',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }

  double get _spinnerSize {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
      case AppButtonSize.custom:
        return customSpinnerSize ?? 18;
    }
  }
}
