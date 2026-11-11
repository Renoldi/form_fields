import 'package:flutter/foundation.dart';

/// Writes [message] to the console in debug builds only.
///
/// Use this instead of `debugPrint`. `debugPrint` also runs in release builds,
/// and these messages can contain file paths, links and payload details.
void debugLog(String? message) {
  if (kDebugMode) debugPrint(message);
}
