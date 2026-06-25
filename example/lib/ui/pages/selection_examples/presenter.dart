import 'package:flutter/material.dart' hide View;
import 'view.dart';
import 'view_model.dart';

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  void handleValidateForm(SelectionExamplesViewModel viewModel) {
    if (viewModel.formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form validated')),
      );
    }
  }
}
