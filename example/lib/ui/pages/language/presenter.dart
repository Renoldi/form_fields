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
  void handleSetEnglish(main.ViewModel viewModel) {
    viewModel.setEnglish();
  }

  void handleSetIndonesian(main.ViewModel viewModel) {
    viewModel.setIndonesian();
  }
}
