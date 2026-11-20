part of '../form_fields_signature_pad.dart';

extension _FormFieldsSignaturePadExportX on _FormFieldsSignaturePadState {
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
    // The PNG is kept on purpose: the direct upload reads it, and an
    // offline-queued payload refers to its path.
    final signatureResult = await MyImageResult.fromFile(
      file,
      quality: widget.quality,
    );
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
      final updatedSignature = await _uploadImageDio(
        signatureResult,
        showSuccessDialog: false,
      );
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
      // A direct upload that returned nothing was refused and not queued, so the
      // signature is shown as failed rather than as a plain capture.
      final finalSignature =
          updatedSignature ??
          (widget.isDirectUpload
              ? signatureResult.copyWith(status: MyImageStatus.failed)
              : signatureResult);
      // Live capture is already uploaded by FormFieldsLiveCameraCapture.capture()
      // so _cameraController.images.first already has the server result.
      final finalLiveCapture =
          widget.showLiveCamera && _cameraController.images.isNotEmpty
          ? _cameraController.images.first
          : liveCapture;
      // Log final results for debugging (link/path/base64 length/status).
      debugLog(
        '[FormFieldsSignaturePad._exportSignature] finalSignature: link=${finalSignature.link}, path=${finalSignature.path}, base64Len=${finalSignature.base64.length}, status=${finalSignature.status}',
      );
      debugLog(
        '[FormFieldsSignaturePad._exportSignature] finalLiveCapture: link=${finalLiveCapture.link}, path=${finalLiveCapture.path}, base64Len=${finalLiveCapture.base64.length}, status=${finalLiveCapture.status}',
      );

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
        final nullable = SignaturePadExportNullableResult.fromExportResult(
          finalResult,
        );
        try {
          // Prefer the nullable combined callback when provided so callers
          // receive both sides in one object where successful sides are
          // represented as `null`.
          if (widget.onFailDirectUploadList != null) {
            widget.onFailDirectUploadList?.call(nullable);
          }
        } catch (e, st) {
          debugLog(
            'FormFieldsSignaturePad.onFailDirectUploadList threw: $e\n$st',
          );
        }

        // Legacy single-item callback removed; callers should use
        // `onFailDirectUploadList` or `onFailDirectUploadPayload`.

        // Queued payloads were already reported when they were queued, so they
        // are not reported again here.
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
        final liveWasCaptured =
            widget.showLiveCamera &&
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
}
