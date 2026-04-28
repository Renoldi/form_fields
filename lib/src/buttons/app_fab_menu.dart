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

/// A compact expandable FAB menu that floats items above the button
/// using [Overlay] + [CompositedTransformFollower]. No Scaffold required.
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

class _AppFabMenuState extends State<AppFabMenu>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggle() {
    if (_isOpen) {
      _controller.reverse().then((_) {
        _removeOverlay();
        if (mounted) setState(() => _isOpen = false);
      });
    } else {
      setState(() => _isOpen = true);
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _controller.forward(from: 0);
    }
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggle,
              child: const SizedBox.expand(),
            ),
          ),
          // Items floating above the FAB
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, -8),
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => ClipRect(
                child: Align(
                  alignment: Alignment.bottomRight,
                  heightFactor: _animation.value,
                  child: child,
                ),
              ),
              child: FadeTransition(
                opacity: _animation,
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: widget.items
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildItemRow(item),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(AppFabMenuItem item) {
    void onPress() {
      item.onPressed();
      _toggle();
    }

    final fab = switch (widget.size) {
      AppButtonSize.small => FloatingActionButton.small(
          heroTag: null,
          onPressed: onPress,
          child: item.icon,
        ),
      AppButtonSize.large => FloatingActionButton.large(
          heroTag: null,
          onPressed: onPress,
          child: item.icon,
        ),
      _ => FloatingActionButton(
          heroTag: null,
          onPressed: onPress,
          child: item.icon,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(item.label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 8),
        fab,
      ],
    );
  }

  Widget _buildMainFab() {
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => RotationTransition(
        turns: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: _isOpen
          ? const Icon(Icons.close, key: ValueKey('close'))
          : (widget.mainIcon ??
              const Icon(Icons.add, key: ValueKey('open'))),
    );

    return switch (widget.size) {
      AppButtonSize.small => FloatingActionButton.small(
          heroTag: null,
          onPressed: _toggle,
          child: icon,
        ),
      AppButtonSize.large => FloatingActionButton.large(
          heroTag: null,
          onPressed: _toggle,
          child: icon,
        ),
      _ => FloatingActionButton(
          heroTag: null,
          onPressed: _toggle,
          child: icon,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: _buildMainFab(),
    );
  }
}
