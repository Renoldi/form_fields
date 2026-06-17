import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_fields/form_fields.dart'
    show ImportExportService, DBService;
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SqlViewerViewModel(),
      child: _SqlView(),
    );
  }
}

class _SqlView extends StatefulWidget {
  @override
  State<_SqlView> createState() => _SqlViewState();
}

class _SqlViewState extends State<_SqlView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SqlViewerViewModel>().loadTables();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SqlViewerViewModel>(builder: (context, vm, _) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: LayoutBuilder(builder: (context, constraints) {
                final dropdownWidth = constraints.maxWidth > 480
                    ? 300.0
                    : constraints.maxWidth * 0.5;
                return Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: dropdownWidth,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        initialValue: vm.selectedTable,
                        items: vm.tables
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t,
                                  overflow: TextOverflow.ellipsis,
                                )))
                            .toList(),
                        onChanged: (v) async {
                          if (v != null) {
                            final vmRef = context.read<SqlViewerViewModel>();
                            await vmRef.loadRows(v);
                            if (!mounted) return;
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Table'),
                      ),
                    ),
                    ElevatedButton(
                        onPressed: vm.loading ? null : () => vm.loadTables(),
                        child: const Text('Refresh')),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Import sample asset'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final messenger =
                                  ScaffoldMessenger.maybeOf(context);
                              final vmRef = context.read<SqlViewerViewModel>();
                              final path = await ImportExportService.instance
                                  .importFromAsset('assets/imports/sample.sql');
                              if (path != null) {
                                messenger?.showSnackBar(SnackBar(
                                    content:
                                        Text('Imported from asset: $path')));
                                // Reload tables after import
                                await vmRef.loadTables();
                              } else {
                                messenger?.showSnackBar(const SnackBar(
                                    content: Text('Import failed')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('Import from file'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final messenger =
                                  ScaffoldMessenger.maybeOf(context);
                              final vmRef = context.read<SqlViewerViewModel>();
                              final path = await ImportExportService.instance
                                  .pickFileAndImport();
                              if (path != null) {
                                messenger?.showSnackBar(SnackBar(
                                    content:
                                        Text('Imported from file: $path')));
                                await vmRef.loadTables();
                              } else {
                                messenger?.showSnackBar(const SnackBar(
                                    content:
                                        Text('Import cancelled or failed')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Export to folder'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final messenger =
                                  ScaffoldMessenger.maybeOf(context);
                              final out = await ImportExportService.instance
                                  .pickFolderAndExport();
                              if (out != null) {
                                messenger?.showSnackBar(SnackBar(
                                    content: Text('Exported to $out')));
                              } else {
                                messenger?.showSnackBar(const SnackBar(
                                    content: Text('Export cancelled')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run SQL'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final controller = TextEditingController();
                              final query = await showDialog<String?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Run SQL'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 8,
                                    decoration: const InputDecoration(
                                        labelText: 'SQL query',
                                        hintText: 'Paste SQL here...'),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, controller.text),
                                        child: const Text('Execute')),
                                  ],
                                ),
                              );
                              if (query == null || query.trim().isEmpty) return;
                              final messenger =
                                  ScaffoldMessenger.maybeOf(context);
                              try {
                                final res =
                                    await DBService.instance.executeSql(query);
                                messenger?.showSnackBar(SnackBar(
                                    content:
                                        Text('SQL executed, result: $res')));
                                await context
                                    .read<SqlViewerViewModel>()
                                    .loadTables();
                              } catch (e) {
                                messenger?.showSnackBar(SnackBar(
                                    content: Text('SQL execution failed: $e')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('Upgrade DB'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = context.read<SqlViewerViewModel>();
                              final controller = TextEditingController();
                              final assetsController = TextEditingController();
                              final target = await showDialog<int?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Upgrade database'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Target version (int)'),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: assetsController,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Migration asset paths (comma-separated)'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          final v = int.tryParse(
                                              controller.text.trim());
                                          Navigator.pop(ctx, v);
                                        },
                                        child: const Text('Upgrade')),
                                  ],
                                ),
                              );
                              if (target != null) {
                                final assetsText = assetsController.text.trim();
                                final assetsList = assetsText.isEmpty
                                    ? null
                                    : assetsText
                                        .split(',')
                                        .map((s) => s.trim())
                                        .where((s) => s.isNotEmpty)
                                        .toList();
                                await vmRef.upgradeAndCaptureTables(target,
                                    migrationAssetPaths: assetsList);
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Tables: before → after'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Before:'),
                                          for (final t
                                              in vmRef.tablesBeforeUpgrade)
                                            Text(' • $t'),
                                          const SizedBox(height: 8),
                                          const Text('After:'),
                                          for (final t
                                              in vmRef.tablesAfterUpgrade)
                                            Text(' • $t'),
                                          if (vmRef.lastUpgradeError !=
                                              null) ...[
                                            const SizedBox(height: 8),
                                            const Text('Error:'),
                                            Text(vmRef.lastUpgradeError!),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'))
                                    ],
                                  ),
                                );
                                await vmRef.loadTables();
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('Downgrade DB'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = context.read<SqlViewerViewModel>();
                              final controller = TextEditingController();
                              final assetsController = TextEditingController();
                              final target = await showDialog<int?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Downgrade database'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Target version (int)'),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: assetsController,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Migration asset paths (comma-separated)'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          final v = int.tryParse(
                                              controller.text.trim());
                                          Navigator.pop(ctx, v);
                                        },
                                        child: const Text('Downgrade')),
                                  ],
                                ),
                              );
                              if (target != null) {
                                final assetsText = assetsController.text.trim();
                                final assetsList = assetsText.isEmpty
                                    ? null
                                    : assetsText
                                        .split(',')
                                        .map((s) => s.trim())
                                        .where((s) => s.isNotEmpty)
                                        .toList();
                                await vmRef.downgradeAndCaptureTables(target,
                                    migrationAssetPaths: assetsList);
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Tables: before → after'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Before:'),
                                          for (final t
                                              in vmRef.tablesBeforeUpgrade)
                                            Text(' • $t'),
                                          const SizedBox(height: 8),
                                          const Text('After:'),
                                          for (final t
                                              in vmRef.tablesAfterUpgrade)
                                            Text(' • $t'),
                                          if (vmRef.lastUpgradeError !=
                                              null) ...[
                                            const SizedBox(height: 8),
                                            const Text('Error:'),
                                            Text(vmRef.lastUpgradeError!),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'))
                                    ],
                                  ),
                                );
                                await vmRef.loadTables();
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Set DB version'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = context.read<SqlViewerViewModel>();
                              final controller = TextEditingController();
                              final target = await showDialog<int?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Set DB version'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'Version (int)'),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          final v = int.tryParse(
                                              controller.text.trim());
                                          Navigator.pop(ctx, v);
                                        },
                                        child: const Text('Set')),
                                  ],
                                ),
                              );
                              if (target != null) {
                                await vmRef.setUserVersion(target);
                                final ver = vmRef.dbVersion;
                                if (vmRef.lastUpgradeError != null) {
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(SnackBar(
                                          content: Text(
                                              'Failed: ${vmRef.lastUpgradeError}')));
                                } else {
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(SnackBar(
                                          content: Text(
                                              'user_version set -> ${ver ?? 'unknown'}')));
                                }
                                await vmRef.loadDbVersion();
                                await vmRef.loadTables();
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Reset DB'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final messenger =
                                  ScaffoldMessenger.maybeOf(context);
                              final vmRef = context.read<SqlViewerViewModel>();
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (ctx) {
                                  bool removeMigrations = false;
                                  bool removePayloads = false;
                                  return StatefulBuilder(
                                    builder: (ctx, setState) => AlertDialog(
                                      title: const Text('Reset database?'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                              'This will delete the local database and re-initialize it from bundled assets.'),
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            value: removeMigrations,
                                            onChanged: (v) => setState(() =>
                                                removeMigrations = v ?? false),
                                            title: const Text(
                                                'Also delete migrations folder'),
                                          ),
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            value: removePayloads,
                                            onChanged: (v) => setState(() =>
                                                removePayloads = v ?? false),
                                            title: const Text(
                                                'Also delete payloads folder'),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, null),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, {
                                                  'confirmed': true,
                                                  'removeMigrations':
                                                      removeMigrations,
                                                  'removePayloads':
                                                      removePayloads,
                                                }),
                                            child: const Text('Reset')),
                                      ],
                                    ),
                                  );
                                },
                              );
                              if (result != null &&
                                  result['confirmed'] == true) {
                                final removeMigrations =
                                    result['removeMigrations'] == true;
                                final removePayloads =
                                    result['removePayloads'] == true;
                                await DBService.instance.resetDatabase(
                                    reinit: false,
                                    removeMigrationsDir: removeMigrations,
                                    removePayloadsDir: removePayloads);
                                messenger?.showSnackBar(const SnackBar(
                                    content: Text('Database reset')));
                                // Do not call loadTables() here because that calls
                                // `DBService.init()` which would recreate the DB.
                                // Instead, clear the view model state so UI shows empty.
                                vmRef.clearState();
                              }
                            },
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Consumer<SqlViewerViewModel>(builder: (context, vm, _) {
                final verText =
                    vm.dbVersion != null ? vm.dbVersion.toString() : 'unknown';
                return Text('DB version: $verText');
              }),
            ),
            const SizedBox(height: 8),
            if (vm.loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: vm.selectedTable == null
                  ? const Center(child: Text('Select a table to view rows'))
                  : ListView.builder(
                      itemCount: vm.rows.length,
                      itemBuilder: (context, idx) {
                        final row = vm.rows[idx];
                        final rowid = row['rowid'] ?? row['id'] ?? idx;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ExpansionTile(
                            title: Text('${vm.selectedTable} • row $rowid'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(vm.rowToPrettyJson(row)),
                              ),
                              OverflowBar(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      await Clipboard.setData(ClipboardData(
                                          text: vm.rowToPrettyJson(row)));
                                      messenger?.showSnackBar(const SnackBar(
                                          content: Text('Copied JSON')));
                                    },
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy JSON'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      final vmRef =
                                          context.read<SqlViewerViewModel>();
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete row?'),
                                          content: const Text(
                                              'This will delete the row from the database.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        final id = (row['rowid'] is int)
                                            ? row['rowid'] as int
                                            : (row['id'] is int
                                                ? row['id'] as int
                                                : null);
                                        if (id != null) {
                                          await vmRef.deleteRow(
                                              vm.selectedTable!, id);
                                          messenger?.showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('Row deleted')));
                                        } else {
                                          messenger?.showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Unable to determine row id')));
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete_forever),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}
