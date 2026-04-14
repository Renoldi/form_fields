import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/config/error_position.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/localization/localizations.dart';
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
    viewModel.loadUserData(context.read<AppStateNotifier>());
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> handleUpdateProfile(AppStateNotifier appState) async {
    final dialog = AppGlobalDialogService.instance;

    final isUpdated = await dialog.guard<bool>(
      task: () => _executeProfileUpdate(appState),
      errorTitle: context.tr('updateFailed'),
      mapError: _mapProfileUpdateError,
      position: _toDialogPosition(appState.errorPosition),
      okLabel: context.tr('ok'),
      showBlockingLoading: true,
      loadingMessage: context.tr('updatingProfile'),
    );

    if (!mounted) return;

    if (isUpdated == true) {
      await dialog.showResult(
        isSuccess: true,
        title: context.tr('success'),
        message: context.tr('profileUpdatedSuccessfully'),
        position: _toDialogPosition(appState.errorPosition),
        okLabel: context.tr('ok'),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _executeProfileUpdate(AppStateNotifier appState) async {
    final error = await viewModel.updateProfile(appState);
    if (error != null) {
      throw StateError(error);
    }
    return true;
  }

  ({String message, AppDialogType type}) _mapProfileUpdateError(Object error) {
    final messageKey = error.toString().replaceFirst('Bad state: ', '');

    return (
      message: context.tr(messageKey),
      type: AppDialogType.server,
    );
  }

  AppDialogPosition _toDialogPosition(ErrorPosition position) {
    switch (position) {
      case ErrorPosition.top:
        return AppDialogPosition.top;
      case ErrorPosition.center:
        return AppDialogPosition.center;
      case ErrorPosition.bottom:
        return AppDialogPosition.bottom;
    }
  }
}
