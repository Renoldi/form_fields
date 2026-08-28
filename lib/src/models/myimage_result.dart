import 'dart:convert';
import 'dart:io';
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

  static Future<MyImageResult> fromFile(
    File file, {
    String? link,
    String? description,
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
  }) async {
    final originalBytes = await file.readAsBytes();
    List<int> bytes = originalBytes;
    String mime = getMimeType(file.path);

    try {
      if (mime.startsWith('image/') && !mime.contains('svg')) {
        final decoded = img.decodeImage(originalBytes);
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

          final ext = file.path.split('.').last.toLowerCase();
          List<int> encoded;
          if (ext == 'png') {
            encoded = img.encodePng(processed);
            mime = 'image/png';
          } else if (ext == 'webp') {
            // Some versions of the `image` package have varying WebP APIs.
            // To keep behavior stable we re-encode WebP as JPEG with quality.
            encoded = img.encodeJpg(processed, quality: quality);
            mime = 'image/jpeg';
          } else {
            encoded = img.encodeJpg(processed, quality: quality);
            mime = 'image/jpeg';
          }

          bytes = encoded;
        }
      }
    } catch (_) {
      // If compression fails, fall back to original bytes.
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
  /// Accepts a Map or a raw String (URL) and attempts to normalize common
  /// keys into the model. If the payload contains a `status` string it will
  /// be mapped to [MyImageStatus].
  /// Legacy helper to build a `MyImageResult` from a server response or
  /// arbitrary dynamic payload. This preserves existing normalization logic
  /// while still allowing `json_serializable`-based (de)serialization via
  /// `fromJson`/`toJson`.
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
      // payload: payload,
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
