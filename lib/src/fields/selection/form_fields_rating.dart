import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class FormFieldsRating extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final ValueChanged<int>? onChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  // form features
  final String? Function(int?)? validator;
  final bool isRequired;
  final bool readOnly;
  final TextStyle? textStyle;
  final String? label;
  final LabelPosition labelPosition;
  final BorderType borderType;
  final String? externalErrorText;

  const FormFieldsRating({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.onChanged,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.validator,
    this.isRequired = false,
    this.readOnly = false,
    this.textStyle,
    this.label,
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.none,
    this.externalErrorText,
  }) : assert(initialRating >= 0 && initialRating <= maxRating);

  @override
  State<FormFieldsRating> createState() => _FormFieldsRatingState();
}

class _FormFieldsRatingState extends State<FormFieldsRating> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _setRating(int r) {
    if (widget.readOnly) return;
    setState(() {
      _rating = r;
    });
    widget.onChanged?.call(_rating);
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    final active =
        widget.activeColor ?? Theme.of(context).colorScheme.secondary;
    final inactive = widget.inactiveColor ?? Colors.grey.shade400;

    return FormField<int>(
      initialValue: _rating,
      validator: (v) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        if (widget.isRequired && (v == null || v == 0)) {
          return widget.label != null
              ? l.select(widget.label!.toTitleCase)
              : l.select('rating');
        }
        if (widget.validator != null) {
          return widget.validator!(v);
        }
        return null;
      },
      builder: (FormFieldState<int> state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(widget.maxRating, (index) {
                final i = index + 1;
                final filled = i <= (state.value ?? _rating);
                return AppButton(
                  type: AppButtonType.icon,
                  size: AppSize.small,
                  useSafeArea: false,
                  customIconSize: widget.size,
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? active : inactive,
                  ),
                  onPressed: widget.readOnly
                      ? null
                      : () {
                          state.didChange(i);
                          _setRating(i);
                        },
                );
              }),
            ),
            if (state.errorText != null)
              Padding(
                padding:
                    const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 8.0),
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
