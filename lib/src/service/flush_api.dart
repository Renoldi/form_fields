import 'flush_state.dart';
import 'package:logging/logging.dart';

final _log = Logger('FlushApi');

typedef SubmitHandler = Future<bool> Function(
    Map<String, dynamic> payload, int? id);
typedef FlushAllHandler = Future<bool> Function({
  SubmitHandler? submitHandler,
  // When true the implementation should not perform its own FlushState
  // guard because the caller (FlushApi) will have already acquired the
  // shared `FlushState` lock.
  bool skipFlushStateGuard,
});
typedef FlushOneHandler = Future<bool> Function(int id,
    {SubmitHandler? submitHandler, required bool skipFlushStateGuard});

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
  /// Attempt to run the registered "flush all" handler.
  ///
  /// If [waitIfFlushing] is true the method will wait until any currently
  /// active flush completes (up to [waitTimeout]) and then acquire the
  /// shared `FlushState` lock before invoking the registered handler.
  /// Otherwise, the call returns immediately with `false` when a flush is
  /// already active.
  static Future<bool> flushPendingSubmissions({
    SubmitHandler? submitHandler,
    bool waitIfFlushing = false,
    Duration? waitTimeout,
  }) async {
    // Attempt to acquire the shared lock. Optionally wait for it.
    final deadline =
        waitTimeout == null ? null : DateTime.now().add(waitTimeout);
    while (true) {
      if (!FlushState.isFlushing) {
        FlushState.isFlushing = true;
        break;
      }
      if (!waitIfFlushing) return false;
      if (deadline != null && DateTime.now().isAfter(deadline)) return false;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      if (_flushAll != null) {
        _log.fine('Invoking registered flushAll handler (skip guard)');
        // Registered handlers are expected to accept a `skipFlushStateGuard`
        // flag so the API-level lock isn't doubled.
        return await _flushAll!(
            submitHandler: submitHandler, skipFlushStateGuard: true);
      }
      _log.warning(
          'No flushAll handler registered when flushPendingSubmissions called');
      throw StateError(
          'No flushAll handler registered. Call FlushApi.register(...) from the host/example.');
    } finally {
      FlushState.isFlushing = false;
    }
  }

  /// Call the registered "flush one" implementation.
  static Future<bool> flushPendingSubmissionById(int id,
      {SubmitHandler? submitHandler,
      bool waitIfFlushing = false,
      Duration? waitTimeout}) async {
    final deadline =
        waitTimeout == null ? null : DateTime.now().add(waitTimeout);
    while (true) {
      if (!FlushState.isFlushing) {
        FlushState.isFlushing = true;
        break;
      }
      if (!waitIfFlushing) return false;
      if (deadline != null && DateTime.now().isAfter(deadline)) return false;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      if (_flushOne != null) {
        _log.fine(
            'Invoking registered flushOne handler for id=$id (skip guard)');
        return await _flushOne!(id,
            submitHandler: submitHandler, skipFlushStateGuard: true);
      }
      _log.warning(
          'No flushOne handler registered when flushPendingSubmissionById called (id=$id)');
      throw StateError(
          'No flushOne handler registered. Call FlushApi.register(...) from the host/example.');
    } finally {
      FlushState.isFlushing = false;
    }
  }
}
