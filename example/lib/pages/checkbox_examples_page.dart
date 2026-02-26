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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildSectionTitle('CHECKBOX - Basic Examples', Colors.pink.shade700,
                Colors.pink.shade400),

            // Example 1: Single Selection - Vertical
            buildFieldTitle(
                'Single Selection - Vertical Layout', Colors.pink.shade600),
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
            buildFieldTitle(
                'Single Selection - Horizontal Layout', Colors.pink.shade600),
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

            buildSectionTitle('CHECKBOX - Multiple Selection',
                Colors.pink.shade700, Colors.pink.shade400),

            // Example 3: Multiple Selection - Vertical
            buildFieldTitle(
                'Multiple Selection - Vertical Layout', Colors.pink.shade600),
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
                'Music',
                'Art & Crafts',
                'Dancing',
                'Yoga',
                'Meditation',
                'Gardening',
                'Fishing',
                'Hiking',
                'Cycling',
                'Swimming',
                'Writing',
                'Blogging',
                'Painting',
                'Drawing',
                'Singing',
                'Playing Instruments',
                'Bird Watching',
                'Astronomy',
                'Volunteering',
              ],
              isRequired: true,
              direction: Axis.vertical,
              onChanged: (value) => setState(() => _checkbox3 = value),
            ),
            buildResultDisplay('Selected Hobbies', _checkbox3),

            // Example 4: Multiple Selection - Horizontal
            buildFieldTitle(
                'Multiple Selection - Horizontal Layout', Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: 'Programming Languages',
              initialValue: _checkbox4,
              items: const [
                'Dart',
                'JavaScript',
                'Python',
                'Java',
                'C++',
                'TypeScript',
                'Go',
                'Rust',
                'Kotlin',
                'Swift',
                'C#',
                'PHP',
                'Ruby',
                'Scala',
                'R',
                'MATLAB',
                'Perl',
                'Haskell',
                'Lua',
                'Elixir',
                'Clojure'
              ],
              isRequired: true,
              direction: Axis.horizontal,
              borderColor: Colors.teal,
              activeColor: Colors.teal,
              onChanged: (value) => setState(() => _checkbox4 = value),
            ),
            buildResultDisplay('Selected Languages', _checkbox4),

            buildSectionTitle('CHECKBOX - Custom Styling', Colors.pink.shade700,
                Colors.pink.shade400),

            // Example 5: Custom Border & Colors
            buildFieldTitle(
                'Custom Border & Active Color', Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: 'Skills',
              initialValue: _checkbox5,
              items: const [
                'Leadership',
                'Communication',
                'Problem Solving',
                'Time Management',
                'Teamwork',
                'Critical Thinking',
                'Creativity',
                'Adaptability',
                'Decision Making',
                'Conflict Resolution',
                'Negotiation',
                'Project Management',
                'Strategic Planning',
                'Public Speaking',
                'Active Listening',
                'Emotional Intelligence',
                'Customer Service',
                'Sales',
                'Marketing',
                'Data Analysis',
                'Research',
                'Technical Writing',
                'Mentoring',
                'Coaching',
                'Delegation',
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
            buildFieldTitle('Custom Item Padding', Colors.pink.shade600),
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

            buildSectionTitle('CHECKBOX - Layout Variations',
                Colors.pink.shade700, Colors.pink.shade400),

            // Example 7: Horizontal Layout
            buildFieldTitle(
                'Horizontal Layout - Days of Week', Colors.pink.shade600),
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
            buildFieldTitle('Vertical Layout - Features', Colors.pink.shade600),
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
            buildResultDisplay('Selected Features', _checkbox8,
                isOptional: true),

            buildSectionTitle('CHECKBOX - Advanced Features',
                Colors.pink.shade700, Colors.pink.shade400),

            // Example 9: Custom Validation
            buildFieldTitle(
                'Custom Validation - Minimum Selections', Colors.pink.shade600),
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
            buildFieldTitle('Custom Item Padding', Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: 'Dietary Restrictions',
              initialValue: _checkbox4,
              items: const [
                'Vegetarian',
                'Vegan',
                'Gluten-Free',
                'Dairy-Free',
                'Nut Allergy',
                'Shellfish Allergy',
                'Egg Allergy',
                'Soy Allergy',
                'Lactose Intolerant',
                'Kosher',
                'Halal',
                'Pescatarian',
                'Raw Food',
                'Keto',
                'Paleo',
                'Low Carb',
                'Low Sodium',
                'Low Sugar',
                'Diabetic',
                'Heart Healthy',
                'No Preservatives',
                'Organic Only',
                'No Artificial Colors',
                'No MSG',
                'No GMO',
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
            buildFieldTitle(
                'Horizontal Layout - Notifications', Colors.pink.shade600),
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
            buildFieldTitle('Many Options - Scrollable', Colors.pink.shade600),
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
              isRequired: false,
              direction: Axis.vertical,
              borderColor: Colors.amber,
              activeColor: Colors.amber,
              itemPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              onChanged: (value) => setState(() => _checkbox6 = value),
            ),
            buildResultDisplay('Countries Visited', _checkbox6,
                isOptional: true),

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
