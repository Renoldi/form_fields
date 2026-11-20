/// Shared layout pieces for the selection fields (checkbox and radio button).
///
/// Both fields arrange a label, a bordered container and an error message the
/// same way, and style their items the same way. Those pieces live here once.
/// What differs between the fields (the item widget, the error message and
/// its color) stays in each field.
library;

import 'package:material_ui/material_ui.dart';
import 'package:form_fields/src/utilities/enums.dart';
import 'package:form_fields/src/utilities/extensions.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';

/// Label with an optional required asterisk. It turns to the error color when
/// [hasError] is true.
Widget buildSelectionLabel({
  required BuildContext context,
  required String label,
  required bool isRequired,
  required bool hasError,
  TextStyle? textStyle,
}) {
  final theme = Theme.of(context);
  return RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: label.toTitleCases,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError
                ? theme.colorScheme.error
                : (textStyle?.color ?? resolveTextColor(context)),
          ),
        ),
        if (isRequired)
          TextSpan(
            text: ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    ),
  );
}

/// Border around the whole field. There is none when the field draws its own
/// item borders or when [borderType] is [BorderType.none].
Border? selectionContainerBorder({
  required BuildContext context,
  required Color? itemBorderColor,
  required BorderType borderType,
  required bool hasError,
}) {
  if (itemBorderColor != null) return null;
  if (borderType == BorderType.none) return null;
  final theme = Theme.of(context);
  return Border.all(
    color: hasError ? theme.colorScheme.error : theme.dividerColor,
    width: 1.5,
  );
}

/// Text color for an item: the selected color when selected, otherwise a muted
/// version of the text style color.
Color selectionItemTextColor(
  BuildContext context, {
  required bool selected,
  Color? selectedItemTextColor,
  TextStyle? textStyle,
}) {
  if (selected) {
    return selectedItemTextColor ??
        textStyle?.color ??
        resolveTextColor(context);
  }
  return textStyle?.color != null
      ? textStyle!.color!.withValues(alpha: 0.7)
      : resolveTextColor(context, muted: true);
}

/// Cross-axis alignment of an item's indicator and text.
CrossAxisAlignment selectionCrossAxisAlignment(
  IndicatorVerticalAlignment alignment,
) {
  switch (alignment) {
    case IndicatorVerticalAlignment.top:
      return CrossAxisAlignment.start;
    case IndicatorVerticalAlignment.center:
      return CrossAxisAlignment.center;
    case IndicatorVerticalAlignment.bottom:
      return CrossAxisAlignment.end;
  }
}

/// Error message under the field. [errorText] is shown when it is not empty,
/// otherwise [fallbackMessage]. Renders nothing when there is no error.
Widget selectionErrorWidget({
  required bool hasError,
  required String? errorText,
  required String fallbackMessage,
  required Color color,
}) {
  if (!hasError) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      (errorText != null && errorText.isNotEmpty) ? errorText : fallbackMessage,
      style: TextStyle(color: color, fontSize: 12),
    ),
  );
}

/// Places the label, the field and the optional error slot according to
/// [labelPosition].
///
/// The fields differ in a few details, and those are options here so each one
/// keeps its exact layout:
/// - [sideGap] is the space between a side label and the field, for the left
///   and right positions (the single dropdown uses 12). Top and bottom always
///   use 8.
/// - [error] is the slot below the field. `null` means the field has none.
/// - [intrinsicLabel] sizes the side label to its own width. The single
///   dropdown turns this off.
/// - [errorWhenBordered] keeps the error slot for [LabelPosition.inBorder] and
///   [LabelPosition.none], where the label is drawn by the field itself.
Widget buildSelectionLayout({
  required LabelPosition labelPosition,
  required Widget label,
  required Widget field,
  Widget? error,
  double sideGap = 8,
  bool intrinsicLabel = true,
  bool errorWhenBordered = true,
}) {
  const padding = EdgeInsets.symmetric(vertical: 8);
  final sideLabel = intrinsicLabel ? IntrinsicWidth(child: label) : label;
  final belowField = error == null ? const <Widget>[] : [error];

  switch (labelPosition) {
    case LabelPosition.top:
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [label, const SizedBox(height: 8), field, ...belowField],
        ),
      );
    case LabelPosition.bottom:
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [field, const SizedBox(height: 8), label, ...belowField],
        ),
      );
    case LabelPosition.left:
      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            sideLabel,
            SizedBox(width: sideGap),
            Expanded(child: _fieldWithError(field, belowField)),
          ],
        ),
      );
    case LabelPosition.right:
      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _fieldWithError(field, belowField)),
            SizedBox(width: sideGap),
            sideLabel,
          ],
        ),
      );
    case LabelPosition.inBorder:
    case LabelPosition.none:
      return Padding(
        padding: padding,
        child: errorWhenBordered ? _fieldWithError(field, belowField) : field,
      );
  }
}

/// The field, with the error slot under it when there is one.
Widget _fieldWithError(Widget field, List<Widget> belowField) {
  if (belowField.isEmpty) return field;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [field, ...belowField],
  );
}

// ---------------------------------------------------------------------------
// List-style fields (list tile and checkbox list tile)
// ---------------------------------------------------------------------------

/// Title or subtitle of a list-style field, styled like the text around it.
/// Returns `null` when there is no content.
Widget? buildTileText(
  BuildContext context,
  Widget? content,
  TextStyle? textStyle,
) {
  if (content == null) return null;
  return DefaultTextStyle.merge(
    style: textStyle ?? DefaultTextStyle.of(context).style,
    child: content,
  );
}

/// Error line under a list-style field.
Widget buildTileErrorText(BuildContext context, String message) {
  return Padding(
    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
    child: Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 12,
      ),
    ),
  );
}

/// Underline below a list-style field. The outlined style is drawn by each
/// field, because a colored box around a ListTile would hide its ink splash.
Widget buildTileUnderline(BuildContext context, Widget child) {
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: child,
  );
}
