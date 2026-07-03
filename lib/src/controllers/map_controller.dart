import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
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
      // ignore: avoid_print
      debugPrint('FormFieldsMapController: registerOnMarkerTap($id) -> null');
    } else {
      // ignore: avoid_print
      debugPrint(
          'FormFieldsMapController: registerOnMarkerTap($id) -> registered');
    }
  }

  /// Invoke the registered `onMarkerTap` handler (if any) for [id]. This
  /// is safe to call from anywhere (e.g., marker widget tap callbacks).
  static void invokeOnMarkerTap(String id, ShapeMeta payload) {
    final handler = _onMarkerTapHandlers[id];
    if (handler == null) {
      // ignore: avoid_print
      debugPrint(
          'FormFieldsMapController.invokeOnMarkerTap: no handler for $id');
      return;
    }

    // suppress duplicate invocations within a short window
    final now = DateTime.now();
    final last = _lastInvokeAt[id];
    const window = Duration(milliseconds: 500);
    if (last != null && now.difference(last) <= window) {
      // ignore: avoid_print
      debugPrint(
          'FormFieldsMapController.invokeOnMarkerTap: suppressed duplicate for $id');
      return;
    }

    _lastInvokeAt[id] = now;
    try {
      // ignore: avoid_print
      debugPrint('FormFieldsMapController.invokeOnMarkerTap: invoking for $id');
      handler.call(payload);
    } catch (e, st) {
      // ignore: avoid_print
      debugPrint('FormFieldsMapController.invokeOnMarkerTap error: $e\n$st');
    }
  }

  /// Remove any registered onMarkerTap handler for [id].
  static void removeOnMarkerTap(String id) {
    _onMarkerTapHandlers.remove(id);
  }

  /// Optionally remove a controller (e.g., on dispose of a long-lived form)
  static void remove(String id) {
    _controllers.remove(id);
  }
}
