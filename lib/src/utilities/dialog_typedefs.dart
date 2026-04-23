library;

import 'package:form_fields/src/utilities/enums.dart';
import 'dart:async';

/// Error mapper for AppDialogService
typedef AppDialogErrorMapper = ({
  String message,
  AppDialogType type,
  Map<String, List<String>>? details
})
    Function(Object error);

/// Callback for cancel requested in dialogs
typedef AppDialogCancelRequested = FutureOr<bool> Function();

/// Callback for dialog cancelled
typedef AppDialogCancelled = FutureOr<void> Function();
