import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/controllers/form_fields_my_image_controller.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/service/offline_upload_manager.dart';
import 'package:form_fields/src/utilities/enums.dart';

Response<dynamic> _resp(String link) => Response(
  requestOptions: RequestOptions(path: '/upload'),
  data: {'fileUrl': link},
);

void main() {
  final mgr = OfflineUploadManager.instance;

  setUp(() => mgr.resetForTesting());
  tearDown(() => mgr.resetForTesting());

  test(
    'file-name fallback marks only one image when several share the name',
    () {
      final c = FormFieldsMyImageController(
        initialImages: [
          MyImageResult(path: '/cam/a/image.jpg'),
          MyImageResult(path: '/cam/b/image.jpg'),
        ],
      );
      mgr.registerController(c);

      // The upload belongs to neither path, so only the name matches.
      mgr.notifyUploadSuccess({
        'file': {'path': '/elsewhere/image.jpg'},
      }, _resp('http://u/x'));

      final uploaded = c.images
          .where((i) => i.status == MyImageStatus.uploaded)
          .toList();
      expect(uploaded, hasLength(1));
      expect(uploaded.single.path, '/cam/a/image.jpg');

      mgr.unregisterController(c);
      c.dispose();
    },
  );

  test('a path match is preferred and marks exactly that image', () {
    final c = FormFieldsMyImageController(
      initialImages: [
        MyImageResult(path: '/cam/a/image.jpg'),
        MyImageResult(path: '/cam/b/image.jpg'),
      ],
    );
    mgr.registerController(c);

    mgr.notifyUploadSuccess({
      'file': {'path': '/cam/b/image.jpg'},
    }, _resp('http://u/b'));

    expect(c.images[0].status, isNot(MyImageStatus.uploaded));
    expect(c.images[1].status, MyImageStatus.uploaded);
    expect(c.images[1].link, 'http://u/b');

    mgr.unregisterController(c);
    c.dispose();
  });
}
