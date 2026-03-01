import 'package:flutter/material.dart' hide View;
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';
import 'main.dart';

class View extends StatefulWidget {
  final VoidCallback onBack;

  const View({
    super.key,
    required this.onBack,
  });

  @override
  State<View> createState() => ViewState();
}

abstract class PresenterState extends State<View> {
  ViewModel viewModel = ViewModel();

  @override
  void initState() {
    super.initState();
    viewModel = ViewModel();
    viewModel.loadUserData(context.read<AppStateNotifier>());
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> handleUpdateProfile(AppStateNotifier appState) async {
    final dialog = BlockingDialog(context);

    dialog.showLoading(
      message: context.tr('updatingProfile'),
    );

    final error = await viewModel.updateProfile(appState);
    if (!mounted) return;

    dialog.hide();
    if (error == null) {
      await dialog.showResult(
        isSuccess: true,
        title: context.tr('success'),
        message: context.tr('profileUpdatedSuccessfully'),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      await dialog.showResult(
        isSuccess: false,
        title: context.tr('updateFailed'),
        message: error,
      );
    }
  }
}
