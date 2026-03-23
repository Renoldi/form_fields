import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class DioServiceException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  DioServiceException(this.message, {this.error, this.stackTrace});
  @override
  String toString() => 'DioServiceException: $message';
}

class DioService {
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _request<T>(
      () => dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
      'GET $path',
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _request<T>(
      () => dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      'POST $path',
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _request<T>(
      () => dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      'PUT $path',
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _request<T>(
      () => dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'DELETE $path',
    );
  }

  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
  }) async {
    return _request(
      () => dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        options: options,
      ),
      'DOWNLOAD $urlPath',
    );
  }

  Future<Response<T>> upload<T>(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? fields,
    List<MultipartFile>? files,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final formData = FormData.fromMap({
      if (fields != null) ...fields,
      ...data,
      if (files != null) ...{
        for (var i = 0; i < files.length; i++) 'file$i': files[i],
      },
    });
    return _request<T>(
      () => dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options ?? Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      'UPLOAD $path',
    );
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() requestFn,
    String context,
  ) async {
    try {
      final response = await requestFn();
      return response;
    } on DioException catch (e, stack) {
      _logger.e('DioService $context error: ${e.message}',
          error: e, stackTrace: stack);
      throw DioServiceException('DioService $context error: ${e.message}',
          error: e, stackTrace: stack);
    } catch (e, stack) {
      _logger.e('DioService $context unknown error',
          error: e, stackTrace: stack);
      throw DioServiceException('DioService $context unknown error',
          error: e, stackTrace: stack);
    }
  }

  static final DioService _instance = DioService._internal();
  factory DioService() => _instance;
  late final Dio dio;
  final Logger _logger = Logger();

  DioService._internal() {
    dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i('Dio Request: \\${options.method} \\${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('Dio Response: \\${response.statusCode} \\${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logger.e('Dio Error: \\${e.message}',
            error: e, stackTrace: e.stackTrace);
        return handler.next(e);
      },
    ));
  }

  // Add more methods as needed (post, put, delete, etc.)
}
