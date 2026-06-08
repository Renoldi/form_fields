library;

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class AppButton<T> extends StatelessWidget {
  final AppButtonType type;
  final AppSize size;
  final String? text;
  final Widget? child;
  final Widget? icon;
  final VoidCallback? onPressed;
  final T? value;
  final ValueChanged<T?>? onPressedWithValue;
  final bool isLoading;
  final ButtonStyle? style;

  /// Custom sizing when [size] is [AppSize.custom].
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
    this.onPressed,
    this.value,
    this.onPressedWithValue,
    this.type = AppButtonType.filled,
    this.size = AppSize.medium,
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

    if (withLayout) {
      return AppButtonLayout(
        margin: margin,
        horizontalPadding: horizontalPadding,
        topPadding: topPadding,
        respectSafeArea: respectSafeArea,
        avoidKeyboard: avoidKeyboard,
        child: button,
      );
    }
    // Always wrap with SafeArea if not already handled
    return SafeArea(child: button);
  }

  Widget _buildButton(BuildContext context) {
    final loadingTheme = Theme.of(context).extension<AppLoadingThemeData>() ??
        const AppLoadingThemeData.fallback();
    final isIcon = type == AppButtonType.icon;
    final isFab = type == AppButtonType.fab;
    final isExtendedFab = type == AppButtonType.extendedFab;
    final childWidget = AppButtonContent(
      type: type,
      size: size,
      isLoading: isLoading,
      icon: icon,
      text: text,
      customSpinnerSize: customSpinnerSize,
      child: child,
    );

    final effectiveOnPressed = _effectiveOnPressed;
    // Ambil theme extension jika ada
    final theme = Theme.of(context).extension<AppButtonThemeData>();

    ButtonStyle? themedStyle;
    Color? iconBgColor;
    Color? fabBgColor;
    if (theme != null) {
      switch (type) {
        case AppButtonType.filled:
          themedStyle = theme.filledStyle;
          break;
        case AppButtonType.filledTonal:
          themedStyle = theme.filledTonalStyle;
          break;
        case AppButtonType.elevated:
          themedStyle = theme.elevatedStyle;
          break;
        case AppButtonType.outlined:
          themedStyle = theme.outlinedStyle;
          break;
        case AppButtonType.text:
          themedStyle = theme.textStyle;
          break;
        case AppButtonType.icon:
          themedStyle = theme.iconStyle;
          iconBgColor = theme.iconBackgroundColor;
          break;
        case AppButtonType.fab:
          themedStyle = theme.fabStyle;
          fabBgColor = theme.fabBackgroundColor;
          break;
        case AppButtonType.extendedFab:
          themedStyle = theme.extendedFabStyle;
          fabBgColor = theme.fabBackgroundColor;
          break;
      }
    }
    // Ensure a caller-provided `style` overrides theme styles.
    // `ButtonStyle.merge` prefers the receiver's non-null fields, so
    // calling `style.merge(themedStyle)` makes `style` take precedence.
    final mergedStyle = style?.merge(themedStyle) ?? themedStyle;
    final iconColor = mergedStyle?.foregroundColor?.resolve(<WidgetState>{}) ??
        IconTheme.of(context).color;

    // Ensure icons inside non-icon buttons receive the button's foreground
    // color (e.g. white on filled buttons) by wrapping the content in an
    // IconTheme. If the icon widget specifies its own color it will not be
    // overridden.
    final themedChild =
        IconTheme(data: IconThemeData(color: iconColor), child: childWidget);

    if (isIcon) {
      final double diameter = _heightBySize;
      final double iconSize = _iconSizeBySize;
      if (iconBgColor != null) {
        return Center(
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: effectiveOnPressed,
              customBorder: const CircleBorder(),
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(size: iconSize, color: iconColor),
                    child: icon ?? childWidget,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        return Center(
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: effectiveOnPressed,
              customBorder: const CircleBorder(),
              child: Container(
                width: diameter,
                height: diameter,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(size: iconSize, color: iconColor),
                    child: icon ?? childWidget,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (isFab) {
      final fabChild = isLoading
          ? SizedBox(
              width: _iconSizeBySize,
              height: _iconSizeBySize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: loadingTheme.indicatorColor,
                backgroundColor: loadingTheme.trackColor,
              ),
            )
          : (icon ?? const Icon(Icons.add));
      switch (size) {
        case AppSize.small:
          return FloatingActionButton.small(
            onPressed: effectiveOnPressed,
            backgroundColor: fabBgColor,
            child: fabChild,
          );
        case AppSize.large:
          return FloatingActionButton.large(
            onPressed: effectiveOnPressed,
            backgroundColor: fabBgColor,
            child: fabChild,
          );
        case AppSize.medium:
        case AppSize.custom:
          return FloatingActionButton(
            onPressed: effectiveOnPressed,
            backgroundColor: fabBgColor,
            child: fabChild,
          );
      }
    }

    if (isExtendedFab) {
      return FloatingActionButton.extended(
        onPressed: effectiveOnPressed,
        icon: icon,
        label: child ?? Text(text ?? 'Action'),
        backgroundColor: fabBgColor,
      );
    }

    final button = switch (type) {
      AppButtonType.filled => FilledButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(mergedStyle),
          child: themedChild,
        ),
      AppButtonType.filledTonal => FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(mergedStyle),
          child: themedChild,
        ),
      AppButtonType.elevated => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(mergedStyle),
          child: themedChild,
        ),
      AppButtonType.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(mergedStyle),
          child: themedChild,
        ),
      AppButtonType.text => TextButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(mergedStyle),
          child: themedChild,
        ),
      AppButtonType.icon => const SizedBox.shrink(),
      AppButtonType.fab => const SizedBox.shrink(),
      AppButtonType.extendedFab => const SizedBox.shrink(),
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

  VoidCallback? get _effectiveOnPressed {
    if (isLoading) return null;
    if (onPressedWithValue != null) {
      return () => onPressedWithValue!(value);
    }
    return onPressed;
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

  double get _heightBySize {
    switch (size) {
      case AppSize.small:
        return kFieldHeightSmall;
      case AppSize.medium:
        return kFieldHeightMedium;
      case AppSize.large:
        return kFieldHeightLarge;
      case AppSize.custom:
        return customHeight ?? kFieldHeightDefault;
    }
  }

  double get _horizontalPaddingBySize {
    switch (size) {
      case AppSize.small:
        return 12;
      case AppSize.medium:
        return 16;
      case AppSize.large:
        return 20;
      case AppSize.custom:
        return customHorizontalPadding ?? 16;
    }
  }

  double get _iconSizeBySize {
    switch (size) {
      case AppSize.small:
        return 18;
      case AppSize.medium:
        return 20;
      case AppSize.large:
        return 24;
      case AppSize.custom:
        return customIconSize ?? 20;
    }
  }
}
