import 'package:flutter_map/flutter_map.dart';
import 'package:form_fields/form_fields.dart';
import 'package:logging/logging.dart';
import 'package:form_fields/src/utilities/debug_log.dart';
import 'package:form_fields/src/providers/map_stores.dart';

final _mapLog = Logger('FormFieldsMapNotifier');

class FormFieldsMapNotifier extends FormFieldsChangeNotifier {
  FormFieldsMapNotifier({
    MapController? controller,
    List<Polygon>? polygons,
    List<Polyline>? polylines,
    List<CircleMarker>? circles,
    Map<String, Polygon>? polygonsMap,
    Map<String, Polyline>? polylinesMap,
    Map<String, CircleMarker>? circlesMap,
  }) {
    _polygons = MapShapeStore<Polygon>(
      idPrefix: 'p',
      ensureControlled: _ensureControlled,
      onChanged: _scheduleNotify,
      initial: polygonsMap,
    );
    _polylines = MapShapeStore<Polyline>(
      idPrefix: 'l',
      ensureControlled: _ensureControlled,
      onChanged: _scheduleNotify,
      initial: polylinesMap,
    );
    _circles = MapShapeStore<CircleMarker>(
      idPrefix: 'c',
      ensureControlled: _ensureControlled,
      onChanged: _scheduleNotify,
      initial: circlesMap,
    );
    _markers = MapShapeStore<Marker>(
      idPrefix: 'm',
      ensureControlled: _ensureControlled,
      onChanged: _scheduleNotify,
    );
    _raw = MapRawMarkerStore(
      polygons: _polygons,
      polylines: _polylines,
      circles: _circles,
      markers: _markers,
      ensureControlled: _ensureControlled,
      onChanged: _scheduleNotify,
    );
    // If a MapController is provided, register this notifier with it so
    // consumers can opt-in to automatic registry wiring.
    if (controller != null) {
      try {
        controller.registerWithNotifier(this);
      } catch (e, st) {
        _mapLog.fine('Ignored map update error', e, st);
      }
    }
    if (polygons != null) {
      _polygons.seed(polygons, (i) => 'p$i');
    }
    if (polylines != null) {
      _polylines.seed(polylines, (i) => 'l$i');
    }
    if (circles != null) {
      _circles.seed(circles, (i) => 'c$i');
    }
  }

  // Debounced notify (see [FormFieldsChangeNotifier.scheduleNotify]).
  void _scheduleNotify() => scheduleNotify();

  // Controller that is allowed to perform mutations. When null, mutating
  // methods will throw. The controller should call `attachController`.
  String? _controllerId;

  /// Attach a controller id to allow mutations via that controller.
  /// Passing `null` detaches and disables mutations.
  void attachController(String? id) {
    _controllerId = id;
    try {
      debugLog(
        '[FormFieldsMapNotifier] attachController id=$_controllerId hash=$hashCode',
      );
    } catch (e, st) {
      _mapLog.fine('Ignored map update error', e, st);
    }
  }

  void _ensureControlled() {
    if (_controllerId == null) {
      throw StateError(
        'FormFieldsMapNotifier is read-only — mutate via FormFieldsMapController',
      );
    }
  }

  late final MapShapeStore<Polygon> _polygons;
  late final MapShapeStore<Polyline> _polylines;
  late final MapShapeStore<CircleMarker> _circles;
  late final MapShapeStore<Marker> _markers;

  late final MapRawMarkerStore _raw;

  // ---- Raw markers ------------------------------------------------------
  // The raw marker list and the bulk algorithms live in [MapRawMarkerStore].

  List<dynamic> get rawMarkers => _raw.rawMarkers;

  set rawMarkers(List<dynamic> coords) => _raw.rawMarkers = coords;

  /// Append raw markers. When [createMarkerWidgets] is false, the notifier
  /// will skip constructing `Marker` widget entries in `markers.raw` which
  /// is significantly faster for very large point sets when rendering is
  /// done via a canvas painter rather than per-marker widgets.
  void appendRawMarkers(
    List<dynamic> coords, {
    bool createMarkerWidgets = true,
  }) => _raw.appendRawMarkers(coords, createMarkerWidgets: createMarkerWidgets);

  /// Apply many raw-marker updates in a single batch.
  ///
  /// `updates` may contain `ShapeMeta` instances or Map-style descriptors.
  /// For entries that carry an `id` the notifier will replace the existing
  /// entry (and its derived concrete map entries) in-place. Entries without
  /// an `id` are appended. Caches are rebuilt once and listeners are
  /// notified via the normal debounced path.
  void batchUpdateRawMarkers(
    List<dynamic> updates, {
    bool createMarkerWidgets = true,
  }) => _raw.batchUpdateRawMarkers(
    updates,
    createMarkerWidgets: createMarkerWidgets,
  );

  /// Fast-path: update coordinates for a single marker (or shape) identified
  /// by [id]. When the entry exists and is a `ShapeMeta`, this will replace
  /// its `pointMetas` with [newPointMetas] and refresh only the affected
  /// concrete map and cache to avoid a full rebuild.
  ///
  /// If the entry does not exist, it will be appended as a new `ShapeMeta`.
  void upsertCoordinates(
    String id,
    List<PointMeta> newPointMetas, {
    bool createMarkerWidgets = true,
  }) => _raw.upsertCoordinates(
    id,
    newPointMetas,
    createMarkerWidgets: createMarkerWidgets,
  );

  /// Batch apply coordinate-only updates. Each entry in [updates] should be
  /// a Map with at least an `id` and either `pointMetas` (List of maps with
  /// `lat`/`lon`) or `lat`/`lon` for single-point markers. This method will
  /// update rawMarkers in-place and refresh only the affected concrete
  /// entries once, then schedule a single debounced notify.
  void batchUpdateCoordinates(
    List<Map<String, dynamic>> updates, {
    bool createMarkerWidgets = true,
    bool useInPlaceMutation = true,
  }) => _raw.batchUpdateCoordinates(
    updates,
    createMarkerWidgets: createMarkerWidgets,
    useInPlaceMutation: useInPlaceMutation,
  );

  void clearRawMarkers() => _raw.clearRawMarkers();

  bool removeRawMarker(String id) => _raw.removeRawMarker(id);

  // ---- Shape collections --------------------------------------------------
  // Each kind is a [MapShapeStore]; the public names and behavior are unchanged.

  List<Polygon> get polygons => _polygons.items;

  set polygons(List<Polygon> p) => _polygons.replaceAll(p, (i) => 'p$i');

  /// Public accessors for internal maps so external consumers (same
  /// package files) can query or iterate entries without relying on
  /// private fields. These are intentionally read-only views.
  Map<String, Polygon> get polygonMap => _polygons.unmodifiableMap;

  Map<String, Polyline> get polylineMap => _polylines.unmodifiableMap;

  Map<String, CircleMarker> get circleMap => _circles.unmodifiableMap;

  // Polygons
  String addPolygon(Polygon p) => _polygons.add(p);

  void addOrUpdatePolygon(String id, Polygon polygon) =>
      _polygons.addOrUpdate(id, polygon);

  Polygon? getPolygon(String id) => _polygons.get(id);

  bool removePolygon(String id) => _polygons.remove(id);

  void clearPolygons() => _polygons.clear();

  // Polylines
  List<Polyline> get polylines => _polylines.items;

  set polylines(List<Polyline> p) => _polylines.replaceAll(p, (i) => 'l$i');

  String addPolyline(Polyline p) => _polylines.add(p);

  void addOrUpdatePolyline(String id, Polyline polyline) =>
      _polylines.addOrUpdate(id, polyline);

  Polyline? getPolyline(String id) => _polylines.get(id);

  bool removePolyline(String id) => _polylines.remove(id);

  void clearPolylines() => _polylines.clear();

  // Circles
  List<CircleMarker> get circles => _circles.items;

  set circles(List<CircleMarker> c) => _circles.replaceAll(c, (i) => 'c$i');

  String addCircle(CircleMarker c) => _circles.add(c);

  void addOrUpdateCircle(String id, CircleMarker circle) =>
      _circles.addOrUpdate(id, circle);

  CircleMarker? getCircle(String id) => _circles.get(id);

  bool removeCircle(String id) => _circles.remove(id);

  void clearCircles() => _circles.clear();

  // Markers
  List<Marker> get markers => _markers.items;

  set markers(List<Marker> m) => _markers.replaceAll(
    m,
    (i) => 'm\${DateTime.now().microsecondsSinceEpoch}_$i',
    requireController: false,
  );

  String addMarker(Marker m) => _markers.add(m);

  void addOrUpdateMarker(String id, Marker marker) =>
      _markers.addOrUpdate(id, marker);

  Marker? getMarker(String id) => _markers.get(id);

  bool removeMarker(String id) => _markers.remove(id);

  void clearMarkers() => _markers.clear();
}
