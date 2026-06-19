import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      headersForPersist.remove(HttpHeaders.authorizationHeader);
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
        if (kDebugMode) {
          debugPrint('UploadService: queueing payload (network error)');
          try {
            debugPrint(
                'UploadService: sanitized.correlation=${sanitized.uploadCorrelationId} file=${sanitized.fileName} path=${sanitized.filePath}');
          } catch (_) {}
        }
        onUploadQueued?.call(sanitized, false);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('UploadService: onUploadQueued threw: $e\n$st');
        }
      }
      return UploadOutcome(
          success: false,
          response: response,
          authExpiredQueued: true,
          sanitizedPayload: sanitized);
    }

    // Handle 401: do NOT attempt an automatic token refresh+retry.
    // Instead create a sanitized payload (without Authorization) and
    // notify the caller so the app-level handler (`onUploadQueued`/
    // `onUploadAuthExpired`) can persist and retry as needed.
    if (response != null && response.statusCode == 401) {
      // Build sanitized payload without Authorization for persistence.
      final headersForPersist = Map<String, String>.from(headers);
      headersForPersist.remove(HttpHeaders.authorizationHeader);
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
        if (kDebugMode) {
          debugPrint('UploadService: auth expired -> queueing payload (auth)');
          try {
            debugPrint(
                'UploadService: sanitized.correlation=${sanitized.uploadCorrelationId} file=${sanitized.fileName} path=${sanitized.filePath}');
          } catch (_) {}
        }
        onUploadAuthExpired?.call();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('UploadService: onUploadAuthExpired threw: $e\n$st');
        }
      }
      try {
        onUploadQueued?.call(sanitized, true);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('UploadService: onUploadQueued threw: $e\n$st');
        }
      }
      return UploadOutcome(
          success: false,
          response: response,
          authExpiredQueued: true,
          sanitizedPayload: sanitized);
    }

    // For other server/client errors (4xx/5xx) treat similarly: do not
    // attempt automatic retry here, instead produce a sanitized payload
    // and notify caller so application-level code can decide to retry.
    if (response != null && response.statusCode != null) {
      final sc = response.statusCode!;
      if (sc >= 400 && sc < 600 && sc != 401) {
        final headersForPersist = Map<String, String>.from(headers);
        headersForPersist.remove(HttpHeaders.authorizationHeader);
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
          if (kDebugMode) {
            debugPrint(
                'UploadService: server error $sc -> queueing payload (server)');
            try {
              debugPrint(
                  'UploadService: sanitized.correlation=${sanitized.uploadCorrelationId} file=${sanitized.fileName} path=${sanitized.filePath}');
            } catch (_) {}
          }
          onUploadQueued?.call(sanitized, false);
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('UploadService: onUploadQueued threw: $e\n$st');
          }
        }
        return UploadOutcome(
            success: false,
            response: response,
            authExpiredQueued: false,
            sanitizedPayload: sanitized);
      }
    }

    final ok = response != null &&
        UploadResponseMapper.isSuccessfulStatus(response.statusCode);
    return UploadOutcome(success: ok, response: response);
  }
}
