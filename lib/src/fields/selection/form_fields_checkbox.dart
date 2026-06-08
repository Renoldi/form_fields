import 'package:flutter/material.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/theme_helpers.dart';
import '../../utilities/extensions.dart';

class FormFieldsCheckbox<T> extends StatefulWidget {
  final String? externalErrorText;
  final String label;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final List<T>? initialValue;
  final bool isRequired;
  final Axis direction;
  final BorderType borderType;
  final Color activeColor;
  final EdgeInsets itemPadding;
  final double itemMarginTop;
  final double itemMarginBottom;
  final double itemMarginHorizontal;
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final double textRightPadding;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final FormFieldValidator<List<T>>? validator;
  final LabelPosition labelPosition;
  final double containerGap;

  const FormFieldsCheckbox({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.isRequired = false,
    this.direction = Axis.vertical,
    this.borderType = BorderType.outlineInputBorder,
    this.activeColor = Colors.blue,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 6),
    this.itemMarginTop = 4,
    this.itemMarginBottom = 4,
    this.itemMarginHorizontal = 0,
    this.indicatorVerticalAlignment = IndicatorVerticalAlignment.center,
    this.horizontalSideBySide = false,
    this.textRightPadding = 0,
    this.itemBorderColor,
    this.itemBorderWidth = 1.0,
    this.itemBorderRadius = 8,
    this.itemLabelBuilder,
    this.itemBuilder,
    this.validator,
    this.labelPosition = LabelPosition.top,
    this.containerGap = 8,
    this.externalErrorText,
  });

  @override
  State<FormFieldsCheckbox<T>> createState() => _FormFieldsCheckboxState<T>();
}

class _FormFieldsCheckboxState<T> extends State<FormFieldsCheckbox<T>> {
  late final GlobalKey<FormFieldState<List<T>>> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormFieldState<List<T>>>();
  }

  @override
  void didUpdateWidget(covariant FormFieldsCheckbox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalErrorText != widget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    return FormField<List<T>>(
      key: _formKey,
      initialValue: widget.initialValue ?? [],
      validator: (value) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        if (widget.isRequired && (value == null || value.isEmpty)) {
          return l.selectAtLeastOne(widget.label.toTitleCase);
        }
        if (widget.validator != null) return widget.validator!(value ?? []);
        return null;
      },
      builder: (FormFieldState<List<T>> state) {
        return _FormFieldsCheckboxBody<T>(
          label: widget.label,
          state: state,
          items: widget.items,
          onChanged: widget.onChanged,
          direction: widget.direction,
          borderType: widget.borderType,
          activeColor: widget.activeColor,
          itemPadding: widget.itemPadding,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          itemMarginHorizontal: widget.itemMarginHorizontal,
          indicatorVerticalAlignment: widget.indicatorVerticalAlignment,
          horizontalSideBySide: widget.horizontalSideBySide,
          textRightPadding: widget.textRightPadding,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          isRequired: widget.isRequired,
          labelPosition: widget.labelPosition,
          containerGap: widget.containerGap,
        );
      },
    );
  }
}

class _FormFieldsCheckboxBody<T> extends StatefulWidget {
  final String label;
  final FormFieldState<List<T>> state;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final Axis direction;
  final BorderType borderType;
  final Color activeColor;
  final EdgeInsets itemPadding;
  final double itemMarginTop;
  final double itemMarginBottom;
  final double itemMarginHorizontal;
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final double textRightPadding;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final bool isRequired;
  final LabelPosition labelPosition;
  final double containerGap;

  const _FormFieldsCheckboxBody({
    required this.label,
    required this.state,
    required this.items,
    required this.onChanged,
    required this.direction,
    required this.borderType,
    required this.activeColor,
    required this.itemPadding,
    required this.itemMarginTop,
    required this.itemMarginBottom,
    required this.itemMarginHorizontal,
    required this.indicatorVerticalAlignment,
    required this.horizontalSideBySide,
    required this.textRightPadding,
    this.itemBorderColor,
    required this.itemBorderWidth,
    required this.itemBorderRadius,
    this.itemLabelBuilder,
    this.itemBuilder,
    required this.isRequired,
    required this.labelPosition,
    required this.containerGap,
  });

  @override
  State<_FormFieldsCheckboxBody<T>> createState() =>
      _FormFieldsCheckboxBodyView<T>();
}

abstract class _FormFieldsCheckboxBodyPresenterState<T>
    extends State<_FormFieldsCheckboxBody<T>> {
  late final _FormFieldsCheckboxBodyViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _FormFieldsCheckboxBodyViewModel();
  }
}

class _FormFieldsCheckboxBodyView<T>
    extends _FormFieldsCheckboxBodyPresenterState<T> {
  CrossAxisAlignment get _itemCrossAxisAlignment {
    switch (widget.indicatorVerticalAlignment) {
      case IndicatorVerticalAlignment.top:
        return CrossAxisAlignment.start;
      case IndicatorVerticalAlignment.center:
        return CrossAxisAlignment.center;
      case IndicatorVerticalAlignment.bottom:
        return CrossAxisAlignment.end;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    final selectedValues = widget.state.value ?? [];
    final hasError = widget.state.hasError;

    final theme = Theme.of(context);
    // Build label widget
    final labelWidget = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: widget.label.toTitleCase,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasError
                  ? theme.colorScheme.error
                  : resolveTextColor(context),
            ),
          ),
          if (widget.isRequired)
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

    // Build checkbox container using borderType and theme colors
    final normalColor = theme.dividerColor;
    final errorColor = theme.colorScheme.error;
    final containerBorder = widget.itemBorderColor == null
        ? (widget.borderType == BorderType.none
            ? null
            : Border.all(
                color: hasError ? errorColor : normalColor, width: 1.5))
        : null;

    final checkboxContainer = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: containerBorder,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child:
          (widget.direction == Axis.horizontal || widget.horizontalSideBySide)
              ? Wrap(
                  children: widget.items
                      .map((item) => _buildItem(item, selectedValues))
                      .toList(),
                )
              : Column(
                  children: widget.items
                      .map((item) => _buildItem(item, selectedValues))
                      .toList(),
                ),
    );

    // Error message
    final errorWidget = hasError
        ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.state.errorText?.isEmpty ?? true
                  ? l.selectAtLeastOne(widget.label.toTitleCase)
                  : widget.state.errorText!,
              style: TextStyle(
                color: errorColor,
                fontSize: 12,
              ),
            ),
          )
        : const SizedBox.shrink();

    // Handle label position
    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            SizedBox(height: widget.containerGap),
            checkboxContainer,
            errorWidget,
          ],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            checkboxContainer,
            SizedBox(height: widget.containerGap),
            labelWidget,
            errorWidget,
          ],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IntrinsicWidth(child: labelWidget),
            SizedBox(width: widget.containerGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  checkboxContainer,
                  errorWidget,
                ],
              ),
            ),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  checkboxContainer,
                  errorWidget,
                ],
              ),
            ),
            SizedBox(width: widget.containerGap),
            IntrinsicWidth(child: labelWidget),
          ],
        );
      case LabelPosition.inBorder:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            checkboxContainer,
            errorWidget,
          ],
        );
      case LabelPosition.none:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            checkboxContainer,
            errorWidget,
          ],
        );
    }
  }

  Widget _buildItem(T item, List<T> selectedValues) {
    final isSelected = selectedValues.contains(item);
    final isCompactHorizontal = widget.horizontalSideBySide;
    final itemBorder = widget.itemBorderColor == null
        ? null
        : Border.all(
            color: widget.itemBorderColor!,
            width: widget.itemBorderWidth,
          );

    final itemContent = widget.itemBuilder != null
        ? Padding(
            padding: EdgeInsets.only(right: widget.textRightPadding),
            child: widget.itemBuilder!(item, isSelected),
          )
        : Padding(
            padding: EdgeInsets.only(right: widget.textRightPadding),
            child: Text(
              widget.itemLabelBuilder != null
                  ? widget.itemLabelBuilder!(item)
                  : item.toString().toBegin,
              style: TextStyle(
                color: isSelected
                    ? resolveTextColor(context)
                    : resolveTextColor(context, muted: true),
              ),
            ),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.itemMarginHorizontal,
        widget.itemMarginTop,
        widget.itemMarginHorizontal,
        widget.itemMarginBottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: itemBorder,
          borderRadius: BorderRadius.circular(widget.itemBorderRadius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.itemBorderRadius),
          onTap: () {
            final updated = List<T>.from(selectedValues);

            if (isSelected) {
              updated.remove(item);
            } else {
              updated.add(item);
            }

            widget.onChanged(updated);
            widget.state.didChange(updated);
            // Validate after user toggles an option so external errors clear
            widget.state.validate();
          },
          child: Padding(
            padding: widget.itemPadding,
            child: Row(
              crossAxisAlignment: _itemCrossAxisAlignment,
              mainAxisSize:
                  isCompactHorizontal ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: resolveActiveColor(context, widget.activeColor),
                  onChanged: (checked) {
                    final updated = List<T>.from(selectedValues);

                    if (checked == true) {
                      updated.add(item);
                    } else {
                      updated.remove(item);
                    }

                    widget.onChanged(updated);
                    widget.state.didChange(updated);
                    // Validate when checkbox changes
                    widget.state.validate();
                  },
                ),
                const SizedBox(width: 8),
                if (isCompactHorizontal)
                  itemContent
                else
                  Expanded(
                    child: itemContent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormFieldsCheckboxBodyViewModel {}
