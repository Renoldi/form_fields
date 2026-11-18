part of '../form_fields_radio_button.dart';

class _FormFieldsRadioButtonBodyView<T>
    extends _FormFieldsRadioButtonBodyPresenterState<T> {
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
    final hasError = widget.state.hasError;
    final hasSections = widget.sections.isNotEmpty;

    // Build label widget
    final theme = Theme.of(context);
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

    // Build radio container using borderType and theme colors
    // theme already defined above
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

    final radioContainer = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.filled
            ? (widget.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest)
            : null,
        border: containerBorder,
        borderRadius: widget.itemBorderColor == null
            ? BorderRadius.circular(10)
            : null,
        boxShadow: widget.itemShadow && !hasError
            ? [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      padding: EdgeInsets.all(widget.containerPadding),
      child: hasSections ? _buildSections() : _buildSimpleItems(),
    );

    // Error message
    final errorWidget = hasError
        ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              (widget.state.errorText != null &&
                      widget.state.errorText!.isNotEmpty)
                  ? widget.state.errorText!
                  : l.getWithLabel('selectRequired', widget.label.toTitleCases),
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12),
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
              radioContainer,
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
              radioContainer,
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
                  children: [radioContainer, errorWidget],
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
                  children: [radioContainer, errorWidget],
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
            children: [radioContainer, errorWidget],
          ),
        );
      case LabelPosition.none:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [radioContainer, errorWidget],
          ),
        );
    }
  }

  Color _effectiveActiveColor(BuildContext context) {
    return resolveActiveColor(context, widget.activeColor);
  }

  /// Build sections layout with horizontal items in each section
  Widget _buildSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.sections.entries.toList().asMap().entries.map((entry) {
          int index = entry.key;
          MapEntry<String, List<T>> sectionEntry = entry.value;
          final sectionName = sectionEntry.key;
          final items = sectionEntry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) SizedBox(height: widget.sectionSpacing),
              // Section title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  sectionName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.textStyle?.color != null
                        ? widget.textStyle!.color!.withValues(alpha: 0.7)
                        : resolveTextColor(context, muted: true),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Items in horizontal layout
              Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 4,
                children: items.map((item) => _buildItem(item)).toList(),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build simple items (backward compatibility)
  Widget _buildSimpleItems() {
    return (widget.direction == Axis.horizontal || widget.horizontalSideBySide)
        ? Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 4,
            children: widget.items.map((e) => _buildItem(e)).toList(),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.items.map((e) => _buildItem(e)).toList(),
          );
  }

  Widget _buildItem(T item) {
    final selected = widget.state.value == item;
    final isCompactHorizontal = widget.horizontalSideBySide;

    final itemContent = widget.itemBuilder != null
        ? Padding(
            padding: EdgeInsets.only(
              right: widget.textRightPadding + widget.itemTextMarginRight,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: selected
                    ? (widget.selectedItemTextColor ??
                          widget.textStyle?.color ??
                          resolveTextColor(context))
                    : (widget.textStyle?.color != null
                          ? widget.textStyle!.color!.withValues(alpha: 0.7)
                          : resolveTextColor(context, muted: true)),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: widget.itemBuilder!(item, selected),
            ),
          )
        : Padding(
            padding: EdgeInsets.only(
              right: widget.textRightPadding + widget.itemTextMarginRight,
            ),
            child: Text(
              widget.itemLabelBuilder != null
                  ? widget.itemLabelBuilder!(item)
                  : item.toString().toBegin,
              style: TextStyle(
                color: selected
                    ? (widget.selectedItemTextColor ??
                          widget.textStyle?.color ??
                          resolveTextColor(context))
                    : (widget.textStyle?.color != null
                          ? widget.textStyle!.color!.withValues(alpha: 0.7)
                          : resolveTextColor(context, muted: true)),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: selected ? 14 : 13.5,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          );

    return Padding(
      padding: EdgeInsets.only(
        top: widget.itemMarginTop,
        bottom: widget.itemMarginBottom,
      ),
      child: StatefulBuilder(
        builder: (context, setHoverState) {
          return MouseRegion(
            onEnter: (_) => setHoverState(() {}),
            onExit: (_) => setHoverState(() {}),
            child: Builder(
              builder: (context) {
                final containerColor = selected
                    ? (widget.selectedItemBackgroundColor ??
                          _effectiveActiveColor(
                            context,
                          ).withValues(alpha: 0.12))
                    : Colors.transparent;

                final itemBox = AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: containerColor,
                    border: widget.itemBorderColor != null
                        ? Border.all(
                            color: selected
                                ? _effectiveActiveColor(context)
                                : widget.itemBorderColor!,
                            width: selected
                                ? widget.itemBorderWidth + 0.5
                                : widget.itemBorderWidth,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(
                      widget.itemBorderRadius,
                    ),
                    boxShadow: widget.itemShadow && selected
                        ? [
                            BoxShadow(
                              color: _effectiveActiveColor(
                                context,
                              ).withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: InkWell(
                    onTap: widget.readOnly
                        ? null
                        : () {
                            widget.onChanged(item);
                            widget.state.didChange(item);
                            // Re-validate so externalErrorText clears when user selects
                            widget.state.validate();
                          },
                    hoverColor:
                        (widget.hoverBackgroundColor ??
                                _effectiveActiveColor(context))
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      widget.itemBorderRadius,
                    ),
                    child: Padding(
                      padding: widget.itemPadding,
                      child: Row(
                        crossAxisAlignment: _itemCrossAxisAlignment,
                        mainAxisSize: isCompactHorizontal
                            ? MainAxisSize.min
                            : MainAxisSize.max,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? _effectiveActiveColor(context)
                                    : resolveBorderColor(context),
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _effectiveActiveColor(context),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          if (isCompactHorizontal)
                            itemContent
                          else
                            Expanded(child: itemContent),
                        ],
                      ),
                    ),
                  ),
                );

                // Wrap with border container if no itemBorderColor
                if (widget.itemBorderColor == null) {
                  return itemBox;
                }

                return itemBox;
              },
            ),
          );
        },
      ),
    );
  }
}
