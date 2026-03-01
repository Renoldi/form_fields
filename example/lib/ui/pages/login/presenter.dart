import 'package:flutter/material.dart' hide View;
import 'package:provider/provider.dart';
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'view_model.dart';
import 'view.dart';

class Presenter extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const Presenter({super.key, required this.onLoginSuccess});

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  Future<void> handleLogin(ViewModel viewModel) async {
    viewModel.clearError();
    if (!mounted) return;

    final appState = context.read<AppStateNotifier>();
    final dialog = BlockingDialog(context);

    dialog.showLoading(message: context.tr('signingIn'));

    try {
      final user = await viewModel.login();
      if (!mounted) return;

      appState.updateUserAfterLogin(user: user);
      dialog.hide();

      if (mounted) widget.onLoginSuccess();
    } catch (error) {
      if (!mounted) return;

      final errorMessage = error.toString().contains('DioException')
          ? context.tr('invalidCredentials')
          : error.toString();

      viewModel.setError(errorMessage);

      dialog.hide();

      await dialog.showResult(
        title: context.tr('loginFailed'),
        message: errorMessage,
        isSuccess: false,
      );
    }
  }

  void handleUsernameChanged(String value, ViewModel viewModel) {
    viewModel.username = value;
    if (viewModel.errorMessage != null) {
      viewModel.clearError();
    }
    viewModel.notify();
  }

  void handlePasswordChanged(String value, ViewModel viewModel) {
    viewModel.password = value;
    if (viewModel.errorMessage != null) {
      viewModel.clearError();
    }
    viewModel.notify();
  }
}
