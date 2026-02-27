import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:logger/logger.dart';
import '../widgets/result_display_widget.dart';
import '../widgets/language_indicator.dart';

final logger = Logger();

class FormFieldsExamplesPage extends StatefulWidget {
  const FormFieldsExamplesPage({Key? key}) : super(key: key);

  @override
  State<FormFieldsExamplesPage> createState() => _FormFieldsExamplesPageState();
}

class _FormFieldsExamplesPageState extends State<FormFieldsExamplesPage> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode1 = FocusNode();
  final _focusNode2 = FocusNode();

  // STRING - All variations
  String _string1 = '';
  String? _string2;
  String _stringCustom = '';
  String _email = '';
  String _phone = '';
  String _phoneWithCountryCode = '';
  String _phoneFormatted = '';
  String _password = '';

  // INT - All variations
  int _int1 = 0;
  int? _int2;

  // DOUBLE - All variations
  double _double1 = 0.0;
  double? _double2;

  // DATETIME - All variations
  DateTime _date1 = DateTime.now();
  DateTime? _date2;

  // TIMEOFDAY - All variations
  TimeOfDay _time1 = TimeOfDay.now();
  TimeOfDay? _time2;

  // DATETIMERANGE - All variations
  DateTimeRange _range1 =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  DateTimeRange? _range2;

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Language indicator showing current locale
            const LanguageIndicator(),

            // ========== STRING TYPE ==========
            buildSectionTitle(l.get('ffStringTypes'), Colors.blue.shade700,
                Colors.blue.shade400),

            // Non-Nullable String - Basic
            buildFieldTitle(l.get('ffStringBasic'), Colors.blue.shade600),
            FormFields<String>(
              label: l.get('ffFullName'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              onChanged: (value) => setState(() => _string1 = value),
              currrentValue: _string1,
            ),
            buildResultDisplay(context, l.get('ffFullName'), _string1),

            // Nullable String - Optional
            buildFieldTitle(l.get('ffStringOptional'), Colors.blue.shade600),
            FormFields<String?>(
              label: l.get('ffMiddleName'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              onChanged: (value) => setState(() => _string2 = value),
              currrentValue: _string2,
            ),
            buildResultDisplay(context, l.get('ffMiddleName'), _string2),

            // String with All Custom Parameters
            buildFieldTitle(
                l.get('ffStringCustomParams'), Colors.blue.shade600),
            FormFields<String>(
              label: l.get('ffDescription'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              multiLine: 4,
              radius: 15,
              borderType: BorderType.outlineInputBorder,
              borderColor: Colors.green,
              errorBorderColor: Colors.red,
              enterText: l.get('enterPrefix'),
              labelTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              prefixIcon: const Icon(Icons.description, color: Colors.green),
              validator: (value) {
                if (value == null || value.isEmpty) return l.get('ffRequired');
                if (value.length < 10) return l.get('ffMinChars');
                return null;
              },
              onChanged: (value) => setState(() => _stringCustom = value),
              currrentValue: _stringCustom,
              focusNode: _focusNode1,
              nextFocusNode: _focusNode2,
            ),
            buildResultDisplay(context, l.get('ffDescription'), _stringCustom),

            // Email with Parameters
            buildFieldTitle(
                l.get('ffStringEmailFormType'), Colors.blue.shade600),
            FormFields<String>(
              label: l.get('ffEmail'),
              formType: FormType.email,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.blue,
              prefixIcon: const Icon(Icons.email),
              onChanged: (value) => setState(() => _email = value),
              currrentValue: _email,
            ),
            buildResultDisplay(context, l.get('ffEmail'), _email),

            // Phone with Parameters
            buildFieldTitle(
                l.get('ffStringPhoneFormType'), Colors.blue.shade600),
            FormFields<String>(
              label: l.get('ffPhone'),
              formType: FormType.phone,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.orange,
              onChanged: (value) => setState(() => _phone = value),
              currrentValue: _phone,
            ),
            buildResultDisplay(context, l.get('ffPhone'), _phone),

            // Phone with Country Code Selection
            buildFieldTitle(
                l.get('ffStringPhoneCountry'), Colors.blue.shade600),
            FormFields<String>(
              label: l.get('ffPhoneCountryLabel'),
              formType: FormType.phone,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.teal,
              onChanged: (value) =>
                  setState(() => _phoneWithCountryCode = value),
              currrentValue: _phoneWithCountryCode,
            ),
            buildResultDisplay(
                context, l.get('ffPhoneCountryCode'), _phoneWithCountryCode),

            // Phone with Country Code & Formatting Display
            buildFieldTitle(
                l.get('ffStringPhoneFormatted'), Colors.blue.shade600),
            FormFields<String>(
              label: l.get('ffPhoneFormattedLabel'),
              formType: FormType.phone,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.indigo,
              formatPhone: true,
              onChanged: (value) => setState(() => _phoneFormatted = value),
              currrentValue: _phoneFormatted,
            ),
            buildResultDisplay(
                context, l.get('ffPhoneFormatted'), _phoneFormatted),

            // Password with All Parameters
            buildFieldTitle(l.get('ffStringPassword'), Colors.blue.shade600),
            FormFields<String>(
              label: l.get('ffPassword'),
              formType: FormType.password,
              labelPosition: LabelPosition.top,
              isRequired: true,
              minLengthPassword: 8,
              minLengthPasswordErrorText: l.get('ffPasswordMin'),
              borderColor: Colors.purple,
              customPasswordValidator: (value) {
                if (value == null || value.isEmpty) {
                  return l.get('passwordRequired');
                }
                if (value.length < 8) {
                  return l.get('passwordTooShort');
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return l.get('passwordNeedsUppercase');
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return l.get('passwordNeedsNumber');
                }
                return null;
              },
              onChanged: (value) => setState(() => _password = value),
              currrentValue: _password,
              focusNode: _focusNode2,
            ),
            buildResultDisplay(context, l.get('ffPassword'), _password),

            // ========== INTEGER TYPE ==========
            buildSectionTitle(l.get('ffIntTypes'), Colors.blue.shade700,
                Colors.blue.shade400),

            // Non-Nullable Int - Basic
            buildFieldTitle(l.get('ffIntBasic'), Colors.blue.shade600),
            FormFields<int>(
              label: l.get('ffAge'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              stripSeparators: false,
              isRequired: true,
              onChanged: (value) => setState(() => _int1 = value),
              currrentValue: _int1,
            ),
            buildResultDisplay(context, l.get('ffAge'), _int1),
            // Nullable Int - With All Parameters
            buildFieldTitle(l.get('ffIntOptional'), Colors.blue.shade600),
            FormFields<int?>(
              label: l.get('ffQuantity'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              stripSeparators: true,
              isRequired: false,
              borderColor: Colors.teal,
              invalidIntegerText: l.get('enterValidInteger'),
              prefixIcon: const Icon(Icons.inventory, color: Colors.teal),
              labelTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
              onChanged: (value) => setState(() => _int2 = value),
              currrentValue: _int2,
            ),
            buildResultDisplay(context, l.get('ffQuantity'), _int2),

            buildSectionTitle(l.get('ffDoubleTypes'), Colors.blue.shade700,
                Colors.blue.shade400),

            // Non-Nullable Double - With Separators
            buildFieldTitle(l.get('ffDoubleBasic'), Colors.blue.shade600),
            FormFields<double>(
              label: l.get('ffProductPrice'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              stripSeparators: true,
              isRequired: true,
              borderColor: Colors.green,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('\$',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              onChanged: (value) => setState(() => _double1 = value),
              currrentValue: _double1,
            ),
            buildResultDisplay(l.get('ffProductPrice'), _double1),

            // Nullable Double - All Parameters
            buildFieldTitle(l.get('ffDoubleOptional'), Colors.blue.shade600),
            FormFields<double?>(
              label: l.get('ffDiscountPercentage'),
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              borderColor: Colors.orange,
              radius: 10,
              invalidNumberText: l.get('enterValidNumber'),
              suffix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('%',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              labelTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              onChanged: (value) => setState(() => _double2 = value),
              currrentValue: _double2,
            ),
            buildResultDisplay(l.get('ffDiscountPercentage'), _double2),

            // ========== DATETIME TYPE ==========
            buildSectionTitle(l.get('ffDateTimeTypes'), Colors.blue.shade700,
                Colors.blue.shade400),

            // Non-Nullable DateTime - Basic
            buildFieldTitle(l.get('ffDateTimeBasic'), Colors.blue.shade600),
            FormFields<DateTime>(
              label: l.get('ffBirthDate'),
              formType: FormType.dateTime,
              labelPosition: LabelPosition.top,
              isRequired: true,
              onChanged: (value) => setState(() => _date1 = value),
              currrentValue: _date1,
            ),
            buildResultDisplay(l.get('ffBirthDate'), _date1),

            // Nullable DateTime - All Parameters
            buildFieldTitle(l.get('ffDateTimeOptional'), Colors.blue.shade600),
            FormFields<DateTime?>(
              label: l.get('ffEventDate'),
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
              onChanged: (value) => setState(() => _date2 = value),
              currrentValue: _date2,
            ),
            buildResultDisplay(l.get('ffEventDate'), _date2),

            // ========== TIMEOFDAY TYPE ==========
            buildSectionTitle(l.get('ffTimeOfDayTypes'), Colors.blue.shade700,
                Colors.blue.shade400),

            // Non-Nullable TimeOfDay - Basic
            buildFieldTitle(l.get('ffTimeOfDayBasic'), Colors.blue.shade600),
            FormFields<TimeOfDay>(
              label: l.get('ffMeetingTime'),
              formType: FormType.timeOfDay,
              labelPosition: LabelPosition.top,
              isRequired: true,
              onChanged: (value) => setState(() => _time1 = value),
              currrentValue: _time1,
            ),
            buildResultDisplay(l.get('ffMeetingTime'), _time1),

            // Nullable TimeOfDay - All Parameters
            buildFieldTitle(l.get('ffTimeOfDayOptional'), Colors.blue.shade600),
            FormFields<TimeOfDay?>(
              label: l.get('ffWakeupTime'),
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
              onChanged: (value) => setState(() => _time2 = value),
              currrentValue: _time2,
            ),
            buildResultDisplay(l.get('ffWakeupTime'), _time2),

            // ========== DATETIMERANGE TYPE ==========
            buildSectionTitle(l.get('ffDateRangeTypes'), Colors.blue.shade700,
                Colors.blue.shade400),

            // Non-Nullable DateTimeRange - Basic
            buildFieldTitle(l.get('ffDateRangeBasic'), Colors.blue.shade600),
            FormFields<DateTimeRange>(
              label: l.get('ffProjectDuration'),
              formType: FormType.dateTimeRange,
              labelPosition: LabelPosition.top,
              useDatePickerForRange: true,
              onChanged: (value) => setState(() => _range1 = value),
              currrentValue: _range1,
            ),
            buildResultDisplay(l.get('ffProjectDuration'), _range1),

            // Nullable DateTimeRange - All Parameters
            buildFieldTitle(l.get('ffDateRangeOptional'), Colors.blue.shade600),
            FormFields<DateTimeRange?>(
              label: l.get('ffVacationPeriod'),
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
              onChanged: (value) => setState(() => _range2 = value),
              currrentValue: _range2,
            ),
            buildResultDisplay(l.get('ffVacationPeriod'), _range2),

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

                  final isValid = _formKey.currentState!.validate();
                  logger.i('Form validation result: $isValid');

                  if (!isValid) {
                    logger.e('❌ Form validation FAILED - showing errors');
                    return;
                  } else {
                    logger.i('✓ Form validation PASSED - submitting');
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
                  l.get('submitFormButton'),
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

  void _showFormData() {
    final l = FormFieldsLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(l.get('ffFormValidated')),
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
