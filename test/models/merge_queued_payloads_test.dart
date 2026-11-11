import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/models/direct_upload_payload.dart';

DirectUploadPayload _payload({
  required String filePath,
  required String? correlationId,
}) {
  return DirectUploadPayload(
    url: 'https://example.com/upload',
    filePath: filePath,
    fileName: filePath.split('/').last,
    headers: const {},
    fields: const {},
    fileFieldName: 'file',
    includeReqType: false,
    uploadCorrelationId: correlationId,
  );
}

void main() {
  group('mergeQueuedPayloads', () {
    test('the same capture reached twice is queued once', () {
      // Buffered by the live camera with its original correlation id.
      final buffered = _payload(
        filePath: '/cache/live_capture_1.png',
        correlationId: 'id-live',
      );
      // Rebuilt from the final result, which gets a new correlation id.
      final rebuilt = _payload(
        filePath: '/cache/live_capture_1.png',
        correlationId: 'id-rebuilt',
      );

      final merged = mergeQueuedPayloads([buffered], [rebuilt]);

      expect(merged, hasLength(1));
      expect(merged.single.uploadCorrelationId, 'id-live');
    });

    test('a different capture from the other path is kept', () {
      final buffered = _payload(
        filePath: '/cache/live_capture_1.png',
        correlationId: 'id-live',
      );
      final signature = _payload(
        filePath: '/cache/signature_2.png',
        correlationId: 'id-sig',
      );

      final merged = mergeQueuedPayloads([buffered], [signature]);

      expect(merged.map((p) => p.filePath), [
        '/cache/live_capture_1.png',
        '/cache/signature_2.png',
      ]);
    });

    test('with nothing buffered, the rebuilt payloads are returned', () {
      final signature = _payload(
        filePath: '/cache/signature_2.png',
        correlationId: 'id-sig',
      );

      final merged = mergeQueuedPayloads(const [], [signature]);

      expect(merged.single.filePath, '/cache/signature_2.png');
    });
  });
}
