import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/localization/localizations.dart';

// Simple integer formatter for thousands separators without adding
// an external dependency.
String formatNumber(int value) {
  final s = value.toString();
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return s.replaceAllMapped(reg, (m) => ',');
}

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
              Column(
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
                              label:
                                  'Generate ${formatNumber(vm.createMarkers)} markers',
                              icon: Icons.auto_awesome,
                              onPressed: () => vm.generateMarkers(
                                  markerCount: vm.createMarkers),
                            ),
                            _ActionButton(
                              label:
                                  'Generate Polygons (${formatNumber(vm.createPolygons)})',
                              icon: Icons.change_history,
                              onPressed: () => vm.generatePolygons(
                                  shapeCount: vm.createPolygons),
                            ),
                            _ActionButton(
                              label:
                                  'Generate Polylines (${formatNumber(vm.createPolylines)})',
                              icon: Icons.timeline,
                              onPressed: () => vm.generatePolylines(
                                  shapeCount: vm.createPolylines),
                            ),
                            _ActionButton(
                              label: 'Generate 1 Polyline (for playback)',
                              icon: Icons.add_road,
                              onPressed: () => vm.generatePlaybackPolyline(),
                            ),
                            _ActionButton(
                              label:
                                  'Generate Circles (${formatNumber(vm.createCircles)})',
                              icon: Icons.circle,
                              onPressed: () => vm.generateCircles(
                                  shapeCount: vm.createCircles),
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
                                const Text('Show titles'),
                                const SizedBox(width: 6),
                                Switch.adaptive(
                                  value: vm.showTitle,
                                  onChanged: (v) => vm.setShowTitle(v),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FormFieldsMap(
                      notifier: vm.mapNotifier,
                      onRequestCurrentLocation: () async => vm.center,
                      showBuiltinPlaybackControls: true,
                      enablePolylinePlayback: true,
                      canvasMarkerRadius: 20.0,
                      canvasMarkerIcon: const Icon(
                        Icons.location_pin,
                        size: 150,
                      ),
                      showTitle: vm.showTitle,
                      onCenterChanged: (value) {
                        debugPrint('onCenterChanged: $value');
                      },
                      // showMarkerInCenter: true,
                      onTapShape: (sm) async {
                        // `sm` is a ShapeMeta
                        final title = sm.title ?? 'Detail';
                        final subtitle = sm.subtitle ?? '';
                        final id = sm.id;
                        final pt = sm.point;

                        if (sm.shapeType == 'marker' ||
                            (id != null && id.startsWith('m\$'))) {
                          await showDialog<void>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: Text(title.toString()),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (subtitle.isNotEmpty) Text(subtitle),
                                    if (id != null) ...[
                                      const SizedBox(height: 8),
                                      Text('ID: $id',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                    if (sm.shapeType != null) ...[
                                      const SizedBox(height: 8),
                                      Text('Type: ${sm.shapeType}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                    ...[
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
                                          // always remove raw marker (markers removed from API)
                                          vm.mapNotifier.removeRawMarker(id);
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
                                ],
                              );
                            },
                          );
                        } else {
                          final shapeId = sm.id;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Tapped: ${sm.shapeType}${shapeId != null ? ' (ID: $shapeId)' : ''}')));
                        }
                      },
                      initialCenter: vm.center,
                      initialZoom: 12.0,
                      onMapTap: (latlng) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Tapped: ${latlng.latitude}, ${latlng.longitude}')));
                      },
                    ),
                  ),
                ],
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
              if (vm.totalPolylines > 0)
                _DraggablePositioned(
                  // initialRight: 0,
                  initWidth: 260,
                  initHeight: 140,
                  initialTop: 0,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Polyline Playback',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: FormFieldsMapController
                                    .getPlaybackPlayingListenable('default'),
                                builder: (context, playing, _) {
                                  return IconButton(
                                    icon: Icon(playing
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                    onPressed: () {
                                      if (playing) {
                                        FormFieldsMapController
                                            .pausePolylinePlayback('default');
                                      } else {
                                        FormFieldsMapController
                                            .startPolylinePlayback('default',
                                                vm.playbackPolylineId);
                                      }
                                    },
                                    tooltip: playing ? 'Pause' : 'Play',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.replay),
                                onPressed: () => FormFieldsMapController
                                    .restartPolylinePlayback('default'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Interval:'),
                              _intervalButton(vm, '0.5s',
                                  const Duration(milliseconds: 500)),
                              _intervalButton(
                                  vm, '1s', const Duration(seconds: 1)),
                              _intervalButton(
                                  vm, '2s', const Duration(seconds: 2)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Interp:'),
                              _interpButton(vm, '0', 0),
                              _interpButton(vm, '2', 2),
                              _interpButton(vm, '4', 4),
                              _interpButton(vm, '8', 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                              'Markers: ${formatNumber(vm.generatedMarkers)}/${formatNumber(vm.totalMarkers)}'),
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
                              'Polygons: ${formatNumber(vm.generatedPolygons)}/${formatNumber(vm.totalPolygons)}'),
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
                              'Polylines: ${formatNumber(vm.generatedPolylines)}/${formatNumber(vm.totalPolylines)}'),
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
                              'Circles: ${formatNumber(vm.generatedCircles)}/${formatNumber(vm.totalCircles)}'),
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

Widget _intervalButton(MapExamplesViewModel vm, String label, Duration d) {
  final selected = vm.playbackInterval.inMilliseconds == d.inMilliseconds;
  return TextButton(
    onPressed: () => vm.setPlaybackInterval(d),
    style: TextButton.styleFrom(
      backgroundColor: selected ? Colors.lightGreen : null,
      foregroundColor: selected ? Colors.white : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(label),
  );
}

Widget _interpButton(MapExamplesViewModel vm, String label, int steps) {
  final selected = vm.playbackInterpolationSteps == steps;
  return TextButton(
    onPressed: () => vm.setPlaybackInterpolationSteps(steps),
    style: TextButton.styleFrom(
      backgroundColor: selected ? Colors.lightGreen : null,
      foregroundColor: selected ? Colors.white : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(label),
  );
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
/// `initialTop` or `initialRight`. For
/// convenience callers can provide estimated `initWidth`/`initHeight` used
/// to compute initial left/top when right is supplied.
class _DraggablePositioned extends StatefulWidget {
  const _DraggablePositioned({
    this.initialTop,
    this.initialRight,
    this.initWidth = 56.0,
    this.initHeight = 56.0,
    required this.child,
  });

  final double? initialTop;
  final double? initialRight;
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
    if (widget.initialRight != null) {
      left = size.width - widget.initialRight! - w;
    } else {
      left = 16.0;
    }

    if (widget.initialTop != null) {
      top = widget.initialTop;
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
