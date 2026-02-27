import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/pages/radio_button_examples_view_model.dart';
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';

class RadioButtonExamplesPage extends StatelessWidget {
  const RadioButtonExamplesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RadioButtonExamplesViewModel(),
      child: Consumer<RadioButtonExamplesViewModel>(
        builder: (context, viewModel, _) {
          final l = FormFieldsLocalizations.of(context);

          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  buildSectionTitle(l.get('radioButtonBasicExamples'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 1: Basic Vertical Radio Button
                  buildFieldTitle(
                      l.get('basicRadioVertical'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('gender'),
                    initialValue: viewModel.radio1,
                    items: [l.get('male'), l.get('female'), l.get('other')],
                    isRequired: true,
                    direction: Axis.vertical,
                    onChanged: (value) => viewModel.setRadio1(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedGender'), viewModel.radio1),

                  // Example 2: Horizontal Radio Button
                  buildFieldTitle(
                      l.get('radioHorizontal'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('maritalStatus'),
                    initialValue: viewModel.radio2,
                    items: [
                      l.get('single'),
                      l.get('married'),
                      l.get('divorced')
                    ],
                    isRequired: true,
                    direction: Axis.horizontal,
                    onChanged: (value) => viewModel.setRadio2(value ?? ''),
                  ),
                  buildResultDisplay(context, l.get('selectedMaritalStatus'),
                      viewModel.radio2),

                  buildSectionTitle(l.get('radioBorderColors'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 3: Custom Border & Colors
                  buildFieldTitle(
                      l.get('customBorderActive'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('subscriptionPlan'),
                    initialValue: viewModel.radio3,
                    items: [
                      l.get('free'),
                      l.get('basic'),
                      l.get('premium'),
                      l.get('enterprise')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.purple,
                    errorBorderColor: Colors.red.shade700,
                    activeColor: Colors.purple,
                    radius: 15,
                    onChanged: (value) => viewModel.setRadio3(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedPlan'), viewModel.radio3),

                  // Example 4: Custom Item Spacing & Padding
                  buildFieldTitle(
                      l.get('customItemSpacing'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('deliveryOption'),
                    initialValue: viewModel.radio4,
                    items: [
                      l.get('pickup'),
                      l.get('standardDelivery'),
                      l.get('expressDelivery')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.orange,
                    activeColor: Colors.orange,
                    itemPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    onChanged: (value) => viewModel.setRadio4(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedDelivery'), viewModel.radio4),

                  buildSectionTitle(l.get('radioLayoutVariations'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 5: Horizontal with Fill Items
                  buildFieldTitle(
                      l.get('horizontalFill'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('rating'),
                    initialValue: viewModel.radio5,
                    items: const ['⭐', '⭐⭐', '⭐⭐⭐', '⭐⭐⭐⭐', '⭐⭐⭐⭐⭐'],
                    isRequired: true,
                    direction: Axis.horizontal,
                    borderColor: Colors.amber,
                    activeColor: Colors.amber,
                    onChanged: (value) => viewModel.setRadio5(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedRating'), viewModel.radio5),

                  // Example 6: Different Label Positions
                  buildFieldTitle(
                      l.get('labelPositionLeft'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('priority'),
                    initialValue: viewModel.radio6,
                    items: [l.get('low'), l.get('medium'), l.get('high')],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.red,
                    activeColor: Colors.red,
                    onChanged: (value) => viewModel.setRadio6(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedPriority'), viewModel.radio6),

                  buildSectionTitle(l.get('radioAdvancedFeatures'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 7: Custom Validation
                  buildFieldTitle(
                      l.get('customValidation'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('paymentMethod'),
                    initialValue: viewModel.radio7,
                    items: [
                      l.get('creditCard'),
                      l.get('debitCard'),
                      l.get('paypal'),
                      l.get('cashOnDelivery')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.teal,
                    activeColor: Colors.teal,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l.get('radioSelectPaymentMethod');
                      }
                      if (value == l.get('cashOnDelivery')) {
                        return l.get('cashNotAvailable');
                      }
                      return null;
                    },
                    onChanged: (value) => viewModel.setRadio7(value ?? ''),
                  ),
                  buildResultDisplay(context, l.get('selectedPaymentMethod'),
                      viewModel.radio7),

                  // Example 8: With Custom Icon Size
                  buildFieldTitle(
                      l.get('customIconSize'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('newsletterFrequency'),
                    initialValue: viewModel.radio8,
                    items: [
                      l.get('daily'),
                      l.get('weekly'),
                      l.get('monthly'),
                      l.get('never')
                    ],
                    isRequired: false,
                    direction: Axis.vertical,
                    borderColor: Colors.indigo,
                    activeColor: Colors.indigo,
                    itemPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    onChanged: (value) => viewModel.setRadio8(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedFrequency'), viewModel.radio8),

                  buildSectionTitle(l.get('radioSectionedLayout'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 9: Sectioned Radio Buttons with Horizontal Layout
                  buildFieldTitle(
                      l.get('sectionedHorizontal'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('subscriptionPlan'),
                    initialValue: viewModel.radio1,
                    sections: {
                      l.get('cloudServices'): [
                        l.get('starter'),
                        l.get('professional'),
                        l.get('enterprise')
                      ],
                      l.get('supportLevel'): [
                        l.get('basic'),
                        l.get('premiumSupport'),
                        l.get('twentyFourSeven')
                      ],
                      l.get('duration'): [
                        l.get('monthly'),
                        l.get('quarterly'),
                        l.get('yearly')
                      ],
                    },
                    isRequired: true,
                    borderColor: Colors.green.shade600,
                    activeColor: Colors.green.shade600,
                    sectionSpacing: 16,
                    onChanged: (value) => viewModel.setRadio1(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedPlan'), viewModel.radio1),

                  // Example 9b: Sectioned with Item Borders
                  buildFieldTitle(
                      l.get('sectionedItemBorders'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('preferences'),
                    initialValue: viewModel.radio2,
                    sections: {
                      l.get('theme'): [
                        l.get('light'),
                        l.get('dark'),
                        l.get('auto')
                      ],
                      l.get('notifications'): [
                        l.get('all'),
                        l.get('important'),
                        l.get('none')
                      ],
                    },
                    isRequired: true,
                    borderColor: Colors.grey,
                    activeColor: Colors.teal,
                    itemBorderColor: Colors.teal.shade300,
                    itemBorderWidth: 1.5,
                    itemBorderRadius: 6,
                    textRightPadding: 8,
                    sectionSpacing: 16,
                    onChanged: (value) => viewModel.setRadio2(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedPreference'), viewModel.radio2),

                  // Example 9c: Beautiful Styled with Selection Highlights
                  buildFieldTitle(
                      l.get('beautifulStyling'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('deliveryOption'),
                    initialValue: viewModel.radio5,
                    items: [
                      l.get('pickup'),
                      l.get('standardDelivery'),
                      l.get('expressDelivery')
                    ],
                    isRequired: true,
                    borderColor: Colors.orange.shade300,
                    activeColor: Colors.orange.shade600,
                    selectedItemBackgroundColor: Colors.orange.shade50,
                    selectedItemTextColor: Colors.orange.shade900,
                    hoverBackgroundColor: Colors.orange.shade100,
                    itemBorderColor: Colors.orange.shade300,
                    itemBorderWidth: 1.5,
                    itemBorderRadius: 10,
                    itemShadow: true,
                    direction: Axis.vertical,
                    itemPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    onChanged: (value) => viewModel.setRadio5(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedOption'), viewModel.radio5),

                  buildSectionTitle(l.get('radioMoreOptions'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 10: Many Options - Vertical
                  buildFieldTitle(
                      l.get('manyOptionsVertical'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('countryLabel'),
                    initialValue: viewModel.radio2,
                    items: const [
                      'United States',
                      'United Kingdom',
                      'Canada',
                      'Australia',
                      'Germany',
                      'France',
                      'Japan',
                      'China',
                      'India',
                      'Brazil',
                      'Mexico',
                      'Italy',
                      'Spain',
                      'Russia',
                      'South Korea',
                      'Argentina',
                      'Netherlands',
                      'Sweden',
                      'Switzerland',
                      'Belgium',
                      'Poland',
                      'Norway',
                      'Austria',
                      'Denmark',
                      'Finland',
                      'Ireland',
                      'Portugal',
                      'Greece',
                      'New Zealand',
                      'Singapore',
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.blue,
                    activeColor: Colors.blue,
                    itemPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    onChanged: (value) => viewModel.setRadio2(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedCountry'), viewModel.radio2),

                  // Example 11: Underline Border Type
                  buildFieldTitle(
                      l.get('underlineBorderType'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: l.get('accountType'),
                    initialValue: viewModel.radio3,
                    items: [
                      l.get('accountPersonal'),
                      l.get('accountBusiness'),
                      l.get('accountStudent'),
                    ],
                    isRequired: true,
                    direction: Axis.horizontal,
                    borderColor: Colors.cyan,
                    activeColor: Colors.cyan,
                    onChanged: (value) => viewModel.setRadio3(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, l.get('selectedAccountType'), viewModel.radio3),

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
            Text(l.get('radioFormValidated')),
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
