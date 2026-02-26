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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildSectionTitle('RADIO BUTTON - Basic Examples',
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 1: Basic Vertical Radio Button
            buildFieldTitle(
                'Basic Radio Button - Vertical Layout', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Gender',
              initialValue: _radio1,
              items: const ['Male', 'Female', 'Other'],
              isRequired: true,
              direction: Axis.vertical,
              onChanged: (value) => setState(() => _radio1 = value ?? ''),
            ),
            buildResultDisplay('Selected Gender', _radio1),

            // Example 2: Horizontal Radio Button
            buildFieldTitle(
                'Radio Button - Horizontal Layout', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Marital Status',
              initialValue: _radio2,
              items: const ['Single', 'Married', 'Divorced'],
              isRequired: true,
              direction: Axis.horizontal,
              onChanged: (value) => setState(() => _radio2 = value ?? ''),
            ),
            buildResultDisplay('Selected Marital Status', _radio2),

            buildSectionTitle('RADIO BUTTON - Custom Styling',
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 3: Custom Border & Colors
            buildFieldTitle(
                'Custom Border & Active Color', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Subscription Plan',
              initialValue: _radio3,
              items: const ['Free', 'Basic', 'Premium', 'Enterprise'],
              isRequired: true,
              direction: Axis.vertical,
              borderColor: Colors.purple,
              errorBorderColor: Colors.red.shade700,
              activeColor: Colors.purple,
              radius: 15,
              onChanged: (value) => setState(() => _radio3 = value ?? ''),
            ),
            buildResultDisplay('Selected Plan', _radio3),

            // Example 4: Custom Item Spacing & Padding
            buildFieldTitle(
                'Custom Item Spacing & Padding', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Delivery Option',
              initialValue: _radio4,
              items: const ['Pickup', 'Standard Delivery', 'Express Delivery'],
              isRequired: true,
              direction: Axis.vertical,
              borderColor: Colors.orange,
              activeColor: Colors.orange,
              itemPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              onChanged: (value) => setState(() => _radio4 = value ?? ''),
            ),
            buildResultDisplay('Selected Delivery', _radio4),

            buildSectionTitle('RADIO BUTTON - Layout Variations',
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 5: Horizontal with Fill Items
            buildFieldTitle('Horizontal - Fill Items', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Rating',
              initialValue: _radio5,
              items: const ['⭐', '⭐⭐', '⭐⭐⭐', '⭐⭐⭐⭐', '⭐⭐⭐⭐⭐'],
              isRequired: true,
              direction: Axis.horizontal,
              borderColor: Colors.amber,
              activeColor: Colors.amber,
              onChanged: (value) => setState(() => _radio5 = value ?? ''),
            ),
            buildResultDisplay('Selected Rating', _radio5),

            // Example 6: Different Label Positions
            buildFieldTitle('Label Position: Left', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Priority',
              initialValue: _radio6,
              items: const ['Low', 'Medium', 'High'],
              isRequired: true,
              direction: Axis.vertical,
              borderColor: Colors.red,
              activeColor: Colors.red,
              onChanged: (value) => setState(() => _radio6 = value ?? ''),
            ),
            buildResultDisplay('Selected Priority', _radio6),

            buildSectionTitle('RADIO BUTTON - Advanced Features',
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 7: Custom Validation
            buildFieldTitle('Custom Validation', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Payment Method',
              initialValue: _radio7,
              items: const [
                'Credit Card',
                'Debit Card',
                'PayPal',
                'Cash on Delivery'
              ],
              isRequired: true,
              direction: Axis.vertical,
              borderColor: Colors.teal,
              activeColor: Colors.teal,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a payment method';
                }
                if (value == 'Cash on Delivery') {
                  return 'Cash on delivery not available in your area';
                }
                return null;
              },
              onChanged: (value) => setState(() => _radio7 = value ?? ''),
            ),
            buildResultDisplay('Selected Payment Method', _radio7),

            // Example 8: With Custom Icon Size
            buildFieldTitle('Custom Icon Size', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Newsletter Frequency',
              initialValue: _radio8,
              items: const ['Daily', 'Weekly', 'Monthly', 'Never'],
              isRequired: false,
              direction: Axis.vertical,
              borderColor: Colors.indigo,
              activeColor: Colors.indigo,
              itemPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              onChanged: (value) => setState(() => _radio8 = value ?? ''),
            ),
            buildResultDisplay('Selected Frequency', _radio8, isOptional: true),

            buildSectionTitle('RADIO BUTTON - More Options',
                Colors.orange.shade700, Colors.orange.shade400),

            // Example 9: Many Options - Vertical
            buildFieldTitle(
                'Many Options - Vertical Scrollable', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Country',
              initialValue: _radio1,
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
              onChanged: (value) => setState(() => _radio1 = value ?? ''),
            ),
            buildResultDisplay('Selected Country', _radio1),

            // Example 10: Underline Border Type
            buildFieldTitle('Underline Border Type', Colors.orange.shade600),
            FormFieldsRadioButton<String>(
              label: 'Account Type',
              initialValue: _radio2,
              items: const ['Personal', 'Business', 'Student'],
              isRequired: true,
              direction: Axis.horizontal,
              borderColor: Colors.cyan,
              activeColor: Colors.cyan,
              onChanged: (value) => setState(() => _radio2 = value ?? ''),
            ),
            buildResultDisplay('Selected Account Type', _radio2),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _showFormData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'VALIDATE FORM',
                  style: TextStyle(
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

  void _showFormData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Radio button form validated successfully!'),
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
