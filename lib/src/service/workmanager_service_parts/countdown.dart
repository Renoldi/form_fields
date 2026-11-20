part of '../workmanager_service.dart';

extension _WorkmanagerCountdownX on WorkmanagerService {
  void _startCountdownTimer() {
    try {
      _countdownTimer?.cancel();
      countdownListenable.value = null;
      try {
        _addLog(
          'countdown: starting timer; registered=${_registeredTasks.length}',
        );
        if (kDebugMode) {
          _log.fine(
            'countdown: starting timer; registered=${_registeredTasks.length}',
          );
        }
      } catch (_) {}
      if (_registeredTasks.isEmpty) return;

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        try {
          final now = DateTime.now();
          Duration? minRem;
          final Map<String, String?> perMap = {};
          final List<String> toTrigger = [];

          for (final tName in _registeredTasks) {
            final at = _scheduledAtPerTask[tName];
            // Prefer displaying the requested frequency when the host
            // provided definitions (the user expects the UI to reflect
            // `workerRegistrations`). Fall back to the effective platform
            // frequency otherwise.
            Duration? fq;
            final requested = _scheduledRequestedFrequencyPerTask[tName];
            if (_providedWorkerDefinitions != null && requested != null) {
              fq = requested;
            } else {
              fq = _scheduledFrequencyPerTask[tName];
            }
            if (at == null || fq == null) {
              perMap[tName] = null;
              continue;
            }
            final next = at.add(fq);
            final rem = next.difference(now);
            if (rem.inMilliseconds <= 0) {
              toTrigger.add(tName);
              perMap[tName] = '00:00';
              minRem = const Duration(seconds: 0);
            } else {
              final h = rem.inHours;
              final m = rem.inMinutes.remainder(60);
              final s = rem.inSeconds.remainder(60);
              final display = h > 0
                  ? '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                  : '${m.toString()}:${s.toString().padLeft(2, '0')}';
              perMap[tName] = display;
              if (minRem == null || rem < minRem) minRem = rem;
            }
          }

          try {
            perTaskCountdownListenable.value = perMap;
          } catch (_) {}

          // countdown tick logging: report per-task remaining times so
          // it's easy to see each worker's countdown in `recentLogs` or
          // console output while debugging.
          try {
            final entries = perMap.entries
                .map((e) => '${e.key}=${e.value ?? 'n/a'}')
                .join(', ');
            final msg = 'countdown-tick: $entries';
            _addLog(msg);
            if (kDebugMode) {
              _log.fine(msg);
            }
          } catch (_) {}
          if (minRem == null) {
            try {
              countdownListenable.value = null;
            } catch (_) {}
          } else {
            final h = minRem.inHours;
            final m = minRem.inMinutes.remainder(60);
            final s = minRem.inSeconds.remainder(60);
            final display = h > 0
                ? '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                : '${m.toString()}:${s.toString().padLeft(2, '0')}';
            try {
              countdownListenable.value = display;
            } catch (_) {}
          }

          if (toTrigger.isNotEmpty) {
            try {
              lastLogListenable.value =
                  'countdown-trigger: calling registered handlers toTrigger=${toTrigger.join(',')}';
            } catch (_) {}
            try {
              _addLog(
                'countdown-trigger: invoking handlers for ${toTrigger.join(',')}',
              );
            } catch (_) {}
            try {
              if (kDebugMode) {
                _log.fine(
                  'countdown-trigger: invoking handlers for ${toTrigger.join(',')}',
                );
              }
            } catch (_) {}

            try {
              for (final n in toTrigger) {
                try {
                  final eff = _scheduledFrequencyPerTask[n];
                  final req = _scheduledRequestedFrequencyPerTask[n];
                  _addLog(
                    'trigger-info: $n effective_s=${eff?.inSeconds} requested_s=${req?.inSeconds} providedDefs=${_providedWorkerDefinitions != null}',
                  );
                  if (kDebugMode) {
                    _log.fine(
                      'trigger-info: $n effective_s=${eff?.inSeconds} requested_s=${req?.inSeconds} providedDefs=${_providedWorkerDefinitions != null}',
                    );
                  }
                } catch (_) {}
              }
            } catch (_) {}

            // Prevent overlapping flush runs using shared guard. Acquire
            // the guard centrally; if acquisition fails another flush is
            // already running and we skip triggering handlers for this tick.
            final acquired = WorkmanagerService.acquireFlushGuard();
            if (!acquired) {
              try {
                lastLogListenable.value =
                    'countdown-trigger: flush already in progress; skipping';
              } catch (_) {}
            } else {
              var success = false;
              try {
                // Mark that countdown is invoking handlers so foreground
                // handlers can avoid attempting to re-acquire the guard.
                try {
                  WorkmanagerService._inCountdownInvocation = true;
                } catch (_) {}
                try {
                  lastLogListenable.value =
                      'countdown-trigger: toTrigger=${toTrigger.join(',')}';
                } catch (_) {}

                // Deduplicate per-task foreground handlers and invoke them
                final Set<Future<void> Function()> uniqueFgHandlers = {};
                for (final n in toTrigger) {
                  final h = _perTaskForegroundHandlers[n];
                  if (h != null) uniqueFgHandlers.add(h);
                }

                if (uniqueFgHandlers.isNotEmpty) {
                  try {
                    lastLogListenable.value =
                        'countdown-trigger: invoking ${uniqueFgHandlers.length} per-task foreground handlers';
                  } catch (_) {}
                  for (final h in uniqueFgHandlers) {
                    try {
                      await h();
                      success = true;
                      try {
                        lastLogListenable.value = 'task-handler success';
                      } catch (_) {}
                    } catch (e) {
                      try {
                        lastLogListenable.value = 'task-handler threw: $e';
                      } catch (_) {}
                      try {
                        _addLog('task-handler threw: $e');
                      } catch (_) {}
                    }
                  }
                } else {
                  // No foreground handlers. Try per-task background handlers
                  // and invoke each unique background handler only once.
                  final Map<BackgroundTaskHandler, String> bgHandlerToTask = {};
                  for (final n in toTrigger) {
                    final bh = _perTaskBackgroundHandlers[n];
                    if (bh != null && !bgHandlerToTask.containsKey(bh)) {
                      bgHandlerToTask[bh] = n;
                    }
                  }

                  if (bgHandlerToTask.isNotEmpty) {
                    try {
                      lastLogListenable.value =
                          'countdown-trigger: invoking ${bgHandlerToTask.length} per-task background handlers';
                    } catch (_) {}
                    for (final entry in bgHandlerToTask.entries) {
                      final bh = entry.key;
                      final repTask = entry.value;
                      // Find inputData for representative task if provided
                      Map<String, dynamic>? inputData;
                      try {
                        for (final def in providedWorkerDefinitions) {
                          try {
                            if ((def['name'] as String) == repTask &&
                                def['inputData'] != null) {
                              inputData = Map<String, dynamic>.from(
                                def['inputData'] as Map<String, dynamic>,
                              );
                              break;
                            }
                          } catch (_) {}
                        }
                      } catch (_) {}

                      try {
                        final res = await bh(repTask, inputData);
                        if (res == true) success = true;
                        try {
                          lastLogListenable.value =
                              'background handler for $repTask -> ${res ? 'success' : 'failure'}';
                        } catch (_) {}
                      } catch (e) {
                        try {
                          lastLogListenable.value =
                              'background handler for $repTask threw: $e';
                        } catch (_) {}
                      }
                    }
                  } else if (foregroundFlushHandler != null) {
                    try {
                      lastLogListenable.value =
                          'countdown-trigger: calling global foregroundFlushHandler';
                    } catch (_) {}
                    try {
                      await foregroundFlushHandler!();
                      success = true;
                      try {
                        lastLogListenable.value =
                            'foregroundFlushHandler success';
                      } catch (_) {}
                    } catch (e) {
                      try {
                        lastLogListenable.value =
                            'foregroundFlushHandler threw: $e';
                      } catch (_) {}
                    }
                  } else if (WorkmanagerService._backgroundHandler != null) {
                    // Fallback to a globally-registered background handler
                    try {
                      final rep = toTrigger.first;
                      Map<String, dynamic>? inputData;
                      try {
                        for (final def in providedWorkerDefinitions) {
                          try {
                            if ((def['name'] as String) == rep &&
                                def['inputData'] != null) {
                              inputData = Map<String, dynamic>.from(
                                def['inputData'] as Map<String, dynamic>,
                              );
                              break;
                            }
                          } catch (_) {}
                        }
                      } catch (_) {}
                      final res = await WorkmanagerService._backgroundHandler!(
                        rep,
                        inputData,
                      );
                      if (res == true) success = true;
                      try {
                        lastLogListenable.value =
                            'global background handler for $rep -> ${res ? 'success' : 'failure'}';
                      } catch (_) {}
                    } catch (e) {
                      try {
                        lastLogListenable.value =
                            'global background handler threw: $e';
                      } catch (_) {}
                    }
                  } else {
                    try {
                      lastLogListenable.value =
                          'countdown-trigger: no handlers registered for tasks';
                    } catch (_) {}
                  }
                }
              } catch (e, st) {
                try {
                  lastLogListenable.value =
                      'countdown-triggered handlers threw: $e\n$st';
                } catch (_) {}
              } finally {
                try {
                  WorkmanagerService._inCountdownInvocation = false;
                } catch (_) {}
                try {
                  WorkmanagerService.releaseFlushGuard();
                } catch (_) {}
              }

              try {
                lastLogListenable.value =
                    'countdown-triggered handlers: ${success ? 'success' : 'failure'}';
              } catch (_) {}

              try {
                _addLog(
                  'countdown-triggered handlers result: ${success ? 'success' : 'failure'}',
                );
                if (kDebugMode) {
                  _log.fine(
                    'countdown-triggered handlers result: ${success ? 'success' : 'failure'}',
                  );
                }
              } catch (_) {}

              try {
                final now2 = DateTime.now();
                for (final n in toTrigger) {
                  // Update scheduledAt when we know an effective frequency
                  // (platform-adjusted) or when the host provided a requested
                  // frequency via `workerRegistrations`. The countdown logic
                  // uses the requested frequency when provided, so we must
                  // update scheduledAt in that case as well to avoid
                  // immediately retriggering.
                  if (_scheduledFrequencyPerTask[n] != null) {
                    _scheduledAtPerTask[n] = now2;
                    try {
                      _addLog(
                        'updated scheduledAt for $n -> ${now2.toIso8601String()} (effective freq)',
                      );
                    } catch (_) {}
                  } else if (_providedWorkerDefinitions != null &&
                      _scheduledRequestedFrequencyPerTask[n] != null) {
                    _scheduledAtPerTask[n] = now2;
                    try {
                      _addLog(
                        'updated scheduledAt for $n -> ${now2.toIso8601String()} (requested freq)',
                      );
                    } catch (_) {}
                  }
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _stopCountdownTimer() {
    try {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    } catch (_) {}
    try {
      countdownListenable.value = null;
    } catch (_) {}
    // Clear the per-task values too. Otherwise a stopped worker keeps showing
    // a "Next run in" time that will never fire.
    try {
      perTaskCountdownListenable.value = <String, String?>{};
    } catch (_) {}
  }
}
