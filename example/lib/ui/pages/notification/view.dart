import 'package:flutter/material.dart';
import 'presenter.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    final payload = (widget.payload ??
        ModalRoute.of(context)?.settings.arguments) as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payload != null) ...[
              Text('Payload:'),
              const SizedBox(height: 8),
              Text(payload.toString()),
              const SizedBox(height: 16),
            ],
            const Text('This page is opened when a notification is clicked.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
