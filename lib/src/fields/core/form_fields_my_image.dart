import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/service/permission_gate.dart';
import 'package:form_fields/src/fields/core/form_fields_my_image_description_sheet.dart';
import 'package:form_fields/src/utilities/base64_image.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
import 'package:form_fields/src/fields/core/image_field_common.dart';
// `UploadResponseMapper` is exported by `package:form_fields/form_fields.dart`.
// Import removed to avoid unnecessary import lint.
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:dio/dio.dart';
import 'package:form_fields/src/utilities/network_status.dart';
import 'package:form_fields/src/service/upload_helper.dart';
import 'package:form_fields/src/widgets/form_field_label.dart';
import 'package:form_fields/src/utilities/debug_log.dart';

part 'form_fields_my_image_parts/sync.dart';
part 'form_fields_my_image_parts/pick.dart';
part 'form_fields_my_image_parts/upload.dart';
part 'form_fields_my_image_parts/view.dart';

/// A form field widget that lets the user pick one or more images, with
/// optional direct upload support.
///
/// Callbacks and semantics:
/// - `onRemoveImage` is called when a specific image is removed (index + item),
///   and it is invoked *before* `onImagesChanged` so callers can react to the
///   removed item prior to receiving the new list.
/// - `onImagesChanged` is called whenever the backing images list changes
///   (including after initial controller->provider sync, removals, adds, and
///   successful uploads). It receives a fresh copy of the current list.
/// - `onImageChanged` is only used when `maxImages == 1` and is invoked when
///   a new image is picked/replaced. It is NOT called when the single image is
///   removed; use `onRemoveImage` / `onImagesChanged` to observe removals.
class FormFieldsMyImage extends StatefulWidget {
  final FormFieldsMyImageController? controller;

  /// Callback untuk perubahan daftar gambar (multi-image, kompatibilitas lama)
  ///
  /// Called after the images list has been updated. When a removal occurs,
  /// `onRemoveImage` will be invoked first, then `onImagesChanged` with the
  /// updated list. Also invoked after initial controller->provider sync so
  /// callers receive the starting state when the widget is built with a
  /// pre-populated controller.
  final void Function(List<MyImageResult> results)? onImagesChanged;

  /// Callback untuk perubahan gambar pada mode single image (maxImages == 1).
  ///
  /// Invoked when a new image is selected or replaced. It is NOT called when
  /// the image is removed; use `onRemoveImage` / `onImagesChanged` to detect
  /// deletions.
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
  ///
  /// Receives the `index` and the `image` that was removed. This callback is
  /// invoked *before* `onImagesChanged` so callers can react to the removed
  /// item directly (for example, to cancel an in-flight upload or show a
  /// confirmation). In single-image mode (`maxImages == 1`) the index will be
  /// `0`.
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

  /// Image compression quality passed to `MyImageResult.fromFile` (1-100).
  final int quality;

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

  FormFieldsMyImage({
    super.key,
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
    this.quality = 80,
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
  static const double _tileSize = 100.0;
  late FormFieldsMyImageProvider _provider;
  int? _uploadingIndex;
  FormFieldsMyImageController? _controller;

  /// True when [_controller] was created by this state rather than supplied
  /// by the parent. Only internal controllers are disposed here.
  bool _ownsController = false;

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
      _ownsController = true;
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
      // Release the internal controller before a different one replaces it.
      if (_ownsController) {
        _controller?.removeListener(_onControllerChanged);
        _controller?.dispose();
        _ownsController = false;
      }
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
      } else {
        // The parent detached its controller. Switch to an internal one, so
        // this widget does not keep writing into a controller it no longer
        // owns.
        _controller = FormFieldsMyImageController.fromImages(_provider.images);
        _ownsController = true;
        _controller!.addListener(_onControllerChanged);
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
    if (_ownsController) _controller?.dispose();
    // Created in initState and not released before. In-flight uploads check
    // `mounted` before touching the provider again.
    _provider.dispose();
    super.dispose();
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
                                widgets: _buildMultiImageWidgets(
                                  context,
                                  provider,
                                ),
                                itemSize: 100,
                                margin: EdgeInsets.zero,
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
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
              return FormFieldLabelLayout(
                label: widget.label,
                labelPosition: widget.labelPosition,
                labelTextStyle: widget.labelTextStyle,
                isRequired: widget.isRequired,
                child: innerContent,
              );
            },
          );
        },
      ),
    );
  }
}
