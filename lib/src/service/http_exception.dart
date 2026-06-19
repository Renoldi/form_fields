import 'package:dio/dio.dart';

/// High-level error classification for HTTP operations.
enum ErrorType {
  validation,
  network,
  authentication,
  server,
}

/// Exception wrapper that carries a user-facing message key and an
/// `ErrorType` for UI classification. The original DioException is
/// preserved for logging/diagnostics.
class HttpException implements Exception {
  final String messageKey;
  final ErrorType type;
  final DioException? originalError;

  HttpException({
    required this.messageKey,
    required this.type,
    this.originalError,
  });

  @override
  String toString() => 'HttpException: $messageKey (type: $type)';
}
