import 'package:flutter/material.dart';
import 'package:form_fields_example/data/models/user.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';

class ProfileViewModel extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void loadUserData(AppStateNotifier appState) {
    final user = appState.currentUser;
    if (user == null) return;

    firstNameController.text = user.firstName ?? '';
    lastNameController.text = user.lastName ?? '';
    emailController.text = user.email ?? '';
    usernameController.text = user.username ?? '';
  }

  Future<String?> updateProfile(AppStateNotifier appState) async {
    if (!formKey.currentState!.validate()) {
      return 'Please fix the validation errors.';
    }

    final accessToken = appState.accessToken;
    if (accessToken.isEmpty) {
      return 'No access token found';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = appState.currentUser;
      final userToUpdate = User(
        id: currentUser?.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        username: usernameController.text.trim(),
        image: currentUser?.image,
        accessToken: currentUser?.accessToken,
        refreshToken: currentUser?.refreshToken,
      );

      await User.updateMe(
        accessToken: accessToken,
        user: userToUpdate,
      );

      final freshUser = await User.getMe(accessToken: accessToken);
      appState.updateUserData(freshUser);
      return null;
    } catch (error) {
      return 'Failed to update profile: ${error.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    super.dispose();
  }
}
