import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/controllers/map_controller.dart';

void main() {
  test('remove() clears the per-id settings kept for a map', () {
    const id = 'registry_test_map';

    FormFieldsMapController.setPlaybackAutoStart(id, true);
    FormFieldsMapController.setNotifyCenterDuringPlayback(id, true);
    expect(FormFieldsMapController.getPlaybackAutoStart(id), isTrue);
    expect(FormFieldsMapController.getNotifyCenterDuringPlayback(id), isTrue);

    FormFieldsMapController.remove(id);

    // A removed entry reads back as its default, so nothing from the old map
    // is left behind.
    expect(FormFieldsMapController.getPlaybackAutoStart(id), isFalse);
    expect(FormFieldsMapController.getNotifyCenterDuringPlayback(id), isFalse);
  });

  test('remove() does not touch other maps', () {
    const kept = 'registry_test_kept';
    const gone = 'registry_test_gone';

    FormFieldsMapController.setPlaybackAutoStart(kept, true);
    FormFieldsMapController.setPlaybackAutoStart(gone, true);
    FormFieldsMapController.remove(gone);

    expect(FormFieldsMapController.getPlaybackAutoStart(kept), isTrue);
    FormFieldsMapController.setPlaybackAutoStart(kept, false);
  });
}
