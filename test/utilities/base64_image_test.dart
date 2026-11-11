import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/utilities/base64_image.dart';

void main() {
  final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
  final plain = base64Encode(bytes);

  test('decodes plain base64, the form stored by captured images', () {
    expect(decodeBase64Image(plain), bytes);
  });

  test('decodes a data URI', () {
    expect(decodeBase64Image('data:image/png;base64,$plain'), bytes);
  });

  test('ignores whitespace and line breaks', () {
    final wrapped = '${plain.substring(0, 4)}\n  ${plain.substring(4)}';
    expect(decodeBase64Image(wrapped), bytes);
  });

  test('returns null for empty, malformed or prefix-only input', () {
    expect(decodeBase64Image(''), isNull);
    expect(decodeBase64Image('   '), isNull);
    expect(decodeBase64Image('not base64!!'), isNull);
    expect(decodeBase64Image('data:image/png;base64'), isNull);
  });
}
