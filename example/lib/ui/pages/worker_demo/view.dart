import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'view_model.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields/form_fields.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<ViewModel>(builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('workerDemo')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary status card for quick visibility
                  Card(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ValueListenableBuilder<dynamic>(
                        valueListenable:
                            WorkmanagerService.instance.statusListenable,
                        builder: (ctx, status, _) {
                          final last = WorkmanagerService.instance.lastRunAt;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Initialized: ${WorkmanagerService.instance.isInitialized}'),
                              ValueListenableBuilder<String?>(
                                valueListenable: WorkmanagerService
                                    .instance.lastLogListenable,
                                builder: (c, lastLog, __) =>
                                    Text('Last log: ${lastLog ?? '-'}'),
                              ),
                              if (last != null)
                                Text('Last run: ${last.toIso8601String()}'),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Background Worker (demo)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ValueListenableBuilder<int>(
                                valueListenable: WorkmanagerService
                                    .instance.registeredCountListenable,
                                builder: (rCtx, cnt, __) {
                                  final active = cnt > 0;
                                  return Chip(
                                    label: Text(
                                      active ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: active
                                            ? Colors.green[800]
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: active
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.12),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 0),
                                  );
                                },
                              ),
                            ],
                          ),
                          ValueListenableBuilder<dynamic>(
                              valueListenable:
                                  WorkmanagerService.instance.statusListenable,
                              builder: (ctx, status, _) {
                                final last =
                                    WorkmanagerService.instance.lastRunAt;
                                final statusText = status == null
                                    ? 'unknown'
                                    : status.toString();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status: $statusText'),
                                    ValueListenableBuilder<String?>(
                                      valueListenable: WorkmanagerService
                                          .instance.countdownListenable,
                                      builder: (c, cd, __) {
                                        if (cd == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6.0),
                                          child: Text('Next run in: $cd',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary)),
                                        );
                                      },
                                    ),
                                    if (last != null)
                                      Text(
                                          'Last run: ${last.toIso8601String()}'),
                                  ],
                                );
                              }),
                          const SizedBox(height: 12),
                          const SizedBox(height: 8),
                          Form(
                            key: vm.formKey,
                            child: Column(
                              children: [
                                FormFields<String>(
                                  onChanged: (val) {
                                    vm.post.title = val;
                                    vm.commit();
                                  },
                                  label: 'Title',
                                  currentValue: vm.post.title,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 8),
                                FormFields<String>(
                                  onChanged: (val) {
                                    vm.post.body = val;
                                    vm.commit();
                                  },
                                  label: 'Body',
                                  currentValue: vm.post.body,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 8),
                                AppButton(
                                  text: 'Submit',
                                  isLoading: vm.isLoading,
                                  onPressed: () async {
                                    if (!vm.formKey.currentState!.validate()) {
                                      return;
                                    }

                                    // Use logged-in user's id if available to
                                    // satisfy server validation (avoids 400).
                                    try {
                                      final appState =
                                          Provider.of<AppStateNotifier>(context,
                                              listen: false);
                                      vm.post.userId = appState.currentUser?.id;
                                    } catch (_) {}

                                    await vm.addPending();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.maybeOf(context)
                                        ?.showSnackBar(const SnackBar(
                                            content: Text('Submitted')));
                                  },
                                ),
                              ],
                            ),
                          ),
                          Wrap(spacing: 8, children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start periodic'),
                              onPressed: () async {
                                vm.setLoading(true);
                                // Reuse previously scheduled frequency if available,
                                // otherwise fall back to 1 hour default.
                                final freq = WorkmanagerService
                                        .instance.configuredFrequency ??
                                    const Duration(hours: 1);
                                await WorkmanagerService.instance
                                    .start(periodic: true, frequency: freq);
                                vm.setLoading(false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(SnackBar(
                                        content: Text(
                                            'Started periodic (${freq.inMinutes}m)')));
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              onPressed: () async {
                                // Re-initialize to refresh the initialized flag.
                                await WorkmanagerService.instance.initialize();
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(const SnackBar(
                                        content: Text('Refreshed')));
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.bolt),
                              label: const Text('Run worker now'),
                              onPressed: () async {
                                vm.setLoading(true);
                                // Ensure periodic worker is started so status
                                // becomes Active, then perform a foreground
                                // flush immediately.
                                var ok = false;
                                try {
                                  final freq = WorkmanagerService
                                          .instance.configuredFrequency ??
                                      const Duration(hours: 1);
                                  await WorkmanagerService.instance
                                      .start(periodic: true, frequency: freq);

                                  final handler = WorkmanagerService
                                      .instance.flushPendingHandler;
                                  if (handler != null) {
                                    try {
                                      await handler();
                                      ok = true;
                                    } catch (_) {
                                      ok = false;
                                    }
                                  } else {
                                    try {
                                      // If a periodic flush is currently active
                                      // we wait briefly for it to finish, then
                                      // run the foreground flush so "Run worker
                                      // now" provides an immediate effect.
                                      ok = await FlushApi
                                          .flushPendingSubmissions(
                                              waitIfFlushing: true,
                                              waitTimeout:
                                                  const Duration(seconds: 15));
                                    } catch (_) {
                                      ok = false;
                                    }
                                  }

                                  WorkmanagerService
                                          .instance.lastLogListenable.value =
                                      'runNow: started periodic (${freq.inMinutes}m) and foreground flush -> $ok';

                                  // Reload pending items to reflect any deletions
                                  try {
                                    await vm.loadPending();
                                  } catch (_) {}
                                } catch (e, st) {
                                  WorkmanagerService.instance.lastLogListenable
                                      .value = 'runNow: threw: $e\n$st';
                                }
                                vm.setLoading(false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Worker started and ran successfully'
                                        : 'Worker started; run failed'),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Run foreground flush'),
                              onPressed: () async {
                                try {
                                  WorkmanagerService.instance.lastLogListenable
                                      .value = 'foregroundFlush invoked';
                                  final handler = WorkmanagerService
                                      .instance.flushPendingHandler;
                                  bool ok2 = false;
                                  if (handler != null) {
                                    try {
                                      await handler();
                                      ok2 = true;
                                    } catch (_) {
                                      ok2 = false;
                                    }
                                  } else {
                                    try {
                                      ok2 = await FlushApi
                                          .flushPendingSubmissions();
                                    } catch (_) {
                                      ok2 = false;
                                    }
                                  }
                                  WorkmanagerService
                                          .instance.lastLogListenable.value =
                                      'foregroundFlush completed -> ${ok2 ? 'success' : 'failure'}';
                                  // Refresh pending list after a foreground flush
                                  try {
                                    await vm.loadPending();
                                  } catch (_) {}
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(SnackBar(
                                          content: Text(ok2
                                              ? 'Foreground flush success'
                                              : 'Foreground flush failed')));
                                } catch (e, st) {
                                  WorkmanagerService.instance.lastLogListenable
                                      .value = 'foregroundFlush threw: $e\n$st';
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(SnackBar(
                                          content: Text('Flush threw: $e')));
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                              onPressed: () async {
                                await WorkmanagerService.instance.stop();
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(const SnackBar(
                                        content: Text('Stopped')));
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text('Run background task'),
                              onPressed: () async {
                                vm.setLoading(true);
                                try {
                                  final err = await WorkmanagerService.instance
                                      .runOnceNowDetailed(taskName: 'dbg_now');
                                  WorkmanagerService
                                          .instance.lastLogListenable.value =
                                      'run background task -> ${err ?? 'ok'}';
                                  // Give a short delay for logs to populate
                                  await Future.delayed(
                                      const Duration(seconds: 2));
                                  try {
                                    await vm.loadPending();
                                  } catch (_) {}
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(SnackBar(
                                    content: Text(err == null
                                        ? 'Background task scheduled'
                                        : 'Background task error: $err'),
                                  ));
                                } catch (e, st) {
                                  WorkmanagerService.instance.lastLogListenable
                                      .value = 'run background threw: $e\n$st';
                                }
                                vm.setLoading(false);
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.stop_circle),
                              label: const Text('Stop All'),
                              onPressed: () async {
                                // Explicitly stop all registered tasks and
                                // cancel auto-send.
                                await WorkmanagerService.instance.stop();
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(const SnackBar(
                                        content: Text('Stopped all')));
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.article_outlined),
                              label: const Text('Show logs'),
                              onPressed: () async {
                                final logs = WorkmanagerService
                                    .instance.recentLogs.reversed
                                    .toList();
                                if (!context.mounted) return;
                                await showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Recent logs'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 300,
                                      child: logs.isEmpty
                                          ? const Center(
                                              child: Text('- no logs -'))
                                          : ListView.separated(
                                              itemCount: logs.length,
                                              separatorBuilder: (_, __) =>
                                                  const Divider(),
                                              itemBuilder: (c, i) => ListTile(
                                                dense: true,
                                                title: Text(logs[i]),
                                              ),
                                            ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          // Clear logs and close dialog.
                                          WorkmanagerService.instance
                                              .clearLogs();
                                          if (!context.mounted) return;
                                          Navigator.of(ctx).pop();
                                          ScaffoldMessenger.maybeOf(context)
                                              ?.showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Logs cleared')));
                                        },
                                        child: const Text('Clear'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final joined = logs.join('\n');
                                          await Clipboard.setData(
                                              ClipboardData(text: joined));
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.maybeOf(context)
                                              ?.showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Logs copied')));
                                        },
                                        child: const Text('Copy'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear logs'),
                              onPressed: () async {
                                WorkmanagerService.instance.clearLogs();
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(const SnackBar(
                                        content: Text('Logs cleared')));
                              },
                            ),
                          ]),
                          const Divider(),
                          const Text('Pending submissions',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          FutureBuilder<void>(
                            future: null,
                            builder: (ctx, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (vm.pending.isEmpty) {
                                return const Text('No pending items');
                              }
                              return Column(
                                children: vm.pending.map((row) {
                                  final id = row['id'] as int?;
                                  final status =
                                      row['status']?.toString() ?? '';
                                  final payloadRaw = row['payload'];
                                  final payload = payloadRaw is String
                                      ? payloadRaw
                                      : (payloadRaw is Map ||
                                              payloadRaw is List)
                                          ? json.encode(payloadRaw)
                                          : payloadRaw?.toString() ?? '';
                                  return ListTile(
                                    title: Text(payload),
                                    subtitle: Text(
                                        'status: ${status.isNotEmpty ? status : '-'} • id: ${id ?? '-'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.play_arrow),
                                          tooltip: 'Run this pending now',
                                          onPressed: id == null
                                              ? null
                                              : () async {
                                                  try {
                                                    WorkmanagerService
                                                            .instance
                                                            .lastLogListenable
                                                            .value =
                                                        'runPending: id=$id';
                                                  } catch (_) {}
                                                  try {
                                                    await FlushApi
                                                        .flushPendingSubmissionById(
                                                            id);
                                                    // Reload pending list after attempt
                                                    await vm.loadPending();
                                                  } catch (e, st) {
                                                    try {
                                                      WorkmanagerService
                                                              .instance
                                                              .lastLogListenable
                                                              .value =
                                                          'runPending threw: $e\n$st';
                                                    } catch (_) {}
                                                  }
                                                },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: id == null
                                              ? null
                                              : () async {
                                                  await vm.removePending(id);
                                                },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
