import 'package:flutter/material.dart' hide View;
import 'package:provider/provider.dart';
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/config/error_type.dart';
import 'package:form_fields_example/data/services/http_service.dart';
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
    if (viewModel.isLoading) return;

    viewModel.clearError();
    viewModel.setLoading(true);
    if (!mounted) return;

    final appState = context.read<AppStateNotifier>();
    final dialog = BlockingDialog(context);

    // Don't await - let dialog show while we process login
    dialog.showLoading(message: context.tr('signingIn'));

    try {
      final user = await viewModel.login();
      if (!mounted) return;

      appState.updateUserAfterLogin(user: user);
      dialog.hide();

      if (mounted) widget.onLoginSuccess();
    } catch (error) {
      if (!mounted) return;

      dialog.hide();

      // HttpException includes error type + message from http_service
      if (error is HttpException) {
        viewModel.setError(error.message, type: error.type);
        await dialog.showError(
          title: context.tr('loginFailed'),
          message: error.message,
          errorType: error.type,
          errorPosition: appState.errorPosition,
        );
      } else {
        // Fallback for unexpected errors
        final message = error.toString();
        viewModel.setError(message, type: ErrorType.server);
        await dialog.showError(
          title: context.tr('loginFailed'),
          message: message,
          errorType: ErrorType.server,
          errorPosition: appState.errorPosition,
        );
      }
    } finally {
      viewModel.setLoading(false);
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
