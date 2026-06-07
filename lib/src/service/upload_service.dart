import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:form_fields/src/models/direct_upload_payload.dart';
import 'package:form_fields/src/service/dio_service.dart';
import 'package:form_fields/src/utilities/upload_response_mapper.dart';

/// Callback type invoked when a payload is queued because of auth expiry
/// or network failure. The boolean flag is `true` when the queueing was
/// due to authentication (401) and `false` for network/DNS errors.
typedef UploadQueuedCallback = void Function(
    DirectUploadPayload payload, bool authExpired);

/// Result of an upload operation.
class UploadOutcome {
  final bool success;
  final Response? response;
  final bool authExpiredQueued;
  final DirectUploadPayload? sanitizedPayload;

  UploadOutcome({
    this.success = false,
    this.response,
    this.authExpiredQueued = false,
    this.sanitizedPayload,
  });
}

/// High-level upload service that wraps `DioUtil.uploadFile` and handles
/// a single 401 refresh+retry, plus returning a sanitized payload when
/// auth is expired so callers can persist/queue it.
class UploadService {
  UploadService._();
  static final UploadService instance = UploadService._();

  /// Uploads a typed [DirectUploadPayload].
  ///
  /// - `uploadTokenRefresher`: optional callback to obtain a fresh token on
  ///   401. If provided, the service will call it once and retry the upload
  ///   with the returned token.
  /// - `onUploadAuthExpired`: optional notification callback invoked when
  ///   authentication appears to be expired and the sanitized payload is
  ///   produced for queuing.
  Future<UploadOutcome> uploadDirectPayload(
    DirectUploadPayload payload, {
    Future<String?> Function()? uploadTokenRefresher,
    VoidCallback? onUploadAuthExpired,
    void Function(double progress)? onProgress,
    UploadQueuedCallback? onUploadQueued,
  }) async {
    final headers = Map<String, String>.from(payload.headers);
    final fieldsList = payload.fields.entries
        .map((e) => MapEntry(e.key.toString(), e.value.toString()))
        .toList();

    Response? response = await DioUtil.uploadFile(
      url: payload.url,
      filePath: payload.filePath,
      filename: payload.fileName,
      headers: headers.isNotEmpty ? headers : null,
      onProgress: onProgress,
      fields: fieldsList.isNotEmpty ? fieldsList : null,
      fileFieldName: payload.fileFieldName,
      includeReqType: payload.includeReqType,
    );

    // Detect transient network/DNS failures normalized by DioUtil.
    // DioUtil returns a 500 Response with diagnostic data for these cases.
    bool looksLikeNetworkError(Response? r) {
      if (r == null) return true;
      final d = r.data;
      if (d is Map) {
        final e = d['error'] ?? d['errorType'] ?? d['errorMessage'];
        if (e is String &&
            (e.contains('no_response') ||
                e.contains('Failed host lookup') ||
                e.contains('connection'))) {
          return true;
        }
      }
      return false;
    }

    if (looksLikeNetworkError(response)) {
      // Build sanitized payload without Authorization for persistence/queueing.
      final headersForPersist = Map<String, String>.from(headers);
      headersForPersist.remove('Authorization');
      final sanitized = DirectUploadPayload(
        url: payload.url,
        filePath: payload.filePath,
        fileName: payload.fileName,
        base64: payload.base64,
        headers: headersForPersist,
        fields: payload.fields,
        fileFieldName: payload.fileFieldName,
        includeReqType: payload.includeReqType,
        uploadCorrelationId: payload.uploadCorrelationId,
      );
      try {
        onUploadQueued?.call(sanitized, false);
      } catch (_) {}
      return UploadOutcome(
          success: false,
          response: response,
          authExpiredQueued: true,
          sanitizedPayload: sanitized);
    }

    // Handle 401: try refresh once, then if still 401 produce sanitized
    // payload (without Authorization) for queueing and notify caller.
    if (response != null && response.statusCode == 401) {
      String? newToken;
      if (uploadTokenRefresher != null) {
        try {
          newToken = await uploadTokenRefresher();
        } catch (_) {
          newToken = null;
        }
      }

      if (newToken != null && newToken.isNotEmpty) {
        try {
          final retryHeaders = Map<String, String>.from(headers);
          retryHeaders['Authorization'] = newToken;
          final retryResp = await DioUtil.uploadFile(
            url: payload.url,
            filePath: payload.filePath,
            filename: payload.fileName,
            headers: retryHeaders,
            onProgress: onProgress,
            fields: fieldsList.isNotEmpty ? fieldsList : null,
            fileFieldName: payload.fileFieldName,
            includeReqType: payload.includeReqType,
          );
          response = retryResp;
        } catch (_) {}
      }

      if (response == null || response.statusCode == 401) {
        // Build sanitized payload without Authorization for persistence.
        final headersForPersist = Map<String, String>.from(headers);
        headersForPersist.remove('Authorization');
        final sanitized = DirectUploadPayload(
          url: payload.url,
          filePath: payload.filePath,
          fileName: payload.fileName,
          base64: payload.base64,
          headers: headersForPersist,
          fields: payload.fields,
          fileFieldName: payload.fileFieldName,
          includeReqType: payload.includeReqType,
          uploadCorrelationId: payload.uploadCorrelationId,
        );
        try {
          onUploadAuthExpired?.call();
        } catch (_) {}
        try {
          onUploadQueued?.call(sanitized, true);
        } catch (_) {}
        return UploadOutcome(
            success: false,
            response: response,
            authExpiredQueued: true,
            sanitizedPayload: sanitized);
      }
    }

    final ok = response != null &&
        UploadResponseMapper.isSuccessfulStatus(response.statusCode);
    return UploadOutcome(success: ok, response: response);
  }
}
