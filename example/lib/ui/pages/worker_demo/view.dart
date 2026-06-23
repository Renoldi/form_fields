import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_fields_example/data/models/post.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/src/service/flush_service.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:flutter/services.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<ViewModel>(builder: (context, vm, _) {
        final appState = context.watch<AppStateNotifier>();

        // Keep `vm.post.userId` in sync with the currently signed-in user.
        final currentUserId = appState.currentUser?.id;
        if (currentUserId != null &&
            (vm.post.userId == null || vm.post.userId == 1)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.post.userId = currentUserId;
            vm.commit();
          });
        }

        Widget spinnerSmall() => SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.onPrimary),
              ),
            );

        // Reusable styles for a cleaner, consistent UI
        final primaryButtonStyle = ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(64, 40),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14),
        );

        final outlinedButtonStyle = OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(64, 40),
          side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12)),
          textStyle: const TextStyle(fontSize: 14),
        );

        final inputBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        );

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
                  // Top card: status + controls
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<dynamic>(
                            valueListenable:
                                ForegroundTaskService.instance.statusListenable,
                            builder: (ctx, status, _) {
                              final last =
                                  ForegroundTaskService.instance.lastRunAt;
                              final statusText = status == null
                                  ? 'unknown'
                                  : status.toString();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status: $statusText'),
                                  ValueListenableBuilder<String?>(
                                    valueListenable: ForegroundTaskService
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
                                    Text('Last run: ${last.toIso8601String()}'),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Primary control buttons
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            ElevatedButton.icon(
                              style: primaryButtonStyle,
                              icon: vm.isLoading
                                  ? spinnerSmall()
                                  : const Icon(Icons.play_arrow),
                              label: const Text('Start periodic'),
                              onPressed: vm.isLoading
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      vm.setLoading(true);
                                      final freq = ForegroundTaskService
                                              .instance.configuredFrequency ??
                                          const Duration(hours: 1);
                                      await ForegroundTaskService.instance
                                          .start(
                                              periodic: true, frequency: freq);
                                      vm.setLoading(false);
                                      if (!context.mounted) return;
                                      messenger?.showSnackBar(SnackBar(
                                          content: Text(
                                              'Started periodic (${freq.inMinutes}m)')));
                                    },
                            ),
                            ElevatedButton.icon(
                              style: primaryButtonStyle,
                              icon: vm.isLoading
                                  ? spinnerSmall()
                                  : const Icon(Icons.playlist_play),
                              label: const Text('Start All'),
                              onPressed: vm.isLoading
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text('Confirm'),
                                              content: const Text(
                                                  'Start all workers now?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child:
                                                        const Text('Cancel')),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child: const Text('Start')),
                                              ],
                                            );
                                          });
                                      if (confirm != true) return;
                                      vm.setLoading(true);
                                      try {
                                        await ForegroundTaskService.instance
                                            .startAll();
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(const SnackBar(
                                            content:
                                                Text('Started all workers')));
                                      } catch (e) {
                                        ForegroundTaskService
                                            .instance
                                            .lastLogListenable
                                            .value = 'start all failed: $e';
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(SnackBar(
                                            content:
                                                Text('Start all failed: $e')));
                                      } finally {
                                        vm.setLoading(false);
                                      }
                                    },
                            ),
                            ElevatedButton.icon(
                              style: primaryButtonStyle,
                              icon: vm.isLoading
                                  ? spinnerSmall()
                                  : const Icon(Icons.stop),
                              label: const Text('Stop All'),
                              onPressed: vm.isLoading
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text('Confirm'),
                                              content: const Text(
                                                  'Stop all workers?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child:
                                                        const Text('Cancel')),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child: const Text('Stop')),
                                              ],
                                            );
                                          });
                                      if (confirm != true) return;
                                      vm.setLoading(true);
                                      try {
                                        await ForegroundTaskService.instance
                                            .stop();
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(const SnackBar(
                                            content:
                                                Text('Stopped all workers')));
                                      } catch (e) {
                                        try {
                                          ForegroundTaskService
                                              .instance
                                              .lastLogListenable
                                              .value = 'stop all failed: $e';
                                        } catch (_) {}
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(SnackBar(
                                            content:
                                                Text('Stop all failed: $e')));
                                      } finally {
                                        vm.setLoading(false);
                                      }
                                    },
                            ),
                            ElevatedButton.icon(
                              style: primaryButtonStyle,
                              icon: vm.isLoading
                                  ? spinnerSmall()
                                  : const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                              onPressed: vm.isLoading
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      await ForegroundTaskService.instance
                                          .initialize();
                                      if (!context.mounted) return;
                                      messenger?.showSnackBar(const SnackBar(
                                          content: Text('Refreshed')));
                                    },
                            ),
                            ElevatedButton.icon(
                              style: primaryButtonStyle,
                              icon: vm.isLoading
                                  ? spinnerSmall()
                                  : const Icon(Icons.bolt),
                              label: const Text('Run worker now'),
                              onPressed: vm.isLoading
                                  ? null
                                  : () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      vm.setLoading(true);
                                      var ok = false;
                                      try {
                                        final freq = ForegroundTaskService
                                                .instance.configuredFrequency ??
                                            const Duration(hours: 1);
                                        await ForegroundTaskService.instance
                                            .start(
                                                periodic: true,
                                                frequency: freq);
                                        final handler = ForegroundTaskService
                                            .instance.foregroundFlushHandler;
                                        if (handler != null) {
                                          try {
                                            await handler();
                                            ok = true;
                                          } catch (_) {
                                            ok = false;
                                          }
                                        } else {
                                          try {
                                            ok = await flushPendingSubmissions(
                                                waitIfFlushing: true,
                                                waitTimeout: const Duration(
                                                    seconds: 15));
                                          } catch (_) {
                                            ok = false;
                                          }
                                        }
                                        ForegroundTaskService.instance
                                                .lastLogListenable.value =
                                            'runNow: started periodic (${freq.inMinutes}m) and foreground flush -> $ok';
                                        try {
                                          await vm.loadPending();
                                        } catch (_) {}
                                      } catch (e, st) {
                                        ForegroundTaskService
                                            .instance
                                            .lastLogListenable
                                            .value = 'runNow: threw: $e\n$st';
                                      }
                                      vm.setLoading(false);
                                      if (!context.mounted) return;
                                      messenger?.showSnackBar(SnackBar(
                                          content: Text(ok
                                              ? 'Worker started and ran successfully'
                                              : 'Worker started; run failed')));
                                    },
                            ),
                            ElevatedButton.icon(
                              style: primaryButtonStyle,
                              icon: vm.isLoading
                                  ? spinnerSmall()
                                  : const Icon(Icons.send),
                              label: const Text('Run foreground flush'),
                              onPressed: vm.isLoading
                                  ? null
                                  : () async {
                                      try {
                                        ForegroundTaskService
                                            .instance
                                            .lastLogListenable
                                            .value = 'foregroundFlush invoked';
                                        final handler = ForegroundTaskService
                                            .instance.foregroundFlushHandler;
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
                                            ok2 =
                                                await flushPendingSubmissions();
                                          } catch (_) {
                                            ok2 = false;
                                          }
                                        }
                                        ForegroundTaskService.instance
                                                .lastLogListenable.value =
                                            'foregroundFlush completed -> ${ok2 ? 'success' : 'failure'}';
                                        try {
                                          await vm.loadPending();
                                        } catch (_) {}
                                        if (!context.mounted) return;
                                        final messenger =
                                            ScaffoldMessenger.maybeOf(context);
                                        messenger?.showSnackBar(SnackBar(
                                            content: Text(ok2
                                                ? 'Foreground flush success'
                                                : 'Foreground flush failed')));
                                      } catch (e, st) {
                                        ForegroundTaskService.instance
                                                .lastLogListenable.value =
                                            'foregroundFlush threw: $e\n$st';
                                        if (!context.mounted) return;
                                        final messenger =
                                            ScaffoldMessenger.maybeOf(context);
                                        messenger?.showSnackBar(SnackBar(
                                            content: Text('Flush threw: $e')));
                                      }
                                    },
                            ),
                            ElevatedButton.icon(
                              style: primaryButtonStyle,
                              icon: vm.isLoading
                                  ? spinnerSmall()
                                  : const Icon(Icons.bug_report),
                              label: const Text('Show debug'),
                              onPressed: vm.isLoading
                                  ? null
                                  : () {
                                      final meta = ForegroundTaskService
                                          .instance.taskMetadata;
                                      final logs = ForegroundTaskService
                                          .instance.recentLogs;
                                      showDialog<void>(
                                          context: context,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text(
                                                  'ForegroundTask Debug'),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                        'Task metadata:'),
                                                    const SizedBox(height: 8),
                                                    Text(meta.entries
                                                        .map((e) =>
                                                            '${e.key}: scheduledAt=${e.value['scheduledAt']}, freq_s=${e.value['frequencySeconds']}')
                                                        .join('\n')),
                                                    const SizedBox(height: 12),
                                                    const Text('Recent logs:'),
                                                    const SizedBox(height: 8),
                                                    Text(logs.join('\n')),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx).pop(),
                                                    child: const Text('Close'))
                                              ],
                                            );
                                          });
                                    },
                            ),
                          ]),

                          const SizedBox(height: 12),

                          // Create Post card (clean)
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: vm.formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Create Post',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    FormFields<String>(
                                      key: ValueKey(
                                          'title-${vm.post.title ?? ''}'),
                                      label: 'Title',
                                      currentValue: vm.post.title ?? '',
                                      inputDecoration: InputDecoration(
                                        labelText: 'Title',
                                        prefixIcon: const Icon(Icons.title),
                                        filled: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 12),
                                        border: inputBorder,
                                        enabledBorder: inputBorder,
                                        focusedBorder: inputBorder.copyWith(
                                            borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 2)),
                                      ),
                                      onChanged: (v) {
                                        vm.post.title = v;
                                        vm.commit();
                                      },
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? 'Title required'
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    FormFields<String>(
                                      key: ValueKey(
                                          'body-${vm.post.body ?? ''}'),
                                      label: 'Body',
                                      currentValue: vm.post.body ?? '',
                                      multiLine: 3,
                                      inputDecoration: InputDecoration(
                                        labelText: 'Body',
                                        prefixIcon: const Icon(Icons.article),
                                        filled: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 12),
                                        border: inputBorder,
                                        enabledBorder: inputBorder,
                                        focusedBorder: inputBorder.copyWith(
                                            borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 2)),
                                      ),
                                      onChanged: (v) {
                                        vm.post.body = v;
                                        vm.commit();
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(
                                          child: FormFields<int>(
                                              key: ValueKey(
                                                  'userId-${vm.post.userId ?? appState.currentUser?.id ?? ''}'),
                                              label: 'User ID',
                                              currentValue: vm.post.userId ??
                                                  appState.currentUser?.id ??
                                                  1,
                                              inputDecoration: InputDecoration(
                                                labelText: 'User ID',
                                                prefixIcon:
                                                    const Icon(Icons.person),
                                                filled: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 12),
                                                border: inputBorder,
                                                enabledBorder: inputBorder,
                                                focusedBorder:
                                                    inputBorder.copyWith(
                                                        borderSide: BorderSide(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            width: 2)),
                                              ),
                                              onChanged: (v) {
                                                vm.post.userId = v;
                                                vm.commit();
                                              })),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: FormFields<String>(
                                              key: ValueKey(
                                                  'tags-${vm.post.tags?.join(',') ?? ''}'),
                                              label: 'Tags (comma)',
                                              currentValue:
                                                  vm.post.tags?.join(',') ?? '',
                                              inputDecoration: InputDecoration(
                                                labelText: 'Tags (comma)',
                                                prefixIcon:
                                                    const Icon(Icons.tag),
                                                filled: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 12),
                                                border: inputBorder,
                                                enabledBorder: inputBorder,
                                                focusedBorder:
                                                    inputBorder.copyWith(
                                                        borderSide: BorderSide(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            width: 2)),
                                              ),
                                              onChanged: (v) {
                                                vm.post.tags = (v)
                                                    .split(',')
                                                    .map((s) => s.trim())
                                                    .where((s) => s.isNotEmpty)
                                                    .toList();
                                                vm.commit();
                                              })),
                                    ]),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      Expanded(
                                          child: ElevatedButton.icon(
                                              style: primaryButtonStyle,
                                              icon: vm.isLoading
                                                  ? spinnerSmall()
                                                  : const Icon(Icons.queue),
                                              label: const Text('Add Pending'),
                                              onPressed: vm.isLoading
                                                  ? null
                                                  : () async {
                                                      final messenger =
                                                          ScaffoldMessenger
                                                              .maybeOf(context);
                                                      if (vm.formKey
                                                              .currentState
                                                              ?.validate() ==
                                                          false) {
                                                        return;
                                                      }
                                                      vm.setLoading(true);
                                                      try {
                                                        vm.post.userId ??=
                                                            appState.currentUser
                                                                    ?.id ??
                                                                1;
                                                        await vm.addPending();
                                                        await vm.loadPending();
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        messenger?.showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Added to pending')));
                                                      } catch (e) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        messenger?.showSnackBar(
                                                            SnackBar(
                                                                content: Text(
                                                                    'Failed to add: $e')));
                                                      } finally {
                                                        vm.setLoading(false);
                                                      }
                                                    })),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                          style: primaryButtonStyle,
                                          icon: vm.isLoading
                                              ? spinnerSmall()
                                              : const Icon(Icons.send),
                                          label: const Text('Submit Now'),
                                          onPressed: vm.isLoading
                                              ? null
                                              : () async {
                                                  final messenger =
                                                      ScaffoldMessenger.maybeOf(
                                                          context);
                                                  if (vm.formKey.currentState
                                                          ?.validate() ==
                                                      false) {
                                                    return;
                                                  }
                                                  vm.setLoading(true);
                                                  try {
                                                    vm.post.userId ??= appState
                                                            .currentUser?.id ??
                                                        1;
                                                    final res = await Post.add(
                                                        post: vm.post);
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    if (res != null) {
                                                      vm.post = Post();
                                                      await vm.loadPending();
                                                      vm.commit();
                                                      messenger?.showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Submitted successfully')));
                                                    } else {
                                                      messenger?.showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Submit failed')));
                                                    }
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    messenger?.showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Submit threw: $e')));
                                                  } finally {
                                                    vm.setLoading(false);
                                                  }
                                                }),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                          onPressed: vm.isLoading
                                              ? null
                                              : () {
                                                  vm.post = Post();
                                                  vm.commit();
                                                },
                                          child: const Text('Clear')),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Per-task controls. Listen to `registeredCountListenable`
                          // as well as `perTaskCountdownListenable` so the UI updates
                          // immediately when a task is started/stopped (fixes the
                          // play/stop toggle not updating on manual stop).
                          ValueListenableBuilder<int>(
                              valueListenable: ForegroundTaskService
                                  .instance.registeredCountListenable,
                              builder: (ctx2, _, __) {
                                return ValueListenableBuilder<
                                        Map<String, String?>>(
                                    valueListenable: ForegroundTaskService
                                        .instance.perTaskCountdownListenable,
                                    builder: (ctx, perMap, __) {
                                      final defs = ForegroundTaskService
                                          .instance.providedWorkerDefinitions;
                                      if (defs.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: defs.map<Widget>((d) {
                                            final name = d['name'] as String;
                                            final freq =
                                                d['frequency'] as Duration;
                                            final cd = perMap[name];
                                            final isRegistered =
                                                ForegroundTaskService.instance
                                                    .registeredTaskNames
                                                    .contains(name);
                                            return ListTile(
                                                dense: true,
                                                title: Text(name),
                                                subtitle: Text(
                                                    'freq: ${freq.inSeconds}s • next: ${cd ?? '-'}'),
                                                trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                          icon: const Icon(
                                                              Icons.play_arrow),
                                                          tooltip:
                                                              'Start $name',
                                                          onPressed:
                                                              isRegistered
                                                                  ? null
                                                                  : () async {
                                                                      try {
                                                                        await ForegroundTaskService
                                                                            .instance
                                                                            .startWorkerByName(name);
                                                                      } catch (_) {}
                                                                    }),
                                                      IconButton(
                                                          icon: const Icon(
                                                              Icons.stop),
                                                          tooltip: 'Stop $name',
                                                          onPressed:
                                                              isRegistered
                                                                  ? () async {
                                                                      try {
                                                                        await ForegroundTaskService
                                                                            .instance
                                                                            .stopWorkerByName(name);
                                                                      } catch (_) {}
                                                                    }
                                                                  : null)
                                                    ]));
                                          }).toList());
                                    });
                              }),

                          const SizedBox(height: 8),

                          // Utilities row
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    style: outlinedButtonStyle,
                                    icon: vm.isLoading
                                        ? spinnerSmall()
                                        : const Icon(Icons.table_rows_outlined),
                                    label: const Text('Empty Table'),
                                    onPressed: vm.isLoading
                                        ? null
                                        : () async {
                                            final messenger =
                                                ScaffoldMessenger.maybeOf(
                                                    context);
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Confirm'),
                                                content: const Text(
                                                    'Delete all pending submissions?'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(false),
                                                      child:
                                                          const Text('Cancel')),
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(true),
                                                      child:
                                                          const Text('Delete')),
                                                ],
                                              ),
                                            );
                                            if (ok != true) return;
                                            vm.setLoading(true);
                                            try {
                                              await vm.removeAllPending();
                                              if (!context.mounted) return;
                                              messenger?.showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Pending table emptied')));
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              messenger?.showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Delete failed: $e')));
                                            } finally {
                                              vm.setLoading(false);
                                            }
                                          },
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: outlinedButtonStyle,
                                    icon: vm.isLoading
                                        ? spinnerSmall()
                                        : const Icon(Icons.delete_sweep),
                                    label: const Text('Clear Logs'),
                                    onPressed: () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      try {
                                        ForegroundTaskService.instance
                                            .clearLogs();
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(const SnackBar(
                                            content: Text('Logs cleared')));
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(SnackBar(
                                            content:
                                                Text('Clear logs failed: $e')));
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: outlinedButtonStyle,
                                    icon: vm.isLoading
                                        ? spinnerSmall()
                                        : const Icon(Icons.copy),
                                    label: const Text('Copy Logs'),
                                    onPressed: () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      try {
                                        final logs = ForegroundTaskService
                                            .instance.recentLogs
                                            .join('\n');
                                        await Clipboard.setData(
                                            ClipboardData(text: logs));
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(const SnackBar(
                                            content: Text('Logs copied')));
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        messenger?.showSnackBar(SnackBar(
                                            content: Text('Copy failed: $e')));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

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
                                  children: vm.pending.map<Widget>((row) {
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
                                    final pretty = () {
                                      try {
                                        final decoded = json.decode(payload);
                                        return JsonEncoder.withIndent('  ')
                                            .convert(decoded);
                                      } catch (_) {
                                        return payload;
                                      }
                                    }();

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: ExpansionTile(
                                        title: Text(
                                          row['title']?.toString() ??
                                              (payload.length > 60
                                                  ? '${payload.substring(0, 60)}…'
                                                  : payload),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                            'status: ${status.isNotEmpty ? status : '-'} • id: ${id ?? '-'}'),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: SelectableText(pretty),
                                          ),
                                          OverflowBar(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.play_arrow),
                                                tooltip: 'Run this pending now',
                                                visualDensity:
                                                    VisualDensity.compact,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36),
                                                onPressed: id == null
                                                    ? null
                                                    : () async {
                                                        try {
                                                          ForegroundTaskService
                                                                  .instance
                                                                  .lastLogListenable
                                                                  .value =
                                                              'runPending: id=$id';
                                                        } catch (_) {}
                                                        try {
                                                          await flushPendingSubmissionById(
                                                              id);
                                                          await vm
                                                              .loadPending();
                                                        } catch (e, st) {
                                                          try {
                                                            ForegroundTaskService
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
                                                tooltip: 'Delete pending',
                                                visualDensity:
                                                    VisualDensity.compact,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36),
                                                onPressed: id == null
                                                    ? null
                                                    : () async {
                                                        await vm
                                                            .removePending(id);
                                                      },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              }),
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
