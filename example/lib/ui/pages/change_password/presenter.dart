import 'package:flutter/material.dart';
import 'main.dart' as main;

class Presenter extends StatefulWidget {
  final VoidCallback onBack;

  const Presenter({
    super.key,
    required this.onBack,
  });

  @override
  State<Presenter> createState() => main.View();
}

abstract class PresenterState extends State<Presenter> {
  late final main.ViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = main.ViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  void handleSubmit() {
    final result = viewModel.submit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }
}
