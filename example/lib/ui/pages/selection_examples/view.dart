import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ViewModel>();
    return Form(
      key: vm.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grouped selection examples (replacing individual per-item widgets)

            // Rating example
            FormFieldsRating(
              label: 'Rate App',
              initialRating: vm.rating,
              onChanged: (v) => vm.setRating(v),
              isRequired: true,
              borderType: BorderType.outlineInputBorder,
            ),
            const SizedBox(height: 12),
            // Example: custom icon widgets (uses `filledIcon` / `emptyIcon`)
            FormFieldsRating(
              label: 'Rate App (custom icons)',
              initialRating: vm.ratingCustom,
              onChanged: (v) => vm.setRatingCustom(v),
              isRequired: true,
              borderType: BorderType.none,
              filledIcon: Icon(Icons.star, color: Colors.amber),
              emptyIcon: Icon(Icons.star_border, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // Switch examples (mirrors ViewModel.switchValue)

            Builder(builder: (context) {
              final totalWidth =
                  MediaQuery.of(context).size.width - 32; // account for padding
              final buttonWidth = (totalWidth - 12) / 2;
              return Row(
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: ElevatedButton(
                      onPressed: () => handleValidateForm(vm),
                      child: const Text('Validate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: buttonWidth,
                    child: OutlinedButton(
                      onPressed: () => vm.reset(),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
