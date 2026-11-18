import 'package:material_ui/material_ui.dart';
import 'package:form_fields/src/utilities/enums.dart';
import 'package:form_fields/src/utilities/extensions.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';

/// Default label typography, shared by every label-aware form field.
const TextStyle kFormFieldLabelDefaultStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

/// Gap between the label and the field when the label sits beside it.
const double kFormFieldLabelSpacing = 12.0;

/// Fixed width of a label placed to the left or right of the field.
const double kFormFieldLabelWidth = 120.0;

/// Vertical gap above and below a labeled field.
const double kFormFieldLabelVerticalGap = 8.0;

/// Renders a field's label with a red `*` when [isRequired] is set.
///
/// Returns an empty box when [label] is null/blank or [labelPosition] is
/// [LabelPosition.none], so callers can always place it unconditionally.
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel({
    super.key,
    required this.label,
    required this.labelPosition,
    this.labelTextStyle,
    this.isRequired = false,
  });

  final String? label;
  final LabelPosition labelPosition;
  final TextStyle? labelTextStyle;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final raw = label;
    if (raw == null || raw.isEmpty || labelPosition == LabelPosition.none) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final style = (labelTextStyle ?? kFormFieldLabelDefaultStyle).copyWith(
      color: resolveTextColor(context),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: kFormFieldLabelVerticalGap),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: raw.toTitleCases, style: style),
            if (isRequired)
              TextSpan(
                text: ' *',
                style: kFormFieldLabelDefaultStyle.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Places [child] together with a [FormFieldLabel] according to
/// [labelPosition] (top, bottom, left or right).
///
/// When the label is null/blank, or the position is [LabelPosition.none] or
/// [LabelPosition.inBorder], [child] is returned with only the vertical gap.
/// The in-border label is rendered by the field itself.
class FormFieldLabelLayout extends StatelessWidget {
  const FormFieldLabelLayout({
    super.key,
    required this.child,
    required this.label,
    required this.labelPosition,
    this.labelTextStyle,
    this.isRequired = false,
  });

  final Widget child;
  final String? label;
  final LabelPosition labelPosition;
  final TextStyle? labelTextStyle;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    if (label == null ||
        label!.isEmpty ||
        labelPosition == LabelPosition.none) {
      return child;
    }
    final labelWidget = FormFieldLabel(
      label: label,
      labelPosition: labelPosition,
      labelTextStyle: labelTextStyle,
      isRequired: isRequired,
    );
    const verticalPadding = EdgeInsets.symmetric(
      vertical: kFormFieldLabelVerticalGap,
    );
    switch (labelPosition) {
      case LabelPosition.top:
        return Padding(
          padding: verticalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: kFormFieldLabelVerticalGap),
              child,
            ],
          ),
        );
      case LabelPosition.bottom:
        return Padding(
          padding: verticalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child,
              const SizedBox(height: kFormFieldLabelVerticalGap),
              labelWidget,
            ],
          ),
        );
      case LabelPosition.left:
        return Padding(
          padding: verticalPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: kFormFieldLabelWidth, child: labelWidget),
              const SizedBox(width: kFormFieldLabelSpacing),
              Expanded(child: child),
            ],
          ),
        );
      case LabelPosition.right:
        return Padding(
          padding: verticalPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: child),
              const SizedBox(width: kFormFieldLabelSpacing),
              SizedBox(width: kFormFieldLabelWidth, child: labelWidget),
            ],
          ),
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return Padding(padding: verticalPadding, child: child);
    }
  }
}
