import 'package:flutter/material.dart';
import 'main.dart' as main;

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => main.View();
}

abstract class PresenterState extends State<Presenter> {
  void handleValidateForm(main.ViewModel viewModel) {
    if (!viewModel.formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form validated')),
    );
  }
}
