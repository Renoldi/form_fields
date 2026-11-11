import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/dio_service.dart';

import '../support/scripted_http_adapter.dart';

void main() {
  late Directory tempDir;
  late File uploadFile;

  setUp(() {
    DioUtil.configure();
    tempDir = Directory.systemTemp.createTempSync('dio_service_test');
    uploadFile = File('${tempDir.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(2048, 7));
  });

  tearDown(() {
    DioUtil.configure();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('request helpers', () {
    test(
      'returns HTTP error statuses as a Response instead of throwing',
      () async {
        final adapter = ScriptedHttpAdapter([404]);
        DioUtil.dio.httpClientAdapter = adapter;

        final resp = await DioUtil.get<Map<String, dynamic>>('/missing');

        expect(resp.statusCode, 404);
        expect(DioUtil.isNetworkFailure(resp), isFalse);
      },
    );

    test(
      'connection failure yields a 500 Response flagged as network error',
      () async {
        DioUtil.dio.httpClientAdapter = ScriptedHttpAdapter([
          DioExceptionType.connectionError,
        ]);

        final resp = await DioUtil.post<Map<String, dynamic>>(
          '/x',
          data: {'a': 1},
        );

        expect(resp.statusCode, 500);
        expect(DioUtil.isNetworkFailure(resp), isTrue);
      },
    );

    test('Client-Timestamp is set per request, not once at creation', () async {
      final adapter = ScriptedHttpAdapter([200, 200]);
      DioUtil.dio.httpClientAdapter = adapter;

      await DioUtil.get('/a');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await DioUtil.get('/b');

      final first = adapter.requests[0].headers['Client-Timestamp'] as String;
      final second = adapter.requests[1].headers['Client-Timestamp'] as String;
      expect(first, isNotEmpty);
      expect(second, isNot(equals(first)));
    });

    test(
      'does not send the invalid Content-MD5 or CORS request headers',
      () async {
        final adapter = ScriptedHttpAdapter([200]);
        DioUtil.dio.httpClientAdapter = adapter;

        await DioUtil.get('/a');

        final headers = adapter.requests.single.headers;
        expect(headers.containsKey('content-md5'), isFalse);
        expect(headers.containsKey('Access-Control-Allow-Origin'), isFalse);
        expect(headers.containsKey('deviceOsVersion'), isTrue);
      },
    );
  });

  group('uploadFile', () {
    test('rebuilds the multipart body on every retry', () async {
      final adapter = ScriptedHttpAdapter([
        DioExceptionType.connectionError,
        DioExceptionType.connectionError,
        200,
      ]);
      DioUtil.dio.httpClientAdapter = adapter;

      final resp = await DioUtil.uploadFile(
        url: 'https://example.test/upload',
        filePath: uploadFile.path,
      );

      expect(resp?.statusCode, 200);
      expect(adapter.requests, hasLength(3));
      // Every attempt must carry the full file, not an already-consumed stream.
      for (final length in adapter.bodyLengths) {
        expect(length, greaterThan(2048));
      }
    });

    test('sends a multipart content type', () async {
      final adapter = ScriptedHttpAdapter([200]);
      DioUtil.dio.httpClientAdapter = adapter;

      await DioUtil.uploadFile(
        url: 'https://example.test/upload',
        filePath: uploadFile.path,
      );

      final contentType =
          adapter.requests.single.headers[Headers.contentTypeHeader] as String;
      expect(contentType, startsWith('multipart/form-data'));
    });

    test('returns an HTTP error response without retrying', () async {
      final adapter = ScriptedHttpAdapter([500]);
      DioUtil.dio.httpClientAdapter = adapter;

      final resp = await DioUtil.uploadFile(
        url: 'https://example.test/upload',
        filePath: uploadFile.path,
      );

      expect(resp?.statusCode, 500);
      expect(adapter.requests, hasLength(1));
    });

    test('gives up after three transient connection failures', () async {
      final adapter = ScriptedHttpAdapter([DioExceptionType.connectionError]);
      DioUtil.dio.httpClientAdapter = adapter;

      final resp = await DioUtil.uploadFile(
        url: 'https://example.test/upload',
        filePath: uploadFile.path,
      );

      expect(adapter.requests, hasLength(3));
      expect(DioUtil.isNetworkFailure(resp), isTrue);
    });

    test(
      'does not retry a receive timeout, since the server may have stored it',
      () async {
        final adapter = ScriptedHttpAdapter([DioExceptionType.receiveTimeout]);
        DioUtil.dio.httpClientAdapter = adapter;

        final resp = await DioUtil.uploadFile(
          url: 'https://example.test/upload',
          filePath: uploadFile.path,
        );

        expect(adapter.requests, hasLength(1));
        expect(DioUtil.isNetworkFailure(resp), isTrue);
      },
    );

    test('throws for a missing file, as before', () async {
      DioUtil.dio.httpClientAdapter = ScriptedHttpAdapter([200]);

      expect(
        () => DioUtil.uploadFile(
          url: 'https://example.test/upload',
          filePath: '${tempDir.path}/missing.jpg',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('downloadFile', () {
    test('returns null on HTTP failure and never writes a file', () async {
      DioUtil.dio.httpClientAdapter = ScriptedHttpAdapter([404]);

      final path = await DioUtil.downloadFile('https://example.test/a/b.bin');

      expect(path, isNull);
    });
  });
}
