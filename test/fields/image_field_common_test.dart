import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/fields/core/image_field_common.dart';
import 'package:form_fields/src/models/direct_upload_payload.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/utilities/enums.dart';

MyImageResult _image({String description = '', String link = ''}) =>
    MyImageResult(path: '/tmp/a.png', description: description, link: link);

void main() {
  group('resolveUploadDescription', () {
    test('an explicit description wins and is trimmed', () {
      expect(
        resolveUploadDescription(
          _image(description: 'own'),
          explicit: '  hi  ',
        ),
        'hi',
      );
    });

    test(
      'a blank explicit description falls back to the image description',
      () {
        expect(
          resolveUploadDescription(
            _image(description: ' own '),
            explicit: '  ',
          ),
          'own',
        );
      },
    );

    test('returns null when both descriptions are blank', () {
      expect(resolveUploadDescription(_image(description: '  ')), isNull);
    });
  });

  group('descriptionFormFields', () {
    test('no entries for a null or empty description', () {
      expect(descriptionFormFields(null, 'description'), isEmpty);
      expect(descriptionFormFields('', 'description'), isEmpty);
    });

    test('one entry under the given field name', () {
      final fields = descriptionFormFields('note', 'remark');
      expect(fields.length, 1);
      expect(fields.single.key, 'remark');
      expect(fields.single.value, 'note');
    });
  });

  group('resolveUploadedLink', () {
    test('uses the uploaded link when the server returned one', () {
      expect(
        resolveUploadedLink(
          uploadedLink: ' https://cdn.test/a.png ',
          fallbackLink: 'local',
          uploadedPath: null,
          uploadUrl: 'https://api.test/upload',
        ),
        'https://cdn.test/a.png',
      );
    });

    test('builds an absolute link from a relative uploaded path', () {
      expect(
        resolveUploadedLink(
          uploadedLink: null,
          fallbackLink: '',
          uploadedPath: 'files/a.png',
          uploadUrl: 'https://api.test/upload',
        ),
        'https://api.test/files/a.png',
      );
    });

    test(
      'keeps the fallback link when there is no upload URL to build from',
      () {
        expect(
          resolveUploadedLink(
            uploadedLink: null,
            fallbackLink: 'keep',
            uploadedPath: null,
            uploadUrl: null,
          ),
          'keep',
        );
      },
    );
  });

  group('resolveUploadedPath', () {
    test('prefers the uploaded path when it is not blank', () {
      expect(
        resolveUploadedPath('/server/a.png', '/local/a.png'),
        '/server/a.png',
      );
    });

    test('keeps the local path when the uploaded path is blank', () {
      expect(resolveUploadedPath('  ', '/local/a.png'), '/local/a.png');
      expect(resolveUploadedPath(null, '/local/a.png'), '/local/a.png');
    });
  });

  group('imageStatusIcon', () {
    test('maps each upload status to its icon', () {
      expect(
        imageStatusIcon(MyImageStatus.uploading).codePoint,
        isNot(imageStatusIcon(MyImageStatus.queued).codePoint),
      );
      expect(
        imageStatusIcon(MyImageStatus.failed).codePoint,
        isNot(imageStatusIcon(MyImageStatus.uploaded).codePoint),
      );
      expect(
        imageStatusIcon(MyImageStatus.idle),
        imageStatusIcon(MyImageStatus.uploaded),
      );
    });
  });

  group('buildImageUploadPayload', () {
    test('records the file, description and keys needed for a retry', () {
      final payload = buildImageUploadPayload(
        uploadUrl: 'https://api.test/upload',
        headers: const {},
        image: _image(),
        fileName: 'a.png',
        description: 'note',
        formFields: descriptionFormFields('note', 'description'),
        fileUrlKey: 'fileUrl',
        imageIdKey: 'imageId',
        index: 2,
      );

      expect(payload['url'], 'https://api.test/upload');
      expect(payload['fields'], {'description': 'note'});
      expect(payload['file'], containsPair('fileName', 'a.png'));
      expect(payload['file'], containsPair('path', '/tmp/a.png'));
      expect(payload['uploadFileUrlKey'], 'fileUrl');
      expect(payload['uploadImageIdKey'], 'imageId');
      expect(payload['description'], 'note');
      expect(payload['index'], 2);
      expect(payload['uploadCorrelationId'], isA<String>());
    });
  });

  group('queueImageForRetry', () {
    test(
      'reports a queued upload once to each callback and returns it queued',
      () async {
        final dir = Directory.systemTemp.createTempSync('image_field_common');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = File('${dir.path}/a.png')..writeAsBytesSync([1, 2, 3]);

        final queuedCalls = <bool>[];
        final failedCalls = <List<DirectUploadPayload>>[];
        final settings = DirectUploadSettings(
          uploadUrl: 'https://api.test/upload',
          uploadToken: null,
          fileFieldName: 'file',
          includeReqType: false,
          fileUrlKey: 'fileUrl',
          imageIdKey: 'imageId',
          descriptionFormField: 'description',
          descriptionResponseKey: 'description',
          showLoading: false,
          showResultDialog: false,
          logTag: 'test',
          onUploadQueued: (payload, authExpired) =>
              queuedCalls.add(authExpired),
          onFailDirectUploadPayload: failedCalls.add,
        );

        final result = await queueImageForRetry(
          image: MyImageResult(path: file.path),
          payload: <String, dynamic>{},
          settings: settings,
          authExpired: true,
        );

        expect(result.image.status, MyImageStatus.queued);
        expect(result.payload, isNotNull);
        expect(queuedCalls, [true]);
        expect(failedCalls.length, 1);
        expect(failedCalls.single.length, 1);
      },
    );
  });
}
