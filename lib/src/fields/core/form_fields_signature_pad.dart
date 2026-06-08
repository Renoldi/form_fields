import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:signature/signature.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:form_fields/src/service/permission_gate.dart';
import 'package:form_fields/src/utilities/signature_pad_export_nullable_result.dart';

// SignaturePadExportResult lives in lib/src/utilities/signature_pad_export_result.dart
// SignaturePadPreviewSource lives in lib/src/utilities/enums.dart

/// ---------------------------------------------------------------------------
/// FormFields SignaturePad Component (menggunakan package signature)
/// ---------------------------------------------------------------------------
/// Komponen signature pad berbasis plugin signature (https://pub.dev/packages/signature)
///
/// ### Live Camera
/// Set [showLiveCamera] to `true` to display a front-camera live preview
/// alongside the signature pad.
///
/// **Auto-capture behaviour:** as soon as the user begins drawing the
/// signature (`onDrawStart`), the widget automatically takes a photo from the
/// front camera — no gallery or camera dialog is shown.  The captured image
/// is forwarded through [onExportedResult] as
/// [SignaturePadExportResult.liveCapture].
///
/// Pass your own [liveCameraController] to read / pre-fill the captured image
/// from outside the widget. If omitted, an internal controller is used.
///
/// Use [layoutBuilder] to fully customise the arrangement of the signature pad
/// and the camera widget. When omitted the camera appears below the pad.
///
/// Use [liveCameraBuilder] to wrap or replace just the camera section itself
/// while keeping the default column layout.
class FormFieldsSignaturePad extends StatefulWidget {
  // ── Signature pad ──────────────────────────────────────────────────────────
  final double height;
  final double width;
  final Color backgroundColor;
  final Color penColor;
  final double penStrokeWidth;

  /// Jika null, export PNG transparan. Jika diisi, gunakan warna ini untuk background PNG.
  final Color? exportBackgroundColor;

  // ── Callbacks ──────────────────────────────────────────────────────────────

  /// Called with the signature only (backward-compatible).
  final void Function(MyImageResult?)? onExported;

  /// Called with signature + optional live capture.
  /// Preferred over [onExported] when [showLiveCamera] is enabled.
  final void Function(SignaturePadExportResult)? onExportedResult;

  /// Called immediately after the auto-capture fires (on draw start).
  /// Useful to show a thumbnail or indicator before the user finishes signing.
  final void Function(MyImageResult captured)? onLiveCaptured;

  /// When true, replace the drawing area with exported preview after confirm.
  /// While preview is shown, export button is hidden until user clears.
  final bool showExportPreview;

  /// Which exported image(s) to render when [showExportPreview] is enabled.
  ///
  /// - [SignaturePadPreviewSource.signature]: preview signature image only
  /// - [SignaturePadPreviewSource.liveCapture]: preview live camera image only
  /// - [SignaturePadPreviewSource.both]: preview both images side-by-side
  ///
  /// Falls back to signature when live capture is unavailable.
  final SignaturePadPreviewSource exportPreviewSource;

  // ── Live camera ────────────────────────────────────────────────────────────

  /// Show a front-camera live preview.  Auto-captures when signing starts.
  final bool showLiveCamera;

  /// Capture a photo from the front camera silently (no preview widget shown).
  /// Auto-captures when the user begins drawing, same as [showLiveCamera].
  /// Cannot be combined with [showLiveCamera] — if both are `true`,
  /// [showLiveCamera] takes precedence.
  final bool silentLiveCapture;

  /// Height of the camera preview widget. Defaults to 200.
  final double liveCameraHeight;

  /// External controller — will be updated with the auto-captured image.
  /// When null, the widget manages its own internal controller.
  final FormFieldsMyImageController? liveCameraController;

  /// Optional controller that exposes the exported result and supports
  /// pre-seeding the pad with an existing signature.
  ///
  /// Use [FormFieldsSignaturePadController.fromSignature] to start in preview
  /// mode with an existing image:
  /// ```dart
  /// final ctrl = FormFieldsSignaturePadController.fromSignature(
  ///   MyimageResult.network('https://example.com/sig.png'),
  /// );
  /// ```
  final FormFieldsSignaturePadController? signaturePadController;

  /// Fully custom layout.
  /// Receives the built [signaturePad] and [cameraWidget]
  /// (null when [showLiveCamera] is false). Return your own arrangement.
  final Widget Function(
    BuildContext context,
    Widget signaturePad,
    Widget? cameraWidget,
  )? layoutBuilder;

  /// Custom wrapper for only the camera section.
  /// Receives the live-preview widget; return a decorated version.
  /// Ignored when [layoutBuilder] is provided.
  final Widget Function(BuildContext context, Widget camera)? liveCameraBuilder;

  // ── Upload ─────────────────────────────────────────────────────────────────

  /// Upload otomatis saat signature diekspor.
  /// Requires [uploadUrl] to be non-empty when `true`.
  final bool isDirectUpload;

  /// Upload endpoint URL (required when [isDirectUpload] is `true`).
  final String? uploadUrl;

  /// Bearer token sent as `Authorization` header during upload.
  final String? uploadToken;

  /// Called when `isDirectUpload == true` but the device has no internet.
  /// Receives a list of payload Maps (each containing URL, headers, fields
  /// and file data) so the caller can store and send them later when online.

  /// Show a result dialog after upload completes (success or failure).
  final bool showUploadResultDialog;

  /// Show a loading overlay on the signature pad while uploading.
  /// Defaults to `true`.
  final bool showUploadLoading;

  /// When true, automatically export the signature shortly after the user
  /// stops drawing. Defaults to `true` so auto-export is the default behaviour.
  ///
  /// Auto-export is debounced to avoid exporting between quick multi-stroke
  /// draws — the export fires only after the user has paused drawing.
  final bool autoExportOnFinish;

  // Customizable upload messages
  final String? uploadSuccessTitle;
  final String? uploadFailedTitle;
  final String? uploadErrorTitle;
  final String? uploadSuccessMessage;
  final String? uploadFailedMessage;
  final String? uploadErrorMessage;

  /// Called when `isDirectUpload == true` but the device has no internet.
  /// Called when `isDirectUpload == true` but the device has no internet.
  /// Receives a single `MyImageResult` (with `payload`) for each queued item
  /// so the caller can persist and retry uploads later.

  /// Called when `isDirectUpload == true` but the device has no internet
  /// and one or more exported results are queued (signature and/or live
  /// capture). The callback receives a `SignaturePadExportNullableResult`
  /// where a `null` field indicates that side succeeded (no error).
  final void Function(SignaturePadExportNullableResult result)?
      onFailDirectUploadList;

  /// Alternative callback that receives a list of typed `DirectUploadPayload`.
  /// Each item is ready to be serialized via `toMap()`/`toJson()` for
  /// persistence or re-upload.
  final void Function(List<DirectUploadPayload> payloads)?
      onFailDirectUploadPayload;

  /// New callback invoked when an individual upload payload is queued by the
  /// widget (e.g. network failure). Receives a sanitized `DirectUploadPayload`
  /// and a boolean `authExpired` which is true when the library detected an
  /// authentication expiry (401) situation.
  final void Function(DirectUploadPayload payload, bool authExpired)?
      onUploadQueued;

  /// Called when `isDirectUpload == true` and `exportPreviewSource == both`.
  /// Invoked when one or both uploads (signature, live capture) fail on server
  /// so the caller can render a combined error UI. Receives the combined
  /// `SignaturePadExportResult` containing the final signature and liveCapture
  /// results.
  final void Function(SignaturePadExportResult result)? onError;

  /// Called when `isDirectUpload == true` but the device has no internet.
  /// (removed) Combined queued-export callback was deprecated.

  /// JSON key for the uploaded file URL in the response body.
  final String uploadFileUrlKey;

  /// JSON key for the image/file ID in the response body.
  final String uploadImageIdKey;

  /// Name of the multipart file field to use when uploading. Defaults to
  /// 'file' which is commonly expected by many servers.
  final String uploadFileFieldName;

  /// Whether to include the legacy 'reqtype=fileupload' field in the
  /// multipart form. Some servers require it; default is false.
  final bool uploadIncludeReqType;

  // ── Validation ──────────────────────────────────────────────────────────────

  /// Label text shown above (or beside) the signature pad.
  final String? label;

  /// Position of the label relative to the signature pad.
  /// Supports [LabelPosition.top], [LabelPosition.bottom],
  /// [LabelPosition.left], [LabelPosition.right] and [LabelPosition.none].
  final LabelPosition labelPosition;

  /// Custom text style for the label.
  final TextStyle? labelTextStyle;

  /// Whether a signature must be drawn before the form is valid.
  final bool isRequired;

  /// Custom validator. Receives `true` if the pad has content, `false` if empty.
  /// Return an error string, or null if valid.
  final String? Function(bool hasSignature)? validator;

  /// Controls when validation errors are shown (default: onUserInteraction).
  final AutovalidateMode autovalidateMode;

  /// Error text injected from external (e.g. backend validation).
  /// Always displayed when non-null, regardless of [autovalidateMode].
  final String? externalErrorText;

  final String? descriptionField;

  FormFieldsSignaturePad({
    super.key,
    this.height = 200,
    this.width = double.infinity,
    this.backgroundColor = Colors.white,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.onExported,
    this.onExportedResult,
    this.onLiveCaptured,
    this.showExportPreview = false,
    this.exportPreviewSource = SignaturePadPreviewSource.signature,
    this.exportBackgroundColor,
    this.showLiveCamera = false,
    this.silentLiveCapture = false,
    this.liveCameraHeight = 200,
    this.liveCameraController,
    this.signaturePadController,
    this.layoutBuilder,
    this.liveCameraBuilder,
    this.isDirectUpload = false,
    this.uploadUrl,
    this.uploadToken,
    this.showUploadResultDialog = false,
    this.showUploadLoading = true,
    this.uploadSuccessTitle,
    this.uploadFailedTitle,
    this.uploadErrorTitle,
    this.uploadSuccessMessage,
    this.uploadFailedMessage,
    this.uploadErrorMessage,
    this.onFailDirectUploadList,
    this.onFailDirectUploadPayload,
    this.onUploadQueued,
    this.onError,
    this.uploadFileUrlKey = 'fileUrl',
    this.uploadImageIdKey = 'imageId',
    this.uploadFileFieldName = 'file',
    this.uploadIncludeReqType = false,
    this.autoExportOnFinish = true,
    this.label,
    this.labelPosition = LabelPosition.none,
    this.labelTextStyle,
    this.isRequired = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.externalErrorText,
    this.descriptionField,
  }) : assert(
          isDirectUpload == false ||
              (uploadUrl != null && uploadUrl.isNotEmpty),
          "For direct upload, uploadUrl must be provided and non-empty.",
        ) {
    // Warn developer about the conflicting combination at construction time.
    assert(
      !(showLiveCamera && silentLiveCapture),
      'showLiveCamera and silentLiveCapture cannot both be true. '
      'When showLiveCamera is true, silentLiveCapture is ignored.',
    );
  }

  @override
  State<FormFieldsSignaturePad> createState() => _FormFieldsSignaturePadState();
}

class _FormFieldsSignaturePadState extends State<FormFieldsSignaturePad> {
  late SignatureController _signatureController;
  late FormFieldsMyImageController _cameraController;
  bool _ownsCamera = false;

  // Debounce timer used to detect end-of-drawing and trigger auto-export.
  Timer? _autoExportTimer;
  static const Duration _autoExportDebounce = Duration(milliseconds: 1200);

  // Guard to avoid overlapping auto-export runs.
  bool _autoExportInProgress = false;

  /// Key used to trigger capture/reset on the separated live-camera widget.
  final _liveCameraKey = GlobalKey<FormFieldsLiveCameraCaptureState>();

  /// Guards auto-capture so it fires only once per signing session.
  /// Reset to false when the clear button is pressed.
  bool _hasCaptured = false;

  late FormFieldsSignaturePadProvider _padProvider;

  final _formFieldKey = GlobalKey<FormFieldState<bool>>();
  FormFieldsLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _padProvider = FormFieldsSignaturePadProvider();
    _initCameraController();
    _signatureController = SignatureController(
      penStrokeWidth: widget.penStrokeWidth,
      penColor: widget.penColor,
      exportBackgroundColor:
          widget.exportBackgroundColor ?? widget.backgroundColor,
      onDrawStart: _onDrawStart,
    );
    _signatureController.addListener(_onSignatureChanged);
    _bindSignaturePadController(widget.signaturePadController);
    // Acquire camera for silent background capture, but only after permission.
    if (widget.silentLiveCapture && !widget.showLiveCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final granted = await PermissionGate.ensureCameraPermission(context);
        if (!mounted) return;
        if (granted) {
          try {
            // Use a lower resolution for background/silent capture to speed
            // up camera initialization.
            await SharedCameraManager.instance.acquire(ResolutionPreset.low);
          } catch (_) {}
        }
      });
    }
    // Pre-seed preview from controller if it already holds a result.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPreviewFromSignaturePadController();
    });
  }

  void _initCameraController() {
    if (widget.liveCameraController != null) {
      _cameraController = widget.liveCameraController!;
      _ownsCamera = false;
    } else {
      _cameraController = FormFieldsMyImageController();
      _ownsCamera = true;
    }
    _cameraController.addListener(_onLiveCameraControllerChanged);
    _syncCaptureGuardFromController();
    // Register camera controller with OfflineUploadManager so offline
    // persisted upload retries can update the controller previews.
    try {
      OfflineUploadManager.instance.registerController(_cameraController);
    } catch (_) {}
  }

  void _disposeCameraControllerBinding() {
    _cameraController.removeListener(_onLiveCameraControllerChanged);
    // Unregister from OfflineUploadManager (best-effort)
    try {
      OfflineUploadManager.instance.unregisterController(_cameraController);
    } catch (_) {}
  }

  // ── SignaturePadController binding ────────────────────────────────────────

  void _bindSignaturePadController(
      FormFieldsSignaturePadController? controller) {
    controller?.registerClearHandler(_clearSignatureSession);
    controller?.addListener(_onSignaturePadControllerChanged);
  }

  void _unbindSignaturePadController(
      FormFieldsSignaturePadController? controller) {
    controller?.unregisterClearHandler();
    controller?.removeListener(_onSignaturePadControllerChanged);
  }

  void _onSignaturePadControllerChanged() {
    _syncPreviewFromSignaturePadController();
  }

  void _syncPreviewFromSignaturePadController() {
    if (!mounted) return;
    final ctrl = widget.signaturePadController;
    if (ctrl == null) return;
    final result = ctrl.exportResult;
    if (result != null) {
      _padProvider.setPreviewResults(
        signature: result.signature,
        liveCapture: result.liveCapture,
      );
      // Also sync live-capture controller so camera widget shows the prefilled image.
      _cameraController.images = [result.liveCapture];
    } else {
      _padProvider.clearPreviewResults();
    }
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

  String? _validateSignature(bool? hasSignature) {
    if (widget.externalErrorText != null) return widget.externalErrorText;
    if (widget.validator != null) {
      return widget.validator!(hasSignature ?? false);
    }
    if (widget.isRequired && (hasSignature != true)) {
      final l = _localizations;
      if (l == null) return '';
      final label = widget.label;
      return (label != null && label.isNotEmpty)
          ? l.getWithLabel('signatureRequired', label)
          : l.get('signatureRequiredDefault');
    }
    return null;
  }

  void _onLiveCameraControllerChanged() {
    _syncCaptureGuardFromController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSignature = _signatureController.isNotEmpty || _hasCaptured;
      _formFieldKey.currentState?.didChange(hasSignature);
      _formFieldKey.currentState?.validate();
    });
  }

  void _syncCaptureGuardFromController() {
    _hasCaptured = widget.showLiveCamera && _cameraController.images.isNotEmpty;
  }

  @override
  void didUpdateWidget(FormFieldsSignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.showExportPreview &&
        oldWidget.showExportPreview != widget.showExportPreview &&
        (_padProvider.previewSignatureResult != null ||
            _padProvider.previewLiveCaptureResult != null)) {
      _padProvider.clearPreviewResults();
    }
    // If the external liveCameraController changed, rebind/unbind so the
    // OfflineUploadManager and listeners attach to the new controller.
    if (widget.liveCameraController != oldWidget.liveCameraController) {
      _disposeCameraControllerBinding();
      if (_ownsCamera) {
        try {
          _cameraController.dispose();
        } catch (_) {}
      }
      _initCameraController();
    }
  }

  Future<bool> _hasNetwork() async {
    try {
      final conn = await Connectivity().checkConnectivity();
      return conn.contains(ConnectivityResult.none) ? false : true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _autoExportTimer?.cancel();
    _unbindSignaturePadController(widget.signaturePadController);
    _disposeCameraControllerBinding();
    _signatureController.removeListener(_onSignatureChanged);
    _signatureController.dispose();
    if (_ownsCamera) _cameraController.dispose();
    if (widget.silentLiveCapture && !widget.showLiveCamera) {
      SharedCameraManager.instance.release();
    }
    _padProvider.dispose();
    super.dispose();
  }

  // ── Auto-capture on draw start ─────────────────────────────────────────────

  void _onSignatureChanged() {
    _formFieldKey.currentState?.didChange(_signatureController.isNotEmpty);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formFieldKey.currentState?.validate();
    });

    // Schedule auto-export when the user pauses drawing.
    if (widget.autoExportOnFinish) {
      _autoExportTimer?.cancel();
      if (_signatureController.isNotEmpty) {
        _autoExportTimer = Timer(_autoExportDebounce, () {
          if (!mounted) return;
          if (_signatureController.isNotEmpty) {
            _triggerAutoExport();
          }
        });
      }
    }
  }

  Future<void> _triggerAutoExport() async {
    if (_autoExportInProgress) return;
    _autoExportInProgress = true;
    try {
      // Do not auto-export while upload is in progress.
      if (_padProvider.isUploading) return;
      await _exportSignature();
    } finally {
      _autoExportInProgress = false;
    }
  }

  Widget _buildLabel() {
    final label = widget.label;
    if (label == null ||
        label.isEmpty ||
        widget.labelPosition == LabelPosition.none) {
      return const SizedBox.shrink();
    }
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

  Future<void> _onDrawStart() async {
    if (!widget.showLiveCamera && !widget.silentLiveCapture) return;
    if (_hasCaptured) return; // already captured this session
    _hasCaptured = true;

    // Silent capture: use CameraController.takePicture() directly.
    if (widget.silentLiveCapture && !widget.showLiveCamera) {
      final ctrl = SharedCameraManager.instance.controller;
      if (ctrl == null || !ctrl.value.isInitialized) {
        _hasCaptured = false;
        return;
      }
      try {
        final xfile = await ctrl.takePicture();
        final result = await MyImageResult.fromFile(File(xfile.path));
        _cameraController.images = [result];
        widget.onLiveCaptured?.call(result);
      } catch (_) {
        _hasCaptured = false;
      }
      return;
    }

    // Visible camera: screenshot-based capture via FormFieldsLiveCameraCapture.
    final result = await _liveCameraKey.currentState?.capture();
    if (result == null) {
      // Allow retry if capture failed during draw start.
      _hasCaptured = false;
    }
  }

  void _clearSignatureSession() {
    _signatureController.clear();
    // Reset capture flag so the next draw triggers a fresh photo.
    _hasCaptured = false;
    if (widget.showLiveCamera) {
      _liveCameraKey.currentState?.resetCapture();
    }
    _cameraController.clear();
    if (_padProvider.previewSignatureResult != null ||
        _padProvider.previewLiveCaptureResult != null) {
      _padProvider.clearPreviewResults();
    }
    widget.signaturePadController?.clearFromWidget();
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<void> _exportSignature() async {
    final hasCallback =
        widget.onExported != null || widget.onExportedResult != null;
    if (!hasCallback) return;

    final data = await _signatureController.toPngBytes();
    if (data == null) {
      widget.onExported?.call(null);
      return;
    }

    final tempDir = Directory.systemTemp;
    final file = await File(
      '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    ).create();
    await file.writeAsBytes(data);
    final signatureResult = await MyImageResult.fromFile(file);
    // Prefer any captured image from the camera controller (covers silent
    // background captures) — do not require `showLiveCamera` to be true.
    final liveCapture = _cameraController.images.isNotEmpty
        ? _cameraController.images.first
        : MyImageResult();

    if (widget.isDirectUpload) {
      // Show preview with local result immediately, but delay callbacks until
      // upload finishes so callers always receive the server link/imageId.
      if (widget.showExportPreview && mounted) {
        _padProvider.setPreviewResults(
          signature: signatureResult,
          liveCapture: liveCapture,
        );
      }
      if (!mounted) return;
      if (widget.showUploadLoading && mounted) {
        _padProvider.startUpload(initialProgress: 0.02);
      }
      final updatedSignature =
          await _uploadImageDio(signatureResult, showSuccessDialog: false);
      if (!mounted) return;
      if (widget.showUploadLoading && mounted) {
        if (updatedSignature != null &&
            updatedSignature.status == MyImageStatus.uploaded) {
          _padProvider.completeUpload();
          await Future<void>.delayed(uploadCompletionTransitionDelay);
          if (mounted) {
            _padProvider.clearUpload();
          }
        } else {
          _padProvider.clearUpload();
        }
      }
      if (updatedSignature != null &&
          updatedSignature.status == MyImageStatus.uploaded &&
          widget.showUploadResultDialog &&
          mounted) {
        final l = FormFieldsLocalizations.of(context);
        final dialog = AppDialogService(context);
        await dialog.showSuccess(
          title: widget.uploadSuccessTitle ?? l.get('uploadSuccessTitle'),
          message: widget.uploadSuccessMessage ?? l.get('uploadSuccessMessage'),
        );
      }
      final finalSignature = updatedSignature ?? signatureResult;
      // Live capture is already uploaded by FormFieldsLiveCameraCapture.capture()
      // so _cameraController.images.first already has the server result.
      final finalLiveCapture =
          widget.showLiveCamera && _cameraController.images.isNotEmpty
              ? _cameraController.images.first
              : liveCapture;
      // Log final results for debugging (link/path/base64 length/status).
      debugPrint(
          '[FormFieldsSignaturePad._exportSignature] finalSignature: link=${finalSignature.link}, path=${finalSignature.path}, base64Len=${finalSignature.base64.length}, status=${finalSignature.status}');
      debugPrint(
          '[FormFieldsSignaturePad._exportSignature] finalLiveCapture: link=${finalLiveCapture.link}, path=${finalLiveCapture.path}, base64Len=${finalLiveCapture.base64.length}, status=${finalLiveCapture.status}');

      // Update preview with final (server) results.
      if (widget.showExportPreview && mounted) {
        _padProvider.setPreviewResults(
          signature: finalSignature,
          liveCapture: finalLiveCapture,
        );
      }
      final finalResult = SignaturePadExportResult(
        signature: finalSignature,
        liveCapture: finalLiveCapture,
      );
      // If any of the final results were queued (offline), notify caller so
      // they can persist payloads. Provide both the legacy list callback and
      // the new `SignaturePadExportResult` variant similar to
      // `onExportedResult`.
      if (finalSignature.status == MyImageStatus.queued ||
          finalLiveCapture.status == MyImageStatus.queued) {
        final nullable =
            SignaturePadExportNullableResult.fromExportResult(finalResult);
        try {
          // Prefer the nullable combined callback when provided so callers
          // receive both sides in one object where successful sides are
          // represented as `null`.
          if (widget.onFailDirectUploadList != null) {
            widget.onFailDirectUploadList?.call(nullable);
          }
        } catch (e, st) {
          debugPrint(
              'FormFieldsSignaturePad.onFailDirectUploadList threw: $e\n$st');
        }

        // Legacy single-item callback removed; callers should use
        // `onFailDirectUploadList` or `onFailDirectUploadPayload`.

        // Also provide upload-friendly payload maps for callers that prefer
        // to persist a simplified shape consumable by `DioUtil.uploadFile`.
        try {
          final imgs = <MyImageResult>[];
          if (nullable.signature != null) imgs.add(nullable.signature!);
          if (nullable.liveCapture != null) imgs.add(nullable.liveCapture!);
          final payloads =
              await UploadHelper.buildDirectUploadPayloadsFromImages(
            imgs,
            defaultUrl: widget.uploadUrl,
            fileFieldName: widget.uploadFileFieldName,
            includeReqType: widget.uploadIncludeReqType,
          );
          if (payloads.isNotEmpty) {
            widget.onFailDirectUploadPayload?.call(payloads);
            // Also provide a per-payload queued notification for callers
            // that prefer handling single sanitized payloads. At this point
            // we treat the queue reason as network-related (`authExpired=false`).
            try {
              for (final p in payloads) {
                widget.onUploadQueued?.call(p, false);
              }
            } catch (_) {}
          }
        } catch (e, st) {
          debugPrint(
              'FormFieldsSignaturePad.onFailDirectUploadPayload threw: $e\n$st');
        }
      }

      // If preview shows both images and this is a direct upload, notify
      // callers via `onError` when either final signature or final live
      // capture are not successfully uploaded. This detects server failures
      // even when the live-capture controller wasn't updated to `failed` by
      // checking the final status (uploaded vs non-uploaded) and whether a
      // live capture was actually present.
      if (widget.exportPreviewSource == SignaturePadPreviewSource.both &&
          widget.isDirectUpload) {
        // Determine if a live capture was present either before or after upload.
        final liveWasCaptured = widget.showLiveCamera &&
            (liveCapture.path.trim().isNotEmpty ||
                liveCapture.link.trim().isNotEmpty ||
                _cameraController.images.isNotEmpty);
        final finalLive = finalLiveCapture;
        final bool signatureFailed =
            finalSignature.status != MyImageStatus.uploaded;
        final bool liveFailed =
            liveWasCaptured && finalLive.status != MyImageStatus.uploaded;
        if (signatureFailed || liveFailed) {
          try {
            widget.onError?.call(finalResult);
          } catch (_) {}
        }
      }
      widget.signaturePadController?.updateFromWidget(finalResult);
      widget.onExported?.call(finalSignature);
      if (widget.onExportedResult != null) {
        widget.onExportedResult!(finalResult);
      }
    } else {
      if (widget.showExportPreview && mounted) {
        _padProvider.setPreviewResults(
          signature: signatureResult,
          liveCapture: liveCapture,
        );
      }
      final exportedResult = SignaturePadExportResult(
        signature: signatureResult,
        liveCapture: liveCapture,
      );
      widget.signaturePadController?.updateFromWidget(exportedResult);
      widget.onExported?.call(signatureResult);
      if (widget.onExportedResult != null) {
        widget.onExportedResult!(exportedResult);
      }
    }
  }

  /// Uploads [image] to [uploadUrl] and returns the updated [MyImageResult]
  /// with server link/imageId filled in. Returns `null` on failure.
  Future<MyImageResult?> _uploadImageDio(
    MyImageResult image, {
    bool showSuccessDialog = true,
  }) async {
    if (widget.uploadUrl == null) return null;
    final headers = <String, String>{};
    if (widget.uploadToken != null && widget.uploadToken!.isNotEmpty) {
      headers['Authorization'] = widget.uploadToken!;
    }

    // Prepare payload for offline enqueueing
    final fileName = image.path.trim().isNotEmpty
        ? image.path.split(Platform.pathSeparator).last
        : (image.link.isNotEmpty ? image.link.split('/').last : 'image');
    final imgDesc = (image.description).trim();
    final effDesc = imgDesc.isNotEmpty ? imgDesc : null;
    final extraFields = <MapEntry<String, String>>[];
    if (effDesc != null && effDesc.isNotEmpty) {
      extraFields.add(MapEntry('description', effDesc));
    }
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
      'index': 0,
    };
    // Add a correlation id to help reliably match persisted payloads back to
    // controller images when retry succeeds.
    final uploadCorrelationId =
        DateTime.now().microsecondsSinceEpoch.toString();
    payload['uploadCorrelationId'] = uploadCorrelationId;

    final hasNet = await _hasNetwork();
    if (!hasNet) {
      if (mounted && widget.showUploadLoading) {
        _padProvider.setUploadProgress(0.0);
      }
      // Return an updated MyImageResult containing payload so callers receive
      // the image (with payload) instead of a null failure. The caller
      // (export flow) will treat this as the final result and emit callbacks.
      final updatedImage = MyImageResult(
        link: image.link,
        base64: image.base64,
        path: image.path,
        imageId: image.imageId,
        description: image.description,
        payload: payload,
        status: MyImageStatus.queued,
      );
      return updatedImage;
    }

    debugPrint('[FormFieldsSignaturePad._uploadImageDio] '
        'START upload url=${widget.uploadUrl}, file=${image.path}, '
        'fileField=${widget.uploadFileFieldName}, includeReqType=${widget.uploadIncludeReqType}, headers=$headers, extraFields=${extraFields.map((e) => '${e.key}=${e.value}').toList()}');

    final response = await DioUtil.uploadFile(
      url: widget.uploadUrl!,
      filePath: image.path,
      filename: File(image.path).path.split('/').last,
      headers: headers,
      onProgress: (progress) {
        if (mounted && widget.showUploadLoading) {
          _padProvider.setUploadProgress(progress);
        }
      },
      fields: extraFields.isNotEmpty ? extraFields : null,
      fileFieldName: widget.uploadFileFieldName,
      includeReqType: widget.uploadIncludeReqType,
    );
    if (!mounted) return null;
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
      debugPrint(
          '[FormFieldsSignaturePad._uploadImageDio] response == null (network error)');
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadFailedTitle,
          message: uploadErrorMessage,
          dialogType: AppDialogType.network,
        );
      }
      return null;
    }
    try {
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
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
        debugPrint('[FormFieldsSignaturePad._uploadImageDio] '
            'status=${response.statusCode}, uploadedLink=$uploadedLink, '
            'uploadedPath=$uploadedPath, imageId=$imageId');

        if (showSuccessDialog && widget.showUploadResultDialog) {
          await dialog.showSuccess(
            title: uploadSuccessTitle,
            message: uploadSuccessMessage,
          );
        }

        final payload = data is Map<String, dynamic>
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{'raw': data};
        // Ensure we preserve local base64 so previews can render without
        // needing to fetch the network copy. If base64 is missing, read
        // bytes from the local path and encode.
        String finalBase64 = image.base64;
        if ((finalBase64.trim()).isEmpty && (image.path.trim()).isNotEmpty) {
          try {
            final bytes = await File(image.path).readAsBytes();
            final mime = MyImageResult.getMimeType(image.path);
            finalBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
          } catch (_) {
            // ignore file read errors — fallback will be network link
          }
        }

        // Build a usable link: prefer uploadedLink, otherwise try to build
        // an absolute URL from uploadedPath when possible (server may
        // return only a relative path).
        String? finalLink = (uploadedLink ?? image.link).trim();
        if ((finalLink.isEmpty) &&
            (uploadedPath != null && uploadedPath.trim().isNotEmpty)) {
          try {
            final base = Uri.parse(widget.uploadUrl!);
            final p =
                uploadedPath.startsWith('/') ? uploadedPath : '/$uploadedPath';
            finalLink = '${base.scheme}://${base.authority}$p';
          } catch (_) {
            // ignore and leave finalLink empty
          }
        }

        final resolvedPath = (uploadedPath != null &&
                uploadedPath.trim().isNotEmpty &&
                uploadedPath.startsWith(Platform.pathSeparator))
            ? uploadedPath
            : image.path;

        return MyImageResult(
          link: finalLink ?? image.link,
          base64: finalBase64,
          // Preserve local path unless server returned absolute path.
          path: resolvedPath,
          imageId: imageId ?? image.imageId,
          description: uploadedDescription ?? image.description,
          payload: payload,
          status: MyImageStatus.uploaded,
        );
      } else {
        debugPrint(
            '[FormFieldsSignaturePad._uploadImageDio] upload failed: status=${response.statusCode}, statusMessage=${response.statusMessage}, data=${response.data}');
        if (widget.showUploadResultDialog) {
          await dialog.showError(
            title: uploadFailedTitle,
            message: '$uploadFailedMessage ${response.statusMessage ?? ''}',
            dialogType: AppDialogType.server,
          );
        }
      }
    } catch (e) {
      debugPrint(
          '[FormFieldsSignaturePad._uploadImageDio] exception while processing response: $e');
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadErrorTitle,
          message: '$uploadErrorMessage $e',
          dialogType: AppDialogType.server,
        );
      }
    }
    return null;
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildPreviewImage(MyImageResult result,
      {BoxFit fit = BoxFit.contain}) {
    Widget imageWidget;
    final tokenHeader =
        (widget.uploadToken != null && widget.uploadToken!.isNotEmpty)
            ? <String, String>{'Authorization': widget.uploadToken!}
            : null;

    // Prefer local preview (file -> base64) to avoid forcing a network GET
    // immediately after upload. Only fall back to NetworkImage when no
    // local content is available.
    final hasLocalPath =
        result.path.trim().isNotEmpty && File(result.path).existsSync();
    final hasBase64 = result.base64.trim().isNotEmpty;

    if (hasLocalPath) {
      imageWidget = Image.file(
        File(result.path),
        fit: fit,
      );
    } else if (hasBase64) {
      final bytes = Uri.parse(result.base64).data?.contentAsBytes();
      if (bytes != null) {
        imageWidget = Image.memory(
          bytes,
          fit: fit,
        );
      } else {
        imageWidget = Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      }
    } else if (result.link.trim().isNotEmpty) {
      imageWidget = Image(
        image: NetworkImage(result.link, headers: tokenHeader),
        fit: fit,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      imageWidget = Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: imageWidget),
        if (result.status != MyImageStatus.idle)
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
                    color: Theme.of(context).shadowColor.withValues(alpha: .18),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                result.status == MyImageStatus.uploading
                    ? Icons.cloud_upload
                    : result.status == MyImageStatus.queued
                        ? Icons.schedule
                        : result.status == MyImageStatus.failed
                            ? Icons.error_outline
                            : Icons.check_circle,
                size: 14,
                color: result.status == MyImageStatus.failed
                    ? Theme.of(context).colorScheme.error
                    : resolveTextColor(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewCanvas(FormFieldsSignaturePadProvider provider) {
    final localizations = FormFieldsLocalizations.of(context);
    final signature = provider.previewSignatureResult;
    if (signature == null) {
      return const SizedBox.shrink();
    }

    switch (widget.exportPreviewSource) {
      case SignaturePadPreviewSource.signature:
        return _buildPreviewImage(signature);
      case SignaturePadPreviewSource.liveCapture:
        final live = provider.previewLiveCaptureResult;
        return _buildPreviewImage(live ?? signature);
      case SignaturePadPreviewSource.both:
        final live = provider.previewLiveCaptureResult;
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreviewImage(signature, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: live != null
                      ? _buildPreviewImage(live, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              localizations.get('noLiveCapture'),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSignaturePad(FormFieldsLocalizations localizations,
      FormFieldsSignaturePadProvider provider) {
    final loadingTheme = Theme.of(context).extension<AppLoadingThemeData>() ??
        const AppLoadingThemeData.fallback();
    final progressTheme = Theme.of(context).progressIndicatorTheme;
    final progressColor = progressTheme.color ?? loadingTheme.indicatorColor;
    final progressTrackColor =
        progressTheme.linearTrackColor ?? loadingTheme.trackColor;
    final isPreviewMode =
        widget.showExportPreview && provider.previewSignatureResult != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              color: widget.backgroundColor,
              width: widget.width,
              height: widget.height,
              child: isPreviewMode
                  ? _buildPreviewCanvas(provider)
                  : Signature(
                      controller: _signatureController,
                      backgroundColor: widget.backgroundColor,
                    ),
            ),
            // Upload loading overlay
            if (provider.isUploading)
              Positioned.fill(
                child: Container(
                  color: loadingTheme.overlayColor,
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 170,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: progressColor.withValues(alpha: .20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .shadowColor
                                  .withValues(alpha: .26),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppProgressIndicator(
                              type: AppProgressType.linear,
                              value: provider.uploadProgress,
                              minHeight: 6,
                              color: progressColor,
                              trackColor: progressTrackColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: localizations.get('signatureClear'),
                child: AppButton(
                  icon: const Icon(Icons.delete_forever),
                  text: '',
                  size: AppSize.small,
                  type: AppButtonType.icon,
                  onPressed:
                      provider.isUploading ? null : _clearSignatureSession,
                  customIconSize: 24,
                  customHeight: 36,
                ),
              ),
            ),
          ],
        ),
        if (!isPreviewMode && !widget.autoExportOnFinish) ...[
          const SizedBox(height: 12),
          Center(
            child: Tooltip(
              message: localizations.get('signatureExport'),
              child: AppButton(
                icon: const Icon(Icons.verified, size: 32),
                text: '',
                size: AppSize.small,
                type: AppButtonType.icon,
                onPressed: provider.isUploading ? null : _exportSignature,
                customIconSize: 32,
                customHeight: 48,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCameraWidget(BuildContext context) {
    // Forward payload-based failures from the live camera to the
    // signature pad's payload callback when provided. Use typed
    // `DirectUploadPayload` objects.
    final void Function(List<DirectUploadPayload>)? failPayloadCb =
        (widget.onFailDirectUploadPayload != null)
            ? (List<DirectUploadPayload> list) {
                try {
                  widget.onFailDirectUploadPayload!.call(list);
                } catch (_) {}
              }
            : null;

    final preview = FormFieldsLiveCameraCapture(
      key: _liveCameraKey,
      height: widget.liveCameraHeight,
      preAcquire: true,
      cameraController: _cameraController,
      onCaptured: widget.onLiveCaptured,
      isDirectUpload: widget.isDirectUpload,
      uploadUrl: widget.uploadUrl,
      uploadToken: widget.uploadToken,
      showUploadResultDialog: widget.showUploadResultDialog,
      showUploadLoading: widget.showUploadLoading,
      uploadSuccessTitle: widget.uploadSuccessTitle,
      uploadFailedTitle: widget.uploadFailedTitle,
      uploadErrorTitle: widget.uploadErrorTitle,
      uploadSuccessMessage: widget.uploadSuccessMessage,
      uploadFailedMessage: widget.uploadFailedMessage,
      uploadErrorMessage: widget.uploadErrorMessage,
      uploadFileUrlKey: widget.uploadFileUrlKey,
      uploadImageIdKey: widget.uploadImageIdKey,
      onFailDirectUploadPayload: failPayloadCb,
    );
    if (widget.liveCameraBuilder != null) {
      return widget.liveCameraBuilder!(context, preview);
    }
    return _DefaultCameraSection(child: preview);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _localizations = FormFieldsLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _padProvider,
      child: Consumer<FormFieldsSignaturePadProvider>(
        builder: (context, provider, _) {
          final localizations = _localizations!;
          final pad = _buildSignaturePad(localizations, provider);
          final cameraWidget =
              widget.showLiveCamera ? _buildCameraWidget(context) : null;

          Widget content;
          if (widget.layoutBuilder != null) {
            content = widget.layoutBuilder!(context, pad, cameraWidget);
          } else if (cameraWidget == null) {
            content = pad;
          } else {
            content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                pad,
                const SizedBox(height: 16),
                cameraWidget,
              ],
            );
          }

          return FormField<bool>(
            key: _formFieldKey,
            autovalidateMode: widget.autovalidateMode,
            initialValue: false,
            validator: _validateSignature,
            builder: (state) {
              final inner = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
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
              return _wrapWithLabel(inner);
            },
          );
        },
      ),
    );
  }
}

/// Default visual wrapper for the live camera section.
class _DefaultCameraSection extends StatelessWidget {
  final Widget child;
  const _DefaultCameraSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final localizations = FormFieldsLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              Icons.camera_front_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            Text(
              localizations.get('liveCaptureTitle'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizations.get('liveCaptureAutoOnSign'),
                style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
