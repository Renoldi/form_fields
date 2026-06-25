import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'presenter.dart';
import 'view_model.dart';

class SelectionExamplesView extends PresenterState {
  const SelectionExamplesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectionExamplesViewModel(),
      child: Consumer<SelectionExamplesViewModel>(
        builder: (context, vm, _) {
          return Form(
            key: vm.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selection Fields Examples', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // CheckboxListTile example
                  const Text('CheckboxListTile', style: TextStyle(fontWeight: FontWeight.w600)),
                  FormFieldsCheckboxListTile(
                    label: 'Agree Terms',
                    value: vm.checkboxValue,
                    onChanged: (v) => vm.setCheckbox(v),
                    isRequired: true,
                  ),
                  Text('Value: \\${vm.checkboxValue}'),
                  const SizedBox(height: 12),

                  // SwitchListTile example
                  const Text('SwitchListTile', style: TextStyle(fontWeight: FontWeight.w600)),
                  FormFieldsSwitchTile(
                    label: 'Enable Notifications',
                    value: vm.switchValue,
                    onChanged: (v) => vm.setSwitch(v),
                    isRequired: false,
                  ),
                  Text('Value: \\${vm.switchValue}'),
                  const SizedBox(height: 12),

                  // ListTile example (tap to set value)
                  const Text('ListTile (tap to set value)', style: TextStyle(fontWeight: FontWeight.w600)),
                  FormFieldsListTile(
                    label: 'Choose Option',
                    title: Text('Option A'),
                    subtitle: Text('Tap to select Option A'),
                    onTap: () => vm.setListTile('Option A'),
                  ),
                  FormFieldsListTile(
                    label: 'Choose Option',
                    title: Text('Option B'),
                    subtitle: Text('Tap to select Option B'),
                    onTap: () => vm.setListTile('Option B'),
                  ),
                  Text('Selected: \\${vm.listTileResult}'),
                  const SizedBox(height: 12),

                  // Rating example
                  const Text('Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                  FormFieldsRating(
                    label: 'Rate App',
                    initialRating: vm.rating,
                    onChanged: (v) => vm.setRating(v),
                    isRequired: false,
                  ),
                  Text('Rating: \\${vm.rating}'),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (vm.formKey.currentState?.validate() ?? false) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form valid')));
                            }
                          },
                          child: const Text('Validate'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => vm.reset(),
                          child: const Text('Reset'),
                        ),
                      ),
                    ],
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
