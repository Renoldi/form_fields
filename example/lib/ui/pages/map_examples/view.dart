import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:form_fields_example/localization/localizations.dart';

// `flutter_map` is used internally by the package; example doesn't import it directly.

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapExamplesViewModel(),
      child: Consumer<MapExamplesViewModel>(
        builder: (context, vm, _) {
          final content = Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(context.tr('mapExampleDescription')),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ActionButton(
                          label: 'Generate 10,000 markers + shapes',
                          icon: Icons.auto_awesome,
                          onPressed: () => vm.generateDemoData(
                              markerCount: 10000, shapeCount: 20),
                        ),
                        _ActionButton(
                          label: 'Generate Polygons (20)',
                          icon: Icons.change_history,
                          onPressed: () => vm.generatePolygons(shapeCount: 20),
                        ),
                        _ActionButton(
                          label: 'Generate Polylines (20)',
                          icon: Icons.timeline,
                          onPressed: () => vm.generatePolylines(shapeCount: 20),
                        ),
                        _ActionButton(
                          label: 'Generate Circles (20)',
                          icon: Icons.circle,
                          onPressed: () => vm.generateCircles(shapeCount: 20),
                        ),
                        _ActionButton(
                          label: 'Clear',
                          icon: Icons.clear,
                          outlined: true,
                          color: Colors.red,
                          onPressed: () => vm.clearDemoData(),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Fast markers'),
                            Switch(
                              value: vm.useCanvasMarkers,
                              onChanged: (v) {
                                vm.useCanvasMarkers = v;
                                vm.commit();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FormFieldsMap(
                        notifier: vm.mapNotifier,
                        useCanvasMarkers: vm.useCanvasMarkers,
                        onRequestCurrentLocation: () async => vm.center,
                        canvasMarkerRadius: 20.0,
                        canvasMarkerIcon: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 36,
                        ),
                        onMarkerTap: (m) async {
                          final payload = (m is Map)
                              ? Map<String, dynamic>.from(m)
                              : <String, dynamic>{};
                          final title =
                              payload['title'] ?? (m?.title) ?? 'Detail';
                          final subtitle =
                              payload['subtitle'] ?? (m?.subtitle) ?? '';
                          final id = payload['id'] as String?;
                          final LatLng? pt = payload['point'] is LatLng
                              ? payload['point'] as LatLng
                              : (m?.point as LatLng?);

                          await showDialog<void>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: Text(title.toString()),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (subtitle != null &&
                                        subtitle.toString().isNotEmpty)
                                      Text(subtitle.toString()),
                                    if (id != null) ...[
                                      const SizedBox(height: 8),
                                      Text('ID: $id',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                    if (pt != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                          'Coords: ${pt.latitude.toStringAsFixed(6)}, ${pt.longitude.toStringAsFixed(6)}'),
                                    ]
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Close')),
                                  if (id != null)
                                    TextButton(
                                      onPressed: () {
                                        if (id.startsWith('m\$')) {
                                          vm.mapNotifier.removeMarker(id);
                                        } else if (id.startsWith('p\$')) {
                                          vm.mapNotifier.removePolygon(id);
                                        } else if (id.startsWith('l\$')) {
                                          vm.mapNotifier.removePolyline(id);
                                        } else if (id.startsWith('c\$')) {
                                          vm.mapNotifier.removeCircle(id);
                                        }
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text('Deleted')));
                                      },
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  if (id != null)
                                    TextButton(
                                      onPressed: () {
                                        if (id.startsWith('p\$')) {
                                          final poly =
                                              vm.mapNotifier.getPolygon(id);
                                          if (poly != null) {
                                            final newPoly = Polygon(
                                                points: poly.points,
                                                color: poly.color ==
                                                        Colors.green.withValues(
                                                            alpha: 0.25)
                                                    ? Colors.purple
                                                        .withValues(alpha: 0.25)
                                                    : Colors.green.withValues(
                                                        alpha: 0.25),
                                                borderColor: poly.borderColor ==
                                                        Colors.green
                                                    ? Colors.purple
                                                    : Colors.green,
                                                borderStrokeWidth:
                                                    poly.borderStrokeWidth);
                                            vm.mapNotifier.addOrUpdatePolygon(
                                                id, newPoly);
                                          }
                                        } else if (id.startsWith('l\$')) {
                                          final line =
                                              vm.mapNotifier.getPolyline(id);
                                          if (line != null) {
                                            final newLine = Polyline(
                                                points: line.points,
                                                strokeWidth: line.strokeWidth,
                                                color: line.color == Colors.blue
                                                    ? Colors.purple
                                                    : Colors.blue);
                                            vm.mapNotifier.addOrUpdatePolyline(
                                                id, newLine);
                                          }
                                        } else if (id.startsWith('c\$')) {
                                          final circ =
                                              vm.mapNotifier.getCircle(id);
                                          if (circ != null) {
                                            final newCirc = CircleMarker(
                                                point: circ.point,
                                                color: circ.color ==
                                                        Colors.orange
                                                            .withValues(
                                                                alpha: 0.35)
                                                    ? Colors.purple
                                                        .withValues(alpha: 0.35)
                                                    : Colors.orange.withValues(
                                                        alpha: 0.35),
                                                borderStrokeWidth:
                                                    circ.borderStrokeWidth,
                                                borderColor: circ.borderColor ==
                                                        Colors.orange
                                                    ? Colors.purple
                                                    : Colors.orange,
                                                useRadiusInMeter:
                                                    circ.useRadiusInMeter,
                                                radius: circ.radius);
                                            vm.mapNotifier
                                                .addOrUpdateCircle(id, newCirc);
                                          }
                                        }
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Toggle Color'),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                        initialCenter: vm.center,
                        initialZoom: 12.0,
                        onTap: (latlng) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Tapped: ${latlng.latitude}, ${latlng.longitude}')));
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Code example',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        "FormFieldsMap(center: LatLong(-6.2, 106.8166), zoom: 12.0)",
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
              // _DraggablePositioned(
              //   initialRight: 16,
              //   initialBottom: 16,
              //   initWidth: 220,
              //   initHeight: 56,
              //   child: FloatingActionButton.extended(
              //     onPressed: zoomToGeneratedBounds,
              //     icon: const Icon(Icons.zoom_out_map),
              //     label: const Text('Zoom to generated bounds'),
              //   ),
              // ),
            ],
          );

          // Progress overlay
          final showProgress = vm.isLoading ||
              vm.generatedMarkers > 0 ||
              vm.generatedPolygons > 0 ||
              vm.generatedPolylines > 0 ||
              vm.generatedCircles > 0;
          if (showProgress) {
            return Stack(
              children: [
                content,
                _DraggablePositioned(
                  initialRight: 12,
                  initialTop: 12,
                  initWidth: 220,
                  initHeight: 160,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Markers: ${vm.generatedMarkers}/${vm.totalMarkers}'),
                          if (vm.totalMarkers > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                  value: vm.totalMarkers > 0
                                      ? vm.generatedMarkers / vm.totalMarkers
                                      : null),
                            ),
                          const SizedBox(height: 6),
                          Text(
                              'Polygons: ${vm.generatedPolygons}/${vm.totalPolygons}'),
                          if (vm.totalPolygons > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                  value: vm.totalPolygons > 0
                                      ? vm.generatedPolygons / vm.totalPolygons
                                      : null),
                            ),
                          const SizedBox(height: 6),
                          Text(
                              'Polylines: ${vm.generatedPolylines}/${vm.totalPolylines}'),
                          if (vm.totalPolylines > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                  value: vm.totalPolylines > 0
                                      ? vm.generatedPolylines /
                                          vm.totalPolylines
                                      : null),
                            ),
                          const SizedBox(height: 6),
                          Text(
                              'Circles: ${vm.generatedCircles}/${vm.totalCircles}'),
                          if (vm.totalCircles > 0)
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                  value: vm.totalCircles > 0
                                      ? vm.generatedCircles / vm.totalCircles
                                      : null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return content;
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final Color? color;

  const _ActionButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle =
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 18, color: color ?? theme.colorScheme.primary)
            : const SizedBox.shrink(),
        label: Text(label,
            style:
                textStyle.copyWith(color: color ?? theme.colorScheme.primary)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: color ?? theme.colorScheme.primary),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label, style: textStyle),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: color ?? theme.colorScheme.primary,
      ),
    );
  }
}

// (Removed unused color helper)

/// A small helper that allows a child placed in a Stack to be dragged
/// around by the user. It accepts optional initial positioning via
/// `initialLeft`/`initialTop` or `initialRight`/`initialBottom`. For
/// convenience callers can provide estimated `initWidth`/`initHeight` used
/// to compute initial left/top when right/bottom are supplied.
class _DraggablePositioned extends StatefulWidget {
  const _DraggablePositioned({
    this.initialLeft,
    this.initialTop,
    this.initialRight,
    this.initialBottom,
    this.initWidth = 56.0,
    this.initHeight = 56.0,
    required this.child,
  });

  final double? initialLeft;
  final double? initialTop;
  final double? initialRight;
  final double? initialBottom;
  final double initWidth;
  final double initHeight;
  final Widget child;

  @override
  State<_DraggablePositioned> createState() => _DraggablePositionedState();
}

class _DraggablePositionedState extends State<_DraggablePositioned> {
  double? left;
  double? top;
  final GlobalKey _childKey = GlobalKey();
  double? childWidth;
  double? childHeight;

  void _ensureInitialized() {
    if (left != null && top != null) return;
    final size = MediaQuery.of(context).size;
    final w = childWidth ?? widget.initWidth;
    final h = childHeight ?? widget.initHeight;
    if (widget.initialLeft != null) {
      left = widget.initialLeft;
    } else if (widget.initialRight != null) {
      left = size.width - widget.initialRight! - w;
    } else {
      left = 16.0;
    }

    if (widget.initialTop != null) {
      top = widget.initialTop;
    } else if (widget.initialBottom != null) {
      top = size.height - widget.initialBottom! - h;
    } else {
      top = size.height - h - 16.0;
    }
  }

  void _clampToBounds() {
    final size = MediaQuery.of(context).size;
    final w = childWidth ?? widget.initWidth;
    final h = childHeight ?? widget.initHeight;
    final maxLeft = (size.width - w).clamp(0.0, size.width);
    final maxTop = (size.height - h).clamp(0.0, size.height);
    left = (left ?? 0).clamp(0.0, maxLeft);
    top = (top ?? 0).clamp(0.0, maxTop);
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    _clampToBounds();

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {},
        onPanUpdate: (details) {
          setState(() {
            left = (left ?? 0) + details.delta.dx;
            top = (top ?? 0) + details.delta.dy;
            _clampToBounds();
          });
        },
        onPanEnd: (_) {},
        child: Container(key: _childKey, child: widget.child),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Measure child after first frame to get actual size for bounds.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChild());
  }

  void _measureChild() {
    final box = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width;
    final h = box.size.height;
    if (w != childWidth || h != childHeight) {
      setState(() {
        childWidth = w;
        childHeight = h;
        _clampToBounds();
      });
    }
  }
}
