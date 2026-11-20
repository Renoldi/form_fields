part of '../workmanager_service.dart';

extension _WorkmanagerRegistrationX on WorkmanagerService {
  Future<void> _startAll({bool triggerNow = true}) async {
    try {
      // Only host-provided registrations are scheduled. The demo definitions
      // are for the example UI and have no handlers in a host app.
      final defs = _providedWorkerDefinitions ?? const <Map<String, dynamic>>[];
      if (defs.isEmpty) {
        _addLog('startAll: no worker registrations were provided');
      }
      for (final def in defs) {
        final name = def['name'] as String;
        final freq = def['frequency'] as Duration;
        final init = def['initialDelay'] as Duration;

        final data = <String, dynamic>{};
        final bgHandler = _perTaskBackgroundHandlers[name];
        if (bgHandler != null) {
          try {
            final cb = PluginUtilities.getCallbackHandle(bgHandler);
            if (cb != null) data['callback_handle'] = cb.toRawHandle();
          } catch (_) {}
        }

        await start(
          taskName: name,
          frequency: freq,
          periodic: true,
          inputData: data.isEmpty ? null : data,
          initialDelay: init,
        );

        if (!triggerNow) continue;

        // Prefer invoking a per-task foreground handler if registered.
        try {
          final fg = _perTaskForegroundHandlers[name];
          if (fg != null) {
            await fg();
          } else {
            await runOnceNowDetailed(
              taskName: name,
              inputData: data.isEmpty ? null : data,
            );
          }
        } catch (e) {
          try {
            lastLogListenable.value = 'start all trigger failed for $name: $e';
          } catch (_) {}
        }
      }
    } catch (e) {
      try {
        lastLogListenable.value = 'start all failed: $e';
      } catch (_) {}
      rethrow;
    }
    // Ensure countdown timer is active after scheduling.
    try {
      _startCountdownTimer();
    } catch (_) {}
  }

  Future<void> _startWorkerByName(String name, {bool triggerNow = true}) async {
    try {
      Map<String, dynamic>? def;
      for (final d
          in _providedWorkerDefinitions ?? const <Map<String, dynamic>>[]) {
        try {
          if ((d['name'] as String) == name) {
            def = d;
            break;
          }
        } catch (_) {}
      }
      if (def == null) {
        _addLog('startWorkerByName: definition not found: $name');
        return;
      }

      final freq = def['frequency'] as Duration;
      final init = def['initialDelay'] as Duration;

      final data = <String, dynamic>{};
      final bgHandler = _perTaskBackgroundHandlers[name];
      if (bgHandler != null) {
        try {
          final cb = PluginUtilities.getCallbackHandle(bgHandler);
          if (cb != null) data['callback_handle'] = cb.toRawHandle();
        } catch (_) {}
      }

      await start(
        taskName: name,
        frequency: freq,
        periodic: true,
        inputData: data.isEmpty ? null : data,
        initialDelay: init,
      );

      if (!triggerNow) return;

      try {
        final fg = _perTaskForegroundHandlers[name];
        if (fg != null) {
          await fg();
        } else {
          await runOnceNowDetailed(
            taskName: name,
            inputData: data.isEmpty ? null : data,
          );
        }
      } catch (e) {
        try {
          lastLogListenable.value = 'start worker trigger failed for $name: $e';
        } catch (_) {}
      }
    } catch (e) {
      try {
        lastLogListenable.value = 'start worker failed: $e';
      } catch (_) {}
      rethrow;
    }
    // Ensure countdown timer is active after scheduling this worker.
    try {
      _startCountdownTimer();
    } catch (_) {}
  }

  Future<void> _stopWorkerByName(String name) async {
    try {
      await stop(taskName: name);
      try {
        lastLogListenable.value = 'stopWorkerByName: stopped $name';
      } catch (_) {}
    } catch (e) {
      try {
        lastLogListenable.value = 'stop worker failed: $e';
      } catch (_) {}
      rethrow;
    }
  }

  String? _getCountdownForTask(String name) {
    try {
      final at = _scheduledAtPerTask[name];
      if (at == null) return null;

      // Prefer the requested frequency when host provided definitions
      // (so UI shows what the host requested rather than platform-adjusted).
      Duration? fq;
      final requested = _scheduledRequestedFrequencyPerTask[name];
      if (_providedWorkerDefinitions != null && requested != null) {
        fq = requested;
      } else {
        fq = _scheduledFrequencyPerTask[name];
      }
      if (fq == null) return null;

      final next = at.add(fq);
      final rem = next.difference(DateTime.now());
      if (rem.inMilliseconds <= 0) return '00:00';

      final h = rem.inHours;
      final m = rem.inMinutes.remainder(60);
      final s = rem.inSeconds.remainder(60);
      final display = h > 0
          ? '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
          : '${m.toString()}:${s.toString().padLeft(2, '0')}';
      return display;
    } catch (_) {
      return null;
    }
  }

  void _setProvidedWorkerDefinitions(List<Map<String, dynamic>> defs) {
    try {
      _providedWorkerDefinitions = List<Map<String, dynamic>>.from(defs);
      try {
        for (final d in _providedWorkerDefinitions ?? []) {
          final name = d['name'];
          final freq = d['frequency'] is Duration
              ? (d['frequency'] as Duration).inSeconds
              : d['frequency']?.toString();
          _addLog('provided_def: $name freq_s=$freq');
          try {
            // Also print to console so adb logcat captures it.
            _log.fine('provided_def: $name freq_s=$freq');
          } catch (_) {}
        }
      } catch (_) {}
    } catch (_) {}
  }
}
