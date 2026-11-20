import 'dart:async';
import 'package:form_fields/src/utilities/enums.dart';

/// Callback when async task in [guard] succeeds.
typedef AppDialogSuccessCallback<T> = FutureOr<void> Function(T result);

/// Callback when async task in [guard] fails.
typedef AppDialogErrorCallback =
    FutureOr<void> Function(Object error, String message, AppDialogType type);

/// Error mapper for AppDialogService
typedef AppDialogErrorMapper =
    ({String message, AppDialogType type, Map<String, List<String>>? details})
    Function(Object error);

/// Callback for cancel requested in dialogs
typedef AppDialogCancelRequested = FutureOr<bool> Function();

/// Callback for dialog cancelled
typedef AppDialogCancelled = FutureOr<void> Function();
