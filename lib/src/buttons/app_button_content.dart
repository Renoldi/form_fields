library;

import 'package:flutter/material.dart';

import 'app_button_enums.dart';

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
    final textColor = DefaultTextStyle.of(context).style.color ??
        Theme.of(context).textTheme.labelLarge?.color;
    final spinnerSize = _spinnerSize;

    if (type == AppButtonType.icon) {
      return SizedBox(
        width: spinnerSize,
        height: spinnerSize,
        child: isLoading
            ? CircularProgressIndicator(
                strokeWidth: 2,
                color: IconTheme.of(context).color,
              )
            : icon,
      );
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
              color: textColor,
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
