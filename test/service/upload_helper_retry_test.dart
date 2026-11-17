import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/dio_service.dart';
import 'package:form_fields/src/utilities/upload_helper.dart';

import '../support/scripted_http_adapter.dart';

void main() {
  late Directory tempDir;
  late File photo;
  late Map<String, dynamic> persisted;

  setUp(() {
    DioUtil.configure();
    tempDir = Directory.systemTemp.createTempSync('upload_helper_retry');
    photo = File('${tempDir.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(64, 7));

    // A queued payload as it is stored: the Authorization header was removed
    // when it was queued, so the retry has to obtain a token itself.
    persisted = {
      'url': 'https://example.test/upload',
      'headers': <String, String>{'X-Client': 'app'},
      'fields': <String, String>{},
      'file': {'fileName': 'photo.jpg', 'path': photo.path},
      'uploadCorrelationId': 'corr-1',
    };
  });

  tearDown(() {
    DioUtil.configure();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('a retry sends the Authorization value from the refresher', () async {
    final adapter = ScriptedHttpAdapter([200]);
    DioUtil.dio.httpClientAdapter = adapter;

    await UploadHelper.uploadPersistedPayload(
      persisted,
      uploadTokenRefresher: () async => 'Bearer FRESH',
    );

    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.headers[HttpHeaders.authorizationHeader],
      'Bearer FRESH',
    );
  });

  test('a retry without a refresher still sends the stored headers', () async {
    final adapter = ScriptedHttpAdapter([200]);
    DioUtil.dio.httpClientAdapter = adapter;

    await UploadHelper.uploadPersistedPayload(persisted);

    expect(adapter.requests.single.headers['X-Client'], 'app');
    expect(
      adapter.requests.single.headers.containsKey(
        HttpHeaders.authorizationHeader,
      ),
      isFalse,
    );
  });
}
