import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:form_fields/src/models/direct_upload_payload.dart';
import 'package:form_fields/src/service/dio_service.dart';
import 'package:form_fields/src/utilities/upload_response_mapper.dart';
import 'package:form_fields/src/utils/debug_log.dart';

/// Callback type invoked when a payload is queued for a later retry. The
/// boolean flag is `true` when the queueing was due to authentication (401)
/// and `false` for network failures and retryable server errors.
typedef UploadQueuedCallback =
    void Function(DirectUploadPayload payload, bool authExpired);

/// Result of an upload operation.
class UploadOutcome {
  final bool success;
  final Response? response;

  /// True only when the payload was queued because authentication expired
  /// (HTTP 401). Use [queued] to check for any kind of queueing.
  final bool authExpiredQueued;

  /// Payload without credentials, ready to persist and retry. Null unless the
  /// upload was queued.
  final DirectUploadPayload? sanitizedPayload;

  UploadOutcome({
    this.success = false,
    this.response,
    this.authExpiredQueued = false,
    this.sanitizedPayload,
  });

  /// True when the payload was queued for a later retry.
  bool get queued => sanitizedPayload != null;
}

/// High-level upload service that wraps `DioUtil.uploadFile`.
///
/// Failures are classified as follows:
/// - Network failure (no HTTP response), HTTP 401 and retryable server errors
///   (408, 429, 5xx) produce a sanitized payload that the caller can persist
///   and retry later.
/// - Other 4xx responses are permanent. They are returned as failures and are
///   not queued, because retrying the same request cannot succeed.
class UploadService {
  UploadService._();
  static final UploadService instance = UploadService._();

  /// Uploads a typed [DirectUploadPayload].
  ///
  /// - `uploadTokenRefresher`: optional callback that returns a fresh
  ///   `Authorization` header value (including the scheme, for example
  ///   `Bearer <token>`). When the server answers 401, it is called once and
  ///   the upload is retried with the new value. Returning null, or an error
  ///   from the callback, skips the retry.
  /// - `onUploadAuthExpired`: notification invoked when the upload is queued
  ///   because authentication expired.
  /// - `onUploadQueued`: invoked with the sanitized payload whenever the upload
  ///   is queued for a later retry.
  Future<UploadOutcome> uploadDirectPayload(
    DirectUploadPayload payload, {
    Future<String?> Function()? uploadTokenRefresher,
    VoidCallback? onUploadAuthExpired,
    void Function(double progress)? onProgress,
    UploadQueuedCallback? onUploadQueued,
  }) async {
    final headers = Map<String, String>.from(payload.headers);

    var response = await _send(payload, headers, onProgress);

    if (_isUnauthorized(response) && uploadTokenRefresher != null) {
      final refreshed = await _refreshAuthorization(uploadTokenRefresher);
      if (refreshed != null) {
        headers[HttpHeaders.authorizationHeader] = refreshed;
        response = await _send(payload, headers, onProgress);
      }
    }

    if (DioUtil.isNetworkFailure(response)) {
      return _queue(
        payload,
        headers,
        response: response,
        authExpired: false,
        onQueued: onUploadQueued,
      );
    }

    if (_isUnauthorized(response)) {
      _notify(onUploadAuthExpired);
      return _queue(
        payload,
        headers,
        response: response,
        authExpired: true,
        onQueued: onUploadQueued,
      );
    }

    final statusCode = response!.statusCode;
    if (UploadResponseMapper.isSuccessfulStatus(statusCode)) {
      return UploadOutcome(success: true, response: response);
    }

    if (isRetryableStatus(statusCode)) {
      return _queue(
        payload,
        headers,
        response: response,
        authExpired: false,
        onQueued: onUploadQueued,
      );
    }

    // Permanent client error (400, 403, 404, 413, 422, ...): retrying the same
    // request cannot succeed, so it is reported and not queued.
    return UploadOutcome(success: false, response: response);
  }

  Future<Response?> _send(
    DirectUploadPayload payload,
    Map<String, String> headers,
    void Function(double progress)? onProgress,
  ) {
    return DioUtil.uploadFile(
      url: payload.url,
      filePath: payload.filePath,
      filename: payload.fileName,
      headers: headers.isNotEmpty ? headers : null,
      onProgress: onProgress,
      fields: payload.fields.isNotEmpty
          ? payload.fields.entries
                .map((e) => MapEntry(e.key.toString(), e.value.toString()))
                .toList()
          : null,
      fileFieldName: payload.fileFieldName,
      includeReqType: payload.includeReqType,
    );
  }

  static bool _isUnauthorized(Response? response) =>
      response?.statusCode == 401;

  /// Statuses that may succeed later without any change to the request.
  /// A missing status (network failure) is treated as retryable.
  static bool isRetryableStatus(int? statusCode) {
    if (statusCode == null) return true;
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  Future<String?> _refreshAuthorization(
    Future<String?> Function() refresher,
  ) async {
    try {
      final value = await refresher();
      return (value == null || value.trim().isEmpty) ? null : value;
    } catch (e, st) {
      if (kDebugMode) {
        debugLog('UploadService: uploadTokenRefresher threw: $e\n$st');
      }
      return null;
    }
  }

  void _notify(VoidCallback? callback) {
    try {
      callback?.call();
    } catch (e, st) {
      if (kDebugMode) {
        debugLog('UploadService: callback threw: $e\n$st');
      }
    }
  }

  /// Builds the sanitized payload (without Authorization) and notifies the
  /// caller so the app can persist it and retry later.
  UploadOutcome _queue(
    DirectUploadPayload payload,
    Map<String, String> headers, {
    required Response? response,
    required bool authExpired,
    UploadQueuedCallback? onQueued,
  }) {
    final headersForPersist = Map<String, String>.from(headers)
      ..remove(HttpHeaders.authorizationHeader);
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

    if (kDebugMode) {
      debugLog(
        'UploadService: queueing payload (authExpired=$authExpired, '
        'status=${response?.statusCode}, correlation=${sanitized.uploadCorrelationId})',
      );
    }
    try {
      onQueued?.call(sanitized, authExpired);
    } catch (e, st) {
      if (kDebugMode) {
        debugLog('UploadService: onUploadQueued threw: $e\n$st');
      }
    }

    return UploadOutcome(
      success: false,
      response: response,
      authExpiredQueued: authExpired,
      sanitizedPayload: sanitized,
    );
  }
}
