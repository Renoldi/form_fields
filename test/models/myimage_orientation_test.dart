import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';
import 'package:image/image.dart' as img;

void main() {
  test('a photo with EXIF rotation keeps its orientation after compression',
      () async {
    final dir = Directory.systemTemp.createTempSync('exif_orientation');
    addTearDown(() => dir.deleteSync(recursive: true));

    // Stored as 20 wide and 10 tall, but tagged to be shown rotated 90 degrees.
    // A portrait photo from a phone looks like this.
    final source = img.Image(width: 20, height: 10);
    source.exif.imageIfd.orientation = 6;
    final file = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(img.encodeJpg(source));

    final result = await MyImageResult.fromFile(file, quality: 90);

    final data = base64Decode(result.base64.split(',').last);
    final decoded = img.decodeJpg(data)!;
    expect(decoded.width, 10, reason: 'rotation must be applied to pixels');
    expect(decoded.height, 20);
  });

  test('resize uses the rotated dimensions, so the aspect ratio holds',
      () async {
    final dir = Directory.systemTemp.createTempSync('exif_resize');
    addTearDown(() => dir.deleteSync(recursive: true));

    final source = img.Image(width: 40, height: 20);
    source.exif.imageIfd.orientation = 6; // shown as 20 wide, 40 tall
    final file = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(img.encodeJpg(source));

    // Limit the height to 20. The rotated image is 20x40, so it becomes 10x20.
    final result = await MyImageResult.fromFile(
      file,
      maxHeight: 20,
      quality: 90,
    );

    final decoded = img.decodeJpg(
      base64Decode(result.base64.split(',').last),
    )!;
    expect(decoded.height, 20);
    expect(decoded.width, 10);
  });
}
