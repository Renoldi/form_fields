import 'dart:convert';

import 'package:dio/dio.dart';

/// Test double for Dio's HTTP layer. Each entry in [script] is consumed in
/// order by one request:
/// - an `int` answers the request with that HTTP status;
/// - a [DioExceptionType] throws before any response, like a dropped
///   connection or a timeout.
///
/// When the script runs out, the last entry repeats.
class ScriptedHttpAdapter implements HttpClientAdapter {
  ScriptedHttpAdapter(this.script) : assert(script.isNotEmpty);

  final List<Object> script;

  /// Every request received, in order.
  final List<RequestOptions> requests = [];

  /// Body length of each request, in bytes. Lets tests check that a retried
  /// multipart upload still carried the whole file.
  final List<int> bodyLengths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    var length = 0;
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        length += chunk.length;
      }
    }
    bodyLengths.add(length);

    final index = requests.length - 1;
    final step = script[index < script.length ? index : script.length - 1];
    if (step is DioExceptionType) {
      throw DioException(
        requestOptions: options,
        type: step,
        message: 'scripted ${step.name}',
      );
    }
    final status = step as int;
    return ResponseBody.fromString(
      jsonEncode({'status': status}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
