part of '../form_fields_map.dart';

extension _FormFieldsMapRenderX on FormFieldsMapState {
  void _resolveCanvasMarkerIcon() {
    final generation = ++_markerIconGeneration;
    // Clean up any existing image streams/listeners for both images.
    if (_canvasMarkerImageStream != null &&
        _canvasMarkerImageStreamListener != null) {
      _canvasMarkerImageStream!.removeListener(
        _canvasMarkerImageStreamListener!,
      );
    }
    if (_playbackMarkerImageStream != null &&
        _playbackMarkerImageStreamListener != null) {
      _playbackMarkerImageStream!.removeListener(
        _playbackMarkerImageStreamListener!,
      );
    }
    _canvasMarkerImageStream = null;
    _canvasMarkerImageStreamListener = null;
    _playbackMarkerImageStream = null;
    _playbackMarkerImageStreamListener = null;
    _canvasMarkerImage = null;
    _playbackMarkerImage = null;

    final canvasProvider = _canvasMarkerIconEffective;
    final playbackProvider = widget.playbackConfig?.playbackMarkerIcon;

    // Helper to resolve an ImageProvider into an ImageStream and set target
    void attachImageProvider(
      ImageProvider provider,
      void Function(ui.Image) onImage, {
      required bool isPlayback,
    }) {
      final config = createLocalImageConfiguration(context);
      final stream = provider.resolve(config);
      final listener = ImageStreamListener((ImageInfo info, bool _) {
        onImage(info.image);
        _safeSetState(() {});
      });
      stream.addListener(listener);
      if (isPlayback) {
        _playbackMarkerImageStream = stream;
        _playbackMarkerImageStreamListener = listener;
      } else {
        _canvasMarkerImageStream = stream;
        _canvasMarkerImageStreamListener = listener;
      }
    }

    // Rasterize canvas provider if present
    if (canvasProvider != null) {
      if (canvasProvider is ImageProvider) {
        attachImageProvider(canvasProvider, (img) {
          _canvasMarkerImage = img;
          // If playback provider equals canvas provider, mirror image
          if (playbackProvider == canvasProvider) _playbackMarkerImage = img;
        }, isPlayback: false);
      } else if (canvasProvider is Icon) {
        _renderIconToImage(canvasProvider)
            .then((img) {
              if (generation != _markerIconGeneration) return;
              _canvasMarkerImage = img;
              if (playbackProvider == canvasProvider) {
                _playbackMarkerImage = img;
              }
              _safeSetState(() {});
            })
            .catchError((_) {
              // Without a marker image the icon is simply not drawn.
            });
      } else if (canvasProvider is Widget) {
        _rasterizeWidgetToImage(canvasProvider).then((img) {
          if (img != null && generation == _markerIconGeneration) {
            _canvasMarkerImage = img;
            if (playbackProvider == canvasProvider) _playbackMarkerImage = img;
            _safeSetState(() {});
          }
        });
      }
    }

    // Rasterize playback provider if present and different from canvas provider
    if (playbackProvider != null && playbackProvider != canvasProvider) {
      if (playbackProvider is ImageProvider) {
        attachImageProvider(playbackProvider, (img) {
          _playbackMarkerImage = img;
        }, isPlayback: true);
      } else if (playbackProvider is Icon) {
        _renderIconToImage(playbackProvider)
            .then((img) {
              if (generation != _markerIconGeneration) return;
              _playbackMarkerImage = img;
              _safeSetState(() {});
            })
            .catchError((_) {
              // Without a marker image the icon is simply not drawn.
            });
      } else if (playbackProvider is Widget) {
        _rasterizeWidgetToImage(playbackProvider).then((img) {
          if (img != null && generation == _markerIconGeneration) {
            _playbackMarkerImage = img;
            _safeSetState(() {});
          }
        });
      }
    }
  }

  Future<ui.Image> _renderIconToImage(Icon icon) async {
    final iconData = icon.icon;
    final double size = icon.size ?? 24.0;
    final Color color = icon.color ?? Colors.black;

    if (iconData == null) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = color;
      final double r = size / 2.0;
      canvas.drawCircle(Offset(r, r), r, paint);
      final picture = recorder.endRecording();
      return picture.toImage(size.ceil(), size.ceil());
    }

    final textStyle = TextStyle(
      fontFamily: iconData.fontFamily,
      package: iconData.fontPackage,
      fontSize: size,
      color: color,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final w = tp.width.ceil();
    final h = tp.height.ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );
    tp.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w == 0 ? 1 : w, h == 0 ? 1 : h);
    return image;
  }

  Future<ui.Image?> _rasterizeWidgetToImage(
    Widget widget, {
    double logicalSize = 36.0,
  }) async {
    // The overlay entry must come down on every path. A failure after the
    // insert used to leave an invisible box over the map that could absorb
    // touches.
    OverlayEntry? entry;
    try {
      if (!mounted) return null;

      final overlay = Overlay.of(context);

      final key = GlobalKey();
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final created = OverlayEntry(
        builder: (ctx) => Positioned(
          left: 0,
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: logicalSize,
                height: logicalSize,
                child: RepaintBoundary(
                  key: key,
                  child: Center(child: widget),
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(created);
      entry = created;

      await Future.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return null;

      final contextForKey = key.currentContext;
      if (contextForKey == null) return null;

      if (contextForKey is! Element || !contextForKey.mounted) return null;

      final renderObject = contextForKey.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        return await renderObject.toImage(pixelRatio: devicePixelRatio);
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      entry?.remove();
    }
  }
}
