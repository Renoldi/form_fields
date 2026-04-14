import 'package:flutter/material.dart' hide View;
import 'package:form_fields/form_fields.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:form_fields_example/config/error_position.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/config/error_type.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/data/services/http_service.dart';
import 'view_model.dart';
import 'view.dart';

final Logger _logger = Logger();

class Presenter extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const Presenter({super.key, required this.onLoginSuccess});

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  Future<void> handleLogin(ViewModel viewModel) async {
    if (!_canStartLogin(viewModel)) return;

    viewModel.clearError();
    viewModel.setLoading(true);

    final appState = context.read<AppStateNotifier>();

    try {
      final user = await _executeLogin(
        viewModel: viewModel,
        position: _toDialogPosition(appState.errorPosition),
      );

      if (!mounted || user == null) return;

      appState.updateUserAfterLogin(user: user);
      widget.onLoginSuccess();
    } finally {
      viewModel.setLoading(false);
    }
  }

  bool _canStartLogin(ViewModel viewModel) {
    return mounted && !viewModel.isLoading;
  }

  Future<User?> _executeLogin({
    required ViewModel viewModel,
    required AppDialogPosition position,
  }) {
    return AppGlobalDialogService.instance.guard(
      task: viewModel.login,
      errorTitle: context.tr('loginFailed'),
      mapError: (error) => _handleLoginError(error, viewModel),
      position: position,
      okLabel: context.tr('ok'),
      showBlockingLoading: viewModel.useBlockingLoadingDialog,
      loadingMessage: context.tr('signingIn'),
    );
  }

  ({String message, AppDialogType type}) _handleLoginError(
    Object error,
    ViewModel viewModel,
  ) {
    final mappedError = _mapLoginError(error);
    viewModel.setError(mappedError.message, type: mappedError.type);
    return (
      message: mappedError.message,
      type: _toDialogType(mappedError.type),
    );
  }

  void handleUsernameChanged(String value, ViewModel viewModel) {
    viewModel.updateUsername(value);
  }

  void handlePasswordChanged(String value, ViewModel viewModel) {
    viewModel.updatePassword(value);
  }

  ({String message, ErrorType type}) _mapLoginError(Object error) {
    if (error is HttpException) {
      return (message: context.tr(error.messageKey), type: error.type);
    }

    _logger.e('Login failed (unexpected): $error');

    return (
      message: context.tr('errorLoginTemporarilyUnavailable'),
      type: ErrorType.server,
    );
  }

  AppDialogType _toDialogType(ErrorType type) {
    switch (type) {
      case ErrorType.validation:
        return AppDialogType.validation;
      case ErrorType.network:
        return AppDialogType.network;
      case ErrorType.authentication:
        return AppDialogType.authentication;
      case ErrorType.server:
        return AppDialogType.server;
    }
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
