import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormFields Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en', 'GB'),
      ],
      home: const FormFieldsExamplePage(),
    );
  }
}

class FormFieldsExamplePage extends StatefulWidget {
  const FormFieldsExamplePage({Key? key}) : super(key: key);

  @override
  State<FormFieldsExamplePage> createState() => _FormFieldsExamplePageState();
}

class _FormFieldsExamplePageState extends State<FormFieldsExamplePage> {
  final _formKey = GlobalKey<FormState>();

  // Text fields
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _bio = '';

  // Numeric fields
  int _quantity = 0;
  double _price = 0.0;
  double? _prices = 0.0;

  // Date/time fields
  DateTime? _birthDate;
  DateTime? _selectedTime;
  TimeOfDay? _selectedTimeOfDay;
  DateTime? _selectedDateTime;
  DateTimeRange? _dateRange;
  DateTimeRange? _vacationDates;
  DateTimeRange? _projectTimeline;

  // Nullable/Optional fields
  String? _optionalNotes;
  int? _optionalQuantity;
  double? _optionalDiscount;
  String? _optionalPhone;
  String? _optionalEmail;
  double? _optionalPrice;
  String? _optionalFullName;
  String? _optionalBio;
  DateTime? _optionalBirthDate;
  DateTime? _optionalSelectedDateTime;
  TimeOfDay? _optionalSelectedTimeOfDay;
  DateTimeRange? _optionalDateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FormFields Example'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Basic Text Fields',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                FormFields<double?>(
                  label: '_prices (Double with separators)',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  stripSeparators: true, // Shows 1,000 instead of 1000
                  onChanged: (value) {
                    setState(() {
                      _prices = value;
                      debugPrint('Updated _prices: $_prices');
                    });
                  },
                  currrentValue: _prices,
                ),

                // Full Name Field
                FormFields<String>(
                  label: 'Full Name',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  isRequired: true,
                  onChanged: (value) {
                    setState(() => _fullName = value);
                  },
                  currrentValue: _fullName.isEmpty ? null : _fullName,
                ),

                // Email Field
                FormFields<String>(
                  label: 'Email Address',
                  formType: FormType.email,
                  labelPosition: LabelPosition.top,
                  isRequired: true,
                  onChanged: (value) {
                    setState(() => _email = value);
                  },
                  currrentValue: _email.isEmpty ? null : _email,
                ),

                // Phone Field
                FormFields<String>(
                  label: 'Phone Number',
                  formType: FormType.phone,
                  labelPosition: LabelPosition.top,
                  isRequired: true,
                  onChanged: (value) {
                    setState(() => _phone = value);
                  },
                  currrentValue: _phone.isEmpty ? null : _phone,
                ),

                // Password Field
                FormFields<String>(
                  label: 'Password',
                  formType: FormType.password,
                  labelPosition: LabelPosition.top,
                  isRequired: true,
                  onChanged: (value) {
                    setState(() => _password = value);
                  },
                  currrentValue: _password.isEmpty ? null : _password,
                ),

                // Bio Field (Multiline)
                FormFields<String>(
                  label: 'Bio',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  multiLine: 3,
                  onChanged: (value) {
                    setState(() => _bio = value);
                  },
                  currrentValue: _bio.isEmpty ? null : _bio,
                ),

                // Bio Field with Custom Enter Text
                FormFields<String>(
                  label: 'Custom Message',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  multiLine: 2,
                  enterText: 'Please input ',
                  onChanged: (value) {
                    setState(() => _bio = value);
                  },
                  currrentValue: _bio.isEmpty ? null : _bio,
                ),

                const SizedBox(height: 24),
                const Text(
                  'Numeric Fields',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Integer Field (Quantity) with thousand separators
                FormFields<int>(
                  label: 'Quantity',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  stripSeparators: true, // Shows 1,000 instead of 1000
                  onChanged: (value) {
                    setState(() => _quantity = value);
                  },
                  currrentValue: _quantity == 0 ? null : _quantity,
                ),

                // Double Field (Price) with thousand separators
                FormFields<double>(
                  label: 'Price',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  stripSeparators: true, // Shows 1,234.56 instead of 1234.56
                  onChanged: (value) {
                    setState(() => _price = value);
                  },
                  currrentValue: _price == 0.0 ? null : _price,
                ),

                const SizedBox(height: 24),
                const Text(
                  'Date & Time Fields',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DateTime vs TimeOfDay for Time Pickers',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),

                // Date Field with custom range (past dates)
                FormFields<DateTime>(
                  label: 'Birth Date',
                  formType: FormType.date,
                  labelPosition: LabelPosition.top,
                  firstDate: DateTime(1924, 1, 1),
                  lastDate: DateTime.now(),
                  onChanged: (value) {
                    setState(() => _birthDate = value);
                  },
                  currrentValue: _birthDate,
                ),

                const SizedBox(height: 8),
                const Text(
                  '📅 Future dates only (booking example)',
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                ),
                const SizedBox(height: 4),

                // Date Field with future dates only
                FormFields<DateTime>(
                  label: 'Appointment Date',
                  formType: FormType.date,
                  labelPosition: LabelPosition.top,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                  onChanged: (value) {
                    setState(() => _birthDate = value);
                  },
                  currrentValue: _birthDate,
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // DateTime Time Picker
                const Text(
                  'Time Picker with DateTime',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Returns DateTime with current date + selected time',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                FormFields<DateTime>(
                  label: 'Appointment Time (DateTime)',
                  formType: FormType.time,
                  labelPosition: LabelPosition.top,
                  onChanged: (value) {
                    setState(() => _selectedTime = value);
                  },
                  currrentValue: _selectedTime,
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // TimeOfDay Time Picker
                const Text(
                  'Time Picker with TimeOfDay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Returns TimeOfDay object (hour and minute only)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                FormFields<TimeOfDay>(
                  label: 'Meeting Time (TimeOfDay)',
                  formType: FormType.time,
                  labelPosition: LabelPosition.top,
                  onChanged: (value) {
                    setState(() => _selectedTimeOfDay = value);
                  },
                  currrentValue: _selectedTimeOfDay,
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Conversion Examples
                if (_selectedTime != null || _selectedTimeOfDay != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔄 Type Conversions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedTime != null) ...[
                          Text(
                            'DateTime → TimeOfDay:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '  ${_selectedTime.toString()} →',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '  ${_selectedTime!.toTimeOfDay()!.hour}:${_selectedTime!.toTimeOfDay()!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_selectedTimeOfDay != null) ...[
                          Text(
                            'TimeOfDay → DateTime:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '  ${_selectedTimeOfDay!.hour}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')} →',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '  ${_selectedTimeOfDay!.toDateTime().toString()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '  With specific date (Christmas 2026):',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '  ${_selectedTimeOfDay!.toDateTimeWithDate(DateTime(2026, 12, 25)).toString()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                ],

                // Time Field with Custom Locale
                FormFields<DateTime>(
                  label: 'Time with Custom Locale (en_US)',
                  formType: FormType.time,
                  labelPosition: LabelPosition.top,
                  pickerLocale: 'en_US',
                  onChanged: (value) {
                    setState(() => _selectedTime = value);
                  },
                  currrentValue: _selectedTime,
                ),

                FormFields<DateTime>(
                  label: 'Selected DateTime',
                  formType: FormType.dateTime,
                  labelPosition: LabelPosition.top,
                  onChanged: (value) {
                    setState(() => _selectedDateTime = value);
                  },
                  currrentValue: _selectedDateTime,
                ),

                // DateRange Field
                FormFields<DateTimeRange>(
                  label: 'Date Range',
                  formType: FormType.date,
                  labelPosition: LabelPosition.top,
                  onChanged: (value) {
                    setState(() => _dateRange = value);
                  },
                  currrentValue: _dateRange,
                ),

                // Vacation Dates (Future dates only, next 2 years)
                FormFields<DateTimeRange>(
                  label: 'Vacation Dates',
                  formType: FormType.date,
                  labelPosition: LabelPosition.top,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                  onChanged: (value) {
                    setState(() => _vacationDates = value);
                  },
                  currrentValue: _vacationDates,
                ),

                // Project Timeline (2020-2030 range)
                FormFields<DateTimeRange>(
                  label: 'Project Timeline',
                  formType: FormType.date,
                  labelPosition: LabelPosition.top,
                  firstDate: DateTime(2020, 1, 1),
                  lastDate: DateTime(2030, 12, 31),
                  onChanged: (value) {
                    setState(() => _projectTimeline = value);
                  },
                  currrentValue: _projectTimeline,
                ),

                const SizedBox(height: 24),
                const Text(
                  'Nullable/Optional Fields',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Optional Notes Field (Nullable String)
                FormFields<String?>(
                  label: 'Additional Notes (Optional)',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  multiLine: 2,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalNotes = value);
                  },
                  currrentValue: _optionalNotes,
                ),

                // Optional Quantity Field (Nullable Int) with thousand separators
                FormFields<int?>(
                  label: 'Optional Quantity',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  stripSeparators: true, // Shows 1,000 instead of 1000
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalQuantity = value);
                  },
                  currrentValue: _optionalQuantity,
                ),

                // Optional Discount Field (Nullable Double - no thousand separators)
                FormFields<double?>(
                  label: 'Discount Percentage (Optional)',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  stripSeparators:
                      false, // No commas: 1234.56 instead of 1,234.56
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalDiscount = value);
                  },
                  currrentValue: _optionalDiscount,
                ),

                // Optional Phone Field (Nullable String with formatters)
                FormFields<String?>(
                  label: 'Optional Phone Number',
                  formType: FormType.phone,
                  labelPosition: LabelPosition.top,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalPhone = value);
                  },
                  currrentValue: _optionalPhone,
                ),

                // Optional Email Field (Nullable String with formatters)
                FormFields<String?>(
                  label: 'Optional Email Address',
                  formType: FormType.email,
                  labelPosition: LabelPosition.top,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalEmail = value);
                  },
                  currrentValue: _optionalEmail,
                ),

                // Optional Price Field (Nullable Double without separators)
                FormFields<double?>(
                  label: 'Optional Price (without separators)',
                  labelPosition: LabelPosition.top,
                  stripSeparators: false, // Only accepts numbers, no formatting
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalPrice = value);
                  },
                  currrentValue: _optionalPrice,
                ),

                // Optional Full Name Field (Nullable String)
                FormFields<String?>(
                  label: 'Optional Full Name',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalFullName = value);
                  },
                  currrentValue: _optionalFullName,
                ),

                // Optional Bio Field (Nullable String - Multiline)
                FormFields<String?>(
                  label: 'Optional Bio',
                  formType: FormType.string,
                  labelPosition: LabelPosition.top,
                  multiLine: 3,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalBio = value);
                  },
                  currrentValue: _optionalBio,
                ),

                // Optional Birth Date Field (Nullable DateTime)
                FormFields<DateTime?>(
                  label: 'Optional Birth Date',
                  formType: FormType.date,
                  labelPosition: LabelPosition.top,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalBirthDate = value);
                  },
                  currrentValue: _optionalBirthDate,
                ),

                // Optional DateTime Field (Nullable DateTime)
                FormFields<DateTime?>(
                  label: 'Optional Selected DateTime',
                  formType: FormType.dateTime,
                  labelPosition: LabelPosition.top,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalSelectedDateTime = value);
                  },
                  currrentValue: _optionalSelectedDateTime,
                ),

                // Optional TimeOfDay Field (Nullable TimeOfDay)
                FormFields<TimeOfDay?>(
                  label: 'Optional TimeOfDay',
                  formType: FormType.time,
                  labelPosition: LabelPosition.top,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalSelectedTimeOfDay = value);
                  },
                  currrentValue: _optionalSelectedTimeOfDay,
                ),

                // Optional DateRange Field (Nullable DateTimeRange)
                FormFields<DateTimeRange?>(
                  label: 'Optional Date Range',
                  formType: FormType.date,
                  labelPosition: LabelPosition.top,
                  isRequired: false,
                  onChanged: (value) {
                    setState(() => _optionalDateRange = value);
                  },
                  currrentValue: _optionalDateRange,
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _showFormData();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Submit Form',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Display submitted data
                if (_fullName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submitted Data:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDataRow('Full Name', _fullName),
                        _buildDataRow('Email', _email),
                        _buildDataRow('Phone', _phone),
                        _buildDataRow('Quantity', _quantity.toString()),
                        _buildDataRow('Price', _price.toString()),
                        if (_birthDate != null)
                          _buildDataRow('Birth Date', _birthDate.toString()),
                        if (_selectedTimeOfDay != null) ...[
                          _buildDataRow('TimeOfDay',
                              '${_selectedTimeOfDay!.hour}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')}'),
                          _buildDataRow(
                            'TimeOfDay → DateTime',
                            _selectedTimeOfDay!.toDateTime().toString(),
                          ),
                        ],
                        if (_selectedTime != null) ...[
                          _buildDataRow(
                              'DateTime Time', _selectedTime.toString()),
                          _buildDataRow(
                            'DateTime → TimeOfDay',
                            '${_selectedTime!.toTimeOfDay()!.hour}:${_selectedTime!.toTimeOfDay()!.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                        if (_dateRange != null)
                          _buildDataRow(
                            'Date Range',
                            '${_dateRange!.start} - ${_dateRange!.end}',
                          ),
                        if (_vacationDates != null)
                          _buildDataRow(
                            'Vacation Dates',
                            '${_vacationDates!.start} - ${_vacationDates!.end}',
                          ),
                        if (_projectTimeline != null)
                          _buildDataRow(
                            'Project Timeline',
                            '${_projectTimeline!.start} - ${_projectTimeline!.end}',
                          ),
                        if (_optionalNotes != null)
                          _buildDataRow('Additional Notes', _optionalNotes!),
                        if (_optionalQuantity != null)
                          _buildDataRow('Optional Quantity',
                              _optionalQuantity.toString()),
                        if (_optionalDiscount != null)
                          _buildDataRow('Discount Percentage',
                              _optionalDiscount.toString()),
                        if (_optionalPhone != null)
                          _buildDataRow('Optional Phone', _optionalPhone!),
                        if (_optionalEmail != null)
                          _buildDataRow('Optional Email', _optionalEmail!),
                        if (_optionalPrice != null)
                          _buildDataRow(
                              'Optional Price', _optionalPrice.toString()),
                        // New nullable field displays
                        if (_optionalFullName != null)
                          _buildDataRow(
                              'Optional Full Name', _optionalFullName!),
                        if (_optionalBio != null)
                          _buildDataRow('Optional Bio', _optionalBio!),
                        if (_optionalBirthDate != null)
                          _buildDataRow('Optional Birth Date',
                              _optionalBirthDate!.toString().split(' ')[0]),
                        if (_optionalSelectedDateTime != null)
                          _buildDataRow('Optional Selected DateTime',
                              _optionalSelectedDateTime.toString()),
                        if (_optionalSelectedTimeOfDay != null)
                          _buildDataRow('Optional Selected TimeOfDay',
                              '${_optionalSelectedTimeOfDay!.hour}:${_optionalSelectedTimeOfDay!.minute.toString().padLeft(2, '0')}'),
                        if (_optionalDateRange != null)
                          _buildDataRow(
                            'Optional Date Range',
                            '${_optionalDateRange!.start} - ${_optionalDateRange!.end}',
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _showFormData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form submitted successfully!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}
