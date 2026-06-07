import 'package:flutter/material.dart';

class ListDataExamplesViewModel extends ChangeNotifier {
  String? search;
  String? selectedItem;

  void updateSearch(String? value) {
    if (search != value) {
      search = value;
      notifyListeners();
    }
  }

  void selectItem(String? item) {
    if (selectedItem != item) {
      selectedItem = item;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (selectedItem != null) {
      selectedItem = null;
      notifyListeners();
    }
  }
}
