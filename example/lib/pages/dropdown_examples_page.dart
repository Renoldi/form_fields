import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class DropdownExamplesPage extends StatefulWidget {
  const DropdownExamplesPage({Key? key}) : super(key: key);

  @override
  State<DropdownExamplesPage> createState() => _DropdownExamplesPageState();
}

class _DropdownExamplesPageState extends State<DropdownExamplesPage> {
  final _formKey = GlobalKey<FormState>();

  // Dropdown values - initialized with first option or empty string
  String _dropdown1 = '';
  String _dropdown2 = '';
  String _dropdown3 = '';
  String _dropdown4 = '';
  String _dropdown5 = '';
  String _dropdown6 = '';
  String _dropdown7 = '';
  String _dropdown8 = '';
  String _dropdown9 = '';

  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'China',
  ];

  final List<String> _colors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Purple',
    'Orange',
  ];

  final List<String> _sizes = ['Small', 'Medium', 'Large', 'Extra Large'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('DROPDOWN - Basic Examples'),

          // Example 1: Basic Dropdown
          _buildFieldTitle('Basic Dropdown - Required'),
          FormFieldsDropdown<String>(
            label: 'Country',
            currentValue: _dropdown1,
            options: _countries,
            isRequired: true,
            onChanged: (value) => setState(() => _dropdown1 = value),
          ),

          // Example 2: Optional Dropdown
          _buildFieldTitle('Optional Dropdown - Not Required'),
          FormFieldsDropdown<String>(
            label: 'Preferred Language',
            currentValue: _dropdown2,
            options: const [
              'English',
              'Spanish',
              'French',
              'German',
              'Chinese'
            ],
            isRequired: false,
            dropdownHint: 'Select your preferred language',
            onChanged: (value) => setState(() => _dropdown2 = value),
          ),

          _buildSectionTitle('DROPDOWN - Custom Styling'),

          // Example 3: Custom Border & Colors
          _buildFieldTitle('Custom Border & Colors'),
          FormFieldsDropdown<String>(
            label: 'Favorite Color',
            currentValue: _dropdown3,
            options: _colors,
            isRequired: true,
            borderColor: Colors.purple,
            focusedBorderColor: Colors.deepPurple,
            errorBorderColor: Colors.red.shade700,
            radius: 15,
            labelTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            onChanged: (value) => setState(() => _dropdown3 = value),
          ),

          // Example 4: With Icons
          _buildFieldTitle('With Prefix & Suffix Icons'),
          FormFieldsDropdown<String>(
            label: 'T-Shirt Size',
            currentValue: _dropdown4,
            options: _sizes,
            isRequired: true,
            borderColor: Colors.teal,
            prefixIcon: const Icon(Icons.shopping_bag, color: Colors.teal),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
            dropdownHint: 'Choose your size',
            onChanged: (value) => setState(() => _dropdown4 = value),
          ),

          _buildSectionTitle('DROPDOWN - Different Label Positions'),

          // Example 5: Label at Top (default)
          _buildFieldTitle('Label Position: Top'),
          FormFieldsDropdown<String>(
            label: 'Shipping Method',
            labelPosition: LabelPosition.top,
            currentValue: _dropdown5,
            options: const [
              'Standard',
              'Express',
              'Overnight',
              'International'
            ],
            isRequired: true,
            borderColor: Colors.orange,
            onChanged: (value) => setState(() => _dropdown5 = value),
          ),

          // Example 6: Label at Left
          _buildFieldTitle('Label Position: Left'),
          FormFieldsDropdown<String>(
            label: 'Payment',
            labelPosition: LabelPosition.left,
            currentValue: _dropdown6,
            options: const ['Credit Card', 'PayPal', 'Bank Transfer', 'Cash'],
            isRequired: true,
            borderColor: Colors.green,
            onChanged: (value) => setState(() => _dropdown6 = value),
          ),

          _buildSectionTitle('DROPDOWN - Advanced Features'),

          // Example 7: Custom Validation
          _buildFieldTitle('Custom Validation'),
          FormFieldsDropdown<String>(
            label: 'Priority Level',
            currentValue: _dropdown7,
            options: const ['Low', 'Medium', 'High', 'Critical'],
            isRequired: true,
            borderColor: Colors.red,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a priority level';
              }
              if (value == 'Critical') {
                return 'Critical priority requires manager approval';
              }
              return null;
            },
            onChanged: (value) => setState(() => _dropdown7 = value),
          ),

          // Example 8: Underline Border Type
          _buildFieldTitle('Underline Border Type'),
          FormFieldsDropdown<String>(
            label: 'Department',
            currentValue: _dropdown8,
            options: const [
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
            labelTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
            onChanged: (value) => setState(() => _dropdown8 = value),
          ),

          _buildSectionTitle('DROPDOWN - Custom Input Decoration'),

          // Example 9: Full Custom InputDecoration
          _buildFieldTitle('Custom Input Decoration'),
          FormFieldsDropdown<String>(
            label: 'Theme',
            currentValue: _dropdown9,
            options: const ['Light', 'Dark', 'Auto', 'System'],
            isRequired: false,
            inputDecoration: InputDecoration(
              hintText: 'Select app theme',
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
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              prefixIcon: const Icon(Icons.palette),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) => setState(() => _dropdown9 = value),
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
                colors: [Colors.green.shade700, Colors.green.shade400],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
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
              color: Colors.green.shade600,
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
            Text('Dropdown form validated successfully!'),
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
