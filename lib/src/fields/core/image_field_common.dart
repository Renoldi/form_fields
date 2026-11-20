/// Shared building blocks for the single-image capture fields: MyImage,
/// SignaturePad and LiveCameraCapture.
///
/// These fields used to repeat the same upload pipeline, payload builder,
/// response mapping, status badge and progress overlay. Each one now calls the
/// helpers here. Behavior that differs between fields is set through
/// [DirectUploadSettings] so each field keeps its own rules.
library;

import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:form_fields/src/feedback/app_dialog_service.dart';
import 'package:form_fields/src/feedback/app_indicators.dart';
import 'package:form_fields/src/localization/form_fields_localizations.dart';
import 'package:form_fields/src/models/direct_upload_payload.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/service/dio_service.dart';
import 'package:form_fields/src/service/upload_helper.dart';
import 'package:form_fields/src/service/upload_response_mapper.dart';
import 'package:form_fields/src/service/upload_service.dart';
import 'package:form_fields/src/theme/form_fields_themes.dart';
import 'package:form_fields/src/utilities/debug_log.dart';
import 'package:form_fields/src/utilities/enums.dart';
import 'package:form_fields/src/utilities/network_status.dart';
import 'package:form_fields/src/utilities/persisted_headers.dart';
import 'package:form_fields/src/utilities/theme_helpers.dart';

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

/// Titles and messages shown after an upload. Each value is the field's own
/// override when it is set, otherwise the localized default.
class ImageUploadMessages {
  const ImageUploadMessages({
    required this.successTitle,
    required this.failedTitle,
    required this.errorTitle,
    required this.successMessage,
    required this.failedMessage,
    required this.errorMessage,
  });

  factory ImageUploadMessages.resolve(
    FormFieldsLocalizations l, {
    String? successTitle,
    String? failedTitle,
    String? errorTitle,
    String? successMessage,
    String? failedMessage,
    String? errorMessage,
  }) {
    return ImageUploadMessages(
      successTitle: successTitle ?? l.get('uploadSuccessTitle'),
      failedTitle: failedTitle ?? l.get('uploadFailedTitle'),
      errorTitle: errorTitle ?? l.get('uploadErrorTitle'),
      successMessage: successMessage ?? l.get('uploadSuccessMessage'),
      failedMessage: failedMessage ?? l.get('uploadFailedMessage'),
      errorMessage: errorMessage ?? l.get('uploadErrorMessage'),
    );
  }

  final String successTitle;
  final String failedTitle;
  final String errorTitle;
  final String successMessage;
  final String failedMessage;
  final String errorMessage;
}

// ---------------------------------------------------------------------------
// Upload settings and the direct upload pipeline
// ---------------------------------------------------------------------------

/// Everything a direct (single-request) upload needs from its field.
class DirectUploadSettings {
  const DirectUploadSettings({
    required this.uploadUrl,
    required this.uploadToken,
    required this.fileFieldName,
    required this.includeReqType,
    required this.fileUrlKey,
    required this.imageIdKey,
    required this.descriptionFormField,
    required this.descriptionResponseKey,
    required this.showLoading,
    required this.showResultDialog,
    required this.logTag,
    this.successTitle,
    this.failedTitle,
    this.errorTitle,
    this.successMessage,
    this.failedMessage,
    this.errorMessage,
    this.onUploadQueued,
    this.onFailDirectUploadPayload,
  });

  final String? uploadUrl;
  final String? uploadToken;
  final String fileFieldName;
  final bool includeReqType;

  /// Response key that holds the uploaded file URL.
  final String fileUrlKey;

  /// Response key that holds the server image id.
  final String imageIdKey;

  /// Multipart form field that carries the description.
  final String descriptionFormField;

  /// Response key that holds the description.
  final String descriptionResponseKey;

  /// Whether to report progress and show the overlay while uploading.
  final bool showLoading;

  /// Whether to show success and failure dialogs.
  final bool showResultDialog;

  /// Prefix for debug logs, usually the field and method name.
  final String logTag;

  final String? successTitle;
  final String? failedTitle;
  final String? errorTitle;
  final String? successMessage;
  final String? failedMessage;
  final String? errorMessage;

  final void Function(DirectUploadPayload payload, bool authExpired)?
  onUploadQueued;
  final void Function(List<DirectUploadPayload> payloads)?
  onFailDirectUploadPayload;

}

/// Runs one direct upload for a single-image field.
///
/// The rules for every field:
/// - A queued upload (offline, expired token, or retryable server error) is
///   reported once, when it is queued, and the queued image is returned.
/// - A failure shows the failure dialog, even when the upload was queued.
/// - `null` means the upload was refused and not queued.
class DirectImageUploader {
  DirectImageUploader({
    required this.context,
    required this.isMounted,
    required this.settings,
    required this.onProgress,
    this.onUploading,
  });

  final BuildContext context;
  final bool Function() isMounted;
  final DirectUploadSettings settings;

  /// Receives upload progress from 0.0 to 1.0. Only called while [isMounted]
  /// and [DirectUploadSettings.showLoading] are true.
  final void Function(double progress) onProgress;

  /// Called with the "uploading" copy of the image before the request starts.
  final void Function(MyImageResult uploading)? onUploading;

  Future<MyImageResult?> upload(
    MyImageResult image, {
    bool showSuccessDialog = true,
  }) async {
    final s = settings;
    final uploadUrl = s.uploadUrl;
    if (uploadUrl == null) return null;

    // Resolved before the first await so no BuildContext is used after a gap.
    final messages = ImageUploadMessages.resolve(
      FormFieldsLocalizations.of(context),
      successTitle: s.successTitle,
      failedTitle: s.failedTitle,
      errorTitle: s.errorTitle,
      successMessage: s.successMessage,
      failedMessage: s.failedMessage,
      errorMessage: s.errorMessage,
    );
    final dialog = AppDialogService(context);

    final headers = buildUploadAuthHeaders(s.uploadToken);
    final effDesc = resolveUploadDescription(image);
    final formFields = descriptionFormFields(effDesc, s.descriptionFormField);
    final payload = buildImageUploadPayload(
      uploadUrl: uploadUrl,
      headers: headers,
      image: image,
      fileName: resolveUploadFileName(image),
      description: effDesc,
      formFields: formFields,
      fileUrlKey: s.fileUrlKey,
      imageIdKey: s.imageIdKey,
      index: 0,
    );

    final hasNet = await isNetworkAvailable();
    if (!hasNet) {
      if (isMounted() && s.showLoading) onProgress(0.0);
      final queued = await queueImageForRetry(
        image: image,
        payload: payload,
        settings: s,
        authExpired: false,
      );
      return queued.image;
    }

    onUploading?.call(_copyWithStatus(image, MyImageStatus.uploading));

    debugLog(
      '[${s.logTag}] START upload url=$uploadUrl, file=${image.path}, '
      'fileField=${s.fileFieldName}, includeReqType=${s.includeReqType}, '
      'headers=${headers.keys.toList()}, '
      'extraFields=${formFields.map((e) => '${e.key}=${e.value}').toList()}',
    );

    final response = await DioUtil.uploadFile(
      url: uploadUrl,
      filePath: image.path,
      filename: File(image.path).path.split('/').last,
      headers: headers,
      onProgress: (progress) {
        if (isMounted() && s.showLoading) onProgress(progress);
      },
      fields: formFields.isNotEmpty ? formFields : null,
      fileFieldName: s.fileFieldName,
      includeReqType: s.includeReqType,
    );
    if (!context.mounted) return null;

    if (response == null) {
      debugLog('[${s.logTag}] response == null (network error)');
      if (s.showResultDialog) {
        await dialog.showError(
          title: messages.failedTitle,
          message: messages.errorMessage,
          dialogType: AppDialogType.network,
        );
      }
      return null;
    }

    // An expired token is queued so the caller can retry with a fresh token.
    if (response.statusCode == 401) {
      debugLog('[${s.logTag}] upload failed: 401 -> queueing payload');
      final queued = await queueImageForRetry(
        image: image,
        payload: payload,
        settings: s,
        authExpired: true,
      );
      if (s.showResultDialog) {
        await dialog.showError(
          title: messages.failedTitle,
          message: messages.errorMessage,
          dialogType: AppDialogType.server,
        );
      }
      return queued.image;
    }

    try {
      if (UploadResponseMapper.isSuccessfulStatus(response.statusCode)) {
        final data = response.data;
        final extracted = extractUploadResponse(
          data,
          fileUrlKey: s.fileUrlKey,
          imageIdKey: s.imageIdKey,
          descriptionKey: s.descriptionResponseKey,
        );
        debugLog(
          '[${s.logTag}] status=${response.statusCode}, '
          'uploadedLink=${extracted.link}, uploadedPath=${extracted.path}, '
          'imageId=${extracted.imageId}',
        );

        if (showSuccessDialog && s.showResultDialog) {
          await dialog.showSuccess(
            title: messages.successTitle,
            message: messages.successMessage,
          );
        }

        final responsePayload = data is Map<String, dynamic>
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{'raw': data};

        return MyImageResult(
          link: resolveUploadedLink(
            uploadedLink: extracted.link,
            fallbackLink: image.link,
            uploadedPath: extracted.path,
            uploadUrl: uploadUrl,
          ),
          base64: await readBase64IfMissing(image),
          path: resolveUploadedPath(extracted.path, image.path),
          imageId: extracted.imageId ?? image.imageId,
          description: extracted.description ?? image.description,
          payload: responsePayload,
          status: MyImageStatus.uploaded,
        );
      }

      debugLog(
        '[${s.logTag}] upload failed: status=${response.statusCode}, '
        'statusMessage=${response.statusMessage}, data=${response.data}',
      );
      // Only failures that can succeed later are queued. A permanent client
      // error (400, 403, 404, 422, ...) would be retried forever, so it is
      // reported and not queued.
      MyImageResult? queued;
      if (UploadService.isRetryableStatus(response.statusCode)) {
        final result = await queueImageForRetry(
          image: image,
          payload: payload,
          settings: s,
          authExpired: false,
        );
        queued = result.image;
      }
      if (s.showResultDialog) {
        await dialog.showError(
          title: messages.failedTitle,
          message: '${messages.failedMessage} ${response.statusMessage ?? ''}',
          dialogType: AppDialogType.server,
        );
      }
      return queued;
    } catch (e) {
      debugLog('[${s.logTag}] exception while processing response: $e');
      if (s.showResultDialog) {
        await dialog.showError(
          title: messages.errorTitle,
          message: '${messages.errorMessage} $e',
          dialogType: AppDialogType.server,
        );
      }
    }
    return null;
  }
}

/// Result of [queueImageForRetry]: the queued image and, when one could be
/// built, the payload that was reported to the caller.
class QueuedImageUpload {
  const QueuedImageUpload(this.image, this.payload);

  final MyImageResult image;
  final DirectUploadPayload? payload;
}

/// Marks [image] as queued with [payload] and reports it once, through
/// [DirectUploadSettings.onUploadQueued] and
/// [DirectUploadSettings.onFailDirectUploadPayload]. Every queued upload goes
/// through here, so the rule holds for all fields.
Future<QueuedImageUpload> queueImageForRetry({
  required MyImageResult image,
  required Map<String, dynamic> payload,
  required DirectUploadSettings settings,
  required bool authExpired,
}) async {
  final queued = _queuedCopy(image, payload);
  DirectUploadPayload? direct;
  try {
    direct = await UploadHelper.buildDirectUploadPayloadFromImage(
      queued,
      defaultUrl: settings.uploadUrl,
      fileFieldName: settings.fileFieldName,
      includeReqType: settings.includeReqType,
    );
    if (direct != null) {
      debugLog(
        '[${settings.logTag}] queued -> payload.correlation='
        '${direct.uploadCorrelationId} file=${direct.fileName} '
        'path=${direct.filePath}',
      );
      try {
        settings.onUploadQueued?.call(direct, authExpired);
      } catch (e, st) {
        debugLog('[${settings.logTag}] onUploadQueued threw: $e\n$st');
      }
      try {
        settings.onFailDirectUploadPayload?.call([direct]);
      } catch (e, st) {
        debugLog(
          '[${settings.logTag}] onFailDirectUploadPayload threw: $e\n$st',
        );
      }
    }
  } catch (e, st) {
    debugLog(
      '[${settings.logTag}] error while building queued payload: $e\n$st',
    );
  }
  return QueuedImageUpload(queued, direct);
}

MyImageResult _queuedCopy(MyImageResult image, Map<String, dynamic> payload) {
  return MyImageResult(
    link: image.link,
    base64: image.base64,
    path: image.path,
    imageId: image.imageId,
    description: image.description,
    payload: payload,
    status: MyImageStatus.queued,
  );
}

MyImageResult _copyWithStatus(MyImageResult image, MyImageStatus status) {
  return MyImageResult(
    link: image.link,
    base64: image.base64,
    path: image.path,
    imageId: image.imageId,
    description: image.description,
    payload: image.payload,
    status: status,
  );
}

// ---------------------------------------------------------------------------
// Payload and response helpers
// ---------------------------------------------------------------------------

/// The description to send with an upload: [explicit] when it is given and not
/// blank, otherwise the image's own description. Returns `null` when both are
/// blank.
String? resolveUploadDescription(MyImageResult image, {String? explicit}) {
  final trimmed = explicit?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  final own = image.description.trim();
  return own.isNotEmpty ? own : null;
}

/// Multipart form fields for [description], or none when it is blank.
List<MapEntry<String, String>> descriptionFormFields(
  String? description,
  String fieldName,
) {
  if (description == null || description.isEmpty) {
    return <MapEntry<String, String>>[];
  }
  return <MapEntry<String, String>>[MapEntry(fieldName, description)];
}

/// Builds the resumable payload stored for an upload, so it can be sent later
/// when the device is offline or the token has expired.
Map<String, dynamic> buildImageUploadPayload({
  required String? uploadUrl,
  required Map<String, String> headers,
  required MyImageResult image,
  required String fileName,
  required String? description,
  required List<MapEntry<String, String>> formFields,
  required String fileUrlKey,
  required String imageIdKey,
  required int index,
}) {
  return <String, dynamic>{
    'url': uploadUrl,
    'headers': headersForPersistence(headers),
    'fields': Map<String, String>.fromEntries(formFields),
    'file': {'fileName': fileName, 'base64': image.base64, 'path': image.path},
    'uploadFileUrlKey': fileUrlKey,
    'uploadImageIdKey': imageIdKey,
    'description': description,
    'index': index,
    // Lets the retry match a persisted payload back to its image.
    'uploadCorrelationId': DateTime.now().microsecondsSinceEpoch.toString(),
  };
}

/// Values read from an upload response.
typedef UploadResponseFields = ({
  String? link,
  String? imageId,
  String? description,
  String? path,
});

UploadResponseFields extractUploadResponse(
  dynamic data, {
  required String fileUrlKey,
  required String imageIdKey,
  required String descriptionKey,
}) {
  return (
    link: UploadResponseMapper.extractUploadedLink(data, keys: fileUrlKey),
    imageId: UploadResponseMapper.extractImageId(data, keys: imageIdKey),
    description: UploadResponseMapper.extractDescription(
      data,
      keys: descriptionKey,
    ),
    path: UploadResponseMapper.extractFilePath(data, keys: 'filePath'),
  );
}

/// The uploaded file link. Falls back to [fallbackLink], and builds an absolute
/// URL from [uploadedPath] when the server returned only a relative path.
String resolveUploadedLink({
  required String? uploadedLink,
  required String fallbackLink,
  required String? uploadedPath,
  required String? uploadUrl,
}) {
  var link = (uploadedLink ?? fallbackLink).trim();
  if (link.isEmpty &&
      uploadedPath != null &&
      uploadedPath.trim().isNotEmpty &&
      uploadUrl != null) {
    try {
      final base = Uri.parse(uploadUrl);
      final p = uploadedPath.startsWith('/') ? uploadedPath : '/$uploadedPath';
      link = '${base.scheme}://${base.authority}$p';
    } catch (_) {
      // Keep the empty link when the upload URL cannot be parsed.
    }
  }
  return link;
}

/// The local path to keep. The uploaded path wins when the server returned one.
String resolveUploadedPath(String? uploadedPath, String fallbackPath) {
  return (uploadedPath != null && uploadedPath.trim().isNotEmpty)
      ? uploadedPath
      : fallbackPath;
}

/// The image's base64. When it is empty, it is read from the local file so the
/// preview can render without fetching the network copy.
Future<String> readBase64IfMissing(MyImageResult image) async {
  if (image.base64.trim().isNotEmpty || image.path.trim().isEmpty) {
    return image.base64;
  }
  try {
    final bytes = await File(image.path).readAsBytes();
    final mime = MyImageResult.getMimeType(image.path);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  } catch (_) {
    return image.base64;
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

/// Icon for an image's upload status.
IconData imageStatusIcon(MyImageStatus status) {
  switch (status) {
    case MyImageStatus.uploading:
      return Icons.cloud_upload;
    case MyImageStatus.queued:
      return Icons.schedule;
    case MyImageStatus.failed:
      return Icons.error_outline;
    case MyImageStatus.idle:
    case MyImageStatus.uploaded:
      return Icons.check_circle;
  }
}

/// Small rounded badge that shows an image's upload status. The caller places
/// it, for example with a [Positioned].
class ImageStatusBadge extends StatelessWidget {
  const ImageStatusBadge({super.key, required this.status});

  final MyImageStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: .18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        imageStatusIcon(status),
        size: 14,
        color: status == MyImageStatus.failed
            ? scheme.error
            : resolveTextColor(context),
      ),
    );
  }
}

/// Card with a linear progress bar, shown over an image while it uploads. The
/// caller places it, for example inside a [Positioned.fill].
class ImageUploadProgressOverlay extends StatelessWidget {
  const ImageUploadProgressOverlay({
    super.key,
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    this.width = 170,
    this.padding = 10,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double width;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingTheme =
        theme.extension<AppLoadingThemeData>() ??
        const AppLoadingThemeData.fallback();
    return Container(
      color: loadingTheme.overlayColor,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: width,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: progressColor.withValues(alpha: .20)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: .25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AppProgressIndicator(
              type: AppProgressType.linear,
              value: progress,
              minHeight: 6,
              color: progressColor,
              trackColor: trackColor,
            ),
          ),
        ),
      ),
    );
  }
}
