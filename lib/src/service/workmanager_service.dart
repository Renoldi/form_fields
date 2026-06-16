import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'db_service.dart';

final _log = Logger('WorkmanagerService');

const String _backgroundTaskName = 'form_fields_background_task';

/// Top-level callback dispatcher required by `workmanager`.
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    _log.info('Workmanager running task: $task, input: $inputData');
    try {
      // Example background job: export the DB to a temp SQL file so it can be
      // inspected or uploaded by other processes. Keep this minimal and
      // resilient — failures are logged but do not crash the worker.
      final tmpDir = await getTemporaryDirectory();
      final out = p.join(tmpDir.path,
          'form_fields_bg_export_${DateTime.now().toIso8601String()}.sql');
      await DBService.instance.exportToSqlFile(out);
      _log.info('Workmanager exported DB to $out');
    } catch (e, st) {
      _log.severe('Background task failed: $e', e, st);
      return Future.value(false);
    }

    return Future.value(true);
  });
}

class WorkmanagerService {
  WorkmanagerService._();
  static final WorkmanagerService instance = WorkmanagerService._();

  Future<void> initialize() async {
    // `isInDebugMode` is deprecated; initialize without that parameter.
    await Workmanager().initialize(workmanagerCallbackDispatcher);
    _log.info('Workmanager initialized');
  }

  Future<void> registerPeriodic() async {
    await Workmanager().registerPeriodicTask(
        _backgroundTaskName, _backgroundTaskName,
        frequency: const Duration(hours: 1));
    _log.info('Registered periodic background task');
  }
}
