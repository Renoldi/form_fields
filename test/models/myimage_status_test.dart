import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utilities/enums.dart';

void main() {
  test('copyWith changes only the status and keeps every other field', () {
    final original = MyImageResult(
      link: 'https://example.com/1.png',
      base64: 'data:image/png;base64,AAA',
      path: '/cache/live_capture_1.png',
      imageId: 'img-1',
      description: 'front door',
      payload: const {'k': 'v'},
      status: MyImageStatus.idle,
    );

    final failed = original.copyWith(status: MyImageStatus.failed);

    expect(failed.status, MyImageStatus.failed);
    expect(failed.link, original.link);
    expect(failed.base64, original.base64);
    expect(failed.path, original.path);
    expect(failed.imageId, original.imageId);
    expect(failed.description, original.description);
    expect(failed.payload, original.payload);
    expect(original.status, MyImageStatus.idle, reason: 'original is unchanged');
  });
}
