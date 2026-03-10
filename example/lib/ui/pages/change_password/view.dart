import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'main.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<ViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.tr('changePassword')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                tooltip: context.tr('back'),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FormFields<String>(
                  label: context.tr('currentPassword'),
                  currrentValue: viewModel.currentPassword,
                  formType: FormType.password,
                  labelPosition: LabelPosition.inBorder,
                  onChanged: (value) {
                    viewModel.currentPassword = value;
                  },
                ),
                const SizedBox(height: 12),
                FormFields<String>(
                  label: context.tr('password'),
                  currrentValue: viewModel.newPassword,
                  formType: FormType.password,
                  labelPosition: LabelPosition.inBorder,
                  onChanged: (value) {
                    viewModel.newPassword = value;
                  },
                ),
                const SizedBox(height: 12),
                FormFields<String>(
                  label: context.tr('confirmNewPassword'),
                  currrentValue: viewModel.confirmPassword,
                  formType: FormType.password,
                  labelPosition: LabelPosition.inBorder,
                  onChanged: (value) {
                    viewModel.confirmPassword = value;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.tr('updatePassword')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
