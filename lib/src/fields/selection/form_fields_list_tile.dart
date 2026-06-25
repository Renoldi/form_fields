import 'package:flutter/material.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/extensions.dart';

class FormFieldsListTile extends StatelessWidget {
  final String? label;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool enabled;
  final bool selected;
  final Color? tileColor;
  final EdgeInsetsGeometry? contentPadding;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  // form features
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool readOnly;
  final TextStyle? textStyle;
  final LabelPosition labelPosition;
  final BorderType borderType;
  final String? externalErrorText;

  const FormFieldsListTile({
    super.key,
    this.label,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.enabled = true,
    this.selected = false,
    this.tileColor,
    this.contentPadding,
    this.onTap,
    this.onLongPress,
    this.validator,
    this.isRequired = false,
    this.readOnly = false,
    this.textStyle,
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.none,
    this.externalErrorText,
  });

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    return FormField<String>(
      initialValue: null,
      validator: (v) {
        if (externalErrorText != null && externalErrorText!.isNotEmpty) {
          return externalErrorText;
        }
        if (isRequired) {
          return l.select(label?.toTitleCase ?? 'item');
        }
        if (validator != null) {
          return validator!(v);
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        final titleWidget = title != null
            ? DefaultTextStyle.merge(
                style: textStyle ?? DefaultTextStyle.of(context).style,
                child: title!)
            : null;
        final subtitleWidget = subtitle != null
            ? DefaultTextStyle.merge(
                style: textStyle ?? DefaultTextStyle.of(context).style,
                child: subtitle!)
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: leading,
              title: titleWidget,
              subtitle: subtitleWidget,
              trailing: trailing,
              enabled: enabled && !readOnly,
              selected: selected,
              tileColor: tileColor,
              contentPadding: contentPadding,
              onTap: readOnly ? null : onTap,
              onLongPress: readOnly ? null : onLongPress,
            ),
            if (state.errorText != null)
              Padding(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                child: Text(state.errorText!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}
