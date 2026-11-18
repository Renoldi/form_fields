part of '../form_fields_signature_pad.dart';

extension _FormFieldsSignaturePadUploadX on _FormFieldsSignaturePadState {
  /// Uploads [image] to [uploadUrl] and returns the updated [MyImageResult]
  /// with server link/imageId filled in. Returns `null` on failure when the
  /// upload was refused and not queued.
  Future<MyImageResult?> _uploadImageDio(
    MyImageResult image, {
    bool showSuccessDialog = true,
  }) async {
    if (widget.uploadUrl == null) return null;
    final headers = buildUploadAuthHeaders(widget.uploadToken);

    // Prepare payload for offline enqueueing
    final fileName = resolveUploadFileName(image);
    final imgDesc = (image.description).trim();
    final effDesc = imgDesc.isNotEmpty ? imgDesc : null;
    final extraFields = <MapEntry<String, String>>[];
    if (effDesc != null && effDesc.isNotEmpty) {
      extraFields.add(MapEntry('description', effDesc));
    }
    final payload = <String, dynamic>{
      'url': widget.uploadUrl,
      'headers': headersForPersistence(headers),
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
    final uploadCorrelationId = DateTime.now().microsecondsSinceEpoch
        .toString();
    payload['uploadCorrelationId'] = uploadCorrelationId;

    final hasNet = await isNetworkAvailable();
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

    debugLog(
      '[FormFieldsSignaturePad._uploadImageDio] '
      'START upload url=${widget.uploadUrl}, file=${image.path}, '
      'fileField=${widget.uploadFileFieldName}, includeReqType=${widget.uploadIncludeReqType}, headers=${headers.keys.toList()}, extraFields=${extraFields.map((e) => '${e.key}=${e.value}').toList()}',
    );

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
      debugLog(
        '[FormFieldsSignaturePad._uploadImageDio] response == null (network error)',
      );
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadFailedTitle,
          message: uploadErrorMessage,
          dialogType: AppDialogType.network,
        );
      }
      return null;
    }
    // Treat 401 as queueable (auth expired) so callers can persist payloads.
    if (response.statusCode == 401) {
      debugLog(
        '[FormFieldsSignaturePad._uploadImageDio] upload failed: 401 -> queueing payload',
      );
      final queued = await _queueFailedUpload(
        image,
        payload,
        authExpired: true,
      );
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadFailedTitle,
          message: uploadErrorMessage,
          dialogType: AppDialogType.server,
        );
      }
      return queued;
    }
    try {
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;

        final uploadedLink = UploadResponseMapper.extractUploadedLink(
          data,
          keys: widget.uploadFileUrlKey,
        );
        final imageId = UploadResponseMapper.extractImageId(
          data,
          keys: widget.uploadImageIdKey,
        );
        final uploadedDescription = UploadResponseMapper.extractDescription(
          data,
          keys: widget.descriptionField ?? 'description',
        );
        final uploadedPath = UploadResponseMapper.extractFilePath(
          data,
          keys: 'filePath',
        );
        debugLog(
          '[FormFieldsSignaturePad._uploadImageDio] '
          'status=${response.statusCode}, uploadedLink=$uploadedLink, '
          'uploadedPath=$uploadedPath, imageId=$imageId',
        );

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
            final p = uploadedPath.startsWith('/')
                ? uploadedPath
                : '/$uploadedPath';
            finalLink = '${base.scheme}://${base.authority}$p';
          } catch (_) {
            // ignore and leave finalLink empty
          }
        }

        final resolvedPath =
            (uploadedPath != null && uploadedPath.trim().isNotEmpty)
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
        debugLog(
          '[FormFieldsSignaturePad._uploadImageDio] upload failed: status=${response.statusCode}, statusMessage=${response.statusMessage}, data=${response.data}',
        );
        // Server-side or transient failures can succeed later, so they are
        // queued the same way as the live camera. Permanent client errors
        // (400, 403, 404, 422, ...) are reported and not queued.
        MyImageResult? queued;
        if (UploadService.isRetryableStatus(response.statusCode)) {
          queued = await _queueFailedUpload(image, payload, authExpired: false);
        }
        if (widget.showUploadResultDialog) {
          await dialog.showError(
            title: uploadFailedTitle,
            message: '$uploadFailedMessage ${response.statusMessage ?? ''}',
            dialogType: AppDialogType.server,
          );
        }
        return queued;
      }
    } catch (e) {
      debugLog(
        '[FormFieldsSignaturePad._uploadImageDio] exception while processing response: $e',
      );
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
}
