import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/example_localizations.dart';
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
              title:
                  Text(ExampleLocalizations.of(context).get('changePassword')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: ExampleLocalizations.of(context).get('back'),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: viewModel.currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        ExampleLocalizations.of(context).get('currentPassword'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: viewModel.newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: ExampleLocalizations.of(context)
                        .get('confirmNewPassword'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: viewModel.confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: ExampleLocalizations.of(context)
                        .get('confirmNewPassword'),
                  ),
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
                    child: Text(
                        ExampleLocalizations.of(context).get('updatePassword')),
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
