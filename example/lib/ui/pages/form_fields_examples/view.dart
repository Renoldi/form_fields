import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart' as loc;
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'package:form_fields_example/ui/widgets/language_indicator.dart';
import 'presenter.dart';
import 'view_model.dart';

final logger = Logger();

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FormFieldsExamplesViewModel(),
      child: Consumer<FormFieldsExamplesViewModel>(
        builder: (context, viewModel, _) {
          final l = loc.Localizations.of(context);
          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Language indicator showing current locale
                  const LanguageIndicator(),

                  // ========== STRING TYPE ==========
                  buildSectionTitle(context.tr('ffStringTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable String - Basic
                  buildFieldTitle(
                      context.tr('ffStringBasic'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffFullName'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    onChanged: viewModel.updateString1,
                    currrentValue: viewModel.string1,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffFullName'), viewModel.string1),

                  // Nullable String - Optional
                  buildFieldTitle(
                      context.tr('ffStringOptional'), Colors.blue.shade600),
                  FormFields<String?>(
                    label: context.tr('ffMiddleName'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    onChanged: viewModel.updateString2,
                    currrentValue: viewModel.string2,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffMiddleName'), viewModel.string2),

                  // String with All Custom Parameters
                  buildFieldTitle(
                      context.tr('ffStringCustomParams'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffDescription'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    multiLine: 4,
                    radius: 15,
                    borderType: BorderType.outlineInputBorder,
                    borderColor: Colors.green,
                    errorBorderColor: Colors.red,
                    enterText: context.tr('enterPrefix'),
                    labelTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    prefixIcon:
                        const Icon(Icons.description, color: Colors.green),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('ffRequired');
                      }
                      if (value.length < 10) {
                        return context.tr('ffMinChars');
                      }
                      return null;
                    },
                    onChanged: viewModel.updateStringCustom,
                    currrentValue: viewModel.stringCustom,
                    focusNode: viewModel.focusNode1,
                    nextFocusNode: viewModel.focusNode2,
                  ),
                  buildResultDisplay(context, context.tr('ffDescription'),
                      viewModel.stringCustom),

                  // Email with Parameters
                  buildFieldTitle(context.tr('ffStringEmailFormType'),
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffEmail'),
                    formType: FormType.email,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.blue,
                    prefixIcon: const Icon(Icons.email),
                    onChanged: viewModel.updateEmail,
                    currrentValue: viewModel.email,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffEmail'), viewModel.email),

                  // Phone with Parameters
                  buildFieldTitle(context.tr('ffStringPhoneFormType'),
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPhone'),
                    formType: FormType.phone,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.orange,
                    onChanged: viewModel.updatePhone,
                    currrentValue: viewModel.phone,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffPhone'), viewModel.phone),

                  // Phone with Country Code Selection
                  buildFieldTitle(
                      context.tr('ffStringPhoneCountry'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPhoneCountryLabel'),
                    formType: FormType.phone,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.teal,
                    onChanged: viewModel.updatePhoneWithCountryCode,
                    currrentValue: viewModel.phoneWithCountryCode,
                  ),
                  buildResultDisplay(context, context.tr('ffPhoneCountryCode'),
                      viewModel.phoneWithCountryCode),

                  // Phone with Country Code & Formatting Display
                  buildFieldTitle(context.tr('ffStringPhoneFormatted'),
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPhoneFormattedLabel'),
                    formType: FormType.phone,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.indigo,
                    formatPhone: true,
                    onChanged: viewModel.updatePhoneFormatted,
                    currrentValue: viewModel.phoneFormatted,
                  ),
                  buildResultDisplay(context, context.tr('ffPhoneFormatted'),
                      viewModel.phoneFormatted),

                  // Password with All Parameters
                  buildFieldTitle(
                      context.tr('ffStringPassword'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPassword'),
                    formType: FormType.password,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    minLengthPassword: 8,
                    minLengthPasswordErrorText: context.tr('ffPasswordMin'),
                    borderColor: Colors.purple,
                    customPasswordValidator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('passwordRequired');
                      }
                      if (value.length < 8) {
                        return context.tr('passwordTooShort');
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return context.tr('passwordNeedsUppercase');
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return context.tr('passwordNeedsNumber');
                      }
                      return null;
                    },
                    onChanged: viewModel.updatePassword,
                    currrentValue: viewModel.password,
                    focusNode: viewModel.focusNode2,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffPassword'), viewModel.password),

                  // ========== INTEGER TYPE ==========
                  buildSectionTitle(context.tr('ffIntTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable Int - Basic
                  buildFieldTitle(
                      context.tr('ffIntBasic'), Colors.blue.shade600),
                  FormFields<int>(
                    label: context.tr('ffAge'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    stripSeparators: false,
                    isRequired: true,
                    onChanged: viewModel.updateInt1,
                    currrentValue: viewModel.int1,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffAge'), viewModel.int1),
                  // Nullable Int - With All Parameters
                  buildFieldTitle(
                      context.tr('ffIntOptional'), Colors.blue.shade600),
                  FormFields<int?>(
                    label: context.tr('ffQuantity'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    stripSeparators: true,
                    isRequired: false,
                    borderColor: Colors.teal,
                    invalidIntegerText: context.tr('enterValidInteger'),
                    prefixIcon: const Icon(Icons.inventory, color: Colors.teal),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                    onChanged: viewModel.updateInt2,
                    currrentValue: viewModel.int2,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffQuantity'), viewModel.int2),

                  buildSectionTitle(context.tr('ffDoubleTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable Double - With Separators
                  buildFieldTitle(
                      context.tr('ffDoubleBasic'), Colors.blue.shade600),
                  FormFields<double>(
                    label: context.tr('ffProductPrice'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    stripSeparators: true,
                    isRequired: true,
                    borderColor: Colors.green,
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('\$',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    onChanged: viewModel.updateDouble1,
                    currrentValue: viewModel.double1,
                  ),
                  buildResultDisplay(
                      context.tr('ffProductPrice'), viewModel.double1),

                  // Nullable Double - All Parameters
                  buildFieldTitle(
                      context.tr('ffDoubleOptional'), Colors.blue.shade600),
                  FormFields<double?>(
                    label: context.tr('ffDiscountPercentage'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.orange,
                    radius: 10,
                    invalidNumberText: context.tr('enterValidNumber'),
                    suffix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('%',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: viewModel.updateDouble2,
                    currrentValue: viewModel.double2,
                  ),
                  buildResultDisplay(
                      context.tr('ffDiscountPercentage'), viewModel.double2),

                  // ========== DATETIME TYPE ==========
                  buildSectionTitle(context.tr('ffDateTimeTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable DateTime - Basic
                  buildFieldTitle(
                      context.tr('ffDateTimeBasic'), Colors.blue.shade600),
                  FormFields<DateTime>(
                    label: context.tr('ffBirthDate'),
                    formType: FormType.dateTime,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    onChanged: viewModel.updateDate1,
                    currrentValue: viewModel.date1,
                  ),
                  buildResultDisplay(
                      context.tr('ffBirthDate'), viewModel.date1),

                  // Nullable DateTime - All Parameters
                  buildFieldTitle(
                      context.tr('ffDateTimeOptional'), Colors.blue.shade600),
                  FormFields<DateTime?>(
                    label: context.tr('ffEventDate'),
                    formType: FormType.dateTime,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.indigo,
                    radius: 12,
                    customFormat: 'dd MMMM yyyy',
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    prefixIcon: const Icon(Icons.calendar_today),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                    onChanged: viewModel.updateDate2,
                    currrentValue: viewModel.date2,
                  ),
                  buildResultDisplay(
                      context.tr('ffEventDate'), viewModel.date2),

                  // ========== TIMEOFDAY TYPE ==========
                  buildSectionTitle(context.tr('ffTimeOfDayTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable TimeOfDay - Basic
                  buildFieldTitle(
                      context.tr('ffTimeOfDayBasic'), Colors.blue.shade600),
                  FormFields<TimeOfDay>(
                    label: context.tr('ffMeetingTime'),
                    formType: FormType.timeOfDay,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    onChanged: viewModel.updateTime1,
                    currrentValue: viewModel.time1,
                  ),
                  buildResultDisplay(
                      context.tr('ffMeetingTime'), viewModel.time1),

                  // Nullable TimeOfDay - All Parameters
                  buildFieldTitle(
                      context.tr('ffTimeOfDayOptional'), Colors.blue.shade600),
                  FormFields<TimeOfDay?>(
                    label: context.tr('ffWakeupTime'),
                    formType: FormType.timeOfDay,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.deepPurple,
                    radius: 12,
                    prefixIcon: const Icon(Icons.access_time),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                    onChanged: viewModel.updateTime2,
                    currrentValue: viewModel.time2,
                  ),
                  buildResultDisplay(
                      context.tr('ffWakeupTime'), viewModel.time2),

                  // ========== DATETIMERANGE TYPE ==========
                  buildSectionTitle(context.tr('ffDateRangeTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable DateTimeRange - Basic
                  buildFieldTitle(
                      context.tr('ffDateRangeBasic'), Colors.blue.shade600),
                  FormFields<DateTimeRange>(
                    label: context.tr('ffProjectDuration'),
                    formType: FormType.dateTimeRange,
                    labelPosition: LabelPosition.top,
                    useDatePickerForRange: true,
                    onChanged: viewModel.updateRange1,
                    currrentValue: viewModel.range1,
                  ),
                  buildResultDisplay(
                      context.tr('ffProjectDuration'), viewModel.range1),

                  // Nullable DateTimeRange - All Parameters
                  buildFieldTitle(
                      context.tr('ffDateRangeOptional'), Colors.blue.shade600),
                  FormFields<DateTimeRange?>(
                    label: context.tr('ffVacationPeriod'),
                    formType: FormType.dateTimeRange,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.cyan,
                    radius: 12,
                    customFormat: 'dd/MM/yyyy',
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2026),
                    prefixIcon: const Icon(Icons.date_range),
                    useDatePickerForRange: true,
                    labelTextStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.cyan,
                    ),
                    onChanged: viewModel.updateRange2,
                    currrentValue: viewModel.range2,
                  ),
                  buildResultDisplay(
                      context.tr('ffVacationPeriod'), viewModel.range2),

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
                        context.tr('submitFormButton'),
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
            Text(context.tr('ffFormValidated')),
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
