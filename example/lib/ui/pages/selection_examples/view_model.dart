import 'package:flutter/material.dart';

class SelectionExamplesViewModel extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool? checkboxValue = false;
  bool switchValue = false;
  String listTileResult = '';
  int? rating;
  int? ratingCustom;
  // grouped selection state
  List<String> checkboxListSelected = [];
  String? radioSelected;

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

  void setRatingCustom(int v) {
    ratingCustom = v;
    notifyListeners();
  }

  void setCheckboxList(List<String> v) {
    checkboxListSelected = v;
    notifyListeners();
  }

  void setRadio(String? v) {
    radioSelected = v;
    notifyListeners();
  }

  void reset() {
    checkboxValue = false;
    switchValue = false;
    listTileResult = '';
    rating = null;
    ratingCustom = null;
    checkboxListSelected = [];
    radioSelected = null;
    notifyListeners();
  }
}
