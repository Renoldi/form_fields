import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:form_fields_example/state/pages/change_password_view_model.dart';

class ChangePasswordPage extends StatelessWidget {
  final VoidCallback onBack;

  const ChangePasswordPage({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChangePasswordViewModel(),
      child: Consumer<ChangePasswordViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.tr('changePassword')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: context.tr('back'),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FormFields<String>(
                  label: context.tr('currentPassword'),
                  currrentValue: viewModel.currentPasswordController.text,
                  formType: FormType.password,
                  labelPosition: LabelPosition.inBorder,
                  enterText: '',
                  onChanged: (value) {
                    viewModel.currentPasswordController.text = value;
                  },
                ),
                const SizedBox(height: 12),
                FormFields<String>(
                  label: context.tr('password'),
                  currrentValue: viewModel.newPasswordController.text,
                  formType: FormType.password,
                  labelPosition: LabelPosition.inBorder,
                  enterText: '',
                  onChanged: (value) {
                    viewModel.newPasswordController.text = value;
                  },
                ),
                const SizedBox(height: 12),
                FormFields<String>(
                  label: context.tr('confirmNewPassword'),
                  currrentValue: viewModel.confirmPasswordController.text,
                  formType: FormType.password,
                  labelPosition: LabelPosition.inBorder,
                  enterText: '',
                  onChanged: (value) {
                    viewModel.confirmPasswordController.text = value;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final result = viewModel.submit();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.message)),
                      );
                    },
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
