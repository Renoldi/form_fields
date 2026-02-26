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
    Country('BR', 'Brazil', '🇧🇷'),
    Country('IN', 'India', '🇮🇳'),
    Country('CN', 'China', '🇨🇳'),
    Country('IT', 'Italy', '🇮🇹'),
    Country('ES', 'Spain', '🇪🇸'),
    Country('MX', 'Mexico', '🇲🇽'),
    Country('RU', 'Russia', '🇷🇺'),
    Country('KR', 'South Korea', '🇰🇷'),
    Country('AR', 'Argentina', '🇦🇷'),
    Country('NL', 'Netherlands', '🇳🇱'),
    Country('SE', 'Sweden', '🇸🇪'),
    Country('CH', 'Switzerland', '🇨🇭'),
    Country('BE', 'Belgium', '🇧🇪'),
    Country('PL', 'Poland', '🇵🇱'),
    Country('NO', 'Norway', '🇳🇴'),
    Country('AT', 'Austria', '🇦🇹'),
    Country('DK', 'Denmark', '🇩🇰'),
    Country('FI', 'Finland', '🇫🇮'),
    Country('IE', 'Ireland', '🇮🇪'),
    Country('PT', 'Portugal', '🇵🇹'),
    Country('GR', 'Greece', '🇬🇷'),
    Country('NZ', 'New Zealand', '🇳🇿'),
    Country('SG', 'Singapore', '🇸🇬'),
  ];

  final List<Skill> skills = [
    Skill('flutter', 'Flutter', 'Mobile', Icons.phone_android),
    Skill('dart', 'Dart', 'Language', Icons.code),
    Skill('firebase', 'Firebase', 'Backend', Icons.cloud),
    Skill('rest', 'REST API', 'Backend', Icons.api),
    Skill('graphql', 'GraphQL', 'Backend', Icons.graphic_eq),
    Skill('ui', 'UI/UX Design', 'Design', Icons.design_services),
    Skill('testing', 'Testing', 'Quality', Icons.bug_report),
    Skill('react', 'React', 'Frontend', Icons.web),
    Skill('vue', 'Vue.js', 'Frontend', Icons.web),
    Skill('angular', 'Angular', 'Frontend', Icons.web),
    Skill('node', 'Node.js', 'Backend', Icons.dns),
    Skill('python', 'Python', 'Language', Icons.code),
    Skill('java', 'Java', 'Language', Icons.code),
    Skill('kotlin', 'Kotlin', 'Language', Icons.code),
    Skill('swift', 'Swift', 'Language', Icons.code),
    Skill('typescript', 'TypeScript', 'Language', Icons.code),
    Skill('javascript', 'JavaScript', 'Language', Icons.code),
    Skill('docker', 'Docker', 'DevOps', Icons.storage),
    Skill('kubernetes', 'Kubernetes', 'DevOps', Icons.cloud_circle),
    Skill('aws', 'AWS', 'Cloud', Icons.cloud_queue),
    Skill('azure', 'Azure', 'Cloud', Icons.cloud_queue),
    Skill('gcp', 'Google Cloud', 'Cloud', Icons.cloud_queue),
    Skill('mongodb', 'MongoDB', 'Database', Icons.storage),
    Skill('postgresql', 'PostgreSQL', 'Database', Icons.storage),
    Skill('mysql', 'MySQL', 'Database', Icons.storage),
    Skill('redis', 'Redis', 'Database', Icons.storage_rounded),
    Skill('git', 'Git', 'Version Control', Icons.source),
    Skill('agile', 'Agile', 'Methodology', Icons.groups),
    Skill('scrum', 'Scrum', 'Methodology', Icons.people),
    Skill('cicd', 'CI/CD', 'DevOps', Icons.sync),
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
  Country? _selectedCountryWithFilter;
  List<Skill> _selectedSkillsWithFilter = [];

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
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
              child: Row(
                children: [
                  const Icon(Icons.class_, size: 48, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.get('ccHeaderTitle'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.get('ccHeaderSubtitle'),
                          style: const TextStyle(
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
            buildSectionTitle(l.get('ccSectionDropdownCustomClass'),
                Colors.teal.shade700, Colors.teal.shade400),
            buildFieldTitle(l.get('ccFieldCountryFlag'), Colors.teal.shade600),
            FormFieldsDropdown<Country>(
              label: l.get('ccSelectCountry'),
              items: countries,
              initialValue: _selectedCountry,
              isRequired: true,
              itemLabelBuilder: (country) => '${country.flag} ${country.name}',
              onChanged: (value) {
                setState(() => _selectedCountry = value);
              },
            ),
            buildResultDisplay(
                context, l.get('ccSelectedCountry'), _selectedCountry),

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
            buildSectionTitle(l.get('ccSectionMultiSelectCustomClass'),
                Colors.teal.shade700, Colors.teal.shade400),
            buildFieldTitle(
                l.get('ccFieldSkillsCategories'), Colors.teal.shade600),
            FormFieldsDropdownMulti<Skill>(
              label: l.get('ccSelectSkills'),
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
            buildResultDisplay(
                context, l.get('ccSelectedSkills'), _selectedSkills),

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
            buildSectionTitle(l.get('ccSectionRadioCustomClass'),
                Colors.teal.shade700, Colors.teal.shade400),
            buildFieldTitle(
                l.get('ccFieldPlanSelection'), Colors.teal.shade600),
            FormFieldsRadioButton<SubscriptionPlan>(
              label: l.get('ccSelectPlan'),
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
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
                  ),
                );
              },
              onChanged: (value) {
                setState(() => _selectedPlan = value);
              },
            ),
            buildResultDisplay(context, l.get('ccSelectedPlan'), _selectedPlan),

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
            buildSectionTitle(l.get('ccSectionCheckboxCustomClass'),
                Colors.teal.shade700, Colors.teal.shade400),
            buildFieldTitle(
                l.get('ccFieldInterestsSelection'), Colors.teal.shade600),
            FormFieldsCheckbox<Interest>(
              label: l.get('ccSelectInterests'),
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
            buildResultDisplay(
                context, l.get('ccSelectedInterests'), _selectedInterests),

            const SizedBox(height: 16),

            if (_selectedInterests.isNotEmpty)
              _buildInfoCard(
                'Selected Interests (${_selectedInterests.length})',
                _selectedInterests.map((i) => '• ${i.name}').join('\n'),
                Colors.green.shade50,
              ),

            const SizedBox(height: 32),

            // Example 5: Dropdown with Filter and Custom Class
            buildSectionTitle(l.get('ccSectionDropdownFilterCustomClass'),
                Colors.teal.shade700, Colors.teal.shade400),
            buildFieldTitle(
                l.get('ccFieldCountrySearchFilter'), Colors.teal.shade600),
            FormFieldsDropdown<Country>(
              label: l.get('ccSelectCountryFilter'),
              items: countries,
              initialValue: _selectedCountryWithFilter,
              isRequired: true,
              enableFilter: true,
              filterHintText: l.get('ccSearchCountriesHint'),
              itemLabelBuilder: (country) => '${country.flag} ${country.name}',
              borderColor: Colors.orange,
              focusedBorderColor: Colors.orange.shade700,
              onChanged: (value) {
                setState(() => _selectedCountryWithFilter = value);
              },
            ),
            buildResultDisplay(context, l.get('ccSelectedCountryFiltered'),
                _selectedCountryWithFilter),

            const SizedBox(height: 16),

            if (_selectedCountryWithFilter != null)
              _buildInfoCard(
                'Selected Country Details',
                'Code: ${_selectedCountryWithFilter!.code}\n'
                    'Name: ${_selectedCountryWithFilter!.name}\n'
                    'Flag: ${_selectedCountryWithFilter!.flag}',
                Colors.orange.shade50,
              ),

            const SizedBox(height: 32),

            // Example 6: Multi-Select Dropdown with Filter and Custom Class
            buildSectionTitle(l.get('ccSectionMultiSelectFilterCustomClass'),
                Colors.teal.shade700, Colors.teal.shade400),
            buildFieldTitle(
                l.get('ccFieldSkillsSearchFilter'), Colors.teal.shade600),
            FormFieldsDropdownMulti<Skill>(
              label: l.get('ccSelectSkillsFilter'),
              items: skills,
              initialValues: _selectedSkillsWithFilter,
              isRequired: false,
              enableFilter: true,
              filterHintText: l.get('ccSearchSkillsHint'),
              itemLabelBuilder: (skill) => '${skill.name} (${skill.category})',
              chipBackgroundColor: Colors.indigo.shade100,
              chipTextColor: Colors.indigo.shade900,
              chipDeleteIconColor: Colors.indigo.shade700,
              showItemCount: true,
              onChanged: (values) {
                setState(() => _selectedSkillsWithFilter = values);
              },
            ),
            buildResultDisplay(context, l.get('ccSelectedSkillsFiltered'),
                _selectedSkillsWithFilter),

            const SizedBox(height: 16),

            if (_selectedSkillsWithFilter.isNotEmpty)
              _buildInfoCard(
                'Selected Skills Details (${_selectedSkillsWithFilter.length})',
                _selectedSkillsWithFilter
                    .map((s) => '• ${s.name} - ${s.category}')
                    .join('\n'),
                Colors.indigo.shade50,
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
    final l = FormFieldsLocalizations.of(context);
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
                l.get('ccFormValidated'),
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
