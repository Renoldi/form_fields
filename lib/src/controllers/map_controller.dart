import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/utilities/debug_log.dart';
part 'map_controller_parts/map_controller_extension.dart';
part 'map_controller_parts/raw_marker_ops.dart';
part 'map_controller_parts/bulk_marker_ops.dart';
part 'map_controller_parts/playback_ops.dart';
part 'map_controller_parts/registry.dart';

/// A persistent controller provider for `MapController` instances.
/// Controllers are keyed by an `id` so they are not recreated on widget rebuilds.
class FormFieldsMapController {
  /// Register an external or pre-created [controller] under [id]. This
  /// allows consumers that provide their own `MapController` to expose it
  /// through the shared registry so other widgets or callers can access
  /// the same controller instance via the registry APIs.
  static void registerController(String id, MapController controller) =>
      _MapRegistry.registerController(id, controller);

  /// Convenience helper that registers a controller under the stable
  /// `ff_controller_<hash>` id and optionally registers a `FormFieldsMapNotifier`
  /// for the same id. This simplifies consumer code by ensuring both the
  /// controller and notifier are registered under the same stable id that
  /// `FormFieldsMap` widgets use.
  static String registerControllerAndNotifier(
    MapController controller,
    FormFieldsMapNotifier? notifier,
  ) => _MapRegistry.registerControllerAndNotifier(controller, notifier);

  /// Returns an existing controller for [id], or creates one if missing.
  static MapController getOrCreate(String id) => _MapRegistry.getOrCreate(id);

  /// Register a `FormFieldsMapNotifier` instance for the controller id.
  static void registerNotifier(String id, FormFieldsMapNotifier notifier) =>
      _MapRegistry.registerNotifier(id, notifier);

  /// Remove a previously registered notifier for [id]. Called on widget
  /// dispose to avoid leaks.
  static void removeNotifier(String id) => _MapRegistry.removeNotifier(id);

  /// Public accessor for the registered `FormFieldsMapNotifier` for [id].
  /// Returns `null` when no notifier is registered. This is a thin
  /// wrapper around the internal `_getNotifier` helper to allow callers
  /// that need direct access to the notifier (e.g. widgets using
  /// `ChangeNotifierProvider.value`) to obtain it safely.
  static FormFieldsMapNotifier? getNotifier(String id) =>
      _MapRegistry.getNotifier(id);

  /// Return a copy of the notifier's `rawMarkers` list for [id], or an
  /// empty list when no notifier is registered. This is a safe read-only
  /// accessor for external callers.
  static List<dynamic> getRawMarkers(String id) =>
      _MapRegistry.getRawMarkers(id);

  /// Return the registry id associated with a `FormFieldsMapNotifier`. If
  /// the notifier is not yet registered, a new id is created and the
  /// notifier is registered under it. This is primarily a helper for
  /// examples and code that holds a notifier instance and needs the
  /// corresponding registry id used by the map widget.
  static String getIdForNotifier(FormFieldsMapNotifier notifier) =>
      _MapRegistry.getIdForNotifier(notifier);

  /// Return the registry id associated with [controller], creating a new
  /// registry entry if the controller is not yet known. This allows callers
  /// that hold a `MapController` instance to obtain a stable string id for
  /// use with other registry APIs.
  static String getIdForController(MapController controller) =>
      _MapRegistry.getIdForController(controller);

  /// Returns a `ValueListenable<bool>` representing the loading state for
  /// the controller with [id]. The notifier is created on demand and shared
  /// so callers can observe or set loading state across widgets and viewmodels.
  static ValueListenable<bool> getLoadingListenable(String id) =>
      _MapRegistry.getLoadingListenable(id);

  /// Convenience setter to change the loading value for [id].
  static void setLoading(String id, bool value) =>
      _MapRegistry.setLoading(id, value);

  /// Setter for blocking loading state for [id]. Use this when you need
  /// to present a full-screen blocking overlay (e.g., while fetching data).
  static void setBlockingLoading(String id, bool value) =>
      _MapRegistry.setBlockingLoading(id, value);

  /// Returns a `ValueListenable<bool>` representing a blocking loading
  /// state for the controller with [id]. This is intended for long-running
  /// data loads where the map UI should be modal/blocked (full-screen
  /// overlay). Notifier is created on demand.
  static ValueListenable<bool> getBlockingLoadingListenable(String id) =>
      _MapRegistry.getBlockingLoadingListenable(id);

  /// Register a handler to be invoked when a marker is tapped. The map
  /// widget will call this during init and update, and it will be removed
  /// when the widget disposes.
  static void registerOnMarkerTap(
    String id,
    ValueChanged<ShapeMeta>? handler,
  ) => _MapRegistry.registerOnMarkerTap(id, handler);

  /// Invoke the registered `onMarkerTap` handler (if any) for [id]. This
  /// is safe to call from anywhere (e.g., marker widget tap callbacks).
  static void invokeOnMarkerTap(String id, ShapeMeta payload) =>
      _MapRegistry.invokeOnMarkerTap(id, payload);

  /// Remove any registered onMarkerTap handler for [id].
  static void removeOnMarkerTap(String id) =>
      _MapRegistry.removeOnMarkerTap(id);

  /// Replace the notifier's `rawMarkers` list for [id]. No-op when no
  /// notifier is registered for [id].
  static void setRawMarkers(String id, List<dynamic> coords) =>
      _MapRawMarkerOps.setRawMarkers(id, coords);

  static Future<bool> appendRawMarkers(
    String id,
    List<dynamic> coords, {
    bool createMarkerWidgets = true,
  }) => _MapRawMarkerOps.appendRawMarkers(
    id,
    coords,
    createMarkerWidgets: createMarkerWidgets,
  );

  static void clearRawMarkers(String id) =>
      _MapRawMarkerOps.clearRawMarkers(id);

  /// Update a single raw marker by `markerId` for the controller `id`.
  ///
  /// This performs a targeted update without replacing the entire
  /// `rawMarkers` list. It removes any existing derived layer entries
  /// for the marker id (polygon/polyline/circle/marker), replaces the
  /// raw marker, and then re-appends the new entry so derived maps are
  /// re-registered. Returns `true` when an update occurred.
  static bool updateRawMarker(String id, String markerId, dynamic entry) =>
      _MapRawMarkerOps.updateRawMarker(id, markerId, entry);

  static bool removeRawMarker(String id, String markerId) =>
      _MapRawMarkerOps.removeRawMarker(id, markerId);

  /// Efficiently apply many coordinate-only updates for [id]. Each update
  /// should be a Map with `id` and `pointMetas` (serializable List of maps)
  /// or `lat`/`lon` for single-point markers. Returns true when applied.
  static bool batchUpdateCoordinates(
    String id,
    List<Map<String, dynamic>> updates, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) => _MapBulkMarkerOps.batchUpdateCoordinates(
    id,
    updates,
    createMarkerWidgets: createMarkerWidgets,
    useInPlaceMutation: useInPlaceMutation,
  );

  /// High-level helper: accept a list of `ShapeMeta` and perform inserts
  /// or updates automatically. Consumers can call this with full
  /// `ShapeMeta` objects and the controller will decide whether to append
  /// new entries or patch existing ones (using `_MapBulkMarkerOps.batchUpdateCoordinates`).
  /// Returns true when the operation was attempted.
  static Future<bool> processShapeMetaList(
    String id,
    List<ShapeMeta> shapes, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) => _MapBulkMarkerOps.processShapeMetaList(
    id,
    shapes,
    createMarkerWidgets: createMarkerWidgets,
    useInPlaceMutation: useInPlaceMutation,
  );

  /// Efficiently apply many raw-marker updates for [id] in a single batch.
  /// Returns true when the notifier exists and the operation was applied.
  static Future<bool> batchUpdateRawMarkers(
    String id,
    List<dynamic> updates, {
    bool createMarkerWidgets = true,
  }) => _MapBulkMarkerOps.batchUpdateRawMarkers(
    id,
    updates,
    createMarkerWidgets: createMarkerWidgets,
  );

  /// Upsert a single raw marker: update if an entry with [markerId] exists,
  /// otherwise insert it. Returns true when the notifier exists and the
  /// operation was applied.
  static Future<bool> upsertRawMarker(
    String id,
    String markerId,
    dynamic entry, {
    bool createMarkerWidgets = true,
  }) => _MapBulkMarkerOps.upsertRawMarker(
    id,
    markerId,
    entry,
    createMarkerWidgets: createMarkerWidgets,
  );

  /// Update only coordinates of an existing raw marker or append if missing.
  /// This fast-path delegates to the notifier to avoid full derived-map
  /// rebuilds and returns true when applied.
  static bool updateRawMarkerCoordinates(
    String id,
    String markerId,
    List<PointMeta> newPointMetas, {
    bool createMarkerWidgets = true,
  }) => _MapBulkMarkerOps.updateRawMarkerCoordinates(
    id,
    markerId,
    newPointMetas,
    createMarkerWidgets: createMarkerWidgets,
  );

  /// Runs [action] on the notifier registered for [id].
  ///
  /// With no notifier the call does nothing and returns [orElse]. With
  /// [createIfMissing] a notifier is created and registered first, so adding to
  /// a new id still works. Errors from [action] are swallowed and [orElse] is
  /// returned, as the individual methods always did.
  static R? _withNotifier<R>(
    String id,
    R Function(FormFieldsMapNotifier notifier) action, {
    bool createIfMissing = false,
    R? orElse,
  }) {
    var n = _MapRegistry._getNotifier(id);
    if (n == null && createIfMissing) {
      try {
        final created = FormFieldsMapNotifier();
        _MapRegistry.registerNotifier(id, created);
        n = created;
      } catch (_) {}
    }
    if (n == null) return orElse;
    try {
      return action(n);
    } catch (_) {
      return orElse;
    }
  }

  static bool get enableBatchLogging => _MapRegistry.enableBatchLogging;

  static set enableBatchLogging(bool value) =>
      _MapRegistry.enableBatchLogging = value;

  // Polygons
  static String? addPolygon(String id, Polygon p) =>
      _withNotifier(id, (n) => n.addPolygon(p), createIfMissing: true);

  static void addOrUpdatePolygon(String id, String pid, Polygon p) {
    _withNotifier<void>(id, (n) => n.addOrUpdatePolygon(pid, p));
  }

  static bool removePolygon(String id, String pid) =>
      _withNotifier(id, (n) => n.removePolygon(pid), orElse: false) ?? false;

  static void clearPolygons(String id) {
    _withNotifier<void>(id, (n) => n.clearPolygons());
  }

  // Polylines
  static String? addPolyline(String id, Polyline l) =>
      _withNotifier(id, (n) => n.addPolyline(l), createIfMissing: true);

  static void addOrUpdatePolyline(String id, String lid, Polyline l) {
    _withNotifier<void>(id, (n) => n.addOrUpdatePolyline(lid, l));
  }

  static bool removePolyline(String id, String lid) =>
      _withNotifier(id, (n) => n.removePolyline(lid), orElse: false) ?? false;

  static void clearPolylines(String id) {
    _withNotifier<void>(id, (n) => n.clearPolylines());
  }

  // Circles
  static String? addCircle(String id, CircleMarker c) =>
      _withNotifier(id, (n) => n.addCircle(c), createIfMissing: true);

  static void addOrUpdateCircle(String id, String cid, CircleMarker c) {
    _withNotifier<void>(id, (n) => n.addOrUpdateCircle(cid, c));
  }

  static bool removeCircle(String id, String cid) =>
      _withNotifier(id, (n) => n.removeCircle(cid), orElse: false) ?? false;

  static void clearCircles(String id) {
    _withNotifier<void>(id, (n) => n.clearCircles());
  }

  // Markers
  static String? addMarker(String id, Marker m) =>
      _withNotifier(id, (n) => n.addMarker(m), createIfMissing: true);

  static void addOrUpdateMarker(String id, String mid, Marker m) {
    _withNotifier<void>(id, (n) => n.addOrUpdateMarker(mid, m));
  }

  static bool removeMarker(String id, String mid) =>
      _withNotifier(id, (n) => n.removeMarker(mid), orElse: false) ?? false;

  static void clearMarkers(String id) {
    _withNotifier<void>(id, (n) => n.clearMarkers());
  }

  /// Returns the current map center for the controller with [id], or `null`
  /// if the controller isn't available or the camera info is not yet
  /// initialized. This uses `mapController.camera.center` when possible.
  static LatLng? getCenter(String id) {
    final controller = _MapRegistry._controllers[id];
    if (controller == null) return null;
    try {
      return controller.camera.center;
    } catch (_) {
      return null;
    }
  }

  /// Removes a controller and every per-id entry kept for it. Called when the
  /// map widget that owns the controller is disposed. Without this, each map
  /// instance left its notifiers, flags and timers in the static maps for good.
  static void remove(String id) {
    _MapRegistry._controllers.remove(id);
    _MapRegistry._appendRetryCounts.remove(id);
    final clearTimer = _MapRegistry._blockingClearTimers.remove(id);
    clearTimer?.cancel();
    _MapRegistry._loadingNotifiers.remove(id);
    _MapRegistry._blockingLoadingNotifiers.remove(id);
    _MapRegistry._onMarkerTapHandlers.remove(id);
    _MapRegistry._lastInvokeAt.remove(id);
    _MapPlaybackOps._playbackHandlers.remove(id);
    _MapPlaybackOps._playbackAutoStart.remove(id);
    _MapPlaybackOps._notifyCenterDuringPlayback.remove(id);
    _MapPlaybackOps._playbackPlayingNotifiers.remove(id);
    _MapPlaybackOps._requestedPlaying.remove(id);
  }

  /// Configure whether `onCenterChanged` callbacks should be invoked while
  /// internal playback is active for controller [id]. Defaults to `false`.
  static void setNotifyCenterDuringPlayback(String id, bool value) =>
      _MapPlaybackOps.setNotifyCenterDuringPlayback(id, value);

  /// Returns whether center updates are allowed during internal playback for
  /// [id]. Defaults to `false` when not configured.
  static bool getNotifyCenterDuringPlayback(String id) =>
      _MapPlaybackOps.getNotifyCenterDuringPlayback(id);

  /// Returns a `ValueListenable<bool>` that emits `true` while playback is
  /// active for controller [id]. The notifier is created on demand.
  static ValueListenable<bool> getPlaybackPlayingListenable(String id) =>
      _MapPlaybackOps.getPlaybackPlayingListenable(id);

  /// Set the authoritative playback playing state for [id]. This will
  /// create the notifier if necessary and update its value.
  static void setPlaybackPlaying(String id, bool value) =>
      _MapPlaybackOps.setPlaybackPlaying(id, value);

  /// Register a playback handler for a given controller id. Pass `null`
  /// to unregister.
  static void registerPlaybackHandler(
    String id,
    FormFieldsMapPlaybackHandler? handler,
  ) => _MapPlaybackOps.registerPlaybackHandler(id, handler);

  /// Control whether _MapRawMarkerOps.appendRawMarkers should auto-start playback for [id].
  /// When set to `true`, the first non-empty append will call the
  /// registered playback handler. Defaults to `false` when not set.
  static void setPlaybackAutoStart(String id, bool value) =>
      _MapPlaybackOps.setPlaybackAutoStart(id, value);

  static bool getPlaybackAutoStart(String id) =>
      _MapPlaybackOps.getPlaybackAutoStart(id);

  /// Unregister a playback handler for [id].
  static void unregisterPlaybackHandler(String id) =>
      _MapPlaybackOps.unregisterPlaybackHandler(id);

  /// Control helpers that forward to a registered playback handler (if any).
  static void startPolylinePlayback(String id, String? polylineId) =>
      _MapPlaybackOps.startPolylinePlayback(id, polylineId);

  static void pausePolylinePlayback(String id) =>
      _MapPlaybackOps.pausePolylinePlayback(id);

  static void restartPolylinePlayback(String id) =>
      _MapPlaybackOps.restartPolylinePlayback(id);

  static void setPolylinePlaybackInterval(String id, Duration interval) =>
      _MapPlaybackOps.setPolylinePlaybackInterval(id, interval);

  /// Set the number of interpolation steps used by the playback handler
  /// for [id]. This forwards to the registered handler if present.
  static void setPolylinePlaybackInterpolationSteps(String id, int steps) =>
      _MapPlaybackOps.setPolylinePlaybackInterpolationSteps(id, steps);

  /// Toggle playback (start/resume or pause) for the given controller id.
  static void togglePolylinePlayback(String id, String? polylineId) =>
      _MapPlaybackOps.togglePolylinePlayback(id, polylineId);

  /// Advance playback by one step (forward). Forwards to registered handler.
  static void stepPolylineForward(String id, String? polylineId) =>
      _MapPlaybackOps.stepPolylineForward(id, polylineId);

  /// Move playback one step backward. Forwards to registered handler.
  static void stepPolylineBackward(String id, String? polylineId) =>
      _MapPlaybackOps.stepPolylineBackward(id, polylineId);
}

/// Convenience extension on `MapController` to allow calling registry APIs
/// directly from a `MapController` instance. This lets consumers simply do
/// `mapController.setBlockingLoading(true)` instead of resolving a string id.
