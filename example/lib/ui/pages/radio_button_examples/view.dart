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
          final l = loc.Localizations.of(context);

          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
    final l = loc.Localizations.of(context);

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
