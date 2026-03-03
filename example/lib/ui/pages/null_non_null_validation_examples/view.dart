import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart' as loc;
import 'package:form_fields_example/ui/widgets/language_indicator.dart';
import 'presenter.dart';
import 'view_model.dart';

final logger = Logger();

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NullNonNullValidationExamplesViewModel(),
      child: Consumer<NullNonNullValidationExamplesViewModel>(
        builder: (context, viewModel, _) {
          final l = loc.Localizations.of(context);
          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Language indicator
                  const LanguageIndicator(),
                  const SizedBox(height: 16),

                  // ===== STRING VALIDATION PATTERNS =====
                  buildSectionTitle(
                    context.tr('valStringNullable'),
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                  ),
                  // PATTERN 1: Non-Nullable + isRequired: true
                  buildFieldTitle(
                      context.tr('valPattern1'), Colors.green.shade600),
                  buildDescriptionBox(
                    context.tr('valStringDesc1'),
                    Colors.green,
                  ),
                  FormFields<String>(
                    label: context.tr('ffFullName'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.green,
                    onChanged: viewModel.setStringNonNullRequired,
                    currrentValue: viewModel.stringNonNullRequired,
                  ),
                  buildResultDisplay(context.tr('ffFullName'),
                      viewModel.stringNonNullRequired),
                  const SizedBox(height: 24),

                  // PATTERN 2: Non-Nullable + isRequired: false
                  buildFieldTitle(
                      context.tr('valPattern2'), Colors.orange.shade600),
                  buildDescriptionBox(
                    context.tr('valStringDesc2'),
                    Colors.orange,
                  ),
                  FormFields<String>(
                    label: context.tr('ffMiddleName'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.orange,
                    onChanged: viewModel.setStringNonNullOptional,
                    currrentValue: viewModel.stringNonNullOptional,
                  ),
                  buildResultDisplay(context.tr('ffMiddleName'),
                      viewModel.stringNonNullOptional,
                      isOptional: true),
                  const SizedBox(height: 24),

                  // PATTERN 3: Nullable + isRequired: true
                  buildFieldTitle(
                      context.tr('valPattern3'), Colors.red.shade600),
                  buildDescriptionBox(
                    context.tr('valStringDesc3'),
                    Colors.red,
                  ),
                  FormFields<String?>(
                    label: context.tr('ffLastName'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.red,
                    onChanged: viewModel.setStringNullRequired,
                    currrentValue: viewModel.stringNullRequired,
                  ),
                  buildResultDisplay(
                      context.tr('ffLastName'), viewModel.stringNullRequired),
                  const SizedBox(height: 24),

                  // PATTERN 4: Nullable + isRequired: false
                  buildFieldTitle(
                      context.tr('valPattern4'), Colors.purple.shade600),
                  buildDescriptionBox(
                    context.tr('valStringDesc4'),
                    Colors.purple,
                  ),
                  FormFields<String?>(
                    label: context.tr('valNickname'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.purple,
                    onChanged: viewModel.setStringNullOptional,
                    currrentValue: viewModel.stringNullOptional,
                  ),
                  buildResultDisplay(
                      context.tr('valNickname'), viewModel.stringNullOptional,
                      isOptional: true),
                  const SizedBox(height: 32),

                  // ===== INT VALIDATION PATTERNS =====
                  buildSectionTitle(context.tr('valIntPatterns'),
                      Colors.teal.shade700, Colors.teal.shade400),

                  // PATTERN 1: Non-Nullable + isRequired: true
                  buildFieldTitle(
                      context.tr('valIntPattern1'), Colors.green.shade600),
                  buildDescriptionBox(
                    context.tr('valIntDesc1'),
                    Colors.green,
                  ),
                  FormFields<int>(
                    label: context.tr('ffAge'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.green,
                    onChanged: viewModel.setIntNonNullRequired,
                    currrentValue: viewModel.intNonNullRequired,
                  ),
                  buildResultDisplay(
                      context.tr('ffAge'), viewModel.intNonNullRequired),
                  const SizedBox(height: 24),

                  // PATTERN 2: Non-Nullable + isRequired: false
                  buildFieldTitle(
                      context.tr('valIntPattern2'), Colors.orange.shade600),
                  buildDescriptionBox(
                    context.tr('valIntDesc2'),
                    Colors.orange,
                  ),
                  FormFields<int>(
                    label: context.tr('valPhoneExtension'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.orange,
                    onChanged: viewModel.setIntNonNullOptional,
                    currrentValue: viewModel.intNonNullOptional,
                  ),
                  buildResultDisplay(context.tr('valPhoneExtension'),
                      viewModel.intNonNullOptional,
                      isOptional: true),
                  const SizedBox(height: 24),

                  // PATTERN 3: Nullable + isRequired: true
                  buildFieldTitle(
                      context.tr('valIntPattern3'), Colors.red.shade600),
                  buildDescriptionBox(
                    context.tr('valIntDesc3'),
                    Colors.red,
                  ),
                  FormFields<int?>(
                    label: context.tr('ffQuantity'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.red,
                    onChanged: viewModel.setIntNullRequired,
                    currrentValue: viewModel.intNullRequired,
                  ),
                  buildResultDisplay(
                      context.tr('ffQuantity'), viewModel.intNullRequired),
                  const SizedBox(height: 24),

                  // PATTERN 4: Nullable + isRequired: false
                  buildFieldTitle(
                      context.tr('valIntPattern4'), Colors.purple.shade600),
                  buildDescriptionBox(
                    context.tr('valIntDesc4'),
                    Colors.purple,
                  ),
                  FormFields<int?>(
                    label: context.tr('valEmployeeId'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.purple,
                    onChanged: viewModel.setIntNullOptional,
                    currrentValue: viewModel.intNullOptional,
                  ),
                  buildResultDisplay(
                      context.tr('valEmployeeId'), viewModel.intNullOptional,
                      isOptional: true),
                  const SizedBox(height: 32),

                  // ===== DOUBLE VALIDATION PATTERNS =====
                  buildSectionTitle(context.tr('valDoublePatterns'),
                      Colors.indigo.shade700, Colors.indigo.shade400),

                  // PATTERN 1: Non-Nullable + isRequired: true
                  buildFieldTitle(
                      context.tr('valDoublePattern1'), Colors.green.shade600),
                  buildDescriptionBox(
                    context.tr('valDoubleDesc1'),
                    Colors.green,
                  ),
                  FormFields<double>(
                    label: context.tr('ffProductPrice'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.green,
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('\$', style: TextStyle(fontSize: 16)),
                    ),
                    onChanged: viewModel.setDoubleNonNullRequired,
                    currrentValue: viewModel.doubleNonNullRequired,
                  ),
                  buildResultDisplay(context.tr('ffProductPrice'),
                      viewModel.doubleNonNullRequired),
                  const SizedBox(height: 24),

                  // PATTERN 2: Non-Nullable + isRequired: false
                  buildFieldTitle(
                      context.tr('valDoublePattern2'), Colors.orange.shade600),
                  buildDescriptionBox(
                    context.tr('valDoubleDesc2'),
                    Colors.orange,
                  ),
                  FormFields<double>(
                    label: context.tr('valShippingCost'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.orange,
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('\$', style: TextStyle(fontSize: 16)),
                    ),
                    onChanged: viewModel.setDoubleNonNullOptional,
                    currrentValue: viewModel.doubleNonNullOptional,
                  ),
                  buildResultDisplay(context.tr('valShippingCost'),
                      viewModel.doubleNonNullOptional,
                      isOptional: true),
                  const SizedBox(height: 24),

                  // PATTERN 3: Nullable + isRequired: true
                  buildFieldTitle(
                      context.tr('valDoublePattern3'), Colors.red.shade600),
                  buildDescriptionBox(
                    context.tr('valDoubleDesc3'),
                    Colors.red,
                  ),
                  FormFields<double?>(
                    label: context.tr('valDiscountRate'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.red,
                    suffix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('%', style: TextStyle(fontSize: 16)),
                    ),
                    onChanged: viewModel.setDoubleNullRequired,
                    currrentValue: viewModel.doubleNullRequired,
                  ),
                  buildResultDisplay(context.tr('valDiscountRate'),
                      viewModel.doubleNullRequired),
                  const SizedBox(height: 24),

                  // PATTERN 4: Nullable + isRequired: false
                  buildFieldTitle(
                      context.tr('valDoublePattern4'), Colors.purple.shade600),
                  buildDescriptionBox(
                    context.tr('valDoubleDesc4'),
                    Colors.purple,
                  ),
                  FormFields<double?>(
                    label: context.tr('valCommissionAmount'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.purple,
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('\$', style: TextStyle(fontSize: 16)),
                    ),
                    onChanged: viewModel.setDoubleNullOptional,
                    currrentValue: viewModel.doubleNullOptional,
                  ),
                  buildResultDisplay(context.tr('valCommissionAmount'),
                      viewModel.doubleNullOptional,
                      isOptional: true),
                  const SizedBox(height: 32),

                  // ===== CUSTOM VALIDATION =====
                  buildSectionTitle(context.tr('valCustomValidationSection'),
                      Colors.teal.shade700, Colors.teal.shade400),

                  buildFieldTitle(context.tr('valCustomValidation1Title'),
                      Colors.teal.shade600),
                  buildDescriptionBox(
                    context.tr('valCustomValidation1Desc'),
                    Colors.teal,
                  ),
                  FormFields<String>(
                    label: context.tr('valUsername'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.teal,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('valUsernameRequired');
                      }
                      if (value.length < 3) {
                        return context.tr('valUsernameMin');
                      }
                      if (value.length > 20) {
                        return context.tr('valUsernameMax');
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return context.tr('valUsernameChars');
                      }
                      return null;
                    },
                    onChanged: viewModel.setUsernameCustom,
                    currrentValue: viewModel.usernameCustom,
                  ),
                  buildResultDisplay(
                      context.tr('valUsername'), viewModel.usernameCustom),
                  const SizedBox(height: 24),

                  buildFieldTitle(context.tr('valCustomValidation2Title'),
                      Colors.cyan.shade600),
                  buildDescriptionBox(
                    context.tr('valCustomValidation2Desc'),
                    Colors.cyan,
                  ),
                  FormFields<String?>(
                    label: context.tr('valEmail'),
                    formType: FormType.email,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.cyan,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Optional field
                      }
                      // First check if valid email format
                      if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                          .hasMatch(value)) {
                        return context.tr('valEmailInvalid');
                      }
                      // Then check if company domain
                      if (!value.endsWith('@company.com')) {
                        return context.tr('valEmailDomain');
                      }
                      return null;
                    },
                    onChanged: viewModel.setEmailCustom,
                    currrentValue: viewModel.emailCustom,
                  ),
                  buildResultDisplay(
                      context.tr('valEmail'), viewModel.emailCustom,
                      isOptional: true),
                  const SizedBox(height: 24),

                  buildFieldTitle(context.tr('valCustomValidation3Title'),
                      Colors.indigo.shade600),
                  buildDescriptionBox(
                    context.tr('valCustomValidation3Desc'),
                    Colors.indigo,
                  ),
                  FormFields<int>(
                    label: context.tr('valAge'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.indigo,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('valAgeRequired');
                      }
                      final age = int.tryParse(value);
                      if (age == null) {
                        return context.tr('valAgeInvalid');
                      }
                      if (age < 18) {
                        return context.tr('valAgeMin');
                      }
                      if (age > 65) {
                        return context.tr('valAgeMax');
                      }
                      return null;
                    },
                    onChanged: viewModel.setAgeCustom,
                    currrentValue: viewModel.ageCustom,
                  ),
                  buildResultDisplay(context.tr('valAge'), viewModel.ageCustom),
                  const SizedBox(height: 32),

                  // ===== VALIDATION RULES SUMMARY =====
                  buildSectionTitle(context.tr('valRulesSummaryTitle'),
                      Colors.grey.shade700, Colors.grey.shade400),
                  buildRuleBox(
                    context.tr('valRule1Title'),
                    context.tr('valRule1Desc'),
                    Colors.green,
                  ),
                  buildRuleBox(
                    context.tr('valRule2Title'),
                    context.tr('valRule2Desc'),
                    Colors.orange,
                  ),
                  buildRuleBox(
                    context.tr('valRule3Title'),
                    context.tr('valRule3Desc'),
                    Colors.red,
                  ),
                  buildRuleBox(
                    context.tr('valRule4Title'),
                    context.tr('valRule4Desc'),
                    Colors.purple,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        logger.i(
                            '\n╔═══════════════════════════════════════════════════════════════╗');
                        logger.i(
                            '║ FORM SUBMIT BUTTON CLICKED                                      ║');
                        logger.i(
                            '╚═══════════════════════════════════════════════════════════════╝');

                        final isValid =
                            viewModel.formKey.currentState!.validate();
                        logger.i('Form validation result: $isValid');

                        if (!isValid) {
                          logger.e('❌ Form validation FAILED - showing errors');
                          return;
                        } else {
                          logger.i('✓ Form validation PASSED - submitting');
                          _showFormData(context);
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
                        context.tr('valValidateSubmitButton'),
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
        },
      ),
    );
  }

  void _showFormData(BuildContext context) {
    final l = loc.Localizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(context.tr('valFormValidated')),
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
    final l = FormFieldsLocalizations.load(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    final displayValue = value ?? context.tr('notSet');
    final optionalLabel = context.tr('optionalLabel');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $displayValue${isOptional ? ' $optionalLabel' : ''}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
