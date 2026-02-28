import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/pages/dropdown_examples_view_model.dart';
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'package:form_fields_example/ui/widgets/language_indicator.dart';

class DropdownExamplesPage extends StatelessWidget {
  const DropdownExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DropdownExamplesViewModel(),
      child: Consumer<DropdownExamplesViewModel>(
        builder: (context, viewModel, _) {
          final l = FormFieldsLocalizations.of(context);
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
                    label: 'Top',
                    labelPosition: LabelPosition.top,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelTopValue,
                    onChanged: (value) => viewModel.setLabelTopValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Top)', viewModel.labelTopValue),
                  buildFieldTitle('Label Bottom', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Bottom',
                    labelPosition: LabelPosition.bottom,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelBottomValue,
                    onChanged: (value) => viewModel.setLabelBottomValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Bottom)', viewModel.labelBottomValue),
                  buildFieldTitle('Label Left', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Left',
                    labelPosition: LabelPosition.left,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelLeftValue,
                    onChanged: (value) => viewModel.setLabelLeftValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Left)', viewModel.labelLeftValue),
                  buildFieldTitle('Label Right', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Right',
                    labelPosition: LabelPosition.right,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelRightValue,
                    onChanged: (value) => viewModel.setLabelRightValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Right)', viewModel.labelRightValue),
                  buildFieldTitle('Label In Border', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'InBorder',
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
                    label: 'None',
                    labelPosition: LabelPosition.none,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.labelNoneValue,
                    onChanged: (value) => viewModel.setLabelNoneValue(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (None)', viewModel.labelNoneValue),
                  buildSectionTitle(l.get('ddBasicExamples'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 1: Basic Dropdown
                  buildFieldTitle(
                      l.get('ddBasicRequired'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddCountry'),
                    initialValue: viewModel.dropdown1,
                    items: viewModel.countries,
                    isRequired: true,
                    onChanged: (value) => viewModel.setDropdown1(value),
                  ),
                  buildResultDisplay(
                      context, l.get('ddSelectedCountry'), viewModel.dropdown1),

                  // Example 2: Optional Dropdown
                  buildFieldTitle(
                      l.get('ddOptionalNotRequired'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddLanguage'),
                    initialValue: viewModel.dropdown2,
                    items: const [
                      'English',
                      'Spanish',
                      'French',
                      'German',
                      'Chinese'
                    ],
                    isRequired: false,
                    hintText: l.select(l.get('ddLanguage')),
                    onChanged: (value) => viewModel.setDropdown2(value),
                  ),
                  buildResultDisplay(context, l.get('ddSelectedLanguage'),
                      viewModel.dropdown2),

                  buildSectionTitle(l.get('ddCustomStyling'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 3: Custom Border & Colors
                  buildFieldTitle(
                      l.get('ddCustomBorderColors'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddColor'),
                    initialValue: viewModel.dropdown3,
                    items: viewModel.colors,
                    isRequired: true,
                    borderColor: Colors.purple,
                    focusedBorderColor: Colors.deepPurple,
                    errorBorderColor: Colors.red.shade700,
                    radius: 15,
                    onChanged: (value) => viewModel.setDropdown3(value),
                  ),
                  buildResultDisplay(
                      context, l.get('ddSelectedColor'), viewModel.dropdown3),

                  // Example 4: With Icons
                  buildFieldTitle(l.get('ddWithIcons'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddSize'),
                    initialValue: viewModel.dropdown4,
                    items: viewModel.sizes,
                    isRequired: true,
                    borderColor: Colors.teal,
                    prefixIcon:
                        const Icon(Icons.shopping_bag, color: Colors.teal),
                    suffixIcon:
                        const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    hintText: l.select(l.get('ddSize')),
                    onChanged: (value) => viewModel.setDropdown4(value),
                  ),
                  buildResultDisplay(
                      context, l.get('ddSelectedSize'), viewModel.dropdown4),

                  buildSectionTitle(l.get('ddLabelPositions'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 5: Label at Top (default)
                  buildFieldTitle(l.get('ddLabelTop'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddShippingMethod'),
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
                  buildResultDisplay(context, l.get('ddSelectedShipping'),
                      viewModel.dropdown5),

                  // Example 6: Label at Left
                  buildFieldTitle('Label Top', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Top',
                    labelPosition: LabelPosition.top,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown1,
                    onChanged: (value) => viewModel.setDropdown1(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Top)', viewModel.dropdown1),
                  buildFieldTitle('Label Bottom', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Bottom',
                    labelPosition: LabelPosition.bottom,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown2,
                    onChanged: (value) => viewModel.setDropdown2(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Bottom)', viewModel.dropdown2),
                  buildFieldTitle('Label Left', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Left',
                    labelPosition: LabelPosition.left,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown3,
                    onChanged: (value) => viewModel.setDropdown3(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Left)', viewModel.dropdown3),
                  buildFieldTitle('Label Right', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Right',
                    labelPosition: LabelPosition.right,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown4,
                    onChanged: (value) => viewModel.setDropdown4(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Right)', viewModel.dropdown4),
                  buildFieldTitle('Label In Border', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'InBorder',
                    labelPosition: LabelPosition.inBorder,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown5,
                    onChanged: (value) => viewModel.setDropdown5(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (InBorder)', viewModel.dropdown5),
                  buildFieldTitle('Label None', Colors.pink.shade600),
                  FormFieldsDropdown<String>(
                    label: 'None',
                    labelPosition: LabelPosition.none,
                    items: const ['A', 'B', 'C'],
                    initialValue: viewModel.dropdown6,
                    onChanged: (value) => viewModel.setDropdown6(value),
                  ),
                  buildResultDisplay(
                      context, 'Selected (None)', viewModel.dropdown6),

                  buildResultDisplay(context, l.get('ddSelectedDepartment'),
                      viewModel.dropdown8),

                  buildSectionTitle(l.get('ddCustomDecoration'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 9: Full Custom InputDecoration
                  buildFieldTitle(
                      l.get('ddCustomInput'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddTheme'),
                    initialValue: viewModel.dropdown9,
                    items: const ['Light', 'Dark', 'Auto', 'System'],
                    isRequired: false,
                    decoration: InputDecoration(
                      hintText: l.select(l.get('ddTheme')),
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
                  buildResultDisplay(
                      context, l.get('ddSelectedTheme'), viewModel.dropdown9),

                  buildSectionTitle(l.get('ddWithFilter'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 10: With Search Filter
                  buildFieldTitle(l.get('ddWithSearch'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddSelectCountryFilter'),
                    initialValue: viewModel.dropdown10,
                    items: viewModel.countries,
                    isRequired: true,
                    enableFilter: true,
                    filterHintText: l.searchHint,
                    borderColor: Colors.teal,
                    focusedBorderColor: Colors.teal.shade700,
                    radius: 12,
                    onChanged: (value) => viewModel.setDropdown10(value),
                  ),
                  buildResultDisplay(context,
                      l.get('ddSelectedCountryFiltered'), viewModel.dropdown10),

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
                        l.get('validateFormButton'),
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
    final l = FormFieldsLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(l.get('ddFormValidated')),
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
