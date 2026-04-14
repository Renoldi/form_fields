import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';

void main() {
  group('AppDialogService (fast unit)', () {
    test('defaultErrorMapper maps error to server type', () {
      final mapped = AppDialogService.defaultErrorMapper(StateError('boom'));

      expect(mapped.type, AppDialogType.server);
      expect(mapped.message, contains('boom'));
    });
  });

  group('AppGlobalDialogService (fast unit)', () {
    test('throws when used before configured', () {
      AppGlobalDialogService.instance.reset();

      expect(
        () => AppGlobalDialogService.instance.showInfo(
          title: 'Info',
          message: 'Message',
        ),
        throwsStateError,
      );
    });

    test('throws again after configure then reset', () {
      final navKey = GlobalKey<NavigatorState>();

      AppGlobalDialogService.instance.configure(navKey);
      AppGlobalDialogService.instance.reset();

      expect(
        () => AppGlobalDialogService.instance.showSuccess(
          title: 'Done',
          message: 'Message',
        ),
        throwsStateError,
      );
    });
  });
}
