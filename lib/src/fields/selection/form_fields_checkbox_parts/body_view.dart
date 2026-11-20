part of '../form_fields_checkbox.dart';

class _FormFieldsCheckboxBodyView<T>
    extends _FormFieldsCheckboxBodyPresenterState<T> {
  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    final selectedValues = widget.state.value ?? [];
    final hasError = widget.state.hasError;
    final theme = Theme.of(context);

    final checkboxContainer = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.filled
            ? (widget.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest)
            : null,
        border: selectionContainerBorder(
          context: context,
          itemBorderColor: widget.itemBorderColor,
          borderType: widget.borderType,
          hasError: hasError,
        ),
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

    return buildSelectionLayout(
      labelPosition: widget.labelPosition,
      label: buildSelectionLabel(
        context: context,
        label: widget.label,
        isRequired: widget.isRequired,
        hasError: hasError,
        textStyle: widget.textStyle,
      ),
      field: checkboxContainer,
      error: selectionErrorWidget(
        hasError: hasError,
        errorText: widget.state.errorText,
        fallbackMessage: l.selectAtLeastOne(widget.label.toTitleCases),
        color: theme.colorScheme.error,
      ),
    );
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
                color: selectionItemTextColor(
                  context,
                  selected: isSelected,
                  selectedItemTextColor: widget.selectedItemTextColor,
                  textStyle: widget.textStyle,
                ),
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
              crossAxisAlignment: selectionCrossAxisAlignment(
                widget.indicatorVerticalAlignment,
              ),
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
