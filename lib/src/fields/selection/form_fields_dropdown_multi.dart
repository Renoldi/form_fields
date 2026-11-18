import 'package:material_ui/material_ui.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
part 'form_fields_dropdown_multi_parts/field.dart';

class FormFieldsDropdownMulti<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final List<T>? initialValues;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
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
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;
  final Color? selectedItemBackgroundColor;
  final Color? selectedItemTextColor;
  final TextStyle? textStyle;

  const FormFieldsDropdownMulti({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.initialValues,
    this.itemLabelBuilder,
    this.itemBuilder,
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
    this.readOnly = false,
    this.backgroundColor,
    this.filled = true,
    this.textStyle,
    this.selectedItemBackgroundColor,
    this.selectedItemTextColor,
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
          return l10n.selectAtLeastOne(widget.label.toTitleCases);
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
      builder: (FormFieldState<List<T>> state) =>
          _buildMultiField(context, state, l10n),
    );
  }

  InputBorder _buildBorder(
    BuildContext context,
    BorderType type, {
    bool isError = false,
    bool isFocused = false,
  }) {
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
        return UnderlineInputBorder(borderSide: BorderSide(color: color));
      case BorderType.outlineInputBorder:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: isFocused ? 1.8 : 1.5),
        );
    }
  }
}
