import 'package:flutter/material.dart';

class FullscreenImage extends StatelessWidget {
  const FullscreenImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.elevation = 2,
    this.semanticLabel,
    this.enableZoom = true,
    this.minScale = 1.0,
    this.maxScale = 3.0,
  });

  final String imageUrl;
  final String heroTag;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double elevation;
  final String? semanticLabel;
  final bool enableZoom;
  final double minScale;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: elevation,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => FullscreenImagePage(
                imageUrl: imageUrl,
                heroTag: heroTag,
                semanticLabel: semanticLabel,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Hero(
            tag: heroTag,
            child: SizedBox(
              width: width,
              height: height,
              child: Image.network(
                imageUrl,
                fit: fit,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FullscreenImagePage extends StatefulWidget {
  const FullscreenImagePage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.semanticLabel,
    this.enableZoom = true,
    this.minScale = 1.0,
    this.maxScale = 3.0,
  });

  final String imageUrl;
  final String heroTag;
  final String? semanticLabel;
  final bool enableZoom;
  final double minScale;
  final double maxScale;

  @override
  State<FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends State<FullscreenImagePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // defaults are provided by the widget fields

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          if (_animation != null) {
            _transformationController.value = _animation!.value;
          }
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.enableZoom) return;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final target = (currentScale <= widget.minScale + 0.1)
        ? widget.maxScale
        : widget.minScale;
    final begin = _transformationController.value.clone();
    final end = Matrix4.diagonal3Values(target, target, 1.0);
    _animation = Matrix4Tween(
      begin: begin,
      end: end,
    ).animate(_animationController);
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [],
      ),
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: Hero(
              tag: widget.heroTag,
              child: InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: true,
                minScale: widget.enableZoom ? widget.minScale : 1.0,
                maxScale: widget.enableZoom ? widget.maxScale : 1.0,
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image,
                      size: 72,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
