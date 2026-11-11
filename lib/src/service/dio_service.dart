// ===================== Dio Utility =====================

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:form_fields/src/utils/debug_log.dart';

/// Key set on [Response.extra] when a request failed before any HTTP response
/// arrived (DNS failure, refused connection, timeout). Callers should check
/// [DioUtil.isNetworkFailure] rather than inspecting error text.
const String kDioNetworkErrorKey = 'form_fields.networkError';

/// Utility class for file upload and download using Dio.
class DioUtil {
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

  // Dio instance is created via `_createDio` so it can be recreated/configured.
  static Dio _dio = _createDio();

  /// Generic request wrapper to handle DioException globally.
  static Future<T?> safeRequest<T>(
    Future<T> Function() request, {
    String? url,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      _logger.e('DioUtil DioException: ${e.type} ${e.message}');
      if (T == Response) {
        return (e.response ?? _networkErrorResponse<dynamic>(url ?? '', e))
            as T;
      }
      return null;
    } catch (e, stack) {
      _logger.e('DioUtil error: $e', error: e, stackTrace: stack);
      if (T == Response) {
        return _unknownErrorResponse<dynamic>(url ?? '', e) as T;
      }
      return null;
    }
  }

  /// Returns true when [response] describes a failure that happened before
  /// any HTTP status was received (no connectivity, DNS, timeout).
  static bool isNetworkFailure(Response? response) {
    if (response == null) return true;
    return response.extra[kDioNetworkErrorKey] == true;
  }

  /// Create a configured Dio instance used by this utility.
  static Dio _createDio({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        headers: <String, dynamic>{
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          'deviceOs': Platform.isAndroid ? 'A' : 'I',
          'deviceOsVersion': Platform.operatingSystemVersion,
          ...?headers,
        },
      ),
    );

    // Timestamp must describe the moment each request is sent, not the moment
    // the client was created.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Client-Timestamp'] = DateTime.now()
              .toIso8601String();
          handler.next(options);
        },
      ),
    );

    // Full request/response logging is for debug builds only. Headers are
    // never logged because they carry credentials such as Authorization.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (object) => _logger.d(object),
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final request = error.requestOptions;
          _logger.e(
            '[DioUtil] ${request.method} ${request.path} failed: '
            'type=${error.type} status=${error.response?.statusCode ?? '-'}',
          );
          handler.next(error);
        },
      ),
    );

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

  /// Downloads a file from the given URL into the system temp directory.
  /// Returns the saved path, or null when the download did not succeed.
  static Future<String?> downloadFile(String url) async {
    final name = _safeFileName(
      Uri.tryParse(url)?.pathSegments.lastOrNull ?? 'download',
    );
    // A timestamp prefix keeps concurrent downloads of the same name apart.
    final file = File(
      '${Directory.systemTemp.path}/${DateTime.now().microsecondsSinceEpoch}_$name',
    );
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(response.data ?? const <int>[]);
      return file.path;
    } on DioException catch (e) {
      _logger.e('[DioUtil] download failed: ${e.type} ${e.message}');
      return null;
    }
  }

  // =============================================================
  // Reusable HTTP helpers (get/post/put/download)
  // These methods provide a consistent, reusable surface similar
  // to HttpService but kept inside this utility for package reuse.
  //
  // They never throw for HTTP or network failures. Every outcome is returned
  // as a Response: the server's response when one arrived, otherwise a
  // synthetic 500 Response (see [isNetworkFailure] to tell the two apart).
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
  }) =>
      _send<T>('GET', path, queryParameters: queryParameters, headers: headers);

  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _send<T>(
    'POST',
    path,
    data: data,
    queryParameters: queryParameters,
    headers: headers,
  );

  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) => _send<T>(
    'PUT',
    path,
    data: data,
    queryParameters: queryParameters,
    headers: headers,
  );

  /// Single code path for get/post/put. Every HTTP status is returned as a
  /// Response, so callers branch on `statusCode` instead of catching errors.
  static Future<Response<T>> _send<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    _logger.i('🌐 $method Request: ${_dio.options.baseUrl}$path');
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: headers,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      _logger.e('❌ $method Failed: ${_dio.options.baseUrl}$path (${e.type})');
      final server = e.response;
      if (server != null) {
        return Response<T>(
          requestOptions: server.requestOptions,
          statusCode: server.statusCode,
          statusMessage: server.statusMessage,
          data: _asType<T>(server.data),
        );
      }
      return _networkErrorResponse<T>(path, e);
    } catch (e) {
      _logger.e('❌ $method Failed (unknown): ${_dio.options.baseUrl}$path');
      return _unknownErrorResponse<T>(path, e);
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

  /// Maximum number of attempts for an upload that fails before the server
  /// answers. HTTP error responses are never retried.
  static const int _uploadMaxAttempts = 3;

  /// Uploads a file to the given URL with optional headers and progress callback.
  ///
  /// Retries up to [_uploadMaxAttempts] times, but only when no HTTP response
  /// arrived and the failure looks transient. A response with status >= 400 is
  /// returned at once. A timeout while receiving the response is not retried,
  /// because the server may already have stored the file.
  static Future<Response?> uploadFile({
    required String url,
    required String filePath,
    String? filename,
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
    List<MapEntry<String, String>>? fields,

    /// Name of the multipart file field (default: 'file')
    String fileFieldName = 'file',

    /// Whether to include the legacy 'reqtype=fileupload' field.
    /// Some servers expect it; others do not. Default: false.
    bool includeReqType = false,
  }) async {
    final uploadName = filename ?? _baseName(filePath);
    if (kDebugMode) {
      debugLog(
        '[DioUtil.uploadFile] url=$url, fileField=$fileFieldName, '
        'includeReqType=$includeReqType, filename=$uploadName, '
        'headers=${headers?.keys.toList()}, fields=${fields?.map((e) => e.key).toList()}',
      );
    }

    for (var attempt = 1; ; attempt++) {
      // A MultipartFile stream can be read only once, so the form is rebuilt
      // for every attempt.
      final formData = FormData();
      if (includeReqType) {
        formData.fields.add(const MapEntry('reqtype', 'fileupload'));
      }
      if (fields != null && fields.isNotEmpty) {
        formData.fields.addAll(fields);
      }
      formData.files.add(
        MapEntry(
          fileFieldName,
          await MultipartFile.fromFile(filePath, filename: uploadName),
        ),
      );

      try {
        return await _dio.post<dynamic>(
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
        );
      } on DioException catch (e) {
        // The server answered with an error status. That is its final answer.
        if (e.response != null) return e.response;

        final retryable = _isRetryableUploadError(e);
        _logger.w(
          '[DioUtil.uploadFile] attempt $attempt failed: ${e.type} '
          '(retryable=$retryable)',
        );
        if (retryable && attempt < _uploadMaxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
          continue;
        }
        return _networkErrorResponse<dynamic>(url, e);
      } catch (e, st) {
        _logger.w(
          '[DioUtil.uploadFile] unexpected error: $e',
          error: e,
          stackTrace: st,
        );
        return _unknownErrorResponse<dynamic>(url, e);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _isRetryableUploadError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.unknown:
        return e.error is SocketException;
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return false;
    }
  }

  /// Builds a synthetic error Response for [T]. The error details are placed
  /// in `data` only when they fit [T]. A Map is not a String, for example, so
  /// `data` is left null in that case instead of failing with a TypeError.
  static Response<T> _errorResponse<T>(
    String path,
    int statusCode,
    String statusMessage,
    Map<String, dynamic> details, {
    bool networkError = false,
  }) {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      statusMessage: statusMessage,
      data: _asType<T>(details),
      extra: {if (networkError) kDioNetworkErrorKey: true},
    );
  }

  static Response<T> _networkErrorResponse<T>(String path, DioException e) {
    return _errorResponse<T>(
      path,
      500,
      'Network/server error. Please try again later.',
      {'errorType': e.type.toString(), 'errorMessage': e.message},
      networkError: true,
    );
  }

  static Response<T> _unknownErrorResponse<T>(String path, Object error) {
    return _errorResponse<T>(path, 500, 'Unknown error', {
      'errorType': 'Unknown',
      'errorMessage': error.toString(),
    });
  }

  /// Returns [value] when it has type [T], otherwise null.
  static T? _asType<T>(Object? value) => value is T ? value : null;

  static String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.substring(normalized.lastIndexOf('/') + 1);
  }

  /// Keeps only characters that are safe in a file name and caps the length.
  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final trimmed = cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
    return trimmed.isEmpty || trimmed == '.' || trimmed == '..'
        ? 'download'
        : trimmed;
  }
}
