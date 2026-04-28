import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart' as loc;
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RadioButtonExamplesViewModel(),
      child: Consumer<RadioButtonExamplesViewModel>(
        builder: (context, viewModel, _) {
          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle(context.tr('radioButtonBasicExamples'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 1: Basic Vertical Radio Button
                  buildFieldTitle(
                      context.tr('basicRadioVertical'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('gender'),
                    initialValue: viewModel.radio1,
                    items: [
                      context.tr('male'),
                      context.tr('female'),
                      context.tr('other')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    indicatorVerticalAlignment: IndicatorVerticalAlignment.top,
                    onChanged: (value) => viewModel.setRadio1(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, context.tr('selectedGender'), viewModel.radio1),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Jenis Kelamin",\n  "isRequired": true,\n  "direction": "vertical",\n  "items": ["Laki-laki", "Perempuan", "Lainnya"],\n  "onChanged": "(value) => setRadio1(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 2: Horizontal Radio Button
                  buildFieldTitle(
                      context.tr('radioHorizontal'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('maritalStatus'),
                    initialValue: viewModel.radio2,
                    items: [
                      context.tr('single'),
                      context.tr('married'),
                      context.tr('divorced')
                    ],
                    isRequired: true,
                    direction: Axis.horizontal,
                    horizontalSideBySide: true,
                    onChanged: (value) => viewModel.setRadio2(value ?? ''),
                  ),
                  buildResultDisplay(context,
                      context.tr('selectedMaritalStatus'), viewModel.radio2),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Status Pernikahan",\n  "isRequired": true,\n  "direction": "horizontal",\n  "horizontalSideBySide": true,\n  "items": ["Belum Menikah", "Menikah", "Cerai"],\n  "onChanged": "(value) => setRadio2(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  buildSectionTitle(context.tr('radioBorderColors'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 3: Custom Border & Colors
                  buildFieldTitle(
                      context.tr('customBorderActive'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('subscriptionPlan'),
                    initialValue: viewModel.radio3,
                    items: [
                      context.tr('free'),
                      context.tr('basic'),
                      context.tr('premium'),
                      context.tr('enterprise')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.purple,
                    errorBorderColor: Colors.red.shade700,
                    activeColor: Colors.purple,
                    radius: 15,
                    indicatorVerticalAlignment:
                        IndicatorVerticalAlignment.center,
                    onChanged: (value) => viewModel.setRadio3(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, context.tr('selectedPlan'), viewModel.radio3),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Paket Berlangganan",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.purple",\n  "activeColor": "Colors.purple",\n  "radius": 15,\n  "items": ["Gratis", "Basic", "Premium", "Enterprise"],\n  "onChanged": "(value) => setRadio3(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 4: Custom Item Spacing & Padding
                  buildFieldTitle(
                      context.tr('customItemSpacing'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('deliveryOption'),
                    initialValue: viewModel.radio4,
                    items: [
                      context.tr('pickup'),
                      context.tr('standardDelivery'),
                      context.tr('expressDelivery')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.orange,
                    activeColor: Colors.orange,
                    itemPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    onChanged: (value) => viewModel.setRadio4(value ?? ''),
                  ),
                  buildResultDisplay(context, context.tr('selectedDelivery'),
                      viewModel.radio4),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Opsi Pengiriman",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.orange",\n  "activeColor": "Colors.orange",\n  "itemPadding": "EdgeInsets.symmetric(vertical: 12, horizontal: 8)",\n  "items": ["Ambil Sendiri", "Reguler", "Ekspres"],\n  "onChanged": "(value) => setRadio4(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  buildSectionTitle(context.tr('radioLayoutVariations'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 5: Horizontal with Fill Items
                  buildFieldTitle(
                      context.tr('horizontalFill'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('rating'),
                    initialValue: viewModel.radio5,
                    items: const ['⭐', '⭐⭐', '⭐⭐⭐', '⭐⭐⭐⭐', '⭐⭐⭐⭐⭐'],
                    isRequired: true,
                    direction: Axis.horizontal,
                    horizontalSideBySide: true,
                    borderColor: Colors.amber,
                    activeColor: Colors.amber,
                    onChanged: (value) => viewModel.setRadio5(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, context.tr('selectedRating'), viewModel.radio5),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Rating",\n  "isRequired": true,\n  "direction": "horizontal",\n  "horizontalSideBySide": true,\n  "borderColor": "Colors.amber",\n  "activeColor": "Colors.amber",\n  "items": ["⭐", "⭐⭐", "⭐⭐⭐", "⭐⭐⭐⭐", "⭐⭐⭐⭐⭐"],\n  "onChanged": "(value) => setRadio5(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 6: Different Label Positions
                  buildFieldTitle(
                      context.tr('labelPositionLeft'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('priority'),
                    initialValue: viewModel.radio6,
                    items: [
                      context.tr('low'),
                      context.tr('medium'),
                      context.tr('high')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.red,
                    activeColor: Colors.red,
                    onChanged: (value) => viewModel.setRadio6(value ?? ''),
                  ),
                  buildResultDisplay(context, context.tr('selectedPriority'),
                      viewModel.radio6),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Prioritas",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.red",\n  "activeColor": "Colors.red",\n  "items": ["Rendah", "Sedang", "Tinggi"],\n  "onChanged": "(value) => setRadio6(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  buildSectionTitle(context.tr('radioAdvancedFeatures'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 7: Custom Validation
                  buildFieldTitle(
                      context.tr('customValidation'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('paymentMethod'),
                    initialValue: viewModel.radio7,
                    items: [
                      context.tr('creditCard'),
                      context.tr('debitCard'),
                      context.tr('paypal'),
                      context.tr('cashOnDelivery')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.teal,
                    activeColor: Colors.teal,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('radioSelectPaymentMethod');
                      }
                      if (value == context.tr('cashOnDelivery')) {
                        return context.tr('cashNotAvailable');
                      }
                      return null;
                    },
                    onChanged: (value) => viewModel.setRadio7(value ?? ''),
                  ),
                  buildResultDisplay(context,
                      context.tr('selectedPaymentMethod'), viewModel.radio7),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Metode Pembayaran",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.teal",\n  "activeColor": "Colors.teal",\n  "items": ["Kartu Kredit", "Kartu Debit", "PayPal", "COD"],\n  "validator": "(value) { if (value == null) return \'Pilih metode\'; if (value == \'COD\') return \'COD tidak tersedia\'; return null; }",\n  "onChanged": "(value) => setRadio7(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 8: With Custom Icon Size
                  buildFieldTitle(
                      context.tr('customIconSize'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('newsletterFrequency'),
                    initialValue: viewModel.radio8,
                    items: [
                      context.tr('daily'),
                      context.tr('weekly'),
                      context.tr('monthly'),
                      context.tr('never')
                    ],
                    isRequired: false,
                    direction: Axis.vertical,
                    borderColor: Colors.indigo,
                    activeColor: Colors.indigo,
                    indicatorVerticalAlignment:
                        IndicatorVerticalAlignment.bottom,
                    itemPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    onChanged: (value) => viewModel.setRadio8(value ?? ''),
                  ),
                  buildResultDisplay(context, context.tr('selectedFrequency'),
                      viewModel.radio8),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Frekuensi Newsletter",\n  "isRequired": false,\n  "direction": "vertical",\n  "borderColor": "Colors.indigo",\n  "activeColor": "Colors.indigo",\n  "indicatorVerticalAlignment": "IndicatorVerticalAlignment.bottom",\n  "itemPadding": "EdgeInsets.symmetric(vertical: 10, horizontal: 4)",\n  "items": ["Harian", "Mingguan", "Bulanan", "Tidak Pernah"],\n  "onChanged": "(value) => setRadio8(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  buildSectionTitle(context.tr('rbLabelPositions'),
                      Colors.orange.shade700, Colors.orange.shade400),

                  // Example 9: Label Position Bottom
                  buildFieldTitle(
                      context.tr('rbLabelBottom'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('communicationMethod'),
                    initialValue: viewModel.radio9,
                    items: [
                      context.tr('email'),
                      context.tr('phone'),
                      context.tr('sms'),
                      context.tr('pushNotification')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.cyan,
                    activeColor: Colors.cyan,
                    labelPosition: LabelPosition.bottom,
                    onChanged: (value) => viewModel.setRadio9(value ?? ''),
                  ),
                  buildResultDisplay(context,
                      context.tr('selectedCommunication'), viewModel.radio9),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Metode Komunikasi",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.cyan",\n  "activeColor": "Colors.cyan",\n  "labelPosition": "LabelPosition.bottom",\n  "items": ["Email", "Telepon", "SMS", "Push Notification"],\n  "onChanged": "(value) => setRadio9(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 10: Label Position Top
                  buildFieldTitle(
                      context.tr('rbLabelTop'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('theme'),
                    initialValue: viewModel.radio10,
                    items: [
                      context.tr('light'),
                      context.tr('dark'),
                      context.tr('system')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.lime,
                    activeColor: Colors.lime,
                    labelPosition: LabelPosition.top,
                    onChanged: (value) => viewModel.setRadio10(value ?? ''),
                  ),
                  buildResultDisplay(
                      context, context.tr('selectedTheme'), viewModel.radio10),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Tema",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.lime",\n  "activeColor": "Colors.lime",\n  "labelPosition": "LabelPosition.top",\n  "items": ["Terang", "Gelap", "Sistem"],\n  "onChanged": "(value) => setRadio10(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 11: Label Position Left
                  buildFieldTitle(
                      context.tr('rbLabelLeft'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('accessibility'),
                    initialValue: viewModel.radio11,
                    items: [context.tr('enabled'), context.tr('disabled')],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.pink,
                    activeColor: Colors.pink,
                    labelPosition: LabelPosition.left,
                    onChanged: (value) => viewModel.setRadio11(value ?? ''),
                  ),
                  buildResultDisplay(context,
                      context.tr('selectedAccessibility'), viewModel.radio11),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Aksesibilitas",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.pink",\n  "activeColor": "Colors.pink",\n  "labelPosition": "LabelPosition.left",\n  "items": ["Aktif", "Nonaktif"],\n  "onChanged": "(value) => setRadio11(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 12: Label Position Right
                  buildFieldTitle(
                      context.tr('rbLabelRight'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('visibility'),
                    initialValue: viewModel.radio12,
                    items: [
                      context.tr('public'),
                      context.tr('private'),
                      context.tr('restricted')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.deepOrange,
                    activeColor: Colors.deepOrange,
                    labelPosition: LabelPosition.right,
                    onChanged: (value) => viewModel.setRadio12(value ?? ''),
                  ),
                  buildResultDisplay(context, context.tr('selectedVisibility'),
                      viewModel.radio12),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Visibilitas",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.deepOrange",\n  "activeColor": "Colors.deepOrange",\n  "labelPosition": "LabelPosition.right",\n  "items": ["Publik", "Privat", "Terbatas"],\n  "onChanged": "(value) => setRadio12(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 13: Label Position InBorder
                  buildFieldTitle(
                      context.tr('rbLabelInBorder'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('verificationStatus'),
                    initialValue: viewModel.radio13,
                    items: [
                      context.tr('verified'),
                      context.tr('pending'),
                      context.tr('unverified')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.green,
                    activeColor: Colors.green,
                    labelPosition: LabelPosition.inBorder,
                    onChanged: (value) => viewModel.setRadio13(value ?? ''),
                  ),
                  buildResultDisplay(context,
                      context.tr('selectedVerification'), viewModel.radio13),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Status Verifikasi",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.green",\n  "activeColor": "Colors.green",\n  "labelPosition": "LabelPosition.inBorder",\n  "items": ["Terverifikasi", "Menunggu", "Belum Terverifikasi"],\n  "onChanged": "(value) => setRadio13(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  // Example 14: Label Position None
                  buildFieldTitle(
                      context.tr('rbLabelNone'), Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: context.tr('notificationPreference'),
                    initialValue: viewModel.radio14,
                    items: [
                      context.tr('on'),
                      context.tr('off'),
                      context.tr('quiet')
                    ],
                    isRequired: true,
                    direction: Axis.vertical,
                    borderColor: Colors.blue,
                    activeColor: Colors.blue,
                    labelPosition: LabelPosition.none,
                    onChanged: (value) => viewModel.setRadio14(value ?? ''),
                  ),
                  buildResultDisplay(context,
                      context.tr('selectedNotification'), viewModel.radio14),
                  const SizedBox(height: 8),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "label": "Preferensi Notifikasi",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.blue",\n  "activeColor": "Colors.blue",\n  "labelPosition": "LabelPosition.none",\n  "items": ["Aktif", "Nonaktif", "Senyap"],\n  "onChanged": "(value) => setRadio14(value ?? \'\')"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (viewModel.formKey.currentState!.validate()) {
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
                        context.tr('validateFormButton'),
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
            Text(context.tr('radioFormValidated')),
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
