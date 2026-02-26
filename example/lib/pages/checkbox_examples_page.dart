import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import '../widgets/result_display_widget.dart';

class CheckboxExamplesPage extends StatefulWidget {
  const CheckboxExamplesPage({Key? key}) : super(key: key);

  @override
  State<CheckboxExamplesPage> createState() => _CheckboxExamplesPageState();
}

class _CheckboxExamplesPageState extends State<CheckboxExamplesPage> {
  final _formKey = GlobalKey<FormState>();

  // Checkbox values - All checkboxes use List<String>
  List<String> _checkbox1 = [];
  List<String> _checkbox2 = [];
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
            initialValue: _checkbox1,
            items: const ['I agree to the Terms and Conditions'],
            isRequired: true,
            direction: Axis.vertical,
            onChanged: (value) => setState(() => _checkbox1 = value),
          ),
          buildResultDisplay('Terms Agreed', _checkbox1),

          // Example 2: Single Selection - Horizontal
          _buildFieldTitle('Single Selection - Horizontal Layout'),
          FormFieldsCheckbox<String>(
            label: 'Newsletter Subscription',
            initialValue: _checkbox2,
            items: const ['Subscribe to weekly newsletter'],
            isRequired: false,
            direction: Axis.horizontal,
            borderColor: Colors.blue,
            activeColor: Colors.blue,
            onChanged: (value) => setState(() => _checkbox2 = value),
          ),
          buildResultDisplay('Newsletter', _checkbox2, isOptional: true),

          _buildSectionTitle('CHECKBOX - Multiple Selection'),

          // Example 3: Multiple Selection - Vertical
          _buildFieldTitle('Multiple Selection - Vertical Layout'),
          FormFieldsCheckbox<String>(
            label: 'Hobbies',
            initialValue: _checkbox3,
            items: const [
              'Reading',
              'Gaming',
              'Sports',
              'Cooking',
              'Traveling',
              'Photography',
            ],
            isRequired: true,
            direction: Axis.vertical,
            onChanged: (value) => setState(() => _checkbox3 = value),
          ),
          buildResultDisplay('Selected Hobbies', _checkbox3),

          // Example 4: Multiple Selection - Horizontal
          _buildFieldTitle('Multiple Selection - Horizontal Layout'),
          FormFieldsCheckbox<String>(
            label: 'Programming Languages',
            initialValue: _checkbox4,
            items: const ['Dart', 'JavaScript', 'Python', 'Java', 'C++'],
            isRequired: true,
            direction: Axis.horizontal,
            borderColor: Colors.teal,
            activeColor: Colors.teal,
            onChanged: (value) => setState(() => _checkbox4 = value),
          ),
          buildResultDisplay('Selected Languages', _checkbox4),

          _buildSectionTitle('CHECKBOX - Custom Styling'),

          // Example 5: Custom Border & Colors
          _buildFieldTitle('Custom Border & Active Color'),
          FormFieldsCheckbox<String>(
            label: 'Skills',
            initialValue: _checkbox5,
            items: const [
              'Leadership',
              'Communication',
              'Problem Solving',
              'Time Management',
              'Teamwork',
            ],
            isRequired: true,
            direction: Axis.vertical,
            borderColor: Colors.purple,
            errorBorderColor: Colors.red.shade700,
            activeColor: Colors.purple,
            radius: 15,
            onChanged: (value) => setState(() => _checkbox5 = value),
          ),
          buildResultDisplay('Selected Skills', _checkbox5),

          // Example 6: Custom Item Padding
          _buildFieldTitle('Custom Item Padding'),
          FormFieldsCheckbox<String>(
            label: 'Preferred Contact Methods',
            initialValue: _checkbox6,
            items: const ['Email', 'Phone', 'SMS', 'WhatsApp'],
            isRequired: false,
            direction: Axis.vertical,
            borderColor: Colors.orange,
            activeColor: Colors.orange,
            itemPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            onChanged: (value) => setState(() => _checkbox6 = value),
          ),
          buildResultDisplay('Contact Methods', _checkbox6, isOptional: true),

          _buildSectionTitle('CHECKBOX - Layout Variations'),

          // Example 7: Horizontal Layout
          _buildFieldTitle('Horizontal Layout - Days of Week'),
          FormFieldsCheckbox<String>(
            label: 'Days of the Week',
            initialValue: _checkbox7,
            items: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            isRequired: true,
            direction: Axis.horizontal,
            borderColor: Colors.indigo,
            activeColor: Colors.indigo,
            onChanged: (value) => setState(() => _checkbox7 = value),
          ),
          buildResultDisplay('Selected Days', _checkbox7),

          // Example 8: Vertical Layout with Custom Colors
          _buildFieldTitle('Vertical Layout - Features'),
          FormFieldsCheckbox<String>(
            label: 'Features',
            initialValue: _checkbox8,
            items: const ['WiFi', 'Parking', 'Gym', 'Pool'],
            isRequired: false,
            direction: Axis.vertical,
            borderColor: Colors.cyan,
            activeColor: Colors.cyan,
            onChanged: (value) => setState(() => _checkbox8 = value),
          ),
          buildResultDisplay('Selected Features', _checkbox8, isOptional: true),

          _buildSectionTitle('CHECKBOX - Advanced Features'),

          // Example 9: Custom Validation
          _buildFieldTitle('Custom Validation - Minimum Selections'),
          FormFieldsCheckbox<String>(
            label: 'Select at least 2 preferences',
            initialValue: _checkbox3,
            items: const ['Option A', 'Option B', 'Option C', 'Option D'],
            isRequired: true,
            direction: Axis.vertical,
            borderColor: Colors.red,
            activeColor: Colors.red,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select at least 2 options';
              }
              if (value.length < 2) {
                return 'Please select at least 2 options';
              }
              return null;
            },
            onChanged: (value) => setState(() => _checkbox3 = value),
          ),
          buildResultDisplay('Custom Validation', _checkbox3),

          // Example 10: Custom Styling
          _buildFieldTitle('Custom Item Padding'),
          FormFieldsCheckbox<String>(
            label: 'Dietary Restrictions',
            initialValue: _checkbox4,
            items: const [
              'Vegetarian',
              'Vegan',
              'Gluten-Free',
              'Dairy-Free',
              'Nut Allergy',
            ],
            isRequired: false,
            direction: Axis.vertical,
            borderColor: Colors.green,
            activeColor: Colors.green,
            itemPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            onChanged: (value) => setState(() => _checkbox4 = value),
          ),
          buildResultDisplay('Dietary Restrictions', _checkbox4,
              isOptional: true),

          // Example 11: Horizontal Layout with Custom Border
          _buildFieldTitle('Horizontal Layout - Notifications'),
          FormFieldsCheckbox<String>(
            label: 'Notifications',
            initialValue: _checkbox5,
            items: const ['Push', 'Email', 'SMS', 'In-App'],
            isRequired: false,
            direction: Axis.horizontal,
            borderColor: Colors.deepPurple,
            activeColor: Colors.deepPurple,
            onChanged: (value) => setState(() => _checkbox5 = value),
          ),
          buildResultDisplay('Notifications', _checkbox5, isOptional: true),

          // Example 12: Many Options
          _buildFieldTitle('Many Options - Scrollable'),
          FormFieldsCheckbox<String>(
            label: 'Countries Visited',
            initialValue: _checkbox6,
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
            ],
            isRequired: false,
            direction: Axis.vertical,
            borderColor: Colors.amber,
            activeColor: Colors.amber,
            itemPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            onChanged: (value) => setState(() => _checkbox6 = value),
          ),
          buildResultDisplay('Countries Visited', _checkbox6, isOptional: true),

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
