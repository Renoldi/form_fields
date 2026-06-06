/// Utilities for normalizing upload responses from various servers.
///
/// Provides helpers to extract common fields such as uploaded file URL,
/// image/file id, description and file path from heterogeneous server
/// responses (String/Map/List). Methods are static so they can be used
/// from widgets and services without instantiating the class.
class UploadResponseMapper {
  /// Returns true when [statusCode] represents a successful HTTP status.
  static bool isSuccessfulStatus(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  /// Extract a nested value by key from a Map/List/string payload.
  /// Returns `null` when not found.
  static String? extractNestedValue(dynamic data, String key) {
    if (data is Map) {
      for (final entry in data.entries) {
        if (entry.key.toString() == key) {
          return entry.value?.toString();
        }
        final nested = extractNestedValue(entry.value, key);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    if (data is List) {
      for (final item in data) {
        final nested = extractNestedValue(item, key);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    return null;
  }

  /// Try to extract a usable uploaded file URL from the server [data].
  /// [uploadFileUrlKey] is attempted first (server-configurable), then a
  /// set of common fallback keys.
  static String? extractUploadedLink(dynamic data, String uploadFileUrlKey) {
    if (data == null) return null;

    if (data is String) {
      final raw = data.trim();
      if (raw.isEmpty) return null;

      final redirectRegex =
          RegExp(r"redirect_link\s*=\s*'([^']+)'", multiLine: true);
      final match = redirectRegex.firstMatch(raw);
      if (match != null) return match.group(1);

      final asUri = Uri.tryParse(raw);
      if (asUri != null && asUri.hasScheme) return raw;
      return null;
    }

    final exact = extractNestedValue(data, uploadFileUrlKey);
    if ((exact ?? '').isNotEmpty) return exact;

    const fallbackKeys = [
      'fileUrl',
      'url',
      'link',
      'imageUrl',
      'downloadUrl',
      'receiverPhoto',
      'receiver_photo',
      'photoUrl',
      'photo',
      'redirect_link',
    ];
    for (final key in fallbackKeys) {
      final val = extractNestedValue(data, key);
      if ((val ?? '').isNotEmpty) return val;
    }
    return null;
  }

  /// Extract an image id from the server [data], preferring the
  /// [uploadImageIdKey] when provided.
  static String? extractImageId(dynamic data, String uploadImageIdKey) {
    if (data == null) return null;

    final exact = extractNestedValue(data, uploadImageIdKey);
    if ((exact ?? '').isNotEmpty) return exact;

    const fallbackKeys = ['imageId', 'id'];
    for (final key in fallbackKeys) {
      final val = extractNestedValue(data, key);
      if ((val ?? '').isNotEmpty) return val;
    }
    return null;
  }

  /// Extract a server-provided file path (if any).
  static String? extractFilePath(dynamic data) {
    if (data == null) return null;

    final exact = extractNestedValue(data, 'filePath');
    if ((exact ?? '').isNotEmpty) return exact;

    const fallbackKeys = ['file_path', 'filepath', 'path'];
    for (final key in fallbackKeys) {
      final val = extractNestedValue(data, key);
      if ((val ?? '').isNotEmpty) return val;
    }
    return null;
  }

  /// Extract a description/caption from the server [data].
  /// [descriptionField] is the preferred key to check first.
  static String? extractDescription(dynamic data, String descriptionField) {
    if (data == null) return null;

    final exact = extractNestedValue(data, descriptionField);
    if ((exact ?? '').isNotEmpty) return exact;

    const fallbackKeys = [
      'description',
      'desc',
      'note',
      'caption',
      'alt',
      'title'
    ];
    for (final key in fallbackKeys) {
      final val = extractNestedValue(data, key);
      if ((val ?? '').isNotEmpty) return val;
    }
    return null;
  }
}
