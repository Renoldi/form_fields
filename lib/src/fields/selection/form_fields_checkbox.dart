import 'package:flutter/material.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';

class FormFieldsCheckbox<T> extends FormField<List<T>> {
  FormFieldsCheckbox({
    super.key,
    required String label,
    required List<T> items,
    required ValueChanged<List<T>> onChanged,
    List<T>? initialValue,
    bool isRequired = false,
    Axis direction = Axis.vertical,
    double radius = 10,
    Color borderColor = const Color(0xFFC7C7C7),
    Color errorBorderColor = Colors.red,
    Color activeColor = Colors.blue,
    EdgeInsets itemPadding = const EdgeInsets.symmetric(vertical: 6),
    double itemMarginTop = 4,
    double itemMarginBottom = 4,
    double itemMarginHorizontal = 0,
    IndicatorVerticalAlignment indicatorVerticalAlignment =
        IndicatorVerticalAlignment.center,
    bool horizontalSideBySide = false,
    double textRightPadding = 0,
    Color? itemBorderColor,
    double itemBorderWidth = 1.0,
    double itemBorderRadius = 8,
    String Function(T item)? itemLabelBuilder,
    Widget Function(T item, bool selected)? itemBuilder,
    FormFieldValidator<List<T>>? validator,
    LabelPosition labelPosition = LabelPosition.top,
    double containerGap = 8,
  }) : super(
          initialValue: initialValue ?? [],
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              // Localization handled in build method
              return "";
            }
            return validator?.call(value ?? []);
          },
          builder: (FormFieldState<List<T>> state) {
            return _FormFieldsCheckboxBody<T>(
              label: label,
              state: state,
              items: items,
              onChanged: onChanged,
              direction: direction,
              radius: radius,
              borderColor: borderColor,
              errorBorderColor: errorBorderColor,
              activeColor: activeColor,
              itemPadding: itemPadding,
              itemMarginTop: itemMarginTop,
              itemMarginBottom: itemMarginBottom,
              itemMarginHorizontal: itemMarginHorizontal,
              indicatorVerticalAlignment: indicatorVerticalAlignment,
              horizontalSideBySide: horizontalSideBySide,
              textRightPadding: textRightPadding,
              itemBorderColor: itemBorderColor,
              itemBorderWidth: itemBorderWidth,
              itemBorderRadius: itemBorderRadius,
              itemLabelBuilder: itemLabelBuilder,
              itemBuilder: itemBuilder,
              isRequired: isRequired,
              labelPosition: labelPosition,
              containerGap: containerGap,
            );
          },
        );
}

class _FormFieldsCheckboxBody<T> extends StatefulWidget {
  final String label;
  final FormFieldState<List<T>> state;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final Axis direction;
  final double radius;
  final Color borderColor;
  final Color errorBorderColor;
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
    required this.radius,
    required this.borderColor,
    required this.errorBorderColor,
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

    // Build label widget
    final labelWidget = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasError ? const Color(0xFFB71C1C) : Colors.black87,
            ),
          ),
          if (widget.isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );

    // Build checkbox container
    final checkboxContainer = Container(
      decoration: BoxDecoration(
        border: widget.itemBorderColor == null
            ? Border.all(
                color: hasError ? widget.errorBorderColor : widget.borderColor,
                width: 1.5,
              )
            : null,
        borderRadius: BorderRadius.circular(widget.radius),
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
                  ? l.selectAtLeastOne(widget.label)
                  : widget.state.errorText!,
              style: TextStyle(
                color: widget.errorBorderColor,
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
                  : item.toString(),
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

            widget.state.didChange(updated);
            widget.onChanged(updated);
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
                  activeColor: widget.activeColor,
                  onChanged: (checked) {
                    final updated = List<T>.from(selectedValues);

                    if (checked == true) {
                      updated.add(item);
                    } else {
                      updated.remove(item);
                    }

                    widget.state.didChange(updated);
                    widget.onChanged(updated);
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
