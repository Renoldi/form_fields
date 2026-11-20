part of '../form_fields_my_image.dart';

extension _FormFieldsMyImageUploadX on _FormFieldsMyImageState {
  Future<void> _uploadImageDio(
    FormFieldsMyImageProvider provider,
    MyImageResult image,
    int? idx, {
    String? description,
  }) async {
    if (widget.uploadUrl == null) return;
    final images = provider.images;
    // The image may have been removed while it was being compressed, and then
    // another image can sit at the same index. Match on the object itself.
    var index =
        (idx != null && idx < images.length && identical(images[idx], image))
        ? idx
        : images.indexWhere((e) => identical(e, image));
    if (index < 0) return;
    // The upload is for this object. Its position in the list can change while
    // the request is in flight, for example when the user removes another
    // image. Every update therefore finds the position again from this object,
    // instead of trusting the index captured at the start.
    var live = images[index];
    int? locate() {
      if (!mounted) return null;
      final i = provider.images.indexWhere((e) => identical(e, live));
      return i < 0 ? null : i;
    }

    void replaceLive(int at, MyImageResult updated) {
      provider.updateImage(at, updated);
      live = updated;
    }

    // Keep overlay visible from the beginning, even when onProgress only
    // emits at completion on some devices/networks.
    provider.setUploadProgress(index, 0.02);
    final request = _buildMyImageUploadRequest(image, description, index);
    final headers = request.headers;
    final effDesc = request.effDesc;
    final payload = request.payload;
    final hasNet = await isNetworkAvailable();
    final afterNetCheck = locate();
    if (afterNetCheck == null) return; // removed or disposed meanwhile
    index = afterNetCheck;
    if (!hasNet) {
      // Keep overlay visible to indicate pending upload.
      provider.setUploadProgress(index, 0.0);
      // Attach payload to the image so UI/controller can access it later.
      final updatedImage = MyImageResult(
        link: live.link,
        base64: live.base64,
        path: live.path,
        imageId: live.imageId,
        description: (effDesc != null && effDesc.isNotEmpty)
            ? effDesc
            : live.description,
        payload: payload,
        status: MyImageStatus.queued,
      );
      replaceLive(index, updatedImage);
      _syncControllerImages(provider);
      // Notify callers specifically about a failed/queued direct upload so
      // they can persist the payloads for later retry. Wrap the callback in
      // try/catch to avoid user-provided handlers from throwing and
      // interrupting the upload flow (which previously could wipe state).
      await _reportQueuedPayloads(provider, source: 'offline');

      // Stop further processing when offline — avoid attempting the
      // network upload and potential race conditions that may overwrite
      // the queued image state.
      return;
    }

    // If we have network, mark the image as uploading before starting the request.
    if (hasNet) {
      final img = live;
      final uploadingImage = MyImageResult(
        link: img.link,
        base64: img.base64,
        path: img.path,
        imageId: img.imageId,
        description: img.description,
        payload: img.payload,
        status: MyImageStatus.uploading,
      );
      replaceLive(index, uploadingImage);
      _syncControllerImages(provider);
    }

    Response? response;
    Map<String, dynamic>? built;
    try {
      // Build an upload-ready payload map (may write temp file for base64)
      built = await UploadHelper.buildUploadPayloadFromMap(payload);
      final afterBuild = locate();
      if (afterBuild == null) return;
      index = afterBuild;
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
        onUploadQueued: (sanitized, authExpired) async {
          try {
            final sanitizedMap = sanitized.toJson();
            final at = locate();
            if (at == null) return;
            index = at;
            final updatedImage = MyImageResult(
              link: live.link,
              base64: live.base64,
              path: live.path,
              imageId: live.imageId,
              description: (effDesc != null && effDesc.isNotEmpty)
                  ? effDesc
                  : live.description,
              payload: sanitizedMap,
              status: MyImageStatus.queued,
            );
            replaceLive(index, updatedImage);
            _syncControllerImages(provider);

            await _reportQueuedPayloads(provider, source: 'queued');

            if (authExpired) {
              try {
                widget.onUploadAuthExpired?.call();
              } catch (_) {}
            }
          } catch (e, st) {
            debugLog('onUploadQueued handler error: $e\n$st');
          }
        },
        onProgress: (progress) {
          final at = locate();
          if (at != null) provider.setUploadProgress(at, progress);
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
    // The request may have finished after the user removed this image. There
    // is nothing left to update in that case.
    final afterUpload = locate();
    if (afterUpload == null) return;
    index = afterUpload;
    final messages = ImageUploadMessages.resolve(
      FormFieldsLocalizations.of(context),
      successTitle: widget.uploadSuccessTitle,
      failedTitle: widget.uploadFailedTitle,
      errorTitle: widget.uploadErrorTitle,
      successMessage: widget.uploadSuccessMessage,
      failedMessage: widget.uploadFailedMessage,
      errorMessage: widget.uploadErrorMessage,
    );
    final dialog = AppDialogService(context);
    if (response == null) {
      provider.resetUploadProgress(index);
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: messages.failedTitle,
          message: messages.errorMessage,
          dialogType: AppDialogType.network,
        );
      }
      return;
    }
    try {
      if (UploadResponseMapper.isSuccessfulStatus(response.statusCode)) {
        final data = response.data;
        final extracted = extractUploadResponse(
          data,
          fileUrlKey: widget.uploadFileUrlKey,
          imageIdKey: widget.uploadImageIdKey,
          descriptionKey: widget.descriptionField ?? 'description',
        );
        final updatedImage = MyImageResult(
          link: resolveUploadedLink(
            uploadedLink: extracted.link,
            fallbackLink: live.link,
            uploadedPath: extracted.path,
            uploadUrl: widget.uploadUrl,
          ),
          base64: live.base64,
          // Keep the local picked file path unless the server returned one.
          path: resolveUploadedPath(extracted.path, live.path),
          imageId: extracted.imageId ?? live.imageId,
          description: extracted.description ?? description ?? live.description,
          payload: data,
          status: MyImageStatus.uploaded,
        );
        replaceLive(index, updatedImage);
        // Keep a short completion transition so users can perceive progress.
        provider.setUploadProgress(index, 0.98);
        await Future<void>.delayed(uploadCompletionTransitionDelay);
        final afterFirstDelay = locate();
        if (afterFirstDelay != null) {
          provider.setUploadProgress(afterFirstDelay, 1.0);
        }
        await Future<void>.delayed(uploadCompletionTransitionDelay);
        final afterSecondDelay = locate();
        if (afterSecondDelay == null) return;
        index = afterSecondDelay;
        _syncControllerImages(provider);
        widget.onImagesChanged?.call(List<MyImageResult>.from(provider.images));
        if (widget.maxImages == 1 && index == 0) {
          final shouldEmitSingleImage =
              !widget.isDirectUpload ||
              updatedImage.link.isNotEmpty ||
              updatedImage.imageId.isNotEmpty;
          if (shouldEmitSingleImage) {
            widget.onImageChanged?.call(provider.images[index]);
          }
        }
        if (widget.showUploadResultDialog) {
          await dialog.showSuccess(
            title: messages.successTitle,
            message: messages.successMessage,
          );
        }
      } else {
        // mark as failed
        final failedImage = MyImageResult(
          link: live.link,
          base64: live.base64,
          path: live.path,
          imageId: live.imageId,
          description: live.description,
          payload: live.payload,
          status: MyImageStatus.failed,
        );
        replaceLive(index, failedImage);
        provider.resetUploadProgress(index);
        if (widget.showUploadResultDialog) {
          await dialog.showError(
            title: messages.failedTitle,
            message:
                '${messages.failedMessage} ${response.statusMessage ?? ''}',
            dialogType: AppDialogType.server,
          );
        }
      }
    } catch (e) {
      // mark as failed on exception
      final at = locate();
      if (at != null) {
        final failedImage = MyImageResult(
          link: live.link,
          base64: live.base64,
          path: live.path,
          imageId: live.imageId,
          description: live.description,
          payload: live.payload,
          status: MyImageStatus.failed,
        );
        replaceLive(at, failedImage);
        provider.resetUploadProgress(at);
      }
      if (widget.showUploadResultDialog) {
        await dialog.showError(
          title: messages.errorTitle,
          message: '$messages.errorMessage $e',
          dialogType: AppDialogType.server,
        );
      }
    }
  }
}

extension _FormFieldsMyImageUploadRequestX on _FormFieldsMyImageState {
  /// Builds the headers, description and resumable payload for one image upload.
  /// Shared by the online request and the offline queue. [index] is the image
  /// position at the time of the call.
  ({Map<String, String> headers, String? effDesc, Map<String, dynamic> payload})
  _buildMyImageUploadRequest(
    MyImageResult image,
    String? description,
    int index,
  ) {
    final headers = buildUploadAuthHeaders(widget.uploadToken);
    final effDesc = resolveUploadDescription(image, explicit: description);
    final payload = buildImageUploadPayload(
      uploadUrl: widget.uploadUrl,
      headers: headers,
      image: image,
      fileName: resolveUploadFileName(image),
      description: effDesc,
      formFields: descriptionFormFields(
        effDesc,
        widget.descriptionField ?? 'description',
      ),
      fileUrlKey: widget.uploadFileUrlKey,
      imageIdKey: widget.uploadImageIdKey,
      index: index,
    );
    return (headers: headers, effDesc: effDesc, payload: payload);
  }

  /// Reports every uploadable image that is queued (or about to be) through
  /// [FormFieldsMyImage.onFailDirectUploadPayload], so callers can persist them.
  /// Falls back to all uploadable images when fewer are marked queued.
  Future<void> _reportQueuedPayloads(
    FormFieldsMyImageProvider provider, {
    required String source,
  }) async {
    try {
      var queued = provider.images
          .where((i) => i.status == MyImageStatus.queued)
          .toList();
      final uploadable = provider.images.where((i) {
        final hasFileInPayload =
            (i.payload.isNotEmpty &&
            (i.payload['file'] is Map || i.payload['filePath'] != null));
        return i.status != MyImageStatus.uploaded &&
            (i.path.trim().isNotEmpty ||
                i.base64.isNotEmpty ||
                hasFileInPayload);
      }).toList();
      if (queued.length < uploadable.length && uploadable.isNotEmpty) {
        queued = uploadable;
      }
      final payloads = await UploadHelper.buildDirectUploadPayloadsFromImages(
        queued,
        defaultUrl: widget.uploadUrl,
        fileFieldName: widget.uploadFileFieldName,
        includeReqType: widget.uploadIncludeReqType,
      );
      if (payloads.isNotEmpty) {
        if (kDebugMode) {
          debugLog(
            'FormFieldsMyImage: onFailDirectUploadPayload -> '
            '${payloads.length} payload(s) ($source)',
          );
        }
        widget.onFailDirectUploadPayload?.call(payloads);
      }
    } catch (e, st) {
      debugLog('FormFieldsMyImage.onFailDirectUploadPayload threw: $e\n$st');
    }
  }
}
