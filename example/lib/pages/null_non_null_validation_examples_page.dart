import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import '../widgets/language_indicator.dart';

class NullNonNullValidationExamplesPage extends StatefulWidget {
  const NullNonNullValidationExamplesPage({Key? key}) : super(key: key);

  @override
  State<NullNonNullValidationExamplesPage> createState() =>
      _NullNonNullValidationExamplesPageState();
}

class _NullNonNullValidationExamplesPageState
    extends State<NullNonNullValidationExamplesPage> {
  final _formKey = GlobalKey<FormState>();

  // ===== STRING TYPE =====
  String _stringNonNullRequired = '';
  String _stringNonNullOptional = '';
  String? _stringNullRequired;
  String? _stringNullOptional;

  // ===== INT TYPE =====
  int _intNonNullRequired = 0;
  int _intNonNullOptional = 0;
  int? _intNullRequired;
  int? _intNullOptional;

  // ===== DOUBLE TYPE =====
  double _doubleNonNullRequired = 0.0;
  double _doubleNonNullOptional = 0.0;
  double? _doubleNullRequired;
  double? _doubleNullOptional;

  // ===== CUSTOM VALIDATION TYPE =====
  String _usernameCustom = '';
  String? _emailCustom;
  int _ageCustom = 0;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Language indicator
            const LanguageIndicator(),
            const SizedBox(height: 16),

            // ===== STRING VALIDATION PATTERNS =====
            buildSectionTitle(
              'STRING: Nullable vs Non-Nullable with isRequired',
              Colors.blue.shade700,
              Colors.blue.shade400,
            ),

            // PATTERN 1: Non-Nullable + isRequired: true
            buildFieldTitle(
              'Pattern 1: String (Non-Null) + isRequired: true',
              Colors.green.shade600,
            ),
            buildDescriptionBox(
              'Type: String | Nullable: ❌ | Required: ✓\n'
              'Behavior: MUST have value, cannot be empty, cannot be null',
              Colors.green,
            ),
            FormFields<String>(
              label: 'Full Name',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.green,
              onChanged: (value) =>
                  setState(() => _stringNonNullRequired = value),
              currrentValue: _stringNonNullRequired,
            ),
            buildResultDisplay('Full Name', _stringNonNullRequired),
            const SizedBox(height: 24),

            // PATTERN 2: Non-Nullable + isRequired: false
            buildFieldTitle(
              'Pattern 2: String (Non-Null) + isRequired: false',
              Colors.orange.shade600,
            ),
            buildDescriptionBox(
              'Type: String | Nullable: ❌ | Required: ❌\n'
              'Behavior: Optional field, but if filled must be valid\n'
              'Note: Default empty string satisfies non-null requirement',
              Colors.orange,
            ),
            FormFields<String>(
              label: 'Middle Name',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.orange,
              onChanged: (value) =>
                  setState(() => _stringNonNullOptional = value),
              currrentValue: _stringNonNullOptional,
            ),
            buildResultDisplay('Middle Name', _stringNonNullOptional,
                isOptional: true),
            const SizedBox(height: 24),

            // PATTERN 3: Nullable + isRequired: true
            buildFieldTitle(
              'Pattern 3: String (Nullable) + isRequired: true',
              Colors.red.shade600,
            ),
            buildDescriptionBox(
              'Type: String? | Nullable: ✓ | Required: ✓\n'
              'Behavior: MUST have value, cannot be null, cannot be empty\n'
              'Validation: isRequired=true overrides nullability',
              Colors.red,
            ),
            FormFields<String?>(
              label: 'Last Name',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.red,
              onChanged: (value) => setState(() => _stringNullRequired = value),
              currrentValue: _stringNullRequired,
            ),
            buildResultDisplay('Last Name', _stringNullRequired),
            const SizedBox(height: 24),

            // PATTERN 4: Nullable + isRequired: false
            buildFieldTitle(
              'Pattern 4: String (Nullable) + isRequired: false',
              Colors.purple.shade600,
            ),
            buildDescriptionBox(
              'Type: String? | Nullable: ✓ | Required: ❌\n'
              'Behavior: Fully optional, can be null or empty\n'
              'Best for: Optional user input fields',
              Colors.purple,
            ),
            FormFields<String?>(
              label: 'Nickname',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.purple,
              onChanged: (value) => setState(() => _stringNullOptional = value),
              currrentValue: _stringNullOptional,
            ),
            buildResultDisplay('Nickname', _stringNullOptional,
                isOptional: true),
            const SizedBox(height: 32),

            // ===== INT VALIDATION PATTERNS =====
            buildSectionTitle(
              'INT: Nullable vs Non-Nullable with isRequired',
              Colors.teal.shade700,
              Colors.teal.shade400,
            ),

            // PATTERN 1: Non-Nullable + isRequired: true
            buildFieldTitle(
              'Pattern 1: Int (Non-Null) + isRequired: true',
              Colors.green.shade600,
            ),
            buildDescriptionBox(
              'Type: int | Nullable: ❌ | Required: ✓\n'
              'Behavior: MUST enter valid integer, cannot skip\n'
              'Default: 0 (satisfies non-null requirement)',
              Colors.green,
            ),
            FormFields<int>(
              label: 'Age',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.green,
              onChanged: (value) => setState(() => _intNonNullRequired = value),
              currrentValue: _intNonNullRequired,
            ),
            buildResultDisplay('Age', _intNonNullRequired),
            const SizedBox(height: 24),

            // PATTERN 2: Non-Nullable + isRequired: false
            buildFieldTitle(
              'Pattern 2: Int (Non-Null) + isRequired: false',
              Colors.orange.shade600,
            ),
            buildDescriptionBox(
              'Type: int | Nullable: ❌ | Required: ❌\n'
              'Behavior: Optional, default to 0 if left empty\n'
              'Validation: Only validates if user enters value',
              Colors.orange,
            ),
            FormFields<int>(
              label: 'Phone Extension',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.orange,
              onChanged: (value) => setState(() => _intNonNullOptional = value),
              currrentValue: _intNonNullOptional,
            ),
            buildResultDisplay('Phone Extension', _intNonNullOptional,
                isOptional: true),
            const SizedBox(height: 24),

            // PATTERN 3: Nullable + isRequired: true
            buildFieldTitle(
              'Pattern 3: Int (Nullable) + isRequired: true',
              Colors.red.shade600,
            ),
            buildDescriptionBox(
              'Type: int? | Nullable: ✓ | Required: ✓\n'
              'Behavior: MUST enter valid integer, cannot be null\n'
              'Error: "Enter Stock Quantity" if left empty',
              Colors.red,
            ),
            FormFields<int?>(
              label: 'Stock Quantity',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.red,
              onChanged: (value) => setState(() => _intNullRequired = value),
              currrentValue: _intNullRequired,
            ),
            buildResultDisplay('Stock Quantity', _intNullRequired),
            const SizedBox(height: 24),

            // PATTERN 4: Nullable + isRequired: false
            buildFieldTitle(
              'Pattern 4: Int (Nullable) + isRequired: false',
              Colors.purple.shade600,
            ),
            buildDescriptionBox(
              'Type: int? | Nullable: ✓ | Required: ❌\n'
              'Behavior: Fully optional, can be null or empty\n'
              'Best for: Optional numeric fields',
              Colors.purple,
            ),
            FormFields<int?>(
              label: 'Employee ID',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.purple,
              onChanged: (value) => setState(() => _intNullOptional = value),
              currrentValue: _intNullOptional,
            ),
            buildResultDisplay('Employee ID', _intNullOptional,
                isOptional: true),
            const SizedBox(height: 32),

            // ===== DOUBLE VALIDATION PATTERNS =====
            buildSectionTitle(
              'DOUBLE: Nullable vs Non-Nullable with isRequired',
              Colors.indigo.shade700,
              Colors.indigo.shade400,
            ),

            // PATTERN 1: Non-Nullable + isRequired: true
            buildFieldTitle(
              'Pattern 1: Double (Non-Null) + isRequired: true',
              Colors.green.shade600,
            ),
            buildDescriptionBox(
              'Type: double | Nullable: ❌ | Required: ✓\n'
              'Behavior: MUST enter valid decimal, cannot skip\n'
              'Default: 0.0 (satisfies non-null requirement)',
              Colors.green,
            ),
            FormFields<double>(
              label: 'Product Price',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.green,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('\$', style: TextStyle(fontSize: 16)),
              ),
              onChanged: (value) =>
                  setState(() => _doubleNonNullRequired = value),
              currrentValue: _doubleNonNullRequired,
            ),
            buildResultDisplay('Product Price', _doubleNonNullRequired),
            const SizedBox(height: 24),

            // PATTERN 2: Non-Nullable + isRequired: false
            buildFieldTitle(
              'Pattern 2: Double (Non-Null) + isRequired: false',
              Colors.orange.shade600,
            ),
            buildDescriptionBox(
              'Type: double | Nullable: ❌ | Required: ❌\n'
              'Behavior: Optional, default to 0.0 if left empty\n'
              'Validation: Only validates if user enters value',
              Colors.orange,
            ),
            FormFields<double>(
              label: 'Shipping Cost',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.orange,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('\$', style: TextStyle(fontSize: 16)),
              ),
              onChanged: (value) =>
                  setState(() => _doubleNonNullOptional = value),
              currrentValue: _doubleNonNullOptional,
            ),
            buildResultDisplay('Shipping Cost', _doubleNonNullOptional,
                isOptional: true),
            const SizedBox(height: 24),

            // PATTERN 3: Nullable + isRequired: true
            buildFieldTitle(
              'Pattern 3: Double (Nullable) + isRequired: true',
              Colors.red.shade600,
            ),
            buildDescriptionBox(
              'Type: double? | Nullable: ✓ | Required: ✓\n'
              'Behavior: MUST enter valid decimal, cannot be null\n'
              'Error: "Enter Discount Rate" if left empty',
              Colors.red,
            ),
            FormFields<double?>(
              label: 'Discount Rate',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.red,
              suffix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('%', style: TextStyle(fontSize: 16)),
              ),
              onChanged: (value) => setState(() => _doubleNullRequired = value),
              currrentValue: _doubleNullRequired,
            ),
            buildResultDisplay('Discount Rate', _doubleNullRequired),
            const SizedBox(height: 24),

            // PATTERN 4: Nullable + isRequired: false
            buildFieldTitle(
              'Pattern 4: Double (Nullable) + isRequired: false',
              Colors.purple.shade600,
            ),
            buildDescriptionBox(
              'Type: double? | Nullable: ✓ | Required: ❌\n'
              'Behavior: Fully optional, can be null or empty\n'
              'Best for: Optional decimal fields',
              Colors.purple,
            ),
            FormFields<double?>(
              label: 'Commission Amount',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.purple,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('\$', style: TextStyle(fontSize: 16)),
              ),
              onChanged: (value) => setState(() => _doubleNullOptional = value),
              currrentValue: _doubleNullOptional,
            ),
            buildResultDisplay('Commission Amount', _doubleNullOptional,
                isOptional: true),
            const SizedBox(height: 32),

            // ===== CUSTOM VALIDATION =====
            buildSectionTitle(
              'CUSTOM VALIDATION: Using Custom Validators',
              Colors.teal.shade700,
              Colors.teal.shade400,
            ),

            buildFieldTitle(
              'Custom Validation 1: Username with Constraints',
              Colors.teal.shade600,
            ),
            buildDescriptionBox(
              'Custom Rules: Min 3 chars, max 20 chars, alphanumeric + underscore only',
              Colors.teal,
            ),
            FormFields<String>(
              label: 'Username',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.teal,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (value.length > 20) {
                  return 'Username cannot exceed 20 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
              onChanged: (value) => setState(() => _usernameCustom = value),
              currrentValue: _usernameCustom,
            ),
            buildResultDisplay('Username', _usernameCustom),
            const SizedBox(height: 24),

            buildFieldTitle(
              'Custom Validation 2: Email with Domain Restriction',
              Colors.cyan.shade600,
            ),
            buildDescriptionBox(
              'Custom Rules: Valid email AND must be company domain only',
              Colors.cyan,
            ),
            FormFields<String?>(
              label: 'Company Email',
              formType: FormType.email,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.cyan,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Optional field
                }
                // First check if valid email format
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                    .hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                // Then check if company domain
                if (!value.endsWith('@company.com')) {
                  return 'Only @company.com emails are allowed';
                }
                return null;
              },
              onChanged: (value) => setState(() => _emailCustom = value),
              currrentValue: _emailCustom,
            ),
            buildResultDisplay('Company Email', _emailCustom, isOptional: true),
            const SizedBox(height: 24),

            buildFieldTitle(
              'Custom Validation 3: Age Range Validation',
              Colors.indigo.shade600,
            ),
            buildDescriptionBox(
              'Custom Rules: Age must be between 18 and 65',
              Colors.indigo,
            ),
            FormFields<int>(
              label: 'Age',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.indigo,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Age is required';
                }
                final age = int.tryParse(value);
                if (age == null) {
                  return 'Enter a valid number';
                }
                if (age < 18) {
                  return 'Must be at least 18 years old';
                }
                if (age > 65) {
                  return 'Age cannot exceed 65';
                }
                return null;
              },
              onChanged: (value) => setState(() => _ageCustom = value),
              currrentValue: _ageCustom,
            ),
            buildResultDisplay('Age', _ageCustom),
            const SizedBox(height: 32),

            // ===== VALIDATION RULES SUMMARY =====
            buildSectionTitle(
              'Validation Rules Summary',
              Colors.grey.shade700,
              Colors.grey.shade400,
            ),
            buildRuleBox(
              'Rule 1: Non-Null + isRequired: true',
              '✓ MUST have value\n'
                  '✗ Cannot be empty\n'
                  '✗ Default value (0, "", 0.0) required',
              Colors.green,
            ),
            buildRuleBox(
              'Rule 2: Non-Null + isRequired: false',
              '✓ Can be empty\n'
                  '✓ Uses default value if empty\n'
                  '✗ Still validates if user enters value',
              Colors.orange,
            ),
            buildRuleBox(
              'Rule 3: Nullable + isRequired: true',
              '✓ MUST have value\n'
                  '✗ Cannot be null\n'
                  '✗ Cannot be empty\n'
                  '⚠ isRequired overrides type nullability',
              Colors.red,
            ),
            buildRuleBox(
              'Rule 4: Nullable + isRequired: false',
              '✓ Can be empty\n'
                  '✓ Can be null\n'
                  '✓ Fully optional field\n'
                  '⚠ Only validates if value provided',
              Colors.purple,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  print(
                      '\n╔═══════════════════════════════════════════════════════════════╗');
                  print(
                      '║ FORM SUBMIT BUTTON CLICKED                                      ║');
                  print(
                      '╚═══════════════════════════════════════════════════════════════╝');

                  final isValid = _formKey.currentState!.validate();
                  print('Form validation result: $isValid');

                  if (!isValid) {
                    print('❌ Form validation FAILED - showing errors');
                    return;
                  } else {
                    print('✓ Form validation PASSED - submitting');
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
                  'VALIDATE & SUBMIT',
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
            Text('Form validated successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget buildSectionTitle(String title, Color darkColor, Color lightColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkColor, lightColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildFieldTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget buildDescriptionBox(String description, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget buildRuleBox(String title, String rules, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rules,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResultDisplay(String label, dynamic value,
      {bool isOptional = false}) {
    final displayValue = value ?? '(null)';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $displayValue${isOptional ? ' (optional)' : ''}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
