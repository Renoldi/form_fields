import 'dart:io';
import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class FormFieldsMyImage extends StatefulWidget {
  final FormFieldsMyImageController? controller;

  /// Callback untuk perubahan daftar gambar (multi-image, kompatibilitas lama)
  final void Function(List<MyimageResult> results)? onImagesChanged;

  /// Callback untuk perubahan gambar pada mode single image (maxImages == 1)
  /// Dipanggil setiap kali gambar dipilih atau diganti.
  final void Function(MyimageResult image)? onImageChanged;
  final String? label;

  /// Position of the label relative to the image widget.
  /// Supports [LabelPosition.top], [LabelPosition.bottom],
  /// [LabelPosition.left], [LabelPosition.right] and [LabelPosition.none].
  final LabelPosition labelPosition;

  /// Custom text style for the label.
  final TextStyle? labelTextStyle;

  final bool isDoc;
  final int? maxImages;
  final Widget Function(BuildContext context, MyimageResult image, int index)?
      imageBuilder;
  final Widget Function(BuildContext context, int index, MyimageResult image)?
      removeIconBuilder;

  /// Callback saat gambar dihapus.
  /// Pada mode single image, index selalu 0.
  final void Function(int index, MyimageResult image)? onRemoveImage;
  final Widget Function(BuildContext context)? plusBuilder;
  final String? uploadUrl;
  final String? uploadToken;
  final bool isDirectUpload;
  // Customizable upload messages
  final String? uploadSuccessTitle;
  final String? uploadFailedTitle;
  final String? uploadErrorTitle;
  final String? uploadSuccessMessage;
  final String? uploadFailedMessage;
  final String? uploadErrorMessage;
  final String uploadFileUrlKey;
  final String uploadImageIdKey;

  final bool allow;
  final bool showUploadResultDialog;

  final bool showDesc;
  final String? descriptionField;

  // ── Validation ──────────────────────────────────────────────────────────────

  /// Whether this field is required. Shows error when no images are present.
  final bool isRequired;

  /// Custom validator. Receives the current images list.
  /// Return an error string, or null if valid.
  final String? Function(List<MyimageResult>?)? validator;

  /// Controls when validation errors are shown (default: onUserInteraction).
  final AutovalidateMode autovalidateMode;

  /// Error text injected from external (e.g. backend validation).
  /// Always displayed when non-null, regardless of [autovalidateMode].
  final String? externalErrorText;

  FormFieldsMyImage({
    super.key,
    this.controller,
    this.onImagesChanged,
    this.onImageChanged,
    this.label,
    this.labelPosition = LabelPosition.none,
    this.labelTextStyle,
    this.isDoc = false,
    this.maxImages,
    this.imageBuilder,
    this.onRemoveImage,
    this.plusBuilder,
    this.removeIconBuilder,
    this.uploadUrl,
    this.uploadToken,
    this.isDirectUpload = false,
    this.uploadSuccessTitle,
    this.uploadFailedTitle,
    this.uploadErrorTitle,
    this.uploadSuccessMessage,
    this.uploadFailedMessage,
    this.uploadErrorMessage,
    this.uploadFileUrlKey = 'fileUrl',
    this.uploadImageIdKey = 'imageId',
    this.allow = true,
    this.showUploadResultDialog = false,
    this.showDesc = false,
    this.descriptionField,
    this.isRequired = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.externalErrorText,
  }) {
    assert(
      isDirectUpload == false || (uploadUrl != null && uploadUrl!.isNotEmpty),
      "For direct upload, uploadUrl must be provided and non-empty.",
    );
  }

  @override
  State<FormFieldsMyImage> createState() => _FormFieldsMyImageState();
}

class _FormFieldsMyImageState extends State<FormFieldsMyImage> {
  String? _lastDescription;
  late FormFieldsMyImageProvider _provider;
  int? _uploadingIndex;
  FormFieldsMyImageController? _controller;

  final _formFieldKey = GlobalKey<FormFieldState<List<MyimageResult>>>();
  FormFieldsLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _provider = FormFieldsMyImageProvider();
    _provider.addListener(_onProviderChanged);
    if (widget.controller != null) {
      _controller = widget.controller;
      _provider.setImages(_controller!.images);
      _controller!.addListener(_onControllerChanged);
      widget.controller!.registerPickImageHandler(
        (source) => _pickImage(context, _provider, initialSource: source),
      );
    } else {
      _controller = FormFieldsMyImageController();
      _provider.setImages(_controller!.images);
      _controller!.addListener(_onControllerChanged);
    }
    _uploadingIndex = null;
  }

  @override
  void didUpdateWidget(FormFieldsMyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalErrorText != oldWidget.externalErrorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formFieldKey.currentState?.validate();
      });
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.unregisterPickImageHandler();
      oldWidget.controller?.removeListener(_onControllerChanged);
      if (widget.controller != null) {
        _controller = widget.controller;
        _provider.setImages(_controller!.images);
        _controller!.addListener(_onControllerChanged);
        widget.controller!.registerPickImageHandler(
          (source) => _pickImage(context, _provider, initialSource: source),
        );
      }
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    if (widget.controller != null) {
      widget.controller!.unregisterPickImageHandler();
    }
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller != null) {
      _provider.setImages(_controller!.images);
    }
  }

  void _onProviderChanged() {
    _formFieldKey.currentState
        ?.didChange(List<MyimageResult>.from(_provider.images));
  }

  void _syncControllerImages(FormFieldsMyImageProvider provider) {
    _controller?.images = List<MyimageResult>.from(provider.images);
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

  Widget _buildUploadOverlay(
    BuildContext context, {
    required double progress,
    required double cardWidth,
  }) {
    final loadingTheme = Theme.of(context).extension<AppLoadingThemeData>() ??
        const AppLoadingThemeData.fallback();
    return Container(
      color: loadingTheme.overlayColor,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: cardWidth,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: loadingTheme.indicatorColor.withValues(alpha: .20),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: AppProgressIndicator(
              type: AppProgressType.linear,
              value: progress,
              minHeight: 6,
              color: loadingTheme.indicatorColor,
              trackColor: loadingTheme.trackColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel() {
    final label = widget.label;
    if (label == null ||
        label.isEmpty ||
        widget.labelPosition == LabelPosition.none) {
      return const SizedBox.shrink();
    }
    const defaultStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final style =
        (widget.labelTextStyle ?? defaultStyle).copyWith(color: Colors.black87);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: label, style: style),
            if (widget.isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithLabel(Widget content) {
    if (widget.label == null ||
        widget.label!.isEmpty ||
        widget.labelPosition == LabelPosition.none) {
      return content;
    }
    final labelWidget = _buildLabel();
    const labelWidth = 120.0;
    const spacing = 12.0;
    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWidget, content],
        );
      case LabelPosition.bottom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [content, labelWidget],
        );
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: labelWidth, child: labelWidget),
            const SizedBox(width: spacing),
            Expanded(child: content),
          ],
        );
      case LabelPosition.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            const SizedBox(width: spacing),
            SizedBox(width: labelWidth, child: labelWidget),
          ],
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return content;
    }
  }

  String? _validateImages(List<MyimageResult>? images) {
    if (widget.externalErrorText != null) return widget.externalErrorText;
    if (widget.validator != null) return widget.validator!(images);
    if (widget.isRequired && (images == null || images.isEmpty)) {
      final l = _localizations;
      if (l == null) return '';
      final label = widget.label;
      return (label != null && label.isNotEmpty)
          ? l.getWithLabel('imageRequired', label)
          : l.get('imageRequiredDefault');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = FormFieldsLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: FormField<List<MyimageResult>>(
        key: _formFieldKey,
        autovalidateMode: widget.autovalidateMode,
        initialValue: _provider.images,
        validator: _validateImages,
        builder: (state) {
          return Consumer<FormFieldsMyImageProvider>(
            builder: (context, provider, _) {
              final innerContent = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.maxImages == 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: _buildSingleImageWidget(context, provider),
                          ),
                        if (widget.maxImages != 1)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ResponsiveMenuGrid(
                                widgets:
                                    _buildMultiImageWidgets(context, provider),
                                itemSize: 100,
                                horizontalMargin: 0,
                                verticalSpacing: 12,
                                minHorizontalSpacing: 8,
                                alignLeft: true,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              state.errorText!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
              return _wrapWithLabel(innerContent);
            },
          );
        },
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
                    cardWidth: 98,
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
              widget.onImagesChanged?.call(
                List<MyimageResult>.from(provider.images),
              );
              widget.onRemoveImage?.call(0, removed);
              widget.onImageChanged?.call(MyimageResult());
            }),
          ),
      ],
    );
  }

  Widget _buildImageDisplay(
    BuildContext context,
    MyimageResult? image,
    int index, {
    bool isSingle = false,
  }) {
    if (image == null) {
      if (widget.imageBuilder != null) {
        return SizedBox(
          width: 120,
          height: 120,
          child: widget.imageBuilder!(context, MyimageResult(), index),
        );
      }
      if (!widget.isDirectUpload) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
      }
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person, size: 60, color: Colors.grey),
            Icon(Icons.camera_alt, size: 24, color: Colors.black54),
          ],
        ),
      );
    }
    if (widget.imageBuilder != null) {
      return SizedBox(
        width: 120,
        height: 120,
        child: widget.imageBuilder!(context, image, index),
      );
    }
    final hasLocalPath =
        image.path.trim().isNotEmpty && File(image.path).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 120,
        height: 120,
        child: hasLocalPath
            ? Image.file(
                File(image.path),
                fit: BoxFit.cover,
              )
            : Image.network(
                image.link,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildRemoveButton(
    BuildContext context,
    int index,
    MyimageResult image,
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
      icon: const Icon(Icons.close, color: Colors.red),
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
                  widget.onImagesChanged?.call(
                    List<MyimageResult>.from(provider.images),
                  );
                  widget.onRemoveImage?.call(idx, removed);
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

  Future<void> _pickImage(
    BuildContext context,
    FormFieldsMyImageProvider provider, {
    String? initialSource,
  }) async {
    File? file;
    String? source;
    // If isDoc, call CunningDocumentScanner directly
    if (widget.isDoc) {
      final scanned = await CunningDocumentScanner.getPictures(
        isGalleryImportAllowed: true,
        noOfPages: 1,
        iosScannerOptions: IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.5,
        ),
      );
      if (!context.mounted) return;
      if (scanned != null && scanned.isNotEmpty) {
        file = File(scanned.first);
      }
    } else {
      if (initialSource != null) {
        source = initialSource;
      } else {
        source = await showAppModalBottomSheet<String>(
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
                    AppButton(
                      type: AppButtonType.icon,
                      onPressed: () => Navigator.pop(dialogContext, 'camera'),
                      icon: const Icon(Icons.camera_alt,
                          size: 32, color: Colors.blue),
                      margin: const EdgeInsets.only(right: 24),
                    ),
                    SizedBox(width: 16),
                    AppButton(
                      type: AppButtonType.icon,
                      onPressed: () => Navigator.pop(dialogContext, 'gallery'),
                      icon: const Icon(Icons.photo_library,
                          size: 32, color: Colors.green),
                      margin: const EdgeInsets.only(left: 24),
                    ),
                  ],
                ),
              ),
            );
            // return Material(
            //   color: Colors.transparent,
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       AppButton(
            //         type: AppButtonType.fab,
            //         onPressed: () => Navigator.pop(dialogContext, 'camera'),
            //         icon: const Icon(Icons.camera_alt, size: 32, color: Colors.blue),
            //         margin: const EdgeInsets.only(right: 24),
            //       ),
            //       SizedBox(width: 16),
            //       AppButton(
            //         type: AppButtonType.fab,
            //         onPressed: () => Navigator.pop(dialogContext, 'gallery'),
            //         icon: const Icon(Icons.photo_library, size: 32, color: Colors.green),
            //         margin: const EdgeInsets.only(left: 24),
            //       ),
            //     ],
            //   ),
            // );
          },
        );
        if (!context.mounted) return;
        if (source == null) return;
      }
      if (source == 'camera' || source == 'gallery') {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (!context.mounted) return;
        if (picked != null) {
          file = File(picked.path);
        }
      }
    }
    if (!context.mounted) return;
    if (file != null) {
      final result = await MyimageResult.fromFile(file);
      if (!context.mounted) return;
      int? uploadIdx;
      String? description;

      // Jika showDesc true, tampilkan modal bottom sheet untuk input deskripsi
      if (widget.showDesc) {
        // Ambil localization sebelum async gap
        final l = FormFieldsLocalizations.of(context);
        final formKey = GlobalKey<FormState>();
        description = await showAppModalBottomSheet<String>(
          context: context,
          isDismissible: false,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (dialogContext) {
            // StatefulBuilder agar descValue tersimpan saat keyboard muncul
            // dan builder sheet dipanggil ulang oleh MediaQuery viewInsets.
            return StatefulBuilder(
              builder: (sbContext, setSheetState) {
                String descValue = _lastDescription ?? '';
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FormFields<String>(
                            label: l.get('description'),
                            currentValue: descValue,
                            onChanged: (v) {
                              setSheetState(() => descValue = v);
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            isRequired: true,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: AppButton(
                                    text: l.cancel,
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, null),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                          Colors.grey.shade200),
                                      foregroundColor: WidgetStatePropertyAll(
                                          Colors.black87),
                                      shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24))),
                                      elevation: WidgetStatePropertyAll(2),
                                      padding: WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(vertical: 14)),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 12),
                                  child: AppButton(
                                    text: l.yes,
                                    onPressed: () {
                                      if (formKey.currentState?.validate() ??
                                          true) {
                                        Navigator.pop(
                                            dialogContext, descValue.trim());
                                      }
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                          Colors.deepPurple),
                                      foregroundColor:
                                          WidgetStatePropertyAll(Colors.white),
                                      shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24))),
                                      elevation: WidgetStatePropertyAll(4),
                                      padding: WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(vertical: 14)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
        if (!context.mounted) return;
        if (description != null && description.isNotEmpty) {
          _lastDescription = description;
        }
      }

      if (widget.maxImages == 1) {
        bool isNew =
            provider.images.isEmpty || provider.images[0].path != result.path;
        provider.clearImages();
        provider.addImage(result);
        uploadIdx = 0;
        if (isNew) {
          provider.setUploadProgress(0, 0.0);
        }
        // Pastikan controller sinkron sebelum callback.
        _syncControllerImages(provider);
        // Callback khusus single image
        if (!widget.isDirectUpload) {
          widget.onImagesChanged
              ?.call(List<MyimageResult>.from(provider.images));
        }
        // Untuk direct upload, callback final (dengan link/imageId) akan
        // dipanggil setelah upload sukses di _uploadImageDio.
        if (!widget.isDirectUpload) {
          widget.onImageChanged?.call(result);
        }
      } else if (widget.maxImages == null) {
        provider.addImage(result);
        uploadIdx = provider.images.length - 1;
        if (provider.uploadProgress.length < provider.images.length) {
          provider.setUploadProgress(provider.images.length - 1, 0.0);
        }
        _syncControllerImages(provider);
        if (!widget.isDirectUpload) {
          widget.onImagesChanged
              ?.call(List<MyimageResult>.from(provider.images));
        }
      } else {
        if (provider.images.length < widget.maxImages!) {
          provider.addImage(result);
          uploadIdx = provider.images.length - 1;
          if (provider.uploadProgress.length < provider.images.length) {
            provider.setUploadProgress(provider.images.length - 1, 0.0);
          }
          _syncControllerImages(provider);
          if (!widget.isDirectUpload) {
            widget.onImagesChanged?.call(
              List<MyimageResult>.from(provider.images),
            );
          }
        }
      }
      if (widget.isDirectUpload && uploadIdx != null) {
        _uploadingIndex = uploadIdx;
        provider.commit();
        await _uploadImageDio(
          provider,
          result,
          uploadIdx,
          description: description,
        );
        if (!context.mounted) return;
        _uploadingIndex = null;
        provider.commit();
      }
    }
  }

  Future<void> _uploadImageDio(
    FormFieldsMyImageProvider provider,
    MyimageResult image,
    int? idx, {
    String? description,
  }) async {
    if (widget.uploadUrl == null) return;
    final images = provider.images;
    final index = idx ?? images.indexOf(image);
    if (index < 0) return;
    // Keep overlay visible from the beginning, even when onProgress only
    // emits at completion on some devices/networks.
    provider.setUploadProgress(index, 0.02);
    final headers = <String, String>{};
    if (widget.uploadToken != null && widget.uploadToken!.isNotEmpty) {
      headers['Authorization'] = widget.uploadToken!;
    }
    // Siapkan formData.fields jika ada description
    final extraFields = <MapEntry<String, String>>[];
    if (description != null && description.isNotEmpty) {
      extraFields.add(
        MapEntry(widget.descriptionField ?? 'description', description),
      );
    }
    final response = await DioUtil.uploadFile(
      url: widget.uploadUrl!,
      filePath: image.path,
      filename: File(image.path).path.split('/').last,
      headers: headers,
      onProgress: (progress) {
        provider.setUploadProgress(index, progress);
      },
      fields: extraFields.isNotEmpty ? extraFields : null,
    );
    if (!mounted) return;
    final l = FormFieldsLocalizations.of(context);
    final dialog = AppDialogService(context);
    final uploadSuccessTitle =
        widget.uploadSuccessTitle ?? l.get('uploadSuccessTitle');
    final uploadFailedTitle =
        widget.uploadFailedTitle ?? l.get('uploadFailedTitle');
    final uploadErrorTitle =
        widget.uploadErrorTitle ?? l.get('uploadErrorTitle');
    final uploadSuccessMessage =
        widget.uploadSuccessMessage ?? l.get('uploadSuccessMessage');
    final uploadFailedMessage =
        widget.uploadFailedMessage ?? l.get('uploadFailedMessage');
    final uploadErrorMessage =
        widget.uploadErrorMessage ?? l.get('uploadErrorMessage');
    if (response == null) {
      provider.resetUploadProgress(index);
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadFailedTitle,
          message: uploadErrorMessage,
          dialogType: AppDialogType.network,
        );
      }
      return;
    }
    try {
      if (_isSuccessfulStatus(response.statusCode)) {
        final data = response.data;
        final uploadedLink = _extractUploadedLink(data);
        final imageId = _extractImageId(data);
        final updatedImage = MyimageResult(
          link: uploadedLink ?? images[index].link,
          base64: images[index].base64,
          // Keep local file path from picked image to avoid re-fetching
          // the same file from server right after upload.
          path: images[index].path,
          imageId: imageId ?? images[index].imageId,
        );
        provider.updateImage(
          index,
          updatedImage,
        );
        // Keep a short completion transition so users can perceive progress.
        provider.setUploadProgress(index, 0.98);
        await Future<void>.delayed(uploadCompletionTransitionDelay);
        provider.setUploadProgress(index, 1.0);
        await Future<void>.delayed(uploadCompletionTransitionDelay);
        _syncControllerImages(provider);
        widget.onImagesChanged?.call(List<MyimageResult>.from(provider.images));
        if (widget.maxImages == 1 && index == 0) {
          final shouldEmitSingleImage = !widget.isDirectUpload ||
              updatedImage.link.isNotEmpty ||
              updatedImage.imageId.isNotEmpty;
          if (shouldEmitSingleImage) {
            widget.onImageChanged?.call(provider.images[index]);
          }
        }
        if (widget.showUploadResultDialog) {
          await dialog.showSuccess(
            title: uploadSuccessTitle,
            message: uploadSuccessMessage,
          );
        }
      } else {
        provider.resetUploadProgress(index);
        if (widget.showUploadResultDialog) {
          await dialog.showError(
            title: uploadFailedTitle,
            message: '$uploadFailedMessage ${response.statusMessage ?? ''}',
            dialogType: AppDialogType.server,
          );
        }
      }
    } catch (e) {
      provider.resetUploadProgress(index);
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadErrorTitle,
          message: '$uploadErrorMessage $e',
          dialogType: AppDialogType.server,
        );
      }
    }
  }

  bool _isSuccessfulStatus(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  String? _extractUploadedLink(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final raw = data.trim();
      if (raw.isEmpty) return null;

      final redirectRegex = RegExp(
        r"redirect_link\s*=\s*'([^']+)'",
        multiLine: true,
      );
      final match = redirectRegex.firstMatch(raw);
      if (match != null) {
        return match.group(1);
      }

      final asUri = Uri.tryParse(raw);
      if (asUri != null && asUri.hasScheme) {
        return raw;
      }
      return null;
    }

    final exact = _extractNestedValue(data, widget.uploadFileUrlKey);
    if ((exact ?? '').isNotEmpty) return exact;

    const fallbackKeys = [
      'fileUrl',
      'url',
      'link',
      'imageUrl',
      'downloadUrl',
      'receiverPhoto',
      'receiver_photo',
      'photoUrl',
      'photo',
      'redirect_link',
    ];
    for (final key in fallbackKeys) {
      final val = _extractNestedValue(data, key);
      if ((val ?? '').isNotEmpty) return val;
    }
    return null;
  }

  String? _extractImageId(dynamic data) {
    if (data == null) return null;

    final exact = _extractNestedValue(data, widget.uploadImageIdKey);
    if ((exact ?? '').isNotEmpty) return exact;

    const fallbackKeys = ['imageId', 'id'];
    for (final key in fallbackKeys) {
      final val = _extractNestedValue(data, key);
      if ((val ?? '').isNotEmpty) return val;
    }
    return null;
  }

  String? _extractNestedValue(dynamic data, String key) {
    if (data is Map) {
      for (final entry in data.entries) {
        if (entry.key.toString() == key) {
          return entry.value?.toString();
        }
        final nested = _extractNestedValue(entry.value, key);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    if (data is List) {
      for (final item in data) {
        final nested = _extractNestedValue(item, key);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    return null;
  }
}
