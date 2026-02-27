import 'package:flutter/material.dart';
import 'localization/form_fields_localizations.dart';
import 'utilities/enums.dart';

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
  final double radius;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;
  final String? hintText;
  final bool showItemCount;
  final Color? chipBackgroundColor;
  final Color? chipTextColor;
  final Color? chipDeleteIconColor;
  final bool enableFilter;
  final String? filterHintText;

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
    this.radius = 10,
    this.borderColor = const Color(0xFFC7C7C7),
    this.focusedBorderColor = Colors.blue,
    this.errorBorderColor = Colors.red,
    this.hintText,
    this.showItemCount = false,
    this.chipBackgroundColor,
    this.chipTextColor,
    this.chipDeleteIconColor,
    this.enableFilter = false,
    this.filterHintText,
  });

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
  Widget build(BuildContext context) {
    final l10n = FormFieldsLocalizations.of(context);
    return FormField<List<T>>(
      key: _formKey,
      initialValue: widget.initialValues ?? [],
      validator: (values) {
        final selected = values ?? [];

        if (widget.isRequired && selected.isEmpty) {
          return l10n.selectAtLeastOne(widget.label);
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
                              : item.toString();
                          return label
                              .toLowerCase()
                              .contains(filterState[0].toLowerCase());
                        }).toList()
                      : widget.items;

                  return AlertDialog(
                    title: Text(dialogL10n.select(widget.label)),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Column(
                        children: [
                          if (widget.enableFilter)
                            Column(
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: widget.filterHintText ??
                                        dialogL10n.searchHint,
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      filterState[0] = value;
                                    });
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
                                        : item.toString(),
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
                          state.didChange(updated);
                          widget.onChanged(updated);
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

        final border = _buildBorder(
          widget.borderType,
          state.hasError ? widget.errorBorderColor : widget.borderColor,
          widget.radius,
        );

        final field = InkWell(
          onTap: () => openDialog(state.context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: widget.hintText ?? l10n.select(widget.label),
              errorText: state.errorText,
              border: border,
              enabledBorder: border,
              focusedBorder: _buildBorder(
                widget.borderType,
                widget.focusedBorderColor,
                widget.radius,
              ),
            ),
            child: selectedItems.isEmpty
                ? Text(
                    widget.hintText ?? l10n.select(widget.label),
                    style: TextStyle(
                      color: Colors.grey.shade600,
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
                              : item.toString(),
                          style: TextStyle(
                            color: widget.chipTextColor ?? Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor:
                            widget.chipBackgroundColor ?? Colors.blue,
                        deleteIconColor:
                            widget.chipDeleteIconColor ?? Colors.white,
                        onDeleted: () {
                          final updated = List<T>.from(selectedItems)
                            ..remove(item);
                          state.didChange(updated);
                          widget.onChanged(updated);
                        },
                      );
                    }).toList(),
                  ),
          ),
        );

        if (widget.labelPosition == LabelPosition.none) {
          return field;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            field,
            if (widget.showItemCount)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${selectedItems.length} of ${widget.items.length} selected',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  InputBorder _buildBorder(
    BorderType type,
    Color color,
    double radius,
  ) {
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
          borderSide: BorderSide(color: color, width: 1.5),
        );
    }
  }
}
