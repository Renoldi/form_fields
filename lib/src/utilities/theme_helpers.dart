import 'package:flutter/material.dart';

/// Utilities for resolving colors from Theme while allowing per-widget overrides.
Color resolveActiveColor(BuildContext context, Color? requested) {
  final theme = Theme.of(context);
  if (requested == null) return theme.colorScheme.primary;
  // If caller left the default Colors.blue, prefer theme primary
  if (requested == Colors.blue) return theme.colorScheme.primary;
  return requested;
}

Color resolveTextColor(BuildContext context,
    {Color? requested, bool muted = false}) {
  final theme = Theme.of(context);
  if (requested != null) return requested;
  if (muted) return theme.disabledColor;
  return theme.textTheme.bodyMedium?.color ?? Colors.black87;
}

Color resolveBorderColor(BuildContext context,
    {Color? requested, bool isError = false, bool focused = false}) {
  final theme = Theme.of(context);
  if (requested != null) return requested;
  if (isError) return theme.colorScheme.error;
  if (focused) return theme.colorScheme.primary;
  return theme.dividerColor;
}

/// Resolve a ButtonStyle using precedence:
/// 1. `themeStyle` (from ThemeData)
/// 2. `extensionStyle` (package/theme extension)
/// 3. `callerStyle` (explicit style passed by caller)
ButtonStyle resolveButtonStyle(BuildContext context,
    {ButtonStyle? themeStyle,
    ButtonStyle? extensionStyle,
    ButtonStyle? callerStyle}) {
  // Use an empty ButtonStyle as neutral base so merge works predictably.
  final base = themeStyle ?? const ButtonStyle();
  final merged = base.merge(extensionStyle).merge(callerStyle);
  return merged;
}
