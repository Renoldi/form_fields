import 'package:connectivity_plus/connectivity_plus.dart';

/// Returns `true` when the device reports at least one usable connection.
///
/// Offline means the connectivity check returned no results, or only
/// [ConnectivityResult.none]. Any error while checking is treated as offline
/// so callers can fall back to their offline/queued path.
Future<bool> isNetworkAvailable() async {
  try {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  } catch (_) {
    return false;
  }
}
