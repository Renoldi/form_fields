part of '../form_fields_live_camera_capture.dart';

extension _FormFieldsLiveCameraCaptureUploadX
    on FormFieldsLiveCameraCaptureState {
  /// Uploads [image] and returns the updated [MyImageResult] with server
  /// link/imageId. Returns `null` on failure.
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
    final uploadCorrelationId = DateTime.now().microsecondsSinceEpoch
        .toString();
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
      'uploadCorrelationId': uploadCorrelationId,
    };

    final hasNet = await isNetworkAvailable();
    if (!hasNet) {
      if (mounted && widget.showUploadLoading) {
        _provider.setUploadProgress(0.0);
      }
      // Return an updated MyImageResult containing payload so callers receive
      // the image (with payload) instead of a null failure.
      final updatedImage = MyImageResult(
        link: image.link,
        base64: image.base64,
        path: image.path,
        imageId: image.imageId,
        description: image.description,
        payload: payload,
        status: MyImageStatus.queued,
      );
      // Notify caller so they can persist queued payloads for later retry.
      // Legacy single-item callback removed; callers receive payloads via
      // `onFailDirectUploadPayload` below.
      // Also provide an upload-friendly payload map for callers that prefer
      // to persist a simplified shape consumable by `DioUtil.uploadFile`.
      try {
        final updated = updatedImage;
        final direct = await UploadHelper.buildDirectUploadPayloadFromImage(
          updated,
          defaultUrl: widget.uploadUrl,
          fileFieldName: widget.uploadFileFieldName,
          includeReqType: widget.uploadIncludeReqType,
        );
        if (direct != null) {
          if (kDebugMode) {
            try {
              debugLog(
                'FormFieldsLiveCameraCapture: onFailDirectUploadPayload -> 1 payload',
              );
              debugLog(
                'FormFieldsLiveCameraCapture: payload[0] correlation=${direct.uploadCorrelationId} file=${direct.fileName} path=${direct.filePath}',
              );
            } catch (_) {}
          }
          widget.onFailDirectUploadPayload?.call([direct]);
        }
      } catch (e, st) {
        debugLog(
          'FormFieldsLiveCameraCapture.onFailDirectUploadPayload threw: $e\n$st',
        );
      }
      // combined export callback removed; callers receive single-item
      // `onFailDirectUpload` for persisting queued payloads.
      return updatedImage;
    }

    // Mark controller preview as uploading so UI can reflect progress.
    if (widget.cameraController != null) {
      final img = MyImageResult(
        link: image.link,
        base64: image.base64,
        path: image.path,
        imageId: image.imageId,
        description: image.description,
        payload: image.payload,
        status: MyImageStatus.uploading,
      );
      widget.cameraController!.images = [img];
      _syncCapturedFromController();
    }

    debugLog(
      '[FormFieldsLiveCameraCapture._uploadImageDio] START upload url=${widget.uploadUrl}, file=${image.path}, fileField=${widget.uploadFileFieldName}, includeReqType=${widget.uploadIncludeReqType}, headers=${headers.keys.toList()}, extraFields=${extraFields.map((e) => '${e.key}=${e.value}').toList()}',
    );

    final response = await DioUtil.uploadFile(
      url: widget.uploadUrl!,
      filePath: image.path,
      filename: File(image.path).path.split('/').last,
      headers: headers,
      onProgress: (progress) {
        if (mounted && widget.showUploadLoading) {
          _provider.setUploadProgress(progress);
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
        '[FormFieldsLiveCameraCapture._uploadImageDio] response == null (network error)',
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
    // Handle auth expiry (401) by building a queueable payload and
    // notifying the caller so they can persist/retry later.
    if (response.statusCode == 401) {
      debugLog(
        '[FormFieldsLiveCameraCapture._uploadImageDio] upload failed: 401 -> queueing payload',
      );
      MyImageResult? queuedImage;
      try {
        queuedImage = MyImageResult(
          link: image.link,
          base64: image.base64,
          path: image.path,
          imageId: image.imageId,
          description: image.description,
          payload: payload,
          status: MyImageStatus.queued,
        );
        final direct = await UploadHelper.buildDirectUploadPayloadFromImage(
          queuedImage,
          defaultUrl: widget.uploadUrl,
          fileFieldName: widget.uploadFileFieldName,
          includeReqType: widget.uploadIncludeReqType,
        );
        if (direct != null) {
          if (kDebugMode) {
            try {
              debugLog(
                'FormFieldsLiveCameraCapture: auth queue -> payload.correlation=${direct.uploadCorrelationId} file=${direct.fileName} path=${direct.filePath}',
              );
            } catch (_) {}
          }
          try {
            widget.onUploadQueued?.call(direct, true);
          } catch (e, st) {
            debugLog(
              'FormFieldsLiveCameraCapture.onUploadQueued threw: $e\n$st',
            );
          }
          try {
            widget.onFailDirectUploadPayload?.call([direct]);
          } catch (e, st) {
            debugLog(
              'FormFieldsLiveCameraCapture.onFailDirectUploadPayload threw: $e\n$st',
            );
          }
          return queuedImage;
        }
      } catch (e, st) {
        debugLog(
          'FormFieldsLiveCameraCapture: error while building queued payload: $e\n$st',
        );
      }
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: uploadFailedTitle,
          message: uploadErrorMessage,
          dialogType: AppDialogType.server,
        );
      }
      return queuedImage;
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
          '[FormFieldsLiveCameraCapture._uploadImageDio] '
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
        // an absolute URL from uploadedPath when possible.
        String? finalLink = (uploadedLink ?? image.link).trim();
        if ((finalLink.isEmpty) &&
            (uploadedPath != null && uploadedPath.trim().isNotEmpty)) {
          try {
            final base = Uri.parse(widget.uploadUrl!);
            final p = uploadedPath.startsWith('/')
                ? uploadedPath
                : '/$uploadedPath';
            finalLink = '${base.scheme}://${base.authority}$p';
          } catch (_) {}
        }

        final resolvedPath =
            (uploadedPath != null && uploadedPath.trim().isNotEmpty)
            ? uploadedPath
            : image.path;

        final updatedImage = MyImageResult(
          link: finalLink ?? image.link,
          base64: finalBase64,
          // Preserve the local captured file path unless the server
          // returned an absolute filesystem path. Avoid overwriting with
          // server-relative paths which are not accessible locally.
          path: resolvedPath,
          imageId: imageId ?? image.imageId,
          description: uploadedDescription ?? image.description,
          payload: payload,
          status: MyImageStatus.uploaded,
        );

        return updatedImage;
      } else {
        // For server/client errors treat similarly to 401: build a
        // queueable payload and notify caller so they can persist/retry.
        final sc = response.statusCode ?? 0;
        debugLog(
          '[FormFieldsLiveCameraCapture._uploadImageDio] upload failed: status=$sc, statusMessage=${response.statusMessage}, data=${response.data}',
        );
        // Only failures that can succeed later are queued. A permanent client
        // error (400, 403, 404, 422, ...) would be retried forever, so it is
        // reported and not queued.
        if (UploadService.isRetryableStatus(response.statusCode)) {
          try {
            final queuedImage = MyImageResult(
              link: image.link,
              base64: image.base64,
              path: image.path,
              imageId: image.imageId,
              description: image.description,
              payload: payload,
              status: MyImageStatus.queued,
            );
            final direct = await UploadHelper.buildDirectUploadPayloadFromImage(
              queuedImage,
              defaultUrl: widget.uploadUrl,
              fileFieldName: widget.uploadFileFieldName,
              includeReqType: widget.uploadIncludeReqType,
            );
            if (direct != null) {
              if (kDebugMode) {
                try {
                  debugLog(
                    'FormFieldsLiveCameraCapture: server queue -> payload.correlation=${direct.uploadCorrelationId} file=${direct.fileName} path=${direct.filePath}',
                  );
                } catch (_) {}
              }
              try {
                widget.onUploadQueued?.call(direct, false);
              } catch (e, st) {
                debugLog(
                  'FormFieldsLiveCameraCapture.onUploadQueued threw: $e\n$st',
                );
              }
              try {
                widget.onFailDirectUploadPayload?.call([direct]);
              } catch (e, st) {
                debugLog(
                  'FormFieldsLiveCameraCapture.onFailDirectUploadPayload threw: $e\n$st',
                );
              }
            }
          } catch (e, st) {
            debugLog(
              'FormFieldsLiveCameraCapture: error while building queued payload: $e\n$st',
            );
          }
        }
        if (widget.showUploadResultDialog) {
          await dialog.showError(
            title: uploadFailedTitle,
            message: '$uploadFailedMessage ${response.statusMessage ?? ''}',
            dialogType: AppDialogType.server,
          );
        }
      }
    } catch (e) {
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
