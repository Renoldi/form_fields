import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

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
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ========== STRING TYPE ==========
          _buildSectionTitle('STRING TYPE - All Parameters'),

          // Non-Nullable String - Basic
          _buildFieldTitle('String (Non-Null) - Basic'),
          FormFields<String>(
            label: 'Full Name',
            formType: FormType.string,
            labelPosition: LabelPosition.top,
            isRequired: true,
            onChanged: (value) => setState(() => _string1 = value),
            currrentValue: _string1,
          ),

          // Nullable String - Optional
          _buildFieldTitle('String (Nullable) - Optional'),
          FormFields<String?>(
            label: 'Middle Name',
            formType: FormType.string,
            labelPosition: LabelPosition.top,
            isRequired: false,
            onChanged: (value) => setState(() => _string2 = value),
            currrentValue: _string2,
          ),

          // String with All Custom Parameters
          _buildFieldTitle('String - All Custom Parameters'),
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

          // Email with Parameters
          _buildFieldTitle('String - Email FormType'),
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

          // Phone with Parameters
          _buildFieldTitle('String - Phone FormType'),
          FormFields<String>(
            label: 'Phone Number',
            formType: FormType.phone,
            labelPosition: LabelPosition.top,
            isRequired: true,
            borderColor: Colors.orange,
            prefixIcon: const Icon(Icons.phone),
            onChanged: (value) => setState(() => _phone = value),
            currrentValue: _phone,
          ),

          // Password with All Parameters
          _buildFieldTitle('String - Password with Custom Validation'),
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

          // ========== INTEGER TYPE ==========
          _buildSectionTitle('INTEGER TYPE - All Parameters'),

          // Non-Nullable Int - Basic
          _buildFieldTitle('Int (Non-Null) - Basic'),
          FormFields<int>(
            label: 'Age',
            formType: FormType.string,
            labelPosition: LabelPosition.top,
            stripSeparators: false,
            isRequired: true,
            onChanged: (value) => setState(() => _int1 = value),
            currrentValue: _int1,
          ),

          // Nullable Int - With All Parameters
          _buildFieldTitle('Int (Nullable) - With Separators & Custom Styling'),
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

          // ========== DOUBLE TYPE ==========
          _buildSectionTitle('DOUBLE TYPE - All Parameters'),

          // Non-Nullable Double - With Separators
          _buildFieldTitle('Double (Non-Null) - With Separators'),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            onChanged: (value) => setState(() => _double1 = value),
            currrentValue: _double1,
          ),

          // Nullable Double - All Parameters
          _buildFieldTitle('Double (Nullable) - All Custom Parameters'),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            labelTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
            onChanged: (value) => setState(() => _double2 = value),
            currrentValue: _double2,
          ),

          // ========== DATETIME TYPE ==========
          _buildSectionTitle('DATETIME TYPE - All Parameters'),

          // Non-Nullable DateTime - Basic
          _buildFieldTitle('DateTime (Non-Null) - Basic'),
          FormFields<DateTime>(
            label: 'Birth Date',
            formType: FormType.dateTime,
            labelPosition: LabelPosition.top,
            isRequired: true,
            onChanged: (value) => setState(() => _date1 = value),
            currrentValue: _date1,
          ),

          // Nullable DateTime - All Parameters
          _buildFieldTitle('DateTime (Nullable) - All Custom Parameters'),
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

          // ========== TIMEOFDAY TYPE ==========
          _buildSectionTitle('TIMEOFDAY TYPE - All Parameters'),

          // Non-Nullable TimeOfDay - Basic
          _buildFieldTitle('TimeOfDay (Non-Null) - Basic'),
          FormFields<TimeOfDay>(
            label: 'Meeting Time',
            formType: FormType.timeOfDay,
            labelPosition: LabelPosition.top,
            isRequired: true,
            onChanged: (value) => setState(() => _time1 = value),
            currrentValue: _time1,
          ),

          // Nullable TimeOfDay - All Parameters
          _buildFieldTitle('TimeOfDay (Nullable) - All Custom Parameters'),
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

          // ========== DATETIMERANGE TYPE ==========
          _buildSectionTitle('DATETIMERANGE TYPE - All Parameters'),

          // Non-Nullable DateTimeRange - Basic
          _buildFieldTitle('DateTimeRange (Non-Null) - Basic'),
          FormFields<DateTimeRange>(
            label: 'Project Duration',
            formType: FormType.dateTimeRange,
            labelPosition: LabelPosition.top,
            isRequired: true,
            onChanged: (value) => setState(() => _range1 = value),
            currrentValue: _range1,
          ),

          // Nullable DateTimeRange - All Parameters
          _buildFieldTitle('DateTimeRange (Nullable) - All Custom Parameters'),
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
            labelTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.cyan,
            ),
            onChanged: (value) => setState(() => _range2 = value),
            currrentValue: _range2,
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
                colors: [Colors.blue.shade700, Colors.blue.shade400],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
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
              color: Colors.blue.shade600,
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
