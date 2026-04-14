library;

import 'package:flutter/material.dart';

import 'app_button_enums.dart';

/// Typed wrapper around Material 3 [SegmentedButton].
class AppSegmentedButton<T> extends StatelessWidget {
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final bool multiSelectionEnabled;
  final bool emptySelectionAllowed;
  final AppButtonSize size;
  final ButtonStyle? style;
  final bool showSelectedIcon;
  final Widget? selectedIcon;

  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.size = AppButtonSize.medium,
    this.style,
    this.showSelectedIcon = true,
    this.selectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: segments,
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      emptySelectionAllowed: emptySelectionAllowed,
      style: _sizeStyle.merge(style),
      showSelectedIcon: showSelectedIcon,
      selectedIcon: selectedIcon,
    );
  }

  ButtonStyle get _sizeStyle {
    switch (size) {
      case AppButtonSize.small:
        return SegmentedButton.styleFrom(
          minimumSize: const Size.fromHeight(36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
        );
      case AppButtonSize.medium:
        return SegmentedButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        );
      case AppButtonSize.large:
        return SegmentedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        );
      case AppButtonSize.custom:
        return SegmentedButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        );
    }
  }
}
