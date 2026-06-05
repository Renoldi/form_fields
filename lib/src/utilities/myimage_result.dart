import 'dart:convert';
import 'dart:io';

import 'enums.dart';

class MyImageResult {
  final String link;
  final String base64;
  final String path;
  final String imageId;
  final String description;
  final Map<String, dynamic> payload;
  final MyImageStatus status;

  MyImageResult(
      {this.link = "",
      this.base64 = "",
      this.path = "",
      this.imageId = "",
      this.description = "",
      this.payload = const <String, dynamic>{},
      this.status = MyImageStatus.idle});

  /// Convenience constructor for a network-only result (e.g. prefilled image).
  MyImageResult.network(String url)
      : link = url,
        base64 = "",
        path = "",
        imageId = "",
        description = "",
        payload = const <String, dynamic>{},
        status = MyImageStatus.idle;
  @override
  String toString() {
    return 'MyimageResult(path: $path, link: $link, base64: ${base64.substring(0, 20)}, imageId: $imageId, description: $description, status: $status, payload: ${payload.toString()})';
  }

  static Future<MyImageResult> fromFile(File file,
      {String? link, String? description}) async {
    final bytes = await file.readAsBytes();
    final base64Raw = base64Encode(bytes);
    final mime = getMimeType(file.path);
    final base64Str = 'data:$mime;base64,$base64Raw';
    return MyImageResult(
        link: link ?? "",
        base64: base64Str,
        path: file.path,
        description: description ?? "",
        payload: const <String, dynamic>{},
        status: MyImageStatus.idle);
  }

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'base64': base64,
      'path': path,
      'imageId': imageId,
      'description': description,
      'payload': payload,
      'status': status.toString().split('.').last,
    };
  }

  /// Returns the MIME type based on file extension.
  static String getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
