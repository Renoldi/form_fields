part of '../form_fields_live_camera_capture.dart';

extension _FormFieldsLiveCameraCaptureUploadX
    on FormFieldsLiveCameraCaptureState {
  /// Uploads [image] directly and returns the updated [MyImageResult] with the
  /// server link and image id, or `null` on failure. The shared flow is in
  /// [DirectImageUploader].
  Future<MyImageResult?> _uploadImageDio(
    MyImageResult image, {
    bool showSuccessDialog = true,
  }) {
    final camera = widget.cameraController;
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
        logTag: 'FormFieldsLiveCameraCapture._uploadImageDio',
        successTitle: widget.uploadSuccessTitle,
        failedTitle: widget.uploadFailedTitle,
        errorTitle: widget.uploadErrorTitle,
        successMessage: widget.uploadSuccessMessage,
        failedMessage: widget.uploadFailedMessage,
        errorMessage: widget.uploadErrorMessage,
        onUploadQueued: widget.onUploadQueued,
        onFailDirectUploadPayload: widget.onFailDirectUploadPayload,
      ),
      onProgress: (progress) => _provider.setUploadProgress(progress),
      // Show the uploading copy in the controller so the preview reflects it.
      onUploading: camera == null
          ? null
          : (uploading) {
              camera.images = [uploading];
              _syncCapturedFromController();
            },
    ).upload(image, showSuccessDialog: showSuccessDialog);
  }
}
