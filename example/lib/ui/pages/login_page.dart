import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields/form_fields.dart';
import '../../data/models/user.dart';
import '../../state/notifiers/app_state_notifier.dart';
import '../widgets/blocking_dialogs.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginFormNotifier _formNotifier = LoginFormNotifier();

  @override
  void dispose() {
    _formNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _formNotifier,
      child: Consumer<LoginFormNotifier>(
        builder: (context, formState, _) {
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
                        currrentValue: formState.username,
                        formType: FormType.string,
                        prefixIcon: const Icon(Icons.person),
                        onChanged: (value) {
                          formState.setUsername(value);
                          if (formState.errorMessage != null) {
                            formState.clearError();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      FormFields<String>(
                        label: 'Password',
                        currrentValue: formState.password,
                        formType: FormType.password,
                        minLengthPassword: 4,
                        prefixIcon: const Icon(Icons.lock_outline),
                        onChanged: (value) {
                          formState.setPassword(value);
                          if (formState.errorMessage != null) {
                            formState.clearError();
                          }
                        },
                      ),
                      if (formState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          formState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: formState.canSubmit
                              ? () async {
                                  formState.clearError();

                                  if (!mounted) return;
                                  final appState =
                                      context.read<AppStateNotifier>();

                                  showBlockingLoading(
                                    context,
                                    message: 'Signing in...',
                                  );

                                  try {
                                    // Call User.login() directly
                                    final user = await User.login(
                                      username: formState.username.trim(),
                                      password: formState.password.trim(),
                                    );

                                    if (!context.mounted) return;

                                    // Update app state with logged in user
                                    appState.updateUserAfterLogin(
                                      user: user,
                                      username: formState.username.trim(),
                                      password: formState.password.trim(),
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

                                    formState.setError(errorMessage);

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

class LoginFormNotifier extends ChangeNotifier {
  String? _errorMessage;
  final bool _isSubmitting = false;
  String _username = '';
  String _password = '';

  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  String get username => _username;
  String get password => _password;

  /// Returns true if the form is valid and can be submitted
  bool get canSubmit =>
      !_isSubmitting &&
      _username.trim().isNotEmpty &&
      _password.trim().isNotEmpty;

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setUsername(String value) {
    if (_username == value) return;
    _username = value;
    notifyListeners();
  }

  void setPassword(String value) {
    if (_password == value) return;
    _password = value;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
