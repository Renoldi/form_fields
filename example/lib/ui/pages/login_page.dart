import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/state/pages/login_view_model.dart';
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Logic Methods
  Future<void> _handleLogin(LoginViewModel viewModel) async {
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

  void _onUsernameChanged(String value, LoginViewModel viewModel) {
    viewModel.username = value;
    if (viewModel.errorMessage != null) {
      viewModel.clearError();
    }
    viewModel.notify();
  }

  void _onPasswordChanged(String value, LoginViewModel viewModel) {
    viewModel.password = value;
    if (viewModel.errorMessage != null) {
      viewModel.clearError();
    }
    viewModel.notify();
  }

  // View Methods
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildLoginCard(viewModel),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginCard(LoginViewModel viewModel) {
    return Container(
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

  Widget _buildUsernameField(LoginViewModel viewModel) {
    return FormFields<String>(
      label: context.tr('username'),
      currrentValue: viewModel.username,
      formType: FormType.string,
      prefixIcon: const Icon(Icons.person),
      onChanged: (value) => _onUsernameChanged(value, viewModel),
    );
  }

  Widget _buildPasswordField(LoginViewModel viewModel) {
    return FormFields<String>(
      label: context.tr('password'),
      currrentValue: viewModel.password,
      formType: FormType.password,
      minLengthPassword: 4,
      prefixIcon: const Icon(Icons.lock_outline),
      onChanged: (value) => _onPasswordChanged(value, viewModel),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Text(
      message,
      style: const TextStyle(color: Colors.red),
    );
  }

  Widget _buildLoginButton(LoginViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.canSubmit ? () => _handleLogin(viewModel) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F2937),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(context.tr('login')),
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
