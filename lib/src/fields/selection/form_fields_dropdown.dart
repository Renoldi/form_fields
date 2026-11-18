import 'package:material_ui/material_ui.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/providers/form_fields_dropdown_notifier.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
import 'package:provider/provider.dart';

part 'form_fields_dropdown_parts/content.dart';

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
    this.backgroundColor,
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
  void dispose() {
    // Created in initState and never released before.
    _notifier.dispose();
    super.dispose();
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
              widget.initialValue,
              widget.items,
            ),
            validator: (value) {
              if (widget.externalErrorText != null &&
                  widget.externalErrorText!.isNotEmpty) {
                return widget.externalErrorText;
              }
              if (widget.isRequired && value == null) {
                return l.select(widget.label.toTitleCases);
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
}
