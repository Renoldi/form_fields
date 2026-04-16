import 'package:flutter/material.dart';

/// A reusable, beautiful, and keyboard-aware modal bottom sheet.
///
/// - Always uses SafeArea and bottom padding for keyboard.
/// - Accepts all [showModalBottomSheet] parameters for full flexibility.
/// - Easy to use across your project: just import and call.
///
/// Example:
/// ```dart
/// showAppModalBottomSheet(
///   context: context,
///   builder: (ctx) => YourWidget(),
///   shape: RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
///   ),
/// );
/// ```
Future<T?> showAppModalBottomSheet<T>({
  // Required
  required BuildContext context,
  required WidgetBuilder builder,

  // Appearance
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  bool? showDragHandle,

  // Behavior
  bool isScrollControlled = true,
  double scrollControlDisabledMaxHeightRatio = 9 / 16,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
  bool? requestFocus,

  // Animation & Routing
  AnimationController? transitionAnimationController,
  AnimationStyle? sheetAnimationStyle,
  Offset? anchorPoint,
  RouteSettings? routeSettings,

  // Barrier
  Color? barrierColor,
  String? barrierLabel,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      final child = builder(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: child,
      );
    },
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    showDragHandle: showDragHandle,
    isScrollControlled: isScrollControlled,
    scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    requestFocus: requestFocus,
    transitionAnimationController: transitionAnimationController,
    sheetAnimationStyle: sheetAnimationStyle,
    anchorPoint: anchorPoint,
    routeSettings: routeSettings,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
  );
}
