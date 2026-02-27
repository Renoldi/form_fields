import 'package:flutter/material.dart';

class ChangePasswordResult {
  final bool isSuccess;
  final String message;

  const ChangePasswordResult({
    required this.isSuccess,
    required this.message,
  });
}

class ChangePasswordViewModel extends ChangeNotifier {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  ChangePasswordResult submit() {
    final current = currentPasswordController.text.trim();
    final next = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      return const ChangePasswordResult(
        isSuccess: false,
        message: 'Please fill all password fields.',
      );
    }
    if (next.length < 6) {
      return const ChangePasswordResult(
        isSuccess: false,
        message: 'New password must be at least 6 characters.',
      );
    }
    if (next != confirm) {
      return const ChangePasswordResult(
        isSuccess: false,
        message: 'New password and confirmation do not match.',
      );
    }

    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();

    return const ChangePasswordResult(
      isSuccess: true,
      message: 'Password updated successfully.',
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
