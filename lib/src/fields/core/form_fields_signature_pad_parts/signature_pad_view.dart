part of '../form_fields_signature_pad.dart';

extension _FormFieldsSignaturePadViewX on _FormFieldsSignaturePadState {
  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildPreviewImage(
    MyImageResult result, {
    BoxFit fit = BoxFit.contain,
  }) {
    Widget imageWidget;
    final tokenHeader =
        (widget.uploadToken != null && widget.uploadToken!.isNotEmpty)
        ? <String, String>{HttpHeaders.authorizationHeader: widget.uploadToken!}
        : null;

    // Prefer local preview (file -> base64) to avoid forcing a network GET
    // immediately after upload. Only fall back to NetworkImage when no
    // local content is available.
    final hasLocalPath =
        result.path.trim().isNotEmpty && File(result.path).existsSync();
    final hasBase64 = result.base64.trim().isNotEmpty;

    if (hasLocalPath) {
      imageWidget = Image.file(File(result.path), fit: fit);
    } else if (hasBase64) {
      final bytes = decodeBase64Image(result.base64);
      if (bytes != null) {
        imageWidget = Image.memory(bytes, fit: fit);
      } else {
        imageWidget = Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        );
      }
    } else if (result.link.trim().isNotEmpty) {
      imageWidget = Image(
        image: NetworkImage(
          result.link,
          headers: isSameOrigin(result.link, widget.uploadUrl)
              ? tokenHeader
              : null,
        ),
        fit: fit,
        errorBuilder: (_, error, stackTrace) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    } else {
      imageWidget = Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              localizations.get('noLiveCapture'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildSignaturePad(
    FormFieldsLocalizations localizations,
    FormFieldsSignaturePadProvider provider,
  ) {
    final loadingTheme =
        Theme.of(context).extension<AppLoadingThemeData>() ??
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
                      backgroundColor:
                          widget.backgroundColor ??
                          Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: progressColor.withValues(alpha: .20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: .26),
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
                  onPressed: provider.isUploading
                      ? null
                      : _clearSignatureSession,
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
    // When the live camera is embedded, buffer its queued payloads so the
    // signature pad can later emit a single combined list. If the caller
    // provided an `onFailDirectUploadPayload` for the whole pad, suppress
    // immediate passthrough and merge later. Otherwise, forward directly.
    void failPayloadCb(List<DirectUploadPayload> list) {
      try {
        if (widget.onFailDirectUploadPayload != null) {
          // Merge into buffer, avoiding duplicates by correlation id.
          for (final p in list) {
            final exists = _embeddedQueuedPayloads.any(
              (e) => e.uploadCorrelationId == p.uploadCorrelationId,
            );
            if (!exists) _embeddedQueuedPayloads.add(p);
          }
        } else {
          widget.onFailDirectUploadPayload?.call(list);
        }
      } catch (_) {}
    }

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

    // Wrap the default camera section in a card with matching background
    // and corner radius so the live camera preview visually matches the
    // signature card (white card + rounded corners).
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: _DefaultCameraSection(child: preview),
    );
  }
}
