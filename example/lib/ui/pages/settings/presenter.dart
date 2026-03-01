import 'package:flutter/material.dart' hide View;
import 'view_model.dart';
import 'view.dart';

class Presenter extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenChangePassword;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAppInfo;

  const Presenter({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.onOpenProfile,
    required this.onOpenChangePassword,
    required this.onOpenLanguage,
    required this.onOpenAppInfo,
  });

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  void handleLogout(ViewModel viewModel) {
    viewModel.logout(widget.onLogout);
  }
}
