import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/data/services/http_service.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';

final Logger _logger = Logger();

class ViewModel extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late User user;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void loadUserData(AppStateNotifier appState) {
    final currentUser = appState.currentUser;
    if (currentUser == null) return;
    user = currentUser;
  }

  Future<String?> updateProfile(AppStateNotifier appState) async {
    if (!formKey.currentState!.validate()) {
      return 'errorFixValidationIssues';
    }

    final accessToken = appState.accessToken;
    if (accessToken.isEmpty) {
      return 'errorNoAccessToken';
    }

    _isLoading = true;
    notifyListeners();

    try {
      await User.updateMe(
        accessToken: accessToken,
        user: user.copyWith(
          firstName: user.firstName?.trim(),
          lastName: user.lastName?.trim(),
          email: user.email?.trim(),
        ),
      );

      final freshUser = await User.getMe(accessToken: accessToken);
      appState.updateUserData(freshUser);
      user = freshUser;
      return null;
    } catch (error, stackTrace) {
      _logger.e('Profile update failed: $error');
      _logger.d(stackTrace.toString());

      if (error is HttpException) {
        return error.messageKey;
      }

      return 'errorUpdateProfileTemporarilyUnavailable';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
