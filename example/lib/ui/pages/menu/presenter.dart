import 'package:flutter/material.dart' hide View;
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'view_model.dart';
import 'view.dart';

class Presenter extends StatefulWidget {
  final VoidCallback onLogout;
  final void Function(String routeName) onMenuItemTap;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onOpenProfile;

  const Presenter({
    super.key,
    required this.onLogout,
    required this.onMenuItemTap,
    required this.onOpenSettings,
    required this.onOpenProfile,
  });

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  late final ViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ViewModel(context.read<AppStateNotifier>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.loadUser();
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> handleOpenProfile() async {
    await widget.onOpenProfile();
    if (!mounted) return;
    final error = await viewModel.loadUser(forceRefresh: true);
    if (error != null) {
      if (!mounted) return;
      await BlockingDialog(context).showResult(
        title: context.tr('loadFailed'),
        message: error,
        isSuccess: false,
      );
    }
  }

  void handleLogout() {
    viewModel.appState.logout();
    widget.onLogout();
  }

  Future<void> handleOpenSettings() async {
    await widget.onOpenSettings();
  }

  void handleMenuItemTap(String routeName) {
    widget.onMenuItemTap(routeName);
  }
}
