library;

import 'package:flutter/material.dart';

import 'app_button_enums.dart';

class AppFabMenuItem {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const AppFabMenuItem({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

/// A compact expandable FAB menu for related quick actions.
class AppFabMenu extends StatefulWidget {
  final List<AppFabMenuItem> items;
  final Widget? mainIcon;
  final AppButtonSize size;

  const AppFabMenu({
    super.key,
    required this.items,
    this.mainIcon,
    this.size = AppButtonSize.medium,
  });

  @override
  State<AppFabMenu> createState() => _AppFabMenuState();
}

class _AppFabMenuState extends State<AppFabMenu> {
  bool _isOpen = false;

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in widget.items.reversed) ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isOpen
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item.label),
                        ),
                        const SizedBox(width: 8),
                        _buildMenuFab(item),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
        _buildMainFab(),
      ],
    );
  }

  Widget _buildMenuFab(AppFabMenuItem item) {
    switch (widget.size) {
      case AppButtonSize.small:
        return FloatingActionButton.small(
          onPressed: () {
            item.onPressed();
            _toggle();
          },
          child: item.icon,
        );
      case AppButtonSize.large:
        return FloatingActionButton.large(
          onPressed: () {
            item.onPressed();
            _toggle();
          },
          child: item.icon,
        );
      case AppButtonSize.medium:
      case AppButtonSize.custom:
        return FloatingActionButton(
          onPressed: () {
            item.onPressed();
            _toggle();
          },
          child: item.icon,
        );
    }
  }

  Widget _buildMainFab() {
    switch (widget.size) {
      case AppButtonSize.small:
        return FloatingActionButton.small(
          onPressed: _toggle,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            turns: _isOpen ? 0.125 : 0,
            child: widget.mainIcon ?? const Icon(Icons.add),
          ),
        );
      case AppButtonSize.large:
        return FloatingActionButton.large(
          onPressed: _toggle,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            turns: _isOpen ? 0.125 : 0,
            child: widget.mainIcon ?? const Icon(Icons.add),
          ),
        );
      case AppButtonSize.medium:
      case AppButtonSize.custom:
        return FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            turns: _isOpen ? 0.125 : 0,
            child: widget.mainIcon ?? const Icon(Icons.add),
          ),
        );
    }
  }
}
