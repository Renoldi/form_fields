import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'view_model.dart';
import 'presenter.dart';

class BarcodeScanView extends State<BarcodeScanPresenter> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BarcodeScanViewModel>(
      create: (_) => BarcodeScanViewModel(),
      child: Consumer<BarcodeScanViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Barcode Scan Example')),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormFieldsBarcodeScan(
                      label: 'Scan Barcode',
                      currentValue: viewModel.barcode,
                      isRequired: true,
                      onChanged: (value) {
                        viewModel.setBarcode(value);
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Barcode: "+viewModel.barcode!+"')),
                          );
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
