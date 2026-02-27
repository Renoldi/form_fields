import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Global HTTP service for making API requests
/// Singleton pattern for app-wide access
class HttpService {
  HttpService._internal({Dio? dio})
      : _dio = dio ?? _createDio(),
        _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
        );

  static HttpService? _instance;

  // Static logger for use in static methods
  static final Logger _staticLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Get the global singleton instance
  static HttpService get instance {
    _instance ??= HttpService._internal();
    return _instance!;
  }

  /// Create a new instance with custom configuration
  factory HttpService({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
    Dio? dio,
  }) {
    if (dio != null) {
      return HttpService._internal(dio: dio);
    }

    return HttpService._internal(
      dio: _createDio(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        headers: headers,
      ),
    );
  }

  static Dio _createDio({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    final effectiveBaseUrl = baseUrl ?? 'https://dummyjson.com';
    _staticLogger
        .i('🚀 HttpService initialized with Base URL: $effectiveBaseUrl');

    final dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 10),
        sendTimeout: sendTimeout ?? const Duration(seconds: 10),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 15),
        headers: headers ?? {'Content-Type': 'application/json'},
      ),
    );

    // Add logging interceptor
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (object) => _staticLogger.d(object),
    ));

    return dio;
  }

  final Dio _dio;
  final Logger _logger;

  /// Update base URL for different API endpoints
  void setBaseUrl(String baseUrl) {
    _logger.i('🔧 Base URL changed: $baseUrl');
    _dio.options.baseUrl = baseUrl;
  }

  /// Update authorization header
  void setAuthToken(String token, {String prefix = 'Bearer'}) {
    _dio.options.headers['Authorization'] = '$prefix $token';
    _logger.i('🔐 Auth token set successfully');
  }

  /// Remove authorization header
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    _logger.i('🔓 Auth token cleared');
  }

  /// Add custom header
  void setHeader(String key, dynamic value) {
    _dio.options.headers[key] = value;
  }

  /// Get current Dio instance for advanced usage
  Dio get dio => _dio;

  /// Generic GET request with retry logic
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    _logger.i('🌐 GET Request: ${_dio.options.baseUrl}$path');
    try {
      final result = await _withRetry(() async {
        final response = await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
        );

        if (parser != null) {
          return parser(response.data);
        }
        return response.data as T;
      });
      _logger.d('✅ GET Success: ${_dio.options.baseUrl}$path');
      return result;
    } catch (e) {
      _logger.e('❌ GET Failed: ${_dio.options.baseUrl}$path');
      rethrow;
    }
  }

  /// Generic POST request with retry logic
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    _logger.i('🌐 POST Request: ${_dio.options.baseUrl}$path');
    if (data != null) {
      _logger.d(
          '📦 Request body: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...');
    }
    try {
      final result = await _withRetry(() async {
        final response = await _dio.post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );

        if (parser != null) {
          return parser(response.data);
        }
        return response.data as T;
      });
      _logger.d('✅ POST Success: ${_dio.options.baseUrl}$path');
      return result;
    } catch (e) {
      _logger.e('❌ POST Failed: ${_dio.options.baseUrl}$path');
      rethrow;
    }
  }

  /// Generic PUT request with retry logic
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    _logger.i('🌐 PUT Request: ${_dio.options.baseUrl}$path');
    if (data != null) {
      _logger.d(
          '📦 Request body: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...');
    }
    try {
      final result = await _withRetry(() async {
        final response = await _dio.put(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );

        if (parser != null) {
          return parser(response.data);
        }
        return response.data as T;
      });
      _logger.d('✅ PUT Success: ${_dio.options.baseUrl}$path');
      return result;
    } catch (e) {
      _logger.e('❌ PUT Failed: ${_dio.options.baseUrl}$path');
      rethrow;
    }
  }

  /// Download file to specified path with progress callback
  Future<void> download(
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
      await _withRetry(() async {
        await _dio.download(
          urlPath,
          savePath,
          queryParameters: queryParameters,
          options: options,
          onReceiveProgress: onProgress,
          cancelToken: cancelToken,
        );
      });
      _logger.d('✅ Download Success: $savePath');
    } catch (e) {
      _logger.e('❌ Download Failed: $urlPath');
      rethrow;
    }
  }

  /// Retry wrapper with exponential backoff
  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    int maxRetries = 2,
    Duration initialDelay = const Duration(milliseconds: 300),
  }) async {
    var attempt = 0;
    var delay = initialDelay;

    while (true) {
      try {
        return await action();
      } on DioException catch (error) {
        attempt++;
        final statusCode = error.response?.statusCode;
        final errorType = _getErrorTypeString(error.type);

        _logger.w('⚠️ Request failed (attempt $attempt/$maxRetries)');
        _logger.w('   Type: $errorType');
        if (statusCode != null) {
          _logger.w('   Status: $statusCode');
        }
        if (error.message != null) {
          _logger.w('   Message: ${error.message}');
        }

        if (attempt > maxRetries || !_shouldRetry(error)) {
          _logger
              .e('❌ Request failed permanently: ${error.requestOptions.uri}');
          _logger.e('   Final error type: $errorType');
          rethrow;
        }
        _logger.i('🔄 Retrying after ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Determine if a request should be retried
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        _logger.d('🔁 Retryable error: Timeout or connection issue');
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        final shouldRetry = status >= 500 && status < 600;
        if (shouldRetry) {
          _logger.d('🔁 Retryable error: Server error ($status)');
        } else {
          _logger.d('🚫 Non-retryable: Client error ($status)');
        }
        return shouldRetry;
      case DioExceptionType.cancel:
        _logger.d('🚫 Non-retryable: Request cancelled');
        return false;
      case DioExceptionType.unknown:
        _logger.d('🚫 Non-retryable: Unknown error');
        return false;
      case DioExceptionType.badCertificate:
        _logger.d('🚫 Non-retryable: Bad certificate');
        return false;
    }
  }

  /// Get human-readable error type string
  String _getErrorTypeString(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection Timeout';
      case DioExceptionType.sendTimeout:
        return 'Send Timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive Timeout';
      case DioExceptionType.connectionError:
        return 'Connection Error';
      case DioExceptionType.badResponse:
        return 'Bad Response';
      case DioExceptionType.cancel:
        return 'Request Cancelled';
      case DioExceptionType.unknown:
        return 'Unknown Error';
      case DioExceptionType.badCertificate:
        return 'Bad Certificate';
    }
  }
}
