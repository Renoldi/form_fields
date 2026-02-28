import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'localization/form_fields_localizations.dart';
import 'utilities/enums.dart';
import 'providers/form_fields_dropdown_notifier.dart';

class FormFieldsDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String label;
  final ValueChanged<T?>? onChanged;
  final T? initialValue;
  final String? Function(T?)? validator;
  final bool isRequired;
  final String Function(T item)? itemLabelBuilder;
  final LabelPosition labelPosition;
  final BorderType borderType;
  final double radius;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;
  final InputDecoration? decoration;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;
  final bool enabled;
  final bool enableFilter;
  final String? filterHintText;

  FormFieldsDropdown({
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
    this.radius = 10,
    this.borderColor = const Color(0xFFC7C7C7),
    this.focusedBorderColor = Colors.blue,
    this.errorBorderColor = Colors.red,
    this.decoration,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.enabled = true,
    this.enableFilter = false,
    this.filterHintText,
  }) : assert(
          items.isEmpty ||
              initialValue == null ||
              items.where((item) => item == initialValue).length == 1,
          "There should be exactly one item with the dropdown's value: $initialValue. Either zero or 2 or more items were detected with the same value",
        );

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
              if (widget.isRequired && value == null) {
                return l.select(widget.label);
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
                    : item.toString();
                return label
                    .toLowerCase()
                    .contains(filterState[0].toLowerCase());
              }).toList();

              return AlertDialog(
                title: Text(l10n.select(widget.label)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    children: [
                      FormField<String>(
                        initialValue: filterState[0],
                        builder: (formFieldState) {
                          return TextFormField(
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

                            return ListTile(
                              title: Text(
                                widget.itemLabelBuilder != null
                                    ? widget.itemLabelBuilder!(item)
                                    : item.toString(),
                              ),
                              selected: isSelected,
                              onTap: () {
                                tempSelected = item;
                                state.didChange(item);
                                widget.onChanged?.call(item);
                                Navigator.pop(context);
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
                    child: Text(l10n.cancel),
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
        final effectiveDecoration = (widget.decoration ??
                InputDecoration(
                  hintText: widget.hintText ?? l10n.select(widget.label),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                ))
            .copyWith(
          errorText: state.errorText,
          border: _buildBorder(
              widget.borderType, widget.borderColor, widget.radius),
          enabledBorder: _buildBorder(
              widget.borderType, widget.borderColor, widget.radius),
          focusedBorder: _buildBorder(
              widget.borderType, widget.focusedBorderColor, widget.radius),
          errorBorder: _buildBorder(
              widget.borderType, widget.errorBorderColor, widget.radius),
          focusedErrorBorder: _buildBorder(
              widget.borderType, widget.errorBorderColor, widget.radius),
        );

        // When filter is enabled, use dialog instead of dropdown
        if (widget.enableFilter && widget.enabled) {
          String currentValueText = '';
          if (state.value != null) {
            if (widget.itemLabelBuilder != null && state.value != null) {
              currentValueText = widget.itemLabelBuilder!(state.value as T);
            } else {
              currentValueText = state.value.toString();
            }
          }

          final field = InkWell(
            onTap: () => openFilterDialog(context),
            child: InputDecorator(
              decoration: effectiveDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentValueText.isEmpty
                          ? (widget.hintText ?? l10n.select(widget.label))
                          : currentValueText,
                      style: TextStyle(
                        color: currentValueText.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
                ],
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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
              ),
              const SizedBox(height: 8),
              field,
            ],
          );
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
                        : item.toString(),
                  ),
                ),
              )
              .toList(),
          onChanged: widget.enabled
              ? (value) {
                  state.didChange(value);
                  widget.onChanged?.call(value);
                }
              : null,
          decoration: effectiveDecoration,
        );

        if (widget.labelPosition == LabelPosition.none) {
          return dropdown;
        }

        final labelText = widget.label;
        final requiredIndicator = widget.isRequired ? ' *' : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: labelText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.isRequired)
                    TextSpan(
                      text: requiredIndicator,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            dropdown,
          ],
        );
      },
    );
  }

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
