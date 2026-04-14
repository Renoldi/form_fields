import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {
  bool isSubmitting = false;

  Future<void> submit() async {
    isSubmitting = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(seconds: 2));

    isSubmitting = false;
    notifyListeners();
  }
}
