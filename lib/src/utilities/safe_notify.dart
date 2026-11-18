import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Safely notify listeners outside of the build phase.
///
/// If called during a non-idle scheduler phase this will schedule the
/// `notifyListeners()` call for the next frame. This protects callers from
/// triggering "setState() or markNeedsBuild() called during build" errors
/// when a notifier update originates while widgets are being built.
void safeNotify(VoidCallback notifyFn) {
  try {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      notifyFn();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          notifyFn();
        } catch (_) {}
      });
    }
  } catch (_) {
    try {
      notifyFn();
    } catch (_) {}
  }
}
