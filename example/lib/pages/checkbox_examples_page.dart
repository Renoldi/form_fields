import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class CheckboxExamplesPage extends StatefulWidget {
  const CheckboxExamplesPage({Key? key}) : super(key: key);

  @override
  State<CheckboxExamplesPage> createState() => _CheckboxExamplesPageState();
}

class _CheckboxExamplesPageState extends State<CheckboxExamplesPage> {
  final _formKey = GlobalKey<FormState>();

  // Checkbox values - Single selection
  String _checkbox1 = '';
  String _checkbox2 = '';

  // Checkbox values - Multiple selection
  List<String> _checkbox3 = [];
  List<String> _checkbox4 = [];
  List<String> _checkbox5 = [];
  List<String> _checkbox6 = [];
  List<String> _checkbox7 = [];
  List<String> _checkbox8 = [];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('CHECKBOX - Basic Examples'),

          // Example 1: Single Selection - Vertical
          _buildFieldTitle('Single Selection - Vertical Layout'),
          FormFieldsCheckbox<String>(
            label: 'Terms & Conditions',
            currentValue: _checkbox1,
            options: const ['I agree to the Terms and Conditions'],
            isRequired: true,
            isMultiple: false,
            itemDirection: Axis.vertical,
            onChanged: (value) => setState(() => _checkbox1 = value),
          ),

          // Example 2: Single Selection - Horizontal
          _buildFieldTitle('Single Selection - Horizontal Layout'),
          FormFieldsCheckbox<String>(
            label: 'Newsletter Subscription',
            currentValue: _checkbox2,
            options: const ['Subscribe to weekly newsletter'],
            isRequired: false,
            isMultiple: false,
            itemDirection: Axis.horizontal,
            borderColor: Colors.blue,
            activeIconColor: Colors.blue,
            onChanged: (value) => setState(() => _checkbox2 = value),
          ),

          _buildSectionTitle('CHECKBOX - Multiple Selection'),

          // Example 3: Multiple Selection - Vertical
          _buildFieldTitle('Multiple Selection - Vertical Layout'),
          FormFieldsCheckbox<List<String>>(
            label: 'Hobbies',
            currentValue: _checkbox3,
            options: const [
              'Reading',
              'Gaming',
              'Sports',
              'Cooking',
              'Traveling',
              'Photography',
            ],
            isRequired: true,
            isMultiple: true,
            itemDirection: Axis.vertical,
            onChanged: (value) => setState(() => _checkbox3 = value),
          ),

          // Example 4: Multiple Selection - Horizontal
          _buildFieldTitle('Multiple Selection - Horizontal Layout'),
          FormFieldsCheckbox<List<String>>(
            label: 'Programming Languages',
            currentValue: _checkbox4,
            options: const ['Dart', 'JavaScript', 'Python', 'Java', 'C++'],
            isRequired: true,
            isMultiple: true,
            itemDirection: Axis.horizontal,
            borderColor: Colors.teal,
            activeIconColor: Colors.teal,
            onChanged: (value) => setState(() => _checkbox4 = value),
          ),

          _buildSectionTitle('CHECKBOX - Custom Styling'),

          // Example 5: Custom Border & Colors
          _buildFieldTitle('Custom Border & Active Color'),
          FormFieldsCheckbox<List<String>>(
            label: 'Skills',
            currentValue: _checkbox5,
            options: const [
              'Leadership',
              'Communication',
              'Problem Solving',
              'Time Management',
              'Teamwork',
            ],
            isRequired: true,
            isMultiple: true,
            itemDirection: Axis.vertical,
            borderColor: Colors.purple,
            errorBorderColor: Colors.red.shade700,
            activeIconColor: Colors.purple,
            activeCheckboxColor: Colors.purple,
            radius: 15,
            labelTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            onChanged: (value) => setState(() => _checkbox5 = value),
          ),

          // Example 6: Custom Item Spacing & Padding
          _buildFieldTitle('Custom Item Spacing & Padding'),
          FormFieldsCheckbox<List<String>>(
            label: 'Preferred Contact Methods',
            currentValue: _checkbox6,
            options: const ['Email', 'Phone', 'SMS', 'WhatsApp'],
            isRequired: false,
            isMultiple: true,
            itemDirection: Axis.vertical,
            borderColor: Colors.orange,
            activeIconColor: Colors.orange,
            itemSpacing: 16,
            itemPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            onChanged: (value) => setState(() => _checkbox6 = value),
          ),

          _buildSectionTitle('CHECKBOX - Layout Variations'),

          // Example 7: Horizontal with Fill Items
          _buildFieldTitle('Horizontal - Fill Items'),
          FormFieldsCheckbox<List<String>>(
            label: 'Days of the Week',
            currentValue: _checkbox7,
            options: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            isRequired: true,
            isMultiple: true,
            itemDirection: Axis.horizontal,
            fillItems: true,
            borderColor: Colors.indigo,
            activeIconColor: Colors.indigo,
            onChanged: (value) => setState(() => _checkbox7 = value),
          ),

          // Example 8: Different Label Positions
          _buildFieldTitle('Label Position: Left'),
          FormFieldsCheckbox<List<String>>(
            label: 'Features',
            labelPosition: LabelPosition.left,
            currentValue: _checkbox8,
            options: const ['WiFi', 'Parking', 'Gym', 'Pool'],
            isRequired: false,
            isMultiple: true,
            itemDirection: Axis.vertical,
            borderColor: Colors.cyan,
            activeIconColor: Colors.cyan,
            onChanged: (value) => setState(() => _checkbox8 = value),
          ),

          _buildSectionTitle('CHECKBOX - Advanced Features'),

          // Example 9: Custom Validation
          _buildFieldTitle('Custom Validation - Minimum Selections'),
          FormFieldsCheckbox<List<String>>(
            label: 'Select at least 2 preferences',
            currentValue: _checkbox3,
            options: const ['Option A', 'Option B', 'Option C', 'Option D'],
            isRequired: true,
            isMultiple: true,
            itemDirection: Axis.vertical,
            borderColor: Colors.red,
            activeIconColor: Colors.red,
            validator: (value) {
              if (_checkbox3.isEmpty) {
                return 'Please select at least 2 options';
              }
              if (_checkbox3.length < 2) {
                return 'Please select at least 2 options';
              }
              return null;
            },
            onChanged: (value) => setState(() => _checkbox3 = value),
          ),

          // Example 10: With Custom Icon Size
          _buildFieldTitle('Custom Icon Size'),
          FormFieldsCheckbox<List<String>>(
            label: 'Dietary Restrictions',
            currentValue: _checkbox4,
            options: const [
              'Vegetarian',
              'Vegan',
              'Gluten-Free',
              'Dairy-Free',
              'Nut Allergy',
            ],
            isRequired: false,
            isMultiple: true,
            itemDirection: Axis.vertical,
            borderColor: Colors.green,
            activeIconColor: Colors.green,
            iconSize: 28,
            itemPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            labelTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
            onChanged: (value) => setState(() => _checkbox4 = value),
          ),

          // Example 11: Underline Border Type
          _buildFieldTitle('Underline Border Type'),
          FormFieldsCheckbox<List<String>>(
            label: 'Notifications',
            currentValue: _checkbox5,
            options: const ['Push', 'Email', 'SMS', 'In-App'],
            isRequired: false,
            isMultiple: true,
            itemDirection: Axis.horizontal,
            borderType: BorderType.underlineInputBorder,
            borderColor: Colors.deepPurple,
            activeIconColor: Colors.deepPurple,
            onChanged: (value) => setState(() => _checkbox5 = value),
          ),

          // Example 12: Many Options
          _buildFieldTitle('Many Options - Scrollable'),
          FormFieldsCheckbox<List<String>>(
            label: 'Countries Visited',
            currentValue: _checkbox6,
            options: const [
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
            ],
            isRequired: false,
            isMultiple: true,
            itemDirection: Axis.vertical,
            borderColor: Colors.amber,
            activeIconColor: Colors.amber,
            itemPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            onChanged: (value) => setState(() => _checkbox6 = value),
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
                colors: [Colors.pink.shade700, Colors.pink.shade400],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.3),
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
              color: Colors.pink.shade600,
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
            Text('Checkbox form validated successfully!'),
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
