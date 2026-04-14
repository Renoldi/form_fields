import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';

void main() {
  testWidgets('guard returns task result on success', (tester) async {
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final service = AppDialogService(ctx);

    final result = await service.guard<int>(
      task: () async => 7,
      errorTitle: 'Error',
      mapError: (error) => (
        message: error.toString(),
        type: AppDialogType.server,
      ),
    );

    expect(result, 7);
    expect(find.text('Error'), findsNothing);
  });

  testWidgets('guard shows error dialog on failure', (tester) async {
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final service = AppDialogService(ctx);

    final result = await service.guard<int>(
      task: () async => throw StateError('boom'),
      errorTitle: 'Login Failed',
      mapError: (_) => (
        message: 'Cannot login',
        type: AppDialogType.authentication,
      ),
      okLabel: 'OK',
    );

    expect(result, isNull);

    await tester.pumpAndSettle();
    expect(find.text('Login Failed'), findsOneWidget);
    expect(find.text('Cannot login'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('guard can show blocking loading dialog', (tester) async {
    late BuildContext ctx;
    final completer = Completer<int>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final service = AppDialogService(ctx);

    unawaited(
      service.guard<int>(
        task: () => completer.future,
        errorTitle: 'Error',
        mapError: (error) => (
          message: error.toString(),
          type: AppDialogType.server,
        ),
        showBlockingLoading: true,
        loadingMessage: 'Signing in...',
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Signing in...'), findsOneWidget);

    completer.complete(1);
    await tester.pumpAndSettle();
    expect(find.text('Signing in...'), findsNothing);
  });
}
