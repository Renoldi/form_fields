import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class ViewModel extends ChangeNotifier {
  MyimageResult? signatureResult;

  void setSignature(MyimageResult? result) {
    signatureResult = result;
    notifyListeners();
  }
}
