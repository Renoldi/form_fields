import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/service/permission_gate.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
// `UploadResponseMapper` is exported by `package:form_fields/form_fields.dart`.
// Import removed to avoid unnecessary import lint.
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class FormFieldsMyImage extends StatefulWidget {
  final FormFieldsMyImageController? controller;

  /// Callback untuk perubahan daftar gambar (multi-image, kompatibilitas lama)
  final void Function(List<MyImageResult> results)? onImagesChanged;

  /// Callback untuk perubahan gambar pada mode single image (maxImages == 1)
  /// Dipanggil setiap kali gambar dipilih atau diganti.
  final void Function(MyImageResult image)? onImageChanged;
  final String? label;

  /// Position of the label relative to the image widget.
  /// Supports [LabelPosition.top], [LabelPosition.bottom],
  /// [LabelPosition.left], [LabelPosition.right] and [LabelPosition.none].
  final LabelPosition labelPosition;

  /// Custom text style for the label.
  final TextStyle? labelTextStyle;

  /// If provided, restricts the chooser and programmatic picks to this list
  /// (order matters when a fallback is required). `null` means allow all.
  final List<MyImageSource>? allowedImageSources;

  /// Note: use `allowedImageSources` only. If `null`, default chooser
  /// will present camera + gallery. To force a single source, pass a
  /// single-item list. To allow document scanning include `MyImageSource.doc`.

  final int? maxImages;
  final Widget Function(BuildContext context, MyImageResult image, int index)?
      imageBuilder;
  final Widget Function(BuildContext context, int index, MyImageResult image)?
      removeIconBuilder;

  /// Callback saat gambar dihapus.
  /// Pada mode single image, index selalu 0.
  final void Function(int index, MyImageResult image)? onRemoveImage;
  final Widget Function(BuildContext context)? plusBuilder;
  final String? uploadUrl;
  final String? uploadToken;
  final bool isDirectUpload;

  /// Optional callback to obtain a fresh upload token when an upload
  /// returns 401. Should return the new token string or null on failure.
  final Future<String?> Function()? uploadTokenRefresher;

  /// Optional callback invoked when upload authentication is expired and
  /// the library has queued the payload for later retry. Use to prompt
  /// re-login or show a UI hint.
  final VoidCallback? onUploadAuthExpired;

  /// New callback invoked when UploadService queues a payload for later
  /// retry. The boolean is `true` when queueing was due to auth expiry
  /// (401) and `false` for network/DNS failures.
  final void Function(DirectUploadPayload payload, bool authExpired)?
      onUploadQueued;

  /// Called when `isDirectUpload == true` but the device has no internet.
  /// Receives a list of payload Maps (each containing URL, headers, fields
  /// and file data) so the caller can store and send them later when online.

  // Customizable upload messages
  final String? uploadSuccessTitle;
  final String? uploadFailedTitle;
  final String? uploadErrorTitle;
  final String? uploadSuccessMessage;
  final String? uploadFailedMessage;
  final String? uploadErrorMessage;
  final String uploadFileUrlKey;
  final String uploadImageIdKey;

  /// Name of the multipart file field to use when uploading. Defaults to
  /// 'file' for backward compatibility with the existing server.
  final String uploadFileFieldName;

  /// Whether to include the legacy 'reqtype=fileupload' field in the
  /// multipart form. Some servers require it; default is false.
  final bool uploadIncludeReqType;

  final bool allow;
  final bool showUploadResultDialog;

  final bool showDesc;
  final String? descriptionField;

  /// Callback invoked when a direct upload is queued/failed due to lack of
  /// network. Receives the current images list (including any attached
  /// payloads) so the caller can persist or retry uploads later.

  /// Alternative callback that receives a list of upload-friendly payload
  /// Maps. Each map is shaped for easy consumption by `DioUtil.uploadFile`:
  /// {
  ///   'url': String,
  ///   'filePath': String,
  ///   'fileName': String,
  ///   'base64': String?,
  ///   'headers': `Map<String, String>`,
  ///   'fields': `Map<String, String>`,
  ///   'fileFieldName': String,
  ///   'includeReqType': bool,
  /// }
  /// This callback is provided as a convenience so callers can immediately
  /// pass the returned payloads to upload helpers or persist them.
  /// Each item is a typed `DirectUploadPayload` and can be serialized via
  /// `toMap()`/`toJson()` for storage or resending.
  final void Function(List<DirectUploadPayload> payloads)?
      onFailDirectUploadPayload;

  // ── Validation ──────────────────────────────────────────────────────────────

  /// Whether this field is required. Shows error when no images are present.
  final bool isRequired;

  /// Custom validator. Receives the current images list.
  /// Return an error string, or null if valid.
  final String? Function(List<MyImageResult>?)? validator;

  /// Controls when validation errors are shown (default: onUserInteraction).
  final AutovalidateMode autovalidateMode;

  /// Error text injected from external (e.g. backend validation).
  /// Always displayed when non-null, regardless of [autovalidateMode].
  final String? externalErrorText;

  FormFieldsMyImage(
      {super.key,
      this.controller,
      this.onImagesChanged,
      this.onImageChanged,
      this.label,
      this.labelPosition = LabelPosition.none,
      this.labelTextStyle,
      this.allowedImageSources = const [
        MyImageSource.camera,
        MyImageSource.gallery,
      ],
      this.maxImages,
      this.imageBuilder,
      this.onRemoveImage,
      this.plusBuilder,
      this.removeIconBuilder,
      this.uploadUrl,
      this.uploadToken,
      this.isDirectUpload = false,
      this.uploadTokenRefresher,
      this.onUploadAuthExpired,
      this.uploadSuccessTitle,
      this.uploadFailedTitle,
      this.uploadErrorTitle,
      this.uploadSuccessMessage,
      this.uploadFailedMessage,
      this.uploadErrorMessage,
      this.uploadFileUrlKey = 'fileUrl',
      this.uploadImageIdKey = 'imageId',
      this.uploadFileFieldName = 'file',
      this.uploadIncludeReqType = false,
      this.onFailDirectUploadPayload,
      this.onUploadQueued,
      this.allow = true,
      this.showUploadResultDialog = false,
      this.showDesc = false,
      this.descriptionField,
      this.isRequired = false,
      this.validator,
      this.autovalidateMode = AutovalidateMode.onUserInteraction,
      this.externalErrorText}) {
    assert(
      isDirectUpload == false || (uploadUrl != null && uploadUrl!.isNotEmpty),
      "For direct upload, uploadUrl must be provided and non-empty.",
    );
  }

  @override
  State<FormFieldsMyImage> createState() => _FormFieldsMyImageState();
}

class _ImageDescriptionSheet extends StatefulWidget {
  final AutovalidateMode autovalidateMode;

  const _ImageDescriptionSheet(
      {this.autovalidateMode = AutovalidateMode.onUserInteraction});

  @override
  State<_ImageDescriptionSheet> createState() => _ImageDescriptionSheetState();
}

class _ImageDescriptionSheetState extends State<_ImageDescriptionSheet> {
  late final TextEditingController _descController;
  late final FocusNode _descFocusNode;
  late final FocusNode _rawKeyboardFocusNode;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _descFocusNode = FocusNode();
    _rawKeyboardFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Wait a short time for the sheet animation to finish so that
      // the Flutter view is "served" and IME can attach reliably.
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      try {
        FocusScope.of(context).requestFocus(_descFocusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _descFocusNode.dispose();
    _rawKeyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dl = FormFieldsLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyboardListener(
                focusNode: _rawKeyboardFocusNode,
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent) {
                    final key = event.logicalKey;
                    if (key == LogicalKeyboardKey.enter) {
                      if (_formKey.currentState?.validate() ?? true) {
                        if (!context.mounted) return;
                        Navigator.pop(context, _descController.text.trim());
                      }
                      return;
                    }

                    if (key == LogicalKeyboardKey.backspace) {
                      final text = _descController.text;
                      final sel = _descController.selection;
                      if (sel.start > 0) {
                        final newStart = sel.start - 1;
                        final newText =
                            text.replaceRange(newStart, sel.start, '');
                        _descController.text = newText;
                        _descController.selection =
                            TextSelection.collapsed(offset: newStart);
                      }
                      return;
                    }

                    final char = event.character;
                    if (char != null && char.isNotEmpty) {
                      final text = _descController.text;
                      final sel = _descController.selection;
                      final start = sel.start >= 0 ? sel.start : text.length;
                      final end = sel.end >= 0 ? sel.end : text.length;
                      final newText = text.replaceRange(start, end, char);
                      final newOffset = start + char.length;
                      _descController.text = newText;
                      _descController.selection =
                          TextSelection.collapsed(offset: newOffset);
                    }
                  }
                },
                child: TextFormField(
                  controller: _descController,
                  focusNode: _descFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: dl.get('description')),
                  autovalidateMode: widget.autovalidateMode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return dl.getWithLabel('required', dl.get('description'));
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (_formKey.currentState?.validate() ?? true) {
                      if (!context.mounted) return;
                      Navigator.pop(context, _descController.text.trim());
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: AppButton(
                        text: dl.cancel,
                        onPressed: () {
                          if (!context.mounted) return;
                          Navigator.pop(context, null);
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest),
                          foregroundColor:
                              WidgetStatePropertyAll(resolveTextColor(context)),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24))),
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
                        text: dl.yes,
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? true) {
                            if (!context.mounted) return;
                            Navigator.pop(context, _descController.text.trim());
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              resolveActiveColor(context, null)),
                          foregroundColor: WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.onPrimary),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24))),
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
  }
}

class _FormFieldsMyImageState extends State<FormFieldsMyImage> {
  late FormFieldsMyImageProvider _provider;
  int? _uploadingIndex;
  FormFieldsMyImageController? _controller;

  final _formFieldKey = GlobalKey<FormFieldState<List<MyImageResult>>>();
  FormFieldsLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _provider = FormFieldsMyImageProvider();
    _provider.addListener(_onProviderChanged);
    // Register provider so OfflineUploadManager can update provider images
    // when persisted/offline uploads are retried and succeed.
    OfflineUploadManager.instance.registerProvider(_provider);
    if (widget.controller != null) {
      _controller = widget.controller;
      _provider.setImages(_controller!.images);
      _controller!.addListener(_onControllerChanged);
      widget.controller!.registerPickImageHandler((source) async {
        if (!mounted) return;
        await _pickImage(context, _provider, initialSource: source);
      });
    } else {
      _controller = FormFieldsMyImageController();
      _provider.setImages(_controller!.images);
      _controller!.addListener(_onControllerChanged);
    }
    // Register controller so OfflineUploadManager can update UI images when
    // persisted/offline uploads are retried and succeed.
    if (_controller != null) {
      OfflineUploadManager.instance.registerController(_controller!);
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
      // Unregister previous controller from offline manager and listeners.
      if (_controller != null) {
        OfflineUploadManager.instance.unregisterController(_controller!);
      }
      oldWidget.controller?.unregisterPickImageHandler();
      oldWidget.controller?.removeListener(_onControllerChanged);
      if (widget.controller != null) {
        _controller = widget.controller;
        // If the new controller is empty but provider already has images,
        // preserve the provider state and push it into the controller to
        // avoid unintentionally clearing images when callers recreate the
        // controller (common mistake in example apps).
        if ((_controller!.images.isEmpty) && _provider.images.isNotEmpty) {
          _controller!.setImages(List<MyImageResult>.from(_provider.images));
        } else {
          _provider.setImages(_controller!.images);
        }
        _controller!.addListener(_onControllerChanged);
        widget.controller!.registerPickImageHandler((source) async {
          if (!mounted) return;
          await _pickImage(context, _provider, initialSource: source);
        });
        OfflineUploadManager.instance.registerController(_controller!);
      }
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    if (widget.controller != null) {
      widget.controller!.unregisterPickImageHandler();
    }
    // Unregister controller from offline manager (best-effort)
    if (_controller != null) {
      OfflineUploadManager.instance.unregisterController(_controller!);
    }
    // Unregister provider
    OfflineUploadManager.instance.unregisterProvider(_provider);
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

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
      OfflineUploadManager.instance
          .updateProviderLocations(_provider, newValue);
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

  Widget _buildUploadOverlay(
    BuildContext context, {
    required double progress,
    required double cardWidth,
  }) {
    final myImageTheme =
        Theme.of(context).extension<FormFieldsMyImageThemeData>() ??
            const FormFieldsMyImageThemeData.fallback();
    final loadingTheme = Theme.of(context).extension<AppLoadingThemeData>() ??
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
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: progressColor.withValues(alpha: .20),
              ),
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

  Widget _buildLabel() {
    final raw = widget.label;
    if (raw == null ||
        raw.isEmpty ||
        widget.labelPosition == LabelPosition.none) {
      return const SizedBox.shrink();
    }
    final label = raw.toTitleCase;
    final theme = Theme.of(context);
    const defaultStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final style = (widget.labelTextStyle ?? defaultStyle)
        .copyWith(color: resolveTextColor(context));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: label, style: style),
            if (widget.isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.error,
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 8), content],
          ),
        );
      case LabelPosition.bottom:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [content, const SizedBox(height: 8), labelWidget],
          ),
        );
      case LabelPosition.left:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: labelWidth, child: labelWidget),
              const SizedBox(width: spacing),
              Expanded(child: content),
            ],
          ),
        );
      case LabelPosition.right:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              const SizedBox(width: spacing),
              SizedBox(width: labelWidth, child: labelWidget),
            ],
          ),
        );
      case LabelPosition.inBorder:
      case LabelPosition.none:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        );
    }
  }

  String? _validateImages(List<MyImageResult>? images) {
    if (widget.externalErrorText != null) return widget.externalErrorText;
    if (widget.validator != null) return widget.validator!(images);

    // Some race conditions can cause the `images` passed here to be empty
    // even though the provider already contains images (e.g. user picked an
    // image and FormField state hasn't been updated yet). Use provider as a
    // fallback so validation doesn't falsely fail.
    final effectiveImages =
        (images == null || images.isEmpty) ? _provider.images : images;

    if (widget.isRequired && (effectiveImages.isEmpty)) {
      final l = _localizations;
      if (l == null) return '';
      final raw = widget.label;
      return (raw != null && raw.isNotEmpty)
          ? l.getWithLabel('imageRequired', raw.toTitleCase)
          : l.get('imageRequiredDefault');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = FormFieldsLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: FormField<List<MyImageResult>>(
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
                          Icon(Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12),
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
                List<MyImageResult>.from(provider.images),
              );
              widget.onRemoveImage?.call(0, removed);
              widget.onImageChanged?.call(MyImageResult());
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
          width: 120,
          height: 120,
          child: widget.imageBuilder!(context, MyImageResult(), index),
        );
      }
      // Single-image default: show an add-tile (plus) placeholder.
      if (isSingle) {
        final active = resolveActiveColor(context, null);
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active, width: 2),
          ),
          child: Center(
            child: Icon(Icons.image, size: 32, color: active),
          ),
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
          child: Center(
            child: Icon(Icons.add, size: 32, color: active),
          ),
        );
      }
      final active = resolveActiveColor(context, null);
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active, width: 2),
        ),
        child: Center(
          child: Icon(Icons.add, size: 32, color: active),
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
    final hasBase64 = image.base64.trim().isNotEmpty;
    Widget displayed;
    if (hasLocalPath) {
      displayed = Image.file(
        File(image.path),
        fit: BoxFit.cover,
      );
    } else if (hasBase64) {
      try {
        var b64 = image.base64;
        if (b64.startsWith('data:')) {
          final comma = b64.indexOf(',');
          if (comma >= 0) b64 = b64.substring(comma + 1);
        }
        final bytes = base64Decode(b64);
        displayed = Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (_) {
        displayed = Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    } else if (image.link.trim().isNotEmpty) {
      displayed = Image.network(
        image.link,
        fit: BoxFit.cover,
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
        width: 120,
        height: 120,
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
                        color: Theme.of(context)
                            .shadowColor
                            .withValues(alpha: .18),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: .72),
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
                  widget.onImagesChanged?.call(
                    List<MyImageResult>.from(provider.images),
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
    Future<bool> ensurePermissionForSource(String src) async {
      if (!mounted) return false;
      final ok =
          await PermissionGate.ensurePickerPermission(context, source: src);
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
      final scanned = await CunningDocumentScanner.getPictures(
        isGalleryImportAllowed: true,
        noOfPages: 1,
      );
      if (!mounted) return;
      if (scanned != null && scanned.isNotEmpty) {
        file = File(scanned.first);
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
                        icon: Icon(Icons.camera_alt,
                            size: 32,
                            color: resolveActiveColor(dialogContext, null)),
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
                        icon: Icon(Icons.photo_library,
                            size: 32,
                            color:
                                Theme.of(dialogContext).colorScheme.secondary),
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
                        icon: Icon(Icons.sticky_note_2,
                            size: 32,
                            color: Theme.of(dialogContext).colorScheme.primary),
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
      MyImageResult result = await MyImageResult.fromFile(file!);
      if (!mounted) return;
      int? uploadIdx;
      String? description;

      // Jika showDesc true, tampilkan modal bottom sheet untuk input deskripsi
      if (widget.showDesc) {
        if (!context.mounted) return;
        description = await showAppModalBottomSheet<String>(
          context: context,
          isDismissible: false,
          useSafeArea: true,
          requestFocus: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (dialogContext) =>
              _ImageDescriptionSheet(autovalidateMode: widget.autovalidateMode),
        );
        if (!mounted) return;
      }

      // Jika description sudah diisi, masukkan ke dalam `result` sehingga
      // UI menampilkan deskripsi segera sebelum upload berlangsung.
      if (description != null && description.isNotEmpty) {
        result = MyImageResult(
          link: result.link,
          base64: result.base64,
          path: result.path,
          imageId: result.imageId,
          description: description,
        );
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
              ?.call(List<MyImageResult>.from(provider.images));
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
              ?.call(List<MyImageResult>.from(provider.images));
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
              List<MyImageResult>.from(provider.images),
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
        if (!mounted) return;
        _uploadingIndex = null;
        provider.commit();
      }
    }
  }

  Future<bool> _hasNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.none)
          ? false
          : true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _uploadImageDio(
    FormFieldsMyImageProvider provider,
    MyImageResult image,
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
    // Determine effective description (prefer explicit param, fallback to image.description)
    final imgDesc = (image.description).trim();
    final effDesc = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : (imgDesc.isNotEmpty ? imgDesc : null);
    // Siapkan formData.fields jika ada description
    final extraFields = <MapEntry<String, String>>[];
    if (effDesc != null && effDesc.isNotEmpty) {
      extraFields
          .add(MapEntry(widget.descriptionField ?? 'description', effDesc));
    }

    // Prepare a payload so callers can enqueue and send it later when offline.
    final fileName = image.path.trim().isNotEmpty
        ? image.path.split(Platform.pathSeparator).last
        : (image.link.isNotEmpty ? image.link.split('/').last : 'image');
    final uploadCorrelationId =
        DateTime.now().microsecondsSinceEpoch.toString();
    final payload = <String, dynamic>{
      'url': widget.uploadUrl,
      'headers': headers,
      'fields': Map<String, String>.fromEntries(extraFields),
      'file': {
        'fileName': fileName,
        'base64': image.base64,
        'path': image.path,
      },
      'uploadFileUrlKey': widget.uploadFileUrlKey,
      'uploadImageIdKey': widget.uploadImageIdKey,
      'description': effDesc,
      'index': index,
      // Correlation id used to reliably match persisted payloads back to
      // controller images when retries succeed.
      'uploadCorrelationId': uploadCorrelationId,
    };

    final hasNet = await _hasNetwork();
    if (!hasNet) {
      // Keep overlay visible to indicate pending upload.
      provider.setUploadProgress(index, 0.0);
      // Attach payload to the image so UI/controller can access it later.
      final updatedImage = MyImageResult(
        link: images[index].link,
        base64: images[index].base64,
        path: images[index].path,
        imageId: images[index].imageId,
        description: (effDesc != null && effDesc.isNotEmpty)
            ? effDesc
            : images[index].description,
        payload: payload,
        status: MyImageStatus.queued,
      );
      provider.updateImage(index, updatedImage);
      _syncControllerImages(provider);
      // Notify callers specifically about a failed/queued direct upload so
      // they can persist the payloads for later retry. Wrap the callback in
      // try/catch to avoid user-provided handlers from throwing and
      // interrupting the upload flow (which previously could wipe state).
      try {
        final queued = provider.images
            .where((i) => i.status == MyImageStatus.queued)
            .toList();
        if (queued.isNotEmpty) {
          try {
            final payloads =
                await UploadHelper.buildDirectUploadPayloadsFromImages(
              queued,
              defaultUrl: widget.uploadUrl,
              fileFieldName: widget.uploadFileFieldName,
              includeReqType: widget.uploadIncludeReqType,
            );
            if (payloads.isNotEmpty) {
              widget.onFailDirectUploadPayload?.call(payloads);
            }
          } catch (e, st) {
            debugPrint(
                'FormFieldsMyImage.onFailDirectUploadPayload threw: $e\n$st');
          }
        }
      } catch (e, st) {
        debugPrint(
            'FormFieldsMyImage.onFailDirectUploadPayload handling threw: $e\n$st');
      }
      // Stop further processing when offline — avoid attempting the
      // network upload and potential race conditions that may overwrite
      // the queued image state.
      return;
    }

    // If we have network, mark the image as uploading before starting the request.
    if (hasNet) {
      final img = images[index];
      final uploadingImage = MyImageResult(
        link: img.link,
        base64: img.base64,
        path: img.path,
        imageId: img.imageId,
        description: img.description,
        payload: img.payload,
        status: MyImageStatus.uploading,
      );
      provider.updateImage(index, uploadingImage);
      _syncControllerImages(provider);
    }

    Response? response;
    Map<String, dynamic>? built;
    try {
      // Build an upload-ready payload map (may write temp file for base64)
      built = await UploadHelper.buildUploadPayloadFromMap(payload);
      if (built == null) {
        provider.resetUploadProgress(index);
        return;
      }

      // Merge headers (use current `headers` which contains latest Authorization)
      final headersForUpload = (built['headers'] is Map)
          ? Map<String, String>.from(built['headers'] as Map)
          : <String, String>{};
      headersForUpload.addAll(headers);

      // Build fields map
      final fieldsMap = <String, String>{};
      if (built['fields'] is Map) {
        (built['fields'] as Map).forEach((k, v) {
          fieldsMap[k.toString()] = v.toString();
        });
      }

      // Base64 (prefer explicit file entry, fallback to image.base64)
      String? base64Val;
      try {
        final fe = payload['file'];
        if (fe is Map &&
            fe['base64'] is String &&
            (fe['base64'] as String).trim().isNotEmpty) {
          base64Val = fe['base64'] as String;
        } else if (image.base64.isNotEmpty) {
          base64Val = image.base64;
        }
      } catch (_) {}

      final direct = DirectUploadPayload(
        url: built['url'] as String,
        filePath: built['filePath'] as String,
        fileName: built['fileName'] as String,
        base64: base64Val,
        headers: headersForUpload,
        fields: fieldsMap,
        fileFieldName:
            built['fileFieldName'] as String? ?? widget.uploadFileFieldName,
        includeReqType:
            (built['includeReqType'] == true) || widget.uploadIncludeReqType,
        uploadCorrelationId: payload['uploadCorrelationId']?.toString(),
      );

      final outcome = await UploadService.instance.uploadDirectPayload(
        direct,
        uploadTokenRefresher: widget.uploadTokenRefresher,
        onUploadAuthExpired: () {
          try {
            widget.onUploadAuthExpired?.call();
          } catch (_) {}
        },
        onUploadQueued: (sanitized, authExpired) {
          try {
            final sanitizedMap = sanitized.toJson();
            final updatedImage = MyImageResult(
              link: images[index].link,
              base64: images[index].base64,
              path: images[index].path,
              imageId: images[index].imageId,
              description: (effDesc != null && effDesc.isNotEmpty)
                  ? effDesc
                  : images[index].description,
              payload: sanitizedMap,
              status: MyImageStatus.queued,
            );
            provider.updateImage(index, updatedImage);
            _syncControllerImages(provider);

            try {
              widget.onFailDirectUploadPayload?.call([sanitized]);
            } catch (e, st) {
              debugPrint('Failed to call onFailDirectUploadPayload: $e\n$st');
            }

            if (authExpired) {
              try {
                widget.onUploadAuthExpired?.call();
              } catch (_) {}
            }
          } catch (e, st) {
            debugPrint('onUploadQueued handler error: $e\n$st');
          }
        },
        onProgress: (progress) {
          provider.setUploadProgress(index, progress);
        },
      );

      response = outcome.response;
    } finally {
      // Clean up any temp file created by buildUploadPayloadFromMap
      try {
        if (built != null && built['tempFileCreated'] == true) {
          final tf = File(built['filePath'] as String);
          if (await tf.exists()) await tf.delete();
        }
      } catch (_) {}
    }
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
      if (UploadResponseMapper.isSuccessfulStatus(response.statusCode)) {
        final data = response.data;
        final uploadedLink = UploadResponseMapper.extractUploadedLink(data,
            keys: widget.uploadFileUrlKey);
        final imageId = UploadResponseMapper.extractImageId(data,
            keys: widget.uploadImageIdKey);
        final uploadedDescription = UploadResponseMapper.extractDescription(
            data,
            keys: widget.descriptionField ?? 'description');
        final uploadedPath =
            UploadResponseMapper.extractFilePath(data, keys: 'filePath');
        // Build absolute link if server provided only a relative path.
        String? finalLink = (uploadedLink ?? images[index].link).trim();
        if ((finalLink.isEmpty) &&
            (uploadedPath != null && uploadedPath.trim().isNotEmpty)) {
          try {
            final base = Uri.parse(widget.uploadUrl!);
            final p =
                uploadedPath.startsWith('/') ? uploadedPath : '/$uploadedPath';
            finalLink = '${base.scheme}://${base.authority}$p';
          } catch (_) {}
        }

        final resolvedPath = (uploadedPath != null &&
                uploadedPath.trim().isNotEmpty &&
                uploadedPath.startsWith(Platform.pathSeparator))
            ? uploadedPath
            : images[index].path;

        final updatedImage = MyImageResult(
          link: finalLink ?? images[index].link,
          base64: images[index].base64,
          // Preserve the local picked file path unless the server
          // returned an absolute filesystem path (rare). Avoid
          // overwriting with server-relative paths which are not
          // accessible locally and cause PathNotFound errors.
          path: resolvedPath,
          imageId: imageId ?? images[index].imageId,
          description:
              uploadedDescription ?? description ?? images[index].description,
          payload: data,
          status: MyImageStatus.uploaded,
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
        widget.onImagesChanged?.call(List<MyImageResult>.from(provider.images));
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
        // mark as failed
        final failedImage = MyImageResult(
          link: images[index].link,
          base64: images[index].base64,
          path: images[index].path,
          imageId: images[index].imageId,
          description: images[index].description,
          payload: images[index].payload,
          status: MyImageStatus.failed,
        );
        provider.updateImage(index, failedImage);
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
      // mark as failed on exception
      final failedImage = MyImageResult(
        link: images[index].link,
        base64: images[index].base64,
        path: images[index].path,
        imageId: images[index].imageId,
        description: images[index].description,
        payload: images[index].payload,
        status: MyImageStatus.failed,
      );
      provider.updateImage(index, failedImage);
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
}
