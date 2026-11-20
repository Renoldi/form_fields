part of '../form_fields_my_image.dart';

extension _FormFieldsMyImageSyncX on _FormFieldsMyImageState {
  void _onControllerChanged() {
    if (_controller != null) {
      _provider.setImages(_controller!.images);
    }
  }

  void _onProviderChanged() {
    // Compute the new value early.
    final newValue = List<MyImageResult>.from(_provider.images);

    void applyChangeIfNeeded() {
      if (!mounted) return;
      final currentState = _formFieldKey.currentState;
      final currentValue = currentState?.value;

      bool equal = false;
      if (currentValue == null && (newValue.isEmpty)) {
        equal = true;
      } else if (currentValue != null &&
          currentValue.length == newValue.length) {
        equal = true;
        for (var i = 0; i < currentValue.length; i++) {
          final a = currentValue[i];
          final b = newValue[i];
          if (a.path != b.path ||
              a.imageId != b.imageId ||
              a.link != b.link ||
              a.base64 != b.base64 ||
              a.description != b.description) {
            equal = false;
            break;
          }
        }
      }

      if (!equal) {
        currentState?.didChange(newValue);
      }
    }

    // Apply immediately to avoid races where callers call Form.validate()
    // before the FormField receives the updated value.
    applyChangeIfNeeded();
    // Update manager registry for quick correlation-id -> location mapping.
    try {
      OfflineUploadManager.instance.updateProviderLocations(
        _provider,
        newValue,
      );
    } catch (_) {}
  }

  void _syncControllerImages(FormFieldsMyImageProvider provider) {
    _controller?.images = List<MyImageResult>.from(provider.images);
  }

  bool _shouldShowUploadOverlay(
    FormFieldsMyImageProvider provider,
    int index, {
    bool requireActiveUploadingIndex = true,
  }) {
    if (!widget.isDirectUpload) return false;
    if (index < 0 || index >= provider.uploadProgress.length) return false;
    final progress = provider.uploadProgress[index];
    if (progress <= 0.0) return false;
    if (requireActiveUploadingIndex && _uploadingIndex != index) return false;
    return true;
  }

  String? _validateImages(List<MyImageResult>? images) {
    if (widget.externalErrorText != null) return widget.externalErrorText;
    if (widget.validator != null) return widget.validator!(images);

    // Some race conditions can cause the `images` passed here to be empty
    // even though the provider already contains images (e.g. user picked an
    // image and FormField state hasn't been updated yet). Use provider as a
    // fallback so validation doesn't falsely fail.
    final effectiveImages = (images == null || images.isEmpty)
        ? _provider.images
        : images;

    if (widget.isRequired && (effectiveImages.isEmpty)) {
      final l = _localizations;
      if (l == null) return '';
      final raw = widget.label;
      return (raw != null && raw.isNotEmpty)
          ? l.getWithLabel('imageRequired', raw.toTitleCases)
          : l.get('imageRequiredDefault');
    }
    return null;
  }
}
