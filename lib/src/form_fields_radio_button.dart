import 'package:flutter/material.dart';

class FormFieldsRadioButton<T> extends FormField<T> {
  FormFieldsRadioButton({
    super.key,
    required String label,
    required List<T> items,
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
    EdgeInsets itemPadding = const EdgeInsets.symmetric(vertical: 8),
    FormFieldValidator<T>? validator,
  }) : super(
          initialValue: initialValue,
          validator: (value) {
            if (isRequired && value == null) {
              return "Select $label";
            }
            return validator?.call(value);
          },
          builder: (FormFieldState<T> state) {
            return _FormFieldsRadioButtonBody<T>(
              label: label,
              state: state,
              items: items,
              onChanged: onChanged,
              itemLabelBuilder: itemLabelBuilder,
              itemBuilder: itemBuilder,
              direction: direction,
              radius: radius,
              borderColor: borderColor,
              errorBorderColor: errorBorderColor,
              activeColor: activeColor,
              itemPadding: itemPadding,
            );
          },
        );
}

class _FormFieldsRadioButtonBody<T> extends StatelessWidget {
  final String label;
  final FormFieldState<T> state;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final Axis direction;
  final double radius;
  final Color borderColor;
  final Color errorBorderColor;
  final Color activeColor;
  final EdgeInsets itemPadding;

  const _FormFieldsRadioButtonBody({
    required this.label,
    required this.state,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
    this.itemBuilder,
    required this.direction,
    required this.radius,
    required this.borderColor,
    required this.errorBorderColor,
    required this.activeColor,
    required this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = state.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Radio Container
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? errorBorderColor : borderColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RadioGroup<T>(
            groupValue: state.value,
            onChanged: (value) {
              state.didChange(value);
              onChanged(value);
            },
            child: direction == Axis.horizontal
                ? Wrap(
                    children: items.map((e) => _buildItem(e)).toList(),
                  )
                : Column(
                    children: items.map((e) => _buildItem(e)).toList(),
                  ),
          ),
        ),

        // Error
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

  Widget _buildItem(T item) {
    final selected = state.value == item;

    return InkWell(
      onTap: () {
        state.didChange(item);
        onChanged(item);
      },
      child: Padding(
        padding: itemPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<T>(
              value: item,
              activeColor: activeColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: itemBuilder != null
                  ? itemBuilder!(item, selected)
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
