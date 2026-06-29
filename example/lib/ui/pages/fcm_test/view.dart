import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ViewModel(),
      child: Consumer<ViewModel>(builder: (context, vm, _) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final payload = args is Map ? args : null;
        return Scaffold(
          appBar: AppBar(title: const Text('FCM Test')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (payload != null) ...[
                  Text('Notification payload:'),
                  const SizedBox(height: 8),
                  Text(payload.toString()),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: () async {
                    final ctx = context;
                    final token = await FCMService.instance.getToken();
                    if (!mounted) return;
                    if (!ctx.mounted) return;
                    await showDialog<void>(
                      context: ctx,
                      builder: (_) =>
                          AlertDialog(content: Text(token ?? 'No token')),
                    );
                  },
                  child: const Text('Show token'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {});
                  },
                  child: const Text('Init FCM (run initializer)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final ctx = context;
                    final messenger = ScaffoldMessenger.of(ctx);
                    await FCMService.instance.subscribeToTopic('news');
                    if (!mounted) return;
                    if (!ctx.mounted) return;
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Subscribed')));
                  },
                  child: const Text('Subscribe to topic "news"'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
