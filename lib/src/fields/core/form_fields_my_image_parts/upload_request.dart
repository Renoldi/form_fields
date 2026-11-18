part of '../form_fields_my_image.dart';

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
    // Determine effective description (prefer explicit param, fallback to image.description)
    final imgDesc = (image.description).trim();
    final effDesc = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : (imgDesc.isNotEmpty ? imgDesc : null);
    // Siapkan formData.fields jika ada description
    final extraFields = <MapEntry<String, String>>[];
    if (effDesc != null && effDesc.isNotEmpty) {
      extraFields.add(
        MapEntry(widget.descriptionField ?? 'description', effDesc),
      );
    }

    // Prepare a payload so callers can enqueue and send it later when offline.
    final fileName = resolveUploadFileName(image);
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
      'index': index,
      // Correlation id used to reliably match persisted payloads back to
      // controller images when retries succeed.
      'uploadCorrelationId': uploadCorrelationId,
    };
    return (headers: headers, effDesc: effDesc, payload: payload);
  }
}
