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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormFields<String>(
                      label: context.tr('currentPassword'),
                      currentValue: viewModel.currentPassword,
                      formType: FormType.password,
                      labelPosition: LabelPosition.inBorder,
                      onChanged: (value) {
                        viewModel.currentPassword = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Contoh penggunaan JSON:',
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
                          '{\n  "label": "Current Password",\n  "currentValue": "contohPassword123",\n  "formType": "FormType.password",\n  "labelPosition": "LabelPosition.inBorder",\n  "onChanged": "(value) => ..."\n}',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF333333)),
                        ),
                      ),
                    ),
                    FormFields<String>(
                      label: context.tr('password'),
                      currentValue: viewModel.newPassword,
                      formType: FormType.password,
                      labelPosition: LabelPosition.inBorder,
                      onChanged: (value) {
                        viewModel.newPassword = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Contoh penggunaan JSON:',
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
                          '{\n  "label": "Password",\n  "currentValue": "passwordBaru456",\n  "formType": "FormType.password",\n  "labelPosition": "LabelPosition.inBorder",\n  "onChanged": "(value) => ..."\n}',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF333333)),
                        ),
                      ),
                    ),
                    FormFields<String>(
                      label: context.tr('confirmNewPassword'),
                      currentValue: viewModel.confirmPassword,
                      formType: FormType.password,
                      labelPosition: LabelPosition.inBorder,
                      onChanged: (value) {
                        viewModel.confirmPassword = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Contoh penggunaan JSON:',
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
                          '{\n  "label": "Konfirmasi Password Baru",\n  "currentValue": "passwordBaru456",\n  "formType": "FormType.password",\n  "labelPosition": "LabelPosition.inBorder",\n  "onChanged": "(value) => ..."\n}',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF333333)),
                        ),
                      ),
                    ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
