import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import '../widgets/result_display_widget.dart';

class DropdownMultiExamplesPage extends StatefulWidget {
  const DropdownMultiExamplesPage({Key? key}) : super(key: key);

  @override
  State<DropdownMultiExamplesPage> createState() =>
      _DropdownMultiExamplesPageState();
}

class _DropdownMultiExamplesPageState extends State<DropdownMultiExamplesPage> {
  final _formKey = GlobalKey<FormState>();

  // Multi-select dropdown values
  List<String> _multiDropdown1 = [];
  List<String> _multiDropdown2 = [];
  List<String> _multiDropdown3 = [];
  List<String> _multiDropdown4 = [];
  List<String> _multiDropdown5 = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade700, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.library_add_check, size: 48, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-Select Dropdown Examples',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Comprehensive examples of multi-select dropdown form fields',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Example 1: Basic Multi-Select
            _buildFieldTitle('1. Basic Multi-Select'),
            FormFieldsDropdownMulti<String>(
              label: 'Select Programming Languages',
              initialValues: _multiDropdown1,
              items: const [
                'Dart',
                'Java',
                'Kotlin',
                'Swift',
                'JavaScript',
                'Python',
                'C++',
                'Go',
                'Rust',
                'TypeScript',
              ],
              isRequired: true,
              onChanged: (values) => setState(() => _multiDropdown1 = values),
            ),
            buildResultDisplay('Programming Languages', _multiDropdown1),

            // Example 2: With Min/Max Constraints
            _buildFieldTitle('2. Min/Max Selections (Min: 2, Max: 4)'),
            FormFieldsDropdownMulti<String>(
              label: 'Select Skills',
              initialValues: _multiDropdown2,
              items: const [
                'Flutter',
                'Firebase',
                'REST API',
                'GraphQL',
                'State Management',
                'UI/UX Design',
                'Testing',
                'CI/CD',
                'Git',
                'Docker',
              ],
              isRequired: true,
              minSelections: 2,
              maxSelections: 4,
              chipBackgroundColor: Colors.blue.shade100,
              chipDeleteIconColor: Colors.blue.shade700,
              onChanged: (values) => setState(() => _multiDropdown2 = values),
            ),
            buildResultDisplay('Selected Skills', _multiDropdown2),

            // Example 3: Custom Styled
            _buildFieldTitle('3. Custom Chip Styling'),
            FormFieldsDropdownMulti<String>(
              label: 'Select Interests',
              initialValues: _multiDropdown3,
              items: const [
                'Gaming',
                'Music',
                'Sports',
                'Reading',
                'Travel',
                'Cooking',
                'Photography',
                'Art',
              ],
              isRequired: false,
              chipBackgroundColor: Colors.green.shade600,
              chipTextColor: Colors.white,
              chipDeleteIconColor: Colors.white,
              onChanged: (values) => setState(() => _multiDropdown3 = values),
            ),
            buildResultDisplay('Selected Interests', _multiDropdown3,
                isOptional: true),

            // Example 4: With Item Count Display
            _buildFieldTitle('4. With Item Count Display'),
            FormFieldsDropdownMulti<String>(
              label: 'Select Frameworks',
              initialValues: _multiDropdown4,
              items: const [
                'React',
                'Vue',
                'Angular',
                'Flutter',
                'React Native',
                'Svelte',
                'Next.js',
                'Nuxt.js',
              ],
              isRequired: false,
              showItemCount: true,
              chipBackgroundColor: Colors.orange.shade100,
              chipTextColor: Colors.orange.shade900,
              chipDeleteIconColor: Colors.orange.shade700,
              onChanged: (values) => setState(() => _multiDropdown4 = values),
            ),
            buildResultDisplay('Selected Frameworks', _multiDropdown4,
                isOptional: true),

            // Example 5: Custom Borders and Hint
            _buildFieldTitle('5. Custom Border & Hint Text'),
            FormFieldsDropdownMulti<String>(
              label: 'Select Countries Visited',
              initialValues: _multiDropdown5,
              items: const [
                'USA',
                'Canada',
                'UK',
                'Germany',
                'France',
                'Japan',
                'Australia',
                'Brazil',
                'India',
                'China',
              ],
              isRequired: false,
              hintText: 'Choose countries from the list',
              borderColor: Colors.grey.shade400,
              focusedBorderColor: Colors.purple,
              errorBorderColor: Colors.red.shade700,
              radius: 12,
              chipBackgroundColor: Colors.purple.shade100,
              chipDeleteIconColor: Colors.purple.shade700,
              labelPosition: LabelPosition.top,
              onChanged: (values) => setState(() => _multiDropdown5 = values),
            ),
            buildResultDisplay('Countries Visited', _multiDropdown5,
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
                  backgroundColor: Colors.purple.shade700,
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

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Container(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.purple.shade600,
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
            Text('Multi-select dropdown form validated successfully!'),
          ],
        ),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
