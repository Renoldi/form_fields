import 'flush_state.dart';

typedef SubmitHandler = Future<bool> Function(
    Map<String, dynamic> payload, int? id);
typedef FlushAllHandler = Future<bool> Function({SubmitHandler? submitHandler});
typedef FlushOneHandler = Future<bool> Function(int id,
    {SubmitHandler? submitHandler});

class FlushApi {
  FlushApi._();

  static FlushAllHandler? _flushAll;
  static FlushOneHandler? _flushOne;

  // Prevent concurrent API-level flush requests from causing duplicate
  // processing. Uses the shared `FlushState` guard in the package.
  // Note: This avoids starting a flush while another is active.

  /// Register example/host implementations.
  static void register({FlushAllHandler? flushAll, FlushOneHandler? flushOne}) {
    _flushAll = flushAll ?? _flushAll;
    _flushOne = flushOne ?? _flushOne;
  }

  /// Call the registered "flush all" implementation.
  static Future<bool> flushPendingSubmissions(
      {SubmitHandler? submitHandler}) async {
    if (FlushState.isFlushing) return false;
    FlushState.isFlushing = true;
    try {
      if (_flushAll != null) {
        return await _flushAll!(submitHandler: submitHandler);
      }
      throw StateError(
          'No flushAll handler registered. Call FlushApi.register(...) from the host/example.');
    } finally {
      FlushState.isFlushing = false;
    }
  }

  /// Call the registered "flush one" implementation.
  static Future<bool> flushPendingSubmissionById(int id,
      {SubmitHandler? submitHandler}) async {
    if (FlushState.isFlushing) return false;
    FlushState.isFlushing = true;
    try {
      if (_flushOne != null) {
        return await _flushOne!(id, submitHandler: submitHandler);
      }
      throw StateError(
          'No flushOne handler registered. Call FlushApi.register(...) from the host/example.');
    } finally {
      FlushState.isFlushing = false;
    }
  }
}
