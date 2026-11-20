import 'package:material_ui/material_ui.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/theme_helpers.dart';
import '../../utilities/extensions.dart';
import 'selection_field_common.dart';
part 'form_fields_checkbox_parts/state.dart';
part 'form_fields_checkbox_parts/body.dart';
part 'form_fields_checkbox_parts/body_view.dart';

class FormFieldsCheckbox<T> extends StatefulWidget {
  final String? externalErrorText;
  final String label;
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final List<T>? initialValue;
  final bool isRequired;
  final Axis direction;
  final BorderType borderType;
  final Color? activeColor;
  final TextStyle? textStyle;
  final EdgeInsets itemPadding;
  final double itemMarginTop;
  final double itemMarginBottom;
  final double itemMarginHorizontal;
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final double textRightPadding;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final Color? selectedItemTextColor;
  final FormFieldValidator<List<T>>? validator;
  final LabelPosition labelPosition;
  final double containerGap;
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;

  const FormFieldsCheckbox({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.isRequired = false,
    this.direction = Axis.vertical,
    this.borderType = BorderType.outlineInputBorder,
    this.activeColor,
    this.textStyle,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 6),
    this.itemMarginTop = 4,
    this.itemMarginBottom = 4,
    this.itemMarginHorizontal = 0,
    this.indicatorVerticalAlignment = IndicatorVerticalAlignment.center,
    this.horizontalSideBySide = false,
    this.textRightPadding = 0,
    this.itemBorderColor,
    this.itemBorderWidth = 1.0,
    this.itemBorderRadius = 8,
    this.itemLabelBuilder,
    this.itemBuilder,
    this.validator,
    this.labelPosition = LabelPosition.top,
    this.containerGap = 8,
    this.readOnly = false,
    this.externalErrorText,
    this.backgroundColor,
    this.selectedItemTextColor,
    this.filled = true,
  });

  @override
  State<FormFieldsCheckbox<T>> createState() => _FormFieldsCheckboxState<T>();
}

abstract class _FormFieldsCheckboxBodyPresenterState<T>
    extends State<_FormFieldsCheckboxBody<T>> {
  late final _FormFieldsCheckboxBodyViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _FormFieldsCheckboxBodyViewModel();
  }
}

class _FormFieldsCheckboxBodyViewModel {}
