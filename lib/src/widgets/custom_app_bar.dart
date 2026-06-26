import 'package:flutter/material.dart';

/// A customizable app bar that implements [PreferredSizeWidget].
///
/// Designed as a drop-in replacement for `Scaffold.appBar` when you need a
/// slightly taller, rounded-bottom app bar similar to the provided screenshot.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.height = 96.0,
    this.borderRadius = 16.0,
    this.centerTitle = false,
    this.elevation = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final bool centerTitle;
  final double elevation;
  final EdgeInsets padding;

  const CustomAppBar._internal({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.height = 96.0,
    this.borderRadius = 16.0,
    this.centerTitle = false,
    this.elevation = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
  });

  // Provide a standard constructor that sets preferredSize correctly.
  factory CustomAppBar.standard({
    Key? key,
    String? title,
    Widget? titleWidget,
    Widget? leading,
    List<Widget>? actions,
    Color? backgroundColor,
    double height = 96.0,
    double borderRadius = 16.0,
    bool centerTitle = false,
    double elevation = 0,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12.0),
  }) {
    return CustomAppBar._internal(
      key: key,
      title: title,
      titleWidget: titleWidget,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor,
      height: height,
      borderRadius: borderRadius,
      centerTitle: centerTitle,
      elevation: elevation,
      padding: padding,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Theme.of(context).primaryColor;

    Widget buildLeading() {
      if (leading != null) return leading!;
      if (Navigator.canPop(context)) {
        return const BackButton(color: Colors.white);
      }
      return const SizedBox.shrink();
    }

    final Widget titleChild = titleWidget ??
        Text(
          title ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        );

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      child: Container(
        height: preferredSize.height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(borderRadius),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: padding.copyWith(top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48),
                  child: Align(
                      alignment: Alignment.centerLeft, child: buildLeading()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: centerTitle
                      ? Center(child: titleChild)
                      : Align(
                          alignment: Alignment.centerLeft, child: titleChild),
                ),
                if (actions != null) ...[
                  const SizedBox(width: 8),
                  Row(children: actions!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alias constructor to keep usage simple
typedef PreferredAppBar = CustomAppBar;
