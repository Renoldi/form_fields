import 'package:flutter/material.dart';

class BarcodeScanViewModel extends ChangeNotifier {
  String? barcode;

  void setBarcode(String? value) {
    barcode = value;
    notifyListeners();
  }
}
