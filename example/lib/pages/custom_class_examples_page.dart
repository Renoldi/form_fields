import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import '../widgets/result_display_widget.dart';

// Custom Model Classes
class Country {
  final String code;
  final String name;
  final String flag;

  Country(this.code, this.name, this.flag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}

class Skill {
  final String id;
  final String name;
  final String category;
  final IconData icon;

  Skill(this.id, this.name, this.category, this.icon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Skill && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String features;

  SubscriptionPlan(this.id, this.name, this.price, this.features);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class Interest {
  final String id;
  final String name;
  final Color color;

  Interest(this.id, this.name, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interest && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class CustomClassExamplesPage extends StatefulWidget {
  const CustomClassExamplesPage({Key? key}) : super(key: key);

  @override
  State<CustomClassExamplesPage> createState() =>
      _CustomClassExamplesPageState();
}

class _CustomClassExamplesPageState extends State<CustomClassExamplesPage> {
  final _formKey = GlobalKey<FormState>();

  // Sample data
  final List<Country> countries = [
    Country('US', 'United States', '🇺🇸'),
    Country('CA', 'Canada', '🇨🇦'),
    Country('GB', 'United Kingdom', '🇬🇧'),
    Country('DE', 'Germany', '🇩🇪'),
    Country('FR', 'France', '🇫🇷'),
    Country('JP', 'Japan', '🇯🇵'),
    Country('AU', 'Australia', '🇦🇺'),
  ];

  final List<Skill> skills = [
    Skill('flutter', 'Flutter', 'Mobile', Icons.phone_android),
    Skill('dart', 'Dart', 'Language', Icons.code),
    Skill('firebase', 'Firebase', 'Backend', Icons.cloud),
    Skill('rest', 'REST API', 'Backend', Icons.api),
    Skill('graphql', 'GraphQL', 'Backend', Icons.graphic_eq),
    Skill('ui', 'UI/UX Design', 'Design', Icons.design_services),
    Skill('testing', 'Testing', 'Quality', Icons.bug_report),
  ];

  final List<SubscriptionPlan> plans = [
    SubscriptionPlan('free', 'Free', 0, 'Basic features'),
    SubscriptionPlan('pro', 'Pro', 9.99, 'Advanced features'),
    SubscriptionPlan('enterprise', 'Enterprise', 29.99, 'All features'),
  ];

  final List<Interest> interests = [
    Interest('gaming', 'Gaming', Colors.purple),
    Interest('music', 'Music', Colors.pink),
    Interest('sports', 'Sports', Colors.orange),
    Interest('reading', 'Reading', Colors.blue),
    Interest('travel', 'Travel', Colors.green),
    Interest('cooking', 'Cooking', Colors.red),
  ];

  // Selected values
  Country? _selectedCountry;
  List<Skill> _selectedSkills = [];
  SubscriptionPlan? _selectedPlan;
  List<Interest> _selectedInterests = [];

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
                  colors: [Colors.teal.shade700, Colors.teal.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.class_, size: 48, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Class Examples',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Using generic types with custom model classes',
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

            // Example 1: Dropdown with Custom Class
            _buildSectionTitle('Dropdown with Custom Class'),
            _buildFieldTitle('Country Selection with Flag Icon'),
            FormFieldsDropdown<Country>(
              label: 'Select Country',
              items: countries,
              initialValue: _selectedCountry,
              isRequired: true,
              itemLabelBuilder: (country) => '${country.flag} ${country.name}',
              onChanged: (value) {
                setState(() => _selectedCountry = value);
              },
            ),
            buildResultDisplay('Selected Country', _selectedCountry),

            const SizedBox(height: 16),

            if (_selectedCountry != null)
              _buildInfoCard(
                'Selected Country',
                'Code: ${_selectedCountry!.code}\n'
                    'Name: ${_selectedCountry!.name}\n'
                    'Flag: ${_selectedCountry!.flag}',
                Colors.blue.shade50,
              ),

            const SizedBox(height: 32),

            // Example 2: Multi-Select Dropdown with Custom Class
            _buildSectionTitle('Multi-Select Dropdown with Custom Class'),
            _buildFieldTitle('Skills Selection with Categories'),
            FormFieldsDropdownMulti<Skill>(
              label: 'Select Your Skills',
              items: skills,
              initialValues: _selectedSkills,
              isRequired: true,
              minSelections: 2,
              maxSelections: 5,
              itemLabelBuilder: (skill) => '${skill.name} (${skill.category})',
              chipBackgroundColor: Colors.teal.shade100,
              chipTextColor: Colors.teal.shade900,
              chipDeleteIconColor: Colors.teal.shade700,
              showItemCount: true,
              onChanged: (values) {
                setState(() => _selectedSkills = values);
              },
            ),
            buildResultDisplay('Selected Skills', _selectedSkills),

            const SizedBox(height: 16),

            if (_selectedSkills.isNotEmpty)
              _buildInfoCard(
                'Selected Skills (${_selectedSkills.length})',
                _selectedSkills
                    .map((s) => '• ${s.name} - ${s.category}')
                    .join('\n'),
                Colors.teal.shade50,
              ),

            const SizedBox(height: 32),

            // Example 3: Radio Button with Custom Class
            _buildSectionTitle('Radio Button with Custom Class'),
            _buildFieldTitle('Subscription Plan Selection'),
            FormFieldsRadioButton<SubscriptionPlan>(
              label: 'Choose Your Plan',
              items: plans,
              initialValue: _selectedPlan,
              isRequired: true,
              direction: Axis.vertical,
              activeColor: Colors.purple,
              itemLabelBuilder: (plan) =>
                  '${plan.name} - \$${plan.price}/month',
              itemBuilder: (plan, selected) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        selected ? Colors.purple.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.purple : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<SubscriptionPlan>(
                        value: plan,
                        groupValue: _selectedPlan,
                        onChanged: (value) {
                          setState(() => _selectedPlan = value);
                        },
                        activeColor: Colors.purple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    selected ? Colors.purple : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${plan.price}/month',
                              style: TextStyle(
                                fontSize: 16,
                                color: selected
                                    ? Colors.purple.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.features,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              onChanged: (value) {
                setState(() => _selectedPlan = value);
              },
            ),
            buildResultDisplay('Selected Plan', _selectedPlan),

            const SizedBox(height: 16),

            if (_selectedPlan != null)
              _buildInfoCard(
                'Selected Plan',
                'Plan: ${_selectedPlan!.name}\n'
                    'Price: \$${_selectedPlan!.price}/month\n'
                    'Features: ${_selectedPlan!.features}',
                Colors.purple.shade50,
              ),

            const SizedBox(height: 32),

            // Example 4: Checkbox with Custom Class
            _buildSectionTitle('Checkbox with Custom Class'),
            _buildFieldTitle('Interests Selection with Colors'),
            FormFieldsCheckbox<Interest>(
              label: 'Select Your Interests',
              items: interests,
              initialValue: _selectedInterests,
              isRequired: false,
              direction: Axis.vertical,
              activeColor: Colors.green,
              itemBuilder: (interest, selected) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? interest.color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? interest.color : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedInterests.add(interest);
                            } else {
                              _selectedInterests.remove(interest);
                            }
                          });
                        },
                        activeColor: interest.color,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: interest.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        interest.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? interest.color : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
              onChanged: (values) {
                setState(() => _selectedInterests = values);
              },
            ),
            buildResultDisplay('Selected Interests', _selectedInterests,
                isOptional: true),

            const SizedBox(height: 16),

            if (_selectedInterests.isNotEmpty)
              _buildInfoCard(
                'Selected Interests (${_selectedInterests.length})',
                _selectedInterests.map((i) => '• ${i.name}').join('\n'),
                Colors.green.shade50,
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
                  backgroundColor: Colors.teal.shade700,
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
                colors: [Colors.teal.shade700, Colors.teal.shade400],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
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
              color: Colors.teal.shade600,
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

  Widget _buildInfoCard(String title, String content, Color backgroundColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showFormData() {
    final message = StringBuffer();
    message.writeln('Form Data:');
    message.writeln('Country: ${_selectedCountry?.name ?? "None"}');
    message.writeln('Skills: ${_selectedSkills.map((s) => s.name).join(", ")}');
    message.writeln('Plan: ${_selectedPlan?.name ?? "None"}');
    message.writeln(
        'Interests: ${_selectedInterests.map((i) => i.name).join(", ")}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Form validated! Check console for details.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );

    // Print to console
    print(message.toString());
  }
}
