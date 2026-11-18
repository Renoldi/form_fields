import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:form_fields/src/utilities/safe_notify.dart';

/// Shared base for every [ChangeNotifier] in the package.
///
/// It gives providers, controllers, and notifiers the same two ways to notify:
///
/// - [notifySafely] notifies now, or after the current frame when called during
///   a build. This is the rule [safeNotify] already enforces.
/// - [scheduleNotify] is debounced. A burst of mutations collapses into one
///   notification, sent [notifyDebounce] after the last call.
///
/// [dispose] cancels a pending debounced notification.
abstract class FormFieldsChangeNotifier extends ChangeNotifier {
  Timer? _notifyTimer;

  /// How long [scheduleNotify] waits after the last call before notifying.
  Duration get notifyDebounce => const Duration(milliseconds: 120);

  /// Notifies listeners without triggering "setState during build" errors.
  void notifySafely() => safeNotify(notifyListeners);

  /// Notifies once, [notifyDebounce] after the last call. Falls back to an
  /// immediate notification if the timer cannot be created.
  void scheduleNotify() {
    try {
      _notifyTimer?.cancel();
      _notifyTimer = Timer(notifyDebounce, () {
        _notifyTimer = null;
        notifySafely();
      });
    } catch (_) {
      notifySafely();
    }
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    super.dispose();
  }
}

/// Upload progress for a single captured or drawn image.
///
/// Shared by the single-capture fields ([FormFieldsLiveCameraCaptureProvider]
/// and [FormFieldsSignaturePadProvider]) so both follow the same lifecycle:
///
/// 1. [startUpload] with a small non-zero value, so the overlay is visible at once.
/// 2. [setUploadProgress] while the request is in flight.
/// 3. [completeUpload] on success, or [clearUpload] when the upload is not sent.
///
/// `null` means no upload is running. Any value other than `null` means
/// [isUploading] is `true`.
mixin FormFieldsUploadProgressMixin on FormFieldsChangeNotifier {
  double? _uploadProgress;

  /// Current progress in the range 0.0 to 1.0, or `null` when idle.
  double? get uploadProgress => _uploadProgress;

  /// Whether an upload is running.
  bool get isUploading => _uploadProgress != null;

  /// Starts an upload, optionally with an initial progress value.
  void startUpload({double? initialProgress}) {
    _uploadProgress = initialProgress;
    notifySafely();
  }

  /// Sets the progress, clamped to the range 0.0 to 1.0.
  void setUploadProgress(double progress) {
    _uploadProgress = progress.clamp(0.0, 1.0);
    notifySafely();
  }

  /// Marks the upload as finished at 100%.
  void completeUpload() {
    _uploadProgress = 1.0;
    notifySafely();
  }

  /// Stops the upload and hides the progress overlay.
  void clearUpload() {
    _uploadProgress = null;
    notifySafely();
  }
}

/// A callback that an attached widget registers on a controller (for example
/// its capture or clear action), and that the controller invokes on request.
///
/// Holds at most one handler. [register] replaces it and [unregister] clears
/// it, which the widget does when it is disposed.
class FormFieldsHandlerSlot<T extends Function> {
  T? _handler;

  /// The registered handler, or `null` when no widget is attached.
  T? get handler => _handler;

  /// Registers [handler], replacing any previous one.
  void register(T handler) => _handler = handler;

  /// Removes the handler.
  void unregister() => _handler = null;
}
