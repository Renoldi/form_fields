import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:form_fields/src/models/shape_meta.dart';
import 'package:latlong2/latlong.dart';

/// Utilities
/// Reads a coordinate or rotation value. Returns null for anything that is not
/// a finite number, so malformed input is skipped instead of thrown.
double? _coordinate(Object? value) {
  final d = value is num
      ? value.toDouble()
      : (value is String ? double.tryParse(value.trim()) : null);
  return (d != null && d.isFinite) ? d : null;
}

double pointToSegmentDistance(Offset p, Offset v, Offset w) {
  final l2 = pow((v.dx - w.dx), 2) + pow((v.dy - w.dy), 2);
  if (l2 == 0) return (p - v).distance;
  var t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
  t = t.clamp(0.0, 1.0);
  final proj = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
  return (p - proj).distance;
}

bool pointInPolygon(LatLng p, List<LatLng> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].longitude;
    final yi = polygon[i].latitude;
    final xj = polygon[j].longitude;
    final yj = polygon[j].latitude;

    final intersect =
        ((yi > p.latitude) != (yj > p.latitude)) &&
        (p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi + 0.0) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

/// Public painter extracted from `form_fields_map.dart` to enable reuse
/// A composed pin: halo, white outline and tinted icon in one image. [size] is
/// in device pixels.
class _PinSprite {
  const _PinSprite(this.image, this.size);

  final ui.Image image;
  final double size;
}

/// Composed pins by color and size. Dart maps keep insertion order, so a hit is
/// moved to the end and the oldest entry is evicted. Evicted images are not
/// disposed, because a picture recorded in the same frame may still use them.
final Map<String, _PinSprite> _pinSpriteCache = <String, _PinSprite>{};
const int _pinSpriteCacheSize = 48;

_PinSprite _pinSprite(
  ui.Image icon,
  Color markerColor,
  double haloAlpha,
  double destSize,
  double haloScale,
  double devicePixelRatio,
) {
  final key =
      '${identityHashCode(icon)}|${markerColor.toARGB32()}|$haloAlpha|'
      '$destSize|$haloScale|$devicePixelRatio';
  final hit = _pinSpriteCache.remove(key);
  if (hit != null) {
    _pinSpriteCache[key] = hit;
    return hit;
  }

  final logicalSize = destSize * haloScale;
  final pixels = (logicalSize * devicePixelRatio).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, pixels.toDouble(), pixels.toDouble()),
  );
  canvas.scale(devicePixelRatio);
  final src = Rect.fromLTWH(
    0,
    0,
    icon.width.toDouble(),
    icon.height.toDouble(),
  );
  final center = Offset(logicalSize / 2, logicalSize / 2);
  Rect square(double side) =>
      Rect.fromCenter(center: center, width: side, height: side);

  canvas.drawImageRect(
    icon,
    src,
    square(logicalSize),
    Paint()
      ..isAntiAlias = true
      ..colorFilter = ColorFilter.mode(
        markerColor.withValues(alpha: haloAlpha),
        BlendMode.srcIn,
      ),
  );
  canvas.drawImageRect(
    icon,
    src,
    square(destSize * 1.5),
    Paint()
      ..isAntiAlias = true
      ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn),
  );
  canvas.drawImageRect(
    icon,
    src,
    square(destSize),
    Paint()
      ..isAntiAlias = true
      ..colorFilter = ColorFilter.mode(markerColor, BlendMode.srcIn),
  );

  final image = recorder.endRecording().toImageSync(pixels, pixels);
  final sprite = _PinSprite(image, pixels.toDouble());
  _pinSpriteCache[key] = sprite;
  if (_pinSpriteCache.length > _pinSpriteCacheSize) {
    _pinSpriteCache.remove(_pinSpriteCache.keys.first);
  }
  return sprite;
}

/// Laid-out titles, reused while the map is panned or zoomed. Without this,
/// each visible title is laid out again on every frame. Dart maps keep their
/// insertion order, so removing and re-inserting a key gives least-recently-used
/// eviction. Evicted layouts are not disposed, because a picture recorded in
/// the same frame may still reference them.
final Map<String, TextPainter> _labelCache = <String, TextPainter>{};
const int _labelCacheSize = 256;

TextPainter _layoutLabel(List<String> lines, double fontSize, double maxWidth) {
  final key = '$fontSize|$maxWidth|${lines.join('\u0001')}';
  final hit = _labelCache.remove(key);
  if (hit != null) {
    _labelCache[key] = hit;
    return hit;
  }
  final textStyle = TextStyle(
    color: Colors.black,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
  );
  final tp = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    text: TextSpan(
      children: lines
          .map((l) => TextSpan(text: '$l\n', style: textStyle))
          .toList(),
    ),
  );
  tp.layout(minWidth: 0, maxWidth: maxWidth);
  _labelCache[key] = tp;
  if (_labelCache.length > _labelCacheSize) {
    _labelCache.remove(_labelCache.keys.first);
  }
  return tp;
}

/// Most titles drawn in one frame. Each title costs a text layout, so the cap
/// keeps panning and zooming smooth when many markers are on screen.
const int maxLabelsPerFrame = 60;

class CanvasRawMarkerPainter extends CustomPainter {
  CanvasRawMarkerPainter({
    required this.rawMarkers,
    this.rawRevision = 0,
    required this.center,
    required this.zoom,
    required this.radius,
    required this.devicePixelRatio,
    this.iconImage,
    this.playbackIconImage,
    this.playbackHaloColor,
    this.playbackHaloScale = 1.6,
    this.playbackHaloOpacity = 0.95,
    this.showTitle = true,
    required this.defaultColor,
    this.foregroundColor,
  });

  final List<dynamic> rawMarkers;

  /// Changes when the entries change in place. The list keeps its identity,
  /// so the painter repaints on this value rather than on the list itself.
  final int rawRevision;
  final LatLng center;
  final double zoom;
  final double radius;
  final double devicePixelRatio;
  final ui.Image? iconImage;
  final ui.Image? playbackIconImage;
  final Color? playbackHaloColor;
  final double playbackHaloScale;
  final double playbackHaloOpacity;
  final bool showTitle;
  final Color defaultColor;
  final Color? foregroundColor;

  static double worldX(double lon, double zoom) {
    final double worldSize = 256 * pow(2, zoom).toDouble();
    return (lon + 180) / 360 * worldSize;
  }

  static double worldY(double lat, double zoom) {
    final double worldSize = 256 * pow(2, zoom).toDouble();
    final sinLat = sin(lat * pi / 180);
    final y = 0.5 - (log((1 + sinLat) / (1 - sinLat)) / (4 * pi));
    return y * worldSize;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Same style for every pin, so it is created once per frame.
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, devicePixelRatio * 0.6);
    // Titles need a TextPainter layout per marker, which is the most expensive
    // part of a frame. Only a limited number are drawn each frame, so dense or
    // zoomed-out views stay responsive.
    var labelsDrawn = 0;
    // Pin dedupe: one pin per cell of this size (see the pin draw below).
    final pinCellSize = max(6.0, radius * 0.5);
    final occupiedPinCells = <int>{};

    final centerX = worldX(center.longitude, zoom);
    final centerY = worldY(center.latitude, zoom);
    final double worldSize = 256 * pow(2, zoom).toDouble();

    for (var i = 0; i < rawMarkers.length; i++) {
      final m = rawMarkers[i];
      double lat;
      double lon;
      String? title;
      String? subtitle;
      String? shapeType;
      double rotationDeg = 0.0;
      if (m is ShapeMeta) {
        final pms = (m.pointMetas != null && m.pointMetas!.isNotEmpty)
            ? m.pointMetas!
            : null;
        if (pms == null) continue;
        // Place title for non-marker shapes at a simple-average centroid
        // (average of vertex coordinates). For marker shapes, use the
        // first PointMeta (its explicit point).
        shapeType = m.shapeType;
        if (shapeType == ShapeTypes.polygon ||
            shapeType == ShapeTypes.polyline) {
          double sumLat = 0.0, sumLon = 0.0;
          for (final pm in pms) {
            sumLat += pm.lat;
            sumLon += pm.lon;
          }
          lat = sumLat / pms.length;
          lon = sumLon / pms.length;
          // Prefer top-level title/subtitle for shapes like polygons/polylines
          title = m.hit?.title ?? pms.first.hit?.title;
          subtitle = m.hit?.subtitle ?? pms.first.hit?.subtitle;
          rotationDeg = pms.first.rotation ?? 0.0;
        } else {
          final pm = pms.first;
          lat = pm.lat;
          lon = pm.lon;
          title = pm.hit?.title ?? m.hit?.title;
          subtitle = pm.hit?.subtitle ?? m.hit?.subtitle;
          rotationDeg = pm.rotation ?? 0.0;
        }
      } else if (m is LatLng) {
        lat = m.latitude;
        lon = m.longitude;
      } else if (m is List && m.length >= 2) {
        // Skip malformed entries. A cast that throws here fails the whole
        // paint, so one bad marker blanked every marker on the map.
        final la = _coordinate(m[0]);
        final lo = _coordinate(m[1]);
        if (la == null || lo == null) continue;
        lat = la;
        lon = lo;
        if (m.length >= 3) title = m[2]?.toString();
        if (m.length >= 4) subtitle = m[3]?.toString();
        if (m.length >= 5) shapeType = m[4]?.toString();
      } else if (m is Map) {
        // A marker without coordinates is skipped rather than drawn at 0,0.
        final la = _coordinate(m['lat']) ?? _coordinate(m['latitude']);
        final lo = _coordinate(m['lon']) ?? _coordinate(m['longitude']);
        if (la == null || lo == null) continue;
        lat = la;
        lon = lo;
        title = m['title']?.toString();
        subtitle = m['subtitle']?.toString();
        shapeType = m['shapeType']?.toString();
        rotationDeg =
            _coordinate(m['rotation']) ??
            _coordinate(m['bearing']) ??
            rotationDeg;
      } else {
        continue;
      }
      final x = worldX(lon, zoom);
      final y = worldY(lat, zoom);

      var dx = (x - centerX) + size.width / 2;
      var dy = (y - centerY) + size.height / 2;

      if (dx.abs() > worldSize / 2) {
        if (dx > 0) {
          dx -= worldSize;
        } else {
          dx += worldSize;
        }
      }

      var radiusToUse = max(radius, 6.0);
      // allow per-marker radius override from properties or map payload
      double? propRadius;
      if (m is ShapeMeta) {
        final rpv = m.properties == null
            ? null
            : (m.properties!['radius'] ?? m.properties!['size']);
        if (rpv != null) {
          if (rpv is num) {
            propRadius = rpv.toDouble();
          } else if (rpv is String) {
            try {
              propRadius = double.parse(rpv);
            } catch (_) {}
          }
        }
      } else if (m is Map) {
        final rpv = m['radius'] ?? m['size'];
        if (rpv != null) {
          if (rpv is num) {
            propRadius = rpv.toDouble();
          } else if (rpv is String) {
            try {
              propRadius = double.parse(rpv);
            } catch (_) {}
          }
        }
      }
      if (propRadius != null) radiusToUse = max(radiusToUse, propRadius);
      if (dx < -radiusToUse ||
          dx > size.width + radiusToUse ||
          dy < -radiusToUse ||
          dy > size.height + radiusToUse) {
        continue;
      }

      // Draw a simple pin icon: circular head + triangular tail.
      final pinPaint = paint;
      Color? metaColor;
      String? propIconName;
      if (m is ShapeMeta) {
        // properties.color takes precedence over top-level color
        if (m.properties != null && m.properties!['color'] != null) {
          try {
            metaColor = ShapeMeta.parseColor(m.properties!['color']);
          } catch (_) {
            metaColor = m.color;
          }
        } else {
          metaColor = m.color;
        }
        if (m.properties != null && m.properties!['icon'] != null) {
          propIconName = m.properties!['icon']?.toString();
        }
      } else if (m is Map && m['color'] != null) {
        try {
          metaColor = ShapeMeta.parseColor(m['color']);
        } catch (_) {
          metaColor = null;
        }
        if (m['icon'] != null) propIconName = m['icon']?.toString();
      }
      final Color markerColor =
          metaColor ?? defaultColor.withValues(alpha: 0.95);
      pinPaint.color = markerColor;

      final headCenter = Offset(dx, dy - radiusToUse * 0.6);
      final headRadius = radiusToUse * 0.9;

      String? iconName;
      if (m is Map) iconName = m['icon']?.toString();
      // allow properties.icon to override map-provided icon
      if (propIconName != null) iconName = propIconName;
      final drawPin = shapeType == null || shapeType == ShapeTypes.marker;
      var isPlayback = false;
      if (m is Map && m['id'] == 'playback_marker') isPlayback = true;
      if (m is ShapeMeta && m.id == 'playback_marker') isPlayback = true;
      // Pins that land in the same small screen cell as one already drawn
      // this frame are skipped. Overlapping pins cost fill time on every
      // frame, and a dense area can hold thousands of them. This keeps the
      // per-frame draw count bounded by the screen size, not by the number
      // of markers. Playback is never skipped.
      if (drawPin && !isPlayback) {
        // Cells use world coordinates, so they move with the map. A pin keeps
        // its cell while the map is dragged, and the set of drawn pins does not
        // change under the pointer.
        final cx = (x / pinCellSize).floor();
        final cy = (y / pinCellSize).floor();
        if (!occupiedPinCells.add((cx << 32) | cy)) continue;
      }
      if (drawPin) {
        final rotationRad = rotationDeg * pi / 180.0;
        canvas.save();
        canvas.translate(headCenter.dx, headCenter.dy);
        canvas.rotate(rotationRad);
        if (iconName == 'arrow') {
          final arrowPath = ui.Path()
            ..moveTo(0, -headRadius)
            ..lineTo(headRadius, headRadius)
            ..lineTo(headRadius * 0.3, headRadius)
            ..lineTo(headRadius * 0.3, headRadius * 1.6)
            ..lineTo(-headRadius * 0.3, headRadius * 1.6)
            ..lineTo(-headRadius * 0.3, headRadius)
            ..lineTo(-headRadius, headRadius)
            ..close();
          if (isPlayback) {
            final haloPaint = Paint()
              ..color = markerColor.withValues(alpha: 0.95)
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(3.0, devicePixelRatio * 3.0)
              ..strokeJoin = StrokeJoin.round;
            canvas.drawPath(arrowPath, haloPaint);
          }
          canvas.drawPath(arrowPath, pinPaint);
          canvas.drawPath(arrowPath, strokePaint);
        } else {
          final useImage = (isPlayback
              ? playbackIconImage ?? iconImage
              : iconImage);
          if (useImage != null) {
            final src = Rect.fromLTWH(
              0,
              0,
              useImage.width.toDouble(),
              useImage.height.toDouble(),
            );
            final double destSize =
                useImage.width.toDouble() / devicePixelRatio;
            final dst = Rect.fromCenter(
              center: Offset.zero,
              width: destSize,
              height: destSize,
            );

            paint.isAntiAlias = true;
            final oldFilter = paint.colorFilter;
            final outlineRect = Rect.fromCenter(
              center: Offset.zero,
              width: destSize * 1.5,
              height: destSize * 1.5,
            );
            final haloScale = isPlayback ? playbackHaloScale : 1.6;
            final haloAlpha = isPlayback ? playbackHaloOpacity : 0.72;
            final haloRect = Rect.fromCenter(
              center: Offset.zero,
              width: destSize * haloScale,
              height: destSize * haloScale,
            );
            final isPlaybackImage =
                isPlayback &&
                playbackIconImage != null &&
                useImage == playbackIconImage;

            if (isPlaybackImage) {
              // For playback-specific rasterized icons, preserve their original
              // colors (do not tint). Draw a shaped halo by drawing a tinted
              // copy of the rasterized icon behind the original image.
              if (isPlayback) {
                // Determine halo color: prefer explicit `playbackHaloColor`,
                // otherwise fall back to `markerColor`.
                final haloColor = playbackHaloColor ?? markerColor;
                paint.colorFilter = ColorFilter.mode(
                  haloColor.withValues(alpha: haloAlpha),
                  BlendMode.srcIn,
                );
                canvas.drawImageRect(useImage, src, haloRect, paint);

                paint.colorFilter = ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                );
                canvas.drawImageRect(useImage, src, outlineRect, paint);
                paint.colorFilter = oldFilter;
              }
              // Draw original artwork on top without tint.
              canvas.drawImageRect(useImage, src, dst, paint);
            } else {
              // The halo, outline and tinted icon are composed once into a
              // sprite and drawn as one image. Tinting three times per marker
              // with color filters was the main raster cost on dense maps.
              final sprite = _pinSprite(
                useImage,
                markerColor,
                haloAlpha,
                destSize,
                haloScale,
                devicePixelRatio,
              );
              paint.colorFilter = null;
              canvas.drawImageRect(
                sprite.image,
                Rect.fromLTWH(0, 0, sprite.size, sprite.size),
                haloRect,
                paint,
              );
              paint.colorFilter = oldFilter;
            }
          } else {
            // fallback to vector pin when no image available
            if (isPlayback) {
              final haloPaint = Paint()
                ..color = markerColor.withValues(alpha: 0.95)
                ..style = PaintingStyle.stroke
                ..strokeWidth = max(3.0, devicePixelRatio * 3.0);
              canvas.drawCircle(
                Offset.zero,
                headRadius + haloPaint.strokeWidth / 2,
                haloPaint,
              );
            }
            canvas.drawCircle(Offset.zero, headRadius, pinPaint);
            canvas.drawCircle(Offset.zero, headRadius, strokePaint);

            final tailTopY = radiusToUse * 0.5;
            final tailPath = ui.Path()
              ..moveTo(0, radiusToUse * 2.2)
              ..lineTo(-radiusToUse, tailTopY)
              ..lineTo(radiusToUse, tailTopY)
              ..close();
            canvas.drawPath(tailPath, pinPaint);
            canvas.drawPath(tailPath, strokePaint);
          }
        }

        canvas.restore();
      }

      if (showTitle &&
          labelsDrawn < maxLabelsPerFrame &&
          ((title != null && title.isNotEmpty) ||
              (subtitle != null && subtitle.isNotEmpty))) {
        labelsDrawn++;
        final lines = <String>[];
        if (title != null && title.isNotEmpty) lines.add(title);
        if (subtitle != null && subtitle.isNotEmpty) lines.add(subtitle);

        final tp = _layoutLabel(
          lines,
          max(10.0, devicePixelRatio * 6),
          size.width,
        );

        final pad = 4.0;
        final bgWidth = tp.width + pad * 2;
        final bgHeight = tp.height + pad * 2;
        // Pins get their title above the head. Polygons, polylines and circles
        // have no head, so their title sits on the shape's anchor (its centroid).
        final labelCenter = drawPin
            ? Offset(
                headCenter.dx,
                headCenter.dy - headRadius - bgHeight / 2 - 6,
              )
            : Offset(dx, dy);
        final bgRect = Rect.fromCenter(
          center: labelCenter,
          width: bgWidth,
          height: bgHeight,
        );

        final rrect = RRect.fromRectAndRadius(bgRect, Radius.circular(4));
        final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
        canvas.drawRRect(rrect, bgPaint);

        tp.paint(canvas, Offset(bgRect.left + pad, bgRect.top + pad));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasRawMarkerPainter oldDelegate) {
    return oldDelegate.rawMarkers != rawMarkers ||
        oldDelegate.rawRevision != rawRevision ||
        oldDelegate.center != center ||
        oldDelegate.zoom != zoom ||
        oldDelegate.iconImage != iconImage ||
        oldDelegate.playbackIconImage != playbackIconImage ||
        oldDelegate.playbackHaloColor != playbackHaloColor ||
        oldDelegate.playbackHaloScale != playbackHaloScale ||
        oldDelegate.playbackHaloOpacity != playbackHaloOpacity ||
        oldDelegate.showTitle != showTitle ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
