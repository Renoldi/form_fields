import 'package:flutter/material.dart';
import 'enums.dart';

class FormFieldsDropdownMulti<T> extends FormField<List<T>> {
  FormFieldsDropdownMulti({
    super.key,
    required String label,
    required List<T> items,
    required ValueChanged<List<T>> onChanged,
    List<T>? initialValues,
    String Function(T item)? itemLabelBuilder,

    // validation
    String? Function(List<T>?)? validator,
    bool isRequired = false,
    int? minSelections,
    int? maxSelections,

    // UI
    LabelPosition labelPosition = LabelPosition.top,
    BorderType borderType = BorderType.outlineInputBorder,
    double radius = 10,
    Color borderColor = const Color(0xFFC7C7C7),
    Color focusedBorderColor = Colors.blue,
    Color errorBorderColor = Colors.red,
    String? hintText,
    bool showItemCount = false,

    // chip
    Color? chipBackgroundColor,
    Color? chipTextColor,
    Color? chipDeleteIconColor,
  }) : super(
          initialValue: initialValues ?? [],
          validator: (values) {
            final selected = values ?? [];

            if (isRequired && selected.isEmpty) {
              return 'Select at least one $label';
            }

            if (minSelections != null && selected.length < minSelections) {
              return 'Select at least $minSelections items';
            }

            if (maxSelections != null && selected.length > maxSelections) {
              return 'Select at most $maxSelections items';
            }

            if (validator != null) {
              return validator(selected);
            }

            return null;
          },
          builder: (FormFieldState<List<T>> state) {
            final selectedItems = state.value ?? [];

            void openDialog(BuildContext context) {
              final tempSelected = selectedItems.toSet();

              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      return AlertDialog(
                        title: Text('Select $label'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: items.map((item) {
                              final isSelected = tempSelected.contains(item);

                              return CheckboxListTile(
                                title: Text(
                                  itemLabelBuilder != null
                                      ? itemLabelBuilder(item)
                                      : item.toString(),
                                ),
                                value: isSelected,
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      if (maxSelections == null ||
                                          tempSelected.length < maxSelections) {
                                        tempSelected.add(item);
                                      }
                                    } else {
                                      tempSelected.remove(item);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final updated = tempSelected.toList();
                              state.didChange(updated);
                              onChanged(updated);
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            }

            final border = _buildBorder(
              borderType,
              state.hasError ? errorBorderColor : borderColor,
              radius,
            );

            final field = InkWell(
              onTap: () => openDialog(state.context),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: hintText ?? 'Select $label',
                  errorText: state.errorText,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: _buildBorder(
                    borderType,
                    focusedBorderColor,
                    radius,
                  ),
                ),
                child: selectedItems.isEmpty
                    ? Text(
                        hintText ?? 'Select $label',
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
                              itemLabelBuilder != null
                                  ? itemLabelBuilder(item)
                                  : item.toString(),
                              style: TextStyle(
                                color: chipTextColor ?? Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: chipBackgroundColor ?? Colors.blue,
                            deleteIconColor:
                                chipDeleteIconColor ?? Colors.white,
                            onDeleted: () {
                              final updated = List<T>.from(selectedItems)
                                ..remove(item);
                              state.didChange(updated);
                              onChanged(updated);
                            },
                          );
                        }).toList(),
                      ),
              ),
            );

            if (labelPosition == LabelPosition.none) {
              return field;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (isRequired)
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
                if (showItemCount)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${selectedItems.length} of ${items.length} selected',
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

  static InputBorder _buildBorder(
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
