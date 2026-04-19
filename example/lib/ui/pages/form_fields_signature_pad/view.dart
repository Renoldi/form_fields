import 'package:flutter/material.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ViewModel(),
      child: Consumer<ViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.tr('signaturePadTitle')),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FormFieldsSignaturePad(
                    onExported: viewModel.setSignature,
                  ),
                  const SizedBox(height: 24),
                  if (viewModel.signatureResult != null) ...[
                    const Text('Signature Preview:'),
                    const SizedBox(height: 8),
                    Image.memory(
                      Uri.parse(viewModel.signatureResult!.base64)
                          .data!
                          .contentAsBytes(),
                      height: 120,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
