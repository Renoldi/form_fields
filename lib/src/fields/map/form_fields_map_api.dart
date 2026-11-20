import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';

/// Lightweight convenience facade over `FormFieldsMapController`.
///
/// Construct from either a `MapController` or a `FormFieldsMapNotifier` and
/// call instance methods without repeatedly passing an `id`.
class FormFieldsMapApi {
  final MapController? _controller;
  final String? _staticId;

  FormFieldsMapApi._(this._controller, this._staticId);

  /// Create API bound to an existing `MapController`.
  ///
  /// The registry id is resolved lazily on each call so widgets that
  /// register the controller under a generated id (e.g. the map widget)
  /// will be honored.
  static FormFieldsMapApi fromController(MapController controller) {
    return FormFieldsMapApi._(controller, null);
  }

  /// Create API bound to a `FormFieldsMapNotifier` instance. This binds to
  /// the notifier's registry id immediately.
  static FormFieldsMapApi fromNotifier(FormFieldsMapNotifier notifier) {
    final id = FormFieldsMapController.getIdForNotifier(notifier);
    return FormFieldsMapApi._(null, id);
  }

  String _resolveId() {
    if (_staticId != null) return _staticId;
    if (_controller != null) {
      return FormFieldsMapController.getIdForController(_controller);
    }
    throw StateError(
      'FormFieldsMapApi is not bound to a controller or notifier',
    );
  }

  // --- Raw markers ---
  void setRawMarkers(List<dynamic> coords) =>
      FormFieldsMapController.setRawMarkers(_resolveId(), coords);
  Future<bool> appendRawMarkers(List<dynamic> coords) async =>
      await FormFieldsMapController.appendRawMarkers(_resolveId(), coords);
  void clearRawMarkers() =>
      FormFieldsMapController.clearRawMarkers(_resolveId());
  bool removeRawMarker(String markerId) =>
      FormFieldsMapController.removeRawMarker(_resolveId(), markerId);

  // --- Polygons ---
  String? addPolygon(Polygon p) =>
      FormFieldsMapController.addPolygon(_resolveId(), p);
  void addOrUpdatePolygon(String pid, Polygon p) =>
      FormFieldsMapController.addOrUpdatePolygon(_resolveId(), pid, p);
  bool removePolygon(String pid) =>
      FormFieldsMapController.removePolygon(_resolveId(), pid);
  void clearPolygons() => FormFieldsMapController.clearPolygons(_resolveId());

  // --- Polylines ---
  String? addPolyline(Polyline l) =>
      FormFieldsMapController.addPolyline(_resolveId(), l);
  void addOrUpdatePolyline(String lid, Polyline l) =>
      FormFieldsMapController.addOrUpdatePolyline(_resolveId(), lid, l);
  bool removePolyline(String lid) =>
      FormFieldsMapController.removePolyline(_resolveId(), lid);
  void clearPolylines() => FormFieldsMapController.clearPolylines(_resolveId());

  // --- Circles ---
  String? addCircle(CircleMarker c) =>
      FormFieldsMapController.addCircle(_resolveId(), c);
  void addOrUpdateCircle(String cid, CircleMarker c) =>
      FormFieldsMapController.addOrUpdateCircle(_resolveId(), cid, c);
  bool removeCircle(String cid) =>
      FormFieldsMapController.removeCircle(_resolveId(), cid);
  void clearCircles() => FormFieldsMapController.clearCircles(_resolveId());

  // --- Markers ---
  String? addMarker(Marker m) =>
      FormFieldsMapController.addMarker(_resolveId(), m);
  void addOrUpdateMarker(String mid, Marker m) =>
      FormFieldsMapController.addOrUpdateMarker(_resolveId(), mid, m);
  bool removeMarker(String mid) =>
      FormFieldsMapController.removeMarker(_resolveId(), mid);
  void clearMarkers() => FormFieldsMapController.clearMarkers(_resolveId());

  // --- Helpers ---
  List<dynamic> getRawMarkers() =>
      FormFieldsMapController.getRawMarkers(_resolveId());
}
