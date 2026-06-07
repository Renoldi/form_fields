// ===================== Dio Utility =====================

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Utility class for file upload and download using Dio.
class DioUtil {
  /// Generic request wrapper to handle DioException globally.
  static Future<T?> safeRequest<T>(
    Future<T> Function() request, {
    String? url,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      _logger.e('DioUtil DioException: $e', error: e, stackTrace: e.stackTrace);
      if (T == Response) {
        return (e.response ??
            Response(
              requestOptions: RequestOptions(path: url ?? ''),
              statusCode: 500,
              statusMessage: 'Network/server error. Please try again later.',
              data: {
                'errorType': e.type.toString(),
                'errorMessage': e.message,
              },
            )) as T;
      }
      return null;
    } catch (e, stack) {
      _logger.e('DioUtil error: $e', error: e, stackTrace: stack);
      if (T == Response) {
        return Response(
          requestOptions: RequestOptions(path: url ?? ''),
          statusCode: 500,
          statusMessage: 'Network/server error. Please try again later.',
          data: {'errorType': 'Unknown', 'errorMessage': e.toString()},
        ) as T;
      }
      return null;
    }
  }

  static final Dio _dio = Dio()
    ..interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

  static final Logger _logger = Logger();

  /// Downloads a file from the given URL and saves it to a temp path.
  static Future<String?> downloadFile(String url) async {
    final response = await safeRequest<Response>(
      () => _dio.get(url, options: Options(responseType: ResponseType.bytes)),
      url: url,
    );
    if (response != null && response.statusCode == 200) {
      final tempDir = Directory.systemTemp;
      final fileName = url.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.data);
      return file.path;
    }
    return null;
  }

  /// Uploads a file to the given URL with optional headers and progress callback.
  static Future<Response?> uploadFile({
    required String url,
    required String filePath,
    String? filename,
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
    List<MapEntry<String, String>>? fields,

    /// Name of the multipart file field (default: 'fileToUpload')
    String fileFieldName = 'file',

    /// Whether to include the legacy 'reqtype=fileupload' field.
    /// Some servers expect it; others do not. Default: true.
    bool includeReqType = false,
  }) async {
    final file = File(filePath);
    final formData = FormData();
    if (includeReqType) {
      formData.fields.add(MapEntry('reqtype', 'fileupload'));
    }
    if (fields != null && fields.isNotEmpty) {
      formData.fields.addAll(fields);
    }
    formData.files.add(
      MapEntry(
        fileFieldName,
        await MultipartFile.fromFile(
          filePath,
          filename: filename ?? file.path.split('/').last,
        ),
      ),
    );
    // Debug: log upload details to help diagnose server errors (avoid
    // printing full header values to reduce secret leakage).
    try {
      final fileSize = file.existsSync() ? file.lengthSync() : null;
      debugPrint(
          '[DioUtil.uploadFile] url=$url, fileField=$fileFieldName, includeReqType=$includeReqType, filename=${filename ?? file.path.split('/').last}, fileSize=$fileSize, headers=${headers?.keys.toList()}, fields=${fields?.map((e) => '${e.key}=${e.value}').toList()}');
    } catch (_) {}
    // Retry loop for transient network/DNS errors. We still use
    // `safeRequest` to normalize DioExceptions into Responses when
    // possible, but wrap it here to catch any thrown SocketExceptions
    // or DioExceptions that might escape and retry a few times.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final resp = await safeRequest<Response>(
          () => _dio.post(
            url,
            data: formData,
            options: Options(
              headers: headers,
              followRedirects: true,
              validateStatus: (status) => status != null && status < 400,
            ),
            onSendProgress: (sent, total) {
              if (onProgress != null) {
                onProgress(total > 0 ? sent / total : 0.0);
              }
            },
          ),
          url: url,
        );

        // If we received a valid response object, return it.
        if (resp != null) return resp;

        // Otherwise, treat as transient and retry (unless last attempt).
        if (attempt < maxAttempts) {
          final backoff = Duration(milliseconds: 200 * attempt);
          debugPrint(
              '[DioUtil.uploadFile] transient null response, retrying in $backoff (attempt $attempt)');
          await Future.delayed(backoff);
          continue;
        }

        // Last attempt and still null -> return a synthetic 500 Response.
        return Response(
          requestOptions: RequestOptions(path: url),
          statusCode: 500,
          statusMessage: 'Network error (no response)',
          data: {'error': 'no_response'},
        );
      } on DioException catch (e) {
        _logger.w(
            '[DioUtil.uploadFile] DioException on attempt $attempt: ${e.message}');
        // If last attempt, convert to a Response so callers can proceed.
        if (attempt >= maxAttempts) {
          return e.response ??
              Response(
                requestOptions: RequestOptions(path: url),
                statusCode: 500,
                statusMessage: 'Dio connection error',
                data: {
                  'errorType': e.type.toString(),
                  'errorMessage': e.message
                },
              );
        }
        // small backoff before next try
        await Future.delayed(Duration(milliseconds: 200 * attempt));
        continue;
      } catch (e, st) {
        _logger.w('[DioUtil.uploadFile] Error on attempt $attempt: $e',
            error: e, stackTrace: st);
        if (attempt >= maxAttempts) {
          return Response(
            requestOptions: RequestOptions(path: url),
            statusCode: 500,
            statusMessage: 'Network/error',
            data: {'errorType': 'Unknown', 'errorMessage': e.toString()},
          );
        }
        await Future.delayed(Duration(milliseconds: 200 * attempt));
        continue;
      }
    }
    // Shouldn't reach here, but return a fallback.
    return Response(
      requestOptions: RequestOptions(path: url),
      statusCode: 500,
      statusMessage: 'Network/error',
      data: {'error': 'unexpected_fallback'},
    );
  }
}
