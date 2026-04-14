import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildLoginCard(viewModel),
                ),
              ),
              if (viewModel.isLoading &&
                  !viewModel.useBlockingLoadingDialog) ...[
                const Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: Color(0x66000000),
                  ),
                ),
                const Positioned.fill(
                  child: Center(
                    child: AppLoadingIndicator(
                      variant: AppLoadingVariant.spinner,
                      size: 42,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginCard(ViewModel viewModel) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildUsernameField(viewModel),
            const SizedBox(height: 16),
            _buildPasswordField(viewModel),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorMessage(viewModel.errorMessage!),
            ],
            const SizedBox(height: 20),
            _buildLoginButton(viewModel),
            const SizedBox(height: 8),
            _buildHintText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock, size: 48, color: Color(0xFF1F2937)),
        const SizedBox(height: 12),
        Text(
          context.tr('login'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField(ViewModel viewModel) {
    return FormFields<String>(
      label: context.tr('username'),
      currrentValue: viewModel.username,
      formType: FormType.string,
      prefixIcon: const Icon(Icons.person),
      onChanged: (value) => handleUsernameChanged(value, viewModel),
    );
  }

  Widget _buildPasswordField(ViewModel viewModel) {
    return FormFields<String>(
      label: context.tr('password'),
      currrentValue: viewModel.password,
      formType: FormType.password,
      minLengthPassword: 4,
      prefixIcon: const Icon(Icons.lock_outline),
      onChanged: (value) => handlePasswordChanged(value, viewModel),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Text(
      message,
      style: const TextStyle(color: Colors.red),
    );
  }

  Widget _buildLoginButton(ViewModel viewModel) {
    return AppButton(
      type: AppButtonType.elevated,
      size: AppButtonSize.medium,
      text: context.tr('login'),
      isLoading: false,
      onPressed: (!viewModel.canSubmit || viewModel.isLoading)
          ? null
          : () => handleLogin(viewModel),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildHintText() {
    return const Text(
      'Use username: emilys | password: emilyspass',
      style: TextStyle(fontSize: 12, color: Colors.black54),
    );
  }
}
