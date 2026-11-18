import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utilities/upload_request_helpers.dart';

void main() {
  group('buildUploadAuthHeaders', () {
    test('returns an Authorization header for a non-empty token', () {
      expect(buildUploadAuthHeaders('Bearer abc'), {
        HttpHeaders.authorizationHeader: 'Bearer abc',
      });
    });

    test('returns an empty map when the token is null or empty', () {
      expect(buildUploadAuthHeaders(null), isEmpty);
      expect(buildUploadAuthHeaders(''), isEmpty);
    });
  });

  group('resolveUploadFileName', () {
    test('uses the last segment of the local path first', () {
      final image = MyImageResult(
        path: '/data/user/0/cache/photo_01.jpg',
        link: 'https://cdn.example.com/other.png',
      );

      expect(resolveUploadFileName(image), 'photo_01.jpg');
    });

    test('falls back to the last segment of the link when path is blank', () {
      final image = MyImageResult(
        path: '   ',
        link: 'https://cdn.example.com/files/remote.png',
      );

      expect(resolveUploadFileName(image), 'remote.png');
    });

    test('falls back to "image" when neither path nor link is set', () {
      expect(resolveUploadFileName(MyImageResult()), 'image');
    });
  });
}
