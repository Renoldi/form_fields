import 'dart:io';

import 'package:form_fields/src/models/myimage_result.dart';

/// Pure helpers shared by the image-capable fields when preparing an upload
/// request. They contain no widget or state logic so they can be unit-tested
/// directly.

/// Builds the request headers for an upload.
///
/// When [token] is non-empty it is sent as the `Authorization` header.
/// Returns an empty map otherwise.
Map<String, String> buildUploadAuthHeaders(String? token) {
  final headers = <String, String>{};
  if (token != null && token.isNotEmpty) {
    headers[HttpHeaders.authorizationHeader] = token;
  }
  return headers;
}

/// Resolves the file name to send for [image].
///
/// Prefers the last segment of the local [MyImageResult.path]. Falls back to
/// the last segment of [MyImageResult.link], and finally to `'image'`.
String resolveUploadFileName(MyImageResult image) {
  if (image.path.trim().isNotEmpty) {
    return image.path.split(Platform.pathSeparator).last;
  }
  if (image.link.isNotEmpty) {
    return image.link.split('/').last;
  }
  return 'image';
}
