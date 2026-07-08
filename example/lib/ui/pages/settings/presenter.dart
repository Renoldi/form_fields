import 'package:flutter/material.dart';
import 'main.dart' as main;

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
  State<Presenter> createState() => main.View();
}

abstract class PresenterState extends State<Presenter> {
  void handleLogout(main.ViewModel viewModel) {
    viewModel.logout(widget.onLogout);
  }
}
