import 'dart:io';
import 'dart:convert';

import 'package:form_fields/form_fields.dart';

/// Helper utilities for converting persisted/queued payloads into
/// upload-ready maps and performing the upload via `DioUtil.uploadFile`.
class UploadHelper {
  /// Build an upload-ready payload from a persisted payload map.
  /// Returns `null` when no usable file information is available.
  ///
  /// Output map keys:
  /// - `url` (String)
  /// - `filePath` (String)
  /// - `fileName` (String)
  /// - `headers` (`Map<String, String>`)
  /// - `fields` (`Map<String, String>`)
  /// - `fileFieldName` (String)
  /// - `includeReqType` (bool)
  /// - `tempFileCreated` (bool) — true when a temp file was written from base64
  static Future<Map<String, dynamic>?> buildUploadPayloadFromMap(
      Map<String, dynamic> persisted) async {
    if (persisted.isEmpty) return null;

    final url = (persisted['url'] ?? '').toString();
    if (url.isEmpty) return null;

    final headersMap = <String, String>{};
    if (persisted['headers'] is Map) {
      (persisted['headers'] as Map).forEach((k, v) {
        headersMap[k.toString()] = v.toString();
      });
    }

    final fieldsMap = <String, String>{};
    if (persisted['fields'] is Map) {
      (persisted['fields'] as Map).forEach((k, v) {
        fieldsMap[k.toString()] = v.toString();
      });
    }

    // Support both shapes:
    // - Nested: persisted['file'] is a Map with keys {path, base64, fileName}
    // - Flat: persisted has top-level keys 'filePath', 'base64', 'fileName'
    final Map<String, dynamic> fileMap;
    if (persisted['file'] is Map) {
      fileMap = Map<String, dynamic>.from(persisted['file'] as Map);
    } else {
      fileMap = <String, dynamic>{};
      try {
        if (persisted['filePath'] is String &&
            (persisted['filePath'] as String).trim().isNotEmpty) {
          fileMap['path'] = persisted['filePath'];
        }
        if (persisted['fileName'] is String &&
            (persisted['fileName'] as String).trim().isNotEmpty) {
          fileMap['fileName'] = persisted['fileName'];
        }
        if (persisted['base64'] is String &&
            (persisted['base64'] as String).trim().isNotEmpty) {
          fileMap['base64'] = persisted['base64'];
        }
        // Also accept common alternative keys
        if (fileMap['path'] == null && persisted['path'] is String) {
          fileMap['path'] = persisted['path'];
        }
        if (fileMap['fileName'] == null && persisted['filename'] is String) {
          fileMap['fileName'] = persisted['filename'];
        }
        if (fileMap['base64'] == null && persisted['data'] is String) {
          fileMap['base64'] = persisted['data'];
        }
      } catch (_) {}
    }

    String filePath = '';
    String? fileName =
        fileMap['fileName'] is String ? fileMap['fileName'] as String : null;

    if (fileMap['path'] is String &&
        (fileMap['path'] as String).trim().isNotEmpty) {
      filePath = fileMap['path'] as String;
      try {
        if (!File(filePath).existsSync()) {
          // If the declared path doesn't exist, clear it so we try base64 next.
          filePath = '';
        }
      } catch (_) {
        filePath = '';
      }
    }

    var tempFileCreated = false;
    if (filePath.isEmpty) {
      final b64 =
          fileMap['base64'] is String ? fileMap['base64'] as String : null;
      if (b64 != null && b64.trim().isNotEmpty) {
        try {
          var rawB64 = b64;
          if (rawB64.startsWith('data:')) {
            final comma = rawB64.indexOf(',');
            if (comma >= 0) rawB64 = rawB64.substring(comma + 1);
          }
          final bytes = base64Decode(rawB64);
          final resolvedFileName = fileName ?? 'file';
          final tmp = File(
              '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_$resolvedFileName');
          await tmp.writeAsBytes(bytes);
          filePath = tmp.path;
          tempFileCreated = true;
        } catch (_) {
          return null;
        }
      }
    }

    final resolvedFileName = fileName ??
        (filePath.isNotEmpty
            ? filePath.split(Platform.pathSeparator).last
            : 'file');

    return {
      'url': url,
      'filePath': filePath,
      'fileName': resolvedFileName,
      'headers': headersMap,
      'fields': fieldsMap,
      'fileFieldName': persisted['fileFieldName'] ?? 'file',
      'includeReqType': persisted['includeReqType'] ?? false,
      'tempFileCreated': tempFileCreated,
    };
  }

  /// Convenience wrapper to build payload from a `MyImageResult` instance.
  static Future<Map<String, dynamic>?> buildUploadPayloadFromImage(
      MyImageResult image) async {
    if (image.payload.isNotEmpty) {
      return buildUploadPayloadFromMap(
          Map<String, dynamic>.from(image.payload));
    }

    // If there's no persisted payload map attached to the image, attempt to
    // construct a minimal persisted shape from the image fields so callers
    // receive a usable payload (supports images with `path` or `base64`).
    final m = <String, dynamic>{};
    // Do not set url here — callers should provide `defaultUrl` when
    // converting to a typed payload via `buildDirectUploadPayloadFromImage`.
    final file = <String, dynamic>{};
    try {
      if (image.path.trim().isNotEmpty) file['path'] = image.path;
    } catch (_) {}
    try {
      if (image.base64.trim().isNotEmpty) file['base64'] = image.base64;
    } catch (_) {}
    if (file.isNotEmpty) {
      file['fileName'] = file['fileName'] ??
          (file['path'] is String
              ? (file['path'] as String).split(Platform.pathSeparator).last
              : 'image');
      m['file'] = file;
    }
    if (m.isEmpty) return null;
    return buildUploadPayloadFromMap(m);
  }

  /// Build a typed `DirectUploadPayload` from a `MyImageResult`.
  /// Returns `null` when no usable file information is available.
  static Future<DirectUploadPayload?> buildDirectUploadPayloadFromImage(
      MyImageResult image,
      {String? defaultUrl,
      String fileFieldName = 'file',
      bool includeReqType = false}) async {
    // Support images that may not have a persisted `payload` map by
    // constructing a minimal persisted map from the image fields.
    final Map<String, dynamic> persisted = image.payload.isNotEmpty
        ? Map<String, dynamic>.from(image.payload)
        : <String, dynamic>{};
    if ((persisted['url'] == null ||
            persisted['url'].toString().trim().isEmpty) &&
        defaultUrl != null) {
      persisted['url'] = defaultUrl;
    }

    // If no nested file shape, synthesize it from image.path/base64.
    if (persisted['file'] == null) {
      final fm = <String, dynamic>{};
      try {
        if (image.path.trim().isNotEmpty) fm['path'] = image.path;
      } catch (_) {}
      try {
        if (image.base64.trim().isNotEmpty) fm['base64'] = image.base64;
      } catch (_) {}
      if (fm.isNotEmpty) {
        fm['fileName'] = fm['fileName'] ??
            (fm['path'] is String
                ? (fm['path'] as String).split(Platform.pathSeparator).last
                : 'image');
        persisted['file'] = fm;
      }
    }

    final built = await buildUploadPayloadFromMap(persisted);
    if (built == null) return null;

    String? base64Val;
    try {
      final fp = persisted['file'];
      if (fp is Map &&
          fp['base64'] is String &&
          (fp['base64'] as String).trim().isNotEmpty) {
        base64Val = fp['base64'] as String;
      } else if (image.base64.isNotEmpty) {
        base64Val = image.base64;
      }
    } catch (_) {}

    final headers = (built['headers'] is Map)
        ? Map<String, String>.from(built['headers'] as Map)
        : <String, String>{};
    final fields = (built['fields'] is Map)
        ? Map<String, String>.from(built['fields'] as Map)
        : <String, String>{};

    return DirectUploadPayload(
      url: built['url'] as String,
      filePath: built['filePath'] as String,
      fileName: built['fileName'] as String,
      base64: base64Val,
      headers: headers,
      fields: fields,
      fileFieldName: built['fileFieldName'] as String? ?? fileFieldName,
      includeReqType: built['includeReqType'] == true || includeReqType,
      uploadCorrelationId: image.payload['uploadCorrelationId']?.toString(),
    );
  }

  /// Build typed `DirectUploadPayload` objects for a list of images.
  static Future<List<DirectUploadPayload>> buildDirectUploadPayloadsFromImages(
      List<MyImageResult> images,
      {String? defaultUrl,
      String fileFieldName = 'file',
      bool includeReqType = false}) async {
    final out = <DirectUploadPayload>[];
    for (final img in images) {
      try {
        final d = await buildDirectUploadPayloadFromImage(img,
            defaultUrl: defaultUrl,
            fileFieldName: fileFieldName,
            includeReqType: includeReqType);
        if (d != null) out.add(d);
      } catch (_) {}
    }
    return out;
  }

  /// Upload a persisted payload (the same shape produced by the field's
  /// queued payload). The helper will decode base64 into a temp file when
  /// necessary and will remove any temp file after the upload completes.
  static Future<MyImageResult?> uploadPersistedPayload(
      Map<String, dynamic> persisted,
      {void Function(double progress)? onProgress}) async {
    final p = await buildUploadPayloadFromMap(persisted);
    if (p == null) return null;

    final headers = (p['headers'] is Map)
        ? Map<String, String>.from(p['headers'] as Map)
        : null;

    try {
      // Build DirectUploadPayload and delegate upload to UploadService so
      // higher-level behaviors (401 refresh+retry) are centralized.
      String? base64Val;
      try {
        final fileEntry = persisted['file'];
        if (fileEntry is Map && fileEntry['base64'] is String) {
          base64Val = fileEntry['base64'] as String;
        }
      } catch (_) {}

      final headersMap = headers != null
          ? Map<String, String>.from(headers)
          : <String, String>{};
      final fieldsMap = <String, String>{};
      if (p['fields'] is Map) {
        (p['fields'] as Map).forEach((k, v) {
          fieldsMap[k.toString()] = v.toString();
        });
      }

      final direct = DirectUploadPayload(
        url: p['url'] as String,
        filePath: p['filePath'] as String,
        fileName: p['fileName'] as String,
        base64: base64Val,
        headers: headersMap,
        fields: fieldsMap,
        fileFieldName: p['fileFieldName'] as String? ?? 'file',
        includeReqType: p['includeReqType'] == true,
        uploadCorrelationId: persisted['uploadCorrelationId']?.toString(),
      );

      final outcome = await UploadService.instance.uploadDirectPayload(
        direct,
        onProgress: onProgress,
      );

      try {
        if (outcome.response != null &&
            UploadResponseMapper.isSuccessfulStatus(
                outcome.response!.statusCode)) {
          OfflineUploadManager.instance
              .notifyUploadSuccess(persisted, outcome.response!);
          // Map successful response into a MyImageResult so callers can
          // conveniently consume normalized upload metadata.
          final data = outcome.response!.data;
          final uploadedLink = UploadResponseMapper.extractUploadedLink(data,
              keys: persisted['uploadFileUrlKey'] ?? 'fileUrl');
          final imageId = UploadResponseMapper.extractImageId(data,
              keys: persisted['uploadImageIdKey'] ?? 'imageId');
          final filePath = UploadResponseMapper.extractFilePath(data,
              keys: persisted['uploadFilePathKey'] ?? 'filePath');
          final description = UploadResponseMapper.extractDescription(data,
              keys: persisted['uploadDescriptionKey'] ?? 'description');

          return MyImageResult(
            link: uploadedLink ?? '',
            base64: '',
            path: filePath ?? '',
            imageId: imageId ?? '',
            description: description ?? '',
            payload: (outcome.response!.data is Map)
                ? Map<String, dynamic>.from(outcome.response!.data as Map)
                : <String, dynamic>{},
            status: MyImageStatus.uploaded,
          );
        }
      } catch (_) {}
      return null;
    } finally {
      if (p['tempFileCreated'] == true) {
        try {
          final tf = File(p['filePath'] as String);
          if (await tf.exists()) await tf.delete();
        } catch (_) {}
      }
    }
  }
}
