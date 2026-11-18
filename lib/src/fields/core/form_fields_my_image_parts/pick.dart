part of '../form_fields_my_image.dart';

extension _FormFieldsMyImagePickX on _FormFieldsMyImageState {
  Future<void> _pickImage(
    BuildContext context,
    FormFieldsMyImageProvider provider, {
    String? initialSource,
  }) async {
    Future<bool> ensurePermissionForSource(String src) async {
      if (!mounted) return false;
      final ok = await PermissionGate.ensurePickerPermission(
        context,
        source: src,
      );
      if (!mounted) return false;
      return ok;
    }

    File? file;

    // Allowed sources (null = allow all). Use order of list as fallback order.
    final allowed = widget.allowedImageSources;

    MyImageSource? mapStringToSource(String s) {
      switch (s) {
        case 'camera':
          return MyImageSource.camera;
        case 'gallery':
          return MyImageSource.gallery;
        case 'doc':
          return MyImageSource.doc;
        default:
          return null;
      }
    }

    Future<MyImageSource?> normalize(MyImageSource src) async {
      if (allowed == null) return src;
      if (allowed.isEmpty) return null;
      if (allowed.contains(src)) return src;
      return allowed.first;
    }

    Future<void> doDocScan() async {
      final ok = await ensurePermissionForSource('camera');
      if (!ok) return;
      final scanned = await CunningDocumentScanner.scanDocuments(
        scannerSource: ScannerSource.camera,
        noOfPages: 1,
      );
      if (!mounted) return;
      final images = scanned?.images;
      if (images != null && images.isNotEmpty) {
        file = File(images.first);
      }
    }

    Future<void> doPickImage(MyImageSource src) async {
      final pickSource = src == MyImageSource.camera ? 'camera' : 'gallery';
      final ok = await ensurePermissionForSource(pickSource);
      if (!ok) return;
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: src == MyImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (!mounted) return;
      if (picked != null) {
        file = File(picked.path);
      }
    }

    // 1) If caller requested a specific source programmatically
    if (initialSource != null) {
      final requested = mapStringToSource(initialSource);
      if (requested != null) {
        final chosen = await normalize(requested);
        if (chosen == null) return;
        if (chosen == MyImageSource.doc) {
          await doDocScan();
        } else {
          await doPickImage(chosen);
        }
      } else {
        // unknown string -> fall back to chooser behavior below
      }
    }

    // 2) If nothing picked yet, determine source from `allowedImageSources`
    if (file == null) {
      // Build effective options: `null` => default camera+gallery.
      final options = <MyImageSource>[];
      if (allowed == null) {
        options.addAll([MyImageSource.camera, MyImageSource.gallery]);
      } else {
        for (final s in allowed) {
          if (!options.contains(s)) {
            options.add(s);
          }
        }
      }
      if (options.isEmpty) return;

      MyImageSource effective;
      if (options.length == 1) {
        effective = options.first;
      } else {
        if (!context.mounted) return;
        final selection = await showAppModalBottomSheet<MyImageSource>(
          context: context,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          isDismissible: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (dialogContext) {
            return SafeArea(
              child: SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (options.contains(MyImageSource.camera))
                      AppButton(
                        type: AppButtonType.icon,
                        onPressed: () {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, MyImageSource.camera);
                        },
                        icon: Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: resolveActiveColor(dialogContext, null),
                        ),
                        margin: const EdgeInsets.only(right: 24),
                      ),
                    if (options.contains(MyImageSource.gallery)) ...[
                      SizedBox(width: 16),
                      AppButton(
                        type: AppButtonType.icon,
                        onPressed: () {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, MyImageSource.gallery);
                        },
                        icon: Icon(
                          Icons.photo_library,
                          size: 32,
                          color: Theme.of(dialogContext).colorScheme.secondary,
                        ),
                        margin: const EdgeInsets.only(left: 24),
                      ),
                    ],
                    if (options.contains(MyImageSource.doc)) ...[
                      SizedBox(width: 16),
                      AppButton(
                        type: AppButtonType.icon,
                        onPressed: () {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, MyImageSource.doc);
                        },
                        icon: Icon(
                          Icons.sticky_note_2,
                          size: 32,
                          color: Theme.of(dialogContext).colorScheme.primary,
                        ),
                        margin: const EdgeInsets.only(left: 24),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
        if (!mounted) return;
        if (selection == null) return;
        effective = selection;
      }

      if (effective == MyImageSource.doc) {
        await doDocScan();
      } else {
        await doPickImage(effective);
      }
    }
    if (!mounted) return;
    if (file != null) {
      int? uploadIdx;
      String? pickedDescription;
      if (widget.showDesc) {
        if (!context.mounted) return;
        try {
          final desc = await showAppModalBottomSheet<String>(
            context: context,
            builder: (ctx) => ImageDescriptionSheet(),
          );
          if (desc != null && desc.trim().isNotEmpty) {
            pickedDescription = desc.trim();
          }
        } catch (_) {}
      }

      // Add a quick placeholder so UI shows an immediate tile/loading state
      final placeholder = MyImageResult(
        link: '',
        base64: '',
        path: file!.path,
        description: pickedDescription ?? '',
        status: widget.isDirectUpload
            ? MyImageStatus.uploading
            : MyImageStatus.idle,
      );
      if (widget.maxImages == 1) {
        bool isNew =
            provider.images.isEmpty ||
            provider.images[0].path != placeholder.path;
        provider.clearImages();
        provider.addImage(placeholder);
        uploadIdx = 0;
        if (isNew) {
          provider.setUploadProgress(0, 0.0);
        }
        _syncControllerImages(provider);
        if (!widget.isDirectUpload) {
          widget.onImagesChanged?.call(
            List<MyImageResult>.from(provider.images),
          );
        }
        if (!widget.isDirectUpload) {
          widget.onImageChanged?.call(placeholder);
        }
      } else if (widget.maxImages == null) {
        provider.addImage(placeholder);
        uploadIdx = provider.images.length - 1;
        if (provider.uploadProgress.length < provider.images.length) {
          provider.setUploadProgress(provider.images.length - 1, 0.0);
        }
        _syncControllerImages(provider);
        if (!widget.isDirectUpload) {
          widget.onImagesChanged?.call(
            List<MyImageResult>.from(provider.images),
          );
        }
      } else {
        if (provider.images.length < widget.maxImages!) {
          provider.addImage(placeholder);
          uploadIdx = provider.images.length - 1;
          if (provider.uploadProgress.length < provider.images.length) {
            provider.setUploadProgress(provider.images.length - 1, 0.0);
          }
          _syncControllerImages(provider);
          if (!widget.isDirectUpload) {
            widget.onImagesChanged?.call(
              List<MyImageResult>.from(provider.images),
            );
          }
        }
      }

      // Start compression in background (doesn't block UI thanks to compute)
      final result = await MyImageResult.fromFile(
        file!,
        description: pickedDescription,
        quality: widget.quality,
      );
      if (!mounted) return;
      // Replace placeholder with real result
      if (uploadIdx != null &&
          uploadIdx >= 0 &&
          uploadIdx < provider.images.length) {
        provider.updateImage(uploadIdx, result);
        _syncControllerImages(provider);
        if (!widget.isDirectUpload) {
          if (widget.maxImages == 1) {
            widget.onImageChanged?.call(result);
          } else {
            widget.onImagesChanged?.call(
              List<MyImageResult>.from(provider.images),
            );
          }
        }
      }

      if (widget.isDirectUpload && uploadIdx != null) {
        _uploadingIndex = uploadIdx;
        provider.commit();
        await _uploadImageDio(provider, result, uploadIdx);
        if (!mounted) return;
        _uploadingIndex = null;
        provider.commit();
      }
    }
  }
}
