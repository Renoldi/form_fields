import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/state/pages/login_view_model.dart';
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                      const Icon(Icons.lock,
                          size: 48, color: Color(0xFF1F2937)),
                      const SizedBox(height: 12),
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FormFields<String>(
                        label: 'Username',
                        currrentValue: viewModel.username,
                        formType: FormType.string,
                        prefixIcon: const Icon(Icons.person),
                        onChanged: (value) {
                          viewModel.setUsername(value);
                          if (viewModel.errorMessage != null) {
                            viewModel.clearError();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      FormFields<String>(
                        label: 'Password',
                        currrentValue: viewModel.password,
                        formType: FormType.password,
                        minLengthPassword: 4,
                        prefixIcon: const Icon(Icons.lock_outline),
                        onChanged: (value) {
                          viewModel.setPassword(value);
                          if (viewModel.errorMessage != null) {
                            viewModel.clearError();
                          }
                        },
                      ),
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: viewModel.canSubmit
                              ? () async {
                                  viewModel.clearError();

                                  if (!mounted) return;
                                  final appState =
                                      context.read<AppStateNotifier>();

                                  showBlockingLoading(
                                    context,
                                    message: 'Signing in...',
                                  );

                                  try {
                                    final user = await viewModel.login();

                                    if (!context.mounted) return;

                                    // Update app state with logged in user
                                    appState.updateUserAfterLogin(
                                      user: user,
                                      username: viewModel.username.trim(),
                                      password: viewModel.password.trim(),
                                    );

                                    if (!context.mounted) return;
                                    hideBlockingDialog(context);

                                    if (!context.mounted) return;
                                    widget.onLoginSuccess();
                                  } catch (error) {
                                    if (!context.mounted) return;

                                    hideBlockingDialog(context);

                                    final errorMessage = error
                                            .toString()
                                            .contains('DioException')
                                        ? 'Invalid username or password'
                                        : error.toString();

                                    viewModel.setError(errorMessage);

                                    if (!context.mounted) return;
                                    await showBlockingResult(
                                      context,
                                      title: 'Login Failed',
                                      message: errorMessage,
                                      isSuccess: false,
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2937),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use username: emilys | password: emilyspass',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
