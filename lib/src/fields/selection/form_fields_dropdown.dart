import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/providers/form_fields_dropdown_notifier.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
import 'package:provider/provider.dart';

class FormFieldsDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String label;
  final ValueChanged<T?>? onChanged;
  final T? initialValue;
  final String? Function(T?)? validator;
  final bool isRequired;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final LabelPosition labelPosition;
  final BorderType borderType;
  // visual styling controlled by `borderType` and theme
  final InputDecoration? decoration;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;
  final bool enabled;
  final bool enableFilter;
  final String? filterHintText;
  final String? externalErrorText;
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;
  final Color? selectedItemBackgroundColor;
  final Color? selectedItemTextColor;
  final TextStyle? textStyle;

  const FormFieldsDropdown({
    super.key,
    required this.items,
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.isRequired = false,
    this.itemLabelBuilder,
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.outlineInputBorder,
    this.decoration,
    this.itemBuilder,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.enabled = true,
    this.enableFilter = false,
    this.filterHintText,
    this.externalErrorText,
    this.readOnly = false,
    this.backgroundColor = Colors.white,
    this.filled = true,
    this.textStyle,
    this.selectedItemBackgroundColor,
    this.selectedItemTextColor,
  });

  @override
  State<FormFieldsDropdown<T>> createState() => _FormFieldsDropdownState<T>();

  static T? _sanitizeInitialValue<T>(T? value, List<T> items) {
    if (value == null) return null;
    try {
      if (items.contains(value)) {
        return value;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class _FormFieldsDropdownState<T> extends State<FormFieldsDropdown<T>> {
  late GlobalKey<FormFieldState<T>> _formKey;
  late FormFieldsDropdownNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormFieldState<T>>();
    _notifier = FormFieldsDropdownNotifier();
  }

  @override
  void didUpdateWidget(covariant FormFieldsDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalErrorText != widget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild when locale changes to update localized strings
    _notifier.rebuildOnLocaleChange();
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _notifier,
      child: Consumer<FormFieldsDropdownNotifier>(
        builder: (context, notifier, _) {
          return FormField<T>(
            key: _formKey,
            initialValue: FormFieldsDropdown._sanitizeInitialValue(
                widget.initialValue, widget.items),
            validator: (value) {
              if (widget.externalErrorText != null &&
                  widget.externalErrorText!.isNotEmpty) {
                return widget.externalErrorText;
              }
              if (widget.isRequired && value == null) {
                return l.select(widget.label.toTitleCase);
              }
              if (widget.validator != null) {
                return widget.validator!(value);
              }
              return null;
            },
            onSaved: (_) {},
            builder: (FormFieldState<T> state) {
              return _buildDropdownContent(context, state, widget);
            },
          );
        },
      ),
    );
  }

  Widget _buildDropdownContent(BuildContext context, FormFieldState<T> state,
      FormFieldsDropdown<T> widget) {
    void openFilterDialog(BuildContext context) {
      final l10n = FormFieldsLocalizations.of(context);
      final filterState = <String>[''];
      T? tempSelected = state.value;

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final filteredItems = widget.items.where((item) {
                final label = widget.itemLabelBuilder != null
                    ? widget.itemLabelBuilder!(item)
                    : item.toString().toBegin;
                return label
                    .toLowerCase()
                    .contains(filterState[0].toLowerCase());
              }).toList();

              return AlertDialog(
                title: Text(l10n.select(widget.label.toTitleCase)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    children: [
                      FormField<String>(
                        initialValue: filterState[0],
                        builder: (formFieldState) {
                          return TextField(
                            decoration: InputDecoration(
                              hintText:
                                  widget.filterHintText ?? l10n.searchHint,
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                filterState[0] = value;
                                formFieldState.didChange(value);
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelected = tempSelected == item;

                            final txt = widget.selectedItemTextColor ??
                                widget.textStyle?.color ??
                                Theme.of(context).colorScheme.primary;
                            final bg = widget.selectedItemBackgroundColor ??
                                (txt.withValues(alpha: 0.12));

                            Widget titleContent;
                            if (widget.itemBuilder != null) {
                              titleContent = DefaultTextStyle(
                                style: TextStyle(
                                  color: isSelected
                                      ? (widget.selectedItemTextColor ??
                                          resolveTextColor(context))
                                      : resolveTextColor(context, muted: true),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                child: widget.itemBuilder!(item, isSelected),
                              );
                            } else {
                              titleContent = Text(
                                widget.itemLabelBuilder != null
                                    ? widget.itemLabelBuilder!(item)
                                    : item.toString().toBegin,
                              );
                            }

                            return ListTileTheme(
                              data: ListTileTheme.of(context).copyWith(
                                selectedTileColor: bg,
                                selectedColor: txt,
                              ),
                              child: ListTile(
                                title: titleContent,
                                selected: isSelected,
                                selectedTileColor: bg,
                                selectedColor: txt,
                                onTap: () {
                                  tempSelected = item;
                                  widget.onChanged?.call(item);
                                  state.didChange(item);
                                  state.validate();
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  SizedBox(
                    width: 92,
                    child: AppButton(
                      type: AppButtonType.outlined,
                      size: AppSize.small,
                      text: l10n.cancel,
                      useSafeArea: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return StatefulBuilder(
      builder: (context, setStateDropdown) {
        final l10n = FormFieldsLocalizations.of(context);

        final baseDecoration = widget.decoration ??
            InputDecoration(
              hintText:
                  widget.hintText ?? l10n.select(widget.label.toTitleCase),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
            );

        final fillColor = widget.decoration?.fillColor ??
            widget.backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest;

        final effectiveDecoration = baseDecoration.copyWith(
          filled: widget.filled,
          fillColor: widget.filled ? fillColor : null,
          errorText: (state.errorText != null && state.errorText!.isNotEmpty)
              ? state.errorText
              : (state.hasError ? l10n.select(widget.label.toTitleCase) : null),
          border: _buildBorder(context, widget.borderType),
          enabledBorder: _buildBorder(context, widget.borderType),
          focusedBorder:
              _buildBorder(context, widget.borderType, isFocused: true),
          errorBorder: _buildBorder(context, widget.borderType, isError: true),
          focusedErrorBorder: _buildBorder(context, widget.borderType,
              isError: true, isFocused: true),
        );

        // When filter is enabled, use dialog instead of dropdown
        if (widget.enableFilter && widget.enabled) {
          String currentValueText = '';
          if (state.value != null) {
            if (widget.itemLabelBuilder != null && state.value != null) {
              currentValueText = widget.itemLabelBuilder!(state.value as T);
            } else {
              currentValueText = state.value.toString().toBegin;
            }
          }

          final field = InkWell(
            onTap: (widget.readOnly || !widget.enabled)
                ? null
                : () => openFilterDialog(context),
            child: InputDecorator(
              decoration: effectiveDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentValueText.isEmpty
                          ? (widget.hintText ??
                              l10n.select(widget.label.toTitleCase))
                          : currentValueText,
                      style: TextStyle(
                        color: currentValueText.isEmpty
                            ? Theme.of(context).disabledColor
                            : (widget.textStyle?.color ??
                                resolveTextColor(context)),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: Theme.of(context).iconTheme.color),
                ],
              ),
            ),
          );
          final theme = Theme.of(context);
          Widget labelWidget = RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.label.toTitleCase,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textStyle?.color ?? resolveTextColor(context),
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

          switch (widget.labelPosition) {
            case LabelPosition.top:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelWidget, const SizedBox(height: 8), field],
                ),
              );
            case LabelPosition.bottom:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [field, const SizedBox(height: 8), labelWidget],
                ),
              );
            case LabelPosition.left:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    labelWidget,
                    const SizedBox(width: 12),
                    Expanded(child: field),
                  ],
                ),
              );
            case LabelPosition.right:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 12),
                    labelWidget,
                  ],
                ),
              );
            case LabelPosition.inBorder:
              // Let InputDecoration handle floating label
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: field,
              );
            case LabelPosition.none:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: field,
              );
          }
        }

        // Regular dropdown without filter
        final filteredItems = widget.items;

        final dropdown = DropdownButtonFormField<T>(
          initialValue: state.value,
          items: filteredItems
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    widget.itemLabelBuilder != null
                        ? widget.itemLabelBuilder!(item)
                        : item.toString().toBegin,
                  ),
                ),
              )
              .toList(),
          onChanged: (widget.enabled && !widget.readOnly)
              ? (value) {
                  widget.onChanged?.call(value);
                  state.didChange(value);
                  // Validate immediately so externalErrorText is cleared when valid
                  state.validate();
                }
              : null,
          decoration: effectiveDecoration,
        );

        final theme = Theme.of(context);
        Widget labelWidget = RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.label.toTitleCase,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: resolveTextColor(context),
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

        switch (widget.labelPosition) {
          case LabelPosition.top:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [labelWidget, const SizedBox(height: 8), dropdown],
              ),
            );
          case LabelPosition.bottom:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [dropdown, const SizedBox(height: 8), labelWidget],
              ),
            );
          case LabelPosition.left:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  labelWidget,
                  const SizedBox(width: 12),
                  Expanded(child: dropdown),
                ],
              ),
            );
          case LabelPosition.right:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: dropdown),
                  const SizedBox(width: 12),
                  labelWidget,
                ],
              ),
            );
          case LabelPosition.inBorder:
            // Let InputDecoration handle floating label
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: dropdown,
            );
          case LabelPosition.none:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: dropdown,
            );
        }
      },
    );
  }

  static InputBorder _buildBorder(BuildContext context, BorderType type,
      {bool isError = false, bool isFocused = false}) {
    final theme = Theme.of(context);
    final normalColor = theme.dividerColor;
    final focusColor = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;
    final color = isError ? errorColor : (isFocused ? focusColor : normalColor);
    const radius = 8.0;

    switch (type) {
      case BorderType.none:
        return InputBorder.none;
      case BorderType.underlineInputBorder:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: color),
        );
      case BorderType.outlineInputBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: isFocused ? 1.8 : 1.5),
        );
    }
  }
}
