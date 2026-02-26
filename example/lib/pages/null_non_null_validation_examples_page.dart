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
    final l = FormFieldsLocalizations.of(context);
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
              l.get('valStringNullable'),
              Colors.blue.shade700,
              Colors.blue.shade400,
            ),

            // PATTERN 1: Non-Nullable + isRequired: true
            buildFieldTitle(l.get('valPattern1'), Colors.green.shade600),
            buildDescriptionBox(
              l.get('valStringDesc1'),
              Colors.green,
            ),
            FormFields<String>(
              label: l.get('ffFullName'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.green,
              onChanged: (value) =>
                  setState(() => _stringNonNullRequired = value),
              currrentValue: _stringNonNullRequired,
            ),
            buildResultDisplay(l.get('ffFullName'), _stringNonNullRequired),
            const SizedBox(height: 24),

            // PATTERN 2: Non-Nullable + isRequired: false
            buildFieldTitle(l.get('valPattern2'), Colors.orange.shade600),
            buildDescriptionBox(
              l.get('valStringDesc2'),
              Colors.orange,
            ),
            FormFields<String>(
              label: l.get('ffMiddleName'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.orange,
              onChanged: (value) =>
                  setState(() => _stringNonNullOptional = value),
              currrentValue: _stringNonNullOptional,
            ),
            buildResultDisplay(l.get('ffMiddleName'), _stringNonNullOptional,
                isOptional: true),
            const SizedBox(height: 24),

            // PATTERN 3: Nullable + isRequired: true
            buildFieldTitle(l.get('valPattern3'), Colors.red.shade600),
            buildDescriptionBox(
              l.get('valStringDesc3'),
              Colors.red,
            ),
            FormFields<String?>(
              label: l.get('ffLastName'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.red,
              onChanged: (value) => setState(() => _stringNullRequired = value),
              currrentValue: _stringNullRequired,
            ),
            buildResultDisplay(l.get('ffLastName'), _stringNullRequired),
            const SizedBox(height: 24),

            // PATTERN 4: Nullable + isRequired: false
            buildFieldTitle(l.get('valPattern4'), Colors.purple.shade600),
            buildDescriptionBox(
              l.get('valStringDesc4'),
              Colors.purple,
            ),
            FormFields<String?>(
              label: l.get('valNickname'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.purple,
              onChanged: (value) => setState(() => _stringNullOptional = value),
              currrentValue: _stringNullOptional,
            ),
            buildResultDisplay(l.get('valNickname'), _stringNullOptional,
                isOptional: true),
            const SizedBox(height: 32),

            // ===== INT VALIDATION PATTERNS =====
            buildSectionTitle(l.get('valIntPatterns'), Colors.teal.shade700,
                Colors.teal.shade400),

            // PATTERN 1: Non-Nullable + isRequired: true
            buildFieldTitle(l.get('valIntPattern1'), Colors.green.shade600),
            buildDescriptionBox(
              l.get('valIntDesc1'),
              Colors.green,
            ),
            FormFields<int>(
              label: l.get('ffAge'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.green,
              onChanged: (value) => setState(() => _intNonNullRequired = value),
              currrentValue: _intNonNullRequired,
            ),
            buildResultDisplay(l.get('ffAge'), _intNonNullRequired),
            const SizedBox(height: 24),

            // PATTERN 2: Non-Nullable + isRequired: false
            buildFieldTitle(l.get('valIntPattern2'), Colors.orange.shade600),
            buildDescriptionBox(
              l.get('valIntDesc2'),
              Colors.orange,
            ),
            FormFields<int>(
              label: l.get('valPhoneExtension'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.orange,
              onChanged: (value) => setState(() => _intNonNullOptional = value),
              currrentValue: _intNonNullOptional,
            ),
            buildResultDisplay(l.get('valPhoneExtension'), _intNonNullOptional,
                isOptional: true),
            const SizedBox(height: 24),

            // PATTERN 3: Nullable + isRequired: true
            buildFieldTitle(l.get('valIntPattern3'), Colors.red.shade600),
            buildDescriptionBox(
              l.get('valIntDesc3'),
              Colors.red,
            ),
            FormFields<int?>(
              label: l.get('ffQuantity'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.red,
              onChanged: (value) => setState(() => _intNullRequired = value),
              currrentValue: _intNullRequired,
            ),
            buildResultDisplay(l.get('ffQuantity'), _intNullRequired),
            const SizedBox(height: 24),

            // PATTERN 4: Nullable + isRequired: false
            buildFieldTitle(l.get('valIntPattern4'), Colors.purple.shade600),
            buildDescriptionBox(
              l.get('valIntDesc4'),
              Colors.purple,
            ),
            FormFields<int?>(
              label: l.get('valEmployeeId'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.purple,
              onChanged: (value) => setState(() => _intNullOptional = value),
              currrentValue: _intNullOptional,
            ),
            buildResultDisplay(l.get('valEmployeeId'), _intNullOptional,
                isOptional: true),
            const SizedBox(height: 32),

            // ===== DOUBLE VALIDATION PATTERNS =====
            buildSectionTitle(l.get('valDoublePatterns'),
                Colors.indigo.shade700, Colors.indigo.shade400),

            // PATTERN 1: Non-Nullable + isRequired: true
            buildFieldTitle(l.get('valDoublePattern1'), Colors.green.shade600),
            buildDescriptionBox(
              l.get('valDoubleDesc1'),
              Colors.green,
            ),
            FormFields<double>(
              label: l.get('ffProductPrice'),
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
            buildResultDisplay(l.get('ffProductPrice'), _doubleNonNullRequired),
            const SizedBox(height: 24),

            // PATTERN 2: Non-Nullable + isRequired: false
            buildFieldTitle(l.get('valDoublePattern2'), Colors.orange.shade600),
            buildDescriptionBox(
              l.get('valDoubleDesc2'),
              Colors.orange,
            ),
            FormFields<double>(
              label: l.get('valShippingCost'),
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
            buildResultDisplay(l.get('valShippingCost'), _doubleNonNullOptional,
                isOptional: true),
            const SizedBox(height: 24),

            // PATTERN 3: Nullable + isRequired: true
            buildFieldTitle(l.get('valDoublePattern3'), Colors.red.shade600),
            buildDescriptionBox(
              l.get('valDoubleDesc3'),
              Colors.red,
            ),
            FormFields<double?>(
              label: l.get('valDiscountRate'),
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
            buildResultDisplay(l.get('valDiscountRate'), _doubleNullRequired),
            const SizedBox(height: 24),

            // PATTERN 4: Nullable + isRequired: false
            buildFieldTitle(l.get('valDoublePattern4'), Colors.purple.shade600),
            buildDescriptionBox(
              l.get('valDoubleDesc4'),
              Colors.purple,
            ),
            FormFields<double?>(
              label: l.get('valCommissionAmount'),
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
            buildResultDisplay(
                l.get('valCommissionAmount'), _doubleNullOptional,
                isOptional: true),
            const SizedBox(height: 32),

            // ===== CUSTOM VALIDATION =====
            buildSectionTitle(l.get('valCustomValidationSection'),
                Colors.teal.shade700, Colors.teal.shade400),

            buildFieldTitle(
                l.get('valCustomValidation1Title'), Colors.teal.shade600),
            buildDescriptionBox(
              l.get('valCustomValidation1Desc'),
              Colors.teal,
            ),
            FormFields<String>(
              label: l.get('valUsername'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.teal,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.get('valUsernameRequired');
                }
                if (value.length < 3) {
                  return l.get('valUsernameMin');
                }
                if (value.length > 20) {
                  return l.get('valUsernameMax');
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return l.get('valUsernameChars');
                }
                return null;
              },
              onChanged: (value) => setState(() => _usernameCustom = value),
              currrentValue: _usernameCustom,
            ),
            buildResultDisplay(l.get('valUsername'), _usernameCustom),
            const SizedBox(height: 24),

            buildFieldTitle(
                l.get('valCustomValidation2Title'), Colors.cyan.shade600),
            buildDescriptionBox(
              l.get('valCustomValidation2Desc'),
              Colors.cyan,
            ),
            FormFields<String?>(
              label: l.get('valEmail'),
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
                  return l.get('valEmailInvalid');
                }
                // Then check if company domain
                if (!value.endsWith('@company.com')) {
                  return l.get('valEmailDomain');
                }
                return null;
              },
              onChanged: (value) => setState(() => _emailCustom = value),
              currrentValue: _emailCustom,
            ),
            buildResultDisplay(l.get('valEmail'), _emailCustom,
                isOptional: true),
            const SizedBox(height: 24),

            buildFieldTitle(
                l.get('valCustomValidation3Title'), Colors.indigo.shade600),
            buildDescriptionBox(
              l.get('valCustomValidation3Desc'),
              Colors.indigo,
            ),
            FormFields<int>(
              label: l.get('valAge'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.indigo,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.get('valAgeRequired');
                }
                final age = int.tryParse(value);
                if (age == null) {
                  return l.get('valAgeInvalid');
                }
                if (age < 18) {
                  return l.get('valAgeMin');
                }
                if (age > 65) {
                  return l.get('valAgeMax');
                }
                return null;
              },
              onChanged: (value) => setState(() => _ageCustom = value),
              currrentValue: _ageCustom,
            ),
            buildResultDisplay(l.get('valAge'), _ageCustom),
            const SizedBox(height: 32),

            // ===== VALIDATION RULES SUMMARY =====
            buildSectionTitle(l.get('valRulesSummaryTitle'),
                Colors.grey.shade700, Colors.grey.shade400),
            buildRuleBox(
              l.get('valRule1Title'),
              l.get('valRule1Desc'),
              Colors.green,
            ),
            buildRuleBox(
              l.get('valRule2Title'),
              l.get('valRule2Desc'),
              Colors.orange,
            ),
            buildRuleBox(
              l.get('valRule3Title'),
              l.get('valRule3Desc'),
              Colors.red,
            ),
            buildRuleBox(
              l.get('valRule4Title'),
              l.get('valRule4Desc'),
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
                child: Text(
                  l.get('valValidateSubmitButton'),
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
            Text(l.get('valFormValidated')),
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
    final l = FormFieldsLocalizations.of(context);
    final displayValue = value ?? l.get('notSet');
    final optionalLabel = l.get('optionalLabel');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $displayValue${isOptional ? ' $optionalLabel' : ''}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
