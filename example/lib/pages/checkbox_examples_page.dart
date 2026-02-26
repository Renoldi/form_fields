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
    final l = FormFieldsLocalizations.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildSectionTitle(l.get('cbBasicExamples'), Colors.pink.shade700,
                Colors.pink.shade400),

            // Example 1: Single Selection - Vertical
            buildFieldTitle(l.get('cbSingleVertical'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbTermsConditions'),
              initialValue: _checkbox1,
              items: [l.get('iAgreeTerms')],
              isRequired: true,
              direction: Axis.vertical,
              onChanged: (value) => setState(() => _checkbox1 = value),
            ),
            buildResultDisplay(context, l.get('cbTermsAgreed'), _checkbox1),

            // Example 2: Single Selection - Horizontal
            buildFieldTitle(l.get('cbSingleHorizontal'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbNewsletter'),
              initialValue: _checkbox2,
              items: [l.get('cbSubscribeWeekly')],
              isRequired: false,
              direction: Axis.horizontal,
              borderColor: Colors.blue,
              activeColor: Colors.blue,
              onChanged: (value) => setState(() => _checkbox2 = value),
            ),
            buildResultDisplay(
                context, l.get('cbNewsletterResult'), _checkbox2),

            buildSectionTitle(l.get('cbMultipleSelection'),
                Colors.pink.shade700, Colors.pink.shade400),

            // Example 3: Multiple Selection - Vertical
            buildFieldTitle(l.get('cbMultipleVertical'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbHobbies'),
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
            buildResultDisplay(context, l.get('cbSelectedHobbies'), _checkbox3),

            // Example 4: Multiple Selection - Horizontal
            buildFieldTitle(
                l.get('cbMultipleHorizontal'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbLanguages'),
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
            buildResultDisplay(
                context, l.get('cbSelectedLanguages'), _checkbox4),

            buildSectionTitle(l.get('cbCustomStyling'), Colors.pink.shade700,
                Colors.pink.shade400),

            // Example 5: Custom Border & Colors
            buildFieldTitle(l.get('cbCustomBorder'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbSkills'),
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
              itemBorderColor: Colors.purple.shade300,
              itemBorderWidth: 1.5,
              itemBorderRadius: 10,
              onChanged: (value) => setState(() => _checkbox5 = value),
            ),
            buildResultDisplay(context, l.get('cbSelectedSkills'), _checkbox5),

            // Example 6: Custom Item Padding
            buildFieldTitle(l.get('cbCustomPadding'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbContactMethods'),
              initialValue: _checkbox6,
              items: const ['Email', 'Phone', 'SMS', 'WhatsApp'],
              isRequired: false,
              direction: Axis.vertical,
              borderColor: Colors.orange,
              activeColor: Colors.orange,
              itemBorderColor: Colors.orange.shade300,
              itemBorderWidth: 1.25,
              itemBorderRadius: 8,
              itemPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              onChanged: (value) => setState(() => _checkbox6 = value),
            ),
            buildResultDisplay(context, l.get('cbContactMethods'), _checkbox6),

            buildSectionTitle(l.get('cbLayoutVariations'), Colors.pink.shade700,
                Colors.pink.shade400),

            // Example 7: Horizontal Layout
            buildFieldTitle(l.get('cbHorizontalLayout'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbDaysOfWeek'),
              initialValue: _checkbox7,
              items: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              isRequired: true,
              direction: Axis.horizontal,
              borderColor: Colors.indigo,
              activeColor: Colors.indigo,
              itemBorderColor: Colors.indigo.shade300,
              itemBorderWidth: 1.25,
              itemBorderRadius: 8,
              itemMarginTop: 6,
              itemMarginBottom: 6,
              itemMarginHorizontal: 4,
              onChanged: (value) => setState(() => _checkbox7 = value),
            ),
            buildResultDisplay(context, l.get('cbSelectedDays'), _checkbox7),

            // Example 8: Vertical Layout with Custom Colors
            buildFieldTitle(l.get('cbVerticalLayout'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbFeatures'),
              initialValue: _checkbox8,
              items: const ['WiFi', 'Parking', 'Gym', 'Pool'],
              isRequired: false,
              direction: Axis.vertical,
              borderColor: Colors.cyan,
              activeColor: Colors.cyan,
              onChanged: (value) => setState(() => _checkbox8 = value),
            ),
            buildResultDisplay(
                context, l.get('cbSelectedFeatures'), _checkbox8),

            buildSectionTitle(l.get('cbAdvancedFeatures'), Colors.pink.shade700,
                Colors.pink.shade400),

            // Example 9: Custom Validation
            buildFieldTitle(l.get('cbCustomValidation'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbRestrictedMinOptions'),
              initialValue: _checkbox3,
              items: const ['Option A', 'Option B', 'Option C', 'Option D'],
              isRequired: true,
              direction: Axis.vertical,
              borderColor: Colors.red,
              activeColor: Colors.red,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.get('cbMinSelections');
                }
                if (value.length < 2) {
                  return l.get('cbMinSelections');
                }
                return null;
              },
              onChanged: (value) => setState(() => _checkbox3 = value),
            ),
            buildResultDisplay(
                context, l.get('cbCustomValidationResult'), _checkbox3),

            // Example 10: Custom Styling
            buildFieldTitle(l.get('cbCustomPadding'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbDietaryRestrictions'),
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
            buildResultDisplay(
                context, l.get('cbDietaryRestrictions'), _checkbox4),

            // Example 11: Horizontal Layout with Custom Border
            buildFieldTitle(
                l.get('cbNotificationsLayout'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbNotifications'),
              initialValue: _checkbox5,
              items: const ['Push', 'Email', 'SMS', 'In-App'],
              isRequired: false,
              direction: Axis.horizontal,
              borderColor: Colors.deepPurple,
              activeColor: Colors.deepPurple,
              itemBorderColor: Colors.deepPurple.shade300,
              itemBorderWidth: 1.25,
              itemBorderRadius: 8,
              onChanged: (value) => setState(() => _checkbox5 = value),
            ),
            buildResultDisplay(context, l.get('cbNotifications'), _checkbox5),

            // Example 12: Many Options
            buildFieldTitle(
                l.get('cbManyOptionsScrollable'), Colors.pink.shade600),
            FormFieldsCheckbox<String>(
              label: l.get('cbCountriesVisited'),
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
            buildResultDisplay(
                context, l.get('cbSelectedCountriesVisited'), _checkbox6),

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
                child: Text(
                  l.get('validateFormButton'),
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
    final l = FormFieldsLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(l.get('cbFormValidated')),
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
