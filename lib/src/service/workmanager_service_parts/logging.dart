part of '../workmanager_service.dart';

extension _WorkmanagerLoggingX on WorkmanagerService {
  void _attachLastLogListener() {
    lastLogListenable.addListener(() {
      try {
        if (_suppressListener) return;
        final v = lastLogListenable.value;
        if (v != null) {
          _logs.add(v);
          if (_logs.length > 50) _logs.removeAt(0);
        }
      } catch (_) {}
    });
  }

  void _addLog(String msg) {
    try {
      _logs.add(msg);
      if (_logs.length > 50) _logs.removeAt(0);
      _suppressListener = true;
      lastLogListenable.value = msg;
      _suppressListener = false;
    } catch (_) {}
  }
}
