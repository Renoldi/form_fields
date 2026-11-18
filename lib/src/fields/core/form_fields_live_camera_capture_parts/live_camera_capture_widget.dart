part of '../form_fields_live_camera_capture.dart';

/// Reusable front-camera live preview that can capture a frame into
/// [FormFieldsMyImageController].
class FormFieldsLiveCameraCapture extends StatefulWidget {
  final double height;

  /// Resolution preset used when creating the camera controller.
  /// Lower presets initialize faster but have lower preview/capture quality.
  final ResolutionPreset resolutionPreset;

  /// Controller that will be updated with the latest captured image.
  /// Optional — only needed when you want to read captured images or trigger
  /// capture/reset programmatically without a [GlobalKey].
  final FormFieldsMyImageController? cameraController;

  /// Called each time [FormFieldsLiveCameraCaptureState.capture] succeeds.
  /// When [isDirectUpload] is enabled, the result passed here will already
  /// contain the server [MyImageResult.link] and [MyImageResult.imageId].
  final void Function(MyImageResult captured)? onCaptured;

  // ── Upload ─────────────────────────────────────────────────────────────────

  /// Upload otomatis saat capture selesai.
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

  /// Show a loading overlay on the camera preview while uploading.
  /// Defaults to `true`.
  final bool showUploadLoading;

  // Customizable upload messages
  final String? uploadSuccessTitle;
  final String? uploadFailedTitle;
  final String? uploadErrorTitle;
  final String? uploadSuccessMessage;
  final String? uploadFailedMessage;
  final String? uploadErrorMessage;

  /// Called when `isDirectUpload == true` but the device has no internet.
  /// Receives a list of `MyImageResult` (each containing `payload`) so the
  /// caller can persist and retry uploads later. This matches
  /// `FormFieldsMyImage` semantics.

  /// Alternative callback that receives a list of typed `DirectUploadPayload`.
  /// Each item is ready to be serialized via `toMap()`/`toJson()` for
  /// persistence or re-upload.
  final void Function(List<DirectUploadPayload> payloads)?
  onFailDirectUploadPayload;

  /// New callback invoked when an individual upload payload is queued by the
  /// widget (e.g. auth expiry). Receives a sanitized `DirectUploadPayload`
  /// and a boolean `authExpired` which is true when the library detected an
  /// authentication expiry (401) situation.
  final void Function(DirectUploadPayload payload, bool authExpired)?
  onUploadQueued;

  // `onFailDirectUploadResult` removed — live camera reports single results
  // via `onFailDirectUpload` only.

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

  /// When `true`, the camera preview is hidden (renders as a zero-size widget)
  /// but the camera is still initialised in the background, allowing
  /// [FormFieldsLiveCameraCaptureState.capture] to fire silently.
  ///
  /// In silent mode [capture] uses [CameraController.takePicture] instead of
  /// the screenshot path, so no rendered widget is required.
  final bool hidePreview;

  /// When `true`, attempt to acquire the camera as soon as the widget is
  /// mounted (after the first frame) so the preview is ready faster.
  /// Permission will be requested if needed.
  final bool preAcquire;

  final String? descriptionField;

  /// Image compression quality passed to `MyImageResult.fromFile` (1-100).
  final int quality;

  FormFieldsLiveCameraCapture({
    super.key,
    this.height = 100,
    this.resolutionPreset = ResolutionPreset.low,
    this.cameraController,
    this.onCaptured,
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
    this.onFailDirectUploadPayload,
    this.onUploadQueued,
    this.uploadFileUrlKey = 'fileUrl',
    this.uploadImageIdKey = 'imageId',
    this.uploadFileFieldName = 'file',
    this.uploadIncludeReqType = true,
    this.hidePreview = false,
    this.preAcquire = false,
    this.descriptionField,
    this.quality = 80,
  }) : assert(
         isDirectUpload == false || (uploadUrl != null && uploadUrl.isNotEmpty),
         'For direct upload, uploadUrl must be provided and non-empty.',
       );

  @override
  State<FormFieldsLiveCameraCapture> createState() =>
      FormFieldsLiveCameraCaptureState();
}
