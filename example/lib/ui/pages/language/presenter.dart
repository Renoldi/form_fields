import 'package:flutter/material.dart' hide View;
import 'view_model.dart';
import 'view.dart';

class Presenter extends StatefulWidget {
  final VoidCallback onBack;

  const Presenter({
    super.key,
    required this.onBack,
  });

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  void handleSetEnglish(ViewModel viewModel) {
    viewModel.setEnglish();
  }

  void handleSetIndonesian(ViewModel viewModel) {
    viewModel.setIndonesian();
  }
}
