import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:json_annotation/json_annotation.dart';
import 'package:form_fields/form_fields.dart';

part 'myimage_result.g.dart';

@JsonSerializable()
class MyImageResult {
  final String link;
  final String base64;
  final String path;
  final String imageId;
  final String description;
  final Map<String, dynamic> payload;
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final MyImageStatus status;

  MyImageResult({
    this.link = "",
    this.base64 = "",
    this.path = "",
    this.imageId = "",
    this.description = "",
    Map<String, dynamic>? payload,
    this.status = MyImageStatus.idle,
  }) : payload = payload ?? const <String, dynamic>{};

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
    final b64Preview = (base64.length > 20)
        ? '${base64.substring(0, 20)}...'
        : base64;
    return 'MyimageResult(path: $path, link: $link, base64: $b64Preview, imageId: $imageId, description: $description, status: $status)';
  }

  /// Read file, compress in a background isolate, and return a model with a
  /// base64 data URI. Uses `compute` to avoid blocking the UI isolate.
  static Future<MyImageResult> fromFile(
    File file, {
    String? link,
    String? description,
    int? maxWidth,
    int? maxHeight,
    int quality = 80,
  }) async {
    final originalBytes = await file.readAsBytes();
    List<int> bytes = originalBytes;
    String mime = getMimeType(file.path);

    try {
      if (mime.startsWith('image/') && !mime.contains('svg')) {
        final Map<String, dynamic> result =
            await compute<Map<String, dynamic>, Map<String, dynamic>>(
              _compressImageIsolate,
              {
                'bytes': originalBytes,
                'path': file.path,
                'maxWidth': maxWidth,
                'maxHeight': maxHeight,
                'quality': quality,
              },
            );
        final rbytes = result['bytes'] as List<int>?;
        final rmime = result['mime'] as String?;
        if (rbytes != null) bytes = rbytes;
        if (rmime != null) mime = rmime;
      }
    } catch (_) {
      bytes = originalBytes;
    }

    final base64Raw = base64Encode(bytes);
    final base64Str = 'data:$mime;base64,$base64Raw';
    return MyImageResult(
      link: link ?? "",
      base64: base64Str,
      path: file.path,
      description: description ?? "",
      status: MyImageStatus.idle,
    );
  }

  factory MyImageResult.fromJson(Map<String, dynamic> json) =>
      _$MyImageResultFromJson(json);

  Map<String, dynamic> toJson() => _$MyImageResultToJson(this);

  /// Construct a [MyImageResult] from a server response shape.
  static MyImageResult fromServerResponse(
    dynamic json, {
    MyImageStatus defaultStatus = MyImageStatus.uploaded,
  }) {
    if (json == null) return MyImageResult();

    String link = '';
    String path = '';
    String imageId = '';
    String description = '';
    Map<String, dynamic> payload = {};

    if (json is Map<String, dynamic>) {
      payload = Map<String, dynamic>.from(json);
      link =
          UploadResponseMapper.extractUploadedLink(json, keys: 'fileUrl') ?? '';
      imageId =
          UploadResponseMapper.extractImageId(json, keys: 'imageId') ?? '';
      path = UploadResponseMapper.extractFilePath(json, keys: 'filePath') ?? '';
      description =
          UploadResponseMapper.extractDescription(json, keys: 'description') ??
          '';
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
      status: status,
    );
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

/// Background compression worker run inside `compute`.
Map<String, dynamic> _compressImageIsolate(Map<String, dynamic> args) {
  final List<int> originalBytes = List<int>.from(args['bytes'] as List);
  final String path = args['path'] as String;
  final int? maxWidth = args['maxWidth'] as int?;
  final int? maxHeight = args['maxHeight'] as int?;
  final int quality = args['quality'] as int? ?? 85;
  String mime = MyImageResult.getMimeType(path);

  try {
    if (mime.startsWith('image/') && !mime.contains('svg')) {
      final decoded = img.decodeImage(Uint8List.fromList(originalBytes));
      if (decoded != null) {
        img.Image processed = decoded;
        if (maxWidth != null || maxHeight != null) {
          final targetW =
              maxWidth ??
              ((decoded.width * (maxHeight! / decoded.height)).round());
          final targetH =
              maxHeight ??
              ((decoded.height * (maxWidth! / decoded.width)).round());
          if (targetW > 0 &&
              targetH > 0 &&
              (targetW != decoded.width || targetH != decoded.height)) {
            processed = img.copyResize(
              processed,
              width: targetW,
              height: targetH,
              interpolation: img.Interpolation.average,
            );
          }
        }

        final ext = path.split('.').last.toLowerCase();
        List<int> encoded;
        if (ext == 'png') {
          encoded = img.encodePng(processed);
          mime = 'image/png';
        } else {
          encoded = img.encodeJpg(processed, quality: quality);
          mime = 'image/jpeg';
        }
        return {'bytes': encoded, 'mime': mime};
      }
    }
  } catch (_) {}
  return {'bytes': originalBytes, 'mime': mime};
}

MyImageStatus _statusFromJson(String? value) {
  if (value == null) return MyImageStatus.idle;
  switch (value.toLowerCase()) {
    case 'idle':
      return MyImageStatus.idle;
    case 'uploading':
      return MyImageStatus.uploading;
    case 'queued':
      return MyImageStatus.queued;
    case 'failed':
      return MyImageStatus.failed;
    case 'uploaded':
      return MyImageStatus.uploaded;
    default:
      return MyImageStatus.idle;
  }
}

String _statusToJson(MyImageStatus status) => status.toString().split('.').last;
