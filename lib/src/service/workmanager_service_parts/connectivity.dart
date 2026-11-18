part of '../workmanager_service.dart';

extension _WorkmanagerConnectivityX on WorkmanagerService {
  void _startConnectivityFlush() {
    if (_connectivitySub == null) {
      try {
        _connectivitySub = Connectivity().onConnectivityChanged.listen(
          (_) => _flushIfOnline('connectivity'),
        );
      } catch (e) {
        _addLog('connectivity listener failed: $e');
      }
    }
    if (_lifecycleListener == null) {
      try {
        // Timers and connectivity events do not run while the app is in the
        // background, so a resume re-checks pending work as well.
        _lifecycleListener = AppLifecycleListener(
          onResume: () => _flushIfOnline('app resumed'),
        );
      } catch (e) {
        _addLog('lifecycle listener unavailable: $e');
      }
    }
  }
}

extension _WorkmanagerFlushX on WorkmanagerService {
  /// Flushes only when a connection exists. Flushing while offline would
  /// spend retry attempts that cannot succeed.
  Future<void> _flushIfOnline(String reason) async {
    try {
      final current = await Connectivity().checkConnectivity();
      // Offline is "no results" or only ConnectivityResult.none. Compare the
      // enum values directly, not the text of the list.
      final hasNetwork = current.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) return;
      _addLog('$reason: $current -> attempting flush');
      try {
        await foregroundFlushHandler?.call();
      } catch (e) {
        _addLog('flush handler error: $e');
      }
    } catch (_) {}
  }
}
