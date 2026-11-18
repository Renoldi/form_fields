part of '../form_fields_my_image.dart';

extension _FormFieldsMyImageViewX on _FormFieldsMyImageState {
  Widget _buildUploadOverlay(
    BuildContext context, {
    required double progress,
    required double cardWidth,
  }) {
    final myImageTheme =
        Theme.of(context).extension<FormFieldsMyImageThemeData>() ??
        const FormFieldsMyImageThemeData.fallback();
    final loadingTheme =
        Theme.of(context).extension<AppLoadingThemeData>() ??
        const AppLoadingThemeData.fallback();
    final progressTheme = Theme.of(context).progressIndicatorTheme;
    final progressColor = myImageTheme.addTileBorderColor;
    final progressTrackColor =
        progressTheme.linearTrackColor ?? progressColor.withValues(alpha: .22);
    return Container(
      color: loadingTheme.overlayColor,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: cardWidth,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: progressColor.withValues(alpha: .20)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: .25),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: AppProgressIndicator(
              type: AppProgressType.linear,
              value: progress,
              minHeight: 6,
              color: progressColor,
              trackColor: progressTrackColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImageWidget(
    BuildContext context,
    FormFieldsMyImageProvider provider,
  ) {
    final hasImage = provider.images.isNotEmpty;
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.allow ? () => _pickImage(context, provider) : null,
          child: Stack(
            key: ValueKey(
              provider.uploadProgress.isNotEmpty
                  ? provider.uploadProgress[0]
                  : 0.0,
            ),
            alignment: Alignment.center,
            children: [
              _buildImageDisplay(
                context,
                hasImage ? provider.images[0] : null,
                0,
                isSingle: true,
              ),
              if (hasImage && _shouldShowUploadOverlay(provider, 0))
                Positioned.fill(
                  child: _buildUploadOverlay(
                    context,
                    progress: provider.uploadProgress[0],
                    cardWidth: 82,
                  ),
                ),
            ],
          ),
        ),
        if (hasImage)
          Positioned(
            top: 0,
            right: 0,
            child: _buildRemoveButton(context, 0, provider.images[0], () {
              final removed = provider.images[0];
              provider.removeImage(0);
              _syncControllerImages(provider);
              widget.onRemoveImage?.call(0, removed);
              // Documented contract: onImagesChanged fires after every change
              // to the list, removals included. Without this call the parent
              // keeps the removed image.
              widget.onImagesChanged?.call(
                List<MyImageResult>.from(provider.images),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildImageDisplay(
    BuildContext context,
    MyImageResult? image,
    int index, {
    bool isSingle = false,
  }) {
    if (image == null) {
      if (widget.imageBuilder != null) {
        return SizedBox(
          width: _FormFieldsMyImageState._tileSize,
          height: _FormFieldsMyImageState._tileSize,
          child: widget.imageBuilder!(context, MyImageResult(), index),
        );
      }
      // Single-image default: show an add-tile (plus) placeholder.
      if (isSingle) {
        final active = resolveActiveColor(context, null);
        return Container(
          width: _FormFieldsMyImageState._tileSize,
          height: _FormFieldsMyImageState._tileSize,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active, width: 2),
          ),
          child: Center(child: Icon(Icons.image, size: 32, color: active)),
        );
      }
      if (!widget.isDirectUpload) {
        final active = resolveActiveColor(context, null);
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active, width: 2),
          ),
          child: Center(child: Icon(Icons.add, size: 32, color: active)),
        );
      }
      final active = resolveActiveColor(context, null);
      return Container(
        width: _FormFieldsMyImageState._tileSize,
        height: _FormFieldsMyImageState._tileSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active, width: 2),
        ),
        child: Center(child: Icon(Icons.add, size: 32, color: active)),
      );
    }
    if (widget.imageBuilder != null) {
      return SizedBox(
        width: _FormFieldsMyImageState._tileSize,
        height: _FormFieldsMyImageState._tileSize,
        child: widget.imageBuilder!(context, image, index),
      );
    }
    final hasLocalPath =
        image.path.trim().isNotEmpty && File(image.path).existsSync();
    final hasBase64 = image.base64.trim().isNotEmpty;
    Widget displayed;
    if (hasLocalPath) {
      displayed = Image.file(
        File(image.path),
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      );
    } else if (hasBase64) {
      // Decoded here for display only. Inside `build` this runs on every
      // rebuild, so the decode must stay cheap and must not throw.
      final bytes = decodeBase64Image(image.base64);
      if (bytes == null) {
        displayed = Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            color: Theme.of(context).disabledColor,
          ),
        );
      } else {
        displayed = Image.memory(
          bytes,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return Stack(
              fit: StackFit.expand,
              children: [
                child,
                const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        );
      }
    } else if (image.link.trim().isNotEmpty) {
      displayed = Image.network(
        image.link,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      );
    } else {
      displayed = Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 48,
            color: resolveTextColor(context, muted: true),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _FormFieldsMyImageState._tileSize,
        height: _FormFieldsMyImageState._tileSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: displayed),
            // Small status indicator (top-left)
            if (image.status != MyImageStatus.idle)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: .18),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    image.status == MyImageStatus.uploading
                        ? Icons.cloud_upload
                        : image.status == MyImageStatus.queued
                        ? Icons.schedule
                        : image.status == MyImageStatus.failed
                        ? Icons.error_outline
                        : Icons.check_circle,
                    size: 14,
                    color: image.status == MyImageStatus.failed
                        ? Theme.of(context).colorScheme.error
                        : resolveTextColor(context),
                  ),
                ),
              ),
            if (image.description.trim().isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: .72),
                  child: Text(
                    image.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: resolveTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveButton(
    BuildContext context,
    int index,
    MyImageResult image,
    VoidCallback onRemove,
  ) {
    if (!widget.allow) {
      return const SizedBox.shrink();
    }
    if (widget.removeIconBuilder != null) {
      return GestureDetector(
        onTap: onRemove,
        child: widget.removeIconBuilder!(context, index, image),
      );
    }
    return IconButton(
      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
      onPressed: onRemove,
    );
  }

  List<Widget> _buildMultiImageWidgets(
    BuildContext context,
    FormFieldsMyImageProvider provider,
  ) {
    final myImageTheme =
        Theme.of(context).extension<FormFieldsMyImageThemeData>() ??
        const FormFieldsMyImageThemeData.fallback();
    final images = provider.images;
    final uploadProgress = provider.uploadProgress;
    final widgets = <Widget>[];
    final max = widget.maxImages ?? images.length + 1;
    for (int idx = 0; idx < max; idx++) {
      if (idx < images.length) {
        widgets.add(
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: _buildImageDisplay(context, images[idx], idx),
                ),
              ),
              if (images.isNotEmpty && _shouldShowUploadOverlay(provider, idx))
                Positioned.fill(
                  child: _buildUploadOverlay(
                    context,
                    progress: uploadProgress[idx],
                    cardWidth: 82,
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: _buildRemoveButton(context, idx, images[idx], () {
                  final removed = images[idx];
                  provider.removeImage(idx);
                  _syncControllerImages(provider);
                  widget.onRemoveImage?.call(idx, removed);
                  widget.onImagesChanged?.call(
                    List<MyImageResult>.from(provider.images),
                  );
                }),
              ),
            ],
          ),
        );
      } else {
        widgets.add(
          SafeArea(
            child: GestureDetector(
              onTap: widget.allow ? () => _pickImage(context, provider) : null,
              child: widget.plusBuilder != null
                  ? widget.plusBuilder!(context)
                  : Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: myImageTheme.addTileBorderColor,
                          width: myImageTheme.addTileBorderWidth,
                        ),
                        borderRadius: BorderRadius.circular(
                          myImageTheme.addTileBorderRadius,
                        ),
                        color: myImageTheme.addTileBackgroundColor,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          color: myImageTheme.addIconColor,
                          size: 32,
                        ),
                      ),
                    ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
