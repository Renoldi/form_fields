import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/pages/dropdown_examples_view_model.dart';
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'package:form_fields_example/ui/widgets/language_indicator.dart';

class DropdownExamplesPage extends StatelessWidget {
  const DropdownExamplesPage({Key? key}) : super(key: key);

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
                    onChanged: (value) => viewModel.setDropdown1(value ?? ''),
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
                    onChanged: (value) => viewModel.setDropdown2(value ?? ''),
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
                    onChanged: (value) => viewModel.setDropdown3(value ?? ''),
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
                    onChanged: (value) => viewModel.setDropdown4(value ?? ''),
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
                    onChanged: (value) => viewModel.setDropdown5(value ?? ''),
                  ),
                  buildResultDisplay(context, l.get('ddSelectedShipping'),
                      viewModel.dropdown5),

                  // Example 6: Label at Left
                  buildFieldTitle(l.get('ddLabelLeft'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddPayment'),
                    labelPosition: LabelPosition.left,
                    initialValue: viewModel.dropdown6,
                    items: const [
                      'Credit Card',
                      'PayPal',
                      'Bank Transfer',
                      'Cash'
                    ],
                    isRequired: true,
                    borderColor: Colors.green,
                    onChanged: (value) => viewModel.setDropdown6(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('ddSelectedPayment'), viewModel.dropdown6),

                  buildSectionTitle(l.get('ddAdvancedFeatures'),
                      Colors.green.shade700, Colors.green.shade400),

                  // Example 7: Custom Validation
                  buildFieldTitle(
                      l.get('ddCustomValidation'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddPriority'),
                    initialValue: viewModel.dropdown7,
                    items: const ['Low', 'Medium', 'High', 'Critical'],
                    isRequired: true,
                    borderColor: Colors.red,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l.get('ddSelectPriority');
                      }
                      if (value == 'Critical') {
                        return l.get('ddCriticalApproval');
                      }
                      return null;
                    },
                    onChanged: (value) => viewModel.setDropdown7(value ?? ''),
                  ),
                  buildResultDisplay(context, l.get('ddSelectedPriority'),
                      viewModel.dropdown7),

                  // Example 8: Underline Border Type
                  buildFieldTitle(l.get('ddUnderline'), Colors.green.shade600),
                  FormFieldsDropdown<String>(
                    label: l.get('ddDepartment'),
                    initialValue: viewModel.dropdown8,
                    items: const [
                      'Sales',
                      'Marketing',
                      'Engineering',
                      'HR',
                      'Finance'
                    ],
                    isRequired: true,
                    borderType: BorderType.underlineInputBorder,
                    borderColor: Colors.indigo,
                    focusedBorderColor: Colors.indigoAccent,
                    onChanged: (value) => viewModel.setDropdown8(value ?? ''),
                  ),
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
                    onChanged: (value) => viewModel.setDropdown9(value ?? ''),
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
                    onChanged: (value) => viewModel.setDropdown10(value ?? ''),
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
