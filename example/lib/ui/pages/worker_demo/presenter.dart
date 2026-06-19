import 'package:flutter/material.dart';
import 'view_model.dart';
import 'view.dart' as worker_view;

class Presenter extends StatefulWidget {
  final VoidCallback onBack;

  const Presenter({super.key, required this.onBack});

  @override
  State<Presenter> createState() => worker_view.View();
}

abstract class PresenterState extends State<Presenter> {
  late final ViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ViewModel();
    // Load pending items once on init
    viewModel.loadPending();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}
