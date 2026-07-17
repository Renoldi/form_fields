import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presenter.dart';
import 'package:form_fields/notifications.dart';

class View extends PresenterState {
  @override
  void initState() {
    super.initState();
    // If this presenter was opened with a payload, attempt to mark the
    // corresponding DB row as read. Prefer an explicit `id`, otherwise try
    // to locate the row by `title`+`body` with short retries to tolerate
    // background-insert races.
    try {
      final p = widget.payload;
      if (p != null) {
        // If we have an explicit id, mark it immediately.
        try {
          if (p.containsKey('id')) {
            final id = p['id'];
            if (id is int) {
              NotificationRepository.instance.markAsRead(id);
            } else if (id is String) {
              final parsed = int.tryParse(id);
              if (parsed != null) {
                NotificationRepository.instance.markAsRead(parsed);
                return;
              }
            }
          }
        } catch (_) {}

        // Fallback: if no id was supplied, try to locate the DB row by
        // matching title+body. Use short retries to tolerate background
        // insert races.
        try {
          final title = p['title']?.toString() ?? '';
          final body = p['body']?.toString() ?? '';
          if (title.isNotEmpty && body.isNotEmpty) {
            Future<void>(() async {
              final delays = [0, 200, 500, 1000];
              for (final ms in delays) {
                try {
                  if (ms > 0) await Future.delayed(Duration(milliseconds: ms));
                  final found = await NotificationRepository.instance
                      .findRecentByTitleBody(title, body, 60000);
                  if (found != null && found.id != null) {
                    await NotificationRepository.instance.markAsRead(found.id!);
                    break;
                  }
                } catch (_) {}
              }
            });
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // If this Presenter was given a payload, show a professional detail view.
    final payload = widget.payload;
    if (payload != null && payload.isNotEmpty) {
      final title = payload['title']?.toString() ?? 'Notification';
      final body = payload['body']?.toString() ?? '';
      final rawData = payload['data'];

      Map<String, dynamic> normalizeData(dynamic d) {
        if (d == null) return {};
        if (d is Map<String, dynamic>) return d;
        if (d is String) {
          // Try JSON first
          try {
            final decoded = json.decode(d);
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (_) {}
          // Fall back to simple key:value parsing like "k1:v1,k2:v2"
          try {
            final cleaned = d.replaceAll(RegExp(r'[{}]'), '');
            final parts = cleaned.split(',');
            final out = <String, dynamic>{};
            for (final p in parts) {
              final idx = p.indexOf(':');
              if (idx <= 0) continue;
              final k = p.substring(0, idx).trim();
              final v = p.substring(idx + 1).trim();
              if (k.isNotEmpty) out[k] = v;
            }
            // Normalize values: unwrap bracketed url forms and extract first URL if present
            final urlRe = RegExp(r'(https?:\/\/[^)\]\s,]+)');
            out.updateAll((key, val) {
              if (val is String) {
                var s = val;
                // remove surrounding []() or extra parentheses
                s = s.replaceAll(RegExp(r"^\[|\]"), '');
                s = s.replaceAll(RegExp(r"\(\)"), '');
                // attempt to extract an http(s) url
                final m = urlRe.firstMatch(s);
                if (m != null) {
                  return m.group(1) ?? s;
                }
                return s;
              }
              return val;
            });
            return out;
          } catch (_) {
            return {};
          }
        }
        return {};
      }

      final data = normalizeData(rawData);
      final imageUrl = data['image']?.toString();

      String prettyData() {
        try {
          return const JsonEncoder.withIndent('  ').convert(data);
        } catch (_) {
          return data.toString();
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Copy details',
              icon: const Icon(Icons.copy),
              onPressed: () async {
                final payloadText = StringBuffer();
                payloadText.writeln(title);
                payloadText.writeln();
                payloadText.writeln(body);
                payloadText.writeln();
                payloadText.writeln(prettyData());
                await Clipboard.setData(
                  ClipboardData(text: payloadText.toString()),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Details copied')),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Hero(
                            tag:
                                (payload['heroTag'] as String?) ??
                                'notification-img-${payload['id'] ?? payload['data'] ?? ''}',
                            child: Image.network(
                              imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                height: 180,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              body,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Data', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    prettyData(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () async {
              await NotificationRepository.instance.markAllRead();
            },
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Mark all read',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: NotificationRepository.instance.notificationsStream,
        builder: (context, snap) {
          if (!snap.hasData) {
            // trigger an initial emit
            NotificationRepository.instance.all().then((_) {});
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final it = items[index];
              return ListTile(
                onTap: () async {
                  if (it.read == 0 && it.id != null) {
                    await NotificationRepository.instance.markAsRead(it.id!);
                  }
                  // Avoid using BuildContext across async gaps: ensure still mounted
                  if (!context.mounted) return;

                  // Use context after mounted check
                  final heroTag = 'notification-img-${it.id ?? it.createdAt}';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Presenter(
                        payload: {
                          'id': it.id,
                          'title': it.title,
                          'body': it.body,
                          'data': it.data,
                          'heroTag': heroTag,
                        },
                      ),
                      settings: RouteSettings(
                        arguments: {
                          'id': it.id,
                          'title': it.title,
                          'body': it.body,
                          'data': it.data,
                          'heroTag': heroTag,
                        },
                      ),
                    ),
                  );
                },
                leading: Builder(
                  builder: (_) {
                    final imageUrl = (it.data ?? {})['image']?.toString();
                    final heroTag = 'notification-img-${it.id ?? it.createdAt}';
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      return Hero(
                        tag: heroTag,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                      );
                    }
                    return const CircleAvatar(child: Icon(Icons.notifications));
                  },
                ),
                title: Text(it.title ?? '(No title)'),
                subtitle: Text(it.body ?? ''),
                trailing: it.read == 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.check, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }
}
