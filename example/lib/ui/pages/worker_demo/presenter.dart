import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
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
  VoidCallback? _workmanagerLogListener;

  @override
  void initState() {
    super.initState();
    viewModel = ViewModel();
    // Load pending items once on init
    viewModel.loadPending();
    // Listen for explicit pending-change notifications and refresh the list.
    try {
      _workmanagerLogListener = () {
        try {
          viewModel.loadPending();
        } catch (_) {}
      };
      WorkmanagerService.instance.pendingChangedListenable
          .addListener(_workmanagerLogListener!);
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      if (_workmanagerLogListener != null) {
        WorkmanagerService.instance.pendingChangedListenable
            .removeListener(_workmanagerLogListener!);
        _workmanagerLogListener = null;
      }
    } catch (_) {}
    viewModel.dispose();
    super.dispose();
  }
}
