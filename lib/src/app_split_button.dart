library;

import 'package:flutter/material.dart';

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

  const AppSplitButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.items,
    required this.onSelected,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite;

        final row = Row(
          mainAxisSize: hasFiniteWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (hasFiniteWidth)
              Expanded(
                child: FilledButton.icon(
                  onPressed: effectiveOnPressed,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (icon ?? const Icon(Icons.shopping_cart_outlined)),
                  label: Text(text),
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(999),
                        bottomLeft: Radius.circular(999),
                      ),
                    ),
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: effectiveOnPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (icon ?? const Icon(Icons.shopping_cart_outlined)),
                label: Text(text),
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(999),
                      bottomLeft: Radius.circular(999),
                    ),
                  ),
                ),
              ),
            PopupMenuButton<T>(
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
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(999),
                    bottomRight: Radius.circular(999),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );

        return row;
      },
    );
  }
}
