import 'package:flutter/material.dart';

class ChangePasswordResult {
  final bool isSuccess;
  final String messageKey;

  const ChangePasswordResult({
    required this.isSuccess,
    required this.messageKey,
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
        messageKey: 'errorChangePasswordFillAllFields',
      );
    }
    if (next.length < 6) {
      return const ChangePasswordResult(
        isSuccess: false,
        messageKey: 'errorChangePasswordMinLength',
      );
    }
    if (next != confirm) {
      return const ChangePasswordResult(
        isSuccess: false,
        messageKey: 'errorChangePasswordMismatch',
      );
    }

    currentPassword = '';
    newPassword = '';
    confirmPassword = '';
    notifyListeners();

    return const ChangePasswordResult(
      isSuccess: true,
      messageKey: 'changePasswordUpdatedSuccessfully',
    );
  }
}
