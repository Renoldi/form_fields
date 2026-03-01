import 'package:flutter/material.dart';
import 'package:form_fields_example/localization/example_localizations.dart';

Future<void> showBlockingLoading(
  BuildContext context, {
  String? message,
}) {
  final l10n = ExampleLocalizations.of(context);
  final displayMessage = message ?? l10n.get('loading');
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await showExitConfirmDialog(context);
        },
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      displayMessage,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void hideBlockingDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}

Future<void> showBlockingResult(
  BuildContext context, {
  required String title,
  required String message,
  required bool isSuccess,
}) {
  final color = isSuccess ? Colors.green : Colors.red;
  final l10n = ExampleLocalizations.of(context);

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await showExitConfirmDialog(context);
        },
        child: AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(l10n.get('ok')),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showExitConfirmDialog(BuildContext context) {
  final l10n = ExampleLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(l10n.get('exitApplication')),
          ],
        ),
        content: Text(
          l10n.get('exitWarning'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(l10n.get('stay')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // Close the app by popping the root navigator.
              Navigator.of(context, rootNavigator: true).maybePop();
            },
            child: Text(l10n.get('exit')),
          ),
        ],
      );
    },
  );
}
