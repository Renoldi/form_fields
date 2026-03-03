import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart' as loc;
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'package:form_fields_example/ui/widgets/language_indicator.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DropdownExamplesViewModel(),
      child: Consumer<DropdownExamplesViewModel>(
        builder: (context, viewModel, _) {
          final l = loc.Localizations.of(context);
          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Language indicator showing current locale
                  const LanguageIndicator(),
// Beautiful All Label Positions Example
                  buildSectionTitle('All Label Positions (Beautiful)',
                      Colors.pink.shade700, Colors.pink.shade400),
                  buildFieldTitle('Label Top', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionTop'),
                    labelPosition: LabelPosition.top,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelTopValue,
                    onChanged: (value) => viewModel.setLabelTopValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Top)', viewModel.labelTopValue),
                  buildFieldTitle('Label Bottom', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionBottom'),
                    labelPosition: LabelPosition.bottom,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelBottomValue,
                    onChanged: (value) => viewModel.setLabelBottomValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Bottom)', viewModel.labelBottomValue),
                  buildFieldTitle('Label Left', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionLeft'),
                    labelPosition: LabelPosition.left,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelLeftValue,
                    onChanged: (value) => viewModel.setLabelLeftValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Left)', viewModel.labelLeftValue),
                  buildFieldTitle('Label Right', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionRight'),
                    labelPosition: LabelPosition.right,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelRightValue,
                    onChanged: (value) => viewModel.setLabelRightValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Right)', viewModel.labelRightValue),
                  buildFieldTitle('Label In Border', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionInBorder'),
                    labelPosition: LabelPosition.inBorder,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelInBorderValue,
                    onChanged: (value) =>
                        viewModel.setLabelInBorderValue(value),
                  ),
                  buildResultDisplay(context, 'Selected (InBorder)',
                      viewModel.labelInBorderValue),
                  buildFieldTitle('Label None', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionNone'),
                    labelPosition: LabelPosition.none,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelNoneValue,
                    onChanged: (value) => viewModel.setLabelNoneValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (None)', viewModel.labelNoneValue),
                  buildSectionTitle(context.tr('ddBasicExamples'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 1: Basic Dropdown
                  buildFieldTitle(
                      context.tr('ddBasicRequired'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('ddCountry'),
                    initialValue: viewModel.dropdown1,
                    items: viewModel.countries,
                    isRequired: true,
                    onChanged: (value) => viewModel.setDropdown1(value),
                  ),
                  buildResultDisplay(context, context.tr('ddSelectedCountry'),
                      viewModel.dropdown1),

                  // Example 2: Optional Dropdown
                  buildFieldTitle(context.tr('ddOptionalNotRequired'),
                      Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('ddLanguage'),
                    initialValue: viewModel.dropdown2,
                    items: const [
                      'English',
                      'Spanish',
                      'French',
                      'German',
                      'Chinese'
                    ],
                    isRequired: false,
                    hintText: FormFieldsLocalizations.of(context)
                        .select(context.tr('ddLanguage')),
                    onChanged: (value) => viewModel.setDropdown2(value),
                  ),
                  buildResultDisplay(context, context.tr('ddSelectedLanguage'),
                      viewModel.dropdown2),

                  buildSectionTitle(context.tr('ddCustomStyling'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 3: Custom Border & Colors
                  buildFieldTitle(context.tr('ddCustomBorderColors'),
                      Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('ddColor'),
                    initialValue: viewModel.dropdown3,
                    items: viewModel.colors,
                    isRequired: true,
                    borderColor: Colors.purple,
                    focusedBorderColor: Colors.deepPurple,
                    errorBorderColor: Colors.red.shade700,
                    radius: 15,
                    onChanged: (value) => viewModel.setDropdown3(value),
                  ),
                  buildResultDisplay(context, context.tr('ddSelectedColor'),
                      viewModel.dropdown3),

                  // Example 4: With Icons
                  buildFieldTitle(
                      context.tr('ddWithIcons'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('ddSize'),
                    initialValue: viewModel.dropdown4,
                    items: viewModel.sizes,
                    isRequired: true,
                    borderColor: Colors.teal,
                    prefixIcon:
                        const Icon(Icons.shopping_bag, color: Colors.teal),
                    suffixIcon:
                        const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    hintText: FormFieldsLocalizations.of(context)
                        .select(context.tr('ddSize')),
                    onChanged: (value) => viewModel.setDropdown4(value),
                  ),
                  buildResultDisplay(context, context.tr('ddSelectedSize'),
                      viewModel.dropdown4),

                  buildSectionTitle(context.tr('ddLabelPositions'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 5: Label at Top (default)
                  buildFieldTitle(
                      context.tr('ddLabelTop'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('ddShippingMethod'),
                    labelPosition: LabelPosition.top,
                    initialValue: viewModel.dropdown5,
                    items: const [
                      'Standard',
                      'Express',
                      'Overnight',
                      'International'
                    ],
                    isRequired: true,
                    borderColor: Colors.orange,
                    onChanged: (value) => viewModel.setDropdown5(value),
                  ),
                  buildResultDisplay(context, context.tr('ddSelectedShipping'),
                      viewModel.dropdown5),

                  // Example 6: Label at Left
                  buildFieldTitle('Label Top', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionTop'),
                    labelPosition: LabelPosition.top,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown1,
                    onChanged: (value) => viewModel.setDropdown1(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Top)', viewModel.dropdown1),
                  buildFieldTitle('Label Bottom', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionBottom'),
                    labelPosition: LabelPosition.bottom,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown2,
                    onChanged: (value) => viewModel.setDropdown2(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Bottom)', viewModel.dropdown2),
                  buildFieldTitle('Label Left', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionLeft'),
                    labelPosition: LabelPosition.left,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown3,
                    onChanged: (value) => viewModel.setDropdown3(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Left)', viewModel.dropdown3),
                  buildFieldTitle('Label Right', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionRight'),
                    labelPosition: LabelPosition.right,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown4,
                    onChanged: (value) => viewModel.setDropdown4(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Right)', viewModel.dropdown4),
                  buildFieldTitle('Label In Border', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionInBorder'),
                    labelPosition: LabelPosition.inBorder,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown5,
                    onChanged: (value) => viewModel.setDropdown5(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (InBorder)', viewModel.dropdown5),
                  buildFieldTitle('Label None', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('positionNone'),
                    labelPosition: LabelPosition.none,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown6,
                    onChanged: (value) => viewModel.setDropdown6(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (None)', viewModel.dropdown6),

                  buildResultDisplay(context,
                      context.tr('ddSelectedDepartment'), viewModel.dropdown8),

                  buildSectionTitle(context.tr('ddCustomDecoration'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 9: Full Custom InputDecoration
                  buildFieldTitle(
                      context.tr('ddCustomInput'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('ddTheme'),
                    initialValue: viewModel.dropdown9,
                    items: const ['Light', 'Dark', 'Auto', 'System'],
                    isRequired: false,
                    decoration: InputDecoration(
                      hintText: FormFieldsLocalizations.of(context)
                          .select(context.tr('ddTheme')),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.palette),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) => viewModel.setDropdown9(value),
                  ),
                  buildResultDisplay(context, context.tr('ddSelectedTheme'),
                      viewModel.dropdown9),

                  buildSectionTitle(context.tr('ddWithFilter'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 10: With Search Filter
                  buildFieldTitle(
                      context.tr('ddWithSearch'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: context.tr('ddSelectCountryFilter'),
                    initialValue: viewModel.dropdown10,
                    items: viewModel.countries,
                    isRequired: true,
                    enableFilter: true,
                    filterHintText:
                        FormFieldsLocalizations.of(context).searchHint,
                    borderColor: Colors.teal,
                    focusedBorderColor: Colors.teal.shade700,
                    radius: 12,
                    onChanged: (value) => viewModel.setDropdown10(value),
                  ),
                  buildResultDisplay(
                      context,
                      context.tr('ddSelectedCountryFiltered'),
                      viewModel.dropdown10),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (viewModel.formKey.currentState!.validate()) {
                          _showFormData(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.tr('validateFormButton'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFormData(BuildContext context) {
    final l = loc.Localizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(context.tr('ddFormValidated')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
