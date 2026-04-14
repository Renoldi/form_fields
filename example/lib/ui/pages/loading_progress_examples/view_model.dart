import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {
  bool isSimulating = false;
  double progress = 0.18;

  Future<void> simulateProgress() async {
    if (isSimulating) return;

    isSimulating = true;
    progress = 0.0;
    notifyListeners();

    for (var i = 1; i <= 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 170));
      progress = i / 12;
      notifyListeners();
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    isSimulating = false;
    notifyListeners();
  }
}
