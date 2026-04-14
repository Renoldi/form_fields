import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:form_fields_example/config/error_type.dart';
import 'package:form_fields_example/config/environment.dart';

// =============================================================
//  Exception Definitions
// =============================================================

/// Custom exception for professional error classification.
/// Usage: Catch HttpException for UI error display.
class HttpException implements Exception {
  final String messageKey;
  final ErrorType type;
  final DioException? originalError;

  /// Create professional HTTP exception with error classification
  /// - [message]: User-friendly error message for display
  /// - [type]: ErrorType for UI styling (validation/network/authentication/server)
  /// - [originalError]: Original DioException for logging/debugging
  HttpException({
    required this.messageKey,
    required this.type,
    this.originalError,
  });

  @override
  String toString() => 'HttpException: $messageKey (type: $type)';
}

/// Global HTTP service for making API requests with professional error handling
///
/// Features:
/// - Singleton pattern for app-wide access
/// - Automatic retry with exponential backoff
/// - Professional error classification (HttpException with ErrorType)
/// - User-friendly error messages
/// - Comprehensive logging
///
/// Error Handling Pattern:
/// 1. HttpService throws HttpException with type & message
/// 2. Presenter catches HttpException
/// 3. AppFeedbackDialog displays with proper styling
///
/// Example usage:
/// ```dart
/// try {
///   final user = await User.login(username, password);
/// } catch (error) {
///   if (error is HttpException) {
///     await AppFeedbackDialog(context).showError(
///       title: 'Login Failed',
///       message: error.message,
///       dialogType: AppDialogType.server,
///     );
///   }
/// }
/// ```
// =============================================================
//  HttpService: Global HTTP Client
// =============================================================

/// Global HTTP service for API requests with professional error handling.
/// Features:
///   - Singleton pattern for app-wide access
///   - Professional error classification (HttpException)
///   - User-friendly error messages
///   - Comprehensive logging
/// Usage: Catch HttpException for UI error display.
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

  // =============================================================
  //  Singleton & Initialization
  // =============================================================

  static HttpService? _instance;

  /// Static logger for use in static methods
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

  /// Internal: Create Dio instance with logging and error handling
  static Dio _createDio({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    // Use environment config by default if no baseUrl provided
    final envConfig = EnvironmentConfig.config;
    final effectiveBaseUrl = baseUrl ?? envConfig.baseUrl;

    _staticLogger.i('');
    _staticLogger
        .i('╔═══════════════════════════════════════════════════════════╗');
    _staticLogger
        .i('║ 🌍 HttpService Initialization                            ║');
    _staticLogger
        .i('╠═══════════════════════════════════════════════════════════╣');
    _staticLogger.i('║ Environment: ${envConfig.name.padRight(49)}║');
    _staticLogger.i('║ Base URL:    ${effectiveBaseUrl.padRight(49)}║');
    _staticLogger.i('║ API Path:    ${envConfig.apiVersion.padRight(49)}║');
    _staticLogger
        .i('╚═══════════════════════════════════════════════════════════╝');
    _staticLogger.i('');

    final dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout:
            connectTimeout ?? Duration(seconds: envConfig.connectTimeout),
        sendTimeout: sendTimeout ?? Duration(seconds: envConfig.sendTimeout),
        receiveTimeout:
            receiveTimeout ?? Duration(seconds: envConfig.receiveTimeout),
        headers: headers ??
            {
              'Content-Type': 'application/json',
              ...envConfig.customHeaders,
            },
      ),
    );

    // -------------------------------------------------------------
    //  Interceptors
    // -------------------------------------------------------------
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (object) => _staticLogger.d(object),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        final mapped = _mapDioError(error);
        final request = error.requestOptions;
        final statusCode = error.response?.statusCode;

        // Keep full technical details in logs for diagnostics.
        _staticLogger.e(
          '[HTTP_ERROR] ${request.method} ${request.uri}',
        );
        _staticLogger.e(
          '[HTTP_ERROR] type=${error.type} status=${statusCode ?? '-'} message=${error.message ?? '-'}',
        );
        if (error.response?.data != null) {
          _staticLogger.e('[HTTP_ERROR] response=${error.response!.data}');
        }

        handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: HttpException(
              messageKey: mapped.messageKey,
              type: mapped.type,
              originalError: error,
            ),
          ),
        );
      },
    ));

    return dio;
  }

  // =============================================================
  //  Fields
  // =============================================================
  final Dio _dio;
  final Logger _logger;

  static ({String messageKey, ErrorType type}) _mapDioError(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return (
          messageKey: 'errorNetworkUnavailable',
          type: ErrorType.network,
        );
      case DioExceptionType.badCertificate:
        return (
          messageKey: 'errorSecureConnectionFailed',
          type: ErrorType.network,
        );
      case DioExceptionType.cancel:
        return (
          messageKey: 'errorRequestCancelled',
          type: ErrorType.validation,
        );
      case DioExceptionType.badResponse:
        return _mapHttpStatus(error.response?.statusCode);
      case DioExceptionType.unknown:
        return (
          messageKey: 'errorSomethingWentWrong',
          type: ErrorType.server,
        );
    }
  }

  static ({String messageKey, ErrorType type}) _mapHttpStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return (
          messageKey: 'errorRequestInvalidData',
          type: ErrorType.validation,
        );
      case 401:
      case 403:
        return (
          messageKey: 'errorAuthenticationFailed',
          type: ErrorType.authentication,
        );
      case 404:
        return (
          messageKey: 'errorResourceNotFound',
          type: ErrorType.server,
        );
      case 409:
        return (
          messageKey: 'errorRequestConflict',
          type: ErrorType.validation,
        );
      case 422:
        return (
          messageKey: 'errorInvalidInputValues',
          type: ErrorType.validation,
        );
      case 429:
        return (
          messageKey: 'errorTooManyRequests',
          type: ErrorType.server,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return (
          messageKey: 'errorServerUnavailable',
          type: ErrorType.server,
        );
      default:
        return (
          messageKey: 'errorRequestFailedGeneric',
          type: ErrorType.server,
        );
    }
  }

  // =============================================================
  //  Configuration Methods
  // =============================================================

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

  // =============================================================
  //  HTTP Methods
  // =============================================================

  /// GET request with optional parser
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    _logger.i('🌐 GET Request: ${_dio.options.baseUrl}$path');
    try {
      Response<T> response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      return response;
    } catch (e) {
      _logger.e('❌ GET Failed: ${_dio.options.baseUrl}$path');
      rethrow;
    }
  }

  /// POST request with optional parser
  Future<Response<T>> post<T>(
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
      Response<T> response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return response;
    } catch (e) {
      _logger.e('❌ POST Failed: ${_dio.options.baseUrl}$path');
      rethrow;
    }
  }

  /// PUT request with optional parser
  Future<Response<T>> put<T>(
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
      Response<T> response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return response;
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
}
