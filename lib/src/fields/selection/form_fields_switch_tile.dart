import 'package:flutter/material.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/extensions.dart';

class FormFieldsSwitchTile extends StatefulWidget {
  final String? label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool selected;
  final bool enabled;
  @Deprecated(
      'Use activeThumbColor instead. This feature was deprecated after v3.31.0-2.0.pre.')
  final Color? activeColor;
  final Color? activeThumbColor;

  // Form features
  final String? Function(bool?)? validator;
  final bool isRequired;
  final bool readOnly;
  final TextStyle? textStyle;
  final LabelPosition labelPosition;
  final BorderType borderType;
  final String? externalErrorText;

  const FormFieldsSwitchTile({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.selected = false,
    this.enabled = true,
    this.activeColor,
    this.activeThumbColor,
    this.validator,
    this.isRequired = false,
    this.readOnly = false,
    this.textStyle,
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.none,
    this.externalErrorText,
  });

  @override
  State<FormFieldsSwitchTile> createState() => _FormFieldsSwitchTileState();
}

class _FormFieldsSwitchTileState extends State<FormFieldsSwitchTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant FormFieldsSwitchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  void _handleChanged(bool newValue) {
    if (!widget.enabled) return;
    setState(() {
      _value = newValue;
    });
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    return FormField<bool>(
      initialValue: _value,
      validator: (v) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        if (widget.isRequired && (v == null || v == false)) {
          return widget.label != null
              ? l.select(widget.label!.toTitleCase)
              : l.select('value');
        }
        if (widget.validator != null) {
          return widget.validator!(v);
        }
        return null;
      },
      builder: (FormFieldState<bool> state) {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: state.value ?? false,
              onChanged: (widget.readOnly || widget.onChanged == null)
                  ? null
                  : (v) {
                      state.didChange(v);
                      _handleChanged(v);
                    },
              title: title,
              subtitle: subtitle,
              secondary: widget.secondary,
              selected: widget.selected,
              activeThumbColor: widget.activeThumbColor ?? widget.activeColor,
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
