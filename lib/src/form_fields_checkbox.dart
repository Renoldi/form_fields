import 'package:flutter/material.dart';

class FormFieldsCheckbox<T> extends FormField<List<T>> {
  FormFieldsCheckbox({
    super.key,
    required String label,
    required List<T> items,
    required ValueChanged<List<T>> onChanged,
    List<T>? initialValue,
    bool isRequired = false,
    Axis direction = Axis.vertical,
    double radius = 10,
    Color borderColor = const Color(0xFFC7C7C7),
    Color errorBorderColor = Colors.red,
    Color activeColor = Colors.blue,
    EdgeInsets itemPadding = const EdgeInsets.symmetric(vertical: 6),
    String Function(T item)? itemLabelBuilder,
    Widget Function(T item, bool selected)? itemBuilder,
    FormFieldValidator<List<T>>? validator,
  }) : super(
          initialValue: initialValue ?? [],
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "Select at least one $label";
            }
            return validator?.call(value ?? []);
          },
          builder: (FormFieldState<List<T>> state) {
            return _FormFieldsCheckboxBody<T>(
              label: label,
              state: state,
              items: items,
              onChanged: onChanged,
              direction: direction,
              radius: radius,
              borderColor: borderColor,
              errorBorderColor: errorBorderColor,
              activeColor: activeColor,
              itemPadding: itemPadding,
              itemLabelBuilder: itemLabelBuilder,
              itemBuilder: itemBuilder,
              isRequired: isRequired,
            );
          },
        );
}

class _FormFieldsCheckboxBody<T> extends StatelessWidget {
  final String label;
  final FormFieldState<List<T>> state;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final Axis direction;
  final double radius;
  final Color borderColor;
  final Color errorBorderColor;
  final Color activeColor;
  final EdgeInsets itemPadding;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final bool isRequired;

  const _FormFieldsCheckboxBody({
    required this.label,
    required this.state,
    required this.items,
    required this.onChanged,
    required this.direction,
    required this.radius,
    required this.borderColor,
    required this.errorBorderColor,
    required this.activeColor,
    required this.itemPadding,
    this.itemLabelBuilder,
    this.itemBuilder,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValues = state.value ?? [];
    final hasError = state.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? errorBorderColor : borderColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: direction == Axis.horizontal
              ? Wrap(
                  children: items
                      .map((item) => _buildItem(item, selectedValues))
                      .toList(),
                )
              : Column(
                  children: items
                      .map((item) => _buildItem(item, selectedValues))
                      .toList(),
                ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.errorText!,
              style: TextStyle(
                color: errorBorderColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItem(T item, List<T> selectedValues) {
    final isSelected = selectedValues.contains(item);

    return InkWell(
      onTap: () {
        final updated = List<T>.from(selectedValues);

        if (isSelected) {
          updated.remove(item);
        } else {
          updated.add(item);
        }

        state.didChange(updated);
        onChanged(updated);
      },
      child: Padding(
        padding: itemPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              activeColor: activeColor,
              onChanged: (checked) {
                final updated = List<T>.from(selectedValues);

                if (checked == true) {
                  updated.add(item);
                } else {
                  updated.remove(item);
                }

                state.didChange(updated);
                onChanged(updated);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: itemBuilder != null
                  ? itemBuilder!(item, isSelected)
                  : Text(
                      itemLabelBuilder != null
                          ? itemLabelBuilder!(item)
                          : item.toString(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
