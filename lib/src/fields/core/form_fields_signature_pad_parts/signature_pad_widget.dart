part of '../form_fields_signature_pad.dart';

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
  final Color? backgroundColor;
  final Color? penColor;
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
  ///   MyImageResult.network('https://example.com/sig.png'),
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
  )?
  layoutBuilder;

  /// Custom wrapper for only the camera section.
  /// Receives the live-preview widget; return a decorated version.
  /// Ignored when [layoutBuilder] is provided.
  /// Image compression quality passed to `MyImageResult.fromFile` (1-100).
  final int quality;
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
    this.backgroundColor,
    this.penColor,
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
    this.quality = 80,
  }) : assert(
         isDirectUpload == false || (uploadUrl != null && uploadUrl.isNotEmpty),
         "For direct upload, uploadUrl must be provided and non-empty.",
       ) {
    // Warn developer about the conflicting combination at construction time.
    if (silentLiveCapture && showLiveCamera) {
      if (kDebugMode) {
        debugLog(
          'FormFieldsSignaturePad: silentLiveCapture ignored when showLiveCamera==true',
        );
      }
    }
  }

  @override
  State<FormFieldsSignaturePad> createState() => _FormFieldsSignaturePadState();
}
