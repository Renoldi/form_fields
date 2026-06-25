import 'package:flutter/material.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/extensions.dart';

class FormFieldsCheckboxListTile extends StatefulWidget {
  final String? label;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool tristate;
  final bool selected;
  final bool enabled;

  // form features
  final FormFieldValidator<bool?>? validator;
  final bool isRequired;
  final bool readOnly;
  final TextStyle? textStyle;
  final LabelPosition labelPosition;
  final BorderType borderType;
  final String? externalErrorText;

  const FormFieldsCheckboxListTile({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.tristate = false,
    this.selected = false,
    this.enabled = true,
    this.validator,
    this.isRequired = false,
    this.readOnly = false,
    this.textStyle,
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.none,
    this.externalErrorText,
  });

  @override
  State<FormFieldsCheckboxListTile> createState() =>
      _FormFieldsCheckboxListTileState();
}

class _FormFieldsCheckboxListTileState
    extends State<FormFieldsCheckboxListTile> {
  bool? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant FormFieldsCheckboxListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  void _handleChanged(bool? newValue) {
    if (!widget.enabled) return;
    setState(() {
      _value = newValue;
    });
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    return FormField<bool?>(
      initialValue: _value,
      validator: (v) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        if (widget.isRequired && (v == null || v == false)) {
          return widget.label != null
              ? l.select(widget.label!.toTitleCases)
              : l.select('value');
        }
        if (widget.validator != null) {
          return widget.validator!(v);
        }
        return null;
      },
      builder: (FormFieldState<bool?> state) {
        final title = widget.title != null
            ? DefaultTextStyle.merge(
                style: widget.textStyle ?? DefaultTextStyle.of(context).style,
                child: widget.title!)
            : null;
        final subtitle = widget.subtitle != null
            ? DefaultTextStyle.merge(
                style: widget.textStyle ?? DefaultTextStyle.of(context).style,
                child: widget.subtitle!)
            : null;
        final child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: state.value,
              onChanged: (widget.readOnly || widget.onChanged == null)
                  ? null
                  : (v) {
                      state.didChange(v);
                      _handleChanged(v);
                    },
              title: title,
              subtitle: subtitle,
              secondary: widget.secondary,
              tristate: widget.tristate,
              selected: widget.selected,
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

        if (widget.borderType == BorderType.none) return child;

        final borderColor = Theme.of(context).dividerColor;
        final decoration = widget.borderType == BorderType.outlineInputBorder
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              )
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              );

        return Container(
          padding: widget.borderType == BorderType.outlineInputBorder
              ? const EdgeInsets.all(6)
              : EdgeInsets.zero,
          decoration: decoration,
          child: child,
        );
      },
    );
  }
}
