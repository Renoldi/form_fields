import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

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
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('RADIO BUTTON - Basic Examples'),

          // Example 1: Basic Vertical Radio Button
          _buildFieldTitle('Basic Radio Button - Vertical Layout'),
          FormFieldsRadioButton<String>(
            label: 'Gender',
            initialValue: _radio1,
            items: const ['Male', 'Female', 'Other'],
            isRequired: true,
            direction: Axis.vertical,
            onChanged: (value) => setState(() => _radio1 = value ?? ''),
          ),

          // Example 2: Horizontal Radio Button
          _buildFieldTitle('Radio Button - Horizontal Layout'),
          FormFieldsRadioButton<String>(
            label: 'Marital Status',
            initialValue: _radio2,
            items: const ['Single', 'Married', 'Divorced'],
            isRequired: true,
            direction: Axis.horizontal,
            onChanged: (value) => setState(() => _radio2 = value ?? ''),
          ),

          _buildSectionTitle('RADIO BUTTON - Custom Styling'),

          // Example 3: Custom Border & Colors
          _buildFieldTitle('Custom Border & Active Color'),
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

          // Example 4: Custom Item Spacing & Padding
          _buildFieldTitle('Custom Item Spacing & Padding'),
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

          _buildSectionTitle('RADIO BUTTON - Layout Variations'),

          // Example 5: Horizontal with Fill Items
          _buildFieldTitle('Horizontal - Fill Items'),
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

          // Example 6: Different Label Positions
          _buildFieldTitle('Label Position: Left'),
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

          _buildSectionTitle('RADIO BUTTON - Advanced Features'),

          // Example 7: Custom Validation
          _buildFieldTitle('Custom Validation'),
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

          // Example 8: With Custom Icon Size
          _buildFieldTitle('Custom Icon Size'),
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

          _buildSectionTitle('RADIO BUTTON - More Options'),

          // Example 9: Many Options - Vertical
          _buildFieldTitle('Many Options - Vertical Scrollable'),
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
            ],
            isRequired: true,
            direction: Axis.vertical,
            borderColor: Colors.blue,
            activeColor: Colors.blue,
            itemPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            onChanged: (value) => setState(() => _radio1 = value ?? ''),
          ),

          // Example 10: Underline Border Type
          _buildFieldTitle('Underline Border Type'),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade700, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Container(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.orange.shade600,
              width: 4,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
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
