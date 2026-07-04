import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';

/// A persistent controller provider for `MapController` instances.
/// Controllers are keyed by an `id` so they are not recreated on widget rebuilds.
class FormFieldsMapController {
  static final Map<String, MapController> _controllers = {};

  // Optional ValueNotifiers to represent loading state per controller id.
  static final Map<String, ValueNotifier<bool>> _loadingNotifiers = {};
  // Optional global handlers for marker taps keyed by controller id. This
  // allows external marker widgets to invoke the map-level `onMarkerTap`
  // callback by calling `invokeOnMarkerTap` with the controller id.
  static final Map<String, ValueChanged<ShapeMeta>?> _onMarkerTapHandlers = {};
  // Timestamp of last invoke per controller id to suppress rapid duplicate
  static final Map<String, DateTime?> _lastInvokeAt = {};

  /// Returns an existing controller for [id], or creates one if missing.
  static MapController getOrCreate(String id) {
    return _controllers.putIfAbsent(id, () => MapController());
  }

  /// Returns a `ValueListenable<bool>` representing the loading state for
  /// the controller with [id]. The notifier is created on demand and shared
  /// so callers can observe or set loading state across widgets and viewmodels.
  static ValueListenable<bool> getLoadingListenable(String id) {
    return _loadingNotifiers.putIfAbsent(id, () => ValueNotifier<bool>(false));
  }

  /// Convenience setter to change the loading value for [id].
  static void setLoading(String id, bool value) {
    _loadingNotifiers.putIfAbsent(id, () => ValueNotifier<bool>(false)).value =
        value;
  }

  /// Register a handler to be invoked when a marker is tapped. The map
  /// widget will call this during init and update, and it will be removed
  /// when the widget disposes.
  static void registerOnMarkerTap(String id, ValueChanged<ShapeMeta>? handler) {
    _onMarkerTapHandlers[id] = handler;
    if (handler == null) {
      // allow explicit unregistering
    } else {
      // registering handler (silent)
    }
  }

  /// Invoke the registered `onMarkerTap` handler (if any) for [id]. This
  /// is safe to call from anywhere (e.g., marker widget tap callbacks).
  static void invokeOnMarkerTap(String id, ShapeMeta payload) {
    final handler = _onMarkerTapHandlers[id];
    if (handler == null) {
      return;
    }

    // suppress duplicate invocations within a short window
    final now = DateTime.now();
    final last = _lastInvokeAt[id];
    const window = Duration(milliseconds: 500);
    if (last != null && now.difference(last) <= window) {
      return;
    }

    _lastInvokeAt[id] = now;
    try {
      handler.call(payload);
    } catch (_) {
      // swallow errors from handlers to avoid affecting map internals
    }
  }

  /// Remove any registered onMarkerTap handler for [id].
  static void removeOnMarkerTap(String id) {
    _onMarkerTapHandlers.remove(id);
  }

  /// Returns the current map center for the controller with [id], or `null`
  /// if the controller isn't available or the camera info is not yet
  /// initialized. This uses `mapController.camera.center` when possible.
  static LatLng? getCenter(String id) {
    final controller = _controllers[id];
    if (controller == null) return null;
    try {
      return controller.camera.center;
    } catch (_) {
      return null;
    }
  }

  /// Optionally remove a controller (e.g., on dispose of a long-lived form)
  static void remove(String id) {
    _controllers.remove(id);
  }
}
