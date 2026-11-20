part of '../form_fields_signature_pad.dart';

extension _FormFieldsSignaturePadUploadX on _FormFieldsSignaturePadState {
  /// Uploads [image] directly and returns the updated [MyImageResult] with the
  /// server link and image id. Returns a queued image when the upload was
  /// deferred, or `null` when it was refused and not queued. The shared flow is
  /// in [DirectImageUploader].
  Future<MyImageResult?> _uploadImageDio(
    MyImageResult image, {
    bool showSuccessDialog = true,
  }) {
    return DirectImageUploader(
      context: context,
      isMounted: () => mounted,
      settings: DirectUploadSettings(
        uploadUrl: widget.uploadUrl,
        uploadToken: widget.uploadToken,
        fileFieldName: widget.uploadFileFieldName,
        includeReqType: widget.uploadIncludeReqType,
        fileUrlKey: widget.uploadFileUrlKey,
        imageIdKey: widget.uploadImageIdKey,
        descriptionFormField: 'description',
        descriptionResponseKey: widget.descriptionField ?? 'description',
        showLoading: widget.showUploadLoading,
        showResultDialog: widget.showUploadResultDialog,
        logTag: 'FormFieldsSignaturePad._uploadImageDio',
        successTitle: widget.uploadSuccessTitle,
        failedTitle: widget.uploadFailedTitle,
        errorTitle: widget.uploadErrorTitle,
        successMessage: widget.uploadSuccessMessage,
        failedMessage: widget.uploadFailedMessage,
        errorMessage: widget.uploadErrorMessage,
        onUploadQueued: widget.onUploadQueued,
        onFailDirectUploadPayload: widget.onFailDirectUploadPayload,
      ),
      onProgress: (progress) => _padProvider.setUploadProgress(progress),
    ).upload(image, showSuccessDialog: showSuccessDialog);
  }
}
