part of '../form_fields_checkbox.dart';

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
            text: widget.label.toTitleCases,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasError
                  ? theme.colorScheme.error
                  : (widget.textStyle?.color ?? resolveTextColor(context)),
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
                  color: hasError ? errorColor : normalColor,
                  width: 1.5,
                ))
        : null;

    final checkboxContainer = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.filled
            ? (widget.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest)
            : null,
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
                  ? l.selectAtLeastOne(widget.label.toTitleCases)
                  : widget.state.errorText!,
              style: TextStyle(color: errorColor, fontSize: 12),
            ),
          )
        : const SizedBox.shrink();

    // Handle label position
    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 8),
              checkboxContainer,
              errorWidget,
            ],
          ),
        );
      case LabelPosition.bottom:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              checkboxContainer,
              const SizedBox(height: 8),
              labelWidget,
              errorWidget,
            ],
          ),
        );
      case LabelPosition.left:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IntrinsicWidth(child: labelWidget),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [checkboxContainer, errorWidget],
                ),
              ),
            ],
          ),
        );
      case LabelPosition.right:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [checkboxContainer, errorWidget],
                ),
              ),
              const SizedBox(width: 8),
              IntrinsicWidth(child: labelWidget),
            ],
          ),
        );
      case LabelPosition.inBorder:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [checkboxContainer, errorWidget],
          ),
        );
      case LabelPosition.none:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [checkboxContainer, errorWidget],
          ),
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
                    ? (widget.selectedItemTextColor ??
                          widget.textStyle?.color ??
                          resolveTextColor(context))
                    : (widget.textStyle?.color != null
                          ? widget.textStyle!.color!.withValues(alpha: 0.7)
                          : resolveTextColor(context, muted: true)),
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
          onTap: widget.readOnly
              ? null
              : () {
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
              mainAxisSize: isCompactHorizontal
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: resolveActiveColor(context, widget.activeColor),
                  onChanged: widget.readOnly
                      ? null
                      : (checked) {
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
                  Expanded(child: itemContent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
