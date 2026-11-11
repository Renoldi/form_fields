import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/service/upload_service.dart';

void main() {
  // Live camera and signature pad both queue a failed upload only when this
  // rule says it can succeed later. Keeping the rule in one place stops the
  // two capture paths from drifting apart again.
  group('UploadService.isRetryableStatus', () {
    test('server errors, timeouts and rate limits can be retried', () {
      expect(UploadService.isRetryableStatus(500), isTrue);
      expect(UploadService.isRetryableStatus(503), isTrue);
      expect(UploadService.isRetryableStatus(408), isTrue);
      expect(UploadService.isRetryableStatus(429), isTrue);
    });

    test('a missing status (network failure) can be retried', () {
      expect(UploadService.isRetryableStatus(null), isTrue);
    });

    test('permanent client errors are not retried', () {
      expect(UploadService.isRetryableStatus(400), isFalse);
      expect(UploadService.isRetryableStatus(403), isFalse);
      expect(UploadService.isRetryableStatus(404), isFalse);
      expect(UploadService.isRetryableStatus(422), isFalse);
    });
  });
}
