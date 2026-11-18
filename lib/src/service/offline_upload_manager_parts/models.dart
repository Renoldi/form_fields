part of '../offline_upload_manager.dart';

/// Values extracted once from the server response of a successful upload.
class _UploadResult {
  const _UploadResult({this.link, this.imageId});

  factory _UploadResult.from(Map<String, dynamic> persisted, Response resp) {
    return _UploadResult(
      link: UploadResponseMapper.extractUploadedLink(
        resp.data,
        keys: persisted['uploadFileUrlKey']?.toString() ?? 'fileUrl',
      ),
      imageId: UploadResponseMapper.extractImageId(
        resp.data,
        keys: persisted['uploadImageIdKey']?.toString() ?? 'imageId',
      ),
    );
  }

  final String? link;
  final String? imageId;
}

/// Identifying data of a persisted upload, used to find the matching image.
class _PersistedRef {
  const _PersistedRef({
    this.correlationId,
    this.path,
    this.base64,
    this.fileName,
  });

  factory _PersistedRef.from(Map<String, dynamic> persisted) {
    final file = persisted['file'];
    final fileMap = file is Map
        ? Map<String, dynamic>.from(file)
        : const <String, dynamic>{};
    final path = _nonEmpty(fileMap['path']);
    final base64 = _nonEmpty(fileMap['base64']);
    return _PersistedRef(
      correlationId: persisted['uploadCorrelationId']?.toString(),
      path: path,
      base64: base64 == null ? null : _stripDataPrefix(base64),
      fileName:
          _nonEmpty(fileMap['fileName']) ??
          (path == null ? null : p.basename(path)),
    );
  }

  final String? correlationId;
  final String? path;
  final String? base64;
  final String? fileName;

  /// Strong match: same correlation id, file path, or base64 content.
  bool matchesStrongly(MyImageResult img) {
    final imgCorr = img.payload['uploadCorrelationId']?.toString();
    if (correlationId != null && imgCorr != null && correlationId == imgCorr) {
      return true;
    }

    final imgPath = _nonEmpty(img.path);
    if (path != null && imgPath != null && path == imgPath) return true;

    final imgBase64 = _nonEmpty(img.base64);
    return base64 != null &&
        imgBase64 != null &&
        base64 == _stripDataPrefix(imgBase64);
  }

  /// Weak match: same file name. Several images can share a name, so callers
  /// must use this only as a fallback.
  bool matchesByFileName(MyImageResult img) {
    if (fileName == null) return false;
    final imgPath = _nonEmpty(img.path);
    final imgFileName = imgPath != null
        ? p.basename(imgPath)
        : _nonEmpty(_fileMapOf(img)?['fileName']);
    return imgFileName != null && fileName == imgFileName;
  }

  static Map<String, dynamic>? _fileMapOf(MyImageResult img) {
    final file = img.payload['file'];
    return file is Map ? Map<String, dynamic>.from(file) : null;
  }
}

class _PendingSuccess {
  _PendingSuccess({
    required this.persisted,
    required this.result,
    required this.createdAt,
  }) : ref = _PersistedRef.from(persisted);

  /// Restores an entry from [toJson] output. Returns null for malformed data.
  static _PendingSuccess? fromJson(Map<String, dynamic> json) {
    try {
      final persisted = json['persisted'];
      final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
      if (persisted is! Map || createdAt == null) return null;
      return _PendingSuccess(
        persisted: Map<String, dynamic>.from(persisted),
        result: _UploadResult(
          link: json['link'] as String?,
          imageId: json['imageId'] as String?,
        ),
        createdAt: createdAt,
      );
    } catch (e, st) {
      _log.warning('Skipping malformed pending upload record', e, st);
      return null;
    }
  }

  /// JSON form of this entry, or null when [persisted] cannot be encoded
  /// (such an entry stays in memory only).
  Map<String, dynamic>? toJson() => _json;

  /// Encoded once: the whole buffer is re-persisted on every change, and
  /// [persisted] can hold large base64 payloads.
  late final Map<String, dynamic>? _json = _encodeOnce();

  Map<String, dynamic>? _encodeOnce() {
    try {
      jsonEncode(persisted);
    } catch (_) {
      return null;
    }
    return {
      'persisted': persisted,
      'link': result.link,
      'imageId': result.imageId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  final Map<String, dynamic> persisted;
  final _PersistedRef ref;
  final _UploadResult result;
  final DateTime createdAt;
}

class _ImageLocation {
  const _ImageLocation(this.provider, this.index);

  final FormFieldsMyImageProvider provider;
  final int index;
}

String? _nonEmpty(Object? value) {
  if (value is! String) return null;
  return value.trim().isEmpty ? null : value;
}

/// Removes a leading `data:<mime>;base64,` prefix, if present.
String _stripDataPrefix(String s) {
  if (!s.startsWith('data:')) return s;
  final comma = s.indexOf(',');
  return comma >= 0 ? s.substring(comma + 1) : s;
}

/// Internal owner of [OfflineUploadManager] members moved out of the main file.
class _OfflineUploadCodec {
  static MyImageResult _markUploaded(MyImageResult img, _UploadResult result) {
    return MyImageResult(
      link: result.link ?? img.link,
      base64: img.base64,
      path: img.path,
      imageId: result.imageId ?? img.imageId,
      description: img.description,
      payload: img.payload,
      status: MyImageStatus.uploaded,
    );
  }
}
