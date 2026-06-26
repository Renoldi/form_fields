// A reusable SafeScaffold widget that places a SafeArea as the parent of Scaffold.
// It exposes common Scaffold properties while providing flexible SafeArea options
// for top/left/right/bottom and minimum padding.

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// A wrapper that places a [SafeArea] as the parent of a [Scaffold].
///
/// - Set [useSafeArea] to `false` to return a plain [Scaffold].
/// - Customize which sides the safe area applies to via [left], [top],
///   [right], and [bottom].
/// - All commonly used [Scaffold] properties are forwarded to the inner
///   [Scaffold], making this widget a drop-in replacement.
class SafeScaffold extends StatelessWidget {
  const SafeScaffold({
    super.key,
    this.useSafeArea = true,
    this.left = false,
    this.top = false,
    this.right = false,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.scaffoldKey,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.endDrawerEnableOpenDragGesture,
    this.drawerEnableOpenDragGesture,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.maintainBottomViewPadding,
  });

  final bool useSafeArea;
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;
  final EdgeInsets minimum;

  // Scaffold properties (commonly used subset)
  final Key? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool? endDrawerEnableOpenDragGesture;
  final bool? drawerEnableOpenDragGesture;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final DragStartBehavior drawerDragStartBehavior;
  final String? restorationId;
  final bool? maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    Widget? effectiveBody = body;
    if (maintainBottomViewPadding == true && body != null) {
      final bottomPad = mq.viewInsets.bottom > 0 ? mq.viewPadding.bottom : 0.0;
      effectiveBody = Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: body,
      );
    }

    final scaffold = Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      body: effectiveBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      endDrawer: endDrawer,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture ?? true,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture ?? true,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerDragStartBehavior: drawerDragStartBehavior,
      restorationId: restorationId,
    );

    if (!useSafeArea) return scaffold;

    return SafeArea(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      minimum: minimum,
      child: scaffold,
    );
  }
}
