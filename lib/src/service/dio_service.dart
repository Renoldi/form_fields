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

  // Dio instance is created via `_createDio` so it can be recreated/configured.
  static Dio _dio = _createDio();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: false,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Create a configured Dio instance used by this utility.
  static Dio _createDio({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    final timeStamp = DateTime.now();
    final newHeaders = <String, dynamic>{};
    newHeaders.addAll({
      HttpHeaders.acceptHeader: "application/json",
      HttpHeaders.contentMD5Header: "application/json",
      "Content-Type": "application/json",
      "Client-Timestamp": timeStamp.toIso8601String(),
      'Access-Control-Allow-Origin': '*', // Replace your domain
      'Access-Control-Allow-Methods': 'POST, GET, DELETE, HEAD, OPTIONS',
      "deviceOs": Platform.isAndroid ? "A" : "I",
      "deviiceOsVersion": Platform.operatingSystemVersion,
    });

    final mergedHeaders = <String, dynamic>{};
    mergedHeaders.addAll(newHeaders);
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      headers: mergedHeaders,
    ));

    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) => _logger.d(object),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        final request = error.requestOptions;
        final statusCode = error.response?.statusCode;
        _logger.e('[DioUtil] HTTP error ${request.method} ${request.uri}');
        _logger.e(
            '[DioUtil] type=${error.type} status=${statusCode ?? '-'} message=${error.message ?? '-'}');
        if (error.response?.data != null) {
          _logger.e('[DioUtil] response=${error.response!.data}');
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  /// Reconfigure the underlying Dio instance. Call this at app startup
  /// or when you need a different base URL / timeouts / headers.
  static void configure({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    _dio = _createDio(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
    );
    _logger.i('[DioUtil] configured baseUrl=${baseUrl ?? ''}');
  }

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

  // =============================================================
  // Reusable HTTP helpers (get/post/put/download)
  // These methods provide a consistent, reusable surface similar
  // to HttpService but kept inside this utility for package reuse.
  // =============================================================

  static Dio get dio => _dio;

  static void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
    _logger.i('🔧 Base URL changed: $baseUrl');
  }

  static void setAuthToken(String token, {String prefix = 'Bearer'}) {
    _dio.options.headers[HttpHeaders.authorizationHeader] = '$prefix $token';
    _logger.i('🔐 Auth token set successfully');
  }

  static void clearAuthToken() {
    _dio.options.headers.remove(HttpHeaders.authorizationHeader);
    _logger.i('🔓 Auth token cleared');
  }

  static void setHeader(String key, dynamic value) {
    _dio.options.headers[key] = value;
  }

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    _logger.i('🌐 GET Request: ${_dio.options.baseUrl}$path');
    try {
      Options? requestOptions;
      if (headers != null) {
        final merged = <String, dynamic>{};
        merged.addAll(_dio.options.headers);
        merged.addAll(headers);
        requestOptions = Options(headers: merged, validateStatus: (_) => true);
      }

      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
      );
      return response;
    } on DioException catch (e) {
      _logger.e('❌ GET Failed: ${_dio.options.baseUrl}$path');
      if (e.response != null) {
        try {
          final r = e.response!;
          return Response<T>(
            requestOptions: r.requestOptions,
            statusCode: r.statusCode,
            statusMessage: r.statusMessage,
            data: r.data as T,
          );
        } catch (_) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: e.response?.statusCode,
            statusMessage: e.response?.statusMessage,
            data: e.response?.data,
          ) as Response<T>;
        }
      }
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 500,
        statusMessage: 'Network/server error',
        data: {'errorType': e.type.toString(), 'errorMessage': e.message},
      ) as Response<T>;
    } catch (e) {
      _logger.e('❌ GET Failed (unknown): ${_dio.options.baseUrl}$path');
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 500,
        statusMessage: 'Unknown error',
        data: {'error': e.toString()},
      ) as Response<T>;
    }
  }

  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    _logger.i('🌐 POST Request: ${_dio.options.baseUrl}$path');
    try {
      Options? requestOptions;
      if (headers != null) {
        final merged = <String, dynamic>{};
        merged.addAll(_dio.options.headers);
        merged.addAll(headers);
        requestOptions = Options(headers: merged, validateStatus: (_) => true);
      }

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
      return response;
    } on DioException catch (e) {
      _logger.e('❌ POST Failed: ${_dio.options.baseUrl}$path');
      if (e.response != null) {
        try {
          final r = e.response!;
          return Response<T>(
            requestOptions: r.requestOptions,
            statusCode: r.statusCode,
            statusMessage: r.statusMessage,
            data: r.data as T,
          );
        } catch (_) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: e.response?.statusCode,
            statusMessage: e.response?.statusMessage,
            data: e.response?.data,
          ) as Response<T>;
        }
      }
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 500,
        statusMessage: 'Network/server error',
        data: {'errorType': e.type.toString(), 'errorMessage': e.message},
      ) as Response<T>;
    } catch (e) {
      _logger.e('❌ POST Failed (unknown): ${_dio.options.baseUrl}$path');
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 500,
        statusMessage: 'Unknown error',
        data: {'error': e.toString()},
      ) as Response<T>;
    }
  }

  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    _logger.i('🌐 PUT Request: ${_dio.options.baseUrl}$path');
    try {
      Options? requestOptions;
      if (headers != null) {
        final merged = <String, dynamic>{};
        merged.addAll(_dio.options.headers);
        merged.addAll(headers);
        requestOptions = Options(headers: merged, validateStatus: (_) => true);
      }

      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
      return response;
    } on DioException catch (e) {
      _logger.e('❌ PUT Failed: ${_dio.options.baseUrl}$path');
      if (e.response != null) {
        try {
          final r = e.response!;
          return Response<T>(
            requestOptions: r.requestOptions,
            statusCode: r.statusCode,
            statusMessage: r.statusMessage,
            data: r.data as T,
          );
        } catch (_) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: e.response?.statusCode,
            statusMessage: e.response?.statusMessage,
            data: e.response?.data,
          ) as Response<T>;
        }
      }
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 500,
        statusMessage: 'Network/server error',
        data: {'errorType': e.type.toString(), 'errorMessage': e.message},
      ) as Response<T>;
    } catch (e) {
      _logger.e('❌ PUT Failed (unknown): ${_dio.options.baseUrl}$path');
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 500,
        statusMessage: 'Unknown error',
        data: {'error': e.toString()},
      ) as Response<T>;
    }
  }

  /// Download file to specified path with progress callback
  static Future<void> download(
    String urlPath,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    _logger.i('📥 Download Request: ${_dio.options.baseUrl}$urlPath');
    _logger.d('💾 Save to: $savePath');
    try {
      await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        options: options,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );
      _logger.d('✅ Download Success: $savePath');
    } catch (e) {
      _logger.e('❌ Download Failed: $urlPath');
      rethrow;
    }
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
        if (resp != null) {
          return resp;
        }

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
