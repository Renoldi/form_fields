library;

import 'package:flutter/material.dart';

import 'app_button_content.dart';
import 'app_button_enums.dart';
import 'app_button_layout.dart';

class AppButton extends StatelessWidget {
  final AppButtonType type;
  final AppButtonSize size;
  final String? text;
  final Widget? child;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle? style;

  /// Custom sizing when [size] is [AppButtonSize.custom].
  final double? customHeight;
  final double? customHorizontalPadding;
  final double? customIconSize;
  final double? customSpinnerSize;

  /// Wrap with [AppButtonLayout] to automatically handle safe area and keyboard.
  final bool withLayout;
  final EdgeInsetsGeometry? margin;
  final double horizontalPadding;
  final double topPadding;
  final bool respectSafeArea;
  final bool avoidKeyboard;

  const AppButton({
    super.key,
    required this.onPressed,
    this.type = AppButtonType.filled,
    this.size = AppButtonSize.medium,
    this.text,
    this.child,
    this.icon,
    this.isLoading = false,
    this.style,
    this.customHeight,
    this.customHorizontalPadding,
    this.customIconSize,
    this.customSpinnerSize,
    this.withLayout = false,
    this.margin,
    this.horizontalPadding = 16,
    this.topPadding = 12,
    this.respectSafeArea = true,
    this.avoidKeyboard = true,
  }) : assert(
          text != null || child != null || icon != null,
          'Provide at least one of text, child, or icon.',
        );

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);

    if (!withLayout) return button;

    return AppButtonLayout(
      margin: margin,
      horizontalPadding: horizontalPadding,
      topPadding: topPadding,
      respectSafeArea: respectSafeArea,
      avoidKeyboard: avoidKeyboard,
      child: button,
    );
  }

  Widget _buildButton(BuildContext context) {
    final isIcon = type == AppButtonType.icon;
    final childWidget = AppButtonContent(
      type: type,
      size: size,
      isLoading: isLoading,
      icon: icon,
      text: text,
      customSpinnerSize: customSpinnerSize,
      child: child,
    );

    final effectiveOnPressed = isLoading ? null : onPressed;

    if (isIcon) {
      return IconButton(
        onPressed: effectiveOnPressed,
        style: _iconButtonStyle().merge(style),
        icon: childWidget,
      );
    }

    final button = switch (type) {
      AppButtonType.filled => FilledButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(style),
          child: childWidget,
        ),
      AppButtonType.elevated => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(style),
          child: childWidget,
        ),
      AppButtonType.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(style),
          child: childWidget,
        ),
      AppButtonType.text => TextButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(style),
          child: childWidget,
        ),
      AppButtonType.icon => const SizedBox.shrink(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite;

        if (!hasFiniteWidth) {
          return button;
        }

        return SizedBox(width: constraints.maxWidth, child: button);
      },
    );
  }

  ButtonStyle _buttonStyle() {
    final height = _heightBySize;
    final horizontalPadding = _horizontalPaddingBySize;

    return ButtonStyle(
      // Keep a fixed minimum height but do not force infinite width in
      // unbounded parents like Row.
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
    );
  }

  ButtonStyle _iconButtonStyle() {
    final dimension = _heightBySize;
    final iconSize = _iconSizeBySize;

    return ButtonStyle(
      fixedSize: WidgetStatePropertyAll(Size.square(dimension)),
      iconSize: WidgetStatePropertyAll(iconSize),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );
  }

  double get _heightBySize {
    switch (size) {
      case AppButtonSize.small:
        return 40;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
      case AppButtonSize.custom:
        return customHeight ?? 48;
    }
  }

  double get _horizontalPaddingBySize {
    switch (size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 20;
      case AppButtonSize.custom:
        return customHorizontalPadding ?? 16;
    }
  }

  double get _iconSizeBySize {
    switch (size) {
      case AppButtonSize.small:
        return 18;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
      case AppButtonSize.custom:
        return customIconSize ?? 20;
    }
  }
}
