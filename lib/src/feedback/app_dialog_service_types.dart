library;

import 'dart:async';

enum AppDialogType {
  validation,
  network,
  authentication,
  server,
}

enum AppDialogPosition {
  top,
  center,
  bottom,
}

enum AppDialogLoadingVisual {
  indicator,
  progress,
  indicatorOnly, // Hanya indikator tanpa background putih dan tanpa text
}

enum AppDialogLoadingBackBehavior {
  block,
  allow,
  confirmCancel,
}

typedef AppDialogErrorMapper = ({String message, AppDialogType type}) Function(
    Object error);

typedef AppDialogCancelRequested = FutureOr<bool> Function();
typedef AppDialogCancelled = FutureOr<void> Function();
