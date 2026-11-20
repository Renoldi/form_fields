import 'package:material_ui/material_ui.dart';
import '../../utilities/enums.dart';
import '../../localization/form_fields_localizations.dart';
import '../../utilities/theme_helpers.dart';
import '../../utilities/extensions.dart';
import 'selection_field_common.dart';
part 'form_fields_radio_button_parts/state.dart';
part 'form_fields_radio_button_parts/body.dart';
part 'form_fields_radio_button_parts/body_view.dart';

class FormFieldsRadioButton<T> extends StatefulWidget {
  final String? externalErrorText;
  final String label;
  final List<T>? items;
  final Map<String, List<T>>? sections;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final Widget Function(T item, bool selected)? itemBuilder;
  final T? initialValue;
  final bool isRequired;
  final Axis direction;
  final BorderType borderType;
  final Color? activeColor;
  final TextStyle? textStyle;
  final EdgeInsets itemPadding;
  final double sectionSpacing;
  final Color? itemBorderColor;
  final double itemBorderWidth;
  final double itemBorderRadius;
  final double textRightPadding;
  final double itemTextMarginRight;
  final Color? selectedItemBackgroundColor;
  final Color? selectedItemTextColor;
  final Color? hoverBackgroundColor;
  final bool itemShadow;
  final LabelPosition labelPosition;
  final double containerPadding;
  final double containerGap;
  final double itemMarginTop;
  final double itemMarginBottom;
  final IndicatorVerticalAlignment indicatorVerticalAlignment;
  final bool horizontalSideBySide;
  final FormFieldValidator<T>? validator;
  final bool readOnly;
  final Color? backgroundColor;
  final bool filled;

  const FormFieldsRadioButton({
    super.key,
    required this.label,
    this.items,
    this.sections,
    required this.onChanged,
    this.itemLabelBuilder,
    this.itemBuilder,
    this.initialValue,
    this.isRequired = false,
    this.direction = Axis.vertical,
    this.borderType = BorderType.outlineInputBorder,
    this.activeColor,
    this.textStyle,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    this.sectionSpacing = 12,
    this.itemBorderColor,
    this.itemBorderWidth = 1.0,
    this.itemBorderRadius = 8,
    this.textRightPadding = 0,
    this.itemTextMarginRight = 0,
    this.selectedItemBackgroundColor,
    this.selectedItemTextColor,
    this.hoverBackgroundColor,
    this.itemShadow = false,
    this.labelPosition = LabelPosition.top,
    this.containerPadding = 12,
    this.containerGap = 8,
    this.itemMarginTop = 4,
    this.itemMarginBottom = 4,
    this.indicatorVerticalAlignment = IndicatorVerticalAlignment.center,
    this.horizontalSideBySide = false,
    this.validator,
    this.readOnly = false,
    this.externalErrorText,
    this.backgroundColor,
    this.filled = true,
  }) : assert(
         items != null || sections != null,
         'Either items or sections must be provided',
       );

  @override
  State<FormFieldsRadioButton<T>> createState() =>
      _FormFieldsRadioButtonState<T>();
}

abstract class _FormFieldsRadioButtonBodyPresenterState<T>
    extends State<_FormFieldsRadioButtonBody<T>> {
  late final _FormFieldsRadioButtonBodyViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _FormFieldsRadioButtonBodyViewModel();
  }
}

class _FormFieldsRadioButtonBodyViewModel {}
