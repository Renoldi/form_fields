import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ViewModel(),
      child: Consumer<ViewModel>(
        builder: (context, viewModel, _) {
          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Radio Button Examples',
                      Colors.orange.shade700, Colors.orange.shade400),
                  buildFieldTitle('Basic Vertical', Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: 'Gender',
                    initialValue: viewModel.radio1,
                    items: const ['Male', 'Female', 'Other'],
                    isRequired: true,
                    onChanged: (v) => viewModel.setRadio1(v ?? ''),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Gender)', viewModel.radio1),
                  const SizedBox(height: 16),
                  buildFieldTitle(
                      'Horizontal (Rating)', Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: 'Rating',
                    initialValue: viewModel.radio5,
                    items: const ['⭐', '⭐⭐', '⭐⭐⭐', '⭐⭐⭐⭐', '⭐⭐⭐⭐⭐'],
                    direction: Axis.horizontal,
                    horizontalSideBySide: true,
                    onChanged: (v) => viewModel.setRadio5(v ?? ''),
                  ),
                  buildResultDisplay(
                      context, 'Selected (Rating)', viewModel.radio5),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (viewModel.formKey.currentState?.validate() ??
                            false) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Form valid')),
                          );
                        }
                      },
                      child: const Text('Validate'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
