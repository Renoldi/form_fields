library;

import 'package:flutter/material.dart';

/// Typed wrapper around Material 3 [SegmentedButton].
class AppSegmentedButton<T> extends StatelessWidget {
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final bool multiSelectionEnabled;
  final bool emptySelectionAllowed;
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
      style: style,
      showSelectedIcon: showSelectedIcon,
      selectedIcon: selectedIcon,
    );
  }
}
