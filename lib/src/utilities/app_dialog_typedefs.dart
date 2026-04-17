import 'dart:async';
import 'enums.dart';

/// Callback when async task in [guard] succeeds.
typedef AppDialogSuccessCallback<T> = FutureOr<void> Function(T result);

/// Callback when async task in [guard] fails.
typedef AppDialogErrorCallback = FutureOr<void> Function(
    Object error, String message, AppDialogType type);
