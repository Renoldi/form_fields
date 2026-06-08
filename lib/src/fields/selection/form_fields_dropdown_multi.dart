import 'package:flutter/material.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/enums.dart';
import '../../utilities/theme_helpers.dart';
import '../../utilities/extensions.dart';

class FormFieldsDropdownMulti<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final List<T>? initialValues;
  final String Function(T item)? itemLabelBuilder;
  final String? Function(List<T>?)? validator;
  final bool isRequired;
  final int? minSelections;
  final int? maxSelections;
  final LabelPosition labelPosition;
  final BorderType borderType;
  // visual styling controlled by `borderType` and theme
  final String? hintText;
  final bool showItemCount;
  final Color? chipBackgroundColor;
  final Color? chipTextColor;
  final Color? chipDeleteIconColor;
  final bool enableFilter;
  final String? filterHintText;
  final String? externalErrorText;

  const FormFieldsDropdownMulti({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.initialValues,
    this.itemLabelBuilder,
    this.validator,
    this.isRequired = false,
    this.minSelections,
    this.maxSelections,
    this.labelPosition = LabelPosition.top,
    this.borderType = BorderType.outlineInputBorder,
    this.hintText,
    this.showItemCount = false,
    this.chipBackgroundColor,
    this.chipTextColor,
    this.chipDeleteIconColor,
    this.enableFilter = false,
    this.filterHintText,
    this.externalErrorText,
  });

// Removed duplicate createState and stray bracket

  @override
  State<FormFieldsDropdownMulti<T>> createState() =>
      _FormFieldsDropdownMultiState<T>();
}

class _FormFieldsDropdownMultiState<T>
    extends State<FormFieldsDropdownMulti<T>> {
  late GlobalKey<FormFieldState<List<T>>> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormFieldState<List<T>>>();
  }

  @override
  void didUpdateWidget(covariant FormFieldsDropdownMulti<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalErrorText != widget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FormFieldsLocalizations.of(context);
    return FormField<List<T>>(
      key: _formKey,
      initialValue: widget.initialValues ?? [],
      validator: (values) {
        if (widget.externalErrorText != null &&
            widget.externalErrorText!.isNotEmpty) {
          return widget.externalErrorText;
        }
        final selected = values ?? [];
        if (widget.isRequired && selected.isEmpty) {
          return l10n.selectAtLeastOne(widget.label.toTitleCase);
        }
        if (widget.minSelections != null &&
            selected.length < widget.minSelections!) {
          return l10n.selectAtLeast(widget.minSelections!);
        }
        if (widget.maxSelections != null &&
            selected.length > widget.maxSelections!) {
          return l10n.selectAtMost(widget.maxSelections!);
        }
        if (widget.validator != null) {
          return widget.validator!(selected);
        }
        return null;
      },
      onSaved: (_) {},
      builder: (FormFieldState<List<T>> state) {
        final selectedItems = state.value ?? [];

        void openDialog(BuildContext context) {
          final dialogL10n = FormFieldsLocalizations.of(context);
          final tempSelected = selectedItems.toSet();

          showDialog(
            context: context,
            builder: (context) {
              final filterState = <String>[''];

              return StatefulBuilder(
                builder: (context, setDialogState) {
                  final filteredItems = widget.enableFilter
                      ? widget.items.where((item) {
                          final label = widget.itemLabelBuilder != null
                              ? widget.itemLabelBuilder!(item)
                              : item.toString().toBegin;
                          return label
                              .toLowerCase()
                              .contains(filterState[0].toLowerCase());
                        }).toList()
                      : widget.items;

                  return AlertDialog(
                    title: Text(dialogL10n.select(widget.label.toTitleCase)),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Column(
                        children: [
                          if (widget.enableFilter)
                            Column(
                              children: [
                                FormField<String>(
                                  initialValue: filterState[0],
                                  builder: (formFieldState) {
                                    return TextFormField(
                                      decoration: InputDecoration(
                                        hintText: widget.filterHintText ??
                                            dialogL10n.searchHint,
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                              ],
                            ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = tempSelected.contains(item);

                                return CheckboxListTile(
                                  title: Text(
                                    widget.itemLabelBuilder != null
                                        ? widget.itemLabelBuilder!(item)
                                        : item.toString().toBegin,
                                  ),
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        if (widget.maxSelections == null ||
                                            tempSelected.length <
                                                widget.maxSelections!) {
                                          tempSelected.add(item);
                                        }
                                      } else {
                                        tempSelected.remove(item);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(dialogL10n.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final updated = tempSelected.toList();
                          widget.onChanged(updated);
                          state.didChange(updated);
                          // Re-validate so externalErrorText clears when selection is valid
                          state.validate();
                          Navigator.pop(context);
                        },
                        child: Text(dialogL10n.get('ok')),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }

        final border =
            _buildBorder(context, widget.borderType, isError: state.hasError);

        final field = InkWell(
          onTap: () => openDialog(state.context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText:
                  widget.hintText ?? l10n.select(widget.label.toTitleCase),
              errorText:
                  (state.errorText != null && state.errorText!.isNotEmpty)
                      ? state.errorText
                      : (state.hasError
                          ? l10n.selectAtLeastOne(widget.label.toTitleCase)
                          : null),
              border: border,
              enabledBorder: border,
              focusedBorder:
                  _buildBorder(context, widget.borderType, isFocused: true),
            ),
            child: selectedItems.isEmpty
                ? Text(
                    widget.hintText ?? l10n.select(widget.label.toTitleCase),
                    style: TextStyle(
                      color: resolveTextColor(context, muted: true),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedItems.map((item) {
                      return Chip(
                        label: Text(
                          widget.itemLabelBuilder != null
                              ? widget.itemLabelBuilder!(item)
                              : item.toString().toBegin,
                          style: TextStyle(
                            color: widget.chipTextColor ??
                                Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: widget.chipBackgroundColor ??
                            resolveActiveColor(context, null),
                        deleteIconColor: widget.chipDeleteIconColor ??
                            Theme.of(context).colorScheme.onPrimary,
                        onDeleted: () {
                          final updated = List<T>.from(selectedItems)
                            ..remove(item);
                          widget.onChanged(updated);
                          state.didChange(updated);
                          // Validate after deletion
                          state.validate();
                        },
                      );
                    }).toList(),
                  ),
          ),
        );

        final theme = Theme.of(context);
        final labelWidget = RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.label.toTitleCase,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: resolveTextColor(context),
                ),
              ),
              if (widget.isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        );

        Widget itemCountWidget = widget.showItemCount
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${selectedItems.length} of ${widget.items.length} selected',
                  style: TextStyle(
                    fontSize: 11,
                    color: resolveTextColor(context, muted: true),
                  ),
                ),
              )
            : const SizedBox.shrink();

        switch (widget.labelPosition) {
          case LabelPosition.top:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 8),
                field,
                itemCountWidget,
              ],
            );
          case LabelPosition.bottom:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                field,
                const SizedBox(height: 8),
                labelWidget,
                itemCountWidget,
              ],
            );
          case LabelPosition.left:
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IntrinsicWidth(child: labelWidget),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      field,
                      itemCountWidget,
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
                      field,
                      itemCountWidget,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IntrinsicWidth(child: labelWidget),
              ],
            );
          case LabelPosition.inBorder:
            return field;
          case LabelPosition.none:
            return field;
        }
      },
    );
  }

  InputBorder _buildBorder(BuildContext context, BorderType type,
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
