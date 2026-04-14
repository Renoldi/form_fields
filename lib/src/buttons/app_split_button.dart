library;

import 'package:flutter/material.dart';

import 'app_button_enums.dart';

class AppSplitButtonItem<T> {
  final T value;
  final String label;
  final Widget? leading;

  const AppSplitButtonItem({
    required this.value,
    required this.label,
    this.leading,
  });
}

/// A simple split button with a primary action and dropdown actions.
class AppSplitButton<T> extends StatelessWidget {
  final String text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final List<AppSplitButtonItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool isLoading;

  /// Size preset aligned with [AppButtonSize].
  final AppButtonSize size;

  /// Optional overrides for [size].
  final double? height;
  final double? mainHorizontalPadding;
  final double? dropdownWidth;
  final double? width;
  final bool expand;

  const AppSplitButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.items,
    required this.onSelected,
    this.icon,
    this.isLoading = false,
    this.size = AppButtonSize.medium,
    this.height,
    this.mainHorizontalPadding,
    this.dropdownWidth,
    this.width,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final splitHeight = _resolvedHeight;
    final horizontalPadding = _resolvedMainHorizontalPadding;
    final trailingWidth = _resolvedDropdownWidth;
    final colorScheme = Theme.of(context).colorScheme;

    final leadingButton = FilledButton.icon(
      onPressed: effectiveOnPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : (icon ?? const Icon(Icons.shopping_cart_outlined)),
      label: Text(text),
      style: FilledButton.styleFrom(
        minimumSize: Size(0, splitHeight),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(999),
            bottomLeft: Radius.circular(999),
          ),
        ),
      ),
    );

    final trailingMenu = PopupMenuButton<T>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items
            .map(
              (item) => PopupMenuItem<T>(
                value: item.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.leading != null) ...[
                      item.leading!,
                      const SizedBox(width: 8),
                    ],
                    Text(item.label),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: Container(
        height: splitHeight,
        width: trailingWidth,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          border: Border(
            left: BorderSide(
                color: colorScheme.onPrimary.withValues(alpha: 0.24)),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(999),
            bottomRight: Radius.circular(999),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.keyboard_arrow_down,
          color: colorScheme.onPrimary,
        ),
      ),
    );

    final content = Row(
      mainAxisSize:
          (expand || width != null) ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (expand || width != null)
          Expanded(child: leadingButton)
        else
          leadingButton,
        trailingMenu,
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }

    if (expand) {
      return SizedBox(width: double.infinity, child: content);
    }

    return content;
  }

  double get _resolvedHeight {
    if (height != null) return height!;

    switch (size) {
      case AppButtonSize.small:
        return 44;
      case AppButtonSize.medium:
        return 52;
      case AppButtonSize.large:
        return 58;
      case AppButtonSize.custom:
        return 52;
    }
  }

  double get _resolvedMainHorizontalPadding {
    if (mainHorizontalPadding != null) return mainHorizontalPadding!;

    switch (size) {
      case AppButtonSize.small:
        return 20;
      case AppButtonSize.medium:
        return 28;
      case AppButtonSize.large:
        return 34;
      case AppButtonSize.custom:
        return 28;
    }
  }

  double get _resolvedDropdownWidth {
    if (dropdownWidth != null) return dropdownWidth!;

    switch (size) {
      case AppButtonSize.small:
        return 64;
      case AppButtonSize.medium:
        return 72;
      case AppButtonSize.large:
        return 88;
      case AppButtonSize.custom:
        return 72;
    }
  }
}
