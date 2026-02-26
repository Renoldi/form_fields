import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import '../widgets/result_display_widget.dart';

class RadioButtonExamplesPage extends StatefulWidget {
  const RadioButtonExamplesPage({Key? key}) : super(key: key);

  @override
  State<RadioButtonExamplesPage> createState() =>
      _RadioButtonExamplesPageState();
}

class _RadioButtonExamplesPageState extends State<RadioButtonExamplesPage> {
  final _formKey = GlobalKey<FormState>();

  // Radio button values
  String _radio1 = '';
  String _radio2 = '';
  String _radio3 = '';
  String _radio4 = '';
  String _radio5 = '';
  String _radio6 = '';
  String _radio7 = '';
  String _radio8 = '';

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);

    return Form(
      key: _formKey,
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
              initialValue: _radio1,
              items: [l.get('male'), l.get('female'), l.get('other')],
              isRequired: true,
              direction: Axis.vertical,
              onChanged: (value) => setState(() => _radio1 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedGender'), _radio1),

            // Example 2: Horizontal Radio Button
            buildFieldTitle(l.get('radioHorizontal'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('maritalStatus'),
              initialValue: _radio2,
              items: [l.get('single'), l.get('married'), l.get('divorced')],
              isRequired: true,
              direction: Axis.horizontal,
              onChanged: (value) => setState(() => _radio2 = value ?? ''),
            ),
            buildResultDisplay(
                context, l.get('selectedMaritalStatus'), _radio2),

            buildSectionTitle(l.get('radioBorderColors'),
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 3: Custom Border & Colors
            buildFieldTitle(
                l.get('customBorderActive'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('subscriptionPlan'),
              initialValue: _radio3,
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
              onChanged: (value) => setState(() => _radio3 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedPlan'), _radio3),

            // Example 4: Custom Item Spacing & Padding
            buildFieldTitle(l.get('customItemSpacing'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('deliveryOption'),
              initialValue: _radio4,
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
              onChanged: (value) => setState(() => _radio4 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedDelivery'), _radio4),

            buildSectionTitle(l.get('radioLayoutVariations'),
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 5: Horizontal with Fill Items
            buildFieldTitle(l.get('horizontalFill'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('rating'),
              initialValue: _radio5,
              items: const ['⭐', '⭐⭐', '⭐⭐⭐', '⭐⭐⭐⭐', '⭐⭐⭐⭐⭐'],
              isRequired: true,
              direction: Axis.horizontal,
              borderColor: Colors.amber,
              activeColor: Colors.amber,
              onChanged: (value) => setState(() => _radio5 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedRating'), _radio5),

            // Example 6: Different Label Positions
            buildFieldTitle(l.get('labelPositionLeft'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('priority'),
              initialValue: _radio6,
              items: [l.get('low'), l.get('medium'), l.get('high')],
              isRequired: true,
              direction: Axis.vertical,
              borderColor: Colors.red,
              activeColor: Colors.red,
              onChanged: (value) => setState(() => _radio6 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedPriority'), _radio6),

            buildSectionTitle(l.get('radioAdvancedFeatures'),
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 7: Custom Validation
            buildFieldTitle(l.get('customValidation'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('paymentMethod'),
              initialValue: _radio7,
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
              onChanged: (value) => setState(() => _radio7 = value ?? ''),
            ),
            buildResultDisplay(
                context, l.get('selectedPaymentMethod'), _radio7),

            // Example 8: With Custom Icon Size
            buildFieldTitle(l.get('customIconSize'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('newsletterFrequency'),
              initialValue: _radio8,
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
              onChanged: (value) => setState(() => _radio8 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedFrequency'), _radio8),

            buildSectionTitle(l.get('radioSectionedLayout'),
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 9: Sectioned Radio Buttons with Horizontal Layout
            buildFieldTitle(
                l.get('sectionedHorizontal'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('subscriptionPlan'),
              initialValue: _radio1,
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
              onChanged: (value) => setState(() => _radio1 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedPlan'), _radio1),

            // Example 9b: Sectioned with Item Borders
            buildFieldTitle(
                l.get('sectionedItemBorders'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('preferences'),
              initialValue: _radio2,
              sections: {
                l.get('theme'): [l.get('light'), l.get('dark'), l.get('auto')],
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
              onChanged: (value) => setState(() => _radio2 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedPreference'), _radio2),

            // Example 9c: Beautiful Styled with Selection Highlights
            buildFieldTitle(l.get('beautifulStyling'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('deliveryOption'),
              initialValue: _radio5,
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
              itemPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              onChanged: (value) => setState(() => _radio5 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedOption'), _radio5),

            buildSectionTitle(l.get('radioMoreOptions'), Colors.orange.shade700,
                Colors.orange.shade400),

            // Example 10: Many Options - Vertical
            buildFieldTitle(
                l.get('manyOptionsVertical'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('countryLabel'),
              initialValue: _radio2,
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
              onChanged: (value) => setState(() => _radio2 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedCountry'), _radio2),

            // Example 11: Underline Border Type
            buildFieldTitle(
                l.get('underlineBorderType'), Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: l.get('accountType'),
              initialValue: _radio3,
              items: [
                l.get('accountPersonal'),
                l.get('accountBusiness'),
                l.get('accountStudent'),
              ],
              isRequired: true,
              direction: Axis.horizontal,
              borderColor: Colors.cyan,
              activeColor: Colors.cyan,
              onChanged: (value) => setState(() => _radio3 = value ?? ''),
            ),
            buildResultDisplay(context, l.get('selectedAccountType'), _radio3),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
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
