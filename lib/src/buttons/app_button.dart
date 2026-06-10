library;

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import '../utilities/theme_helpers.dart';

/// A flexible, theme-aware button wrapper used across the app.
///
/// Usage notes:
/// - By default `AppButton` wraps its content with a `SafeArea` to avoid
///   overlapping system UI (status bar, notches) when used in full-screen
///   layouts. This is appropriate for most on-screen buttons.
/// - When placing buttons inside platform dialogs (e.g. `AlertDialog`)
///   the dialog already manages insets and intrinsic sizing. In those
///   cases `SafeArea` can cause layout conflicts. Set `useSafeArea: false`
///   for dialog actions and control sizing from the caller (for example
///   by wrapping the `AppButton` in a `SizedBox`).
///
/// Example (dialog action):
/// ```dart
/// SizedBox(
///   width: 96,
///   child: AppButton(
///     useSafeArea: false,
///     size: AppSize.small,
///     text: 'OK',
///     onPressed: () => Navigator.pop(context),
///   ),
/// )
/// ```
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

  /// When true (default) the button is wrapped with `SafeArea` to avoid
  /// system insets. Set to false when the parent (like an `AlertDialog`)
  /// already manages layout/insets and you need full control over sizing.
  final bool useSafeArea;

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
    this.useSafeArea = true,
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
    // Optionally wrap with SafeArea if not already handled
    return useSafeArea ? SafeArea(child: button) : button;
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
      text: text.toBegin,
      customSpinnerSize: customSpinnerSize,
      child: child,
    );

    final effectiveOnPressed = _effectiveOnPressed;
    // Ambil theme extension jika ada
    final theme = Theme.of(context).extension<AppButtonThemeData>();

    ButtonStyle? themedStyle;
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
    // Resolve styles from multiple sources with this precedence (low->high):
    // 1) Framework `ThemeData` button themes (e.g. Filled/Elevated/Text/Outlined)
    // 2) Our `AppButtonThemeData` extension (`themedStyle`) if present
    // 3) Caller-provided `style` (highest priority)
    ButtonStyle? themeDataStyle;
    final themeData = Theme.of(context);
    switch (type) {
      case AppButtonType.filled:
      case AppButtonType.filledTonal:
        themeDataStyle = themeData.filledButtonTheme.style;
        break;
      case AppButtonType.elevated:
        themeDataStyle = themeData.elevatedButtonTheme.style;
        break;
      case AppButtonType.outlined:
        themeDataStyle = themeData.outlinedButtonTheme.style;
        break;
      case AppButtonType.text:
        themeDataStyle = themeData.textButtonTheme.style;
        break;
      default:
        themeDataStyle = null;
    }

    // Resolve merged ButtonStyle with precedence: ThemeData <- extension <- caller
    final mergedStyle = resolveButtonStyle(
      context,
      themeStyle: themeDataStyle,
      extensionStyle: themedStyle,
      callerStyle: style,
    );

    // If the caller provided a `textStyle` with an explicit color but did
    // not provide `foregroundColor`, prefer the `textStyle` color for the
    // button foreground so callers who set `textStyle(color: ...)` see that
    // color applied (Flutter buttons use `foregroundColor` to color text
    // and icons, which can otherwise override `textStyle.color`). We'll
    // create an adjusted style that sets `foregroundColor` from the
    // resolved `textStyle.color` when appropriate.
    ButtonStyle? effectiveMergedStyle = mergedStyle;
    final resolvedTextStyle = mergedStyle.textStyle?.resolve(<WidgetState>{});
    final resolvedTextColor = resolvedTextStyle?.color;
    final callerHasForeground = style?.foregroundColor != null;
    if (resolvedTextColor != null && style != null && !callerHasForeground) {
      effectiveMergedStyle = mergedStyle.copyWith(
        foregroundColor: WidgetStatePropertyAll(resolvedTextColor),
      );
    }

    final iconColor =
        effectiveMergedStyle.foregroundColor?.resolve(<WidgetState>{}) ??
            IconTheme.of(context).color;

    // Ensure icons inside non-icon buttons receive the button's foreground
    // color (e.g. white on filled buttons) by wrapping the content in an
    // IconTheme. Also apply a DefaultTextStyle merge using the resolved
    // foreground color so plain `Text` widgets inside `AppButtonContent`
    // pick up caller `textStyle.color` when provided.
    final resolvedForegroundColor =
        effectiveMergedStyle.foregroundColor?.resolve(<WidgetState>{});
    final themedChild = DefaultTextStyle.merge(
      style: TextStyle(color: resolvedForegroundColor),
      child:
          IconTheme(data: IconThemeData(color: iconColor), child: childWidget),
    );

    if (isIcon) {
      final double iconSize = _iconSizeBySize;

      // If the caller provided a ButtonStyle (or a themed style was
      // resolved into `effectiveMergedStyle`), prefer rendering a
      // material button that honors that style so properties like
      // `shape`, `padding`, and `fixedSize` are applied.
      final ButtonStyle styleForIcon =
          _buttonStyle().merge(effectiveMergedStyle);

      return Center(
        child: FilledButton(
          onPressed: effectiveOnPressed,
          style: styleForIcon,
          child: IconTheme(
            data: IconThemeData(size: iconSize, color: iconColor),
            child: icon ?? childWidget,
          ),
        ),
      );
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

      // Resolve FAB colors by merging (low->high): ThemeData.floatingActionButtonTheme
      // -> AppButtonThemeData extension -> caller `style` (ButtonStyle).
      final floatingFabTheme = Theme.of(context).floatingActionButtonTheme;
      Color? resolvedFabBg = floatingFabTheme.backgroundColor;
      Color? resolvedFabFg = floatingFabTheme.foregroundColor;

      // extension-provided background (from earlier `fabBgColor`)
      if (fabBgColor != null) resolvedFabBg = fabBgColor;

      // allow caller ButtonStyle to override when present
      final styleBg =
          effectiveMergedStyle.backgroundColor?.resolve(<WidgetState>{});
      final styleFg =
          effectiveMergedStyle.foregroundColor?.resolve(<WidgetState>{});
      if (styleBg != null) resolvedFabBg = styleBg;
      if (styleFg != null) resolvedFabFg = styleFg;

      final iconWidget = IconTheme(
        data: IconThemeData(
            size: _iconSizeBySize,
            color: resolvedFabFg ?? IconTheme.of(context).color),
        child: fabChild,
      );

      switch (size) {
        case AppSize.small:
          return FloatingActionButton.small(
            onPressed: effectiveOnPressed,
            backgroundColor: resolvedFabBg,
            child: iconWidget,
          );
        case AppSize.large:
          return FloatingActionButton.large(
            onPressed: effectiveOnPressed,
            backgroundColor: resolvedFabBg,
            child: iconWidget,
          );
        case AppSize.medium:
        case AppSize.custom:
          return FloatingActionButton(
            onPressed: effectiveOnPressed,
            backgroundColor: resolvedFabBg,
            child: iconWidget,
          );
      }
    }

    if (isExtendedFab) {
      // Resolve FAB colors similarly to the regular FAB branch.
      final floatingFabTheme = Theme.of(context).floatingActionButtonTheme;
      Color? resolvedFabBgExt = floatingFabTheme.backgroundColor;
      Color? resolvedFabFgExt = floatingFabTheme.foregroundColor;
      if (fabBgColor != null) resolvedFabBgExt = fabBgColor;
      final styleBgExt =
          effectiveMergedStyle.backgroundColor?.resolve(<WidgetState>{});
      final styleFgExt =
          effectiveMergedStyle.foregroundColor?.resolve(<WidgetState>{});
      if (styleBgExt != null) resolvedFabBgExt = styleBgExt;
      if (styleFgExt != null) resolvedFabFgExt = styleFgExt;

      final labelWidget = child ??
          DefaultTextStyle(
            style: TextStyle(
                color: resolvedFabFgExt ?? IconTheme.of(context).color),
            child: Text((text ?? 'Action').toTitleCase),
          );

      return FloatingActionButton.extended(
        onPressed: effectiveOnPressed,
        icon: icon,
        label: labelWidget,
        backgroundColor: resolvedFabBgExt,
      );
    }

    final button = switch (type) {
      AppButtonType.filled => FilledButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(effectiveMergedStyle),
          child: themedChild,
        ),
      AppButtonType.filledTonal => FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(effectiveMergedStyle),
          child: themedChild,
        ),
      AppButtonType.elevated => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(effectiveMergedStyle),
          child: themedChild,
        ),
      AppButtonType.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(effectiveMergedStyle),
          child: themedChild,
        ),
      AppButtonType.text => TextButton(
          onPressed: effectiveOnPressed,
          style: _buttonStyle().merge(effectiveMergedStyle),
          child: themedChild,
        ),
      AppButtonType.icon => const SizedBox.shrink(),
      AppButtonType.fab => const SizedBox.shrink(),
      AppButtonType.extendedFab => const SizedBox.shrink(),
    };

    return button;
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
