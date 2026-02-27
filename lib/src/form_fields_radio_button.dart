import 'package:flutter/material.dart';
import 'utilities/enums.dart';
import 'localization/form_fields_localizations.dart';

class FormFieldsRadioButton<T> extends FormField<T> {
  FormFieldsRadioButton({
    super.key,
    required String label,
    List<T>? items,
    Map<String, List<T>>? sections,
    required ValueChanged<T?> onChanged,
    String Function(T item)? itemLabelBuilder,
    Widget Function(T item, bool selected)? itemBuilder,
    T? initialValue,
    bool isRequired = false,
    Axis direction = Axis.vertical,
    double radius = 10,
    Color borderColor = const Color(0xFFC7C7C7),
    Color errorBorderColor = Colors.red,
    Color activeColor = Colors.blue,
    EdgeInsets itemPadding =
        const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    double sectionSpacing = 12,
    Color? itemBorderColor,
    double itemBorderWidth = 1.0,
    double itemBorderRadius = 8,
    double textRightPadding = 0,
    double itemTextMarginRight = 0,
    Color? selectedItemBackgroundColor,
    Color? selectedItemTextColor,
    Color? hoverBackgroundColor,
    bool itemShadow = false,
    LabelPosition labelPosition = LabelPosition.top,
    double containerPadding = 12,
    double containerGap = 8,
    double itemMarginTop = 4,
    double itemMarginBottom = 4,
    FormFieldValidator<T>? validator,
  })  : assert(items != null || sections != null,
            'Either items or sections must be provided'),
        super(
          initialValue: initialValue,
          validator: (value) {
            if (isRequired && value == null) {
              // Localization handled in build method
              return '';
            }
            return validator?.call(value);
          },
          builder: (FormFieldState<T> state) {
            return _FormFieldsRadioButtonBody<T>(
              label: label,
              state: state,
              items: items ?? [],
              sections: sections ?? {},
              onChanged: onChanged,
              itemLabelBuilder: itemLabelBuilder,
              itemBuilder: itemBuilder,
              direction: direction,
              radius: radius,
              borderColor: borderColor,
              errorBorderColor: errorBorderColor,
              activeColor: activeColor,
              itemPadding: itemPadding,
              isRequired: isRequired,
              sectionSpacing: sectionSpacing,
              itemBorderColor: itemBorderColor,
              itemBorderWidth: itemBorderWidth,
              itemBorderRadius: itemBorderRadius,
              textRightPadding: textRightPadding,
              itemTextMarginRight: itemTextMarginRight,
              selectedItemBackgroundColor: selectedItemBackgroundColor,
              selectedItemTextColor: selectedItemTextColor,
              hoverBackgroundColor: hoverBackgroundColor,
              itemShadow: itemShadow,
              labelPosition: labelPosition,
              containerPadding: containerPadding,
              containerGap: containerGap,
              itemMarginTop: itemMarginTop,
              itemMarginBottom: itemMarginBottom,
            );
          },
        );
}

class _FormFieldsRadioButtonBody<T> extends StatelessWidget {
  final String label;
  final FormFieldState<T> state;
  final List<T> items;
  final Map<String, List<T>> sections;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final Axis direction;
  final double radius;
  final Color borderColor;
  final Color errorBorderColor;
  final Color activeColor;
  final EdgeInsets itemPadding;
  final double sectionSpacing;
  final bool isRequired;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final double textRightPadding;
  final double itemTextMarginRight;
  final Color? selectedItemBackgroundColor;
  final Color? selectedItemTextColor;
  final Color? hoverBackgroundColor;
  final bool itemShadow;
  final LabelPosition labelPosition;
  final double containerPadding;
  final double containerGap;
  final double itemMarginTop;
  final double itemMarginBottom;

  const _FormFieldsRadioButtonBody({
    required this.label,
    required this.state,
    required this.items,
    required this.sections,
    required this.onChanged,
    this.itemLabelBuilder,
    this.itemBuilder,
    required this.direction,
    required this.radius,
    required this.borderColor,
    required this.errorBorderColor,
    required this.activeColor,
    required this.itemPadding,
    required this.sectionSpacing,
    required this.isRequired,
    this.itemBorderColor,
    required this.itemBorderWidth,
    required this.itemBorderRadius,
    required this.textRightPadding,
    required this.itemTextMarginRight,
    this.selectedItemBackgroundColor,
    this.selectedItemTextColor,
    this.hoverBackgroundColor,
    required this.itemShadow,
    required this.labelPosition,
    required this.containerPadding,
    required this.containerGap,
    required this.itemMarginTop,
    required this.itemMarginBottom,
  });

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    final hasError = state.hasError;
    final hasSections = sections.isNotEmpty;

    // Build label widget
    final labelWidget = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasError ? const Color(0xFFB71C1C) : Colors.black87,
            ),
          ),
          if (isRequired)
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

    // Build radio container
    final radioContainer = Container(
      decoration: BoxDecoration(
        border: itemBorderColor == null
            ? Border.all(
                color: hasError ? const Color(0xFFB71C1C) : borderColor,
                width: 1.5,
              )
            : null,
        borderRadius:
            itemBorderColor == null ? BorderRadius.circular(radius) : null,
        boxShadow: itemShadow && !hasError
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      padding: EdgeInsets.all(containerPadding),
      child: hasSections ? _buildSections() : _buildSimpleItems(),
    );

    // Error message
    final errorWidget = hasError
        ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.errorText ?? l.getWithLabel('selectRequired', label),
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 12,
              ),
            ),
          )
        : const SizedBox.shrink();

    // Handle label position
    switch (labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            SizedBox(height: containerGap),
            radioContainer,
            errorWidget,
          ],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            radioContainer,
            SizedBox(height: containerGap),
            labelWidget,
            errorWidget,
          ],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelWidget),
            SizedBox(width: containerGap),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  radioContainer,
                  errorWidget,
                ],
              ),
            ),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  radioContainer,
                  errorWidget,
                ],
              ),
            ),
            SizedBox(width: containerGap),
            Expanded(child: labelWidget),
          ],
        );
      case LabelPosition.inBorder:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            radioContainer,
            errorWidget,
          ],
        );
      case LabelPosition.none:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            radioContainer,
            errorWidget,
          ],
        );
    }
  }

  /// Build sections layout with horizontal items in each section
  Widget _buildSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sections.entries.toList().asMap().entries.map((entry) {
          int index = entry.key;
          MapEntry<String, List<T>> sectionEntry = entry.value;
          final sectionName = sectionEntry.key;
          final items = sectionEntry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) SizedBox(height: sectionSpacing),
              // Section title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  sectionName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
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
        }).toList(),
      ],
    );
  }

  /// Build simple items (backward compatibility)
  Widget _buildSimpleItems() {
    return direction == Axis.horizontal
        ? Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 4,
            children: items.map((e) => _buildItem(e)).toList(),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((e) => _buildItem(e)).toList(),
          );
  }

  Widget _buildItem(T item) {
    final selected = state.value == item;

    return Padding(
      padding: EdgeInsets.only(
        top: itemMarginTop,
        bottom: itemMarginBottom,
      ),
      child: StatefulBuilder(
        builder: (context, setHoverState) {
          return MouseRegion(
            onEnter: (_) => setHoverState(() {}),
            onExit: (_) => setHoverState(() {}),
            child: Builder(
              builder: (context) {
                final containerColor = selected
                    ? (selectedItemBackgroundColor ??
                        activeColor.withValues(alpha: 0.1))
                    : Colors.transparent;

                final itemBox = AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: containerColor,
                    border: itemBorderColor != null
                        ? Border.all(
                            color: selected ? activeColor : itemBorderColor!,
                            width: selected
                                ? itemBorderWidth + 0.5
                                : itemBorderWidth,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(itemBorderRadius),
                    boxShadow: itemShadow && selected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: InkWell(
                    onTap: () {
                      state.didChange(item);
                      onChanged(item);
                    },
                    hoverColor: (hoverBackgroundColor ?? activeColor)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(itemBorderRadius),
                    child: Padding(
                      padding: itemPadding,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Custom radio button indicator (replaces Radio widget)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? activeColor : Colors.grey,
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
                                        color: activeColor,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          itemBuilder != null
                              ? Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: textRightPadding +
                                          itemTextMarginRight,
                                    ),
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        color: selected
                                            ? (selectedItemTextColor ??
                                                Colors.black87)
                                            : Colors.black54,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                      child: itemBuilder!(item, selected),
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: textRightPadding +
                                          itemTextMarginRight,
                                    ),
                                    child: Text(
                                      itemLabelBuilder != null
                                          ? itemLabelBuilder!(item)
                                          : item.toString(),
                                      style: TextStyle(
                                        color: selected
                                            ? (selectedItemTextColor ??
                                                Colors.black87)
                                            : Colors.black54,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: selected ? 14 : 13.5,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                );

                // Wrap with border container if no itemBorderColor
                if (itemBorderColor == null) {
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
