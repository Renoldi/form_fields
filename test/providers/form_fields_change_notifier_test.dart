import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/state/image_field_states.dart';
import 'package:form_fields/src/models/myimage_result.dart';
import 'package:form_fields/src/state/form_fields_change_notifier.dart';

class _Counter extends FormFieldsChangeNotifier {}

void main() {
  test('scheduleNotify collapses a burst into one notification', () async {
    final notifier = _Counter();
    addTearDown(notifier.dispose);
    var calls = 0;
    notifier.addListener(() => calls++);

    notifier.scheduleNotify();
    notifier.scheduleNotify();
    notifier.scheduleNotify();
    expect(calls, 0);

    await Future<void>.delayed(notifier.notifyDebounce * 2);
    expect(calls, 1);
  });

  test('notifySafely notifies immediately when called outside a build', () {
    final notifier = _Counter();
    addTearDown(notifier.dispose);
    var calls = 0;
    notifier.addListener(() => calls++);

    notifier.notifySafely();

    expect(calls, 1);
  });

  test('dispose cancels a pending debounced notification', () async {
    final notifier = _Counter();
    var calls = 0;
    notifier.addListener(() => calls++);

    notifier.scheduleNotify();
    notifier.dispose();
    await Future<void>.delayed(notifier.notifyDebounce * 2);

    expect(calls, 0);
  });

  // ── Shared upload progress (FormFieldsUploadProgressMixin) ──

  for (final make in <String, FormFieldsUploadProgressMixin Function()>{
    'live camera': FormFieldsLiveCameraCaptureProvider.new,
    'signature pad': FormFieldsSignaturePadProvider.new,
  }.entries) {
    group('${make.key} upload progress', () {
      test('starts idle', () {
        final p = make.value();
        expect(p.isUploading, isFalse);
        expect(p.uploadProgress, isNull);
      });

      test('startUpload makes it uploading with the initial value', () {
        final p = make.value()..startUpload(initialProgress: 0.02);
        expect(p.isUploading, isTrue);
        expect(p.uploadProgress, 0.02);
      });

      test('setUploadProgress clamps the value to 0..1', () {
        final p = make.value()..startUpload();
        p.setUploadProgress(1.7);
        expect(p.uploadProgress, 1.0);
        p.setUploadProgress(-0.3);
        expect(p.uploadProgress, 0.0);
      });

      test('completeUpload sets 100% and keeps uploading state', () {
        final p = make.value()..startUpload();
        p.completeUpload();
        expect(p.uploadProgress, 1.0);
        expect(p.isUploading, isTrue);
      });

      test('clearUpload returns to idle', () {
        final p = make.value()..startUpload(initialProgress: 0.5);
        p.clearUpload();
        expect(p.isUploading, isFalse);
        expect(p.uploadProgress, isNull);
      });

      test('every change notifies listeners', () {
        final p = make.value();
        var calls = 0;
        p.addListener(() => calls++);
        p.startUpload();
        p.setUploadProgress(0.4);
        p.completeUpload();
        p.clearUpload();
        expect(calls, 4);
      });
    });
  }

  group('handler slots', () {
    test('a slot is empty until a handler is registered', () {
      final slot = FormFieldsHandlerSlot<VoidCallback>();
      expect(slot.handler, isNull);
    });

    test('register and unregister', () {
      final slot = FormFieldsHandlerSlot<VoidCallback>();
      var calls = 0;
      slot.register(() => calls++);
      slot.handler!.call();
      expect(calls, 1);
      slot.unregister();
      expect(slot.handler, isNull);
    });

    test('a later register replaces the earlier handler', () {
      final slot = FormFieldsHandlerSlot<VoidCallback>();
      var first = 0, second = 0;
      slot.register(() => first++);
      slot.register(() => second++);
      slot.handler!.call();
      expect((first, second), (0, 1));
    });

    test(
      'my-image controller: capture and reset go to the registered widget',
      () async {
        final c = FormFieldsMyImageController();
        addTearDown(c.dispose);
        expect(await c.capture(), isNull, reason: 'no widget attached');
        c.resetCapture(); // no-op without a widget

        var reset = 0;
        c.registerCaptureHandler(() async => MyImageResult(), () => reset++);
        expect(await c.capture(), isNotNull);
        c.resetCapture();
        expect(reset, 1);

        c.unregisterCaptureHandler();
        expect(await c.capture(), isNull);
      },
    );

    test('my-image controller: pickImage forwards the source', () async {
      final c = FormFieldsMyImageController();
      addTearDown(c.dispose);
      String? seen;
      c.registerPickImageHandler((source) async => seen = source);
      await c.pickImage(source: 'camera');
      expect(seen, 'camera');
      c.unregisterPickImageHandler();
      await c.pickImage(source: 'gallery');
      expect(seen, 'camera', reason: 'unregistered handler must not run');
    });

    test(
      'signature controller: clearWidget runs the registered clear handler',
      () {
        final c = FormFieldsSignaturePadController();
        addTearDown(c.dispose);
        c.clearWidget(); // no-op without a widget
        var cleared = 0;
        c.registerClearHandler(() => cleared++);
        c.clearWidget();
        expect(cleared, 1);
        c.unregisterClearHandler();
        c.clearWidget();
        expect(cleared, 1);
      },
    );
  });
}
