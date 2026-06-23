import 'package:logger/logger.dart';
import 'package:form_fields/form_fields.dart';

final Logger _pendingLogger = Logger();

/// Insert a generic payload into `pending_submissions` and notify listeners.
/// Returns the inserted row id or -1 on failure.
Future<int> addPendingSubmission(Map<String, dynamic> payload,
    {String status = 'pending'}) async {
  try {
    final values = <String, dynamic>{'payload': payload, 'status': status};
    final id = await DBService.instance.insert('pending_submissions', values);
    try {
      ForegroundTaskService.instance.notifyPendingChanged();
    } catch (_) {}
    _pendingLogger.i(
        'addPendingSubmission inserted id=$id payloadType=${payload['type'] ?? '-'}');
    return id;
  } catch (e, st) {
    _pendingLogger.w('addPendingSubmission failed: $e\n$st');
    return -1;
  }
}
