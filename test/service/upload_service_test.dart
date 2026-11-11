import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:form_fields/src/models/direct_upload_payload.dart';
import 'package:form_fields/src/service/dio_service.dart';
import 'package:form_fields/src/service/upload_service.dart';

import '../support/scripted_http_adapter.dart';

void main() {
  late Directory tempDir;
  late File photo;
  late List<DirectUploadPayload> queued;
  late List<bool> queuedAuthFlags;
  late int authExpiredCalls;

  DirectUploadPayload payload() => DirectUploadPayload(
    url: 'https://example.test/upload',
    filePath: photo.path,
    fileName: 'photo.jpg',
    headers: {HttpHeaders.authorizationHeader: 'Bearer OLD'},
    fields: const {},
  );

  Future<UploadOutcome> run(
    ScriptedHttpAdapter adapter, {
    Future<String?> Function()? refresher,
  }) async {
    DioUtil.dio.httpClientAdapter = adapter;
    return UploadService.instance.uploadDirectPayload(
      payload(),
      uploadTokenRefresher: refresher,
      onUploadAuthExpired: () => authExpiredCalls++,
      onUploadQueued: (sanitized, authExpired) {
        queued.add(sanitized);
        queuedAuthFlags.add(authExpired);
      },
    );
  }

  setUp(() {
    DioUtil.configure();
    tempDir = Directory.systemTemp.createTempSync('upload_service_test');
    photo = File('${tempDir.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(512, 1));
    queued = [];
    queuedAuthFlags = [];
    authExpiredCalls = 0;
  });

  tearDown(() {
    DioUtil.configure();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('success is reported and nothing is queued', () async {
    final outcome = await run(ScriptedHttpAdapter([200]));

    expect(outcome.success, isTrue);
    expect(outcome.queued, isFalse);
    expect(queued, isEmpty);
  });

  test('permanent client error (400) is reported, not queued', () async {
    final outcome = await run(ScriptedHttpAdapter([400]));

    expect(outcome.success, isFalse);
    expect(outcome.response?.statusCode, 400);
    expect(outcome.queued, isFalse);
    expect(queued, isEmpty);
  });

  test(
    'retryable server error (503) is queued without the auth flag',
    () async {
      final outcome = await run(ScriptedHttpAdapter([503]));

      expect(outcome.queued, isTrue);
      expect(outcome.authExpiredQueued, isFalse);
      expect(queuedAuthFlags, [false]);
    },
  );

  test('network failure is queued and is not flagged as auth expiry', () async {
    final outcome = await run(
      ScriptedHttpAdapter([DioExceptionType.connectionError]),
    );

    expect(outcome.queued, isTrue);
    expect(outcome.authExpiredQueued, isFalse);
    expect(queuedAuthFlags, [false]);
    expect(authExpiredCalls, 0);
  });

  test('queued payload never keeps the Authorization header', () async {
    final outcome = await run(
      ScriptedHttpAdapter([DioExceptionType.connectionError]),
    );

    expect(outcome.sanitizedPayload, isNotNull);
    expect(
      outcome.sanitizedPayload!.headers.containsKey(
        HttpHeaders.authorizationHeader,
      ),
      isFalse,
    );
  });

  test('401 without a refresher queues with the auth flag', () async {
    final outcome = await run(ScriptedHttpAdapter([401]));

    expect(outcome.queued, isTrue);
    expect(outcome.authExpiredQueued, isTrue);
    expect(queuedAuthFlags, [true]);
    expect(authExpiredCalls, 1);
  });

  test(
    '401 with a refresher retries once using the new Authorization value',
    () async {
      final adapter = ScriptedHttpAdapter([401, 200]);
      var refreshCalls = 0;

      final outcome = await run(
        adapter,
        refresher: () async {
          refreshCalls++;
          return 'Bearer NEW';
        },
      );

      expect(refreshCalls, 1);
      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests[0].headers[HttpHeaders.authorizationHeader],
        'Bearer OLD',
      );
      expect(
        adapter.requests[1].headers[HttpHeaders.authorizationHeader],
        'Bearer NEW',
      );
      expect(outcome.success, isTrue);
      expect(queued, isEmpty);
    },
  );

  test('a refresher that returns null leaves the payload queued', () async {
    final adapter = ScriptedHttpAdapter([401]);

    final outcome = await run(adapter, refresher: () async => null);

    expect(adapter.requests, hasLength(1));
    expect(outcome.authExpiredQueued, isTrue);
  });

  test('a refresher that throws is treated as no token', () async {
    final adapter = ScriptedHttpAdapter([401]);

    final outcome = await run(
      adapter,
      refresher: () async {
        throw StateError('auth service down');
      },
    );

    expect(adapter.requests, hasLength(1));
    expect(outcome.queued, isTrue);
  });

  test('a refresh that still gets 401 is queued with the auth flag', () async {
    final adapter = ScriptedHttpAdapter([401, 401]);

    final outcome = await run(adapter, refresher: () async => 'Bearer NEW');

    expect(adapter.requests, hasLength(2));
    expect(outcome.authExpiredQueued, isTrue);
    expect(queuedAuthFlags, [true]);
  });
}
