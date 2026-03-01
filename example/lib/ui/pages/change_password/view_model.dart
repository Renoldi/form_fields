import 'package:flutter/material.dart';

class ChangePasswordResult {
  final bool isSuccess;
  final String message;

  const ChangePasswordResult({
    required this.isSuccess,
    required this.message,
  });
}

class ViewModel extends ChangeNotifier {
  String currentPassword = '';
  String newPassword = '';
  String confirmPassword = '';

  ChangePasswordResult submit() {
    final current = currentPassword.trim();
    final next = newPassword.trim();
    final confirm = confirmPassword.trim();

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

    currentPassword = '';
    newPassword = '';
    confirmPassword = '';
    notifyListeners();

    return const ChangePasswordResult(
      isSuccess: true,
      message: 'Password updated successfully.',
    );
  }
}
