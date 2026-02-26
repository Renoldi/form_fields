import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import '../widgets/result_display_widget.dart';
import '../widgets/language_indicator.dart';

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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Language indicator showing current locale
            const LanguageIndicator(),

            // ========== STRING TYPE ==========
            buildSectionTitle('STRING TYPE - All Parameters',
                Colors.blue.shade700, Colors.blue.shade400),

            // Non-Nullable String - Basic
            buildFieldTitle('String (Non-Null) - Basic', Colors.blue.shade600),
            FormFields<String>(
              label: 'Full Name',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              onChanged: (value) => setState(() => _string1 = value),
              currrentValue: _string1,
            ),
            buildResultDisplay('Full Name', _string1),

            // Nullable String - Optional
            buildFieldTitle(
                'String (Nullable) - Optional', Colors.blue.shade600),
            FormFields<String?>(
              label: 'Middle Name',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: false,
              onChanged: (value) => setState(() => _string2 = value),
              currrentValue: _string2,
            ),
            buildResultDisplay('Middle Name', _string2, isOptional: true),

            // String with All Custom Parameters
            buildFieldTitle(
                'String - All Custom Parameters', Colors.blue.shade600),
            FormFields<String>(
              label: 'Description',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              isRequired: true,
              multiLine: 4,
              radius: 15,
              borderType: BorderType.outlineInputBorder,
              borderColor: Colors.green,
              errorBorderColor: Colors.red,
              enterText: 'Please enter ',
              labelTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              prefixIcon: const Icon(Icons.description, color: Colors.green),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length < 10) return 'Min 10 characters';
                return null;
              },
              onChanged: (value) => setState(() => _stringCustom = value),
              currrentValue: _stringCustom,
              focusNode: _focusNode1,
              nextFocusNode: _focusNode2,
            ),
            buildResultDisplay('Description', _stringCustom),

            // Email with Parameters
            buildFieldTitle('String - Email FormType', Colors.blue.shade600),
            FormFields<String>(
              label: 'Email Address',
              formType: FormType.email,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.blue,
              prefixIcon: const Icon(Icons.email),
              onChanged: (value) => setState(() => _email = value),
              currrentValue: _email,
            ),
            buildResultDisplay('Email Address', _email),

            // Phone with Parameters
            buildFieldTitle('String - Phone FormType', Colors.blue.shade600),
            FormFields<String>(
              label: 'Phone Number',
              formType: FormType.phone,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.orange,
              onChanged: (value) => setState(() => _phone = value),
              currrentValue: _phone,
            ),
            buildResultDisplay('Phone Number', _phone),

            // Phone with Country Code Selection
            buildFieldTitle(
                'String - Phone with Country Code (dropdown shows +62 ▼, input shows local digits only)',
                Colors.blue.shade600),
            FormFields<String>(
              label: 'Phone Number (with Country Code)',
              formType: FormType.phone,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.teal,
              onChanged: (value) =>
                  setState(() => _phoneWithCountryCode = value),
              currrentValue: _phoneWithCountryCode,
            ),
            buildResultDisplay(
                'Phone with Country Code (result: +62XXXXXXXXXXX)',
                _phoneWithCountryCode),

            // Phone with Country Code & Formatting Display
            buildFieldTitle(
                'String - Phone with Formatted Input (dropdown: +62 ▼, input: 111-1111-1111, result: +628111111111)',
                Colors.blue.shade600),
            FormFields<String>(
              label: 'Phone Number (formatted input)',
              formType: FormType.phone,
              labelPosition: LabelPosition.top,
              isRequired: true,
              borderColor: Colors.indigo,
              formatPhone: true,
              onChanged: (value) => setState(() => _phoneFormatted = value),
              currrentValue: _phoneFormatted,
            ),
            buildResultDisplay(
                'Phone (result always unformatted)', _phoneFormatted),

            // Password with All Parameters
            buildFieldTitle('String - Password with Custom Validation',
                Colors.blue.shade600),
            FormFields<String>(
              label: 'Password',
              formType: FormType.password,
              labelPosition: LabelPosition.top,
              isRequired: true,
              minLengthPassword: 8,
              minLengthPasswordErrorText:
                  'Password must be at least 8 characters long',
              borderColor: Colors.purple,
              customPasswordValidator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be 8+ characters';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Must contain uppercase letter';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Must contain a number';
                }
                return null;
              },
              onChanged: (value) => setState(() => _password = value),
              currrentValue: _password,
              focusNode: _focusNode2,
            ),
            buildResultDisplay('Password', _password),

            // ========== INTEGER TYPE ==========
            buildSectionTitle('INTEGER TYPE - All Parameters',
                Colors.blue.shade700, Colors.blue.shade400),

            // Non-Nullable Int - Basic
            buildFieldTitle('Int (Non-Null) - Basic', Colors.blue.shade600),
            FormFields<int>(
              label: 'Age',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              stripSeparators: false,
              isRequired: true,
              onChanged: (value) => setState(() => _int1 = value),
              currrentValue: _int1,
            ),
            buildResultDisplay('Age', _int1),
            // Nullable Int - With All Parameters
            buildFieldTitle('Int (Nullable) - With Separators & Custom Styling',
                Colors.blue.shade600),
            FormFields<int?>(
              label: 'Stock Quantity',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              stripSeparators: true,
              isRequired: false,
              borderColor: Colors.teal,
              radius: 12,
              invalidIntegerText: 'Please enter valid integer for',
              prefixIcon: const Icon(Icons.inventory, color: Colors.teal),
              labelTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
              onChanged: (value) => setState(() => _int2 = value),
              currrentValue: _int2,
            ),
            buildResultDisplay('Quantity', _int2, isOptional: true),

            // ========== DOUBLE TYPE ==========
            buildSectionTitle('DOUBLE TYPE - All Parameters',
                Colors.blue.shade700, Colors.blue.shade400),

            // Non-Nullable Double - With Separators
            buildFieldTitle(
                'Double (Non-Null) - With Separators', Colors.blue.shade600),
            FormFields<double>(
              label: 'Product Price',
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
            buildResultDisplay('Product Price', _double1),

            // Nullable Double - All Parameters
            buildFieldTitle('Double (Nullable) - All Custom Parameters',
                Colors.blue.shade600),
            FormFields<double?>(
              label: 'Discount Percentage',
              formType: FormType.string,
              labelPosition: LabelPosition.top,
              stripSeparators: false,
              isRequired: false,
              borderColor: Colors.orange,
              radius: 10,
              invalidNumberText: 'Please enter valid decimal for',
              suffix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('%',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              labelTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
              onChanged: (value) => setState(() => _double2 = value),
              currrentValue: _double2,
            ),
            buildResultDisplay('Discount Percentage', _double2,
                isOptional: true),

            // ========== DATETIME TYPE ==========
            buildSectionTitle('DATETIME TYPE - All Parameters',
                Colors.blue.shade700, Colors.blue.shade400),

            // Non-Nullable DateTime - Basic
            buildFieldTitle(
                'DateTime (Non-Null) - Basic', Colors.blue.shade600),
            FormFields<DateTime>(
              label: 'Birth Date',
              formType: FormType.dateTime,
              labelPosition: LabelPosition.top,
              isRequired: true,
              onChanged: (value) => setState(() => _date1 = value),
              currrentValue: _date1,
            ),
            buildResultDisplay('Birth Date', _date1),

            // Nullable DateTime - All Parameters
            buildFieldTitle('DateTime (Nullable) - All Custom Parameters',
                Colors.blue.shade600),
            FormFields<DateTime?>(
              label: 'Event Date',
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
            buildResultDisplay('Event Date', _date2, isOptional: true),

            // ========== TIMEOFDAY TYPE ==========
            buildSectionTitle('TIMEOFDAY TYPE - All Parameters',
                Colors.blue.shade700, Colors.blue.shade400),

            // Non-Nullable TimeOfDay - Basic
            buildFieldTitle(
                'TimeOfDay (Non-Null) - Basic', Colors.blue.shade600),
            FormFields<TimeOfDay>(
              label: 'Meeting Time',
              formType: FormType.timeOfDay,
              labelPosition: LabelPosition.top,
              isRequired: true,
              onChanged: (value) => setState(() => _time1 = value),
              currrentValue: _time1,
            ),
            buildResultDisplay('Meeting Time', _time1),

            // Nullable TimeOfDay - All Parameters
            buildFieldTitle('TimeOfDay (Nullable) - All Custom Parameters',
                Colors.blue.shade600),
            FormFields<TimeOfDay?>(
              label: 'Alarm Time',
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
            buildResultDisplay('Alarm Time', _time2, isOptional: true),

            // ========== DATETIMERANGE TYPE ==========
            buildSectionTitle('DATETIMERANGE TYPE - All Parameters',
                Colors.blue.shade700, Colors.blue.shade400),

            // Non-Nullable DateTimeRange - Basic
            buildFieldTitle(
                'DateTimeRange (Non-Null) - Basic', Colors.blue.shade600),
            FormFields<DateTimeRange>(
              label: 'Project Duration',
              formType: FormType.dateTimeRange,
              labelPosition: LabelPosition.top,
              isRequired: true,
              useDatePickerForRange: true,
              onChanged: (value) => setState(() => _range1 = value),
              currrentValue: _range1,
            ),
            buildResultDisplay('Project Duration', _range1),

            // Nullable DateTimeRange - All Parameters
            buildFieldTitle('DateTimeRange (Nullable) - All Custom Parameters',
                Colors.blue.shade600),
            FormFields<DateTimeRange?>(
              label: 'Vacation Period',
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.cyan,
              ),
              onChanged: (value) => setState(() => _range2 = value),
              currrentValue: _range2,
            ),
            buildResultDisplay('Vacation Period', _range2, isOptional: true),

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
                  'SUBMIT FORM',
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
}
