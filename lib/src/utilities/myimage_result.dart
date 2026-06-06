import 'dart:convert';
import 'dart:io';

import 'enums.dart';
import 'package:form_fields/src/utilities/upload_response_mapper.dart';

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
    final b64Preview =
        (base64.length > 20) ? '${base64.substring(0, 20)}...' : base64;
    return 'MyimageResult(path: $path, link: $link, base64: $b64Preview, imageId: $imageId, description: $description, status: $status, payload: ${payload.toString()})';
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

  /// Construct a [MyImageResult] from a server response shape.
  /// Accepts a Map or a raw String (URL) and attempts to normalize common
  /// keys into the model. If the payload contains a `status` string it will
  /// be mapped to [MyImageStatus].
  static MyImageResult fromJson(dynamic json,
      {MyImageStatus defaultStatus = MyImageStatus.uploaded}) {
    if (json == null) return MyImageResult();

    String link = '';
    String path = '';
    String imageId = '';
    String description = '';
    Map<String, dynamic> payload = {};

    if (json is Map<String, dynamic>) {
      payload = Map<String, dynamic>.from(json);
      link = UploadResponseMapper.extractUploadedLink(json, 'fileUrl') ?? '';
      imageId = UploadResponseMapper.extractImageId(json, 'imageId') ?? '';
      path = UploadResponseMapper.extractFilePath(json) ?? '';
      description =
          UploadResponseMapper.extractDescription(json, 'description') ?? '';
    } else if (json is String) {
      link = json;
      payload = {'raw': json};
    } else {
      link = json.toString();
      payload = {'raw': json};
    }

    var status = defaultStatus;
    final st = payload['status']?.toString();
    if (st != null && st.isNotEmpty) {
      switch (st.toLowerCase()) {
        case 'idle':
          status = MyImageStatus.idle;
          break;
        case 'uploading':
          status = MyImageStatus.uploading;
          break;
        case 'queued':
          status = MyImageStatus.queued;
          break;
        case 'failed':
          status = MyImageStatus.failed;
          break;
        case 'uploaded':
          status = MyImageStatus.uploaded;
          break;
      }
    }

    return MyImageResult(
        link: link,
        base64: '',
        path: path,
        imageId: imageId,
        description: description,
        payload: payload,
        status: status);
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
