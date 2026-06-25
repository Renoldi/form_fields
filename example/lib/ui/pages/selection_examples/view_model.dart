import 'package:flutter/material.dart';

class SelectionExamplesViewModel extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool? checkboxValue = false;
  bool switchValue = false;
  String listTileResult = '';
  int rating = 0;

  void setCheckbox(bool? v) {
    checkboxValue = v;
    notifyListeners();
  }

  void setSwitch(bool v) {
    switchValue = v;
    notifyListeners();
  }

  void setListTile(String v) {
    listTileResult = v;
    notifyListeners();
  }

  void setRating(int v) {
    rating = v;
    notifyListeners();
  }

  void reset() {
    checkboxValue = false;
    switchValue = false;
    listTileResult = '';
    rating = 0;
    notifyListeners();
  }
}
