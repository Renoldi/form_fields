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
          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language indicator showing current locale
                  const LanguageIndicator(),

                  // ========== AUTOCOMPLETE PROPERTY DEMOS ==========
                  buildSectionTitle('Autocomplete (Custom Query Param)',
                      Colors.cyan, Colors.cyan.shade100),
                  FormFieldsAutocomplete(
                    label: 'Custom Query Param',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    resultProcessor: (data) {
                      if (data is Map && data['products'] is List) {
                        return (data['products'] as List)
                            .map((e) => e['title'].toString())
                            .toList();
                      }
                      return [];
                    },
                    onSelected:
                        viewModel.updateAutocompleteCustomQueryParamResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Custom Query Param Result',
                      viewModel.autocompleteCustomQueryParamResult),

                  buildSectionTitle('Autocomplete (Token Auth)', Colors.red,
                      Colors.red.shade100),
                  FormFieldsAutocomplete(
                    label: 'Token Auth',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    token: 'demo-token',
                    tokenHeader: 'X-Api-Key',
                    resultProcessor: (data) {
                      if (data is Map && data['products'] is List) {
                        return (data['products'] as List)
                            .map((e) => e['title'].toString())
                            .toList();
                      }
                      return [];
                    },
                    onSelected: viewModel.updateAutocompleteTokenResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Token Auth Result',
                      viewModel.autocompleteTokenResult),

                  buildSectionTitle('Autocomplete (Custom Result Processor)',
                      Colors.deepOrange, Colors.deepOrange.shade100),
                  FormFieldsAutocomplete(
                    label: 'Custom Result Processor',
                    url: 'https://dummyjson.com/products/search',
                    resultProcessor: (data) {
                      if (data is Map && data['products'] is List) {
                        return (data['products'] as List)
                            .where(
                                (e) => e['title'].toString().contains('Phone'))
                            .map((e) => e['title'].toString())
                            .toList();
                      }
                      return [];
                    },
                    onSelected:
                        viewModel.updateAutocompleteCustomResultProcessorResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Custom Result Processor Result',
                      viewModel.autocompleteCustomResultProcessorResult),

                  buildSectionTitle('Autocomplete (Custom Decoration)',
                      Colors.pink, Colors.pink.shade100),
                  FormFieldsAutocomplete(
                    label: 'Custom Decoration',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    decoration: InputDecoration(
                      hintText: 'Type to search...',
                      filled: true,
                      fillColor: Colors.pink.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onSelected:
                        viewModel.updateAutocompleteCustomDecorationResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Custom Decoration Result',
                      viewModel.autocompleteCustomDecorationResult),

                  buildSectionTitle('Autocomplete (Suffix Icon)', Colors.amber,
                      Colors.amber.shade100),
                  FormFieldsAutocomplete(
                    label: 'Suffix Icon',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    suffixIcon: Icon(Icons.star, color: Colors.amber),
                    onSelected: viewModel.updateAutocompleteSuffixIconResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Suffix Icon Result',
                      viewModel.autocompleteSuffixIconResult),

                  buildSectionTitle('Autocomplete (Remove Suffix Icon)',
                      Colors.lime, Colors.lime.shade100),
                  FormFieldsAutocomplete(
                    label: 'Remove Suffix Icon',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    removeSuffixIcon: true,
                    onSelected:
                        viewModel.updateAutocompleteRemoveSuffixIconResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Remove Suffix Icon Result',
                      viewModel.autocompleteRemoveSuffixIconResult),

                  buildSectionTitle('Autocomplete (BorderType Outline)',
                      Colors.blueGrey, Colors.blueGrey.shade100),
                  FormFieldsAutocomplete(
                    label: 'Outline Border',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    borderType: BorderType.outlineInputBorder,
                    onSelected: viewModel.updateAutocompleteOutlineBorderResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Outline BorderType Result',
                      viewModel.autocompleteOutlineBorderResult),

                  buildSectionTitle('Autocomplete (BorderType Underline)',
                      Colors.teal, Colors.teal.shade100),
                  FormFieldsAutocomplete(
                    label: 'Underline Border',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    borderType: BorderType.underlineInputBorder,
                    onSelected:
                        viewModel.updateAutocompleteUnderlineBorderResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Underline BorderType Result',
                      viewModel.autocompleteUnderlineBorderResult),

                  buildSectionTitle('Autocomplete (BorderType None)',
                      Colors.deepPurple, Colors.deepPurple.shade100),
                  FormFieldsAutocomplete(
                    label: 'No Border',
                    url: 'https://dummyjson.com/products/search',
                    queryParam: 'q',
                    borderType: BorderType.none,
                    onSelected: viewModel.updateAutocompleteNoBorderResult,
                    labelPosition: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'No BorderType Result',
                      viewModel.autocompleteNoBorderResult),

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

                  // Verification code with verificationAsOtp: true
                  buildFieldTitle('Verification Code (verificationAsOtp: true)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: true,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    onChanged: viewModel.updateVerificationCode,
                    currrentValue: viewModel.verificationCode,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code',
                    viewModel.verificationCode,
                  ),

                  // Verification code with verificationAsOtp: false
                  buildFieldTitle(
                      'Verification Code (verificationAsOtp: false)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code (Single Field)',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: false,
                    verificationLength: 6,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    onChanged: viewModel.updateVerificationCodeNoOtp,
                    currrentValue: viewModel.verificationCodeNoOtp,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code (Single Field)',
                    viewModel.verificationCodeNoOtp,
                  ),

                  // Verification code hidden with OTP boxes
                  buildFieldTitle(
                      'Verification Code (Hidden OTP)', Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code (Hidden OTP)',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: true,
                    verificationLength: 6,
                    verificationHidden: true,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.shield_outlined),
                    onChanged: viewModel.updateVerificationCodeHiddenOtp,
                    currrentValue: viewModel.verificationCodeHiddenOtp,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code (Hidden OTP)',
                    viewModel.verificationCodeHiddenOtp,
                  ),

                  // Verification code hidden in single text field
                  buildFieldTitle('Verification Code (Hidden Single Field)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code (Hidden Single)',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: false,
                    verificationLength: 6,
                    verificationHidden: true,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.lock_outline),
                    onChanged: viewModel.updateVerificationCodeHiddenSingle,
                    currrentValue: viewModel.verificationCodeHiddenSingle,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code (Hidden Single)',
                    viewModel.verificationCodeHiddenSingle,
                  ),

                  // Verification code with custom OTP style + inputDecoration
                  buildFieldTitle('Verification Code (Custom OTP Style)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Custom OTP',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationLength: 6,
                    verificationAsOtp: true,
                    otpBoxWidth: 44,
                    otpBoxSpacing: 12,
                    otpTextStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    inputDecoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF3F4F6),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: Color(0xFF84CC16), width: 1.6),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red, width: 1.6),
                      ),
                    ),
                    onChanged: viewModel.updateVerificationCodeStyled,
                    currrentValue: viewModel.verificationCodeStyled,
                  ),
                  buildResultDisplay(
                    context,
                    'Custom OTP',
                    viewModel.verificationCodeStyled,
                  ),

                  // Dedicated OTP example (4 digits)
                  buildFieldTitle(
                      'OTP Example (4 Digits)', Colors.blue.shade600),
                  FormFields<String>(
                    label: 'OTP Code',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationLength: 4,
                    verificationAsOtp: true,
                    otpBoxWidth: 52,
                    otpBoxSpacing: 14,
                    otpTextStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    inputDecoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFEEF2FF),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide:
                            BorderSide(color: Color(0xFFCBD5E1), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide:
                            BorderSide(color: Color(0xFF2563EB), width: 1.8),
                      ),
                    ),
                    onChanged: viewModel.updateOtp4Code,
                    currrentValue: viewModel.otp4Code,
                  ),
                  buildResultDisplay(
                    context,
                    'OTP 4 Digits',
                    viewModel.otp4Code,
                  ),

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
