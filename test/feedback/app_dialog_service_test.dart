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

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Login Failed'), findsOneWidget);
    expect(find.text('Cannot login'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pump(const Duration(milliseconds: 200));
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Signing in...'), findsNothing);
  });

  testWidgets('showLoading with allow back closes loading dialog', (
    tester,
  ) async {
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

    unawaited(
      service.showLoading(
        message: 'Processing...',
        loadingBackBehavior: AppDialogLoadingBackBehavior.allow,
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Processing...'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Processing...'), findsNothing);
  });

  testWidgets('showLoading with block back keeps loading dialog visible', (
    tester,
  ) async {
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

    unawaited(
      service.showLoading(
        message: 'Please wait...',
        loadingBackBehavior: AppDialogLoadingBackBehavior.block,
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Please wait...'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Please wait...'), findsOneWidget);

    service.hide();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('showLoading with confirmCancel can be canceled by back flow', (
    tester,
  ) async {
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

    unawaited(
      service.showLoading(
        message: 'Uploading...',
        loadingBackBehavior: AppDialogLoadingBackBehavior.confirmCancel,
        cancelTitle: 'Cancel Upload?',
        cancelLabel: 'Yes Cancel',
        stayLabel: 'Keep Uploading',
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Uploading...'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cancel Upload?'), findsOneWidget);
    expect(find.text('Yes Cancel'), findsOneWidget);

    await tester.tap(find.text('Yes Cancel'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Uploading...'), findsNothing);
  });
}
