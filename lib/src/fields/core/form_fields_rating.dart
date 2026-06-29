import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class FormFieldsRating extends StatefulWidget {
  final int? initialRating;
  final int maxRating;
  final ValueChanged<int>? onChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final AppSize fieldSize;
  final double? customFieldHeight;
  final bool errorOutsideBorder;
  final Widget? filledIcon;
  final Widget? emptyIcon;

  // form features
  final String? Function(int?)? validator;
  final bool isRequired;
  final bool readOnly;
  final TextStyle? textStyle;
  final String? label;
  final LabelPosition labelPosition;
  final BorderType borderType;
  final String? externalErrorText;
  final AutovalidateMode autovalidateMode;

  const FormFieldsRating({
    super.key,
    this.initialRating,
    this.maxRating = 5,
    this.onChanged,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.fieldSize = AppSize.medium,
    this.customFieldHeight,
    this.errorOutsideBorder = true,
    this.filledIcon,
    this.emptyIcon,
    this.validator,
    this.isRequired = false,
    this.readOnly = false,
    this.textStyle,
    this.label,
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.none,
    this.externalErrorText,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : assert(initialRating == null ||
            (initialRating >= 0 && initialRating <= maxRating));

  @override
  State<FormFieldsRating> createState() => _FormFieldsRatingState();
}

class _FormFieldsRatingState extends State<FormFieldsRating> {
  int? _rating;
  GlobalKey<FormFieldState<int?>> _formKey = GlobalKey<FormFieldState<int?>>();

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  void didUpdateWidget(covariant FormFieldsRating oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If external error text changed, revalidate the FormField after build
    if (oldWidget.externalErrorText != widget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _formKey.currentState?.validate();
      });
    }

    // If the caller updated the initial rating, recreate the FormField
    // so it re-initializes its internal value from `initialValue`.
    // Recreating avoids calling `didChange(...)` which marks the field as
    // user-interacted and can trigger `AutovalidateMode.onUserInteraction`.
    if (oldWidget.initialRating != widget.initialRating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _formKey = GlobalKey<FormFieldState<int?>>();
          _rating = widget.initialRating;
        });
      });
    }
  }

  void _setRating(int r) {
    if (widget.readOnly) return;
    setState(() {
      _rating = r;
    });
    widget.onChanged?.call(_rating!);
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    final active =
        widget.activeColor ?? Theme.of(context).colorScheme.secondary;
    final inactive = widget.inactiveColor ?? Colors.grey.shade400;

    return FormField<int?>(
      key: _formKey,
      autovalidateMode: widget.autovalidateMode,
      initialValue: _rating,
      validator: (v) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        // Treat `null` as empty/unset. `0` is a valid rating value.
        if (widget.isRequired && v == null) {
          return widget.label != null
              ? l.select(widget.label!.toTitleCases)
              : l.select('rating');
        }
        if (widget.validator != null) {
          return widget.validator!(v);
        }
        return null;
      },
      builder: (FormFieldState<int?> state) {
        final labelWidget = (widget.label != null && widget.label!.isNotEmpty)
            ? Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Text(widget.label!,
                    style:
                        widget.textStyle ?? DefaultTextStyle.of(context).style),
              )
            : null;

        final ratingRow = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(widget.maxRating, (index) {
            final i = index + 1;
            final filled = i <= (state.value ?? _rating ?? 0);
            final iconWidget = filled
                ? (widget.filledIcon ??
                    // When caller doesn't provide a custom icon, allow theme to
                    // control color/size by avoiding hard-coded color/size.
                    (widget.activeColor != null
                        ? Icon(Icons.star, color: active)
                        : const Icon(Icons.star)))
                : (widget.emptyIcon ??
                    (widget.inactiveColor != null
                        ? Icon(Icons.star_border, color: inactive)
                        : const Icon(Icons.star_border)));

            return AppButton(
              type: AppButtonType.icon,
              size: AppSize.small,
              useSafeArea: false,
              customIconSize: (widget.size != 24.0 ? widget.size : null),
              icon: iconWidget,
              onPressed: widget.readOnly
                  ? null
                  : () {
                      state.didChange(i);
                      _setRating(i);
                    },
            );
          }),
        );

        final errorWidget = state.errorText != null
            ? Padding(
                padding:
                    const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0),
                child: Text(state.errorText!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12)),
              )
            : null;

        final innerChild = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ratingRow,
            if (widget.borderType == BorderType.none && errorWidget != null)
              errorWidget,
          ],
        );

        if (widget.borderType == BorderType.none) {
          return widget.labelPosition == LabelPosition.top &&
                  labelWidget != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    labelWidget,
                    innerChild,
                  ],
                )
              : innerChild;
        }

        final borderColor = state.errorText != null
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).dividerColor;
        final borderWidth = state.errorText != null ? 1.4 : 1.0;
        final decoration = widget.borderType == BorderType.outlineInputBorder
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: borderWidth),
              )
            : BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: borderColor, width: borderWidth)));

        double fieldHeight;
        switch (widget.fieldSize) {
          case AppSize.small:
            fieldHeight = kFieldHeightSmall;
            break;
          case AppSize.medium:
            fieldHeight = kFieldHeightMedium;
            break;
          case AppSize.large:
            fieldHeight = kFieldHeightLarge;
            break;
          case AppSize.custom:
            fieldHeight = widget.customFieldHeight ?? kFieldHeightDefault;
            break;
        }
        final boxedChild = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: ratingRow),
            if (!widget.errorOutsideBorder && errorWidget != null) errorWidget,
          ],
        );

        final boxed = Container(
          width: double.infinity,
          padding: widget.borderType == BorderType.outlineInputBorder
              ? const EdgeInsets.symmetric(horizontal: 12.0)
              : EdgeInsets.zero,
          height: fieldHeight,
          decoration: decoration,
          child: boxedChild,
        );

        final columnChildren = <Widget>[];
        if (labelWidget != null && widget.labelPosition == LabelPosition.top) {
          columnChildren.add(labelWidget);
        }
        columnChildren.add(boxed);
        if (errorWidget != null && widget.errorOutsideBorder) {
          columnChildren.add(errorWidget);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: columnChildren,
        );
      },
    );
  }
}
