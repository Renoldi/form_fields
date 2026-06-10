import 'package:flutter/material.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/theme_helpers.dart';
import '../../utilities/extensions.dart';

class FormFieldsRadioButton<T> extends StatefulWidget {
  final String? externalErrorText;
  final String label;
  final List<T>? items;
  final Map<String, List<T>>? sections;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final T? initialValue;
  final bool isRequired;
  final Axis direction;
  final BorderType borderType;
  final Color? activeColor;
  final TextStyle? textStyle;
  final EdgeInsets itemPadding;
  final double sectionSpacing;
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
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final FormFieldValidator<T>? validator;
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;

  const FormFieldsRadioButton({
    super.key,
    required this.label,
    this.items,
    this.sections,
    required this.onChanged,
    this.itemLabelBuilder,
    this.itemBuilder,
    this.initialValue,
    this.isRequired = false,
    this.direction = Axis.vertical,
    this.borderType = BorderType.outlineInputBorder,
    this.activeColor,
    this.textStyle,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    this.sectionSpacing = 12,
    this.itemBorderColor,
    this.itemBorderWidth = 1.0,
    this.itemBorderRadius = 8,
    this.textRightPadding = 0,
    this.itemTextMarginRight = 0,
    this.selectedItemBackgroundColor,
    this.selectedItemTextColor,
    this.hoverBackgroundColor,
    this.itemShadow = false,
    this.labelPosition = LabelPosition.top,
    this.containerPadding = 12,
    this.containerGap = 8,
    this.itemMarginTop = 4,
    this.itemMarginBottom = 4,
    this.indicatorVerticalAlignment = IndicatorVerticalAlignment.center,
    this.horizontalSideBySide = false,
    this.validator,
    this.readOnly = false,
    this.externalErrorText,
    this.backgroundColor,
    this.filled = true,
  }) : assert(items != null || sections != null,
            'Either items or sections must be provided');

  @override
  State<FormFieldsRadioButton<T>> createState() =>
      _FormFieldsRadioButtonState<T>();
}

class _FormFieldsRadioButtonState<T> extends State<FormFieldsRadioButton<T>> {
  late final GlobalKey<FormFieldState<T>> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormFieldState<T>>();
  }

  @override
  void didUpdateWidget(covariant FormFieldsRadioButton<T> oldWidget) {
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
    return FormField<T>(
      key: _formKey,
      initialValue: widget.initialValue,
      validator: (value) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        if (widget.isRequired && value == null) {
          return l.getWithLabel('selectRequired', widget.label.toTitleCase);
        }
        if (widget.validator != null) return widget.validator!(value);
        return null;
      },
      builder: (FormFieldState<T> state) {
        return _FormFieldsRadioButtonBody<T>(
          label: widget.label,
          state: state,
          items: widget.items ?? [],
          sections: widget.sections ?? {},
          onChanged: widget.onChanged,
          itemLabelBuilder: widget.itemLabelBuilder,
          itemBuilder: widget.itemBuilder,
          direction: widget.direction,
          borderType: widget.borderType,
          activeColor: widget.activeColor,
          textStyle: widget.textStyle,
          itemPadding: widget.itemPadding,
          isRequired: widget.isRequired,
          sectionSpacing: widget.sectionSpacing,
          itemBorderColor: widget.itemBorderColor,
          itemBorderWidth: widget.itemBorderWidth,
          itemBorderRadius: widget.itemBorderRadius,
          textRightPadding: widget.textRightPadding,
          itemTextMarginRight: widget.itemTextMarginRight,
          selectedItemBackgroundColor: widget.selectedItemBackgroundColor,
          selectedItemTextColor: widget.selectedItemTextColor,
          hoverBackgroundColor: widget.hoverBackgroundColor,
          itemShadow: widget.itemShadow,
          labelPosition: widget.labelPosition,
          containerPadding: widget.containerPadding,
          containerGap: widget.containerGap,
          itemMarginTop: widget.itemMarginTop,
          itemMarginBottom: widget.itemMarginBottom,
          indicatorVerticalAlignment: widget.indicatorVerticalAlignment,
          horizontalSideBySide: widget.horizontalSideBySide,
          readOnly: widget.readOnly,
          backgroundColor: widget.backgroundColor,
          filled: widget.filled,
        );
      },
    );
  }
}

class _FormFieldsRadioButtonBody<T> extends StatefulWidget {
  final String label;
  final FormFieldState<T> state;
  final List<T> items;
  final Map<String, List<T>> sections;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final Axis direction;
  final BorderType borderType;
  final Color? activeColor;
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
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;
  final TextStyle? textStyle;

  const _FormFieldsRadioButtonBody({
    required this.label,
    required this.state,
    required this.items,
    required this.sections,
    required this.onChanged,
    this.itemLabelBuilder,
    this.itemBuilder,
    required this.direction,
    required this.borderType,
    this.activeColor,
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
    required this.indicatorVerticalAlignment,
    required this.horizontalSideBySide,
    required this.readOnly,
    this.textStyle,
    this.backgroundColor,
    this.filled = true,
  });

  @override
  State<_FormFieldsRadioButtonBody<T>> createState() =>
      _FormFieldsRadioButtonBodyView<T>();
}

abstract class _FormFieldsRadioButtonBodyPresenterState<T>
    extends State<_FormFieldsRadioButtonBody<T>> {
  late final _FormFieldsRadioButtonBodyViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _FormFieldsRadioButtonBodyViewModel();
  }
}

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
            text: widget.label.toTitleCase,
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
                color: hasError ? errorColor : normalColor, width: 1.5))
        : null;

    final radioContainer = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.filled
            ? (widget.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest)
            : null,
        border: containerBorder,
        borderRadius:
            widget.itemBorderColor == null ? BorderRadius.circular(10) : null,
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
                  : l.getWithLabel('selectRequired', widget.label.toTitleCase),
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 12,
              ),
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
                  children: [
                    radioContainer,
                    errorWidget,
                  ],
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
                  children: [
                    radioContainer,
                    errorWidget,
                  ],
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
            children: [
              radioContainer,
              errorWidget,
            ],
          ),
        );
      case LabelPosition.none:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              radioContainer,
              errorWidget,
            ],
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
                        _effectiveActiveColor(context).withValues(alpha: 0.12))
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
                    borderRadius:
                        BorderRadius.circular(widget.itemBorderRadius),
                    boxShadow: widget.itemShadow && selected
                        ? [
                            BoxShadow(
                              color: _effectiveActiveColor(context)
                                  .withValues(alpha: 0.15),
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
                    hoverColor: (widget.hoverBackgroundColor ??
                            _effectiveActiveColor(context))
                        .withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(widget.itemBorderRadius),
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
                            Expanded(
                              child: itemContent,
                            ),
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

class _FormFieldsRadioButtonBodyViewModel {}
