part of '../map_controller.dart';

extension FormFieldsMapControllerMapControllerExt on MapController {
  String registerWithNotifier([FormFieldsMapNotifier? notifier]) {
    final id = FormFieldsMapController.registerControllerAndNotifier(
      this,
      null,
    );
    if (notifier == null) {
      // Create and register a fresh notifier for this controller id.
      final n = FormFieldsMapNotifier();
      FormFieldsMapController.registerNotifier(id, n);
    } else {
      FormFieldsMapController.registerNotifier(id, notifier);
    }
    return id;
  }

  void setBlockingLoading(bool value) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setBlockingLoading(id, value);
  }

  void setLoading(bool value) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setLoading(id, value);
  }

  void setRawMarkers(List<dynamic> coords) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setRawMarkers(id, coords);
  }

  Future<bool> appendRawMarkers(List<dynamic> coords) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.appendRawMarkers(id, coords);
  }

  Future<bool> batchUpdateRawMarkers(List<dynamic> updates) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.batchUpdateRawMarkers(id, updates);
  }

  Future<bool> batchUpdateCoordinates(
    List<Map<String, dynamic>> updates, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) async {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.batchUpdateCoordinates(
      id,
      updates,
      createMarkerWidgets: createMarkerWidgets,
      useInPlaceMutation: useInPlaceMutation,
    );
  }

  Future<bool> processShapeMetaList(
    List<ShapeMeta> shapes, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.processShapeMetaList(
      id,
      shapes,
      createMarkerWidgets: createMarkerWidgets,
      useInPlaceMutation: useInPlaceMutation,
    );
  }

  Future<bool> upsertRawMarker(String markerId, dynamic entry) async {
    final id = FormFieldsMapController.getIdForController(this);
    return await FormFieldsMapController.upsertRawMarker(id, markerId, entry);
  }

  bool updateRawMarkerCoordinates(
    String markerId,
    List<PointMeta> newPointMetas,
  ) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.updateRawMarkerCoordinates(
      id,
      markerId,
      newPointMetas,
    );
  }

  void clearRawMarkers() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearRawMarkers(id);
  }

  String? addPolyline(Polyline l) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addPolyline(id, l);
  }

  String? addMarker(Marker m) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addMarker(id, m);
  }

  void clearPolylines() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearPolylines(id);
  }

  void clearPolygons() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearPolygons(id);
  }

  void clearCircles() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.clearCircles(id);
  }

  void startPolylinePlayback(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.startPolylinePlayback(id, polylineId);
  }

  void pausePolylinePlayback() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.pausePolylinePlayback(id);
  }

  void restartPolylinePlayback() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.restartPolylinePlayback(id);
  }

  void togglePolylinePlayback(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.togglePolylinePlayback(id, polylineId);
  }

  void setPolylinePlaybackInterval(Duration interval) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setPolylinePlaybackInterval(id, interval);
  }

  void setPolylinePlaybackInterpolationSteps(int steps) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setPolylinePlaybackInterpolationSteps(id, steps);
  }

  ValueListenable<bool> getPlaybackPlayingListenable() {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.getPlaybackPlayingListenable(id);
  }

  void setPlaybackPlaying(bool value) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.setPlaybackPlaying(id, value);
  }

  void stepPolylineForward(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.stepPolylineForward(id, polylineId);
  }

  void stepPolylineBackward(String? polylineId) {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.stepPolylineBackward(id, polylineId);
  }

  /// Smoothly animate the map camera from current center to [target].
  /// This helper performs a simple per-frame interpolation and calls
  /// `move` repeatedly. It is intentionally conservative and will
  /// catch errors thrown by the underlying controller.
  Future<void> animateCameraTo(
    LatLng target,
    double targetZoom, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
  }) async {
    LatLng start;
    try {
      start = camera.center;
    } catch (_) {
      // Fallback to a safe origin at equator if camera unavailable.
      start = LatLng(0, 0);
    }

    double startZoom;
    try {
      startZoom = camera.zoom;
    } catch (_) {
      startZoom = 12.0;
    }

    final int steps = (duration.inMilliseconds / 16).clamp(1, 60).toInt();
    final int stepMs = (duration.inMilliseconds / steps).round();
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final et = curve.transform(t);
      final lat = start.latitude + (target.latitude - start.latitude) * et;
      final lon = start.longitude + (target.longitude - start.longitude) * et;
      final zoom = startZoom + (targetZoom - startZoom) * et;
      try {
        move(LatLng(lat, lon), zoom);
      } catch (_) {}
      await Future.delayed(Duration(milliseconds: stepMs));
    }
  }

  List<dynamic> getRawMarkers() {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.getRawMarkers(id);
  }

  String? addPolygon(Polygon p) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addPolygon(id, p);
  }

  String? addCircle(CircleMarker c) {
    final id = FormFieldsMapController.getIdForController(this);
    return FormFieldsMapController.addCircle(id, c);
  }

  void removeNotifier() {
    final id = FormFieldsMapController.getIdForController(this);
    FormFieldsMapController.removeNotifier(id);
  }
}
