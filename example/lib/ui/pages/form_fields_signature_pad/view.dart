import 'package:flutter/material.dart';
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
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FormFieldsSignaturePad(
                    onExported: viewModel.setSignature,
                    backgroundColor: Colors.white,
                    exportBackgroundColor: Colors.transparent,
                  ),
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
                        '{\n  "onExported": "(result) => setSignature(result)",\n  "backgroundColor": "Colors.transparent",\n  "exportBackgroundColor": "Colors.transparent"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
