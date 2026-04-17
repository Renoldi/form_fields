import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class ViewModel extends ChangeNotifier {
  AppDialogPosition loadingPosition = AppDialogPosition.top;
  void setLoadingPosition(AppDialogPosition value) {
    loadingPosition = value;
    notifyListeners();
  }

  bool isRunning = false;
  bool simulateError = false;
  bool useBlockingLoading = true;
  AppDialogPosition position = AppDialogPosition.top;
  AppDialogLoadingVisual loadingVisual = AppDialogLoadingVisual.indicator;
  AppDialogLoadingContainer loadingContainer = AppDialogLoadingContainer.card;
  AppLoadingVariant loadingVariant = AppLoadingVariant.spinner;
  AppProgressType progressType = AppProgressType.circular;
  AppDialogLoadingBackBehavior loadingBackBehavior =
      AppDialogLoadingBackBehavior.allow;
  String lastResult = '-';

  void setPosition(AppDialogPosition value) {
    position = value;
    notifyListeners();
  }

  void setLoadingVisual(AppDialogLoadingVisual value) {
    loadingVisual = value;
    notifyListeners();
  }

  void setLoadingContainer(AppDialogLoadingContainer value) {
    loadingContainer = value;
    notifyListeners();
  }

  void setLoadingVariant(AppLoadingVariant value) {
    loadingVariant = value;
    notifyListeners();
  }

  void setProgressType(AppProgressType value) {
    progressType = value;
    notifyListeners();
  }

  void setBlockingLoading(bool value) {
    useBlockingLoading = value;
    notifyListeners();
  }

  void setSimulateError(bool value) {
    simulateError = value;
    notifyListeners();
  }

  void setRunning(bool value) {
    isRunning = value;
    notifyListeners();
  }

  void setLastResult(String value) {
    lastResult = value;
    notifyListeners();
  }

  void setLoadingBackBehavior(AppDialogLoadingBackBehavior value) {
    loadingBackBehavior = value;
    notifyListeners();
  }
}
